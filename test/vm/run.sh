#!/bin/bash
# A reinstall of this laptop in a UEFI VM (QEMU + OVMF; an NVMe disk with 4K
# sectors and the 2880x1920 screen of the Framework), from the latest Arch ISO,
# in five phases:
#   install   install/install.sh with a config, over SSH (the ISO's cloud-init
#             takes our key)
#   base      boot it, typing the LUKS passphrase at GRUB on the serial
#             console, then test/vm/tests/base.bats
#   dotfiles  chezmoi init --apply, then test/tests (test/vm/dotfiles.sh)
#   reboot    boot again, then test/vm/tests/rebooted.bats: what only a real
#             boot shows (TRIM through LUKS, GRUB's theme, the login screen)
#   hyprland  boot on a virgl GPU (Hyprland needs 3D acceleration in a VM), log
#             in, then test/vm/tests/hyprland.bats
#
# Usage: test/vm/run.sh [--config <file>] [--base-only] [--remote [url]] [--save] [--keep]
#   --config     the install config (default: install/fw13.conf)
#   --base-only  stop after the base phase
#   --remote     the dotfiles from the pushed repo (default: GitHub) instead of
#                the working tree
#   --save       when everything passes, shut the VM down and keep it for
#                test/vm/show.sh (replaces the last saved one)
#   --keep       leave the VM running at the end, or where it failed (the
#                command to get in is printed); stop it with
#                python3 test/vm/vm.py qmp test/out/vm/qmp.sock quit
#
# test/out/vm/ gets each phase's log, the serial console, the journal and
# failed units of every boot, and screenshots: grub.png, login.png,
# desktop.png, and failed.png when something fails. Needs qemu-desktop,
# edk2-ovmf, libisoburn, KVM and the age key. The ISO is cached in
# ~/.cache/dotfiles-vm.
set -euo pipefail

VM_DIR=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$VM_DIR/../.." && pwd)
# shellcheck source=lib.sh
source "$VM_DIR/lib.sh"
OUT=$REPO/test/out/vm
SSH_KEY=$OUT/id_ed25519
KEY=$HOME/.config/chezmoi/key.txt
MIRROR=https://geo.mirror.pkgbuild.com/iso

config=$REPO/install/fw13.conf
base_only=0
remote=
save=0
keep=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --config) config=$(realpath "$2"); shift ;;
        --base-only) base_only=1 ;;
        --remote)
            if [[ ${2:-} && $2 != --* ]]; then remote=$2; shift
            else remote=https://github.com/SjorsLockhorst/dotfiles.git; fi ;;
        --save) save=1 ;;
        --keep) keep=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
encryption=$(source "$config"; echo "$ENCRYPTION")
user=$(source "$config"; echo "$USERNAME")
[[ -f $KEY ]] || { echo "No age key at $KEY" >&2; exit 1; }
require_virgl
refuse_if_running

rm -rf "$OUT"
mkdir -p "$OUT" "$CACHE"
QEMU_PID=
PHASE=setup
login=root

vm_running() { [[ -n $QEMU_PID ]] && kill -0 "$QEMU_PID" 2>/dev/null; }
screenshot() { python3 "$VM_DIR/vm.py" screenshot "$OUT/qmp.sock" "$OUT/$1.png" 2>/dev/null || true; }

cleanup() {
    local status=$?
    if [[ $status != 0 && $PHASE != done ]]; then
        echo "==> $PHASE FAILED"
        if vm_running; then
            screenshot failed
            [[ $login == root ]] || collect "$PHASE" || true
        fi
    fi
    if vm_running && [[ $keep == 1 ]]; then
        echo "==> The VM keeps running: ssh -i $SSH_KEY -p $SSH_PORT $login@127.0.0.1"
    else
        if vm_running; then kill "$QEMU_PID"; wait "$QEMU_PID" 2>/dev/null || true; fi
        # After the dotfiles phase this disk holds the decrypted SSH key.
        rm -f "$OUT/disk.qcow2" "$OUT/vars.fd"
    fi
    echo "==> Logs in $OUT"
    exit "$status"
}
trap cleanup EXIT

phase() {
    PHASE=$1
    PHASE_START=$SECONDS
    echo "==> $1: $2"
}
phase_ok() { echo "    ok in $((SECONDS - PHASE_START))s"; }

