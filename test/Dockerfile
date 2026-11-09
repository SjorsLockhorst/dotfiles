# A freshly installed Arch: base system, a sudo user, chezmoi. Nothing else, so
# everything the dotfiles need has to come from the dotfiles themselves.
FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed sudo chezmoi bats \
    && pacman -Scc --noconfirm

# Test-only deviation: makepkg's curl has no timeout, so a stalled AUR source
# would hang the run. Give up after 2 minutes without data instead.
RUN sed -i "s|/usr/bin/curl -qgb \"\" |/usr/bin/curl -qgb \"\" --speed-limit 1 --speed-time 120 |" /etc/makepkg.conf \
    && grep -q -- '--speed-time 120' /etc/makepkg.conf

# Same user name as the real machine: some configs hardcode /home/sjors, and
# makepkg refuses to run as root.
RUN useradd -m -G wheel -s /bin/bash sjors \
    && echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER sjors
WORKDIR /home/sjors
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
