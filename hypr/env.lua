hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Run Electron/Chromium apps natively on Wayland (avoids XWayland flicker with fractional scaling)
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Hardware video decode/encode on the Intel GPU (VA-API, intel-media-driver)
hl.env("LIBVA_DRIVER_NAME", "iHD")
