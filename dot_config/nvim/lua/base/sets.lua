vim.o.nu = true
vim.o.relativenumber=true
vim.wo.number = true

vim.o.mouse = "a"

vim.o.splitbelow = true
vim.o.splitright = true

vim.o.cursorline = true

vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.smarttab = true
vim.o.breakindent = true

vim.o.smartindent = true
vim.o.filetype = true

vim.o.wrap = false

vim.o.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.o.undofile = true

vim.o.hlsearch = false
vim.o.incsearch = true

vim.o.termguicolors = true

vim.o.scrolloff = 8

vim.o.updatetime=250
vim.o.timeoutlen=500
vim.wo.signcolumn = "yes"
vim.o.colorcolumn = "88"
vim.o.completeopt = "menuone,noselect"

vim.o.clipboard = "unnamedplus"
vim.g.python3_host_prog = "~/nvim-env/bin/python3"

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})
