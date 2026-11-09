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
- rofi variable names can't contain `_` (the whole .rasi silently fails to parse).
