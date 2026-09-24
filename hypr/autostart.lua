hl.on("hyprland.start", function()
    hl.exec_cmd("/usr/bin/awww-daemon")
    hl.exec_cmd("elephant")
    hl.exec_cmd("hyprlock")
    hl.exec_cmd("dunst")

    -- Notch bar (Quickshell)
    hl.exec_cmd("qs -d")
end)
