
local telescope = require("telescope")
telescope.load_extension("workspaces")

local builtin = require('telescope.builtin')


vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
vim.keymap.set('n', '<C-p>', builtin.git_files, {})
vim.keymap.set('n', '<leader>ps', function()
	builtin.grep_string({ search = vim.fn.input("Grep > ") });
end)
vim.keymap.set('n', '<leader>b', builtin.buffers, {})
vim.keymap.set("n", "<leader>w", "<cmd>Telescope workspaces<cr>")
