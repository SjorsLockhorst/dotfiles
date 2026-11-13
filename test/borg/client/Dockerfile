# The laptop: Arch with what running the playbooks needs. The hostname is set
# by compose (framework-arch): the playbooks name users and folders after it.
FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed sudo ansible borg openssh expect bats jq inetutils \
    && pacman -Scc --noconfirm

# sudo with a password, like the real laptop: the playbooks run with -K.
ARG PASSWORD=test
RUN useradd -m -G wheel -s /bin/bash sjors \
    && echo "sjors:$PASSWORD" | chpasswd \
    && echo '%wheel ALL=(ALL:ALL) ALL' >/etc/sudoers.d/wheel

COPY --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
