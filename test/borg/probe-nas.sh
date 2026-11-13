#!/bin/bash
# Read-only probe of the real NAS (OpenMediaVault), to model the mock on how OMV
# actually sets things up. Changes nothing. Logs in as the admin user, like
# setup_nas.yml; a few reads need sudo, so you may be asked for the NAS password.
#
# Usage: test/borg/probe-nas.sh [admin@host]   (default: sjors@nas.home.lan)
# The backup user it looks at is this machine's hostname, as in the playbook.
# Output is also saved to test/out/probe-nas.txt (gitignored).
set -uo pipefail

target=${1:-sjors@nas.home.lan}
backup_user=$(hostname)

out=$(dirname "$0")/../out/probe-nas.txt
mkdir -p "$(dirname "$out")"

# Runs on the NAS. $1 = backup user. Never prints secrets: the repo's config
# file holds the encrypted repo key, so only its harmless settings are shown.
read -r -d '' remote <<'REMOTE'
u=$1
section() { printf '\n=== %s\n' "$*"; }

section "OS"
. /etc/os-release && echo "$PRETTY_NAME"
section "OMV and plugins"
dpkg-query -W -f='${Package} ${Version}\n' 'openmediavault*' 2>&1
section "borg"
command -v borg && borg --version

section "Admin user (who the playbook logs in as)"
id
section "Backup user"
getent passwd "$u" || echo "(no user $u)"
id "$u"
section "Groups that matter"
for g in _ssh ssh sudo users; do getent group "$g" || echo "(no group $g)"; done
section "OMV home folder setting"
sudo omv-confdbadm read conf.system.usermgmt.homedir 2>&1

home=$(getent passwd "$u" | cut -d: -f6)
section "Where the backup user's home is mounted"
findmnt -T "$home" -no SOURCE,TARGET,FSTYPE,OPTIONS
section "Permissions on the path to the repo"
sudo namei -l "$home/repo"
sudo ls -la "$home" "$home/.ssh"
section "Backup user's authorized_keys (public key + restriction)"
sudo cat "$home/.ssh/authorized_keys"
section "Repo settings (no key)"
sudo grep -E '^(version|segments_per_dir|max_segment_size|append_only|storage_quota|additional_free_space) ' "$home/repo/config"
sudo du -sh "$home/repo"

section "sshd effective settings"
sudo sshd -T 2>&1 | grep -iE '^(port|allowgroups|allowusers|denygroups|denyusers|authorizedkeysfile|authorizedkeyscommand|strictmodes|pubkeyauthentication|passwordauthentication|permitrootlogin|usepam|subsystem|forcecommand|chrootdirectory) '
section "sshd Match blocks and drop-ins"
sudo grep -n -iE '^\s*(match|include)' -A4 /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>&1
section "OMV-managed key folder"
sudo ls -la /var/lib/openmediavault/ssh/authorized_keys 2>&1

section "sudo rules mentioning the backup user"
sudo grep -rn -- "$u" /etc/sudoers /etc/sudoers.d/ 2>&1
REMOTE

# -t: a terminal, so sudo on the NAS can ask for the password.
ssh -t "$target" "bash -c $(printf %q "$remote") probe $(printf %q "$backup_user")" 2>&1 |
    tr -d '\r' | tee "$out"

printf '\nSaved to %s\n' "$(realpath "$out")"
