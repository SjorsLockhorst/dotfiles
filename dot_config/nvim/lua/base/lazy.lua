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
        "nvim-telescope/telescope.nvim",
        tag = "0.1.4",
        dependencies = { "nvim-lua/plenary.nvim" }
    },

    -- Syntax Highlighting & Parsing
    {
        "nvim-treesitter/nvim-treesitter",
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
    { "christoomey/vim-tmux-navigator" },

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
    { "hanschen/vim-ipython-cell" },
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
    {
        "iamcco/markdown-preview.nvim",
        build = function() vim.fn["mkdp#util#install"]() end
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
        "yetone/avante.nvim",
        -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
        -- ⚠️ must add this setting! ! !
        build = function()
            -- conditionally use the correct build system for the current OS
            if vim.fn.has("win32") == 1 then
                return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
            else
                return "make"
            end
        end,
        event = "VeryLazy",
        version = false, -- Never set this value to "*"! Never!
        ---@module 'avante'
        ---@type avante.Config
        opts = {
            -- add any opts here
            -- for example
            provider = "claude",
            providers = {
                claude = {
                    endpoint = "https://api.anthropic.com",
                    model = "claude-sonnet-4-20250514",
                    timeout = 30000, -- Timeout in milliseconds
                    extra_request_body = {
                        temperature = 0.75,
                        max_tokens = 20480,
                    },
                },
            },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            --- The below dependencies are optional,
            "echasnovski/mini.pick",         -- for file_selector provider mini.pick
            "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
            "hrsh7th/nvim-cmp",              -- autocompletion for avante commands and mentions
            "ibhagwan/fzf-lua",              -- for file_selector provider fzf
            "stevearc/dressing.nvim",        -- for input provider dressing
            "folke/snacks.nvim",             -- for input provider snacks
            "nvim-tree/nvim-web-devicons",   -- or echasnovski/mini.icons
            "zbirenbaum/copilot.lua",        -- for providers='copilot'
            {
                -- support for image pasting
                "HakonHarnes/img-clip.nvim",
                event = "VeryLazy",
                opts = {
                    -- recommended settings
                    default = {
                        embed_image_as_base64 = false,
                        prompt_for_file_name = false,
                        drag_and_drop = {
                            insert_mode = true,
                        },
                        -- required for Windows users
                        use_absolute_path = true,
                    },
                },
            },
            {
                -- Make sure to set this up properly if you have lazy=true
                'MeanderingProgrammer/render-markdown.nvim',
                opts = {
                    file_types = { "markdown", "Avante" },
                },
                ft = { "markdown", "Avante" },
            },
        },
    }
})
