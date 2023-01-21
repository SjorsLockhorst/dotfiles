-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- Packer can manage itself
	use('wbthomason/packer.nvim')
	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.1',
		requires = { {'nvim-lua/plenary.nvim'} }
	}
    -- Colors
	use({
		'rose-pine/neovim',
		as = 'rose-pine',
		config = function()
			require("rose-pine").setup()
		end
	})
    use('arcticicestudio/nord-vim')

    -- Syntax parsing
	use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})

    -- Syntax for chezmoi specific files
    use('alker0/chezmoi.vim')

    -- Set a command to map to a specific file
	use('ThePrimeagen/harpoon')

    -- An undo tree for more elaborate undo's
	use('mbbill/undotree')

    -- Vim Git integration
	use('tpope/vim-fugitive')

    -- Easy surrounding of brackents, parentheses etc.
	use('tpope/vim-surround')

    -- Tmux integration
    use('tmux-plugins/vim-tmux-focus-events')
    use('christoomey/vim-tmux-navigator')

    -- Shortcuts for comments
    use('tpope/vim-commentary')

    -- Enable an airline
    use('vim-airline/vim-airline')

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
		}
	}


    -- Unused, from old setup

    -- use('jiangmiao/auto-pairs')
    -- Web programming
    -- use('alvan/vim-closetag')
    -- use('AndrewRadev/tagalong.vim')

end)
