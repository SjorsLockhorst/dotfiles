#!/usr/bin/env bats
# The backup keys may only run borg on their own repo (the command="borg serve
# --restrict-to-repository ..." line the playbooks install).
# For the storage box this shows what the playbook asks for; whether Hetzner
# enforces command= is not confirmed on the real box yet.

# as_borg <rsh> <cmd...>: run as the backup user with BORG_RSH=<rsh> (no host
# key questions), giving up after 60 s.
as_borg() {
    timeout 60 sudo -u borgbackup env BORG_RSH="$1" "${@:2}"
}

nas_ssh="ssh -i /home/borgbackup/.ssh/nas-backup -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
box_ssh="ssh -i /home/borgbackup/.ssh/storagebox-backup -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 23"

# The key must exist and log in (ssh exits 255 when it can't), so a missing
# key or failed login doesn't pass as "restricted". borg serve answers any
# other command with its usage text (it parses SSH_ORIGINAL_COMMAND for
# options) and repeats the bad command in its error, so look for what only a
# shell running it would print: SHELL-42.
@test "NAS backup key can't run a shell command" {
    [ -f /home/borgbackup/.ssh/nas-backup ]
    run timeout 20 sudo -u borgbackup $nas_ssh framework-arch@nas.home.lan 'echo SHELL-$((6*7))' </dev/null
    echo "exit $status: $output"
    [ "$status" -ne 255 ]
    [[ $output != *SHELL-42* ]]
}

@test "NAS backup key can't reach another repo" {
    run as_borg "$nas_ssh" borg init --encryption=none ssh://framework-arch@nas.home.lan/./other-repo
    echo "$output"
    [ "$status" -ne 0 ]
    [[ $output == *"not allowed"* || $output == *PathNotAllowed* ]]
}

@test "storage box backup key can't run a shell command" {
    [ -f /home/borgbackup/.ssh/storagebox-backup ]
    run timeout 20 sudo -u borgbackup $box_ssh u123456-sub1@u123456-sub1.your-storagebox.de 'echo SHELL-$((6*7))' </dev/null
    echo "exit $status: $output"
    [ "$status" -ne 255 ]
    [[ $output != *SHELL-42* ]]
}

@test "storage box backup key can't reach another repo" {
    run as_borg "$box_ssh" borg init --encryption=none ssh://u123456-sub1@u123456-sub1.your-storagebox.de:23/./other-repo
    echo "$output"
    [ "$status" -ne 0 ]
    [[ $output == *"not allowed"* || $output == *PathNotAllowed* ]]
}
