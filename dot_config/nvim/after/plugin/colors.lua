function SetColors(color)
	color = color or "nord"
	vim.cmd.colorscheme(color)
end

SetColors("catppuccin-mocha")

require("colorizer").setup()
