#!/bin/bash
# Read-only probe of the real Hetzner storage box, to model the mock on what it
# actually does (the docs leave gaps). Changes nothing: the only mkdir is
# `mkdir -p backups`, which already exists.
#
# Usage: test/borg/probe-storagebox.sh [env-file]
#   Needs STORAGEBOX_USER (main account) and optionally STORAGEBOX_SUB_USER
#   (sub-account number), as for the playbook: from the environment, or from
#   [env-file] if given (sourced first).
# Output is also saved to test/out/probe-storagebox.txt (gitignored).
set -uo pipefail

# shellcheck disable=SC1090
[[ $# -eq 1 ]] && . "$1"
: "${STORAGEBOX_USER:?set it in the environment, or pass a file that sets it}"

out=$(dirname "$0")/../out/probe-storagebox.txt
mkdir -p "$(dirname "$out")"
exec > >(tee "$out") 2>&1

user=$STORAGEBOX_USER
host=$(hostname)

# probe <description> <remote command...>: run one command on port 23.
probe() {
    local what=$1; shift
    printf '\n=== %s\n$ %s\n' "$what" "$*"
    timeout 30 ssh -p23 "$user@$user.your-storagebox.de" "$@" </dev/null
    echo "[exit $?]"
}

probe "Allowed commands" help
probe "Version info" version
probe "Main account: where it starts" pwd
probe "Main account: its files" ls -la
probe "Main account: backups folder" ls -la backups
probe "Main account: this machine's folder" ls -la "backups/$host"
probe "Main account: this machine's .ssh" ls -la "backups/$host/.ssh"
probe "Installed key line (public key + restriction)" cat "backups/$host/.ssh/authorized_keys"
probe "Is mkdir -p accepted? (no-op, backups exists)" mkdir -p backups
probe "Is ; chaining accepted?" 'pwd; pwd'
probe "Is && chaining accepted?" 'pwd && pwd'
probe "Is an absolute /home path valid?" ls -la /home

if [[ -n ${STORAGEBOX_SUB_USER:-} ]]; then
    sub=$user-sub$STORAGEBOX_SUB_USER
    printf '\n=== Sub-account: is the borg-only restriction applied? (needs sudo)\n'
    echo "If this lists files, the command=\"borg serve ...\" restriction is IGNORED."
    echo "No listing (borg serve starts, sees no input and stops, or errors) = applied."
    echo "\$ ssh $sub@$sub.your-storagebox.de ls   (with the backup key)"
    sudo -u borgbackup timeout 15 ssh -i /home/borgbackup/.ssh/storagebox-backup -p23 \
        "$sub@$sub.your-storagebox.de" ls </dev/null
    echo "[exit $?]"
else
    printf '\n=== Sub-account check skipped: STORAGEBOX_SUB_USER not set\n'
fi

printf '\nSaved to %s\n' "$(realpath "$out")"
