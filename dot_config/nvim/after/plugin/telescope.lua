require("telescope").setup({
  defaults = {
    -- rg args used by live_grep / grep_string. Tuned to keep the UI from
    -- stalling on large codebases: cap absurdly long lines and skip dirs/files
    -- that produce huge, useless match floods on short queries.
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
      '--max-columns=200',           -- don't ship minified/one-line files into Lua
      '--max-columns-preview',
      '--glob=!**/.git/*',
      '--glob=!**/node_modules/*',
      '--glob=!**/*.min.*',
      '--glob=!**/*.lock',
      '--glob=!**/package-lock.json',
    },
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = 'smart_case',
    },
  },
})

-- Enable telescope fzf native (compiled C sorter; installed via lazy.lua).
require('telescope').load_extension('fzf')

local function in_git_repo()
  local handle = io.popen("git rev-parse --is-inside-work-tree 2> /dev/null")
  if handle then
    local result = handle:read("*a")
    handle:close()
    return result:find("true") ~= nil
  else
    return false
  end
end

local function find_files()
  if in_git_repo() then
    require('telescope.builtin').git_files()
  else
    require('telescope.builtin').find_files({ hidden = true })
  end
end

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer]' })

vim.keymap.set('n', '<C-f>', find_files)
vim.keymap.set('n', '<leader>sf', function() require('telescope.builtin').find_files({ hidden = true }) end,
  { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
