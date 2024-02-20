-- Learn the keybindings, see :help lsp-zero-keybindings
-- Learn to configure LSP servers, see :help lsp-zero-api-showcase
-- Setup neovim lua configuration
require('neodev').setup({
  library = { plugins = { "nvim-dap-ui" }, type = true }
})
require("fidget").setup()
local lsp = require('lsp-zero')
local luasnip = require("luasnip")

local has_words_before = function()
  unpack = unpack or table.unpack
  local line, col = unpack(vim.api.nvim_win_get_cursor(0))
  return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

lsp.preset('recommended')

lsp.configure("pylsp", {
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
lsp.configure("vetur", {
  format = {
    enable = false
  }
})
lsp.configure("eslint", {
  filetypes = { "vue" },
  on_attach = function(_, bufnr)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      command = "EslintFixAll",
    })
  end,
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
local cmp_mappings = lsp.defaults.cmp_mappings({
  -- Disable certain defaults
  ["<CR>"] = cmp.config.disable,
  ['<Tab>'] = cmp.config.disable,
  ['<S-Tab>'] = cmp.config.disable,

  -- Scrolling through docs
  ['<C-b>'] = cmp.mapping.scroll_docs(-4),
  ['<C-f>'] = cmp.mapping.scroll_docs(4),

  -- Select next option / jump to next position in snippet
  ["<C-n>"] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_next_item()
      -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
      -- that way you will only jump inside the snippet region
    elseif luasnip.expand_or_jumpable() then
      luasnip.expand_or_jump()
    elseif has_words_before() then
      cmp.complete()
    else
      fallback()
    end
  end, { "i", "s" }),

  -- Select prev option / jumpt to prev position in snippet
  ["<C-p>"] = cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.select_prev_item()
    elseif luasnip.jumpable(-1) then
      luasnip.jump(-1)
    else
      fallback()
    end
  end, { "i", "s" }),
  ['<C-y>'] = cmp.mapping.confirm({ select = true }),
  ["<C-Space>"] = cmp.mapping.complete(),
})

lsp.setup_nvim_cmp({
  mapping = cmp_mappings
})

-- Make sure mappings are only used when an lsp is available
lsp.on_attach(function(_, bufnr)
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
  vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, { buffer = bufnr, remap = true })

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
end)

lsp.nvim_workspace()
lsp.setup()

vim.diagnostic.config({
  virtual_text = true,
})

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)

require("luasnip.loaders.from_vscode").lazy_load()
