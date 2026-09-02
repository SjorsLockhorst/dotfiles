-- nvim-treesitter `main` branch (required for Neovim 0.12+).
-- This is a full rewrite of the old `master` API: there is no
-- `configs.setup{ highlight = ..., ensure_installed = ... }`. Instead you
-- install parsers explicitly and enable Neovim's built-in treesitter features
-- (highlight/indent/fold) yourself, per filetype.

require('nvim-treesitter').setup({
    -- Parsers + queries install here; this dir is prepended to runtimepath so
    -- freshly built parsers take priority over any stale ones.
    install_dir = vim.fn.stdpath('data') .. '/site',
})

-- Parsers to keep installed. `install()` is async and a no-op if already
-- present. After updating the plugin, run `:TSUpdate` to rebuild parsers so
-- they stay in sync with the queries (mismatches cause query/parse errors).
local ensure = {
    'c', 'lua', 'vim', 'vimdoc', 'query',
    'markdown', 'markdown_inline',
    'python', 'vue', 'typescript', 'javascript', 'html', 'css',
    'json', 'yaml', 'toml', 'bash', 'rst',
}
require('nvim-treesitter').install(ensure)

-- Enable treesitter highlighting (and experimental indent) per filetype.
-- Highlighting itself is provided by Neovim via `vim.treesitter.start()`.
vim.api.nvim_create_autocmd('FileType', {
    callback = function(ev)
        local ft = vim.bo[ev.buf].filetype
        -- chezmoi templates mix template + target syntax; treesitter chokes.
        if ft == '' or ft:find('chezmoitmpl') then
            return
        end
        local lang = vim.treesitter.language.get_lang(ft)
        if not lang then
            return
        end
        -- Only start if a parser is actually available (avoids errors for
        -- filetypes whose parser isn't installed yet).
        if not pcall(vim.treesitter.start, ev.buf, lang) then
            return
        end
        -- Experimental treesitter-based indentation (was enabled on master,
        -- except python). Remove this block if indenting misbehaves.
        if lang ~= 'python' then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,
})

-- NOTE: the `main` branch dropped the built-in `incremental_selection` and
-- `textobjects` modules that the old commented config used. If you want those
-- back, add the companion plugin `nvim-treesitter/nvim-treesitter-textobjects`
-- (its `main` branch) and configure it separately.
