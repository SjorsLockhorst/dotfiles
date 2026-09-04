local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)


require("lazy").setup({
    {
        'alexghergh/nvim-tmux-navigation',
        config = function()
            local set_keymaps = function()
                require 'nvim-tmux-navigation'.setup {
                    disable_when_zoomed = true, -- defaults to false
                    keybindings = {
                        left = "<C-h>",
                        down = "<C-j>",
                        up = "<C-k>",
                        right = "<C-l>",
                        last_active = "<C-\\>",
                        next = "<C-Space>",
                    }
                }
            end
            set_keymaps()

            vim.api.nvim_create_autocmd("TermEnter", {
                callback = set_keymaps,
            })
        end
    },
    {
        "nickjvandyke/opencode.nvim",
        version = "*", -- Latest stable release
        -- dependencies = {
        --     {
        --         -- `snacks.nvim` integration is recommended, but optional
        --         ---@module "snacks" <- Loads `snacks.nvim` types for configuration intellisense
        --         "folke/snacks.nvim",
        --         optional = true,
        --         opts = {
        --             input = {}, -- Enhances `ask()`
        --             picker = {  -- Enhances `select()`
        --                 actions = {
        --                     opencode_send = function(...) return require("opencode").snacks_picker_send(...) end,
        --                 },
        --                 win = {
        --                     input = {
        --                         keys = {
        --                             ["<a-a>"] = { "opencode_send", mode = { "n", "i" } },
        --                         },
        --                     },
        --                 },
        --             },
        --         },
        --     },
        -- },
        config = function()
            ---@type opencode.Opts
            vim.g.opencode_opts = {
                -- Your configuration, if any; goto definition on the type or field for details
            }

            vim.o.autoread = true -- Required for `opts.events.reload`

            -- Recommended/example keymaps
            vim.keymap.set({ "n", "x" }, "<C-a>", function() require("opencode").ask("@this: ", { submit = true }) end,
                { desc = "Ask opencode…" })
            vim.keymap.set({ "n", "x" }, "<C-x>", function() require("opencode").select() end,
                { desc = "Execute opencode action…" })
            vim.keymap.set({ "n", "t" }, "<leader>.", function() require("opencode").toggle() end,
                { desc = "Toggle opencode" })

            vim.keymap.set({ "n", "x" }, "go", function() return require("opencode").operator("@this ") end,
                { desc = "Add range to opencode", expr = true })
            vim.keymap.set("n", "goo", function() return require("opencode").operator("@this ") .. "_" end,
                { desc = "Add line to opencode", expr = true })

            vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end,
                { desc = "Scroll opencode up" })
            vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end,
                { desc = "Scroll opencode down" })

            -- You may want these if you use the opinionated `<C-a>` and `<C-x>` keymaps above — otherwise consider `<leader>o…` (and remove terminal mode from the `toggle` keymap)
            vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
            vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })
        end,
    },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = { "nvim-lua/plenary.nvim",
            { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }, }

    },

    -- Syntax Highlighting & Parsing
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,    -- this plugin does not support lazy-loading
        branch = 'main', -- REQUIRED for Neovim 0.12+ (master is locked to <=0.11)
        build = ":TSUpdate",
    },
    { "shaunsingh/nord.nvim" },
    { "catppuccin/nvim",                    name = "catppuccin", priority = 1000 },
    { "windwp/nvim-ts-autotag" },
    { "alker0/chezmoi.vim" },

    -- File Navigation
    { "ThePrimeagen/harpoon" },

    -- Undo Tree
    { "mbbill/undotree" },

    -- Git Integration
    { "tpope/vim-fugitive" },
    { "tpope/vim-rhubarb" },
    { "lewis6991/gitsigns.nvim" },

    -- Surround text easily
    { "tpope/vim-surround" },
    { "tpope/vim-repeat" },

    -- Tmux Navigation
    -- { "christoomey/vim-tmux-navigator"

    -- Commenting
    { "numToStr/Comment.nvim" },

    -- Statusline
    { "nvim-lualine/lualine.nvim" },

    -- Indentation
    { "lukas-reineke/indent-blankline.nvim" },
    { "tpope/vim-sleuth" },

    -- LSP & Autocompletion
    { "neovim/nvim-lspconfig" },
    { "mason-org/mason.nvim" },
    {
        "mason-org/mason-lspconfig.nvim",
        opts = {},
        dependencies = {
            { "mason-org/mason.nvim", opts = {} },
            "neovim/nvim-lspconfig",
        },
    },
    { "L3MON4D3/LuaSnip" },
    { "rafamadriz/friendly-snippets" },
    { "j-hui/fidget.nvim" },
    {
        "folke/trouble.nvim",
        opts = {}, -- for default options, refer to the configuration section for custom setup.
        cmd = "Trouble",
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Diagnostics (Trouble)",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                desc = "Buffer Diagnostics (Trouble)",
            },
            {
                "<leader>cs",
                "<cmd>Trouble symbols toggle focus=false<cr>",
                desc = "Symbols (Trouble)",
            },
            {
                "<leader>cl",
                "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                desc = "LSP Definitions / references / ... (Trouble)",
            },
            {
                "<leader>xL",
                "<cmd>Trouble loclist toggle<cr>",
                desc = "Location List (Trouble)",
            },
            {
                "<leader>xQ",
                "<cmd>Trouble qflist toggle<cr>",
                desc = "Quickfix List (Trouble)",
            },
        },
    },
    {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
            library = {
                -- See the configuration section for more details
                -- Load luvit types when the `vim.uv` word is found
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
    { -- optional cmp completion source for require statements and module annotations
        "hrsh7th/nvim-cmp",
        opts = function(_, opts)
            opts.sources = opts.sources or {}
            table.insert(opts.sources, {
                name = "lazydev",
                group_index = 0, -- set group index to 0 to skip loading LuaLS completions
            })
        end,
    },
    { -- optional blink completion source for require statements and module annotations
        "saghen/blink.cmp",
        opts = {
        },
    },
    {
        'saghen/blink.cmp',
        -- optional: provides snippets for the snippet source
        dependencies = { 'rafamadriz/friendly-snippets' },

        -- use a release tag to download pre-built binaries
        version = '1.*',
        -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
        -- build = 'cargo build --release',
        -- If you use nix, you can build from source using latest nightly rust with:
        -- build = 'nix run .#build-plugin',

        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            -- 'default' (recommended) for mappings similar to built-in completions (C-y to accept)
            -- 'super-tab' for mappings similar to vscode (tab to accept)
            -- 'enter' for enter to accept
            -- 'none' for no mappings
            --
            -- All presets have the following mappings:
            -- C-space: Open menu or open docs if already open
            -- C-n/C-p or Up/Down: Select next/previous item
            -- C-e: Hide menu
            -- C-k: Toggle signature help (if signature.enabled = true)
            --
            -- See :h blink-cmp-config-keymap for defining your own keymap
            keymap = {
                preset = 'default',
                ["<C-n>"] = { "select_next", "fallback" },
                ["<C-p>"] = { "select_prev", "fallback" },
            },

            appearance = {
                -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
                -- Adjusts spacing to ensure icons are aligned
                nerd_font_variant = 'mono'
            },

            -- (Default) Only show the documentation popup when manually triggered
            completion = { documentation = { auto_show = false } },

            -- Default list of enabled providers defined so that you can extend it
            -- elsewhere in your config, without redefining it, due to `opts_extend`

            sources = {
                -- add lazydev to your completion providers
                default = { "lazydev", "lsp", "path", "snippets", "buffer" },
                providers = {
                    lazydev = {
                        name = "LazyDev",
                        module = "lazydev.integrations.blink",
                        -- make lazydev completions top priority (see `:h blink.cmp`)
                        score_offset = 100,
                    },
                },
            },

            -- (Default) Rust fuzzy matcher for typo resistance and significantly better performance
            -- You may use a lua implementation instead by using `implementation = "lua"` or fallback to the lua implementation,
            -- when the Rust fuzzy matcher is not available, by using `implementation = "prefer_rust"`
            --
            -- See the fuzzy documentation for more information
            fuzzy = { implementation = "prefer_rust_with_warning" }
        },
        opts_extend = { "sources.default" }
    },
    { 'hrsh7th/cmp-nvim-lsp' },
    { 'hrsh7th/cmp-buffer' },
    { 'hrsh7th/cmp-path' },
    { 'hrsh7th/cmp-cmdline' },
    { 'L3MON4D3/LuaSnip' },
    { 'saadparwaiz1/cmp_luasnip' },
    -- Jupyter Notebook Support
    { "jpalardy/vim-slime" },
    -- { "hanschen/vim-ipython-cell" },
    { "bfredl/nvim-ipy" },

    -- Debugging
    { "mfussenegger/nvim-dap" },
    { "mfussenegger/nvim-dap-python" },
    { "rcarriga/nvim-dap-ui" },
    { "nvim-neotest/nvim-nio" },
    { "jay-babu/mason-nvim-dap.nvim" },

    -- Codicons for nvim-dap-ui
    { "mortepau/codicons.nvim" },

    -- Colorizer
    { "norcalli/nvim-colorizer.lua" },

    -- Markdown Preview & Highlighting
    {
        "ellisonleao/glow.nvim",
        config = function() require("glow").setup() end
    },
    -- Jupyter Ascending
    { "untitled-ai/jupyter_ascending.vim" },

    -- Auto close pairs
    { "m4xshen/autoclose.nvim" },

    -- LaTeX
    { "lervag/vimtex" },

    -- File Explorer
    {
        "stevearc/oil.nvim",
        config = function()
            require("oil").setup()
        end,
    },

    -- Notifications
    { "rcarriga/nvim-notify" },

    -- Pomodoro Timer
    {
        "epwalsh/pomo.nvim",
        dependencies = { "rcarriga/nvim-notify" }
    },

    -- Obsidian Notes Integration
    {
        "epwalsh/obsidian.nvim",
        dependencies = { "nvim-lua/plenary.nvim" }
    },

    -- Icons
    { "nvim-tree/nvim-web-devicons" },

    -- CSV Highlighting
    { "mechatroner/rainbow_csv" },
    {
        "pwntester/octo.nvim",
        cmd = "Octo",
        opts = {
            -- or "fzf-lua" or "snacks" or "default"
            picker = "telescope",
            -- bare Octo command opens picker of commands
            enable_builtin = true,
        },
        keys = {
            {
                "<leader>oi",
                "<CMD>Octo issue list<CR>",
                desc = "List GitHub Issues",
            },
            {
                "<leader>op",
                "<CMD>Octo pr list<CR>",
                desc = "List GitHub PullRequests",
            },
            {
                "<leader>od",
                "<CMD>Octo discussion list<CR>",
                desc = "List GitHub Discussions",
            },
            {
                "<leader>on",
                "<CMD>Octo notification list<CR>",
                desc = "List GitHub Notifications",
            },
            {
                "<leader>os",
                function()
                    require("octo.utils").create_base_search_command { include_current_repo = true }
                end,
                desc = "Search GitHub",
            },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
            -- OR "ibhagwan/fzf-lua",
            -- OR "folke/snacks.nvim",
            "nvim-tree/nvim-web-devicons", -- optional if file_panel.icons is a function
        },
    },
    { "sindrets/diffview.nvim" },
    {
        "kdheepak/lazygit.nvim",
        lazy = true,
        cmd = {
            "LazyGit",
            "LazyGitConfig",
            "LazyGitCurrentFile",
            "LazyGitFilter",
            "LazyGitFilterCurrentFile",
        },
        -- optional for floating window border decoration
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        -- setting the keybinding for LazyGit with 'keys' is recommended in
        -- order to load the plugin when the command is run for the first time
        keys = {
            { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
        }
    },
    {
        "ThePrimeagen/git-worktree.nvim",
        dependencies = { "nvim-telescope/telescope.nvim" },
        config = function()
            require("git-worktree").setup()
            require("telescope").load_extension("git_worktree")
        end,
        keys = {
            {
                "<leader>gw",
                function()
                    require("telescope").extensions.git_worktree.git_worktrees()
                end,
                desc = "Switch Worktrees",
            },
            {
                "<leader>gW",
                function()
                    require("telescope").extensions.git_worktree.create_git_worktree()
                end,
                desc = "Create Worktree",
            },
        },
    },
    {
        "iamcco/markdown-preview.nvim",
        cmd = { 'MarkdownPreviewToggle', 'MarkdownPreview', 'MarkdownPreviewStop' },
        ft = { 'markdown' },
        build = function()
            vim.cmd [[Lazy load markdown-preview.nvim]]
            vim.fn['mkdp#util#install']()
        end,
    },
})
