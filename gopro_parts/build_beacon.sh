#!/usr/bin/env bash
# Render the RC boat blink beacon and gate it.
#
#   ./build_beacon.sh
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
# A real slicer profile, so the printability gate below is answered with the
# settings these parts are actually printed with rather than with defaults.
# Committed, because a gate whose config is a local artifact is a gate that
# quietly stops running on the next machine.
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
# from F6 -- so all of them passed with flying colours on a carrier that drew
# absolutely nothing in the interactive viewport.  F5 normalizes the CSG tree
# by distributing differences over unions; a union of seven solids inside a
# difference with eighteen cutters blows past the element ceiling, and OpenSCAD
# gives up with "Aborting normalization" / "resulted in an empty tree".  Two
# warnings in a console nobody is watching, and an empty screen.
#
# The fix is render() on the offending subtree.  This is the check that would
# have caught needing it.
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
python3 verify_beacon.py --selftest | tail -12

echo "--- body"
scad stl/rc_boat_blink_beacon_body.stl body
echo "--- carrier"
scad stl/rc_boat_blink_beacon_carrier.stl carrier
echo "--- dome"
scad stl/rc_boat_blink_beacon_dome.stl dome

# The two probes.  Neither is printable; each is a boolean whose VOLUME answers
# a question no single part can be asked.
echo "--- probe: seated carrier vs body (must be empty)"
scad stl/beacon_probe_fit.stl probe_fit
echo "--- probe: barb material outside the bore (must NOT be empty)"
scad stl/beacon_probe_hook.stl probe_hook

# Does it SLICE support-free?  The mesh checks cannot see this either: the
# body's two old PCB rails were a perfectly good mesh that happened to start in
# mid-air, and they were the only reason this thing needed support at all.
# A bridge is fine, an ISLAND is not, and only the slicer knows which is which.
echo "--- slicing (support off), because a good mesh can still be unprintable"
if command -v prusa-slicer >/dev/null 2>&1 && [ -f "$SLICE_CFG" ]; then
    python3 verify_slice.py --selftest | sed 's/^/  /'
    # The body is printed SOCKET DOWN, which is not how the STL sits, so the
    # check has to rotate it or it measures a part nobody prints.
    python3 verify_slice.py --config "$SLICE_CFG" --rotate-x 180 \
            --label body stl/rc_boat_blink_beacon_body.stl
    python3 verify_slice.py --config "$SLICE_CFG" \
            --label carrier stl/rc_boat_blink_beacon_carrier.stl
    python3 verify_slice.py --config "$SLICE_CFG" \
            --label dome stl/rc_boat_blink_beacon_dome.stl
else
    echo "!!! prusa-slicer or $SLICE_CFG missing -- the support-free proof did NOT run."
    echo "!!! Regenerate the config with:  prusa-slicer --save $SLICE_CFG"
fi

echo
# stl/ is gitignored, so the reference dome is a LOCAL artifact -- a fresh
# clone will not have one.  Say so loudly rather than quietly dropping the one
# check that protects a part which is already printed.
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
    "${SAME[@]}" \
    --probes  stl/beacon_probe_fit.stl stl/beacon_probe_hook.stl

echo
ls -la stl/rc_boat_blink_beacon_*.stl
