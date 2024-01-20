require("autoclose").setup({
   keys = {
      ["$"] = { escape = true, close = true, pair = "$$", enabled_filetypes = {"markdown", "tex"} },
      ["*"] = { escape = true, close = true, pair = "**", enabled_filetypes = {"markdown"} },
      ["'"] = { escape = true, close = true, pair = "''", disabled_filetypes = {"markdown", "tex"} },
   },
})
