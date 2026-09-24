# Arch Dotfiles

Hyprland desktop on Arch Linux, centred on a MacBook-notch style shell built
with [Quickshell](https://quickshell.org).

![notch](https://img.shields.io/badge/compositor-Hyprland-9cf?style=flat-square)
![shell](https://img.shields.io/badge/shell-Quickshell-ffe5ec?style=flat-square)
![distro](https://img.shields.io/badge/distro-Arch-1793d1?style=flat-square)

---

## What's in here

| Folder | What it configures |
| --- | --- |
| [`quickshell/`](quickshell) | **The notch bar** — the whole desktop shell. See its [README](quickshell/README.md). |
| [`hypr/`](hypr) | Hyprland: binds, monitors, animations, input, hyprlock, autostart. |
| [`dunst/`](dunst) | Notifications, styled to match the notch. |
| [`kitty/`](kitty) | Terminal. |
| [`zed/`](zed) | Zed editor — settings, keymap, and a set of themes. |
| [`nvim/`](nvim) | Neovim — transparent, Python-oriented. See its [README](nvim/README.md). |
| [`btop/`](btop) | System monitor. |
| [`fastfetch/`](fastfetch) | Fetch, with custom ASCII. |
| `shortcuts.txt` | Scratch notes on keybinds. |

## The notch

A single centred notch flush with the top edge — concave shoulders, rounded
bottom, no side bars. It reserves no screen space and sits on the layer-shell
overlay layer, so windows get the full height and it floats above them.

* **Collapsed** — workspace dots, clock, network, battery, and a faint
  "camera" dot on the centre line.
* **Hover** — unfolds into a panel: large clock and date, the focused window
  or a media card (art, title, artist, transport, progress), volume and
  brightness sliders, status chips and the system tray.
* **Volume / brightness** changed from anywhere makes the collapsed notch
  stretch sideways into a mini OSD, then settle back.
* **Entrance** — two wave crests run in from the screen edges, collide on the
  centre line and splash out into the notch. `Super+W` toggles it: waves in
  when hidden, waves back off the edges when shown.

Notifications drop from directly beneath it, at the notch's own width and
corner radius, so they read as the notch handing you a message.

Full detail — geometry, animation timing, tuning knobs — is in
[`quickshell/README.md`](quickshell/README.md).

## How this repo is wired

The real files live **here**; `~/.config/<name>` is a symlink pointing into
this repo. That direction matters: if it were the other way round, git would
store a symlink instead of the content and nothing would actually be backed
up.

    ~/.config/hypr  ->  ~/hyprland-setup/hypr

## Install

```sh
git clone git@github.com:ballKonsti/Arch-Dotfiles.git ~/hyprland-setup
cd ~/hyprland-setup

for d in btop dunst fastfetch hypr kitty nvim quickshell zed; do
    [ -e ~/.config/"$d" ] && mv ~/.config/"$d" ~/.config/"$d".bak
    ln -s "$PWD/$d" ~/.config/"$d"
done
```

Then log out and back into Hyprland, or `hyprctl reload`.

### Packages

```sh
sudo pacman -S --needed hyprland quickshell dunst kitty btop fastfetch \
    pipewire pipewire-pulse wireplumber networkmanager upower \
    brightnessctl playerctl grim slurp wl-clipboard \
    inter-font ttf-jetbrains-mono-nerd \
    neovim ripgrep fd tree-sitter-cli imagemagick
```

The last line is for the editor and the theme switcher: `ripgrep`/`fd` back
Telescope, `tree-sitter-cli` builds Neovim's parsers, and `imagemagick` is
what reads a wallpaper's dominant colour.

`quickshell` is in `extra` — no AUR build needed. `inter-font` is the notch's
UI typeface and `ttf-jetbrains-mono-nerd` supplies its glyphs; without them Qt
falls back and the icons render as boxes.

## Keybinds

`mainMod` is <kbd>Super</kbd>.

| Bind | Action |
| --- | --- |
| <kbd>Super</kbd> + <kbd>W</kbd> | Toggle the notch (waves in / out) |
| <kbd>Super</kbd> + <kbd>T</kbd> | Theme picker — wallpaper + shell colours |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>T</kbd> | Next theme |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>D</kbd> | Toggle dark / light |
| <kbd>Super</kbd> + <kbd>I</kbd> | Terminal |
| <kbd>Super</kbd> + <kbd>Q</kbd> | Close window |
| <kbd>Super</kbd> + <kbd>E</kbd> | File manager (yazi) |
| <kbd>Super</kbd> + <kbd>C</kbd> | Chromium |
| <kbd>Super</kbd> + <kbd>B</kbd> | btop |
| <kbd>Super</kbd> + <kbd>Z</kbd> | Zed |
| <kbd>Super</kbd> + <kbd>Esc</kbd> | Lock (hyprlock) |
| <kbd>Super</kbd> + <kbd>L</kbd> | Toggle Wi-Fi |
| <kbd>Super</kbd> + <kbd>S</kbd> | Screenshot selection → clipboard |
| <kbd>Super</kbd> + <kbd>Shift</kbd> + <kbd>S</kbd> | Screenshot screen → `~/Pictures` |
| <kbd>Super</kbd> + <kbd>1…0</kbd> | Switch workspace |
| <kbd>Super</kbd> + arrows | Move focus |
| <kbd>Super</kbd> + scroll | Cycle workspace |
| <kbd>Super</kbd> + LMB / RMB drag | Move / resize window |

Media and brightness keys are bound to `wpctl`, `brightnessctl` and
`playerctl`; the notch shows an OSD for each.

The full list lives in [`hypr/binds.lua`](hypr/binds.lua). The Hyprland config is Lua (`hypr/hyprland.lua` requires one module per area); `hyprlock.conf` stays in hyprlang because hyprlock has no Lua config.
