#!/usr/bin/env bash
# Render every part to stl/ and verify each one against the spec.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stl

# OpenSCAD 2026.07 turned --render into an option that TAKES AN ARGUMENT, so
# the bare `--render` this script used to pass swallowed the .scad filename,
# openscad printed its usage and exited non-zero -- and the `| grep ... || true`
# on the end threw that away.  Every part "built" and every verify ran against
# whatever stale STL happened to be on disk.  So renders go through here now:
# one place that knows the flag, and a failure that stops the build.
scad() {
    local out="$1" part="$2"
    if ! msg=$(openscad -o "$out" --export-format binstl --render=force \
                        -D 'x=0' -D "part=\"${part}\"" main.scad 2>&1); then
        echo "$msg"
        echo "*** openscad failed rendering ${part}"
        exit 1
    fi
    grep -E "Status|WARNING|ERROR" <<<"$msg" || true
}

# FIRST, because every measurement below reaches the mesh through load(), and a
# loader that returns an empty mesh does not error -- it measures 0.0 mm^3 and
# an inverted bbox, which fitcheck.py reads as a perfect fit.  A gate whose
# instrument is untested is not a gate.
echo "--- loader self-test"
python3 verify.py --selftest | tail -2

for L in 50 75 100 140; do
    echo "--- arm${L}"
    scad "stl/gopro_arm_${L}mm.stl" "arm${L}"
    python3 verify.py "stl/gopro_arm_${L}mm.stl" --length "${L}" | tail -4
done

echo "--- gauge"
scad "stl/gopro_fit_gauge.stl" "gauge"
python3 verify.py "stl/gopro_fit_gauge.stl" --length 21 --gauge | tail -4

echo "--- set (all four on one plate)"
scad "stl/gopro_arms_set.stl" "set"

for L in 50 75 100 140; do
    echo "--- simple${L}"
    scad "stl/gopro_arm_simple_${L}mm.stl" "simple${L}"
    python3 verify.py "stl/gopro_arm_simple_${L}mm.stl" --length "${L}" --simple | tail -4
done

echo "--- simple gauge"
scad "stl/gopro_fit_gauge_simple.stl" "sgauge"
python3 verify.py "stl/gopro_fit_gauge_simple.stl" --length 21 --gauge --simple | tail -4

echo "--- simple set (all four on one plate)"
scad "stl/gopro_arms_simple_set.stl" "sset"

echo "--- pipe clamp"
scad "stl/gopro_pipe_clamp_12mm.stl" "clamp"
python3 verify_clamp.py "stl/gopro_pipe_clamp_12mm.stl" | tail -4

echo "--- quick-release buckle"
scad "stl/gopro_qr_buckle.stl" "buckle"
python3 verify_buckle.py "stl/gopro_qr_buckle.stl" | tail -4

echo "--- 90 deg twist adapter"
scad "stl/gopro_90_twist.stl" "twist"
python3 verify_twist.py "stl/gopro_90_twist.stl" | tail -4

# The fit coupon comes before the part it sizes, because that is the order they
# get printed in: the cap's press fit is set from a tube nobody has measured to
# better than "about 9.9".
echo "--- pipe cap fit gauge"
scad "stl/pipe_cap_12mm_gauge.stl" "capgauge"
python3 verify_cap.py "stl/pipe_cap_12mm_gauge.stl" --gauge | tail -4

echo "--- pipe fairing cap"
scad "stl/pipe_cap_12mm.stl" "cap"
python3 verify_cap.py "stl/pipe_cap_12mm.stl" | tail -4

echo "--- pipe fairing cap (four on a plate)"
scad "stl/pipe_cap_12mm_x4.stl" "capset"

echo "--- mating / interference (a shipping gate that never checks FIT is no gate)"
python3 fitcheck.py
python3 fitcheck.py --simple
# The twist adapter is the one part whose two ends articulate in planes the
# other end cannot see, so each is swung independently against the reference.
python3 fitcheck.py --twist
# The buckle is swung against a REAL arm rather than the ideal reference, and
# it is the only part here whose gate is a range and not just zero at 0 deg:
# the connector is raised exactly far enough to free a half turn, so a check
# that only asked "does it fit collinear" would pass the unraised part too.
python3 fitcheck.py --buckle

ls -la stl/
