#!/usr/bin/env bash
# Render every part to stl/ and verify each one against the spec.
#
#   ./build.sh                 everything (but see "unchanged" below)
#   ./build.sh plate           only the steps whose label matches "plate"
#   ./build.sh arm cap         several filters, matched as substrings
#   ./build.sh --force         rebuild even what is unchanged
#
# UNCHANGED parts are skipped.  Every part in here comes off ONE include chain,
# so the only honest input hash is "all the .scad files together" -- change any
# of them and every part is potentially different.  What that buys is the case
# that actually hurt: running the script twice in a row, or after editing a .md,
# now costs seconds instead of minutes.  When you ARE iterating on one part, the
# filter is the tool -- `./build.sh plate` skips the other thirty steps and,
# just as importantly, the fitcheck sweeps that belong to them.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stl

FORCE=0
FILTER=()
for a in "$@"; do
    if [ "$a" = "--force" ]; then FORCE=1; else FILTER+=("$a"); fi
done

CHAIN_HASH=$(cat ./*.scad | md5sum | cut -d" " -f1)

# NOTE the labels below say "bed" where they mean a print bed.  They used to say
# "plate", which the filter then matched -- `./build.sh plate` rebuilt three
# multi-part beds and took as long as the full run.
want() {   # want <label> -- no filter means everything
    [ ${#FILTER[@]} -eq 0 ] && return 0
    local f
    for f in "${FILTER[@]}"; do
        case "$1" in *"$f"*) return 0;; esac
    done
    return 1
}

ACTIVE=1
sec() {    # start a labelled section
    if want "$1"; then echo "--- $1"; ACTIVE=1; else ACTIVE=0; fi
}

vfy() {    # run a check, unless this section was filtered or skipped
    [ "$ACTIVE" = "1" ] || return 0
    "$@"
}

# OpenSCAD 2026.07 turned --render into an option that TAKES AN ARGUMENT, so
# the bare `--render` this script used to pass swallowed the .scad filename,
# openscad printed its usage and exited non-zero -- and the `| grep ... || true`
# on the end threw that away.  Every part "built" and every verify ran against
# whatever stale STL happened to be on disk.  So renders go through here now:
# one place that knows the flag, and a failure that stops the build.
scad() {
    local out="$1" part="$2"
    [ "$ACTIVE" = "1" ] || return 0
    local stamp="stl/.${part}.hash"
    if [ "$FORCE" = "0" ] && [ -f "$out" ] && [ -f "$stamp" ] \
       && [ "$(cat "$stamp")" = "$CHAIN_HASH" ]; then
        echo "    unchanged, skipped"
        ACTIVE=0            # ... and so are its checks: same mesh, same answer
        return 0
    fi
    if ! msg=$(openscad -o "$out" --export-format binstl --render=force \
                        -D 'x=0' -D "part=\"${part}\"" main.scad 2>&1); then
        echo "$msg"
        echo "*** openscad failed rendering ${part}"
        exit 1
    fi
    grep -E "Status|WARNING|ERROR" <<<"$msg" || true
    echo "$CHAIN_HASH" > "stl/.${part}.hash"
}

# FIRST, because every measurement below reaches the mesh through load(), and a
# loader that returns an empty mesh does not error -- it measures 0.0 mm^3 and
# an inverted bbox, which fitcheck.py reads as a perfect fit.  A gate whose
# instrument is untested is not a gate.
sec "loader self-test"
ACTIVE=1; python3 verify.py --selftest | tail -2

for L in 50 75 100 140; do
    sec "arm${L}"
    scad "stl/gopro_arm_${L}mm.stl" "arm${L}"
    vfy python3 verify.py "stl/gopro_arm_${L}mm.stl" --length "${L}" | tail -4
done

sec "gauge"
scad "stl/gopro_fit_gauge.stl" "gauge"
vfy python3 verify.py "stl/gopro_fit_gauge.stl" --length 21 --gauge | tail -4

sec "set (all four on one bed)"
scad "stl/gopro_arms_set.stl" "set"

for L in 50 75 100 140; do
    sec "simple${L}"
    scad "stl/gopro_arm_simple_${L}mm.stl" "simple${L}"
    vfy python3 verify.py "stl/gopro_arm_simple_${L}mm.stl" --length "${L}" --simple | tail -4
done

sec "simple gauge"
scad "stl/gopro_fit_gauge_simple.stl" "sgauge"
vfy python3 verify.py "stl/gopro_fit_gauge_simple.stl" --length 21 --gauge --simple | tail -4

sec "simple set (all four on one bed)"
scad "stl/gopro_arms_simple_set.stl" "sset"

# 3-prong at BOTH ends.  --double is --simple plus a second connector, so the
# far end is held to the SAME grid checks as the near one rather than to a
# relaxed copy of them.
for L in 50 75 100 140; do
    sec "double${L}"
    scad "stl/gopro_arm_double_${L}mm.stl" "double${L}"
    vfy python3 verify.py "stl/gopro_arm_double_${L}mm.stl" --length "${L}" --double | tail -4
done

sec "double set (all four on one bed)"
scad "stl/gopro_arms_double_set.stl" "dset"

# The ground end of every chain in here: a flat plate on the airboat's M4 rail
# grid with a 3-prong connector at each end.  Its verify is a MESH read, not a
# recomputation of the .scad: fitcheck cannot tell a connector that does not
# foul from a connector that is not there.
sec "rail plate (bolts to the boat's 40 x 62 M4 rail grid)"
scad "stl/gopro_rail_plate.stl" "plate"
vfy python3 verify_plate.py "stl/gopro_rail_plate.stl" | tail -4

# The WIDE variant: same connector, 155 x 40 grid, one of them in the middle
# turned a quarter turn so the arm swings fore-aft.  --wide reads the mesh in a
# rotated frame so the connector checks are the same code, not a second copy.
sec "rail plate, WIDE (155 x 40 grid, one fore-aft connector)"
scad "stl/gopro_rail_plate_155mm.stl" "plate155"
vfy python3 verify_plate.py "stl/gopro_rail_plate_155mm.stl" --wide | tail -4

sec "pipe clamp"
scad "stl/gopro_pipe_clamp_12mm.stl" "clamp"
vfy python3 verify_clamp.py "stl/gopro_pipe_clamp_12mm.stl" | tail -4

sec "quick-release buckle"
scad "stl/gopro_qr_buckle.stl" "buckle"
vfy python3 verify_buckle.py "stl/gopro_qr_buckle.stl" | tail -4

sec "90 deg twist adapter"
scad "stl/gopro_90_twist.stl" "twist"
vfy python3 verify_twist.py "stl/gopro_90_twist.stl" | tail -4

# The fit coupon comes before the part it sizes, because that is the order they
# get printed in: the cap's press fit is set from a tube nobody has measured to
# better than "about 9.9".
sec "pipe cap fit gauge"
scad "stl/pipe_cap_12mm_gauge.stl" "capgauge"
vfy python3 verify_cap.py "stl/pipe_cap_12mm_gauge.stl" --gauge | tail -4

sec "pipe fairing cap"
scad "stl/pipe_cap_12mm.stl" "cap"
vfy python3 verify_cap.py "stl/pipe_cap_12mm.stl" | tail -4

sec "pipe fairing cap (four on a bed)"
scad "stl/pipe_cap_12mm_x4.stl" "capset"

# The two-part bungee cap.  Each half is checked alone, and then -- the part
# that matters -- the two are checked AGAINST EACH OTHER: a thread that fits
# nothing is just a decorative helix, and the knot chamber only exists once
# both halves are on the same datum.
sec "bungee cap: anchor half"
scad "stl/pipe_cap_12mm_bore.stl" "borecap"
vfy python3 verify_cap.py "stl/pipe_cap_12mm_bore.stl" --bore | tail -4

sec "bungee cap: screw-on dome"
scad "stl/pipe_cap_12mm_dome.stl" "domecap"
vfy python3 verify_cap.py "stl/pipe_cap_12mm_dome.stl" --dome | tail -4

sec "plain cord cap (no thread, no dome)"
scad "stl/pipe_cap_12mm_cord.stl" "cordcap"
vfy python3 verify_cap.py "stl/pipe_cap_12mm_cord.stl" --cord | tail -4

sec "bungee cap: do the two halves actually go together"
vfy python3 verify_cap.py "stl/pipe_cap_12mm_bore.stl" \
        --mate "stl/pipe_cap_12mm_dome.stl" | tail -6

# MATING / INTERFERENCE.  A shipping gate that never checks FIT is no gate.
# One labelled section each, so a filtered run still gets the sweeps that
# belong to the part being filtered for -- `./build.sh plate` runs the plate's
# two and none of the others, which is where most of the wall clock went.
fit() {    # fit <key> [fitcheck flags...]
    local key="$1"; shift
    sec "fit: $key"
    [ "$ACTIVE" = "1" ] || return 0
    local stamp="stl/.fit_${key}.hash"
    if [ "$FORCE" = "0" ] && [ -f "$stamp" ] \
       && [ "$(cat "$stamp")" = "$CHAIN_HASH" ]; then
        echo "    unchanged, skipped"
        return 0
    fi
    python3 fitcheck.py "$@"
    echo "$CHAIN_HASH" > "$stamp"
}

fit arm
fit simple --simple
# The twist adapter is the one part whose two ends articulate in planes the
# other end cannot see, so each is swung independently against the reference.
fit twist --twist
# The buckle is swung against a REAL arm rather than the ideal reference, and
# it is the only part here whose gate is a range and not just zero at 0 deg:
# the connector is raised exactly far enough to free a half turn, so a check
# that only asked "does it fit collinear" would pass the unraised part too.
fit buckle --buckle
# Both of arm_double's ends are female, so both are swung against the reference
# MALE and there is no arm-to-arm case to run: two females cannot couple, which
# is the reason that part exists.
fit double --double
# The plate is the one part whose limit is the PART ITSELF rather than a mating
# body: a connector standing on a plate can only swing through the half space
# above it.  So its sweep is gated on the outboard quadrant, and the readings
# BELOW flat -- under the plate -- have to come back non-zero or the probe was
# never touching the plate at all.
fit plate --plate
# The wide plate's connector is yawed, and it is ALONE -- so unlike the default
# plate nothing but the plate limits it, and the real arm should keep the whole
# half turn rather than losing the last 30 deg to a neighbour.
fit plate155 --plate155

ACTIVE=1
ls -la stl/*.stl
