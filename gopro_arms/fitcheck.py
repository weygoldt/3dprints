#!/usr/bin/env python3
"""Drive fitcheck.scad and report interference volume vs hinge angle.

Interference against an exactly-nominal GoPro reference must be 0.000 mm^3
at every angle inside the working range.  The ctrl_* test must be non-zero:
if the control reads zero, the probe is blind and the other results mean
nothing.

  python3 fitcheck.py                 the streamlined arm (arm.scad)
  python3 fitcheck.py --simple        the simple variant (arm_simple.scad)
  python3 fitcheck.py --twist         the 90 deg twist adapter (twist.scad)
  python3 fitcheck.py --double        arm_double() -- 3-prong at both ends
  python3 fitcheck.py --buckle        a simple arm on the quick-release
                                      buckle's hinge (buckle.scad)
  python3 fitcheck.py --plate         the rail plate's connector (plate.scad)
  python3 fitcheck.py --plate155      ... and the WIDE plate's, yawed 90 deg
  python3 fitcheck.py --chain         also swing one of our arms against
                                      another, which is the pairing the body
                                      shape actually limits

--twist sweeps its TWO ENDS SEPARATELY, and that is not tidiness: the adapter's
whole job is that its two hinge axes stand at right angles, so each end
articulates in a plane the other cannot see.  One sweep would measure a pose.

--buckle breaks the pattern the other three share, twice, and both times
because of what is being asked.  It swings a REAL ARM rather than the ideal
reference, because what limits that hinge is arm_simple's 15.0 mm slab body and
the reference has no body worth the name.  And it GATES ON THE RANGE, not on
zero-at-collinear: the buckle's connector is raised exactly far enough to free
a half turn, and a check that only asked "does it fit extended" would pass the
unraised part just as happily.
"""
import argparse
import math
import os
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify import load, volume, bbox      # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = os.environ.get('TMPDIR', '/tmp')


def run(test, ang, armL=100):
    out = os.path.join(TMP, f'fc_{test}_{ang}.stl')
    # An EMPTY intersection makes no file at all, and the read below treats a
    # file that exists as this render's answer.  So anything left at that path
    # by an earlier run -- one that died between rendering and the os.remove()
    # further down -- would be read as the volume for THIS angle.  Clear it
    # first: the only thing at `out` after this line is what openscad puts
    # there.
    if os.path.exists(out):
        os.remove(out)
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
        return 0.0, None, r.stderr
    # NOT wrapped in try/except.  It was, returning 0.0 on any exception, which
    # is the same false-pass as the empty-file case above wearing a different
    # hat: every way of failing to READ the mesh became "no interference".  By
    # here the render succeeded and the file is >= 100 bytes, so there is no
    # benign parse failure left to absorb -- anything load() raises is a real
    # fault and has to stop the gate.  The file is deliberately left on disk.
    tris = load(out)
    v, bb = volume(tris), bbox(tris)
    os.remove(out)
    # The bbox comes back with the volume because WHERE two parts touch says
    # something the volume cannot: see the buckle's grid check below, where a
    # mating stack centred on the wrong prong measures nearly the same volume
    # and lands somewhere else entirely.
    return v, bb, r.stderr


# ---- the quick-release buckle ---------------------------------------
# Its own driver, because both of its preliminaries differ in kind from the
# arms' single off-axis control.  See fitcheck.scad for the placement.
MID_PRONG = (14.681, 17.856)       # the donor's middle prong, measured
GRID_OVERLAP = (3.175 - 3.10)/2    # per finger: the donor's 1/8" against our slot
D_BORE, KNUCKLE_R = 5.461, 7.3655  # ... and the donor's bore and knuckle


