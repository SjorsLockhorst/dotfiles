#!/usr/bin/env bats
# A backup through the real runner (util/borg-backup/borg-backup-run), as the
# timer would run it.

# borg_as <target> <borg args...>: borg as the backup user with a target's settings.
borg_as() {
    local t=$1; shift
    sudo -u borgbackup bash -c '. /home/borgbackup/targets/$0 && borg "$@"' "$t" "$@"
}

@test "a backup to both targets succeeds" {
    run borg-backup-run storagebox nas
    echo "$output"
    [ "$status" -eq 0 ]
    for t in storagebox nas; do
        result=$(jq -r .result "/var/lib/borg-backup/$t.json")
        echo "$t: $result"
        # warning = borg exit 1, e.g. /timeshift doesn't exist (as on the laptop)
        [[ $result == ok || $result == warning ]]
    done
}

@test "both repos list the new archive" {
    for t in storagebox nas; do
        run borg_as "$t" list --short
        echo "$t: $output"
        [ "$status" -eq 0 ]
        [[ $output == *framework-arch-* ]]
    done
}
