-- Learn the keybindings, see :help lsp-zero-keybindings
-- Learn to configure LSP servers, see :help lsp-zero-api-showcase
local lsp = require('lsp-zero')
lsp.preset('recommended')

lsp.configure("pylsp", {
    settings = {
        pylsp = {
            plugins = {
                pycodestyle = {
                    enabled = false
                },
                flake8 = {
                    enabled = true,
                    executable = "pflake8"
                },
                pylint = {
                    enabled = true
                }
            }
        }
    }
})
lsp.nvim_workspace()
lsp.setup()

vim.diagnostic.config({
    virtual_text = true,
})
