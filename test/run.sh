#!/bin/bash
# Test the dotfiles on a fresh Arch install in Docker: apply chezmoi with this
# machine's settings, then run the bats tests in test/tests.
#
# Usage: test/run.sh [--remote [url]] [--shell]
#   --remote [url]  test what is pushed (default: the GitHub repo) instead of
#                   the local working tree
#   --shell         open a shell in the container after the tests
#
# Logs end up in test/out/. Always starts from a freshly pulled archlinux image
# and downloads everything again: slow, but that is what a reinstall does.
set -euo pipefail

TEST_DIR=$(cd "$(dirname "$0")" && pwd)
REPO=$(dirname "$TEST_DIR")
OUT="$TEST_DIR/out"
IMAGE=dotfiles-test
KEY="$HOME/.config/chezmoi/key.txt"

remote=""
docker_tty=()
drop_shell=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --remote)
            if [[ ${2:-} && $2 != --* ]]; then remote=$2; shift
            else remote=https://github.com/SjorsLockhorst/dotfiles.git; fi ;;
        --shell) drop_shell=1; docker_tty=(-it) ;;
        -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown option: $1" >&2; exit 2 ;;
    esac
    shift
done

[[ -f $KEY ]] || { echo "No age key at $KEY" >&2; exit 1; }

# The answers to .chezmoi.toml.tmpl's prompts, taken from this machine
data=$(chezmoi data --format json)
email=$(jq -r .email <<<"$data")
prompt_bool=$(jq -r '[to_entries[] | select(.value | type == "boolean")
    | "\(.key)=\(.value)"] | join(",")' <<<"$data")
echo "==> Settings: $prompt_bool"

rm -rf "$OUT"
mkdir -p "$OUT"

# Host network: Tailscale DNS (100.100.100.100) is not reachable from the bridge
docker build --network host --pull -t "$IMAGE" "$TEST_DIR"

status=0
docker run --rm --network host "${docker_tty[@]}" \
    -v "$REPO:/src:ro" \
    -v "$TEST_DIR/tests:/tests:ro" \
    -v "$KEY:/run/secrets/key.txt:ro" \
    -v "$OUT:/out" \
    -e CHEZMOI_EMAIL="$email" \
    -e CHEZMOI_PROMPT_BOOL="$prompt_bool" \
    -e DOTFILES_REMOTE="$remote" \
    -e DROP_SHELL="$drop_shell" \
    "$IMAGE" || status=$?

# Packages installed by hand on this machine that a reinstall would not bring
# back. Informational: some (kernel, firmware, bootloader) never apply in Docker.
if [[ -f $OUT/packages-explicit.txt ]]; then
    comm -23 <(pacman -Qqe | sort) <(sort "$OUT/packages-explicit.txt") >"$OUT/packages-not-in-dotfiles.txt"
    echo "==> $(wc -l <"$OUT/packages-not-in-dotfiles.txt") packages on this machine are not installed by the dotfiles: see test/out/packages-not-in-dotfiles.txt"
fi

echo "==> Logs in $OUT"
exit "$status"
