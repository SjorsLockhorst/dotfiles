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

vim.g.tabby_keybinding_accept = '<Tab>'

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
    { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
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
    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v1.x",
        dependencies = {
            "neovim/nvim-lspconfig",
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/nvim-cmp",
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "saadparwaiz1/cmp_luasnip",
            "hrsh7th/cmp-nvim-lua",
            "L3MON4D3/LuaSnip",
            "rafamadriz/friendly-snippets",
            "j-hui/fidget.nvim",
            "folke/neodev.nvim",
            "ray-x/lsp_signature.nvim"
        }
    },
    { "rafamadriz/friendly-snippets" },

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
    {
        "lukas-reineke/headlines.nvim",
        dependencies = "nvim-treesitter/nvim-treesitter",
        config = true, -- or `opts = {}`
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
        event = "VeryLazy",
        version = false, -- Never set this value to "*"! Never!
        opts = {
            provider = "claude", -- The provider used in Aider mode or in the planning phase of Cursor Planning Mode
            -- WARNING: Since auto-suggestions are a high-frequency operation and therefore expensive,
            -- currently designating it as `copilot` provider is dangerous because: https://github.com/yetone/avante.nvim/issues/1048
            -- Of course, you can reduce the request frequency by increasing `suggestion.debounce`.
            auto_suggestions_provider = "claude",
            cursor_applying_provider = nil, -- The provider used in the applying phase of Cursor Planning Mode, defaults to nil, when nil uses Config.provider as the provider for the applying phase
            claude = {
                endpoint = "https://api.anthropic.com",
                model = "claude-3-5-sonnet-20241022",
                temperature = 0,
                max_tokens = 4096,
                disable_tools = true
            },
            -- add any opts here
            -- WARNING: Since auto-suggestions are a high-frequency operation and therefore expensive,
            -- currently designating it as `copilot` provider is dangerous because: https://github.com/yetone/avante.nvim/issues/1048
            -- Of course, you can reduce the request frequency by increasing `suggestion.debounce`.
        },
        -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
        build = "make",
        -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
            "stevearc/dressing.nvim",
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            --- The below dependencies are optional,
            "echasnovski/mini.pick", -- for file_selector provider mini.pick
            "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
            "hrsh7th/nvim-cmp",      -- autocompletion for avante commands and mentions
            "ibhagwan/fzf-lua",      -- for file_selector provider fzf
            "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
            "zbirenbaum/copilot.lua", -- for providers='copilot'
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
