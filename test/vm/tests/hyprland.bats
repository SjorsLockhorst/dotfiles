#!/usr/bin/env bats
# Hyprland with the dotfiles, in the VM of test/vm/run.sh: booted on a virgl
# GPU (Hyprland needs 3D acceleration in a VM) and logged in by run.sh
# (log_in_to_hyprland). Its wiki calls VMs unsupported and slow, so this checks
# that it starts and loads the config, not how it performs.

setup() {
    [ "$(chezmoi execute-template '{{ .hyprland }}')" != false ] || skip "hyprland disabled"
}

@test "Hyprland renders with virgl, not in software" {
    # Its own log, not the journal: "Renderer: virgl (AMD Radeon 860M ...)"
    log=$(ls -d "$XDG_RUNTIME_DIR"/hypr/*/ | head -1)hyprland.log
    grep -E 'Renderer: ' "$log"
    grep -qE 'Renderer: virgl' "$log"
}

@test "Hyprland runs the dotfiles' config without errors" {
    hyprctl -i 0 -j monitors | jq -e 'length > 0'
    run hyprctl -i 0 -j configerrors
    echo "$output"
    jq -e 'map(select(length > 0)) | length == 0' <<<"$output"
}

@test "waybar is up" {
    pgrep -u "$USER" -x waybar
}
