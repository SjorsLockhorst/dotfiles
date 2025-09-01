require("fidget").setup()
require("mason").setup()

local luasnip = require("luasnip")

vim.lsp.config('lua_ls', {
  on_init = function(client)
    if client.workspace_folders then
      local path = client.workspace_folders[1].name
      if
          path ~= vim.fn.stdpath('config')
          and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc'))
      then
        return
      end
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        version = 'LuaJIT',
        path = {
          'lua/?.lua',
          'lua/?/init.lua',
        },
      },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME
        }
      }
    })
  end,
  settings = {
    Lua = {}
  }
})


vim.lsp.config("pylsp", {
  settings = {
    pylsp = {
      plugins = {}
    }
  }
})


local capabilities = {
  textDocument = {
    foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true
    }
  }
}

capabilities = require('blink.cmp').get_lsp_capabilities(capabilities)
-- or equivalently

local capabilities = vim.lsp.protocol.make_client_capabilities()

capabilities = vim.tbl_deep_extend('force', capabilities, require('blink.cmp').get_lsp_capabilities({}, false))

capabilities = vim.tbl_deep_extend('force', capabilities, {
  textDocument = {
    foldingRange = {
      dynamicRegistration = false,
      lineFoldingOnly = true
    }
  }
})

-- Make sure mappings are only used when an lsp is available
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf, remap = false }

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
    vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, { buffer = args.buf, remap = true })

    -- Lesser used LSP functionality
    vim.keymap.set("n", 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set("n", '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set("n", '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set("n", '<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
  end
})

vim.diagnostic.config({
  virtual_text = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '',
      [vim.diagnostic.severity.WARN] = '',
      [vim.diagnostic.severity.INFO] = '',
      [vim.diagnostic.severity.HINT] = '',
    }
  }
})


vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)

require("luasnip.loaders.from_vscode").lazy_load()

local s = luasnip.snippet
local t = luasnip.text_node
local i = luasnip.insert_node

luasnip.add_snippets("markdown", {
  s("task", {
    t("- [ ] "),
    i(1, "Task"),
  }),
}, { key = "all" })
