#!/usr/bin/env bats
# Every package the dotfiles ask for is actually installed: the install script's
# and the system playbook's (system/vars/Archlinux.yml).
load helpers

setup_file() {
    # Render the install script with this machine's settings and pull the
    # package names out of its pacman/yay lines, so this stays in sync with it.
    {
        chezmoi execute-template \
            <~/.local/share/chezmoi/.chezmoiscripts/run_onchange_before_install-packages.sh.tmpl \
            | grep -E '^\s*(sudo pacman|yay) -S' \
            | sed -E 's/.*--needed//' | tr ' ' '\n' | grep -E '^[a-z0-9][a-z0-9@._+-]*$'
        # npu: only with an AMD NPU, as in site.yml
        python3 -c '
import os, sys, yaml
p = yaml.safe_load(open(sys.argv[1]))["system_packages"]
npu = os.path.isdir("/sys/bus/pci/drivers/amdxdna") and os.path.exists("/dev/accel/accel0")
print("\n".join(p["base"] + (p["desktop"] if sys.argv[2] == "true" else []) + (p["npu"] if npu else [])))
' ~/.local/share/chezmoi/system/vars/Archlinux.yml "$(data hyprland)"
    } | sort -u >"$BATS_FILE_TMPDIR/packages"
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