def buckle_main(armL):
    print("interference volume vs hinge angle   (the SIMPLE arm's BODY on the\n"
          "QUICK-RELEASE BUCKLE's hinge; ang=0 stands the arm straight up out\n"
          "of the clip, which is this pairing's collinear)\n")
    ok = True

    # [1] The donor's IMPERIAL grid, measured instead of assumed -- and it is
    # the reason the sweep runs on the arm's body.  Both fingers overlap the
    # middle prong by (3.175 - 3.10)/2 at EVERY angle, so the two faces are the
    # whole prediction: a full R7.3655 knuckle disc less the donor's own bore.
    pred = 2 * GRID_OVERLAP * math.pi * (KNUCKLE_R**2 - (D_BORE/2)**2)
    print("  GRID -- the joint envelope left IN, at the extended pose")
    v, bb, _ = run('buckle_grid', 0, armL)
    print(f"    buckle_grid  ang=  0   {v:10.4f} mm^3   against {pred:.4f} predicted")
    # VOLUME ALONE CANNOT SEE A MIS-CENTRED STACK: shift the arm along the
    # hinge and one finger bites deeper by exactly what the other gives up, so
    # the total does not move.  Where it lands does.  Confined to the middle
    # prong is the claim -- if a finger ever reached an OUTER prong, or only
    # one of them touched, this bbox says so and the volume does not.
    grid_ok = 0.9*pred < v < 1.15*pred
    span_ok = bb is not None and (abs(bb[0][0] - MID_PRONG[0]) < 0.01
                                  and abs(bb[1][0] - MID_PRONG[1]) < 0.01)
    print(f"    ... x {bb[0][0]:.3f}..{bb[1][0]:.3f} against the middle prong's "
          f"{MID_PRONG[0]:.3f}..{MID_PRONG[1]:.3f}"
          if bb else "    ... NO BBOX -- nothing intersected")
    print("    " + ("OK (the 1/8\" grid, on the middle prong and nowhere else)"
                    if grid_ok and span_ok else
                    "*** not the grid overlap this test claims to isolate ***"))
    ok = ok and grid_ok and span_ok

    # [2] CONTROL, and it is a POSE rather than an offset.  The arms nudge
    # their reference 1.0 mm along the hinge axis to close the slot clearance;
    # there is nothing here to nudge it into, because at the extended pose the
    # arm points into 190 deg of open air.  What must collide is the arm driven
    # straight DOWN into the clip plate -- deliberately outside the swept range
    # below, so the control is not merely one of the sweep's own points.
    print("\n  CONTROL -- the same body at ang=180, into the plate; must be NON-zero")
    v, _, _ = run('simple_in_buckle', 180, armL)
    print(f"    simple_in_buckle ang=180   {v:10.4f} mm^3   "
          + ("OK (probe can see body on body)" if v > 0.1 else "*** BLIND PROBE ***"))
    ok = ok and v > 0.1

    # SIX decimals, not the four the other sweeps print.  The angles that
    # decide this range come free through the 1e-5 range -- at ang=-100 the
    # interference falls 1.5e-4 -> 1.3e-5 -> 1.4e-7 as the raise goes
    # 1.25 -> 1.50 -> 1.70 -- and at four places every one of those reads
    # "0.0000" with an interference flag beside it, which is unreadable.
    # The 1e-7 floor is the coincident-face dust off the eased gap; it is two
    # orders under the gate and it does not move with the hinge.
    print("\n  simple_in_buckle")
    rng = []
    for ang in range(-120, 121, 10):
        v, _, _ = run('simple_in_buckle', ang, armL)
        if v < 1e-6:
            rng.append(ang)
        print(f"    ang={ang:5d}   {v:12.6f} mm^3"
              + ('' if v < 1e-6 else '  <-- interference'))

    print("\n  clear articulation range (interference exactly 0.0000):")
    if 0 not in rng:
        print("    simple_in_buckle  FOULS AT 0 deg (extended) -- it does not fit")
        ok = False
    else:
        lo = hi = 0
        while lo - 10 in rng:
            lo -= 10
        while hi + 10 in rng:
            hi += 10
        gaps = [a for a in rng if a < lo or a > hi]
        note = f"   (also clear at {gaps} -- NOT reachable)" if gaps else ""
        print(f"    simple_in_buckle  {lo:+d} .. {hi:+d} deg  "
              f"= {hi - lo} deg of swing{note}")
        ok = ok and (hi - lo) >= 180

    print()
    if ok:
        print("FIT OK: a simple arm swings a full 180 deg on the buckle's hinge.")
        return 0
    print("FIT FAILED")
    return 1


# ---- the rail plate -------------------------------------------------
# Its own driver, because the question is a RANGE and the range is not
# symmetric.  A connector standing on a plate can only swing through the half
# space above the plate, and one of the two halves of THAT is aimed straight at
# the plate's other connector.  So the sweep runs -20..180 with ang = 0 flat
# OUTBOARD, and the gate is the outboard quadrant 0..90.  Two things fall out
# for free and are checked as controls in their own right: below 0 the mating
# part must FOUL (it is under the plate -- if it does not, the plate is not
# where this test thinks it is), and past 90 it eventually meets the other
# connector, which is reported rather than gated.
PLATE_GATE = 90        # deg of clear outboard swing the plate must give


