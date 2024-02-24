vim.g.slime_target = "tmux"
vim.g.slime_paste_file = vim.fn.expand("$HOME/.slime_paste")

vim.keymap.set("n", "<leader>l", "<Plug>SlimeLineSend")
vim.keymap.set("v", "<leader>s", "<Plug>SlimeRegionSend")
vim.keymap.set("n", "<leader>s", "<Plug>SlimeSendCell")
vim.keymap.set('n', '<leader>sf', ':%SlimeSend<CR>', { noremap = true, silent = true })


-- always send text to the top-right pane in the current tmux tab without asking
vim.g.slime_default_config = {
  socket_name = 'default',
  target_pane = '{top-right}'
}
vim.g.slime_dont_ask_default = 1

function OpenTmuxRepl(repl_command)
  vim.cmd("silent !tmux split-window -h\\; last-pane") -- Create a vertical split in Tmux
  ReplSend(repl_command)
end

function CloseTmuxRepl()
  vim.cmd("silent !tmux kill-pane -t {top-right}")
end

function ReplSend(repl_command)
  vim.cmd(string.format("SlimeSend1 %s", repl_command))
end



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
-- local RunQtConsole = function()
--     vim.fn.jobstart("jupyter qtconsole --JupyterWidget.include_other_output=True")
-- end
--
-- local ConnectQTConsole = function()
--     vim.fn.IPyConnect("--no-window", "--existing")
-- end
--
-- -- Reset default mappings
-- vim.api.nvim_set_var('nvim_ipy_perform_mappings', 0)
-- vim.keymap.set('n', '<leader>rs', '<Plug>(IPy-Run)')
-- vim.keymap.set('v', '<leader>rs', '<Plug>(IPy-Run)')
-- vim.keymap.set('n', '<leader>rc', '<Plug>(IPy-RunCell)')
-- vim.keymap.set('n', '<leader>C', ':IPythonCellNextCell<CR> <Plug>(IPy-RunCell)')
-- vim.keymap.set('n', '<leader>ro', '<Plug>(IPy-RunOp)')
-- vim.keymap.set('n', '<leader>X', '<Plug>(IPy-Interrupt)')

-- TODO: Make this less flaky
-- vim.cmd("let @l = 'j rc]c'")
-- vim.keymap.set('n', '<leader>ra', ':g/^# %%/normal! @l<CR>')
--
-- vim.keymap.set('n','<leader>ss', function() RunQtConsole() end)
-- vim.keymap.set('n','<leader>sc', function() ConnectQTConsole() end)
--
