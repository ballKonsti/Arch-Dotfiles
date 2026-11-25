-- beamer: automatic HDMI / projector handling (installed by hdmi-beamer/install.sh)
hl.on("hyprland.start", function()
    hl.exec_cmd("/home/ball/.local/bin/beamer daemon")
end)

-- SUPER+P: display popup (mirror / extend / projector only / laptop only + arrange)
hl.bind("SUPER + P",         hl.dsp.exec_cmd("/home/ball/.local/bin/beamer ui"))
-- SUPER+SHIFT+P: back to mirror instantly (handy in front of a class)
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("/home/ball/.local/bin/beamer mirror"))
