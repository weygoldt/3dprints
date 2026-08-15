#!/usr/bin/env bash
# Render every part to stl/ and verify each one against the spec.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stl

# FIRST, because every measurement below reaches the mesh through load(), and a
# loader that returns an empty mesh does not error -- it measures 0.0 mm^3 and
# an inverted bbox, which fitcheck.py reads as a perfect fit.  A gate whose
# instrument is untested is not a gate.
echo "--- loader self-test"
python3 verify.py --selftest | tail -2

for L in 50 75 100 140; do
    echo "--- arm${L}"
    openscad -o "stl/gopro_arm_${L}mm.stl" --export-format binstl --render -D 'x=0' -D "part=\"arm${L}\"" main.scad 2>&1 \
        | grep -E "Status|WARNING|ERROR" || true
    python3 verify.py "stl/gopro_arm_${L}mm.stl" --length "${L}" | tail -4
done

echo "--- gauge"
openscad -o "stl/gopro_fit_gauge.stl" --export-format binstl --render -D 'x=0' -D 'part="gauge"' main.scad 2>&1 \
    | grep -E "Status|WARNING|ERROR" || true
python3 verify.py "stl/gopro_fit_gauge.stl" --length 21 --gauge | tail -4

echo "--- set (all four on one plate)"
openscad -o "stl/gopro_arms_set.stl" --export-format binstl --render -D 'x=0' -D 'part="set"' main.scad 2>&1 \
    | grep -E "Status|WARNING|ERROR" || true

for L in 50 75 100 140; do
    echo "--- simple${L}"
    openscad -o "stl/gopro_arm_simple_${L}mm.stl" --export-format binstl --render -D 'x=0' -D "part=\"simple${L}\"" main.scad 2>&1 \
        | grep -E "Status|WARNING|ERROR" || true
    python3 verify.py "stl/gopro_arm_simple_${L}mm.stl" --length "${L}" --simple | tail -4
done

echo "--- simple gauge"
openscad -o "stl/gopro_fit_gauge_simple.stl" --export-format binstl --render -D 'x=0' -D 'part="sgauge"' main.scad 2>&1 \
    | grep -E "Status|WARNING|ERROR" || true
python3 verify.py "stl/gopro_fit_gauge_simple.stl" --length 21 --gauge --simple | tail -4

echo "--- simple set (all four on one plate)"
openscad -o "stl/gopro_arms_simple_set.stl" --export-format binstl --render -D 'x=0' -D 'part="sset"' main.scad 2>&1 \
    | grep -E "Status|WARNING|ERROR" || true

echo "--- pipe clamp"
openscad -o "stl/gopro_pipe_clamp_12mm.stl" --export-format binstl --render -D 'x=0' -D 'part="clamp"' main.scad 2>&1 \
    | grep -E "Status|WARNING|ERROR" || true
python3 verify_clamp.py "stl/gopro_pipe_clamp_12mm.stl" | tail -4

echo "--- quick-release buckle"
openscad -o "stl/gopro_qr_buckle.stl" --export-format binstl --render -D 'x=0' -D 'part="buckle"' main.scad 2>&1 \
    | grep -E "Status|WARNING|ERROR" || true
python3 verify_buckle.py "stl/gopro_qr_buckle.stl" | tail -4

echo "--- 90 deg twist adapter"
openscad -o "stl/gopro_90_twist.stl" --export-format binstl --render -D 'x=0' -D 'part="twist"' main.scad 2>&1 \
    | grep -E "Status|WARNING|ERROR" || true
python3 verify_twist.py "stl/gopro_90_twist.stl" | tail -4

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
