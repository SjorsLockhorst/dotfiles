#!/usr/bin/env bats
# Docker has no GPU or display: only check that configs parse.
load helpers

setup() {
    skip_unless hyprland
}

@test "hyprland config has no errors" {
    # Normally set up by the login session
    export XDG_RUNTIME_DIR="$BATS_TEST_TMPDIR/run"
    mkdir -m 700 "$XDG_RUNTIME_DIR"
    run Hyprland --verify-config
    echo "$output"
    [ "$status" -eq 0 ]
}

@test "waybar config and modules are valid JSON" {
    for f in config modules.json; do
        # JSONC: drop // comment lines
        grep -vE '^\s*//' ~/.config/waybar/"$f" | jq empty
    done
}

@test "rofi config parses" {
    run rofi -dump-config
    echo "$output"
    [ "$status" -eq 0 ]
}

@test "sddm uses our theme, coloured by theme-set" {
    grep -qx 'Current=desktop' /etc/sddm.conf.d/10-theme.conf
    # /etc/sddm.conf would win over sddm.conf.d (a `! cmd` line can't fail a bats test)
    run grep '^Current=' /etc/sddm.conf
    [ "$status" -ne 0 ]
    theme=/usr/share/sddm/themes/desktop
    # A QML syntax error leaves a black login screen; warnings are fine
    # (sddm, config, userModel are injected by the greeter)
    /usr/lib/qt6/bin/qmllint "$theme/Main.qml" >/dev/null
    # The greeter (user sddm) can't read ~, so theme-set copies to here
    [ "$(readlink "$theme/theme.conf.user")" = /var/lib/sddm-theme/theme.conf ]
    grep -qE '^accent="#[0-9a-fA-F]{6}"$' /var/lib/sddm-theme/theme.conf
    [ "$(stat -c %a /var/lib/sddm-theme/theme.conf /var/lib/sddm-theme/background)" = $'644\n644' ]
}

@test "grub uses arch-silence with the fonts it ships" {
    theme=/usr/share/grub/themes/arch-silence
    grep -qx "GRUB_THEME=\"$theme/theme.txt\"" /etc/default/grub
    # GRUB silently falls back to its tiny default font when a name doesn't match.
    mapfile -t names < <(grep -oE 'font[^=:]*[=:] *"[^"]+"' "$theme/theme.txt" | cut -d'"' -f2)
    [ "${#names[@]}" -gt 0 ]
    for n in "${names[@]}"; do
        echo "font: $n"
        file -b "$theme"/*.pf2 | grep -qxF "GRUB2 font \"$n\""
    done
}

@test "the login screen, hyprlock and local logins take a fingerprint" {
    for f in sddm hyprlock system-local-login; do
        # pam_fprintd has to come before the include that asks for the password
        fp=$(grep -n -m1 -E '^auth\s+sufficient\s+pam_fprintd\.so' "/etc/pam.d/$f" | cut -d: -f1)
        inc=$(grep -n -m1 -E '^auth\s+include' "/etc/pam.d/$f" | cut -d: -f1)
        echo "$f: pam_fprintd on line ${fp:-none}, include on line $inc"
        [ -n "$fp" ] && [ "$fp" -lt "$inc" ]
    done
}

@test "Steam's multilib repo is on" {
    pacman-conf --repo-list | grep -qx multilib
}

@test "a new session has no memlock limit for the NPU" {
    # As in site.yml: never in Docker (own /dev, can't raise memlock)
    [ -d /sys/bus/pci/drivers/amdxdna ] && [ -e /dev/accel/accel0 ] || skip "no usable AMD NPU"
    # sudo opens a PAM session, which applies limits.d
    [ "$(sudo -u "$(id -un)" bash -c 'ulimit -l')" = unlimited ]
}

@test "waybar-backup reports the status files" {
    skip_unless hyprland
    d=$BATS_TEST_TMPDIR now=$(date +%s)
    echo "{\"last_attempt\": $now, \"result\": \"ok\", \"last_success\": $now}" >"$d/storagebox.json"
    echo "{\"last_attempt\": $now, \"result\": \"unreachable\", \"last_success\": $((now - 3 * 86400))}" >"$d/nas.json"
    run env BORG_STATUS_DIR="$d" ~/.local/bin/waybar-backup
    echo "$output"
    jq -e '.class == "warning" and (.tooltip | contains("last success 3d ago"))' <<<"$output"
}
