#!/usr/bin/env bash
# Render every part to stl/ and verify each one against the spec.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p stl

for L in 50 75 100 140; do
    echo "--- arm${L}"
    openscad -o "stl/gopro_arm_${L}mm.stl" --render -D 'x=0' -D "part=\"arm${L}\"" main.scad 2>&1 \
        | grep -E "Status|WARNING|ERROR" || true
    python3 verify.py "stl/gopro_arm_${L}mm.stl" --length "${L}" | tail -4
done

echo "--- gauge"
openscad -o "stl/gopro_fit_gauge.stl" --render -D 'x=0' -D 'part="gauge"' main.scad 2>&1 \
    | grep -E "Status|WARNING|ERROR" || true
python3 verify.py "stl/gopro_fit_gauge.stl" --length 21 --gauge | tail -4

echo "--- set (all four on one plate)"
openscad -o "stl/gopro_arms_set.stl" --render -D 'x=0' -D 'part="set"' main.scad 2>&1 \
    | grep -E "Status|WARNING|ERROR" || true

ls -la stl/
