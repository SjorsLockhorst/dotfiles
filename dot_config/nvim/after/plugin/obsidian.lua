require("obsidian").setup({
  workspaces = {
    {
      name = "lifeOS",
      path = "~/vaults/lifeOS/",
    },
  },
  templates = {
    subdir = "0_PeriodicNotes/Templates",
    date_format = "%Y-%m-%d",
    time_format = "%Hh:%M",
  },
  daily_notes = {
    -- Optional, if you keep daily notes in a separate directory.
    folder = os.date("0_PeriodicNotes/%Y/Daily/%m"),
    -- Optional, if you want to change the date format for the ID of daily notes.
    date_format = "%Y-%m-%d",
    -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
    template = "Daily.md"
  },
  ui = {
      checkboxes = {
        -- NOTE: the 'char' value has to be a single character, and the highlight groups are defined below.
        [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
        ["x"] = { char = "󰄲", hl_group = "ObsidianDone" },
        -- [">"] = { char = "", hl_group = "ObsidianRightArrow" },
        -- ["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
        -- Replace the above with this if you don't have a patched font:
        -- [" "] = { char = "☐", hl_group = "ObsidianTodo" },
        -- ["x"] = { char = "✔", hl_group = "ObsidianDone" },

        -- You can also add more custom ones...
      },
  },
  open_app_foreground = true,
  follow_url_func = function(url)
    -- Open the URL in the default web browser.
    vim.fn.jobstart({"xdg-open", url})  -- linux
  end,
})
