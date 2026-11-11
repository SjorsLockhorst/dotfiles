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

@test "sddm uses the catppuccin theme" {
    grep -q '^Current=catppuccin' /etc/sddm.conf
    [ -d /usr/share/sddm/themes ]
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
