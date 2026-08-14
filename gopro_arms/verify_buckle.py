#!/usr/bin/env python3
"""Measure the quick-release buckle against the two pockets it exists for.

  python3 verify_buckle.py stl/gopro_qr_buckle.stl

Two questions, and they need different instruments.

WHAT WE ADDED is measured off the finished mesh by ray-casting, the same way
verify.py measures an arm: predict each number from the geometry, then check
the measurement against the prediction rather than against a round number.

WHAT WE DID NOT TOUCH cannot be measured that way at all.  "The rest of the
buckle is unchanged" is a claim about two SETS, and a pocket cut in the wrong
place measures exactly as well as one cut in the right place.  So [2] renders
the two set differences through buckle_diff.scad -- what we added, and what we
took out -- and holds each to its intended footprint.

The check that matters most is [4], and it is not a dimension.  Measuring
"8.00 across flats" proves nothing: a ROUND hole 8.00 wide passes it and lets
the nut spin.  [4] instead sweeps the pocket's own boundary and asks how far a
centred M5 nut can turn before its corners bind -- 0 deg is a trap, 60 deg is
a hole.  Its control is the head counterbore, which is a genuine round bore on
this very part and must therefore read FREE.  If it does not, the sweep is
measuring something other than what it claims and [4] means nothing.
"""
import math
import os
import subprocess
import sys

from verify import (load, bbox, volume, near_axis, ray_intervals,   # noqa: E402
                    ray_hits, normal)
from verify import (NUT_AF, NUT_T, NUT_WALL, TAB_R,                 # noqa: E402
                    HEAD_D, HEAD_DA, S_PKT_AF, S_PKT_DEPTH, S_HD_D,
                    S_HD_DEPTH, S_HEAD_CS, S_BOSS_RIM)

BOSS_RIM = S_BOSS_RIM   # the same rim round arm_simple.scad rolls on its bosses

HERE = os.path.dirname(os.path.abspath(__file__))
TMP = os.environ.get('TMPDIR', '/tmp')
DONOR = os.path.join(HERE, 'inspiration', 'Quck Release v3 clip.STL')

# ---- the donor, measured (mirrors buckle.scad) -----------------------
PIVOT_Y   = 15.240
PIVOT_Z   = 12.700
D_BORE    =  5.461     # the donor's pivot bore -- wider than our own 5.30
KNUCKLE_R =  7.3655
FACE_NUT  =  5.0164    # low-x prong: outer face of the boss the donor has
SLOT_NUT  = 11.506     # ... and the slot wall behind it
FACE_HD   = 23.635     # high-x prong: the plain outer face
SLOT_HD   = 21.031     # ... and the slot wall behind it
UNIT      = 3.175      # the donor's grid: 1/8", not our 3.00 mm

# ---- derived, exactly as buckle.scad derives them --------------------
BOSS_HD   = max(0.0, S_HD_DEPTH + NUT_WALL - (FACE_HD - SLOT_HD))   # 4.196
BK_FACE   = FACE_HD + BOSS_HD                                       # 27.831
HD_FLOOR  = BK_FACE - S_HD_DEPTH                                    # 22.531
NUT_FLOOR = FACE_NUT + S_PKT_DEPTH                                  # 9.3164
PKT_R     = S_PKT_AF/math.sqrt(3)                                   # 4.6188
CS_INNER  = HD_FLOOR - S_HEAD_CS                                    # 22.031

FAIL = []
WARN = []


def check(ok, msg):
    print(("  PASS  " if ok else "  FAIL  ") + msg)
    if not ok:
        FAIL.append(msg)


def warn(ok, msg):
    print(("  ok    " if ok else "  WARN  ") + msg)
    if not ok:
        WARN.append(msg)


# ---- probes ----------------------------------------------------------
# Angles are measured in the YZ plane about the pivot: 0 deg is +Y, which is
# UP in the print orientation (the buckle sits on its y = 0 face), and 90 deg
# is +Z, along the buckle's length.
def spans_x(tris, y, z):
    t = near_axis(near_axis(tris, 1, y), 2, z)
    return [(a - 100, b - 100) for a, b in ray_intervals(t, (-100.0, y, z), 0)]


def at(r, ang):
    return (PIVOT_Y + r*math.cos(math.radians(ang)),
            PIVOT_Z + r*math.sin(math.radians(ang)))