# The latest ISO, checked every run against its checksum and Arch's release
# signature (the keyring pacman already trusts).
fetch_iso() {
    local name date
    name=$(curl -fsSL "$MIRROR/latest/sha256sums.txt" | awk '$2 ~ /^archlinux-[0-9.]+-x86_64\.iso$/ { print $2; exit }')
    date=${name#archlinux-}
    date=${date%-x86_64.iso}
    ISO=$CACHE/$name
    if [[ ! -f $ISO ]]; then
        echo "    downloading $name"
        curl -fL -o "$ISO.part" "$MIRROR/$date/$name"
        mv "$ISO.part" "$ISO"
    fi
    [[ -f $ISO.sig ]] || curl -fsSL -o "$ISO.sig" "$MIRROR/$date/$name.sig"
    [[ -f $CACHE/sha256sums-$date.txt ]] || curl -fsSL -o "$CACHE/sha256sums-$date.txt" "$MIRROR/$date/sha256sums.txt"
    (cd "$CACHE" && grep " $name\$" "sha256sums-$date.txt" | sha256sum -c --quiet)
    # gpgv wants a binary keyring; pacman's is armored
    gpg --dearmor </usr/share/pacman/keyrings/archlinux.gpg >"$OUT/archlinux-keyring.gpg"
    gpgv --keyring "$OUT/archlinux-keyring.gpg" "$ISO.sig" "$ISO" 2>"$OUT/iso-signature.log" ||
        { cat "$OUT/iso-signature.log"; exit 1; }
}

# The ISO's cloud-init reads a CIDATA volume: here only our SSH key for root.
make_cidata() {
    ssh-keygen -q -t ed25519 -N '' -C vm-test -f "$SSH_KEY"
    mkdir "$OUT/cidata"
    : >"$OUT/cidata/meta-data" # NoCloud ignores the volume without it
    printf '#cloud-config\nusers:\n  - name: root\n    ssh_authorized_keys:\n      - %s\n' \
        "$(cat "$SSH_KEY.pub")" >"$OUT/cidata/user-data"
    xorriso -as genisoimage -output "$OUT/cidata.iso" -V CIDATA -J -r "$OUT/cidata" 2>"$OUT/cidata.log"
}

# start_vm <name> <vga|virgl> [qemu args]: the VM of lib.sh, without a window,
# in the background
start_vm() {
    local name=$1 gpu=$2 display=none
    shift 2
    [[ $gpu == vga ]] || display=egl-headless
    qemu_machine "$OUT/disk.qcow2" "$OUT/vars.fd" "$OUT/qmp.sock" "$gpu"
    qemu-system-x86_64 -name "dotfiles-vm-$name" "${QEMU_MACHINE[@]}" -display "$display" \
        "$@" >"$OUT/$name-qemu.log" 2>&1 &
    QEMU_PID=$!
}

vm_scp() {
    local dest=$1
    shift
    scp -q -r -i "$SSH_KEY" -P "$SSH_PORT" -o BatchMode=yes \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$@" "$login@127.0.0.1:$dest"
}

wait_ssh() {
    local timeout=$1 start=$SECONDS
    until vm_ssh true 2>/dev/null; do
        vm_running || { echo "    QEMU exited: $(tail -3 "$OUT"/*-qemu.log)"; return 1; }
        ((SECONDS - start < timeout)) || { echo "    no SSH as $login within ${timeout}s"; return 1; }
        sleep 3
    done
}

# shut_down: power off cleanly and wait for QEMU to exit (root on the ISO
# may have no sudo)
shut_down() {
    vm_ssh "sudo -n poweroff 2>/dev/null || poweroff" 2>/dev/null || true
    local start=$SECONDS
    while vm_running; do
        ((SECONDS - start < 120)) || { echo "    still running 120s after poweroff"; return 1; }
        sleep 2
    done
    QEMU_PID=
}

# unlock [screenshot]: GRUB asks the passphrase to read /boot (the initramfs
# then uses the keyfile). Its menu shows for GRUB_TIMEOUT (5s) once the slot
# opened: the moment for a screenshot.
unlock() {
    python3 "$VM_DIR/vm.py" type "$OUT/serial.sock" --wait 'Enter passphrase' \
        --text "$LUKS_PASSPHRASE" --then 'Slot "[0-9]+" opened' --timeout 300 || return 1
    if [[ -n ${1:-} ]]; then
        sleep 2
        screenshot "$1"
    fi
}

# collect <name>: the journal and failed units of the running boot
collect() {
    vm_ssh "sudo journalctl -b --no-pager" >"$OUT/$1-journal.log" 2>&1 || return 1
    vm_ssh "systemctl --failed --no-legend" >"$OUT/$1-failed-units.log" 2>&1 || true
}

# run_bats <name> <path in the VM>
run_bats() {
    vm_ssh "bats --print-output-on-failure --timing $2" | tee "$OUT/$1-tests.log"
}

# Log in to Hyprland as the login screen would: a test-only autologin, removed
# again once Hyprland runs, so a saved state still shows the login screen.
log_in_to_hyprland() {
    local conf=/etc/sddm.conf.d/99-vm-test-autologin.conf start=$SECONDS
    vm_ssh "printf '[Autologin]\nUser=%s\nSession=hyprland-uwsm.desktop\n' $user \
        | sudo tee $conf >/dev/null && sudo systemctl restart sddm" || return 1
    until vm_ssh "hyprctl -i 0 version" >/dev/null 2>&1; do
        if ((SECONDS - start > 120)); then
            echo "    Hyprland didn't start within 120s"
            vm_ssh "sudo rm -f $conf"
            return 1
        fi
        sleep 3
    done
    vm_ssh "sudo rm $conf" || return 1
    # waybar and the wallpaper come up a few seconds after Hyprland. QMP can't
    # screenshot a virgl screen: grim in the session can.
    sleep 10
    vm_ssh 'WAYLAND_DISPLAY=$(basename "$(ls -d "$XDG_RUNTIME_DIR"/wayland-? | head -1)") grim -' \
        >"$OUT/desktop.png" || true
}

# The VM as the passing run left it, for show.sh
save_state() {
    echo "==> save: shut down and keep the VM for test/vm/show.sh"
    shut_down || return 1
    rm -rf "$SAVED"
    mkdir -p -m 700 "$SAVED"
    mv "$OUT/disk.qcow2" "$OUT/vars.fd" "$SSH_KEY" "$SSH_KEY.pub" "$SAVED/"
    cp "$config" "$SAVED/install.conf"
    git -C "$REPO" describe --always --dirty >"$SAVED/revision"
    echo "    $SAVED ($(du -h "$SAVED/disk.qcow2" | cut -f1), dotfiles $(cat "$SAVED/revision")): test/vm/show.sh"
}

install_phase() {
    phase install "install/install.sh $(basename "$config") from $(basename "$ISO")"
    start_vm install vga \
        -drive file="$ISO",media=cdrom,if=none,id=iso,readonly=on -device ide-cd,drive=iso,bus=ide.0,bootindex=0 \
        -drive file="$OUT/cidata.iso",media=cdrom,if=none,id=cidata,readonly=on -device ide-cd,drive=cidata,bus=ide.1 \
        -chardev socket,id=serial,path="$OUT/serial.sock",server=on,wait=off,logfile="$OUT/install-serial.log" \
        -serial chardev:serial
    wait_ssh 300
    # QEMU's DNS forwarder only tries the host's first nameserver, which may be down
    local dns
    dns=$(python3 "$VM_DIR/vm.py" dns)
    vm_ssh "resolvectl dns \$(ip -o route show default | awk '{print \$5; exit}') $dns"
    mkdir "$OUT/hook"
    cp "$VM_DIR/hook/run" "$OUT/hook/"
    cp "$SSH_KEY.pub" "$OUT/hook/test-key.pub"
    echo "$dns" >"$OUT/hook/dns"
    vm_scp /root/ "$REPO/install" "$OUT/hook"
    vm_scp /root/install.conf "$config"
    vm_ssh "LUKS_PASSPHRASE=$LUKS_PASSPHRASE USER_PASSWORD=$USER_PASSWORD \
        /root/install/install.sh --unattended --post-install /root/hook /root/install.conf" \
        >"$OUT/install.log" 2>&1 || { tail -20 "$OUT/install.log"; return 1; }
    shut_down
    phase_ok
}

# boot_vm <name> <vga|virgl>: start the installed system and get it past GRUB
boot_vm() {
    if [[ $encryption == luks ]]; then
        # wait=on: QEMU starts once vm.py listens, so it can't miss GRUB's prompt.
        start_vm "$1" "$2" \
            -chardev socket,id=serial,path="$OUT/serial.sock",server=on,wait=on,logfile="$OUT/$1-serial.log" \
            -serial chardev:serial
        unlock
    else
        start_vm "$1" "$2" -serial file:"$OUT/$1-serial.log"
    fi
}

base_phase() {
    phase base "boot the installed system, test/vm/tests/base.bats"
    login=$user
    boot_vm boot vga
    wait_ssh 300
    vm_ssh mkdir -p vm-tests
    vm_scp vm-tests/ "$VM_DIR/tests"
    vm_scp vm-tests/install.conf "$config"
    collect base
    run_bats base vm-tests/tests/base.bats
    phase_ok
}

# Runs with errexit off (called with ||): every step checks its own status.
dotfiles_phase() {
    phase dotfiles "chezmoi init --apply, then test/tests (test/vm/dotfiles.sh)"
    local data email prompt_bool status=0
    data=$(chezmoi data --format json) || return 1
    email=$(jq -r .email <<<"$data")
    prompt_bool=$(jq -r '[to_entries[] | select(.value | type == "boolean")
        | "\(.key)=\(.value)"] | join(",")' <<<"$data")
    # Where dotfiles.sh and test/tests look: the repo in /src, the tests in
    # /tests, the logs in /out. The age key goes to /run, a RAM disk.
    vm_ssh "sudo install -d -o $user -g $user /src /out \
        && sudo install -D -m 600 -o $user /dev/stdin /run/secrets/key.txt \
        && sudo ln -sfn /src/test/tests /tests" <"$KEY" || return 1
    tar -C "$REPO" --exclude=./test/out -cf - . | vm_ssh "tar -C /src -xf -" || return 1
    echo "    takes ~15 min; follow it with: tail -f $OUT/dotfiles.log"
    vm_ssh "CHEZMOI_EMAIL='$email' CHEZMOI_PROMPT_BOOL='$prompt_bool' DOTFILES_REMOTE='$remote' \
        bash /src/test/vm/dotfiles.sh" >"$OUT/dotfiles.log" 2>&1 || status=$?
    mkdir -p "$OUT/dotfiles"
    vm_ssh "tar -C /out -cf - ." | tar -C "$OUT/dotfiles" -xf - || true
    collect dotfiles || true
    echo "    apply: exit $(cat "$OUT/dotfiles/apply.status" 2>/dev/null || echo '?') (dotfiles/apply.log)"
    grep -E '^not ok' "$OUT/dotfiles/tests.log" 2>/dev/null | sed 's/^/    /' || true
    # What this machine has that a reinstall would not bring back (some only
    # look missing: in the VM they came in as a dependency)
    if [[ -f $OUT/dotfiles/packages-explicit.txt ]]; then
        comm -23 <(pacman -Qqe | sort) <(sort "$OUT/dotfiles/packages-explicit.txt") >"$OUT/packages-not-in-dotfiles.txt"
        echo "    $(wc -l <"$OUT/packages-not-in-dotfiles.txt") packages on this machine are not installed by the dotfiles (packages-not-in-dotfiles.txt)"
    fi
    [[ $status == 0 ]] || return 1
    phase_ok
}

# Runs with errexit off (called with ||): every step checks its own status.
reboot_phase() {
    phase reboot "boot again, test/vm/tests/rebooted.bats"
    if [[ $encryption == luks ]]; then
        # Listen for GRUB's prompt before the reboot starts
        unlock grub &
        local unlocker=$!
        # The reboot cuts this SSH session: that's expected
        vm_ssh "sudo systemctl reboot" 2>/dev/null || true
        wait "$unlocker" || return 1
    else
        vm_ssh "sudo systemctl reboot" 2>/dev/null || true
        sleep 15
    fi
    wait_ssh 300 || return 1
    # sddm draws the login screen a few seconds after it starts
    if vm_ssh "systemctl is-active -q sddm"; then
        sleep 5
        screenshot login
    fi
    collect rebooted || return 1
    run_bats rebooted vm-tests/tests/rebooted.bats || return 1
    phase_ok
}

# Runs with errexit off (called with ||): every step checks its own status.
hyprland_phase() {
    phase hyprland "boot on a virgl GPU, log in to Hyprland, test/vm/tests/hyprland.bats"
    shut_down || return 1
    boot_vm hyprland virgl || return 1
    wait_ssh 300 || return 1
    log_in_to_hyprland || return 1
    collect hyprland || return 1
    run_bats hyprland vm-tests/tests/hyprland.bats || return 1
    phase_ok
}

phase setup "ISO, cloud-init volume, empty disk"
fetch_iso
make_cidata
qemu-img create -q -f qcow2 "$OUT/disk.qcow2" 80G
cp "$OVMF/OVMF_VARS.4m.fd" "$OUT/vars.fd"
phase_ok

install_phase
base_phase
[[ $base_only == 0 ]] || exit 0

# A failed dotfiles phase still gets rebooted: the next boot shows more.
failed=()
dotfiles_phase || failed+=(dotfiles)
if vm_running; then reboot_phase || failed+=(reboot); else failed+=(reboot); fi
if vm_running; then hyprland_phase || failed+=(hyprland); else failed+=(hyprland); fi
PHASE=done
[[ ${#failed[@]} == 0 ]] || { vm_running && screenshot failed; echo "==> FAILED: ${failed[*]}"; exit 1; }
[[ $save == 0 ]] || save_state
