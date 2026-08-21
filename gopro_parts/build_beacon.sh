#!/usr/bin/env bash
# Render the RC boat blink beacon and gate it.
#
#   ./build_beacon.sh
#
# Three parts, none of which need support.  The carrier is back, but as a flat
# disc: its skirt only ever existed to give snap tongues length, and that skirt
# was what made it a cup with a 25.2 mm roof costing 1.96 cm^3 of support on a
# 2.71 cm^3 part.  No snap, no skirt, no roof, no support.
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
preview_ok carrier
preview_ok dome
preview_ok assembly

# Then the loader, because every measurement reaches the mesh through it, and a
# loader that returns an empty mesh does not error -- it measures 0.0 mm^3 and
# an inverted bbox, which reads as a perfect fit.
echo "--- loader selftest"
python3 verify_beacon.py --selftest | tail -14

echo "--- body"
scad stl/rc_boat_blink_beacon_body.stl body
echo "--- carrier"
scad stl/rc_boat_blink_beacon_carrier.stl carrier
echo "--- dome"
scad stl/rc_boat_blink_beacon_dome.stl dome

# Retention, rendered as three booleans.  An empty intersection makes OpenSCAD
# exit 1 with "Current top level object is empty" -- and for two of these three
# that is the PASS signal, not an error.  So they do not go through scad(), and
# an empty result is written out as a real zero-facet STL rather than left as a
# missing file: "the render produced nothing" and "the render never ran" must
# not arrive at the verifier looking the same.
echo "--- retention probes"
probe() {
    local pr="$1" msg
    msg=$(openscad -o "stl/$pr.stl" --export-format binstl --render=force \
                   -D "part=\"$pr\"" "$SRC" 2>&1) && \
        { printf "    %-14s rendered\n" "$pr"; return 0; }
    if grep -q "top level object is empty" <<<"$msg"; then
        # 80-byte header + a uint32 zero: a valid STL containing nothing.
        printf '%080d' 0 > "stl/$pr.stl"
        printf '\0\0\0\0' >> "stl/$pr.stl"
        printf "    %-14s EMPTY (the intersection really is nothing)\n" "$pr"
        return 0
    fi
    echo "$msg"
    echo "*** openscad failed rendering $pr"
    exit 1
}
probe probe_seated
probe probe_lift
probe probe_entry

# Does it SLICE?  The mesh checks cannot see this: the body's two PCB rails are
# a perfectly good mesh that happens to start in mid-air.  A bridge is fine, an
# ISLAND is not, and only the slicer knows which is which.
#
# ALL THREE now expect ZERO islands.  The rails are gone and the carrier is a
# flat disc, so there is nothing left anywhere in the beacon that starts in
# mid-air.  If that ever stops being true this build fails.
echo "--- slicing, because a good mesh can still be unprintable"
if command -v prusa-slicer >/dev/null 2>&1 && [ -f "$SLICE_CFG" ]; then
    python3 verify_slice.py --selftest | sed 's/^/  /'
    # The body is printed THREAD DOWN, which is not how the STL sits, so the
    # check has to rotate it or it measures a part nobody prints.
    python3 verify_slice.py --config "$SLICE_CFG" --rotate-x 180 \
            --label body stl/rc_boat_blink_beacon_body.stl
    python3 verify_slice.py --config "$SLICE_CFG" \
            --label carrier stl/rc_boat_blink_beacon_carrier.stl
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
    --body    stl/rc_boat_blink_beacon_body.stl \
    --carrier stl/rc_boat_blink_beacon_carrier.stl \
    --dome    stl/rc_boat_blink_beacon_dome.stl \
    --probes  stl/probe_seated.stl stl/probe_lift.stl stl/probe_entry.stl \
    "${SAME[@]}"

echo
ls -la stl/rc_boat_blink_beacon_*.stl
