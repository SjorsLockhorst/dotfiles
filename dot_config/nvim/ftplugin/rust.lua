
local function cargoRun()
    -- Check the number of tmux panes
    local handle = io.popen("tmux list-panes | wc -l")  -- Run tmux command to count panes
    local panes_count = tonumber(handle:read("*a"))    -- Read the output and convert to number
    handle:close()

    -- If there is only one pane, create a new one
    if panes_count == 1 then
        os.execute("tmux split-window -h")  -- Split the tmux window horizontally (to the right)
    end
    local cargo_run = "cargo run"
    local send_command = "SlimeSend1 " .. cargo_run .. "\n"
    vim.cmd(send_command)
end



vim.keymap.set('n', '<leader>r', cargoRun)
