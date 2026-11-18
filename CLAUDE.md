# Repository: chezmoi dotfiles source

This repo is the **chezmoi source directory** (`~/.local/share/chezmoi`). Files here are
templates/source versions that get **deployed to `$HOME`** by chezmoi. Applications read
the deployed copies, **not** the files in this repo.

## Critical workflow rule

**Editing a file in this repo does NOT change the live config.** The deployed copy under
`$HOME` (e.g. `~/.config/nvim/...`) is unchanged until you run:

```sh
chezmoi apply
```

So after editing any `dot_*` source file here, you MUST `chezmoi apply` before testing the
change with the real application. Skipping this means the app still runs the OLD config and
your tests will silently reflect the un-applied version.

### Path mapping
- Source: `~/.local/share/chezmoi/dot_config/nvim/lua/base/lazy.lua`
- Deployed: `~/.config/nvim/lua/base/lazy.lua`
- `dot_` prefix in source → `.` in the deployed path. `.tmpl` suffix → template-rendered.

### Useful commands
- `chezmoi diff` — preview what `apply` would change (source → deployed).
- `chezmoi apply` — deploy source to `$HOME`.
- `chezmoi apply <target>` — apply a single deployed path, e.g. `chezmoi apply ~/.config/nvim`.
- `chezmoi source-path <deployed-file>` — find the source file for a deployed path.
- `chezmoi managed | grep <x>` — list what chezmoi manages.

> Note: `chezmoi apply` blocks on an interactive prompt (hangs in non-interactive shells)
> when a deployed file was modified since chezmoi last wrote it. Use
> `chezmoi diff --no-pager <file>` to check it first, then `chezmoi apply --force <file>`.
> Pass individual files: `chezmoi diff ~/.config/kitty` (a directory) missed a pending
> change to `~/.config/kitty/kitty.conf`.

> Note: `chezmoi diff <source-path>` reports "not managed" — it expects a **target** (deployed)
> path, not the repo-relative source path. Use `chezmoi diff` with no args, or pass a `~/...` path.

## State that lives OUTSIDE this repo (not chezmoi-managed)
Some runtime state affects behavior but is not in this repo, so it won't move with `apply`:
- `~/.config/nvim/lazy-lock.json` — lazy.nvim plugin lockfile (pins plugin commits/branches).
  A `branch =` change in `lazy.lua` only takes effect after `chezmoi apply` **and** a lazy
  update (`:Lazy update <plugin>`), which also rewrites this lock.
- `~/.local/share/nvim/lazy/` — installed plugins.
- `~/.local/share/nvim/mason/` — Mason-installed LSP servers / tools / treesitter parsers.

## Neovim config gotchas
- Some plugin `setup()` calls live in `dot_config/nvim/after/plugin/<name>.lua`. Those run
  later and override lazy.lua `opts`, so check there before changing a plugin's opts.
- The colorscheme is NOT set in nvim config: it follows the desktop theme (see Themes).
  Per-colorscheme preferences (e.g. catppuccin integrations) go in `overrides` in
  `dot_config/nvim/lua/base/theme.lua`.

## Zsh
- Machine-specific / work-only shell config goes in `~/.zshrc.local` (NOT chezmoi-managed,
  sourced at the end of `dot_zshrc.tmpl`). Setup scripts that append to `~/.zshrc` cause
  drift; move such lines into `~/.zshrc.local`.

## Themes (live switching, omarchy-style)
- `theme-set <name>` / `theme-menu` (SUPER+CTRL+SHIFT+SPACE) / `theme-bg-next`
  (SUPER+CTRL+SPACE) / `theme-list` / `theme-install <git-url>`, all in `dot_local/bin/`.
- Themes use omarchy's format (`colors.toml` + extras). Official ones come from the omarchy repo
  via `.chezmoiexternal.toml` (pinned commit) into `~/.local/share/theme/themes/`. Own themes:
  `dot_config/theme/themes/<name>/`. Community installs: `~/.local/share/theme/installed/`
  (untrusted: their `.lua`/terminal configs are ignored by `theme-render`).
