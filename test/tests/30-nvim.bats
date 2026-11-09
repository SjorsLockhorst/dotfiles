#!/usr/bin/env bats
load helpers

setup() {
    skip_unless nvim
}

# Errors only, not the informational messages of plugins installing things
errors() { grep -E 'E[0-9]+:|[Ee]rror|stack traceback' <<<"$1"; }

@test "neovim is installed" {
    command -v nvim
}

@test "lazy.nvim installs all plugins" {
    nvim --headless "+Lazy! install" +qa >/dev/null 2>&1
    cat >"$BATS_TEST_TMPDIR/check.lua" <<'EOF'
for _, p in ipairs(require("lazy").plugins()) do
    if not p._.installed then io.stdout:write("not installed: " .. p.name .. "\n") end
end
EOF
    run nvim --headless +"luafile $BATS_TEST_TMPDIR/check.lua" +qa
    echo "$output"
    ! grep -q 'not installed:' <<<"$output"
}

@test "first start installs mason tools and treesitter parsers" {
    # Both install asynchronously on startup and abort when nvim quits, so keep
    # one nvim open until debugpy is in and no new parser appeared for 30s.
    cat >"$BATS_TEST_TMPDIR/warmup.lua" <<'EOF'
local reg = require("mason-registry")
local function parsers() return #vim.api.nvim_get_runtime_file("parser/*.so", true) end
local last, since = -1, vim.uv.now()
local done = vim.wait(900000, function()
    local n = parsers()
    if n ~= last then last, since = n, vim.uv.now() end
    return reg.is_installed("debugpy") and vim.uv.now() - since > 30000
end, 1000)
io.stdout:write(done and "warmup done\n" or "warmup timed out\n")
EOF
    installed() {
        [ -d ~/.local/share/nvim/mason/packages/debugpy ] || return 1
        for p in python lua vue typescript; do
            [ -f ~/.local/share/nvim/site/parser/$p.so ] || return 1
        done
    }
    # A second start retries what failed, like the config does on every start
    # (a parser download sometimes comes back corrupt).
    for attempt in 1 2; do
        run nvim --headless +"luafile $BATS_TEST_TMPDIR/warmup.lua" +qa
        echo "attempt $attempt: $output"
        installed && break
    done
    grep -q 'warmup done' <<<"$output"
    ! errors "$output"
    installed
}

@test "neovim starts without errors" {
    run nvim --headless +qa
    echo "$output"
    ! errors "$output"
}

@test "opening files of each language gives no errors" {
    cd "$BATS_TEST_TMPDIR"
    for f in a.py a.lua a.rs a.ts a.vue a.md a.json a.sh a.tex; do
        echo "x" >"$f"
        run nvim --headless "$f" "+sleep 2" +qa
        echo "$f: $output"
        ! errors "$output"
    done
}

@test "the nvim python env has pynvim" {
    ~/nvim-env/bin/python -c 'import pynvim'
}
