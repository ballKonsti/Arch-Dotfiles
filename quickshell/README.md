# Notch bar

A MacBook-notch / Dynamic-Island style top bar for Hyprland, built with
[Quickshell](https://quickshell.org). Replaces the old waybar setup
(`~/.config/waybar` is left in place but nothing launches it any more).

## Running

    qs -d          # bare `qs` finds ~/.config/quickshell/shell.qml

Started by `~/.config/hypr/autostart.conf`. Edits to any `.qml` file
hot-reload the running shell — no restart needed.

`Super+W` toggles the notch over IPC — waves it in if it's hidden, waves it
back off the screen edges if it's showing (and starts the shell if it isn't
running at all):

    qs ipc call notch toggle || qs -d

While hidden the notch draws nothing and claims no input region, so the top
of the screen behaves as if the shell weren't there. The process stays
alive, which is why toggling back on is instant.

Other IPC calls: `replay` (force the entrance), `hide`, and `open` / `close`
to pin and unpin the panel. `qs ipc show` lists them.

## Layout

There are no side bars — the notch is the whole shell.

    ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁
    ● ○ ○ ○   13:10   ·   󰤨 󰁹 43%

* **Notch** — flush with the top edge, concave shoulders, rounded bottom.
  Collapsed: workspace dots + clock on the left, network + battery on the
  right, a faint "camera" dot on the centre line.
* **Hover** it and it unfolds into a panel: big clock and date, the focused
  window (or a media card with art, title, artist, transport and progress),
  volume + brightness sliders, chips for SSID / battery + estimate / uptime,
  and the system tray. Click to pin it open, click again to unpin.
* **Scroll** anywhere on the notch to change volume; **middle-click** mutes.
* Changing volume or brightness from anywhere (media keys, `wpctl`,
  `brightnessctl`) makes the collapsed notch stretch to the right and show a
  mini OSD for ~1.7 s, then settle back.

It sits on the layer-shell **overlay** layer and reserves no space
(`ExclusionMode.Ignore`), so windows get the full screen height and the
notch floats on top of everything — fullscreen windows included. Only the
notch silhouette itself swallows clicks; the rest of the strip is
click-through.

## The entrance

On start — and on every `Super+W` — two crests run in from the left and
right screen edges on an accelerating curve, collide on the centre line, and
splash out into the full notch: the width overshoots past its target while
the height briefly bulges downward, the way a head-on collision would squash
it.

Each crest (`widgets/WaveShape.qml`) is a steep leading face, a rounded
trough, and a long tail streaming back the way it came, and it swells and
dips as it travels. Two things retract on the approach: the tail shrinks to
nothing, at which point the tail curve *is* the notch's concave shoulder;
and the leading face's rounded corner flattens to a vertical butt. So the
instant the two noses touch, their union is exactly a notch of the right
width and the hand-off to the real shape is invisible.

Closing runs the same thing backwards: the notch draws down into the blob,
splits, and the two halves accelerate off the sides of the screen.

Tuning lives in `config/Theme.qml`: `wavePiece` (crest width), `waveTail`
(wake length), `waveWobble` / `waveRipples` (how much the crest swells on
the way in, and how often), `waveTravel` (crossing time), `waveOvershoot`
(how far off-screen they start).

## The unfold

The notch is measured as two independent half-widths out from a fixed centre
line, so it doesn't zoom symmetrically — it sweeps. The right edge leads, the
height unfurls ~80 ms behind it, the left edge follows ~150 ms behind, and the
panel contents slide in from the right on the same beat. Tune the three
`*Delay` values in `config/Theme.qml` to change the character of the wave;
set them all to 0 for a plain symmetric expand.

Hover is tracked by a `HoverHandler` on the notch root rather than a
`MouseArea`, so dragging the volume or brightness slider can't steal the
hover out from under it and snap the panel shut mid-adjustment.

Everything inside the notch lives in a clipped box (`bodyClip`) pinned to
the silhouette's current bounds, so panel content is physically unable to
draw where the background hasn't arrived yet — it gets wiped in by the black
rather than appearing on top of the desktop. The fade is held back a further
`heightDelay + 110` ms on the way open for the same reason; on the way shut
it starts immediately, so the content leaves before the box does.

## Files

| Path | What |
| --- | --- |
| `shell.qml` | entry point |
| `config/Theme.qml` | **all** colours, sizes, fonts, motion curves |
| `modules/Bar.qml` | the `PanelWindow` per screen, click-through mask |
| `modules/Notch.qml` | geometry + wave, collapsed face, OSD, expanded panel |
| `modules/Workspaces.qml` | Hyprland workspace dots |
| `modules/ActiveWindow.qml` | focused window icon + title |
| `modules/Tray.qml` | StatusNotifier tray |
| `widgets/NotchShape.qml` | the silhouette (QtQuick Shapes path) |
| `widgets/SliderBar.qml` | drag/scroll slider |
| `services/*.qml` | singletons: audio, backlight, battery, network, clock |

Tweak `config/Theme.qml` first — notch size, expanded size, corner radii
and the whole palette live there.