- Per-app templates: `dot_config/theme/templates/*.tpl`, omarchy placeholder syntax
  (`{{ accent }}`, `{{ accent_strip }}`, `{{ mix a b 20% }}`). NOT chezmoi templates (no `.tmpl`).
- `theme-set` renders into `~/.local/state/theme/current/` (runtime state, not managed) and
  reloads apps. App configs only point at `current/` files, so never hardcode colours in them.
- Changing a template only takes effect after `chezmoi apply` (the run_onchange theme-refresh
  script re-renders) or `theme-set --refresh`.
- Own wallpapers: files directly in `dot_config/theme/backgrounds/` go in every theme, those in
  `backgrounds/<theme>/` only in that one. Both are added to the theme's own (yours win on a name clash).
- Obsidian: `theme-set` copies `current/obsidian.css` into every vault (from
  `~/.config/obsidian/obsidian.json`) as the "Omarchy" theme (`.obsidian/themes/Omarchy/`), like
  omarchy does. Pick it once per vault in Obsidian; vault config is not chezmoi-managed.
- rofi variable names can't contain `_` (the whole .rasi silently fails to parse).

## Login screen (SDDM)
- Own theme `desktop` (`util/sddm-theme/`, hyprlock's layout), installed into
  `/usr/share/sddm/themes/desktop` by `system/tasks/sddm.yml`, set in
  `/etc/sddm.conf.d/10-theme.conf` (`/etc/sddm.conf` would win over it: keep `Current=` out of it).
- The greeter runs as user `sddm` and can't read `~` (700). So its colours (template
  `sddm.conf.tpl`) and wallpaper go to `/var/lib/sddm-theme/` (owned by you): `theme-set` and
  `theme-bg-next` copy them there without sudo. The theme's `theme.conf.user` links to it.
- The greeter runs on Xorg at scale 1, so the QML scales by screen height (`s`), not DPI.
- Preview without logging out: `sddm-greeter-qt6 --test-mode --theme <dir>` (a window; logs go to
  the journal, not stderr). Keyboard layout and power buttons stay hidden in test mode.
- `qmllint Main.qml` (`/usr/lib/qt6/bin`) exits non-zero only on real errors; the "unqualified"
  warnings are the greeter's injected `sddm`/`config`/`userModel`.

## Waybar
- Two bars in `dot_config/waybar/config` (compact on `eDP-1`, full on `!eDP-1`); module
  definitions are shared in `modules.json` (via `include`). Variants use `module#name`.
- Font family must be `FantasqueSansM Nerd Font Propo` (a wrong name silently falls back to
  DejaVu and random icon fonts). Use only Material Design icons (U+F0000 range) for even sizes.
- A `group/foo` is styled as `#foo` in CSS (not `#group-foo`).
- mpris `dynamic-len` drops fields that don't fit instead of truncating; use `title-len`/`artist-len`.
- waybar 0.15 custom modules: `{}` in a format next to `{icon}` errors; use `{text}`.
- Reload: `pkill -USR2 -x waybar` (styles/config). Restart detached: `setsid -f waybar`.
  Screenshot to check: `grim -o eDP-1 out.png`.

## System config (Ansible)
- Goal: an Arch base install plus `chezmoi init --apply` gives a working machine (`test/run.sh` is
  that, in Docker).
- Everything root-owned outside `$HOME` (system services, `/etc` files, GRUB, the login screen,
  fingerprint login, Steam's multilib repo, the NPU, timeshift and autosnap, reflector, the borg
  timer, the login shell) is the Ansible playbook in `system/`: `site.yml`, one `tasks/<area>.yml`
  per area, files in `files/`. chezmoi's FAQ leaves system config to a config management tool.
  `system/` is in `.chezmoiignore`.
- Turning on multilib triggers a full `pacman -Syu` (Arch has no partial upgrades) before the
  package step. Steam's virtual dependencies (Vulkan, libgl, font) are pinned in `vars/`, since
  `--noconfirm` would take the first provider.
