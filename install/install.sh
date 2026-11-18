#!/bin/bash
# Arch base install from the Arch ISO, set up by a config file (fw13.conf is
# this Framework 13). The dotfiles take over after the first boot:
# chezmoi init --apply SjorsLockhorst.
#
# Usage: install.sh [--unattended] [--post-install <dir>] <config>
#   Interactive (default): shows the plan, asks you to type the disk it wipes,
#   then the LUKS passphrase and the user's password.
#   --unattended    for test/vm: passwords from LUKS_PASSPHRASE and
#                   USER_PASSWORD, no questions, and only inside a VM.
#   --post-install  run <dir>/run in the new system at the end, with the user
#                   name as $1 (files it needs go in <dir>).
#
# On the laptop, from the ISO (connect wifi first: iwctl):
#   curl -L https://github.com/SjorsLockhorst/dotfiles/archive/main.tar.gz | tar xz
#   dotfiles-main/install/install.sh dotfiles-main/install/fw13.conf
#
# Each step is one function below; the config picks between the variants they
# support. Test a change in a VM first: test/vm/run.sh.
set -euo pipefail

unattended=0
post_install=
while [[ $# -gt 1 ]]; do
    case $1 in
        --unattended) unattended=1 ;;
        --post-install) post_install=$(realpath "$2"); shift ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
if [[ $# -ne 1 || $1 == -* ]]; then
    # The header comment above
    awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
    exit 2
fi
config=$(realpath "$1")

log() { echo "==> $*"; }
die() { echo "install: $*" >&2; exit 1; }

load_config() {
    # shellcheck source=fw13.conf
    source "$config"
    local v
    for v in DISK ESP_SIZE ESP_MOUNT ENCRYPTION FILESYSTEM HOST_NAME TIMEZONE LOCALE USERNAME BOOTLOADER_ID; do
        [[ -n ${!v:-} ]] || die "$v is not set in $config"
    done
    for v in PACKAGES SERVICES; do
        declare -p "$v" &>/dev/null || die "$v is not set in $config"
    done
    case $ENCRYPTION in luks|none) ;; *) die "ENCRYPTION must be luks or none" ;; esac
    case $FILESYSTEM in btrfs|ext4) ;; *) die "FILESYSTEM must be btrfs or ext4" ;; esac
    # GRUB unlocks /boot inside the LUKS root; with /boot on the EFI partition
    # the initramfs would have to ask for the passphrase instead.
    if [[ $ENCRYPTION == luks && $ESP_MOUNT == /boot ]]; then
        die "ENCRYPTION=luks needs /boot inside the root: set ESP_MOUNT=/efi"
    fi
    # nvme0n1 -> nvme0n1p1, vda -> vda1
    local sep=; [[ $DISK =~ [0-9]$ ]] && sep=p
    ESP_PART=$DISK${sep}1
    ROOT_PART=$DISK${sep}2
}

preflight() {
    [[ -d /run/archiso ]] || die "run this from the Arch ISO"
    if [[ $unattended == 1 ]] && ! systemd-detect-virt --vm -q; then
        die "--unattended wipes $DISK without asking: only inside a VM"
    fi
    [[ -d /sys/firmware/efi/efivars ]] || die "boot the ISO in UEFI mode"
    [[ -b $DISK ]] || die "$DISK is not a disk"
    curl -fsI -m 10 https://archlinux.org >/dev/null || die "no network (wifi: iwctl)"
    # The ISO fills its keyring and picks mirrors at boot; pacstrap needs both.
    systemctl start pacman-init.service
    while [[ $(systemctl show -p ActiveState --value reflector.service) == activating ]]; do sleep 2; done
}

