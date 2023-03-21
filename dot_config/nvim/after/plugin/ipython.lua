
-- IPythonCell definitions of what is a cell
vim.api.nvim_set_var(
    "ipython_cell_tag",
    {"# |%%--%%|", "# %%", "#%%", "# <codecell>"}
)

-- IPythonCell movements
vim.keymap.set('n', '[c', ':IPythonCellPrevCell<CR>')
vim.keymap.set('n', ']c', ':IPythonCellNextCell<CR>')
vim.keymap.set('n', '<leader>ca', ':IPythonCellInsertAbove<CR>')
vim.keymap.set('n', '<leader>cb', ':IPythonCellInsertBelow<CR>')
vim.keymap.set('n', '<leader>cm', ':IPythonCellToMarkdown<CR>')

-- Set cell definition for vim-ipy
vim.api.nvim_set_var('ipy_celldef', "^# %%")

local RunQtConsole = function()
    vim.fn.jobstart("jupyter qtconsole --JupyterWidget.include_other_output=True")
end

local ConnectQTConsole = function()
    vim.fn.IPyConnect("--no-window", "--existing")
end

-- Reset default mappings
vim.api.nvim_set_var('nvim_ipy_perform_mappings', 0)
vim.keymap.set('n', '<leader>rs', '<Plug>(IPy-Run)')
vim.keymap.set('v', '<leader>rs', '<Plug>(IPy-Run)')
vim.keymap.set('n', '<leader>rc', '<Plug>(IPy-RunCell)')
vim.keymap.set('n', '<leader>C', ':IPythonCellNextCell<CR> <Plug>(IPy-RunCell)')
vim.keymap.set('n', '<leader>ro', '<Plug>(IPy-RunOp)')
vim.keymap.set('n', '<leader>X', '<Plug>(IPy-Interrupt)')

-- TODO: Make this less flaky
vim.cmd("let @l = 'j rc]c'")
vim.keymap.set('n', '<leader>ra', ':g/^# %%/normal! @l<CR>')

vim.keymap.set('n','<leader>ss', function() RunQtConsole() end)
vim.keymap.set('n','<leader>sc', function() ConnectQTConsole() end)



-- vim.api.nvim_set_var('slime_target', 'tmux')
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
-- vim.keymap.set('n', '<Leader>t', ':w<CR> :SlimeSend1 pytest<CR>')

-- map <Leader>r to run script
-- vim.keymap.set('n', '<Leader>pra', ':IPythonCellRun<CR>')

-- map <Leader>R to run script and time the execution
-- vim.keymap.set('n', '<Leader>rat', ':IPythonCellRunTime<CR>')

-- map <Leader>c to execute the current cell
-- vim.keymap.set('n', '<Leader>rc', ':IPythonCellExecuteCell<CR>')

-- map <Leader>C to execute the current cell and jump to the next cell
-- vim.keymap.set('n', '<Leader>C', ':IPythonCellExecuteCellJump<CR>')

-- map <Leader>l to clear IPython screen
-- vim.keymap.set('n', '<Leader>pcl', ':IPythonCellClear<CR>')

-- map <Leader>x to close all Matplotlib figure windows
 -- vim.keymap.set('n', '<Leader>pcc', ':IPythonCellClose<CR>')

-- map [c and ]c to jump to the previous and next cell header

-- map <Leader>h to send the current line or current selection to IPython
-- vim.keymap.set("n", "<leader>h", "<Plug>SlimeLineSend")
-- vim.keymap.set("v", "<leader>h", "<Plug>SlimeRegionSend")

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
--

--
--
