local programs = require("programs")
local terminal = programs.terminal
local menu     = programs.menu

-- See https://wiki.hypr.land/Configuring/Binds/ for more
local mainMod = "SUPER"

hl.bind(mainMod .. " + I",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + ESCAPE", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(terminal .. " -e yazi"))
hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd(menu))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Screenshot selection → clipboard
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"))

hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("chromium"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("qs ipc call notch toggle || qs -d"))

-- Theme switcher — wallpaper + shell colours move together
hl.bind(mainMod .. " + T",         hl.dsp.exec_cmd("qs ipc call theme toggle"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("qs ipc call theme next"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("qs ipc call theme mode"))
hl.bind(mainMod .. " + B",         hl.dsp.exec_cmd(terminal .. " -e btop"))
hl.bind(mainMod .. " + Z",         hl.dsp.exec_cmd("zeditor"))
-- Also on SUPER + R, like the old config: opens Teams alongside the launcher
hl.bind(mainMod .. " + R",         hl.dsp.exec_cmd("teams"))

-- Screenshot full screen → file
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("grim ~/Pictures/$(date +%F_%T).png"))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("SUPER + F2", hl.dsp.exec_cmd("brightnessctl set 5%-"))
hl.bind("SUPER + F3", hl.dsp.exec_cmd("brightnessctl set 5%+"))

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
