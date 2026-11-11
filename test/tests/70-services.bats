#!/usr/bin/env bats
# Docker has no running systemd: this checks the services are enabled (unit
# symlinks), not that they start.
load helpers

@test "grub-btrfsd and cronie are enabled" {
    systemctl is-enabled grub-btrfsd.service
    systemctl is-enabled cronie.service
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

@test "borg backup timer is installed and enabled" {
    skip_unless backup
    [ -x /usr/local/bin/borg-backup-run ]
    systemctl is-enabled borg-backup.timer
}

@test "timeshift takes daily snapshots" {
    [ "$(findmnt -no FSTYPE /)" = btrfs ] || skip "/ is not btrfs (Docker)"
    jq -e '.schedule_daily == "true" and .do_first_run == "false"' /etc/timeshift/timeshift.json
    grep -q 'timeshift --check' /etc/cron.d/timeshift-hourly
}