- The NPU part runs only where both `/sys/bus/pci/drivers/amdxdna` and `/dev/accel/accel0` exist,
  so never in Docker. Docker sees the host's `/sys` but can't raise memlock: there the NPU's
  `limits.d` file makes every `sudo` fail with `pam_open_session: Permission denied`. The laptop's
  `system-apply --check --diff` covers it. Fingerprint enrolment stays manual (`fprintd-enroll`).
- The packages the playbook sets up are in `system/vars/<os_family>.yml` (installed first, in one
  `ansible.builtin.package` call, so names can differ per OS). The general tool lists, AUR packages
  (yay's sudo needs a terminal, which Ansible doesn't give it), `ansible` itself and user-level setup
  stay in `.chezmoiscripts`. `ansible`, not `ansible-core`: the pacman module is in community.general.
- Debian isn't maintained: there the playbook only runs for the borg timer (`vars/Debian.yml` is
  empty), and the Debian scripts in `.chezmoiscripts` stay as they are.
- `system-apply` (`dot_local/bin`) runs it with the chezmoi settings it reads (`hyprland`, `backup`,
  `zsh`) and asks for the sudo password when it has a terminal. `run_onchange_after_system.sh.tmpl`
  calls it on apply when `system/`, `util/borg-backup/`, `util/sddm-theme/` or those settings
  change. It sorts before `theme-refresh`, which fills `/var/lib/sddm-theme` once the playbook made it.
- `system-apply --check --diff` shows what it would change: the drift check `chezmoi diff` can't do
  for `/etc`.
- Every task must be idempotent (a second run reports `changed=0`, tested): commands need
  `creates:` or `changed_when:`. Read-only lookups need `check_mode: false`, or `--check` can't see
  the system.
- `--check` only pretends to create folders and unit files, so a task that writes into one (or
  enables one) made earlier in the same run fails there: give it
  `when: not (ansible_check_mode and <that task's register> is changed)`. The same goes for
  packages: when `--check` finds some to install, `previewing_installs` skips the areas that need them.
- `grub-mkconfig` and the first reflector run are handlers: they run only when their inputs changed,
  and `grub-mkconfig` only where `/boot/grub/grub.cfg` exists (not in Docker).
- Tests: `test/run.sh` runs the playbook as part of the fresh install. `60-desktop` and `70-services`
  check what it set up; `80-system.bats` checks that a second run changes nothing, and the LUKS
  `allow-discards` edit on stand-in files (Docker has no LUKS root). What Docker can't show (btrfs,
  LUKS, running services, `grub-mkconfig`): `system-apply --check --diff` on the laptop.

## Testing a fresh install (Docker)
- `test/run.sh` builds a vanilla Arch image (`test/Dockerfile`: base + sudo user `sjors` + chezmoi
  + bats), runs `chezmoi init --apply` with THIS machine's `chezmoi data` as prompt answers, then
  the bats tests in `test/tests/`. Logs in `test/out/` (gitignored). `--remote` tests the pushed
  repo instead of the working tree, `--shell` opens a shell in the container afterwards.
- Takes ~15+ min and re-downloads everything on purpose (realism over speed).
- The age key is mounted read-only at runtime, never baked into the image.
- Uses `--network host`: Tailscale DNS (100.100.100.100) is unreachable from Docker's bridge.
- Apply runs with stdin `/dev/null`, so any script that prompts fails instead of hanging: use
  `--noconfirm` / `set -e` in `.chezmoiscripts`. Apply is capped at 60m (`APPLY_TIMEOUT`).
- `test/` is in `.chezmoiignore`, otherwise it would be deployed to `~/test`.
- Scripts in `.chezmoiscripts` run alphabetically per phase (before/after): `00-install-yay` must
  sort before `install-packages`.
