# Mock of the NAS (OpenMediaVault 6 on Debian 11), modelled on the real one:
# see test/borg/probe-nas.sh. Not OMV itself: its users, groups, home folders
# and sshd settings, as OMV leaves them.
FROM debian:bullseye

# Debian 11 is end-of-life: its packages are on archive.debian.org (the normal
# mirrors drop them). Same borg as the real NAS: 1.2.3 from bullseye-backports.
RUN rm -f /etc/apt/sources.list.d/* \
    && printf 'deb http://archive.debian.org/debian %s main\n' bullseye bullseye-updates bullseye-backports \
        >/etc/apt/sources.list \
    && echo 'deb http://archive.debian.org/debian-security bullseye-security main' >>/etc/apt/sources.list \
    && echo 'Acquire::Check-Valid-Until "false";' >/etc/apt/apt.conf.d/99archive \
    && apt-get update \
    && apt-get install -y --no-install-recommends openssh-server sudo python3 \
    && apt-get install -y --no-install-recommends -t bullseye-backports borgbackup \
    && rm -rf /var/lib/apt/lists/*

# Must match the client's hostname: the playbook uses it as the user name.
ARG MACHINE=framework-arch
ARG PASSWORD=test
ENV DISK=/srv/dev-disk-by-uuid-00000000-0000-4000-8000-000000000000
ENV OMV_KEYS=/var/lib/openmediavault/ssh/authorized_keys

# The `ssh` group (from Debian 11's openssh-client) is what OMV's sshd allows.
# Homes live on the data disk, as OMV's "user home directory" setting does.
RUN install -d -m 755 "$DISK" \
    && install -d -m 2770 -o root -g users "$DISK/homes" \
    && install -d -m 755 "$OMV_KEYS" \
    # Admin user: sudo with a password (the playbook runs with -K)
    && useradd -u 1000 -g users -G sudo,ssh -m -s /bin/bash sjors \
    # The backup user, as created by hand in the OMV web UI (README step):
    # named after the machine, groups users/sudo/ssh (+ backup, as on the NAS)
    && useradd -u 1015 -g users -G sudo,backup,ssh -m -d "$DISK/homes/$MACHINE" -s /bin/sh "$MACHINE" \
    && printf 'sjors:%s\n%s:%s\n' "$PASSWORD" "$MACHINE" "$PASSWORD" | chpasswd \
    # OMV keeps an (here empty) key file per user, owner user, group root
    && for u in sjors "$MACHINE"; do install -m 600 -o "$u" -g root /dev/null "$OMV_KEYS/$u"; done

COPY sshd_config /etc/ssh/sshd_config
COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