confirm_and_ask_passwords() {
    if [[ $unattended == 1 ]]; then
        [[ -n ${LUKS_PASSPHRASE:-} || $ENCRYPTION == none ]] || die "LUKS_PASSPHRASE is not set"
        [[ -n ${USER_PASSWORD:-} ]] || die "USER_PASSWORD is not set"
        return
    fi
    echo "Config: $config"
    echo "  $DISK: GPT, $ESP_SIZE EFI partition on $ESP_MOUNT, the rest $FILESYSTEM ($ENCRYPTION)"
    echo "  host $HOST_NAME, user $USERNAME, $TIMEZONE, $LOCALE"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MODEL "$DISK"
    local answer
    read -rp "Everything on $DISK will be erased. Type $DISK to go on: " answer
    [[ $answer == "$DISK" ]] || die "not confirmed"
    if [[ $ENCRYPTION == luks ]]; then
        LUKS_PASSPHRASE=$(ask_secret "LUKS passphrase (GRUB asks it at boot, US layout)")
    fi
    USER_PASSWORD=$(ask_secret "Password for $USERNAME")
}

ask_secret() {
    local a b
    while true; do
        read -rsp "$1: " a; echo >&2
        read -rsp "Again: " b; echo >&2
        [[ -n $a && $a == "$b" ]] && break
        echo "Empty or not the same, try again." >&2
    done
    printf '%s' "$a"
}

partition() {
    log "Partitioning $DISK"
    umount -R /mnt 2>/dev/null || true
    cryptsetup close root 2>/dev/null || true
    sgdisk --zap-all "$DISK"
    # 8304: "Linux root (x86-64)", so systemd can find it without fstab.
    sgdisk -n "1:0:+$ESP_SIZE" -t 1:ef00 -n 2:0:0 -t 2:8304 "$DISK"
    partprobe "$DISK"
    udevadm settle
}

encrypt() {
    if [[ $ENCRYPTION == none ]]; then
        ROOT_DEV=$ROOT_PART
        return
    fi
    log "Encrypting $ROOT_PART (LUKS2)"
    # PBKDF2: GRUB can't unlock LUKS2 keyslots that use Argon2.
    printf '%s' "$LUKS_PASSPHRASE" |
        cryptsetup luksFormat --batch-mode --type luks2 --pbkdf pbkdf2 --key-file=- "$ROOT_PART"
    printf '%s' "$LUKS_PASSPHRASE" | cryptsetup open --key-file=- "$ROOT_PART" root
    ROOT_DEV=/dev/mapper/root
}

filesystems() {
    log "Creating $FILESYSTEM on $ROOT_DEV"
    mkfs.fat -F 32 "$ESP_PART"
    case $FILESYSTEM in
        btrfs)
            mkfs.btrfs -f "$ROOT_DEV"
            mount "$ROOT_DEV" /mnt
            local sv
            for sv in "${BTRFS_SUBVOLUMES[@]}"; do btrfs subvolume create "/mnt/${sv%%:*}"; done
            umount /mnt
            # / first: the other mountpoints are inside it.
            for sv in "${BTRFS_SUBVOLUMES[@]}"; do
                mount --mkdir -o "${MOUNT_OPTIONS:+$MOUNT_OPTIONS,}subvol=${sv%%:*}" "$ROOT_DEV" "/mnt${sv#*:}"
            done
            ;;
        ext4)
            mkfs.ext4 -F "$ROOT_DEV"
            mount ${MOUNT_OPTIONS:+-o "$MOUNT_OPTIONS"} "$ROOT_DEV" /mnt
            ;;
    esac
    mount --mkdir "$ESP_PART" "/mnt$ESP_MOUNT"
}

install_packages() {
    log "Installing ${#PACKAGES[@]} packages"
    pacstrap -K /mnt "${PACKAGES[@]}"
    genfstab -U /mnt >>/mnt/etc/fstab
    # Timeshift restores by subvolume name; a subvolid would pin the old one.
    sed -i 's/,subvolid=[0-9]*//' /mnt/etc/fstab
}

