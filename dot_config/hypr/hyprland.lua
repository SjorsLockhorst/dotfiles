-- Hyprland Lua config (replaces the deprecated hyprlang hyprland.conf).
-- https://wiki.hypr.land/Configuring/Start/

local colors = require("mocha")


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({ output = "desc:Samsung Electric Company SAMSUNG 0x01000E00", mode = "preferred", position = "auto", scale = 1.875 })
hl.monitor({ output = "desc:LG Electronics LG SIGNAGE 0x01010101",        mode = "preferred", position = "auto", scale = 1.875 })
hl.monitor({ output = "desc:Dell Inc. DELL U2412M 0FFXD4C82ELS",          mode = "preferred", position = "auto", scale = 1, transform = 1 })

hl.monitor({ output = "",      mode = "preferred", position = "auto", scale = "auto" })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0",  scale = 1.875 })
hl.monitor({ output = "desc:Iiyama North America PL2493H 1187814501041", mode = "preferred", position = "-1920x0", scale = 1 })
hl.monitor({ output = "desc:Iiyama North America PL2493H 1187814501042", mode = "preferred", position = "-3000x0", scale = 1, transform = 1 })

-- Overrides the earlier Dell rule (later rules win)
hl.monitor({ output = "desc:Dell Inc. DELL U2412M 0FFXD4C82ELS",                                      mode = "1920x1080@60", position = "1536x0", scale = 1, transform = 1 })
hl.monitor({ output = "desc:Philips Consumer Electronics Company PHL27E1N1100A UHB2527002046",        mode = "1920x1080@60", position = "2616x0", scale = 1 })
hl.monitor({ output = "desc:Philips Consumer Electronics Company PHL 272B8Q UK01933010412",           mode = "preferred",    position = "auto" })

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "kitty"
local fileManager = "nautilus"
local menu        = "rofi -show drun"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar & swaync & hypridle & hyprpaper & nm-applet --indicator")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        border_size = 2,

        col = {
            active_border   = colors.flamingo,
            inactive_border = colors.lavender,
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.9,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = colors.sky,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

hl.config({
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = false,
    },
    cursor = {
        no_hardware_cursors = 1,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },
})

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "ALT"

-- See https://wiki.hypr.land/Configuring/Basics/Binds/
hl.bind(mainMod .. " + Return",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Q",   hl.dsp.window.close())
hl.bind(mainMod .. " + M",           hl.dsp.exit())
-- hl.bind(mainMod .. " + F",        hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V",           hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + D",           hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",           hl.dsp.window.pseudo()) -- dwindle
-- hl.bind(mainMod .. " + E",        hl.dsp.layout("togglesplit")) -- dwindle
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Move focus with mainMod + hjkl
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
-- hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
-- hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Custom by ME
hl.bind("Print",             hl.dsp.exec_cmd("hyprshot -m window"))
hl.bind(mainMod .. " + S",   hl.dsp.exec_cmd("hyprshot -m region"))
hl.bind("SUPER + L",         hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + B",   hl.dsp.exec_cmd("gtk-launch $(xdg-settings get default-web-browser)"))

-- TODO: Make this more modular so we can spinn up also other shells easily
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd([[kitty $SHELL -i -c "start-core-ai; exec $SHELL"]], { workspace = "1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),   { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),  { locked = true })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Confine the cursor inside Civilization to prevent moving to adjacent monitors
hl.window_rule({
    name = "civ-confine-pointer",
    match = {
        -- Match Steam App ID (e.g., steam_app_289070 for Civ VI) or class pattern
        class = "^(steam_app_.*)$",
    },
    confine_pointer = true,
    fullscreen = true
})
