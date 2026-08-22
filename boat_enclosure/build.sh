#!/usr/bin/env bash
# Render every printable airboat-enclosure part into stl/.
#
#   ./build.sh                 everything (but see "unchanged" below)
#   ./build.sh connector       only the steps whose label matches "connector"
#   ./build.sh pylon guard     several filters, matched as substrings
#   ./build.sh --force         rebuild even what is unchanged
#
# WHY THIS EXISTS.  The exports used to live as one-off command lines scattered
# through AIRBOAT-NOTES.md, and they drifted: the notes still tell you to build a
# dirP/dirN PYLON PAIR, which stopped being two parts at 5e8a4b1.  The names below
# are the ones already in stl/, so existing slicer projects keep resolving.
#
# UNCHANGED parts are skipped.  Every part here comes off ONE include chain
# (common.scad), so the only honest input hash is "all the .scad files together":
# change any of them and every part is potentially different.  Same trade as
# gopro_arms/build.sh -- a second run costs seconds, and when you are iterating on
# one part the filter is the tool.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stl

FORCE=0
FILTER=()
for a in "$@"; do
    if [ "$a" = "--force" ]; then FORCE=1; else FILTER+=("$a"); fi
done

# _probe_*.scad are scratch instruments, not inputs to any part -- editing one
# must not invalidate every STL.
CHAIN_HASH=$(cat body.scad lid.scad pylon.scad propguard.scad caps.scad \
                 rail.scad connector.scad common.scad float.scad | md5sum | cut -d" " -f1)

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

# OpenSCAD 2026.07 turned --render into an option that TAKES AN ARGUMENT, so a
# bare `--render` swallows the .scad filename and openscad exits non-zero with a
# usage message.  A `|| true` on the end of that pipeline would throw the failure
# away and leave whatever stale STL was on disk looking freshly built -- so every
# render goes through here: one place that knows the flag, and a failure stops.
#
#   scad <out.stl> <label> <file.scad> [-D ...]
scad() {
    local out="$1" label="$2" file="$3"; shift 3
    [ "$ACTIVE" = "1" ] || return 0
    local stamp="stl/.${label}.hash"
    if [ "$FORCE" = "0" ] && [ -f "$out" ] && [ -f "$stamp" ] \
       && [ "$(cat "$stamp")" = "$CHAIN_HASH" ]; then
        echo "    unchanged, skipped"
        return 0
    fi
    local msg
    if ! msg=$(openscad -o "$out" --export-format binstl --render=force "$@" "$file" 2>&1); then
        echo "$msg"
        echo "*** openscad failed rendering ${label}"
        exit 1
    fi
    # Surface the render status and any warning.  NOT the "<<" advisories:
    # common.scad echoes those from the shared chain, so every part reprints the
    # same three "confirm your motor" lines and the real messages drown.  The one
    # "<<" that is a gate rather than a reminder (the driver-bore vs forward-gusset
    # clearance) says WARNING, so this pattern still catches it.
    grep -E "Status:|WARNING|ERROR" <<<"$msg" || true
    # A GATE that reads "<< FAIL" is not an advisory -- it is an assertion the part
    # makes about itself, and it was verified to fire on a named control.  Stop.
    if grep -qE "GATE[0-9].*<< FAIL" <<<"$msg"; then
        grep -E "GATE[0-9].*<< FAIL" <<<"$msg"
        echo "*** ${label}: a self-check FAILED -- not shipping this STL"
        exit 1
    fi
    measure "$out"
    echo "$CHAIN_HASH" > "stl/.${label}.hash"
}

