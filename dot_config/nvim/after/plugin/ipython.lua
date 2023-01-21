-- slime configuration 
-- always use tmux


vim.api.nvim_set_var('slime_target', 'tmux')

-- fix paste issues in ipython
vim.api.nvim_set_var(
    "ipython_cell_tag",
    {"# |%%--%%|", "# %%", "#%%", "# <codecell>"}
)
-- always send text to the top-right pane in the current tmux tab without asking
-- vim.api.nvim_exec(
-- [[
-- let g:slime_default_config = {
--     \ 'socket_name': 'default,
--     \ 'target_pane': '{top-right}' }
-- ]]
-- )

-- vim.api.nvim_set_var('slime_dont_ask_default', 1)

-- ipython-cell configuration

-- map <Leader>s to start IPython
vim.keymap.set('n', '<Leader>ss', ':SlimeSend1 ipython --matplotlib<CR>')

-- map <Leader>r to run script
vim.keymap.set('n', '<Leader>pra', ':IPythonCellRun<CR>')

-- map <Leader>R to run script and time the execution
vim.keymap.set('n', '<Leader>rat', ':IPythonCellRunTime<CR>')

-- map <Leader>c to execute the current cell
vim.keymap.set('n', '<Leader>rc', ':IPythonCellExecuteCell<CR>')

-- map <Leader>C to execute the current cell and jump to the next cell
vim.keymap.set('n', '<Leader>C', ':IPythonCellExecuteCellJump<CR>')

-- map <Leader>l to clear IPython screen
vim.keymap.set('n', '<Leader>pcl', ':IPythonCellClear<CR>')

-- map <Leader>x to close all Matplotlib figure windows
 vim.keymap.set('n', '<Leader>pcc', ':IPythonCellClose<CR>')

-- map [c and ]c to jump to the previous and next cell header
vim.keymap.set('n', '[c', ':IPythonCellPrevCell<CR>')
vim.keymap.set('n', ']c', ':IPythonCellNextCell<CR>')

-- map <Leader>h to send the current line or current selection to IPython
vim.keymap.set("n", "<leader>h", "<Plug>SlimeLineSend")
vim.keymap.set("v", "<leader>h", "<Plug>SlimeRegionSend")

-- map <Leader>p to run the previous command
-- vim.keymap.set('n', '<Leader>p', ':IPythonCellPrevCommand<CR>')

-- map <Leader>Q to restart ipython
-- vim.keymap.set('n', '<Leader>Q', ':IPythonCellRestart<CR>')

-- map <Leader>d to start debug mode
-- vim.keymap.set('n', '<Leader>d :SlimeSend1', '%debug<CR>')

-- map <Leader>q to exit debug mode or IPython
-- vim.keymap.set('n', '<Leader>q :SlimeSend1', 'exit<CR>')

-- map <F9> and <F10> to insert a cell header tag above/below and enter insert mode
-- nmap <F9> :IPythonCellInsertAbove<CR>a
-- nmap <F10> :IPythonCellInsertBelow<CR>a

-- also make <F9> and <F10> work in insert mode
-- imap <F9> <C-o>:IPythonCellInsertAbove<CR>
-- imap <F10> <C-o>:IPythonCellInsertBelow<CR>
