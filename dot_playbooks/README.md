# Setting up backups


## Purpose of these playbooks

The purpose of the playbooks in these directories, are setup borg backup to enable a 3-2-1 backup system.
3 copies of the data, in 2 locations, 1 offsite.
The first copy of the data, is on the host machine, the original. The second copy, is locally on the homelab NAS server in a borg repository.
The third and last one, is on Hetzner storagebox, in another borg repository, which is 'offsite'.

### Setting up borg locally

Running

```bash
ansible-playbook setup_borg_locally.yml -K
```


will attempt to create a new user, the borgbackup user, which is a service account for running backups.
Because of this, it will need to have root priviledges.
This user will have the right ssh keys to connect with both the NAS and storagebox borg repos.

### Setting up borg repository on NAS

First of all, we need to create a new account in OMV on the NAS.
This is because, the home directory of our new user needs to be deferred to a different location than `/home/{new_user}`, because that folder is present on the main SSD that OMV runs on.
Rather, we want to create a new user through OMV, such that the home directory is automatically placed on our RAID array, which has more than enough space for our backups.

In OMV, go to Users -> create a new user. Ensure the following:

- The user has the exact same username as the `hostname` command returns on the device you want to setup
- The new user is in groups: `backups`, `users`, `sudo`, and `ssh`

After doing that, you can run:

```bash
ansible-playbook setup_nas.yml -K

```

which should now run succesfully.

## Setting up borg repository on Hetzner storagebox and connecting

First, we need to setup a new subaccount on hetzner.
Do so through the web UI. Create a new folder with the exact same as `hostname` in the `backups/` directory.
Allow external reachability and SSH support. Take note of the sub account number, which will be some integer.

Then before running the ansible-playbook, set the following env vars:

```bash
export STORAGEBOX_USER=...
export STORAGEBOX_SUB_USER=...
```


Then, run the script which will generate the right keys and move them to the storagebox instance.

> [!WARNING]
> It seems as though some ISPs block access to port 23 somehow. Therefore, all connections must go over VPN to be able to connect to the storagebox and execute any commands.


