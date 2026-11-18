#!/bin/bash
# Runs in the VM as the user (test/vm/run.sh, dotfiles phase): bootstrap the
# dotfiles like on a new machine, then run the bats tests in /tests. run.sh
# puts the repo in /src and the age key in /run/secrets/key.txt (a RAM disk),
# and fetches the logs from /out afterwards.
#
# Env: CHEZMOI_EMAIL and CHEZMOI_PROMPT_BOOL, the answers to
# .chezmoi.toml.tmpl's prompts (this machine's chezmoi data), and optionally
# DOTFILES_REMOTE, a repo to test instead of /src.
set -uo pipefail

OUT=/out

# The key at chezmoi's usual place: the decrypt-private-key script then skips
# its passphrase prompt.
install -D -m 600 /run/secrets/key.txt "$HOME/.config/chezmoi/key.txt"

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
# timeout catches stalled downloads.
timeout "${APPLY_TIMEOUT:-60m}" chezmoi "${init_args[@]}" </dev/null 2>&1 | tee "$OUT/apply.log"
echo "${PIPESTATUS[0]}" >"$OUT/apply.status"
echo "==> chezmoi apply exited with $(cat "$OUT/apply.status")"

pacman -Qqe >"$OUT/packages-explicit.txt"

echo "==> Running tests"
bats --print-output-on-failure --timing /tests | tee "$OUT/tests.log"
exit "${PIPESTATUS[0]}"
