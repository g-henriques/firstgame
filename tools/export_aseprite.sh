#!/usr/bin/env bash
# Re-exports every art/*.aseprite into the sheets the game reads.
# Requires the Aseprite CLI (set ASEPRITE=/path/to/aseprite if not in PATH).
#   tools/export_aseprite.sh            # export everything
#   tools/export_aseprite.sh player     # export only art/player.aseprite
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -z "${ASEPRITE:-}" ]]; then
  ASEPRITE=aseprite
  for app in "/Applications/Aseprite.app" "$HOME/Library/Application Support/Steam/steamapps/common/Aseprite/Aseprite.app"; do
    if ! command -v aseprite >/dev/null && [[ -x "$app/Contents/MacOS/aseprite" ]]; then ASEPRITE="$app/Contents/MacOS/aseprite"; fi
  done
fi
UI_ART="panel panel_gold button_normal button_hover button_pressed button_disabled button_focus bar_bg bar_hp bar_xp bar_boss slot dim logo"

export_one() {
  local name="$1" src="art/$1.aseprite" out="assets/sprites"
  [[ " $UI_ART " == *" $name "* ]] && out="assets/ui"
  if [[ "$name" == "pixel_font" ]]; then
    "$ASEPRITE" -b "$src" --save-as assets/fonts/pixel_font.png
    echo "pixel_font -> assets/fonts/pixel_font.png (glyph layout must stay the same)"
    return
  fi
  "$ASEPRITE" -b "$src" --sheet "$out/$name.png" --sheet-type horizontal \
    --data "$out/$name.json" --format json-array --list-tags --list-slices
  echo "$name -> $out/$name.png"
}

if [[ $# -gt 0 ]]; then
  for n in "$@"; do export_one "$n"; done
else
  for f in art/*.aseprite; do export_one "$(basename "$f" .aseprite)"; done
fi
echo "Done. If you changed GUI art run: godot --headless --path . --script res://scripts/editor/build_theme.gd"
