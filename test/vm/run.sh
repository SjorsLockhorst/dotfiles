#!/bin/bash
# Test install/install.sh the way it runs on the laptop: boot the latest Arch
# ISO in a UEFI VM (QEMU + OVMF) with an NVMe disk, install with a config,
# boot the result (typing the LUKS passphrase at GRUB on the serial console)
# and run the bats tests in test/vm/tests on it.
#
# Usage: test/vm/run.sh [--config <file>] [--keep]
#   --config  the install config (default: install/fw13.conf)
#   --keep    leave the VM running after the tests. Get in with
#             ssh -i test/out/vm/id_ed25519 -p 2222 <user>@127.0.0.1
#             and stop it with: python3 test/vm/vm.py qmp test/out/vm/qmp.sock quit
#
# Needs qemu-base, edk2-ovmf, libisoburn and KVM. Logs, the serial consoles and
# a screenshot end up in test/out/vm/. The ISO is cached in ~/.cache/dotfiles-vm.
set -euo pipefail

VM_DIR=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$VM_DIR/../.." && pwd)
OUT=$REPO/test/out/vm
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-vm
MIRROR=https://geo.mirror.pkgbuild.com/iso
OVMF=/usr/share/edk2/x64
SSH_PORT=2222
# Throwaway secrets for a throwaway VM
LUKS_PASSPHRASE=vm-test-luks
USER_PASSWORD=vm-test-user

config=$REPO/install/fw13.conf
keep=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --config) config=$(realpath "$2"); shift ;;
        --keep) keep=1 ;;
        -h|--help) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done
encryption=$(source "$config"; echo "$ENCRYPTION")
user=$(source "$config"; echo "$USERNAME")

rm -rf "$OUT"
mkdir -p "$OUT" "$CACHE"
QEMU_PID=

cleanup() {
    local status=$?
    if [[ -n $QEMU_PID ]] && kill -0 "$QEMU_PID" 2>/dev/null; then
        python3 "$VM_DIR/vm.py" qmp "$OUT/qmp.sock" screendump \
            "{\"filename\": \"$OUT/screen.png\", \"format\": \"png\"}" || true
        if [[ $keep == 1 ]]; then
            echo "==> The VM keeps running (--keep): ssh -i $OUT/id_ed25519 -p $SSH_PORT $user@127.0.0.1"
        else
            kill "$QEMU_PID"
        fi
    fi
    echo "==> Logs in $OUT"
    exit "$status"
}
trap cleanup EXIT

