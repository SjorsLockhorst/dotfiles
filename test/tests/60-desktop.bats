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
