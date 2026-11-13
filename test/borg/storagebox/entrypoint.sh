#!/bin/bash
# Start one storage box account ($BOX_USER) with its files in /home.
#   main account (u123456):     the whole box; the user's own key logs in.
#   sub-account (u123456-sub1): /home is backups/$MACHINE of the main account
#                               (mounted by compose), as on Hetzner.
set -euo pipefail

# All accounts share one uid: on the real box every file is owned by the main
# account, also what a sub-account writes. '*' = no password, but not locked.
useradd -o -u 1000 -U -d /home -M -s /usr/local/bin/restricted-shell "$BOX_USER"
usermod -p '*' "$BOX_USER"
chown 1000:1000 /home

if [[ $BOX_USER != *-sub* ]]; then
    install -d -o 1000 -g 1000 -m 755 /home/.ssh
    install -o 1000 -g 1000 -m 600 /keys/id_rsa.pub /home/.ssh/authorized_keys
    # What creating the sub-account in the Hetzner Console does: its base
    # directory (the README's manual step, done before the playbook runs).
    install -d -o 1000 -g 1000 -m 755 /home/backups "/home/backups/$MACHINE"
fi

ssh-keygen -A >/dev/null
mkdir -p /run/sshd
exec /usr/sbin/sshd -D -e