# The latest ISO, checked every run against its checksum and Arch's release
# signature (the keyring pacman already trusts).
fetch_iso() {
    local name date
    name=$(curl -fsSL "$MIRROR/latest/sha256sums.txt" | awk '$2 ~ /^archlinux-[0-9.]+-x86_64\.iso$/ { print $2; exit }')
    date=${name#archlinux-}
    date=${date%-x86_64.iso}
    ISO=$CACHE/$name
    if [[ ! -f $ISO ]]; then
        echo "==> Downloading $name"
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
    ssh-keygen -q -t ed25519 -N '' -C vm-test -f "$OUT/id_ed25519"
    mkdir "$OUT/cidata"
    : >"$OUT/cidata/meta-data" # NoCloud ignores the volume without it
    printf '#cloud-config\nusers:\n  - name: root\n    ssh_authorized_keys:\n      - %s\n' \
        "$(cat "$OUT/id_ed25519.pub")" >"$OUT/cidata/user-data"
    xorriso -as genisoimage -output "$OUT/cidata.iso" -V CIDATA -J -r "$OUT/cidata" 2>"$OUT/cidata.log"
}

# start_vm <phase> [qemu args]: the Framework stand-in, in the background.
# NVMe with 4K sectors like the laptop's disk; its own UEFI variables, so the
# boot entry grub-install makes is what boots it next time (no bootindex on
# the disk, which would override that). No PXE ROM on the network card.
start_vm() {
    local phase=$1
    shift
    qemu-system-x86_64 -name "dotfiles-vm-$phase" \
        -machine q35,accel=kvm -cpu host -smp 4 -m 8G \
        -drive if=pflash,format=raw,readonly=on,file="$OVMF/OVMF_CODE.4m.fd" \
        -drive if=pflash,format=raw,file="$OUT/vars.fd" \
        -drive file="$OUT/disk.qcow2",if=none,id=disk,discard=unmap \
        -device nvme,drive=disk,serial=fw13,logical_block_size=4096,physical_block_size=4096 \
        -netdev user,id=net,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22 \
        -device virtio-net-pci,netdev=net,romfile= \
        -display none -vga std \
        -qmp unix:"$OUT/qmp.sock",server=on,wait=off \
        "$@" >"$OUT/$phase-qemu.log" 2>&1 &
    QEMU_PID=$!
}

vm_ssh() {
    local login=$1
    shift
    ssh -q -i "$OUT/id_ed25519" -p "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout=5 \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$login@127.0.0.1" "$@"
}

vm_scp() {
    local login=$1 dest=$2
    shift 2
    scp -q -r -i "$OUT/id_ed25519" -P "$SSH_PORT" -o BatchMode=yes \
        -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$@" "$login@127.0.0.1:$dest"
}

wait_ssh() {
    local login=$1 timeout=$2 start=$SECONDS
    until vm_ssh "$login" true 2>/dev/null; do
        kill -0 "$QEMU_PID" 2>/dev/null || { echo "QEMU exited: $(tail -3 "$OUT"/*-qemu.log)"; return 1; }
        ((SECONDS - start < timeout)) || { echo "No SSH as $login within ${timeout}s"; return 1; }
        sleep 3
    done
}

wait_poweroff() {
    local timeout=$1 start=$SECONDS
    while kill -0 "$QEMU_PID" 2>/dev/null; do
        ((SECONDS - start < timeout)) || { echo "Still running after ${timeout}s"; return 1; }
        sleep 2
    done
    QEMU_PID=
}

fetch_iso
make_cidata
dns=$(python3 "$VM_DIR/vm.py" dns)
qemu-img create -q -f qcow2 "$OUT/disk.qcow2" 80G
cp "$OVMF/OVMF_VARS.4m.fd" "$OUT/vars.fd"

echo "==> Installing from $(basename "$ISO") with $(basename "$config")"
start=$SECONDS
start_vm install \
    -drive file="$ISO",media=cdrom,if=none,id=iso,readonly=on -device ide-cd,drive=iso,bus=ide.0,bootindex=0 \
    -drive file="$OUT/cidata.iso",media=cdrom,if=none,id=cidata,readonly=on -device ide-cd,drive=cidata,bus=ide.1 \
    -chardev socket,id=serial,path="$OUT/serial.sock",server=on,wait=off,logfile="$OUT/install-serial.log" \
    -serial chardev:serial
wait_ssh root 300
# QEMU's DNS forwarder only tries the host's first nameserver, which may be down
vm_ssh root "resolvectl dns \$(ip -o route show default | awk '{print \$5; exit}') $dns"
mkdir "$OUT/hook"
cp "$VM_DIR/hook/run" "$OUT/hook/"
cp "$OUT/id_ed25519.pub" "$OUT/hook/test-key.pub"
echo "$dns" >"$OUT/hook/dns"
vm_scp root /root/ "$REPO/install" "$OUT/hook"
vm_scp root /root/install.conf "$config"
vm_ssh root "LUKS_PASSPHRASE=$LUKS_PASSPHRASE USER_PASSWORD=$USER_PASSWORD \
    /root/install/install.sh --unattended --post-install /root/hook /root/install.conf" \
    >"$OUT/install.log" 2>&1 || { tail -20 "$OUT/install.log"; exit 1; }
vm_ssh root poweroff || true
wait_poweroff 120
echo "==> Installed in $((SECONDS - start))s (log: install.log)"

echo "==> Booting the installed system"
start=$SECONDS
if [[ $encryption == luks ]]; then
    # wait=on: QEMU starts once vm.py listens, so it can't miss GRUB's prompt.
    start_vm boot \
        -chardev socket,id=serial,path="$OUT/serial.sock",server=on,wait=on,logfile="$OUT/boot-serial.log" \
        -serial chardev:serial
    python3 "$VM_DIR/vm.py" type "$OUT/serial.sock" 'Enter passphrase' "$LUKS_PASSPHRASE" 120
else
    start_vm boot -serial file:"$OUT/boot-serial.log"
fi
wait_ssh "$user" 300
echo "==> Booted in $((SECONDS - start))s"

echo "==> Running the tests"
vm_ssh "$user" mkdir -p vm-tests
vm_scp "$user" vm-tests/ "$VM_DIR/tests"
vm_scp "$user" vm-tests/install.conf "$config"
vm_ssh "$user" bats --print-output-on-failure --timing vm-tests/tests | tee "$OUT/tests.log"
