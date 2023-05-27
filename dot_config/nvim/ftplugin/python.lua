vim.o.colorcolumn = "88"

vim.b.slime_bracketed_paste = 1
vim.b.slime_cell_delimiter = "# %%"

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

vim.keymap.set('n', '<leader>aa', insertCellAbove)
vim.keymap.set('n', '<leader>bb', insertCellBelow)
vim.keymap.set('n', '<leader>cm', ':IPythonCellToMarkdown<CR>')

vim.keymap.set('n', '<leader>re', function() StartTmuxRepl("ipython3") end)
vim.keymap.set('n', '<leader>rr', runAndNext)
