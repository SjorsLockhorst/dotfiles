#!/usr/bin/env bats
load helpers

setup() {
    skip_unless hyprland
    export PATH="$HOME/.local/bin:$PATH"
}

@test "the default theme was rendered during apply" {
    [ -f ~/.local/state/theme/current/colors.toml ]
}

@test "official and own themes are available" {
    run theme-list
    echo "$output"
    [ "${#lines[@]}" -gt 5 ]
    grep -qx catppuccin <<<"$output"
}

@test "every theme renders every template" {
    failed=()
    for theme in $(theme-list); do
        if ! theme-set "$theme" >/dev/null 2>&1; then failed+=("$theme"); continue; fi
        for tpl in ~/.config/theme/templates/*.tpl; do
            out=$(basename "$tpl" .tpl)
            [ -s ~/.local/state/theme/current/"$out" ] || failed+=("$theme:$out")
        done
    done
    [ ${#failed[@]} -eq 0 ] || { echo "failed: ${failed[*]}"; false; }
}
