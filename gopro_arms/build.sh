#!/usr/bin/env bash
# Render every part to stl/ and verify each one against the spec.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stl

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

echo "--- mating / interference (a shipping gate that never checks FIT is no gate)"
python3 fitcheck.py
python3 fitcheck.py --simple

ls -la stl/
