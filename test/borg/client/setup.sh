#!/bin/bash
# Runs in the client as sjors: the README's steps, in order, the way you'd run
# them by hand. The playbooks are copied to ~/.playbooks like chezmoi deploys
# them. Each playbook's output and exit status go to
# /out/<pass>-<playbook>.{log,status}.
#
# Usage: setup.sh <pass> [playbooks-dir] [passphrase]
#   pass         a label for the logs, e.g. "first" or "second"
#   playbooks    default /src/dot_playbooks (the working tree)
#   passphrase   what to type when asked for the borg passphrase
set -uo pipefail

pass=$1
playbooks=${2:-/src/dot_playbooks}
passphrase=${3:-borg-test-passphrase}
password=test

rm -rf ~/.playbooks
cp -r "$playbooks" ~/.playbooks
cd ~/.playbooks

# The README's storagebox env vars (main account, sub-account number).
export STORAGEBOX_USER=u123456 STORAGEBOX_SUB_USER=1
export ANSIBLE_FORCE_COLOR=0 ANSIBLE_NOCOLOR=1

for playbook in setup_borg_locally setup_nas setup_storagebox; do
    log=/out/$pass-$playbook
    echo "==> $pass run: ansible-playbook $playbook.yml -K"
    /src/test/borg/client/drive.exp "$password" "$passphrase" \
        ansible-playbook "$playbook.yml" -K >"$log.log" 2>&1
    status=$?
    echo "$status" >"$log.status"
    echo "    exit $status (log: test/out/borg/$pass-$playbook.log)"
done
