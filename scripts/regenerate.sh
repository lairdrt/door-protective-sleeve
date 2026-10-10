#!/bin/sh
# Regenerate every derived file from src/sleeve.scad, so the exports
# and images always match the current approved design.
#
# Run from the repository root (Git Bash on Windows):
#   sh scripts/regenerate.sh
#
# Historical test artifacts are NOT regenerated:
#   exports/sleeve-test.stl    15 mm fit-test specimen (OpenSCAD)
#   exports/sleeve-test.3mf    its Bambu Studio print project
#   photos/sleeve-test-*.png   15 mm prototype images
# The script only checks that the current cross-section still
# reproduces the fit-tested specimen, and says so if it does not.

set -e
cd "$(dirname "$0")/.."

if [ -n "$OPENSCAD" ]; then
    :
elif command -v openscad >/dev/null 2>&1; then
    OPENSCAD=openscad
else
    OPENSCAD="/c/Program Files/OpenSCAD/openscad.com"
fi

# Run OpenSCAD, showing only its design-check echoes and any problems
scad() {
    "$OPENSCAD" --colorscheme=Tomorrow "$@" 2>&1 |
        grep -E "ECHO|ERROR|WARNING|Assertion" |
        grep -v "Viewall and autocenter disabled" || true
}

echo "== Current design: exports"
scad -o exports/sleeve.stl src/sleeve.scad
scad -o exports/sleeve.3mf src/sleeve.scad | grep -v ECHO || true

echo "== Current design: images"
scad -o photos/sleeve-iso.png --imgsize=1400,1050 --render src/sleeve.scad | grep -v ECHO || true
scad -o photos/sleeve-tongue.png --imgsize=1400,1050 --render -D 'view="tongue"' src/sleeve-drawing.scad | grep -v ECHO || true
scad -o photos/sleeve-profile.png --imgsize=1600,1250 --projection=ortho -D 'view="profile"' src/sleeve-drawing.scad | grep -v ECHO || true
scad -o photos/sleeve-section.png --imgsize=1000,1000 --projection=ortho -D 'view="fit"' src/sleeve-drawing.scad | grep -v ECHO || true

echo "== Check: cross-section against the fit-tested 15 mm specimen"
tmp="${TMPDIR:-/tmp}/sleeve-test-check.$$.stl"
scad -o "$tmp" -D sleeve_height=prototype_height src/sleeve.scad | grep -v ECHO || true
if cmp -s "$tmp" exports/sleeve-test.stl; then
    echo "OK: identical to exports/sleeve-test.stl"
else
    echo "NOTE: the cross-section differs from the fit-tested specimen"
    echo "      (exports/sleeve-test.stl left unchanged as the historical record)"
fi
rm -f "$tmp"
