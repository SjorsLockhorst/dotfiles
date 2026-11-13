#!/bin/bash
# Test the borg playbooks (dot_playbooks/) against a mock NAS and a mock Hetzner
# storage box in Docker, then a backup with the real runner (util/borg-backup).
#
# Usage: test/borg/run.sh [--keep]
#   --keep  leave the containers running afterwards (to poke around:
#           docker compose -p borg-test exec client bash), stop with
#           docker compose -p borg-test down -v
#
# Order: the README's setup steps (client/setup.sh) + tests, the same again as
# a re-run on the set up machine, then a backup with the NAS stopped.
# Logs end up in test/out/borg/. The playbooks run unchanged, answered by
# expect like a person would (client/drive.exp).
set -euo pipefail

BORG_DIR=$(cd "$(dirname "$0")" && pwd)
OUT=$(dirname "$BORG_DIR")/out/borg
keep=0
[[ ${1:-} == --keep ]] && keep=1

compose() { docker compose -f "$BORG_DIR/compose.yaml" "$@"; }

rm -rf "$OUT"
mkdir -p "$OUT/keys"
# The user's own key (~/.ssh/id_rsa, as setup_nas.yml expects): NAS admin and
# storage box main account accept it.
ssh-keygen -q -t rsa -N '' -C sjors@framework-arch -f "$OUT/keys/id_rsa"

export KEYS_DIR=$OUT/keys OUT_DIR=$OUT
compose down -v --remove-orphans >/dev/null 2>&1 || true
[[ $keep == 1 ]] || trap 'compose down -v >/dev/null 2>&1' EXIT

compose build
compose up -d --wait

# tests <name> <dir> [env...]: run a folder of bats files in the client as root.
status=0
tests() {
    local name=$1 dir=$2; shift 2
    echo "==> Tests: $name"
    compose exec -T -u root "${@/#/-e}" client \
        bats --print-output-on-failure --timing "/src/test/borg/$dir" \
        | tee "$OUT/tests-$name.log" || status=1
}

# The README's steps on a fresh machine, then a backup and the checks.
compose exec -T -u sjors client /src/test/borg/client/setup.sh first || status=1
tests first tests PASS=first

# Running the playbooks again on the set up machine must work too.
compose exec -T -u sjors client /src/test/borg/client/setup.sh second || status=1
tests second tests PASS=second

# The NAS unreachable (e.g. Tailscale down): skipped, not failed.
compose stop nas
tests nas-down tests-offline

echo "==> Logs in $OUT"
exit "$status"
