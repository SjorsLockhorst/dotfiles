#!/bin/bash
# Boot the VM that test/vm/run.sh --save kept, in a window: GRUB (the LUKS
# passphrase is typed for you), the login screen, then Hyprland with the
# dotfiles. Log in as the install config's user with password vm-test-user.
#
# Usage: test/vm/show.sh [--persist]
#   --persist  keep what you change in the saved VM. By default a session runs
#              on a throwaway layer over it, deleted when the window closes.
#
# SSH alongside: ssh -i ~/.cache/dotfiles-vm/saved/id_ed25519 -p 2222 <user>@127.0.0.1
# Your own Hyprland takes SUPER shortcuts before the window sees them (its FAQ:
# a passthrough submap). Needs qemu-desktop.
set -euo pipefail

VM_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=lib.sh
source "$VM_DIR/lib.sh"
SSH_KEY=$SAVED/id_ed25519

persist=0
case ${1:-} in
    "") ;;
    --persist) persist=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
esac
[[ -f $SAVED/disk.qcow2 ]] || { echo "Nothing saved yet: run test/vm/run.sh --save first" >&2; exit 1; }
require_virgl
refuse_if_running
login=$(source "$SAVED/install.conf"; echo "$USERNAME")
encryption=$(source "$SAVED/install.conf"; echo "$ENCRYPTION")

run=$(mktemp -d "$CACHE/show.XXXXXX")
trap 'kill $(jobs -p) 2>/dev/null; rm -rf "$run"' EXIT
if [[ $persist == 1 ]]; then
    disk=$SAVED/disk.qcow2
    vars=$SAVED/vars.fd
else
    qemu-img create -q -f qcow2 -b "$SAVED/disk.qcow2" -F qcow2 "$run/disk.qcow2"
    cp "$SAVED/vars.fd" "$run/vars.fd"
    disk=$run/disk.qcow2
    vars=$run/vars.fd
fi

qemu_machine "$disk" "$vars" "$run/qmp.sock" virgl
args=("${QEMU_MACHINE[@]}" -display gtk,gl=on,zoom-to-fit=on)
if [[ $encryption == luks ]]; then
    # wait=on: QEMU starts once vm.py listens, so it can't miss GRUB's prompt.
    args+=(-chardev socket,id=serial,path="$run/serial.sock",server=on,wait=on -serial chardev:serial)
    python3 "$VM_DIR/vm.py" type "$run/serial.sock" --wait 'Enter passphrase' \
        --text "$LUKS_PASSPHRASE" --timeout 300 &
fi

# The nameserver the VM got at install may not answer on this network. Once
# SSH is up, give it one that does (in the background: the window comes first).
fix_dns() {
    local dns
    dns=$(python3 "$VM_DIR/vm.py" dns) || return 0
    for _ in $(seq 100); do
        set_vm_dns "$dns" 2>/dev/null && return 0
        sleep 3
    done
}
fix_dns &

echo "==> Saved $(stat -c %y "$SAVED/disk.qcow2" | cut -d. -f1), dotfiles $(cat "$SAVED/revision" 2>/dev/null || echo '?')$([[ $persist == 1 ]] && echo ', changes are kept')"
echo "    log in as $login, password $USER_PASSWORD"
echo "    ssh -i $SSH_KEY -p $SSH_PORT $login@127.0.0.1"
qemu-system-x86_64 -name dotfiles-vm-show "${args[@]}"
