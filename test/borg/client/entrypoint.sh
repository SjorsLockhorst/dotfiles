#!/bin/bash
# The user's own SSH key (what logs in to the NAS admin and storage box main
# account), and the backup runner chezmoi installs on the real laptop.
set -euo pipefail

install -d -o sjors -g sjors -m 700 /home/sjors/.ssh
install -o sjors -g sjors -m 600 /keys/id_rsa /home/sjors/.ssh/id_rsa
install -o sjors -g sjors -m 644 /keys/id_rsa.pub /home/sjors/.ssh/id_rsa.pub
install -m 755 /src/util/borg-backup/borg-backup-run /usr/local/bin/borg-backup-run

exec sleep infinity
