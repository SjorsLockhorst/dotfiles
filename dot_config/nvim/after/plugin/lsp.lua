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

-- Change default lsp mappings
local cmp = require('cmp')
local cmp_select = {behavior = cmp.SelectBehavior.Select}
local cmp_mappings = lsp.defaults.cmp_mappings({
  ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
  ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
  ['<C-y>'] = cmp.mapping.confirm({ select = true }),
  ["<C-Space>"] = cmp.mapping.complete(),
})
cmp_mappings['<Tab>'] = nil
cmp_mappings['<S-Tab>'] = nil

lsp.setup_nvim_cmp({
  mapping = cmp_mappings
})

-- Make sure mappings are only used when an lsp is available
lsp.on_attach(function(client, bufnr)
  local opts = {buffer = bufnr, remap = false}

  -- Default
  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
  vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
  vim.keymap.set("n", "gr", function() vim.lsp.buf.references() end, opts)
  -- TODO: Change this to be something that currently isn't mapped to
  vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
  vim.keymap.set("n", "gl", function() vim.diagnostic.open_float() end, opts)

  -- Custom
  -- vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
  vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)

end)

lsp.nvim_workspace()
lsp.setup()

vim.diagnostic.config({
    virtual_text = true,
})
