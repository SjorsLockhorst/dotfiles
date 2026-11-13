# Setting up backups

## Purpose of these playbooks

These playbooks set up borg backups for a 3-2-1 backup system: 3 copies of the
data, in 2 locations, 1 offsite. The first copy is the original on this machine.
The second is a borg repository on the homelab NAS. The third is a borg
repository on a Hetzner storage box, offsite.

The playbooks only do the one-time setup. The daily backups are scheduled by
chezmoi (`borg-backup.timer`, which runs `/usr/local/bin/borg-backup-run` as
root), and `run_backup` starts one by hand.

Running a playbook again is safe: it keeps the keys and the passphrase it saved
the first time, and updates the backup scripts.

## 1. Setting up borg locally

```bash
ansible-playbook ~/.playbooks/setup_borg_locally.yml -K
```

This creates the `borgbackup` user, which holds the backup keys (in
`/home/borgbackup/.ssh`) and each target's settings, including its borg
passphrase (in `/home/borgbackup/targets`, readable only by that user and root).

## 2. Borg repository on the NAS

First create a user for this machine in OpenMediaVault, so that its home folder
is on the RAID array (with room for the backups) instead of the system SSD. In
OMV, go to Users, create a new user, and make sure that:

- the username is exactly what `hostname` prints on this machine;
- it is in the groups `users` and `ssh` (it doesn't need `sudo`).

Then run:

```bash
ansible-playbook ~/.playbooks/setup_nas.yml -K
```

It logs in to the NAS as you (your own ssh key), with sudo, using the same
password as here (`-K`). Use `-e nas_admin=<user>` to log in as someone else.
It asks for the borg passphrase for a new setup: twice, and for an existing
repo the passphrase it already has.

## 3. Borg repository on the Hetzner storage box

First add a sub-account in the Hetzner Console (Storage Boxes, your box,
Sub-accounts): base folder `backups/<hostname>` (exactly what `hostname`
prints), with SSH support and external reachability on. Note its number: the
`2` in `u123456-sub2`.

Then set your main account and the sub-account number, and run the playbook:

```bash
export STORAGEBOX_USER=u123456
export STORAGEBOX_SUB_USER=2
ansible-playbook ~/.playbooks/setup_storagebox.yml -K
```

It connects to the main account with your own ssh key, installs this
machine's backup key for the sub-account, and creates the repo.

> [!WARNING]
> Some ISPs seem to block port 23, which the storage box uses for ssh. Then
> connect over a VPN first.

## How access is restricted

Each target gets its own ssh key. On the NAS and on the storage box, that key
can only run `borg serve` on this machine's repo (`command="borg serve
--restrict-to-repository ..."` in `authorized_keys`), no shell, no other repos.

## Testing

`test/borg/run.sh` in the chezmoi repo runs these playbooks against a mock NAS
and storage box in Docker, on a new machine and on one set up with older
versions of the playbooks.
