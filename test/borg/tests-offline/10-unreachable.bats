#!/usr/bin/env bats
# Run by run.sh with the NAS container stopped: the runner must skip it (not
# fail) and still back up to the storage box.

@test "an unreachable NAS is skipped, the storage box still backed up" {
    run borg-backup-run storagebox nas
    echo "$output"
    [ "$status" -eq 0 ]
    [[ $output == *"nas: skipped, nas.home.lan:22 is unreachable"* ]]
    [ "$(jq -r .result /var/lib/borg-backup/nas.json)" = unreachable ]
    [[ $(jq -r .result /var/lib/borg-backup/storagebox.json) == @(ok|warning) ]]
    # the last success from before is kept
    [ "$(jq -r .last_success /var/lib/borg-backup/nas.json)" != null ]
}
