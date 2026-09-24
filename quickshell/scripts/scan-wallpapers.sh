#!/usr/bin/env bash
# Scans the wallpaper directory and prints one JSON array describing each
# image: its path, a display name, a seed colour and the mean luminance.
# The shell turns the seed into a full palette, so a wallpaper dropped into
# the directory becomes a usable theme without any hand-tuning.
#
# Results are cached keyed on the directory listing + mtimes, because
# ImageMagick histogramming a dozen 4K photos is not something to redo on
# every shell start.

set -euo pipefail

WALLDIR="${1:-$HOME/Pictures/wallpapers}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/wallpapers.json"

shopt -s nullglob
candidates=("$WALLDIR"/*)
shopt -u nullglob

# Extension is just a hint; go by actual content so every picture in the
# folder counts, whatever it's named or however it got there.
files=()
for f in "${candidates[@]}"; do
    [ -f "$f" ] || continue
    case "$(file --brief --mime-type "$f" 2>/dev/null)" in
        image/*) files+=("$f") ;;
    esac
done

if [ ${#files[@]} -eq 0 ]; then
    echo '[]'
    exit 0
fi

IFS=$'\n' files=($(printf '%s\n' "${files[@]}" | sort)); unset IFS

# Signature = every path plus its mtime. Any add, remove or edit busts it.
sig=$(stat -c '%n:%Y' "${files[@]}" | sha256sum | cut -d' ' -f1)

if [ -f "$CACHE" ] && head -c 200 "$CACHE" | grep -q "\"sig\":\"$sig\""; then
    cat "$CACHE"
    exit 0
fi

# Pick the seed from an 8-colour histogram: the entry with the best
# score of saturation weighted by how much of the image it covers. A photo
# that is mostly grey still yields its one bit of colour, and a photo that is
# uniformly blue yields that blue rather than a stray highlight.
seed_of() {
    magick "$1" -resize 200x200^ -gravity center -extent 200x200 \
        -colors 8 -format %c histogram:info:- 2>/dev/null |
    awk '
        match($0, /#[0-9A-Fa-f]{6}/) {
            hex = substr($0, RSTART + 1, 6)
            count = $1 + 0
            r = strtonum("0x" substr(hex,1,2)) / 255
            g = strtonum("0x" substr(hex,3,2)) / 255
            b = strtonum("0x" substr(hex,5,2)) / 255
            mx = (r > g ? r : g); mx = (mx > b ? mx : b)
            mn = (r < g ? r : g); mn = (mn < b ? mn : b)
            l = (mx + mn) / 2
            sat = (mx == mn) ? 0 : (l > 0.5 ? (mx - mn) / (2 - mx - mn) : (mx - mn) / (mx + mn))
            # Near-black and near-white carry no usable hue; damp them out.
            usable = (l < 0.06 || l > 0.94) ? 0.05 : 1
            score = (sat + 0.12) * usable * (count ^ 0.4)
            if (score > best) { best = score; bestHex = hex }
        }
        END { print (bestHex == "" ? "808080" : bestHex) }
    '
}

mkdir -p "$(dirname "$CACHE")"

{
    printf '{"sig":"%s","items":[' "$sig"
    first=1
    for f in "${files[@]}"; do
        hex=$(seed_of "$f")
        mean=$(magick "$f" -resize 1x1! -format '%[fx:mean]' info: 2>/dev/null || echo 0.5)
        base=$(basename "$f"); base="${base%.*}"
        # Strip the unsplash-style "name-HASH-unsplash" noise from filenames.
        name=$(printf '%s' "$base" |
            sed -E 's/-[A-Za-z0-9_-]{11}-unsplash.*$//; s/[-_]+/ /g; s/\(.*\)//; s/^ +| +$//g')
        [ -z "$name" ] && name="$base"
        [ $first -eq 0 ] && printf ','
        first=0
        printf '{"path":"%s","name":"%s","seed":"#%s","mean":%s}' \
            "$f" "$name" "$hex" "$mean"
    done
    printf ']}'
} > "$CACHE.tmp"

mv "$CACHE.tmp" "$CACHE"
cat "$CACHE"
