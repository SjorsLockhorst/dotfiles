require("obsidian").setup({
  workspaces = {
    {
      name = "lifeOS",
      path = "~/vaults/lifeOS/",
    },
  },
  templates = {
    subdir = "0. PeriodicNotes/Templates",
    date_format = "%Y-%m-%d",
    time_format = "%Hh:%M",
  },
  daily_notes = {
    -- Optional, if you keep daily notes in a separate directory.
    folder = os.date("0. PeriodicNotes/%Y/Daily/%m"),
    -- Optional, if you want to change the date format for the ID of daily notes.
    date_format = "%Y-%m-%d",
    -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
    template = "Daily.md"
  },
})