# Print what actually landed on disk.  A render that "succeeds" into an empty or
# half-built mesh is the failure mode that matters here: openscad reports NoError
# either way, so the facet count, volume and bbox are the only honest receipt.
measure() {
    python3 - "$1" <<'PY'
import struct, sys
p = sys.argv[1]
d = open(p, 'rb').read()
n = struct.unpack('<I', d[80:84])[0]
if n == 0:
    print(f"    *** {p}: EMPTY MESH (0 facets)"); sys.exit(1)
vs = [struct.unpack('<9f', d[84+50*i+12:84+50*i+48]) for i in range(n)]
vol = abs(sum((a*(e*i_-f*h) - b*(d_*i_-f*g) + c*(d_*h-e*g))/6.0
              for a, b, c, d_, e, f, g, h, i_ in vs))
ax = [[v[j+k] for v in vs for j in (0, 3, 6)] for k in (0, 1, 2)]
bb = " x ".join(f"{max(a)-min(a):.2f}" for a in ax)
print(f"    {n:7d} facets   {vol/1000:8.2f} cm^3   bbox {bb} mm")
PY
}

# ---------------------------------------------------------------------------
#  THE PRINT SET
# ---------------------------------------------------------------------------
# The two hulls' boxes are genuinely handed (mirrored), and each hull carries its
# own electronics role -> its own gland set.  box_role is derived from `side`.
sec "housing: port hull (RC)"
scad stl/airboat_housing_port_RC.stl        housing_port      body.scad -D 'side="port"'      -D '$fn=128'

sec "housing: starboard hull (stim)"
scad stl/airboat_housing_starboard_stim.stl housing_starboard body.scad -D 'side="starboard"' -D '$fn=128'

sec "lid: port hull"
scad stl/airboat_lid_port.stl       lid_port      lid.scad -D 'side="port"'      -D '$fn=128'

sec "lid: starboard hull"
scad stl/airboat_lid_starboard.stl  lid_starboard lid.scad -D 'side="starboard"' -D '$fn=128'

# ONE PART, BOTH HULLS (5e8a4b1).  The motor is centred across the pylon width and
# the foot is symmetric, so the part is a pure translation onto either hull; the
# motor's wire side is chosen when you BOLT THE MOTOR ON, not by the print.  The
# old _port/_starboard names are kept as copies so existing projects still open,
# and the build ASSERTS the two motor dirs are byte-identical rather than asking
# you to take the commit's word for it.
sec "pylon (ONE part, both hulls)"
scad stl/airboat_pylon.stl pylon pylon.scad -D '$fn=128'
if [ "$ACTIVE" = "1" ] && [ -f stl/airboat_pylon.stl ]; then
    openscad -o stl/.pylon_dirN.stl --export-format binstl --render=force \
             -D 'motor_offset_dir=-1' -D '$fn=128' pylon.scad >/dev/null 2>&1
    if cmp -s stl/airboat_pylon.stl stl/.pylon_dirN.stl; then
        echo "    dir +1 and -1 are byte-identical -- one part, confirmed"
    else
        echo "*** the two motor dirs render DIFFERENT pylons -- the one-part claim is broken"
        exit 1
    fi
    rm -f stl/.pylon_dirN.stl
    cp stl/airboat_pylon.stl stl/airboat_pylon_port.stl
    cp stl/airboat_pylon.stl stl/airboat_pylon_starboard.stl
fi

