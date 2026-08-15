#!/usr/bin/env python3
"""Drive fitcheck.scad and report interference volume vs hinge angle.

Interference against an exactly-nominal GoPro reference must be 0.000 mm^3
at every angle inside the working range.  The ctrl_* test must be non-zero:
if the control reads zero, the probe is blind and the other results mean
nothing.

  python3 fitcheck.py                 the streamlined arm (arm.scad)
  python3 fitcheck.py --simple        the simple variant (arm_simple.scad)
  python3 fitcheck.py --twist         the 90 deg twist adapter (twist.scad)
  python3 fitcheck.py --chain         also swing one of our arms against
                                      another, which is the pairing the body
                                      shape actually limits

--twist sweeps its TWO ENDS SEPARATELY, and that is not tidiness: the adapter's
whole job is that its two hinge axes stand at right angles, so each end
articulates in a plane the other cannot see.  One sweep would measure a pose.
"""
import argparse
import os
import subprocess
import sys

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
    # A render that FAILED also produces no file, which without a check is
    # indistinguishable from "the parts do not intersect" -- every angle would
    # silently certify as a perfect fit.  But openscad also exits NON-ZERO on a
    # legitimately empty result, so returncode alone conflates the two.  The
    # empty-object message is the discriminator; anything else is a real fault.
    empty = 'Current top level object is empty' in r.stderr
    broken = ("Can't open import file" in r.stderr
              or "Can't find include file" in r.stderr
              or 'ERROR:' in r.stderr)
    if broken or (r.returncode != 0 and not empty):
        raise RuntimeError(f"openscad failed ({test}, ang={ang}):\n{r.stderr[-800:]}")
    if not os.path.exists(out) or os.path.getsize(out) < 100:
        if not empty:
            raise RuntimeError(
                f"no output and no empty-object message ({test}, ang={ang}) -- "
                f"refusing to read that as zero interference")
        return 0.0, r.stderr
    # NOT wrapped in try/except.  It was, returning 0.0 on any exception, which
    # is the same false-pass as the empty-file case above wearing a different
    # hat: every way of failing to READ the mesh became "no interference".  By
    # here the render succeeded and the file is >= 100 bytes, so there is no
    # benign parse failure left to absorb -- anything load() raises is a real
    # fault and has to stop the gate.  The file is deliberately left on disk.
    v = volume(load(out))
    os.remove(out)
    return v, r.stderr


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--simple', action='store_true',
                    help='test arm_simple.scad instead of arm.scad')
    ap.add_argument('--twist', action='store_true',
                    help='test twist.scad -- both ends, each on its own axis')
    ap.add_argument('--chain', action='store_true',
                    help='also swing one of our arms against another')
    args = ap.parse_args()
    armL = 100
    if args.twist:
        ctrl = 'ctrl_twist'
        tests = ['male_in_twist', 'twist_in_female']
        chain = None
    elif args.simple:
        ctrl = 'ctrl_simple'
        tests = ['male_in_simple', 'simple_in_female']
        chain = 'simple_in_simple'
    else:
        ctrl = 'ctrl_male'
        tests = ['male_in_ours', 'ours_in_female']
        chain = 'arm_in_arm'
    if args.chain and chain:
        tests.append(chain)

    what = ('90 deg TWIST adapter, each end on its own axis' if args.twist
            else f"{'SIMPLE' if args.simple else 'streamlined'} arm, L={armL}")
    print(f"interference volume vs hinge angle   "
          f"({what}, ang=0 is collinear / fully extended)\n")

    print(f"  CONTROL -- male driven 1.0 mm off-axis in Y; must be NON-zero")
    v, _ = run(ctrl, 0, armL)
    print(f"    {ctrl:12s} ang=  0   {v:10.4f} mm^3   "
          + ("OK (probe can see collisions)" if v > 0.1 else "*** BLIND PROBE ***"))
    ctrl_ok = v > 0.1

    results = {}
    for test in tests:
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
        if 0 not in v:
            print(f"    {k:16s}  FOULS AT 0 deg (collinear) -- it does not fit")
            ok = False
            continue
        # CONTIGUOUS band through collinear.  min()..max() would paper over a
        # hinge that jams solid part-way through its travel and report the
        # whole span as clear.
        lo = hi = 0
        while lo - 10 in v:
            lo -= 10
        while hi + 10 in v:
            hi += 10
        gaps = [a for a in v if a < lo or a > hi]
        note = f"   (also clear at {gaps} -- NOT reachable)" if gaps else ""
        print(f"    {k:16s}  {lo:+d} .. {hi:+d} deg{note}")

    print()
    if ok and ctrl_ok:
        print("FIT OK: mates an exactly-nominal GoPro part with zero interference.")
        return 0
    print("FIT FAILED")
    return 1


if __name__ == '__main__':
    sys.exit(main())