def wall_r(tsub, x, ang):
    """Radius at which material starts, looking out from the pivot axis."""
    a = math.radians(ang)
    h = [q for q in ray_hits(tsub, (x, PIVOT_Y, PIVOT_Z), [0.0, math.cos(a), math.sin(a)])
         if q > 1e-9]
    return h[0] if h else None


def outer_r(tsub, x, ang):
    """Outermost material along the same ray."""
    a = math.radians(ang)
    h = [q for q in ray_hits(tsub, (x, PIVOT_Y, PIVOT_Z), [0.0, math.cos(a), math.sin(a)])
         if q > 1e-9]
    return h[-1] if h else None


def hex_r(phi, theta, af):
    """Boundary radius of a hex of across-flats `af`, turned `theta`, at `phi`."""
    d = ((phi - theta + 30.0) % 60.0) - 30.0
    return (af/2)/math.cos(math.radians(d))


def max_turn(tris, x, af=NUT_AF):
    """How far a centred hex of across-flats `af` can turn at this x.

    0 deg means its corners bind on the pocket wall the instant it moves --
    a trap.  30 deg means it is through the worst misalignment there is, so
    by the hexagon's own symmetry it turns freely; report that as 60.
    """
    tsub = near_axis(tris, 0, x)
    cache = {}

    def pr(phi):
        key = round(phi % 360.0, 4)
        if key not in cache:
            cache[key] = wall_r(tsub, x, key) or 0.0
        return cache[key]

    def fits(th):
        # The six CORNERS are where a hex binds, so they are tested exactly;
        # the background sweep makes no convexity assumption on the pocket.
        phis = [th + 30.0 + 60.0*k for k in range(6)] + [2.0*k for k in range(180)]
        return all(pr(p) >= hex_r(p, th, af) - 1e-6 for p in phis)

    if not fits(0.0):
        return -1.0                     # will not go in square, let alone turn
    if fits(30.0):
        return 60.0                     # past the worst case: free
    lo, hi = 0.0, 30.0
    for _ in range(44):
        m = (lo + hi)/2
        if fits(m):
            lo = m
        else:
            hi = m
    return lo


def render(test):
    """One boolean from buckle_diff.scad, measured.  Empty is a real answer."""
    out = os.path.join(TMP, f'bk_{test}.stl')
    cmd = ['openscad', '-o', out, '--render', '-D', f'test="{test}"',
           os.path.join(HERE, 'buckle_diff.scad')]
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=HERE)
    # Same discipline as fitcheck.py: a render that FAILED also produces no
    # file, and without this a broken render would read as "we changed
    # nothing", which is the answer [2] is trying to earn.
    empty = 'Current top level object is empty' in r.stderr
    broken = ("Can't open import file" in r.stderr
              or "Can't find include file" in r.stderr
              or 'ERROR:' in r.stderr)
    if broken or (r.returncode != 0 and not empty):
        raise RuntimeError(f"openscad failed ({test}):\n{r.stderr[-800:]}")
    if not os.path.exists(out) or os.path.getsize(out) < 100:
        if not empty:
            raise RuntimeError(f"no output and no empty-object message ({test})")
        return []
    tris = load(out)
    os.remove(out)
    return tris


