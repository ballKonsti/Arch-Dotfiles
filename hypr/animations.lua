hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("snappy", { type = "bezier", points = { {0.15, 0.9}, {0.1, 1.0} } })

hl.animation({ leaf = "windows",     enabled = true, speed = 2.5, bezier = "snappy",  style = "popin 85%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2.5, bezier = "snappy",  style = "popin 85%" })
hl.animation({ leaf = "fade",        enabled = true, speed = 2.5, bezier = "snappy" })
hl.animation({ leaf = "border",      enabled = true, speed = 4,   bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 5,   bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 3,   bezier = "snappy",  style = "slidefade" })
