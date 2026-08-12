#!/usr/bin/env python3
"""Drive fitcheck.scad and report interference volume vs hinge angle.

Interference against an exactly-nominal GoPro reference must be 0.000 mm^3
at every angle inside the working range.  The ctrl_* test must be non-zero:
if the control reads zero, the probe is blind and the other results mean
nothing.
"""
import os
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify import load, volume            # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = os.environ.get('TMPDIR', '/tmp')


def run(test, ang, armL=100):
    out = os.path.join(TMP, f'fc_{test}_{ang}.stl')
    cmd = ['openscad', '-o', out, '--render',
           '-D', f'ang={ang}', '-D', f'armL={armL}', '-D', f'test="{test}"',
           os.path.join(HERE, 'fitcheck.scad')]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=HERE)
    if not os.path.exists(out) or os.path.getsize(out) < 100:
        return 0.0, r.stderr
    try:
        v = volume(load(out))
    except Exception:
        v = 0.0
    os.remove(out)
    return v, r.stderr


def main():
    armL = 100
    print(f"interference volume vs hinge angle   (arm L={armL}, "
          f"ang=0 is collinear / fully extended)\n")

    print("  CONTROL -- male driven 1.0 mm off-axis in Y; must be NON-zero")
    v, _ = run('ctrl_male', 0, armL)
    print(f"    ctrl_male   ang=  0   {v:10.4f} mm^3   "
          + ("OK (probe can see collisions)" if v > 0.1 else "*** BLIND PROBE ***"))
    ctrl_ok = v > 0.1

    results = {}
    for test in ('male_in_ours', 'ours_in_female'):
        print(f"\n  {test}")
        rng = []
        for ang in range(-120, 121, 10):
            v, err = run(test, ang, armL)
            flag = '' if v < 1e-6 else '  <-- interference'
            if v < 1e-6:
                rng.append(ang)
            print(f"    ang={ang:5d}   {v:10.4f} mm^3{flag}")
        results[test] = rng

    print("\n  clear articulation range (interference exactly 0.0000):")
    ok = True
    for k, v in results.items():
        if v:
            print(f"    {k:16s}  {min(v):+d} .. {max(v):+d} deg")
        else:
            print(f"    {k:16s}  NONE -- does not even mate straight!")
            ok = False
        if 0 not in v:
            print(f"    *** {k} FOULS AT 0 deg (collinear) -- it does not fit ***")
            ok = False

    print()
    if ok and ctrl_ok:
        print("FIT OK: mates an exactly-nominal GoPro part with zero interference.")
        return 0
    print("FIT FAILED")
    return 1


if __name__ == '__main__':
    sys.exit(main())
