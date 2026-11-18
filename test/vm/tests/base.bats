#!/usr/bin/env bats
# The base install (install/install.sh) after its first boot, in the VM of
# test/vm/run.sh. Checks follow the config it was installed with
# (../install.conf). Reaching this at all means GRUB took the one passphrase
# typed at the serial console and the initramfs needed no second one.

setup() {
    # shellcheck source=../../../install/fw13.conf
    source "$BATS_TEST_DIRNAME/../install.conf"
    sep=; [[ $DISK =~ [0-9]$ ]] && sep=p
}

@test "it boots to a running system" {
    run systemctl is-system-running --wait
    systemctl --failed --no-legend
    [ "$output" = running ]
}

@test "GPT: the EFI partition with GRUB, in the firmware's boot order, then the root" {
    [ "$(lsblk -dno PARTTYPENAME "$DISK${sep}1")" = "EFI System" ]
    [ "$(lsblk -dno PARTTYPENAME "$DISK${sep}2")" = "Linux root (x86-64)" ]
    [ "$(findmnt -no FSTYPE "$ESP_MOUNT")" = vfat ]
    [ -f "$ESP_MOUNT/EFI/$BOOTLOADER_ID/grubx64.efi" ]
    efibootmgr | grep -qE "^Boot[0-9A-F]{4}\* $BOOTLOADER_ID\b"
}

@test "the root is LUKS2 with /boot inside it, unlocked by a keyfile in the initramfs" {
    [ "$ENCRYPTION" = luks ] || skip "not encrypted"
    [ "$(findmnt -nvo SOURCE /)" = /dev/mapper/root ]
    sudo cryptsetup status root | grep -qE 'type: +LUKS2'
    run findmnt /boot
    [ "$status" -ne 0 ]
    uuid=$(sudo blkid -s UUID -o value "$DISK${sep}2")
    grep -q "cryptdevice=UUID=$uuid:root .*cryptkey=rootfs:/etc/cryptsetup-keys.d/root.key" /proc/cmdline
    sudo lsinitcpio /boot/initramfs-linux.img | grep -qx etc/cryptsetup-keys.d/root.key
    [ "$(sudo stat -c %a /etc/cryptsetup-keys.d /etc/cryptsetup-keys.d/root.key)" = $'700\n600' ]
}

@test "btrfs subvolumes mounted with the options, and fstab names them by path" {
    [ "$FILESYSTEM" = btrfs ] || skip "not btrfs"
    for sv in "${BTRFS_SUBVOLUMES[@]}"; do
        opts=$(findmnt -no FSTYPE,OPTIONS "${sv#*:}")
        echo "${sv#*:}: $opts"
        [[ $opts == btrfs* && $opts == *"subvol=/${sv%%:*}"* && $opts == *"$MOUNT_OPTIONS"* ]]
    done
    # Timeshift restores by name; a subvolid would pin the old subvolume.
    run grep subvolid /etc/fstab
    [ "$status" -ne 0 ]
}

@test "host, time, locale, swap and services as configured, and the network is up" {
    [ "$(hostnamectl hostname)" = "$HOST_NAME" ]
    [ "$(timedatectl show -p Timezone --value)" = "$TIMEZONE" ]
    grep -qx "LANG=$LOCALE" /etc/locale.conf
    [ -z "${ZRAM_SIZE:-}" ] || swapon --show=NAME --noheadings | grep -qx /dev/zram0
    for s in "${SERVICES[@]}"; do systemctl is-enabled -q "$s"; done
    getent hosts archlinux.org
}

@test "the user is in wheel and has git and chezmoi; root is locked" {
    id -nG | grep -qw wheel
    # The wheel rule itself, not the test's passwordless one
    sudo -l -U "$USERNAME" | grep -qE '^\s+\(ALL : ALL\) ALL$'
    command -v git chezmoi
    [ "$(sudo passwd -S root | awk '{print $2}')" = L ]
}
