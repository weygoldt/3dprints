#!/usr/bin/env bash
# Render the RC boat blink beacon and gate it.
#
#   ./build_beacon.sh
#
# Two parts now: the dome threads straight onto the body.  The LED carrier that
# used to sit between them is gone -- it was a shallow cup printed open-end-down
# whose 25.2 mm roof cost 1.96 cm^3 of support against a 2.71 cm^3 part, to
# mount a board that can be glued to the driver instead.
#
# The beacon is NOT part of build.sh: it does not come off main.scad's include
# chain, it is its own file with its own part picker.  Keeping it separate also
# keeps build.sh's CHAIN_HASH from rebuilding thirty arm variants every time a
# beacon parameter moves.
#
# Renders go through scad() rather than being written out inline, because
# OpenSCAD 2026.07 made --render take an argument -- a bare `--render` swallows
# the filename, openscad prints its usage and exits non-zero, and a pipeline
# ending in `|| true` would throw that away and "verify" a stale STL.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stl

SRC=rc_boat_blink_beacon.scad
# The dome that is already on the printer.  Every run proves the current source
# still renders that exact mesh; if it does not, the printed part is scrap and
# the check says so out loud.
REF=stl/dome_AS_PRINTED.stl
# A real slicer profile, so the printability gate is answered with the settings
# these parts are actually printed with rather than with defaults.  Committed,
# because a gate whose config is a local artifact is a gate that quietly stops
# running on the next machine.
SLICE_CFG=beacon_print.ini

scad() {   # scad <out> <part>
    local out="$1" part="$2"
    if ! msg=$(openscad -o "$out" --export-format binstl --render=force \
                        -D "part=\"${part}\"" "$SRC" 2>&1); then
        echo "$msg"
        echo "*** openscad failed rendering ${part}"
        exit 1
    fi
    grep -E "Status|WARNING|ERROR|Genus" <<<"$msg" | sed 's/^/    /' || true
}

# Does it PREVIEW?  Every other check in here reads an STL, and an STL comes
# from F6 -- so all of them once passed with flying colours on a part that drew
# absolutely nothing in the interactive viewport.  F5 normalizes the CSG tree
# by distributing differences over unions, and past the element ceiling
# OpenSCAD gives up with "Aborting normalization" / "resulted in an empty
# tree": two warnings in a console nobody is watching, and an empty screen.
preview_ok() {   # preview_ok <part>
    local part="$1" png msg
    png=$(mktemp -t beacon_prev_XXXX.png)
    if ! msg=$(openscad -o "$png" --imgsize=200,200 \
                        -D "part=\"${part}\"" "$SRC" 2>&1); then
        rm -f "$png"
        echo "    *** preview of ${part} failed to run:"
        echo "$msg" | sed 's/^/        /'
        exit 1
    fi
    rm -f "$png"
    if grep -qE "Aborting normalization|resulted in an empty tree" <<<"$msg"; then
        echo "    *** ${part} PREVIEWS AS NOTHING (F6 would still be fine):"
        grep -E "WARNING" <<<"$msg" | sed 's/^/        /'
        echo "    *** wrap the offending subtree in render()"
        exit 1
    fi
    printf "    %-10s %s\n" "$part" "$(grep -oE 'Normalized CSG tree has [0-9]+ elements' \
                                       <<<"$msg" | tail -1)"
}

echo "--- previews (F5), because everything below this line only tests F6"
preview_ok body
preview_ok dome
preview_ok assembly

# Then the loader, because every measurement reaches the mesh through it, and a
# loader that returns an empty mesh does not error -- it measures 0.0 mm^3 and
# an inverted bbox, which reads as a perfect fit.
echo "--- loader selftest"
python3 verify_beacon.py --selftest | tail -14

echo "--- body"
scad stl/rc_boat_blink_beacon_body.stl body
echo "--- dome"
scad stl/rc_boat_blink_beacon_dome.stl dome

# Does it SLICE?  The mesh checks cannot see this: the body's two PCB rails are
# a perfectly good mesh that happens to start in mid-air.  A bridge is fine, an
# ISLAND is not, and only the slicer knows which is which.
#
# The body's two rails ARE islands and they stay: two thin walls cost less
# material than the solid floor a pocket would have to be sunk into, so the
# body is printed with support and the count is pinned at 2.  A THIRD island
# still fails the build.  The dome must stay at zero.
echo "--- slicing, because a good mesh can still be unprintable"
if command -v prusa-slicer >/dev/null 2>&1 && [ -f "$SLICE_CFG" ]; then
    python3 verify_slice.py --selftest | sed 's/^/  /'
    # The body is printed THREAD DOWN, which is not how the STL sits, so the
    # check has to rotate it or it measures a part nobody prints.
    python3 verify_slice.py --config "$SLICE_CFG" --rotate-x 180 \
            --expect-islands 2 --label body stl/rc_boat_blink_beacon_body.stl
    python3 verify_slice.py --config "$SLICE_CFG" \
            --label dome stl/rc_boat_blink_beacon_dome.stl
else
    echo "!!! prusa-slicer or $SLICE_CFG missing -- the printability proof did NOT run."
fi

echo
SAME=()
if [ -f "$REF" ]; then
    SAME=(--same-as "$REF")
else
    echo "!!! $REF is missing -- the 'dome is unchanged' proof did NOT run."
    echo "!!! To restore it, copy the dome STL you actually printed to that path."
fi

python3 verify_beacon.py \
    --body stl/rc_boat_blink_beacon_body.stl \
    --dome stl/rc_boat_blink_beacon_dome.stl \
    "${SAME[@]}"

echo
ls -la stl/rc_boat_blink_beacon_*.stl