def main(path):
    tris = load(path)
    donor = load(DONOR)
    lo, hi = bbox(tris)
    dlo, dhi = bbox(donor)
    print(f"\n=== {path}  ({len(tris)} facets)")
    print(f"bbox  X {lo[0]:8.3f} .. {hi[0]:8.3f}   (donor {dlo[0]:.3f} .. {dhi[0]:.3f})")
    print(f"      Y {lo[1]:8.3f} .. {hi[1]:8.3f}   (donor {dlo[1]:.3f} .. {dhi[1]:.3f})")
    print(f"      Z {lo[2]:8.3f} .. {hi[2]:8.3f}   (donor {dlo[2]:.3f} .. {dhi[2]:.3f})")
    print(f"volume {volume(tris):.1f} mm^3   (donor {volume(donor):.1f})")

    # ---------------------------------------------------------------- 0
    # The boss is 4.196 mm of new material, and the part does not get one
    # micron bigger for it: the donor's own body already reaches x 32.537,
    # well past the 27.831 the boss stops at.  So the bounding box is a real
    # check, not a formality -- if it grew, the boss went on the wrong face.
    print("\n[0] the boss hides inside the donor's own bounding box")
    for k, nm in ((0, 'X'), (1, 'Y'), (2, 'Z')):
        check(abs(lo[k] - dlo[k]) < 1e-3 and abs(hi[k] - dhi[k]) < 1e-3,
              f"{nm} {lo[k]:.3f}..{hi[k]:.3f} is the donor's own extent")

    # ---------------------------------------------------------------- 1
    # The GoPro joint is the donor's and must come through untouched.  Every
    # number here is measured on BOTH meshes the same way and compared to the
    # other measurement, never to a constant -- that is what makes it a claim
    # about this donor rather than about GoPro in general.
    print("\n[1] the joint is the donor's, unaltered")
    # -80..+90 is the knuckle's FREE arc.  Outside it the donor's own body
    # blends in and the radius climbs away from the circle -- 7.394 by -85 and
    # 7.839 by -100 -- so a sweep that overran it would be measuring the body
    # and reporting it as the knuckle.
    tE = near_axis(tris, 0, 16.0)
    tD = near_axis(donor, 0, 16.0)
    rE = [outer_r(tE, 16.0, a) or 0 for a in range(-80, 91, 5)]
    rD = [outer_r(tD, 16.0, a) or 0 for a in range(-80, 91, 5)]
    check(max(abs(a-b) for a, b in zip(rE, rD)) < 1e-3,
          f"knuckle radius {min(rE):.4f}..{max(rE):.4f} over the free arc, "
          f"identical to the donor's")
    check(abs(max(rE) - KNUCKLE_R) < 1e-3,
          f"... and that radius is {KNUCKLE_R}, which is {TAB_R - KNUCKLE_R:.4f} "
          f"inside the R{TAB_R} envelope before we add anything")
    for r, ang in ((3.0, 0.0), (6.5, 90.0), (7.0, 315.0)):
        y, z = at(r, ang)
        sE, sD = spans_x(tris, y, z), spans_x(donor, y, z)
        # Only the two pockets may differ; the slots between them may not.
        # Compared with a tolerance, not with ==: the two meshes are tessellated
        # differently, so the same plane is the same number only to within the
        # ray solver's noise.
        slE = [(a, b) for a, b in sE if SLOT_NUT - 0.01 <= a and b <= SLOT_HD + 0.01]
        slD = [(a, b) for a, b in sD if SLOT_NUT - 0.01 <= a and b <= SLOT_HD + 0.01]
        same = (len(slE) == len(slD) == 1
                and max(abs(p-q) for p, q in zip(slE[0], slD[0])) < 1e-3)
        check(same,
              f"at r={r}, ang={ang:g}: the middle prong is {slE[0][1]-slE[0][0]:.3f} "
              f"at x {slE[0][0]:.3f}..{slE[0][1]:.3f}, exactly the donor's"
              if slE else f"at r={r}, ang={ang:g}: middle prong not found")
    y, z = at(3.0, 0.0)
    sE = spans_x(tris, y, z)
    gaps = [(sE[i][1], sE[i+1][0]) for i in range(len(sE)-1)]
    slots = [g for g in gaps if abs((g[1]-g[0]) - UNIT) < 0.02]
    check(len(slots) == 2,
          f"both slots still {UNIT} wide (1/8\") at "
          + ", ".join(f"{a:.3f}..{b:.3f}" for a, b in slots))
    # The bore the screw runs through is the donor's, not ours, and the
    # countersink in [6] is cut to fit IT.
    tb = near_axis(tris, 0, 16.0)
    d_meas = 2*min(wall_r(tb, 16.0, a) or 0 for a in range(0, 360, 15))
    check(abs(d_meas - D_BORE) < 0.02,
          f"pivot bore {d_meas:.3f} == the donor's {D_BORE} (our bore_d of 5.30 "
          f"is NOT imposed on it -- the donor's hole is the one that is there)")
    # The face it prints on has to survive too.
    base = sum(a for t in tris for n, a in [normal(t)]
               if n and n[1] < -0.999 and sum(p[1] for p in t)/3 < 0.01)
    dbase = sum(a for t in donor for n, a in [normal(t)]
                if n and n[1] < -0.999 and sum(p[1] for p in t)/3 < 0.01)
    check(abs(base - dbase) < 1e-3,
          f"the y=0 bed face is still {base:.1f} mm^2 -- the part prints the "
          f"same way up (+Y is UP)")

    # ---------------------------------------------------------------- 2
    print("\n[2] what we added, and what we took out -- as SETS")
    ctrl = render('ctrl')
    cv = volume(ctrl) if ctrl else 0.0
    check(cv > 0.1,
          f"CONTROL: donor minus itself shifted 0.5 mm = {cv:.1f} mm^3, non-zero "
          f"-- the boolean-and-measure path can see a difference at all"
          if cv > 0.1 else "CONTROL read zero: *** BLIND PROBE ***")

    # Measured by VOLUME, never by vertex position.  Differencing two meshes
    # that share most of their surfaces leaves coplanar, zero-volume shells
    # strewn over the coincident faces -- they are not material, but they do
    # move a bounding box, and an early version of this check failed on them
    # while the geometry underneath was exactly right.
    def poly_area(n, r):
        """A regular n-gon of CIRCUMradius r, which is what $fn = n gives."""
        return 0.5*n*r*r*math.sin(2*math.pi/n)

    def boss_volume(R, rr, h, n=180, steps=20000):
        """The boss, with a quarter-round of radius rr rolled off its outer rim.

        Straight for h - rr, then a stack of discs whose radius follows the
        arc: at t above where the round starts, R - rr + sqrt(rr^2 - t^2),
        which is R at t = 0 and R - rr at t = rr.
        """
        v = poly_area(n, R)*(h - rr)
        for i in range(steps):
            t = (i + 0.5)*rr/steps
            v += poly_area(n, R - rr + math.sqrt(rr*rr - t*t))*(rr/steps)
        return v

    added = render('added')
    av = volume(added) if added else 0.0
    # What the boss is, minus what the counterbore takes straight back out of
    # it: the counterbore is wider than the boss is long, so it passes clean
    # through, and it is nowhere near the rim -- 4.40 against the round's
    # innermost radius of KNUCKLE_R - BOSS_RIM -- so the two do not interact.
    pred_add = boss_volume(KNUCKLE_R, BOSS_RIM, BOSS_HD) - poly_area(96, S_HD_D/2)*BOSS_HD
    print(f"     added   {av:8.3f} mm^3  (boss with an r{BOSS_RIM} rim, less the "
          f"{S_HD_D} bore, over {BOSS_HD:.3f} -> {pred_add:.3f} predicted)")
    check(abs(av - pred_add) < 0.1,
          f"we added {av:.3f} mm^3 against {pred_add:.3f} predicted -- the boss "
          f"is the right size and the counterbore really does go through it")
    stray = render('added_stray')
    sv = volume(stray) if stray else 0.0
    check(sv < 1e-3,
          f"and {sv:.6f} mm^3 of it lies outside the boss fence -- nothing was "
          f"added anywhere else on the part")

    removed = render('removed')
    rv = volume(removed) if removed else 0.0
    print(f"     removed {rv:8.3f} mm^3")
    check(rv > 1.0,
          f"we removed {rv:.3f} mm^3 -- both pockets actually cut something")
    stray = render('removed_stray')
    sv = volume(stray) if stray else 0.0
    check(sv < 1e-3,
          f"and {sv:.6f} mm^3 of it lies outside the two pocket fences -- the "
          f"latch, the rails and the joint kept all their material")

    # ---------------------------------------------------------------- 3
    print("\n[3] the press-fit nut pocket")
    xm = (FACE_NUT + NUT_FLOOR)/2
    tsub = near_axis(tris, 0, xm)
    ap = min(wall_r(tsub, xm, a) or 9 for a in range(0, 360))
    cr = max(wall_r(tsub, xm, a) or 0 for a in range(0, 360))
    print(f"     at x={xm:.3f}: apothem {ap:.4f}, circumradius {cr:.4f}, "
          f"ratio {cr/ap:.4f} (a hexagon is {2/math.sqrt(3):.4f})")
    check(abs(cr/ap - 2/math.sqrt(3)) < 0.01,
          f"the pocket is a HEXAGON, not a bore that merely measures 8 across")
    check(abs(2*ap - S_PKT_AF) < 0.02,
          f"across flats {2*ap:.4f} == pkt_af {S_PKT_AF} at nominal -- the press "
          f"comes from FDM laying it undersize, not from the model")
    # FLATS UP.  +Y is up; a flat facing it means the nut lands on a face and
    # the pocket roof is a flat ceiling, which is the orientation arm_simple
    # argues for and the one the donor already cut.
    up = wall_r(tsub, xm, 0.0)
    side = wall_r(tsub, xm, 90.0)
    check(abs(up - S_PKT_AF/2) < 0.01 and abs(side - PKT_R) < 0.01,
          f"FLATS UP: the wall is {up:.4f} straight up (+Y, the apothem) and "
          f"{side:.4f} along +Z (a corner) -- a vertex up would rest the nut "
          f"on two points")
    # r = 3.4 is chosen, not convenient: it has to sit OUTSIDE the donor's
    # 2.7305 bore radius and INSIDE the pocket's 4.0005 apothem, or the ray
    # runs down the bore and never sees the floor at all.
    y, z = at(3.4, 30.0)
    sp = spans_x(tris, y, z)
    seg = [s for s in sp if abs(s[1] - SLOT_NUT) < 0.02]
    floor = seg[0][0] if seg else 0.0
    nut_floor_m = floor
    # The face the nut is sunk below, read at a radius outside the pocket.
    nut_face_m = spans_x(tris, *at(5.0, 0.0))[0][0]
    check(abs(floor - NUT_FLOOR) < 0.02,
          f"floor at x={floor:.3f} == face {FACE_NUT} + pkt_depth {S_PKT_DEPTH}")
    check(abs((floor - FACE_NUT) - S_PKT_DEPTH) < 0.02,
          f"depth {floor - FACE_NUT:.3f} takes a {NUT_T} nut and sinks it "
          f"{floor - FACE_NUT - NUT_T:.3f} below the face -- the donor's own "
          f"3.887 left it standing 0.113 proud")
    wall = SLOT_NUT - floor
    check(wall >= NUT_WALL,
          f"and leaves {wall:.3f} to the slot at {SLOT_NUT} -- "
          f"{wall - NUT_WALL:+.3f} on nut_wall {NUT_WALL}")

    # ---------------------------------------------------------------- 4
    print("\n[4] IS IT A TRAP?  how far a centred M5 nut turns before it binds")
    print("     (a dimension cannot answer this -- a round 8.00 hole is 8.00")
    print("      across flats too, and the nut spins in it)")
    worst = None
    for x in (FACE_NUT + 0.4, FACE_NUT + 1.5, FACE_NUT + 2.8, NUT_FLOOR - 0.15):
        t = max_turn(tris, x)
        print(f"     x={x:7.3f}   turns {t:7.3f} deg")
        if worst is None or t > worst[1]:
            worst = (x, t)
    # Predicted from the pocket we MEASURED, not from a wish: an M5 nut of
    # apothem 4.00 inside a hex of apothem `ap` binds when its corner, at
    # 4.00/cos30, reaches the wall.
    pred = 30 - math.degrees(math.acos(min(1.0, (ap/(NUT_AF/2))*math.cos(math.radians(30)))))
    print(f"     predicted from the measured {2*ap:.4f} across flats: {pred:.3f} deg")
    check(worst[1] >= 0.0,
          f"the nut goes in square at every depth (a negative reading would "
          f"mean the pocket is under 8.00 somewhere and nothing seats)")
    check(abs(worst[1] - pred) < 0.05,
          f"worst case {worst[1]:.3f} deg at x={worst[0]:.3f}, against {pred:.3f} "
          f"predicted -- measurement and geometry agree")
    check(worst[1] < 1.0,
          f"{worst[1]:.3f} deg is a TRAP: the nut cannot turn, so the screw can "
          f"be driven with a key against it")
    # CONTROL.  The head counterbore on this same part IS a round bore, so the
    # very same sweep must report it free.  If it does not, [4] is measuring
    # something other than anti-rotation and its verdict is worthless.
    #
    # It is swept with a 7.00 hex, not the 8.00 nut, and that is the point
    # arm_simple.scad makes rather than a fudge: an M5 nut is 9.2376 across
    # CORNERS, so it will not enter an 8.80 bore at any angle -- ask the sweep
    # about a nut here and it correctly answers "does not fit", which tests
    # nothing.  A 7.00 hex clears 8.80 and can therefore spin, which is the
    # behaviour the control needs to see.
    CTRL_AF = 7.00
    ctrl_turn = max_turn(tris, HD_FLOOR + 1.0, af=CTRL_AF)
    ctrl_hex = max_turn(tris, xm, af=CTRL_AF)
    print(f"     control: a {CTRL_AF} hex turns {ctrl_turn:.1f} deg in the round "
          f"head bore, {ctrl_hex:.2f} deg in this hex pocket")
    check(ctrl_turn >= 60.0,
          f"CONTROL: a hex that FITS the round head counterbore turns "
          f"{ctrl_turn:.1f} deg there == free, so the sweep can tell a trap "
          f"from a hole and the {worst[1]:.3f} above is a real reading"
          if ctrl_turn >= 60 else
          f"CONTROL: the ROUND head counterbore read {ctrl_turn:.3f} deg -- the "
          f"sweep calls a plain bore a trap, so [4] proves nothing")

    # ---------------------------------------------------------------- 5
    print("\n[5] the barrel-head counterbore")
    xh = HD_FLOOR + S_HD_DEPTH/2
    th = near_axis(tris, 0, xh)
    rr = [wall_r(th, xh, a) or 0 for a in range(0, 360, 5)]
    print(f"     at x={xh:.3f}: r {min(rr):.4f}..{max(rr):.4f}")
    check(max(rr) - min(rr) < 0.01,
          f"it is ROUND ({max(rr)-min(rr):.4f} out of round) -- a screw head "
          f"needs a seat, not anti-rotation, so a hex there would be pretence")
    check(abs(2*min(rr) - S_HD_D) < 0.02,
          f"{2*min(rr):.3f} across == hd_d {S_HD_D}, clearing a {HEAD_D} head "
          f"by {2*min(rr) - HEAD_D:.2f}")
    # The span that STARTS on the slot wall is the floor the head bears on, so
    # the floor is its far end.  (Reading its near end instead measures the
    # slot, which is the donor's number and would pass whatever we cut.)
    y, z = at(4.0, 0.0)
    sp = spans_x(tris, y, z)
    seg = [s for s in sp if abs(s[0] - SLOT_HD) < 0.02][0]
    hd_floor_m = seg[1]
    check(abs(seg[1] - HD_FLOOR) < 0.02,
          f"floor at x={seg[1]:.3f} == boss face {BK_FACE:.3f} - hd_depth "
          f"{S_HD_DEPTH}")
    check(abs((seg[1] - seg[0]) - NUT_WALL) < 0.02,
          f"which leaves exactly nut_wall {NUT_WALL} to the slot at {SLOT_HD} "
          f"-- the head bears on {seg[1] - seg[0]:.3f} mm of solid floor")
    y, z = at(6.0, 0.0)
    sp = spans_x(tris, y, z)
    seg = [s for s in sp if s[1] > FACE_HD][0]
    check(abs(seg[1] - BK_FACE) < 0.02,
          f"boss face at x={seg[1]:.3f}, so the head sits {S_HD_DEPTH - 5.00:.2f} "
          f"below flush and nothing protrudes")
    check(abs((seg[1] - FACE_HD) - BOSS_HD) < 0.02,
          f"the boss is {seg[1] - FACE_HD:.3f} thick, which is what a {5.00} tall "
          f"head plus {NUT_WALL} of floor needs beyond the donor's "
          f"{FACE_HD - SLOT_HD:.3f} of prong")

    # ---- the rim round, measured as a radius, not eyeballed ----------
    # The donor rolls its nut boss's rim off at R1.24; this matches it on the
    # head boss so the two ends of the same part agree.  Checked by finding
    # where the flat face gives out and then holding the surface beyond it to
    # the arc that should be there -- "it looks rounded" is not a measurement.
    def outer_x(r):
        iv = spans_x(tris, *at(r, 0.0))
        s = [q for q in iv if q[1] > FACE_HD + 0.05]
        return s[-1][1] if s else None

    cr, cx = KNUCKLE_R - BOSS_RIM, BK_FACE - BOSS_RIM
    # Sampled, not bisected.  Hunting for "where the face stops being flat"
    # cannot work here: the round leaves its tangent point QUADRATICALLY, so
    # x has only fallen a micron 0.05 mm out along the radius, and any
    # threshold you pick reports the tangent point 0.05 too far out.  Ask
    # instead whether the face IS flat everywhere it should be.
    flat = [outer_x(r) for r in (4.6, 5.2, 5.8, cr - 0.02)]
    check(all(v is not None and abs(v - BK_FACE) < 1e-3 for v in flat),
          f"the face is dead flat at {BK_FACE} all the way out to r={cr:.4f} == "
          f"knuckle {KNUCKLE_R} less the r{BOSS_RIM} rim, where the round starts")
    flat_r = cr
    worst_r, shown = 0.0, []
    for rq in (cr + 0.2, cr + 0.5, cr + 0.9, cr + 1.15):
        v = outer_x(rq)
        pr = cx + math.sqrt(max(0.0, BOSS_RIM**2 - (rq - cr)**2))
        shown.append(f"r={rq:.3f}->{v:.4f}")
        worst_r = max(worst_r, abs(v - pr))
    print("     rim profile: " + ", ".join(shown))
    check(worst_r < 0.01,
          f"and the surface beyond it sits on that circle to {1000*worst_r:.1f} um "
          f"-- a true quarter-round, not a chamfer")
    check(flat_r - S_HD_D/2 > 0.5,
          f"the round leaves {flat_r - S_HD_D/2:.3f} mm of flat face round the "
          f"{S_HD_D} counterbore, so it never touches the head's seat")

    # ---------------------------------------------------------------- 6
    print("\n[6] the 45 deg relief under the head")
    def hole_d(x):
        t = near_axis(tris, 0, x)
        rs = [wall_r(t, x, a) or 0 for a in (0, 60, 120, 180, 240, 300)]
        return 2*sum(rs)/len(rs)
    pts = [(x, hole_d(x)) for x in (CS_INNER - 0.20, CS_INNER + 0.10,
                                    CS_INNER + 0.25, CS_INNER + 0.40)]
    for x, d in pts:
        print(f"     x={x:.3f}  bore opens to {d:.3f}")
    mouth = hole_d(HD_FLOOR - 0.02)
    check(abs(hole_d(CS_INNER - 0.20) - D_BORE) < 0.02,
          f"inboard of the relief the bore is the donor's {D_BORE}, untouched")
    slope = ((pts[3][1] - pts[1][1])/2)/(pts[3][0] - pts[1][0])
    check(abs(slope - 1.0) < 0.05,
          f"the relief rises {slope:.3f} in radius per mm of x == 45 deg")
    check(mouth >= HEAD_DA + 0.15,
          f"at the floor the bore is opened to {mouth:.3f}, clearing a {HEAD_DA} "
          f"under-head fillet by {mouth - HEAD_DA:+.3f} -- the head seats on the "
          f"floor, not on the bore's edge")
    # Where the relief actually STARTS, bisected off the mesh rather than
    # asserted from the parameters -- it is cut INTO the wall the head bears
    # on, so how much of that wall survives is the whole question.
    a, b = SLOT_HD, HD_FLOOR
    for _ in range(40):
        m = (a + b)/2
        if hole_d(m) > D_BORE + 1e-3:
            b = m
        else:
            a = m
    start = (a + b)/2
    check(abs(start - CS_INNER) < 0.02,
          f"the relief starts at x={start:.3f} == floor {HD_FLOOR:.3f} - head_cs "
          f"{S_HEAD_CS}")
    check(start - SLOT_HD >= 1.00,
          f"and stops {start - SLOT_HD:.3f} short of the slot at {SLOT_HD}, so "
          f"{start - SLOT_HD:.3f} mm of floor wall is left behind the head "
          f"(want >= 1.00)")
    # HEAD SIDE ONLY: a nut's bearing face is flat to its thread, so the same
    # cut on the nut side would only thin the wall carrying the press fit.
    nut_mouth = hole_d(NUT_FLOOR + 0.05)
    check(abs(nut_mouth - D_BORE) < 0.03,
          f"the NUT side is left at {nut_mouth:.3f} == the donor's bore, "
          f"uncountersunk -- a nut has no fillet to clear")

    # ---------------------------------------------------------------- 7
    print("\n[7] print reality: what the boss underside has under it")
    bot = PIVOT_Y - KNUCKLE_R
    shelf = []
    for x in (FACE_HD + 0.4, (FACE_HD + BK_FACE)/2, BK_FACE - 0.2):
        t = near_axis(near_axis(tris, 0, x), 2, PIVOT_Z)
        iv = [(a-100, b-100) for a, b in ray_intervals(t, (x, -100.0, PIVOT_Z), 1)]
        below = [b for a, b in iv if b < bot - 1e-6]
        shelf.append((x, max(below) if below else None))
    for x, s in shelf:
        if s is None:
            print(f"     x={x:7.3f}: nothing under the boss at all")
        else:
            print(f"     x={x:7.3f}: donor shelf tops out at y={s:.3f}, "
                  f"boss starts at y={bot:.4f}  -> gap {bot - s:.3f}")
    gaps = [bot - s for _, s in shelf if s is not None]
    warn(gaps and max(gaps) < 1.5,
         f"the boss underside bridges at most {max(gaps):.3f} mm to the donor's "
         f"own shelf -- {max(gaps)/0.20:.0f} layers at 0.20, over a wide flat, "
         f"which is the smallest of this part's four support jobs"
         if gaps else "the boss underside has nothing beneath it to bridge to")

    # ---------------------------------------------------------------- 8
    # WHAT SCREW, worked out from the two faces rather than from memory.  The
    # file used to claim an M5x20 with "nothing protruding on either side",
    # which is wrong by 2.5 mm -- the sort of number that is only ever checked
    # when someone has the part and the screw in their hands.  So it is checked
    # here, off the mesh, in the units the shop sells.
    print("\n[8] what screw actually fits")
    nut_far = nut_floor_m - NUT_T          # the nut bears on its floor and
    full = hd_floor_m - nut_far            # stands off it toward the face
    proud = hd_floor_m - nut_face_m
    print(f"     head bears at x={hd_floor_m:.3f}, nut spans {nut_far:.3f}"
          f"..{nut_floor_m:.3f}, boss face {nut_face_m:.3f}")
    print(f"     shank for a FULL nut  >= {full:.3f}")
    print(f"     shank before it stands proud <= {proud:.3f}")
    for L in (16, 18, 20, 25):
        tip = hd_floor_m - L
        eng = min(NUT_T, max(0.0, nut_floor_m - tip))
        pr = nut_face_m - tip
        print(f"     M5x{L}: {eng:.3f}/{NUT_T} of the nut engaged, "
              + (f"stands {pr:.3f} proud" if pr > 0 else "nothing proud"))
    check(full <= proud + 1e-9,
          f"the window {full:.3f}..{proud:.3f} is the right way round -- a screw "
          f"that fills the nut can in principle still sit flush, which is what "
          f"nut_seat {S_PKT_DEPTH - NUT_T:.2f} buys")
    # Not a failure, a fact about what the shop sells: the window is only as
    # wide as nut_seat, and M5 comes in even lengths.
    warn(any(full <= L <= proud for L in (16, 18, 20, 25)),
         f"no standard M5 length lands in the {proud-full:.3f} mm window, so the "
         f"screw is a genuine either/or -- see the next line for which way")
    # M5x16 is the one to buy: it protrudes nowhere, and 2.785 mm of engagement
    # is ~3.5 turns of steel-on-steel thread.  The joint fails in the PETG round
    # the pocket long before an M5 thread strips, so full engagement buys
    # nothing here and 0.485 mm of screw sticking out of the boss face costs
    # snagging on a part whose whole job is to be clipped on and off.
    eng16 = min(NUT_T, max(0.0, nut_floor_m - (hd_floor_m - 16)))
    check(eng16 >= 2.0 and (nut_face_m - (hd_floor_m - 16)) <= 0,
          f"M5x16 engages {eng16:.3f} mm of nut and protrudes nowhere -- that is "
          f"the one to buy; an M5x18 fills the nut but stands "
          f"{nut_face_m - (hd_floor_m - 18):.3f} proud of the boss face")

    print()
    if FAIL:
        print(f"*** {len(FAIL)} FAILURE(S)")
        for m in FAIL:
            print("   -", m)
    if WARN:
        print(f"--- {len(WARN)} warning(s)")
        for m in WARN:
            print("   -", m)
    if not FAIL:
        print("ALL CHECKS PASSED")
    return 1 if FAIL else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
