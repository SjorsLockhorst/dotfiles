-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- Packer can manage itself
	use('wbthomason/packer.nvim')
	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.4',
		requires = { {'nvim-lua/plenary.nvim'} }
	}
    -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
    use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }

    -- Syntax parsing
    use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
    use('shaunsingh/nord.nvim')

    -- Headlines for markdown
    use {
        "lukas-reineke/headlines.nvim",
        after = "nvim-treesitter",
        config = function()
            require("headlines").setup()
        end,
    }

    -- Auto open and close tags with treesitter
    use('windwp/nvim-ts-autotag')

    -- Syntax for chezmoi specific files
    use('alker0/chezmoi.vim')

    -- Set a command to map to a specific file
	use('ThePrimeagen/harpoon')

    -- An undo tree for more elaborate undo's
	use('mbbill/undotree')

    -- Vim Git integration
	use('tpope/vim-fugitive')
    use('tpope/vim-rhubarb')
    use('lewis6991/gitsigns.nvim')
    -- Easy surrounding of brackents, parentheses etc.
    use('tpope/vim-surround')

    use("tpope/vim-repeat")

    -- Tmux integration
    use('tmux-plugins/vim-tmux-focus-events')
    use('christoomey/vim-tmux-navigator')

    -- Shortcuts for comments
    use('numToStr/Comment.nvim')

    -- Enable an airline
    use('nvim-lualine/lualine.nvim')

    -- Add identation guides even on blank lines
    use('lukas-reineke/indent-blankline.nvim')

    -- Detect tabstop and shiftwidth automatically
    use('tpope/vim-sleuth')


    -- Language Server Protocol
	use {
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v1.x',
		requires = {
			-- LSP Support
			{'neovim/nvim-lspconfig'},

            -- Mason, handler for installing external LSP's, linters etc.
			{'williamboman/mason.nvim'},
			{'williamboman/mason-lspconfig.nvim'},

			-- Autocompletion dependencies
			{'hrsh7th/nvim-cmp'},
			{'hrsh7th/cmp-nvim-lsp'},
			{'hrsh7th/cmp-buffer'},
			{'hrsh7th/cmp-path'},
			{'saadparwaiz1/cmp_luasnip'},
			{'hrsh7th/cmp-nvim-lua'},

			-- Snippets
			{'L3MON4D3/LuaSnip'},
			{'rafamadriz/friendly-snippets'},

            -- Useful status updates for LSP
            {'j-hui/fidget.nvim'},

            -- Additional Lua configuration
            {'folke/neodev.nvim'},
            {'ray-x/lsp_signature.nvim'}
		}
	}


    -- Jupyter notebook setup
    use('jpalardy/vim-slime')
    use ('hanschen/vim-ipython-cell')
    use('bfredl/nvim-ipy')

    -- Debugging
    use("mfussenegger/nvim-dap")
    use("mfussenegger/nvim-dap-python")
    use("rcarriga/nvim-dap-ui")
    use("jay-babu/mason-nvim-dap.nvim")

    -- Codicons for nvim dap ui
    use("mortepau/codicons.nvim")

    use("norcalli/nvim-colorizer.lua")

    use {"ellisonleao/glow.nvim", config = function() require("glow").setup() end}

    use({
	"iamcco/markdown-preview.nvim",
	run = function() vim.fn["mkdp#util#install"]() end,
    })
    use("untitled-ai/jupyter_ascending.vim")

    -- Auto close
    use("m4xshen/autoclose.nvim")

end)
