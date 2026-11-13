#!/bin/bash
# The admin's public key goes where OMV puts keys added in its web UI (the real
# NAS has sjors's key there, not in ~/.ssh).
set -euo pipefail

install -m 600 -o sjors -g root /keys/id_rsa.pub "$OMV_KEYS/sjors"

ssh-keygen -A >/dev/null
mkdir -p /run/sshd
exec /usr/sbin/sshd -D -e
