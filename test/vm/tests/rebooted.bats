#!/usr/bin/env bats
# After chezmoi init --apply and a reboot, in the VM of test/vm/run.sh: what
# only a real boot shows, which Docker can't (no systemd, LUKS, GRUB, btrfs).
# Checks follow the install config (../install.conf).

setup() {
    # shellcheck source=../../../install/fw13.conf
    source "$BATS_TEST_DIRNAME/../install.conf"
}

@test "it boots to a running system with everything the dotfiles turned on" {
    run systemctl is-system-running --wait
    systemctl --failed --no-legend
    [ "$output" = running ]
}

@test "TRIM reaches the SSD through LUKS" {
    [ "$ENCRYPTION" = luks ] || skip "not encrypted"
    grep -q 'cryptdevice=[^ ]*:root:allow-discards ' /proc/cmdline
    lsblk --discard /dev/mapper/root
    [ "$(lsblk -dno DISC-GRAN /dev/mapper/root | tr -d ' ')" != 0B ]
    [ "$FILESYSTEM" != btrfs ] || findmnt -no OPTIONS / | grep -q 'discard=async'
}

@test "GRUB's config loads the theme and every font it ships" {
    theme=/usr/share/grub/themes/arch-silence
    sudo grep -q "set theme=.*$theme/theme.txt" /boot/grub/grub.cfg
    for f in "$theme"/*.pf2; do
        sudo grep -q "loadfont .*${f#/usr}" /boot/grub/grub.cfg
    done
}

@test "the login screen runs our theme without QML errors" {
    systemctl is-active -q sddm
    journalctl -b --no-pager | grep 'sddm-greeter' | tee "$BATS_TEST_TMPDIR/greeter"
    [ -s "$BATS_TEST_TMPDIR/greeter" ]
    # Script and load errors; a missing image (QML Image: Cannot open) is a warning
    run grep -E 'Main\.qml:[0-9]+(:[0-9]+)?: .*(Error|is not defined|is not installed|is not a type|unavailable)' "$BATS_TEST_TMPDIR/greeter"
    [ "$status" -ne 0 ]
}

@test "timeshift can snapshot the root" {
    [ "$FILESYSTEM" = btrfs ] || skip "timeshift's btrfs mode needs btrfs"
    sudo timeshift --create --comments vm-test --scripted
    sudo timeshift --list --scripted | grep -q vm-test
}

@test "a new login has the docker group, and docker answers" {
    id -nG | grep -qw docker
    docker info >/dev/null
}
