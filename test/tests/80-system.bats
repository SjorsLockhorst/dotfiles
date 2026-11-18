#!/usr/bin/env bats
# The system playbook itself (system/, Ansible, run by chezmoi apply through
# system-apply). What it sets up is checked where it's used: 10-packages,
# 20-shell (login shell), 60-desktop (GRUB theme, login screen, fingerprint,
# multilib, NPU), 70-services (services, timers, mirrorlist, backups).

@test "a second playbook run changes nothing" {
    run ~/.local/bin/system-apply </dev/null
    echo "$output"
    [ "$status" -eq 0 ]
    grep -qE '^localhost +: .*changed=0 .*failed=0' <<<"$output"
}

@test "GRUB gets allow-discards on an encrypted root, once" {
    # Docker has no LUKS root: run the task on stand-ins for /etc/default/grub.
    d=$BATS_TEST_TMPDIR
    echo 'GRUB_CMDLINE_LINUX="cryptdevice=UUID=1234:root root=/dev/mapper/root"' >"$d/luks"
    echo 'GRUB_CMDLINE_LINUX=""' >"$d/plain"
    cat >"$d/play.yml" <<EOF
- hosts: localhost
  connection: local
  gather_facts: false
  tasks:
    - ansible.builtin.import_tasks: $HOME/.local/share/chezmoi/system/tasks/grub_cmdline.yml
  handlers:
    - name: Regenerate grub.cfg
      ansible.builtin.debug: {msg: regenerate}
EOF
    for f in luks plain; do
        ansible-playbook "$d/play.yml" -e grub_default="$d/$f" >/dev/null
        run ansible-playbook "$d/play.yml" -e grub_default="$d/$f"
        echo "$output"
        grep -qE '^localhost +: .*changed=0' <<<"$output"
    done
    grep -qx 'GRUB_CMDLINE_LINUX="cryptdevice=UUID=1234:root:allow-discards root=/dev/mapper/root"' "$d/luks"
    grep -qx 'GRUB_CMDLINE_LINUX=""' "$d/plain"
}
