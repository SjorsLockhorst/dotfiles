#!/usr/bin/env bats
# Docker has no running systemd: this checks the services are enabled (unit
# symlinks), not that they start.
load helpers

@test "grub-btrfsd is enabled" {
    systemctl is-enabled grub-btrfsd.service
}

@test "desktop services are enabled" {
    skip_unless hyprland
    for s in sddm.service NetworkManager.service bluetooth.service power-profiles-daemon.service \
        tailscaled.service docker.socket; do
        echo "$s: $(systemctl is-enabled "$s" 2>&1)"
        systemctl is-enabled -q "$s"
    done
}

@test "the user can use docker without sudo" {
    skip_unless hyprland
    id -nG "$(id -un)" | grep -qw docker
}
