vim.o.colorcolumn = "88"

vim.b.slime_bracketed_paste = 1
vim.b.slime_cell_delimiter = "# %%"

-- IPythonCell definitions of what is a cell
vim.g.ipython_cell_tag = { "# |%%--%%|", "# %%", "#%%", "# <codecell>" }

-- Set cell definition for vim-ipy
vim.g.ipy_celldef = "^# %%"

-- IPythonCell movements
vim.keymap.set('n', '[c', ':IPythonCellPrevCell<CR>')
vim.keymap.set('n', ']c', ':IPythonCellNextCell<CR>')

local function insertCellAndEdit(insertionCommand)
    vim.cmd(insertionCommand)
    vim.api.nvim_feedkeys('o', 'n', false)
end

local function insertCellBelow()
    insertCellAndEdit("IPythonCellInsertBelow")
end

local function insertCellAbove()
    insertCellAndEdit("IPythonCellInsertAbove")
end

local function runAndNext()
    vim.api.nvim_feedkeys(
        vim.api.nvim_replace_termcodes('<Plug>SlimeSendCell', true, true, true),
        'n',
        true
    )
    vim.schedule(function()
        vim.cmd("IPythonCellNextCell")
    end
    )
end

local function runTest()
    -- Get the absolute path of the current buffer
    local file_path = vim.fn.expand('%:p')  -- This gives the absolute path of the current buffer

    -- Construct the Python unittest command
    local test_command = "python -m unittest " .. file_path

    -- Use 'SlimeSend1' plug mapping to send the command to the REPL/terminal
    local send_command = "SlimeSend1 " .. test_command .. "\n"

    -- Feed the keys into Slime (native Lua function to send keys)
    vim.cmd(send_command)
end



vim.keymap.set('n', '<leader>aa', insertCellAbove)
vim.keymap.set('n', '<leader>bb', insertCellBelow)
vim.keymap.set('n', '<leader>cm', ':IPythonCellToMarkdown<CR>')

vim.keymap.set('n', '<leader>re', function() OpenTmuxRepl("ipython3") end)
vim.keymap.set('n', '<leader>rr', function()
    ReplSend("exit")
    ReplSend("ipython3")
end)
vim.keymap.set('n', '<leader>rq', function() CloseTmuxRepl() end)

vim.keymap.set('n', '<leader>jn', function() OpenTmuxRepl("jupyter console --existing") end)
vim.keymap.set("n", "<leader>jnq", function()
    vim.cmd("SlimeSend1 quit(keep_kernel=True)")
    vim.cmd("SlimeSend1 exit")
end)
vim.keymap.set('n', '<leader>S', runAndNext)
vim.keymap.set('n', '<leader>t', runTest)

vim.keymap.set("n", "<leader>x", "<Plug>JupyterExecute")
vim.keymap.set("n", "<leader>X", "<Plug>JupyterExecuteAll")
vim.keymap.set("n", "<leader>r", "<Plug>JupyterRestart")
