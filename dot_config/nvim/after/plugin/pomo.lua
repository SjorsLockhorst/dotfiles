require("pomo").setup(
	{
		notifiers = {
			-- The "Default" notifier uses 'vim.notify' and works best when you have 'nvim-notify' installed.
			{
				name = "Default",
				opts = {
					-- With 'nvim-notify', when 'sticky = true' you'll have a live timer pop-up
					-- continuously displayed. If you only want a pop-up notification when the timer starts
					-- and finishes, set this to false.
					sticky = true,

					title_icon = "⏳",
					text_icon = "⏱️",
				},
			},
		}
	}
)
