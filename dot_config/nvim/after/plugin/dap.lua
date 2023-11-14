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

dap.adapters.lldb = {
	type = 'executable',
	command = '/usr/bin/lldb-vscode-11', -- adjust as needed, must be absolute path
	name = 'lldb'
}

dap.configurations.rust = {
	{
		name = 'Launch',
		type = 'lldb',
		request = 'launch',
		program = function()
			return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
		end,
		cwd = '${workspaceFolder}',
		stopOnEntry = false,
		args = {},

		-- 💀
		-- if you change `runInTerminal` to true, you might need to change the yama/ptrace_scope setting:
		--
		--    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
		--
		-- Otherwise you might get the following error:
		--
		--    Error on launch: Failed to attach to the target process
		--
		-- But you should be aware of the implications:
		-- https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html
		-- runInTerminal = false,

		initCommands = function()
			-- Find out where to look for the pretty printer Python module
			local rustc_sysroot = vim.fn.trim(vim.fn.system('rustc --print sysroot'))

			local script_import = 'command script import "' ..
			    rustc_sysroot .. '/lib/rustlib/etc/lldb_lookup.py"'
			local commands_file = rustc_sysroot .. '/lib/rustlib/etc/lldb_commands'

			local commands = {}
			local file = io.open(commands_file, 'r')
			if file then
				for line in file:lines() do
					table.insert(commands, line)
				end
				file:close()
			end
			table.insert(commands, 1, script_import)

			return commands
		end,
		-- ...,
	}
}

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
