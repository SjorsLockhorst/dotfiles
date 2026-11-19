-- Puts workspaces on monitors: some always on the laptop screen, the others on the external
-- monitor while one is connected (and back on the laptop without one). Set up from hyprland.lua;
-- runs on every config load and every monitor change.
--
-- Workspace rules make a new workspace open on the right monitor; existing ones are moved.
-- A second hl.workspace_rule for a workspace updates its enabled rule in place, so the rules are
-- never disabled (a call after set_enabled(false) would add one more rule each time).

local M = {}

-- The external monitor: a landscape one before a rotated one, then the one with the most pixels.
local function external_monitor(laptop)
    local best, best_score
    for _, m in ipairs(hl.get_monitors()) do
        if m.name ~= laptop then
            local score = m.width * m.height
            if m.transform % 2 == 0 then score = score + 1e9 end -- odd transforms turn it 90°
            if not best or score > best_score then best, best_score = m, score end
        end
    end
    return best
end

local function place(spec)
    local external = external_monitor(spec.laptop)
    local groups = {
        { monitor = spec.laptop, workspaces = spec.laptop_workspaces },
        { monitor = external and external.name or spec.laptop, workspaces = spec.external_workspaces },
    }

    local moved = false
    for _, group in ipairs(groups) do
        for _, ws in ipairs(group.workspaces) do
            hl.workspace_rule({ workspace = tostring(ws), monitor = group.monitor })
            local w = hl.get_workspace(ws)
            if w and w.monitor and w.monitor.name ~= group.monitor and hl.get_monitor(group.monitor) then
                hl.dispatch(hl.dsp.workspace.move({ workspace = ws, monitor = group.monitor }))
                moved = true
            end
        end
    end

    -- After a move, each monitor shows the first of its workspaces, and the external one has focus.
    if moved then
        for _, group in ipairs(groups) do
            local first = group.workspaces[1]
            if hl.get_workspace(first) then hl.dispatch(hl.dsp.focus({ workspace = first })) end
        end
    end
end

-- spec: { laptop = "eDP-1", laptop_workspaces = { 2 }, external_workspaces = { 1, 3, 4 } }
function M.setup(spec)
    place(spec)
    hl.on("monitor.added",   function() place(spec) end)
    hl.on("monitor.removed", function() place(spec) end)
end

return M
