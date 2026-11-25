-- Laptop panel keeps its 1.25 scale.
hl.monitor({
    output   = "eDP-1",
    mode     = "preferred",
    position = "0x0",
    scale    = 1.25,
    bitdepth = 10,
})

-- Any other screen (beamer, monitor): scale 1 is valid for every resolution.
-- `beamer` adjusts mirror/extend at runtime.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto-right",
    scale    = 1,
})

-- XWayland apps (e.g. Minecraft via Lunar Client) get broken/offset mouse input
-- with mixed monitor scales (1.25 laptop + 1 external). Let them render unscaled.
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})
