-- Touchscreen window management via the hyprgrass plugin.
-- Built from source in ~/.local/src/hyprgrass (pinned to the commit matching
-- this Hyprland version — rebuild after a Hyprland update).
--
--   2 fingers: hold still briefly, then drag  → resize the window under them
--   3 fingers: hold still briefly, then drag  → move the window under them
--   1 finger:  long-press a border/gap, drag  → resize from that edge

local PLUGIN = os.getenv("HOME") .. "/.local/src/hyprgrass/build/src/libhyprgrass.so"

local f = io.open(PLUGIN, "r")
if not f then
    return
end
f:close()

local ok, err = pcall(hl.plugin.load, PLUGIN)
if not ok then
    hl.notification.create({ text = "hyprgrass failed to load: " .. tostring(err), timeout = 8000 })
    return
end
if not (hl.plugin.hyprgrass and hl.plugin.hyprgrass.bind) then
    return
end

hl.config({
    general = {
        -- a fingertip is a lot fatter than a cursor
        extend_border_grab_area = 25,
    },
    plugin = {
        hyprgrass = {
            sensitivity = 4.0,
            long_press_delay = 300,
            resize_on_border_long_press = true,
        },
    },
})

hl.plugin.hyprgrass.bind({
    pattern = { kind = "longpress", fingers = 2 },
    action  = hl.dsp.window.resize(),
    mouse   = true,
})

hl.plugin.hyprgrass.bind({
    pattern = { kind = "longpress", fingers = 3 },
    action  = hl.dsp.window.drag(),
    mouse   = true,
})
