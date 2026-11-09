-- Follows the desktop theme set by ~/.local/bin/theme-set.
-- specs(): the colorscheme plugin of every trusted theme, lazy-loaded, so any
--          theme can be switched to without installing anything.
-- apply(): load the active theme's colorscheme. theme-set calls ThemeReload()
--          in every running Neovim over its RPC socket.
local M = {}

local home = vim.env.HOME
local current = home .. "/.local/state/theme/current"
-- Community themes (theme-install) are left out: their neovim.lua is code
local trusted_dirs = { home .. "/.config/theme/themes", home .. "/.local/share/theme/themes" }

-- My own settings per colorscheme plugin, merged over what a theme asks for
local overrides = {
    catppuccin = {
        integrations = { cmp = true, gitsigns = true, nvimtree = true, treesitter = true, notify = true, mason = true },
    },
}

local function plugin_name(spec)
    return spec.name or spec[1]:match("([^/]+)$"):gsub("%.git$", "")
end

function M.specs()
    local specs, by_name = {}, {}
    local function add(spec)
        if type(spec) ~= "table" or type(spec[1]) ~= "string" or spec[1] == "LazyVim/LazyVim" then
            return
        end
        local name = plugin_name(spec)
        if by_name[name] then
            -- e.g. catppuccin is listed by both catppuccin and catppuccin-latte
            if spec.opts then
                by_name[name].opts = vim.tbl_deep_extend("force", by_name[name].opts or {}, spec.opts)
            end
            return
        end
        spec = vim.deepcopy(spec)
        spec.lazy, spec.priority = true, nil
        by_name[name] = spec
        table.insert(specs, spec)
    end

    for _, dir in ipairs(trusted_dirs) do
        for _, file in ipairs(vim.fn.glob(dir .. "/*/neovim.lua", false, true)) do
            local ok, list = pcall(dofile, file)
            if ok and type(list) == "table" then
                for _, spec in ipairs(list) do
                    add(spec)
                end
            end
        end
    end
    -- Themes without their own neovim.lua get a colorscheme generated from their palette
    add({ "omacom/aether.nvim", branch = "v3", name = "aether" })

    for name, opts in pairs(overrides) do
        if by_name[name] then
            by_name[name].opts = vim.tbl_deep_extend("force", by_name[name].opts or {}, opts)
        end
    end
    return specs
end

function M.apply()
    local ok, list = pcall(dofile, current .. "/neovim.lua")
    if not ok or type(list) ~= "table" then
        return
    end

    local colorscheme
    for _, spec in ipairs(list) do
        if spec[1] == "LazyVim/LazyVim" and spec.opts then
            colorscheme = spec.opts.colorscheme
        elseif spec.name == "aether" then
            -- aether's palette differs per theme, so set it up on every switch
            require("lazy").load({ plugins = { "aether" } })
            require("aether").setup(spec.opts)
        end
    end

    local mode = vim.fn.filereadable(current .. "/mode") == 1 and vim.fn.readfile(current .. "/mode")[1]
    if mode == "light" or mode == "dark" then
        vim.o.background = mode
    end
    if colorscheme then
        local loaded, err = pcall(vim.cmd.colorscheme, colorscheme)
        if not loaded then
            vim.notify("theme: " .. err, vim.log.levels.WARN)
        end
    end
end

-- Let kitty's background_opacity show through, whatever the colorscheme
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("ThemeTransparency", { clear = true }),
    callback = function()
        for _, group in ipairs({ "Normal", "NormalNC", "SignColumn", "EndOfBuffer", "LineNr", "FoldColumn" }) do
            local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
            hl.bg, hl.ctermbg = nil, nil
            vim.api.nvim_set_hl(0, group, hl)
        end
    end,
})

function _G.ThemeReload()
    M.apply()
    return 0
end

return M
