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

> Note: `chezmoi diff <source-path>` reports "not managed" — it expects a **target** (deployed)
> path, not the repo-relative source path. Use `chezmoi diff` with no args, or pass a `~/...` path.

## State that lives OUTSIDE this repo (not chezmoi-managed)
Some runtime state affects behavior but is not in this repo, so it won't move with `apply`:
- `~/.config/nvim/lazy-lock.json` — lazy.nvim plugin lockfile (pins plugin commits/branches).
  A `branch =` change in `lazy.lua` only takes effect after `chezmoi apply` **and** a lazy
  update (`:Lazy update <plugin>`), which also rewrites this lock.
- `~/.local/share/nvim/lazy/` — installed plugins.
- `~/.local/share/nvim/mason/` — Mason-installed LSP servers / tools / treesitter parsers.