def plate_main(armL, wide=False):
    sfx = '155' if wide else ''
    tail = ("plate, 90 stands it up, 180 lays it flat back across it.  Its one\n"
            "connector is centred, so there is no neighbour to meet and the\n"
            "real arm should keep the whole half turn.\n" if wide else
            "plate, 90 stands it up, 180 lays it flat inboard at the other\n"
            "connector)\n")
    print(f"interference volume vs hinge angle   (mating parts on the "
          f"{'WIDE ' if wide else ''}RAIL\n"
          f"PLATE's connector; ang=0 lays the part flat OUTBOARD along the\n"
          + tail)
    ok = True

    print("  CONTROL -- male driven 1.0 mm off-axis in Y; must be NON-zero")
    v, _, _ = run(f'ctrl_plate{sfx}', 0, armL)
    ctrl_ok = v > 0.1
    print(f"    ctrl_plate{sfx:3s} ang=  0   {v:10.4f} mm^3   "
          + ("OK (probe can see collisions)" if ctrl_ok else "*** BLIND PROBE ***"))
    ok = ok and ctrl_ok

    results = {}
    for test in [f'male_in_plate{sfx}', f'simple_in_plate{sfx}']:
        print(f"\n  {test}")
        rng = []
        for ang in range(-20, 181, 10):
            v, _, _ = run(test, ang, armL)
            if v < 1e-6:
                rng.append(ang)
            print(f"    ang={ang:5d}   {v:10.4f} mm^3"
                  + ('' if v < 1e-6 else '  <-- interference'))
        results[test] = rng

    print("\n  clear swing measured from flat-outboard (0 deg):")
    for k, rng in results.items():
        if 0 not in rng:
            print(f"    {k:16s}  FOULS AT 0 deg -- it will not lie flat on the plate")
            ok = False
            continue
        # Contiguous band through 0.  min()..max() would paper over a hinge
        # that jams part-way and call the whole span clear.
        lo = hi = 0
        while lo - 10 in rng:
            lo -= 10
        while hi + 10 in rng:
            hi += 10
        reach_ok = hi >= PLATE_GATE
        # BELOW flat-outboard is under the plate.  A clear reading there is not
        # good news, it means the probe never met the plate at all.
        under_ok = -10 not in rng
        print(f"    {k:16s}  {lo:+d} .. {hi:+d} deg   "
              f"(need 0..{PLATE_GATE}) "
              + ("OK" if reach_ok else "*** short of the gate ***")
              + ("" if under_ok else "  *** and CLEAR below the plate -- "
                                     "this probe is not touching the plate ***"))
        ok = ok and reach_ok and under_ok

    print()
    if ok:
        print(f"FIT OK: an arm swings flat-outboard to vertical and past it, and "
              f"the plate stops it going under.")
        return 0
    print("FIT FAILED")
    return 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--simple', action='store_true',
                    help='test arm_simple.scad instead of arm.scad')
    ap.add_argument('--twist', action='store_true',
                    help='test twist.scad -- both ends, each on its own axis')
    ap.add_argument('--buckle', action='store_true',
                    help="the simple arm on the quick-release buckle's hinge")
    ap.add_argument('--double', action='store_true',
                    help='arm_double() -- both ends 3-prong, each swung on its '
                         'own against the reference male')
    ap.add_argument('--plate', action='store_true',
                    help="the rail plate's connector, swept over the half "
                         "space above the plate")
    ap.add_argument('--plate155', action='store_true',
                    help="the WIDE plate's single centred connector, which is "
                         "yawed 90 deg and has no neighbour to foul")
    ap.add_argument('--chain', action='store_true',
                    help='also swing one of our arms against another')
    args = ap.parse_args()
    armL = 100
    if args.buckle:
        return buckle_main(armL)
    if args.plate:
        return plate_main(armL)
    if args.plate155:
        return plate_main(armL, wide=True)
    if args.double:
        ctrl = 'ctrl_double'
        tests = ['male_in_double_a', 'male_in_double_b']
        # No chain case, and not from laziness: both of this arm's ends are
        # FEMALE, so two of them cannot couple to each other at all.  That is
        # the reason the part exists, so there is nothing there to measure.
        chain = None
    elif args.twist:
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
            else '3-prong BOTH ENDS, each end swung on its own' if args.double
            else f"{'SIMPLE' if args.simple else 'streamlined'} arm, L={armL}")
    print(f"interference volume vs hinge angle   "
          f"({what}, ang=0 is collinear / fully extended)\n")

    print(f"  CONTROL -- male driven 1.0 mm off-axis in Y; must be NON-zero")
    v, _, _ = run(ctrl, 0, armL)
    print(f"    {ctrl:12s} ang=  0   {v:10.4f} mm^3   "
          + ("OK (probe can see collisions)" if v > 0.1 else "*** BLIND PROBE ***"))
    ctrl_ok = v > 0.1

    results = {}
    for test in tests:
        print(f"\n  {test}")
        rng = []
        for ang in range(-120, 121, 10):
            v, _, err = run(test, ang, armL)
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
