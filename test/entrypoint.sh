#!/bin/bash
# Runs inside the container: bootstrap the dotfiles like on a new machine, then
# run the bats tests. Logs go to /out (mounted from test/out on the host).
set -uo pipefail

OUT=/out
mkdir -p "$OUT"

# The age key is mounted read-only; chezmoi wants it at its usual place, owned
# by us. The decrypt-private-key script then skips its passphrase prompt.
if [[ -f /run/secrets/key.txt ]]; then
    install -D -m 600 /run/secrets/key.txt "$HOME/.config/chezmoi/key.txt"
fi

init_args=(init --apply --no-tty
    --promptString "email=$CHEZMOI_EMAIL"
    --promptBool "$CHEZMOI_PROMPT_BOOL")

if [[ -n ${DOTFILES_REMOTE:-} ]]; then
    init_args+=("$DOTFILES_REMOTE")
else
    # The working tree as it is on the host, uncommitted changes included
    mkdir -p "$HOME/.local/share"
    cp -a /src "$HOME/.local/share/chezmoi" || exit 1
fi

echo "==> chezmoi ${init_args[*]}"
# stdin is /dev/null: anything that prompts fails instead of hanging. The
# timeout catches stalled downloads (curl in makepkg has none).
timeout "${APPLY_TIMEOUT:-60m}" chezmoi "${init_args[@]}" </dev/null 2>&1 | tee "$OUT/apply.log"
echo "${PIPESTATUS[0]}" >"$OUT/apply.status"
echo "==> chezmoi apply exited with $(cat "$OUT/apply.status")"

pacman -Qqe >"$OUT/packages-explicit.txt"

echo "==> Running tests"
bats --print-output-on-failure --timing /tests | tee "$OUT/tests.log"
status=${PIPESTATUS[0]}

if [[ ${DROP_SHELL:-} == 1 ]]; then
    echo "==> Dropping into a shell (exit to stop the container)"
    if command -v zsh >/dev/null; then zsh -l; else bash -l; fi
fi

exit "$status"