- `test/out/packages-not-in-dotfiles.txt` lists packages on this machine a reinstall would miss.
- A package a config calls (waybar click, Hyprland bind, script) must be in the install-packages
  lists; one the system config sets up goes in `system/vars/Archlinux.yml` instead (`10-packages`
  checks both). A daemon must be enabled in `system/tasks/services.yml` (a fresh install leaves
  services off; user units go in `run_onchange_after_enable-user-services.sh.tmpl`). AUR-only
  packages (e.g. blueberry) go in the yay step.

## Backups (borg)
- One-time setup (borgbackup user, keys, repos, `/home/borgbackup/backup_<target>.sh`) is done by the
  `dot_playbooks/` ansible playbooks, run by hand. Not part of `chezmoi apply`.
- Scheduling: `system/tasks/borg_timer.yml` installs `util/borg-backup/` (timer, service, runner)
  into `/etc` and `/usr/local/bin` (only when `backup = true`). Schedule: `OnCalendar=` in
  `borg-backup.timer`.
- The runner TCP-checks each target's host:port (parsed from `BORG_REPO`) and logs a skip when it's
  unreachable or not set up: `journalctl -u borg-backup -p warning`.
- The runner writes `/var/lib/borg-backup/<target>.json` (last attempt, result, last success);
  `waybar-backup` (`custom/backup`, next to updates) reads it. Hidden via `exec-if` until the runner
  is installed. `run_backup` goes through the runner, so manual runs update the status too.

## Testing the borg playbooks (Docker mocks)
- `test/borg/run.sh [--keep]` (~6 min after the first build) runs the 3 playbooks unchanged on an Arch
  client against a mock NAS and a mock Hetzner storage box, then backups through the real
  `borg-backup-run`. Scenario "fresh": setup + tests, a re-run + tests, then the NAS stopped.
  Scenario "upgrade": setup with the playbooks of `OLD_REV` (how the laptop was set up) + a backup,
  then the current ones + tests. Re-runs type a wrong passphrase: the saved one must be kept.
  Logs: `test/out/borg/`.
- Playbook layout: the per-target borg steps (passphrase, repo check/init, settings, backup script
  from `templates/backup.sh.j2`) are shared in `dot_playbooks/tasks/borg_repo.yml`.
- The mocks copy the real machines, read by `test/borg/probe-nas.sh` / `probe-storagebox.sh`
  (read-only, run them by hand). Re-probe and update the mocks when the NAS (OMV 6, Debian 11) is upgraded.
- The compose network is `internal`: otherwise a stopped mock's name resolves to the REAL machine
  (`nas.home.lan` did, once).
- Prompts are answered by `client/drive.exp` in a pty. Piped stdin makes ansible's `pause` continue
  with an EMPTY answer (an empty borg passphrase). `pause` also drops input typed right after its
  prompt. No `#` comments inside a Tcl `expect { }` block: they're read as patterns.
- Storage box: sub-account = its own container (and hostname) with `backups/<host>` mounted as `/home`.
  The real box accepts a 666 `authorized_keys` (mock: `StrictModes no`); `;` fails but `&&` works.
  Not confirmed on the real box yet: whether it enforces `command=` in `authorized_keys`.

## Snapshots (timeshift)
- Daily snapshots (keep 5): `system/tasks/timeshift.yml` writes `/etc/timeshift/timeshift.json` and
  `/etc/cron.d/timeshift-hourly` exactly as the GUI's setup does, only when timeshift isn't set up
  yet (so GUI changes stick) and `/` is btrfs (not in Docker).
- Timeshift schedules via cron: cronie must be enabled (in `system/tasks/services.yml`), or nothing
  happens.
- Pre-upgrade snapshots come from `timeshift-autosnap` (pacman hook, own config in
  `/etc/timeshift-autosnap.conf`, keeps its newest 3). Scheduled and autosnap snapshots never prune
  each other's.
- `waybar-backup` also shows timeshift, read without root from `/boot/grub/grub-btrfs.cfg` (kept up
  to date by grub-btrfsd; lists each snapshot's date, tag and comment). `timeshift --list` needs root.