# The guards DO stay two handed parts: the arc lean and the wire slot follow the
# motor offset even though the (2-fold symmetric) bolt pattern does not.
# $fn=128 is what the shipped washers are built at.
#
# YOU CANNOT PRINT ONE AND MIRROR IT.  The bodies ARE mirror-symmetric (bbox delta
# 0.0000000, volume delta 0.00011 mm^3), which is exactly what makes that mistake
# tempting -- but the A2212 cross is clocked to the same mount_rot on BOTH hulls, so
# the 4-hole pattern is identical rather than mirrored, and the two parts differ by
# 98.61 mm^3 concentrated at the bolt ring.  Print BOTH files.  (_probe_guardmirror.scad)
#
# The pylon's byte-identical `cmp -s` assertion is deliberately NOT reused here: the
# two hands are genuinely different parts, and their facet counts differ (19686 vs
# 19692) because the arc tessellation is not triangle-for-triangle mirrored.  What is
# asserted instead is that they are not ACCIDENTALLY the same file -- if a future edit
# drops the handedness, this catches it.
# WHICH FILE GOES ON WHICH HULL (Patrick, 2026-08-22).  Hold the guard so you are looking at the face that
# SCREWS TO THE PYLON, with the fan pointing UP.  In that view:
#
#   dirP -- the wire channel exits to your LEFT   -> PORT hull
#   dirN -- the wire channel exits to your RIGHT  -> STARBOARD hull
#
# Both files show the 19 mm bolt pair on the TOP-LEFT / BOTTOM-RIGHT diagonal in that view -- that is
# automatic, because motor_clock is 135 on both hulls, and it is the check that tells you the part is the
# right way up before you look at anything else.
#
# THE RULE BEHIND IT, so it can be re-derived: the leads must run INBOARD, toward the boat's centreline.
# Measured through main.scad's own transform chain (_probe_guardhand.scad, marker at the channel mouth):
# dirP on port puts the mouth at X = -87.50 against a hub at -108.50, and dirN on starboard puts it at
# +87.50 against +108.50 -- both toward the middle.  The other two assignments push it to +/-129.50, i.e.
# out over the water.  (Remember apply_side_of() MIRRORS the starboard hull, so feeding a hand to that hull
# displays the other one -- the numbers above are the physical parts, not the fed ones.)
sec "guard washer: dirP"
scad stl/airboat_guardwasher_a2212_dirP.stl guard_dirP propguard.scad -D 'motor_offset_dir=1'  -D '$fn=128'
[ "$ACTIVE" = "1" ] && echo "    ^ PORT hull: looking at the pylon face, the wire channel exits LEFT"

sec "guard washer: dirN"
scad stl/airboat_guardwasher_a2212_dirN.stl guard_dirN propguard.scad -D 'motor_offset_dir=-1' -D '$fn=128'
[ "$ACTIVE" = "1" ] && echo "    ^ STARBOARD hull: looking at the pylon face, the wire channel exits RIGHT"

if [ "$ACTIVE" = "1" ] && [ -f stl/airboat_guardwasher_a2212_dirP.stl ] \
                       && [ -f stl/airboat_guardwasher_a2212_dirN.stl ]; then
    if cmp -s stl/airboat_guardwasher_a2212_dirP.stl stl/airboat_guardwasher_a2212_dirN.stl; then
        echo "*** the two guard hands rendered IDENTICAL -- handedness has been lost"
        exit 1
    fi
    echo "    the two hands differ (as they must) -- print both, do not mirror one"
fi

# Fore-aft symmetric -> ONE part serves all four corners of the centre box.
sec "centre-box connector bracket (x4)"
scad stl/airboat_centrebox_connector.stl connector connector.scad -D 'conn_show="print"' -D '$fn=128'

# A full rail = one START + N MID + one END.  seg_holes 4 x rail_pitch 40 = 160 mm.
sec "rail: start segment"
scad stl/airboat_rail_start_160mm.stl rail_start rail.scad -D 'rail="segment"' -D 'rail_type="start"' -D '$fn=128'

sec "rail: mid segment"
scad stl/airboat_rail_mid_160mm.stl   rail_mid   rail.scad -D 'rail="segment"' -D 'rail_type="mid"'   -D '$fn=128'

sec "rail: end segment"
scad stl/airboat_rail_end_160mm.stl   rail_end   rail.scad -D 'rail="segment"' -D 'rail_type="end"'   -D '$fn=128'

# Blanking caps: one plug per hole RANGE, so "12" covers both the 12 and 12.2 bores.
sec "blanking caps: 12 mm family (row of 4)"
scad stl/airboat_cap_12.stl cap12 caps.scad -D 'cap="small"' -D 'cap_n=4' -D '$fn=256'

sec "blanking caps: 16 mm family (row of 4)"
scad stl/airboat_cap_16.stl cap16 caps.scad -D 'cap="big"'   -D 'cap_n=4' -D '$fn=256'

ACTIVE=1
echo
ls -la stl/*.stl
