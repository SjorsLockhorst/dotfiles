-- Learn the keybindings, see :help lsp-zero-keybindings
-- Learn to configure LSP servers, see :help lsp-zero-api-showcase
-- Setup neovim lua configuration
require('neodev').setup({
  library = { plugins = { "nvim-dap-ui" }, type = true }
})
require("fidget").setup()

local lsp = require('lsp-zero')
local nvim_lsp = require('lspconfig')


lsp.preset('recommended')

lsp.configure("pylsp", {
  -- on_attach = function() print("test") end,
  settings = {
    pylsp = {
      plugins = {
        pycodestyle = {
          enabled = false
        },
        pyflakes = {
          enabled = false
        }
      }
    }
  }
})

local function FixAll()
  vim.lsp.buf.code_action({ context = { only = { "source.fixAll" } }, apply = true })
  vim.lsp.buf.format()
end

lsp.configure("ruff_lsp", {
  on_attach = function() vim.keymap.set("n", "<leader>fa", FixAll) end
})


-- Change default lsp mappings
local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }
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
local on_attach = lsp.on_attach(function(client, bufnr)
  local opts = { buffer = bufnr, remap = false }

  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  -- Default
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "gr", require("telescope.builtin").lsp_references, opts)
  vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts)
  vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
  vim.keymap.set("n", "<leader>ds", require("telescope.builtin").lsp_document_symbols, opts)
  vim.keymap.set("n", "<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, opts)

  vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
  vim.keymap.set("i", "<C-k>", vim.lsp.buf.signature_help, opts)

  -- Lesser used LSP functionality
  vim.keymap.set("n", 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set("n", '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
  vim.keymap.set("n", '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
  vim.keymap.set("n", '<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, opts)

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })

  if client.name == 'tailwindcss' then
    -- Init tailwindcss colors
    require("tailwindcss-colors").buf_attach(bufnr)
  end

end)

nvim_lsp["tailwindcss"].setup({
  -- other settings --
  on_attach = on_attach,
})

lsp.nvim_workspace()
lsp.setup()

vim.diagnostic.config({
  virtual_text = true,
})

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)

-- Remove weird panda parameter emoji that's unsupported
local cfg = {
  hint_prefix = "", -- Panda for parameter, NOTE: for the terminal not support emoji, might crash
}

require('lsp_signature').setup(cfg)
