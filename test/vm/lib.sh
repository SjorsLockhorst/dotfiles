# Shared by test/vm/run.sh and test/vm/show.sh (sourced).

CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles-vm
# What run.sh --save keeps and show.sh boots: the disk, UEFI variables, SSH key
# and install config of the last fully passing run.
SAVED=$CACHE/saved
OVMF=/usr/share/edk2/x64
SSH_PORT=2222
# Throwaway secrets for a throwaway VM
LUKS_PASSPHRASE=vm-test-luks
USER_PASSWORD=vm-test-user

# usage: the script's header comment
usage() { awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"; }

require_virgl() {
    [[ -e /usr/lib/qemu/hw-display-virtio-vga-gl.so ]] || {
        echo "Needs QEMU's virgl GPU (Hyprland needs 3D acceleration in a VM):" >&2
        echo "  sudo pacman -S --needed qemu-desktop" >&2
        exit 1
    }
}

refuse_if_running() {
    if pgrep -f '^qemu-system-x86_64 -name dotfiles-vm-' >/dev/null; then
        echo "A dotfiles VM is already running (it holds port $SSH_PORT)." >&2
        exit 1
    fi
}

# qemu_machine <disk> <uefi vars> <qmp socket> <gpu>: sets QEMU_MACHINE, the
# Framework stand-in. NVMe with 4K sectors like the laptop's disk, and its own
# UEFI variables, so the boot entry grub-install makes is what boots it next
# time (no bootindex on the disk, which would override that). No PXE ROM on the
# network card. Both GPUs ask for the laptop's 2880x1920:
#   vga    QMP screenshots of everything, and the firmware (so GRUB) gets
#          2880x1920. Add -display none.
#   virgl  3D acceleration, which Hyprland needs in a VM, but QMP can't
#          screenshot what Linux draws, and the firmware falls back to 1280x800.
#          Add a -display that can do OpenGL.
qemu_machine() {
    local gpu
    case $4 in
        vga) gpu=(-device VGA,xres=2880,yres=1920,vgamem_mb=32) ;;
        virgl) gpu=(-device virtio-vga-gl,xres=2880,yres=1920) ;;
    esac
    QEMU_MACHINE=(
        -machine q35,accel=kvm -cpu host -smp 8 -m 8G
        -drive if=pflash,format=raw,readonly=on,file="$OVMF/OVMF_CODE.4m.fd"
        -drive if=pflash,format=raw,file="$2"
        -drive file="$1",if=none,id=disk,discard=unmap
        -device nvme,drive=disk,serial=fw13,logical_block_size=4096,physical_block_size=4096
        -netdev user,id=net,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22
        -device virtio-net-pci,netdev=net,romfile=
        "${gpu[@]}"
        -qmp unix:"$3",server=on,wait=off
    )
}

# vm_ssh [command]: as $login, with $SSH_KEY
vm_ssh() {
    ssh -q -i "$SSH_KEY" -p "$SSH_PORT" -o BatchMode=yes -o ConnectTimeout=5 \
        -o ServerAliveInterval=30 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        "$login@127.0.0.1" "$@"
}

# set_vm_dns <nameserver>: QEMU's DNS forwarder only tries the host's first
# nameserver, which may be down. Replaces the hook's choice, for when the VM
# boots on another network than it was installed on.
set_vm_dns() {
    vm_ssh "printf '[global-dns-domain-*]\nservers=%s\n' $1 \
        | sudo tee /etc/NetworkManager/conf.d/90-vm-test-dns.conf >/dev/null && sudo nmcli general reload"
}
