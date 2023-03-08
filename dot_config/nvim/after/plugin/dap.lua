local dap = require("dap")
vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
vim.keymap.set("n", "<F5>", dap.continue)
vim.keymap.set("n", "<F2>", dap.step_over)
vim.keymap.set("n", "<F3>", dap.step_over)
vim.keymap.set("n", "<F3>", dap.step_out)

local mason_path = vim.fn.glob(vim.fn.stdpath "data" .. "/mason/")
require("dap-python").setup(mason_path .. "packages/debugpy/venv/bin/python")
require("mason-nvim-dap").setup({
	ensure_installed = {"python"}
})
require("dapui").setup()
