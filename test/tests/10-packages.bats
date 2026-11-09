#!/usr/bin/env bats
# Every package the install script asks for is actually installed.

setup_file() {
    # Render the install script with this machine's settings and pull the
    # package names out of its pacman/yay lines, so this stays in sync with it.
    chezmoi execute-template \
        <~/.local/share/chezmoi/.chezmoiscripts/run_onchange_before_install-packages.sh.tmpl \
        | grep -E '^\s*(sudo pacman|yay) -S' \
        | sed -E 's/.*--needed//' | tr ' ' '\n' | grep -E '^[a-z0-9][a-z0-9@._+-]*$' \
        | sort -u >"$BATS_FILE_TMPDIR/packages"
}

@test "the install script lists packages" {
    [ -s "$BATS_FILE_TMPDIR/packages" ]
}

@test "yay is installed" {
    command -v yay
}

@test "all packages from the install script are installed" {
    missing=()
    while read -r pkg; do
        pacman -Q "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done <"$BATS_FILE_TMPDIR/packages"
    [ ${#missing[@]} -eq 0 ] || { echo "missing: ${missing[*]}"; false; }
}
