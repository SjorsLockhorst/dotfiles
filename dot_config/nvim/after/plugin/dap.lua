local dap, dapui = require("dap"), require("dapui")
dap.listeners.after.event_initialized["dapui_config"] = function()
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end
vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
vim.keymap.set("n", "<F1>", dap.continue)
vim.keymap.set("n", "<F2>", dap.step_over)
vim.keymap.set("n", "<F3>", dap.step_into)
vim.keymap.set("n", "<F4>", dap.step_out)
vim.keymap.set("n", "<F5>", dap.step_back)
vim.keymap.set("n", "<leader>dp", dapui.float_element)

local mason_path = vim.fn.glob(vim.fn.stdpath "data" .. "/mason/")
require("dap-python").setup(mason_path .. "packages/debugpy/venv/bin/python")
require("mason-nvim-dap").setup({
	ensure_installed = { "python" }
})
require("dapui").setup({
	layouts = { {
		elements = {
			{
				id = "watches",
				size = 0.2
			},
			{
				id = "scopes",
				size = 0.6
			},
			{
				id = "console",
				size = 0.2
			},
		},
		position = "left",
		size = 70
	},
	},
})
