#!/bin/bash
# Test the borg playbooks (dot_playbooks/) against a mock NAS and a mock Hetzner
# storage box in Docker, then a backup with the real runner (util/borg-backup).
#
# Usage: test/borg/run.sh [--keep]
#   --keep  leave the containers of the last scenario running (to poke around:
#           docker compose -p borg-test exec client bash), stop with
#           docker compose -p borg-test down -v
#
# Two scenarios, each on fresh containers:
#   fresh    a new machine: the README's steps (client/setup.sh) + tests, a
#            re-run + tests, then a backup with the NAS stopped.
#   upgrade  a machine set up with the playbooks of $OLD_REV (how the laptop
#            was set up) and backed up, then the current playbooks + tests.
# Re-runs type a wrong passphrase: they must keep the saved one, not ask.
# Logs end up in test/out/borg/. The playbooks run unchanged, answered by
# expect like a person would (client/drive.exp).
set -euo pipefail

OLD_REV=0621e85

BORG_DIR=$(cd "$(dirname "$0")" && pwd)
REPO=$(cd "$BORG_DIR/../.." && pwd)
OUT=$REPO/test/out/borg
keep=0
[[ ${1:-} == --keep ]] && keep=1

compose() { docker compose -f "$BORG_DIR/compose.yaml" "$@"; }

rm -rf "$OUT"
mkdir -p "$OUT/keys" "$OUT/old"
# The user's own key (~/.ssh/id_rsa): NAS admin and storage box main account
# accept it.
ssh-keygen -q -t rsa -N '' -C sjors@framework-arch -f "$OUT/keys/id_rsa"
# The old playbooks, for the upgrade scenario (in the client: /out/old).
git -C "$REPO" archive "$OLD_REV" dot_playbooks | tar -x -C "$OUT/old"

export KEYS_DIR=$OUT/keys OUT_DIR=$OUT
compose down -v --remove-orphans >/dev/null 2>&1 || true
[[ $keep == 1 ]] || trap 'compose down -v >/dev/null 2>&1' EXIT

compose build

status=0
fresh_containers() {
    echo "==> Scenario: $1"
    compose down -v >/dev/null 2>&1
    compose up -d --wait
}
setup() { compose exec -T -u sjors client /src/test/borg/client/setup.sh "$@" || status=1; }

# tests <name> <dir> [env...]: run a folder of bats files in the client as root.
tests() {
    local name=$1 dir=$2; shift 2
    echo "==> Tests: $name"
    compose exec -T -u root "${@/#/-e}" client \
        bats --print-output-on-failure --timing "/src/test/borg/$dir" \
        | tee "$OUT/tests-$name.log" || status=1
}

# check <description> <service> <command...>: a check inside a mock.
check() {
    local what=$1 service=$2; shift 2
    if compose exec -T "$service" "$@"; then
        echo "ok: $what"
    else
        echo "FAILED: $what"; status=1
    fi
}
nas_checks() {
    check "NAS: backup user has no passwordless sudo" nas \
        sh -c '! grep -rq "^framework-arch.*NOPASSWD" /etc/sudoers /etc/sudoers.d'
}

fresh_containers fresh
setup first
tests first tests PASS=first
nas_checks
setup second /src/dot_playbooks wrong-passphrase
tests second tests PASS=second
# The NAS unreachable (e.g. Tailscale down): skipped, not failed.
compose stop nas
tests nas-down tests-offline

fresh_containers upgrade
setup old /out/old/dot_playbooks
compose exec -T -u root client borg-backup-run >"$OUT/old-backup.log" 2>&1 \
    || { echo "FAILED: backup after the old playbooks (see old-backup.log)"; status=1; }
setup upgrade /src/dot_playbooks wrong-passphrase
tests upgrade tests PASS=upgrade
nas_checks

echo "==> Logs in $OUT"
exit "$status"