configure() {
    log "Configuring $HOST_NAME"
    ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime
    arch-chroot /mnt hwclock --systohc
    sed -i "s/^#\($LOCALE \)/\1/" /mnt/etc/locale.gen
    arch-chroot /mnt locale-gen
    echo "LANG=$LOCALE" >/mnt/etc/locale.conf
    if [[ -n ${KEYMAP:-} ]]; then echo "KEYMAP=$KEYMAP" >/mnt/etc/vconsole.conf; fi
    echo "$HOST_NAME" >/mnt/etc/hostname
    if [[ -n ${ZRAM_SIZE:-} ]]; then
        printf '[zram0]\nzram-size = %s\ncompression-algorithm = zstd\n' "$ZRAM_SIZE" \
            >/mnt/etc/systemd/zram-generator.conf
    fi
    arch-chroot /mnt systemctl enable "${SERVICES[@]}"
}

initramfs() {
    if [[ $ENCRYPTION == luks ]]; then
        log "Keyfile and initramfs for the encrypted root"
        # GRUB asks the passphrase to read /boot; the initramfs then unlocks
        # the root with this keyfile instead of asking again. It lives in the
        # (encrypted) root and in the initramfs, which mkinitcpio keeps 600.
        local key=/etc/cryptsetup-keys.d/root.key
        install -d -m 700 /mnt/etc/cryptsetup-keys.d
        dd if=/dev/random of="/mnt$key" bs=512 count=4 iflag=fullblock status=none
        chmod 600 "/mnt$key"
        # PBKDF2 as above; few iterations, since a random keyfile can't be guessed.
        printf '%s' "$LUKS_PASSPHRASE" | cryptsetup luksAddKey --key-file=- \
            --pbkdf pbkdf2 --pbkdf-force-iterations 1000 "$ROOT_PART" "/mnt$key"
        # The busybox encrypt hook: it reads cryptdevice= and cryptkey= (bootloader).
        cat >/mnt/etc/mkinitcpio.conf.d/encrypt.conf <<EOF
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)
FILES=($key)
EOF
    fi
    log "Building the initramfs"
    arch-chroot /mnt mkinitcpio -P
}

bootloader() {
    log "Installing GRUB on $ESP_MOUNT"
    if [[ $ENCRYPTION == luks ]]; then
        local uuid
        uuid=$(blkid -s UUID -o value "$ROOT_PART")
        sed -i 's/^#\?GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/' /mnt/etc/default/grub
        sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=$uuid:root root=/dev/mapper/root cryptkey=rootfs:/etc/cryptsetup-keys.d/root.key\"|" \
            /mnt/etc/default/grub
    fi
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory="$ESP_MOUNT" --bootloader-id="$BOOTLOADER_ID"
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
}

create_user() {
    log "Creating $USERNAME"
    arch-chroot /mnt useradd -m -G wheel "$USERNAME"
    printf '%s:%s\n' "$USERNAME" "$USER_PASSWORD" | arch-chroot /mnt chpasswd
    echo '%wheel ALL=(ALL:ALL) ALL' >/mnt/etc/sudoers.d/10-wheel
    chmod 440 /mnt/etc/sudoers.d/10-wheel
    # No root password: sudo instead.
    arch-chroot /mnt passwd -l root
}

run_post_install() {
    [[ -n $post_install ]] || return 0
    log "Post-install: $post_install"
    cp -r "$post_install" /mnt/root/post-install
    arch-chroot /mnt bash -c 'cd /root/post-install && ./run "$1"' _ "$USERNAME"
    rm -rf /mnt/root/post-install
}

finish() {
    cp /tmp/install.log /mnt/var/log/install.log
    umount -R /mnt
    if [[ $ENCRYPTION == luks ]]; then cryptsetup close root; fi
    log "Done. Reboot, log in as $USERNAME, then: chezmoi init --apply SjorsLockhorst"
}

load_config
preflight
confirm_and_ask_passwords
# From here on, everything goes to the log too (copied to /var/log/install.log).
exec > >(tee /tmp/install.log) 2>&1
partition
encrypt
filesystems
install_packages
configure
initramfs
bootloader
create_user
run_post_install
finish
