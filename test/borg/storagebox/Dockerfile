# Mock of a Hetzner storage box account. One container per account (main and
# sub-account), like Hetzner gives each its own hostname; they share one volume.
# Modelled on a real box: see test/borg/probe-storagebox.sh.
FROM debian:bookworm

# borg 1.2 is Hetzner's default `borg` (borg-1.1/1.2/1.4 via --remote-path).
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server borgbackup rsync tree \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/borg /usr/local/bin/borg-1.2

COPY sshd_config /etc/ssh/sshd_config
COPY --chmod=755 restricted-shell /usr/local/bin/restricted-shell
COPY --chmod=755 entrypoint.sh /entrypoint.sh
RUN echo /usr/local/bin/restricted-shell >>/etc/shells

ENTRYPOINT ["/entrypoint.sh"]
