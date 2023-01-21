-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function(use)
	-- Packer can manage itself
	use('wbthomason/packer.nvim')
	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.1',
		-- or                            , branch = '0.1.x',
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

	use('nvim-treesitter/nvim-treesitter', {run = ':TSUpdate'})
    use('alker0/chezmoi.vim')

	use('ThePrimeagen/harpoon')
	use('mbbill/undotree')
	use('tpope/vim-fugitive')
	use('tpope/vim-surround')


    -- Tmux integration
    use('tmux-plugins/vim-tmux-focus-events')
    use('christoomey/vim-tmux-navigator')

    -- Easier coding
    use('tpope/vim-commentary')
    use('vim-airline/vim-airline')
    use('jiangmiao/auto-pairs')


    -- Web programming
    -- use('alvan/vim-closetag')
    -- use('AndrewRadev/tagalong.vim')

	use {
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v1.x',
		requires = {
			-- LSP Support
			{'neovim/nvim-lspconfig'},             -- Required
			{'williamboman/mason.nvim'},           -- Optional
			{'williamboman/mason-lspconfig.nvim'}, -- Optional

			-- Autocompletion
			{'hrsh7th/nvim-cmp'},         -- Required
			{'hrsh7th/cmp-nvim-lsp'},     -- Required
			{'hrsh7th/cmp-buffer'},       -- Optional
			{'hrsh7th/cmp-path'},         -- Optional
			{'saadparwaiz1/cmp_luasnip'}, -- Optional
			{'hrsh7th/cmp-nvim-lua'},     -- Optional

			-- Snippets
			{'L3MON4D3/LuaSnip'},             -- Required
			{'rafamadriz/friendly-snippets'}, -- Optional
		}
	}
end)
