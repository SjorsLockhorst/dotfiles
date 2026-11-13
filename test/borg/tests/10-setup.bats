#!/usr/bin/env bats
# Did the README's setup steps (client/setup.sh) work? Runs as root in the
# client. PASS (set by run.sh) says which run to check: first, or second (a
# re-run on an already set up machine).

playbook_ok() {
    local log=/out/$PASS-$1
    echo "--- last lines of test/out/borg/$PASS-$1.log:"
    tail -n 25 "$log.log" | sed 's/^/    /'
    [ "$(cat "$log.status")" = 0 ]
}

@test "setup_borg_locally.yml succeeds" { playbook_ok setup_borg_locally; }
@test "setup_nas.yml succeeds" { playbook_ok setup_nas; }
@test "setup_storagebox.yml succeeds" { playbook_ok setup_storagebox; }

@test "both targets have a backup script and settings" {
    for t in nas storagebox; do
        ls -l "/home/borgbackup/backup_$t.sh" "/home/borgbackup/targets/$t"
    done
}
