hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- The old config had a qalculate calculator rule written as `$windowrulev2 = ...`,
-- which only set an unused variable and never applied. Uncomment to actually use it:
-- hl.window_rule({
--     name  = "qalculate-calculator",
--     match = { class = "qalculate-gtk" },
--
--     float     = true,
--     workspace = "special:calculator",
-- })
