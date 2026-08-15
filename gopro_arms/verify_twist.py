#!/usr/bin/env python3
"""Measure the 90 deg twist adapter against the geometry it claims.

  python3 verify_twist.py stl/gopro_90_twist.stl

Method is the house standard: measure the exported mesh by ray-casting,
predict every number from the geometry, and check the measurement against the
prediction rather than against a round number.

Four of these checks are not dimensions, and they are the ones that matter.

[2] THE TWIST.  Nothing in verify.py covers it, and it is the one thing this
    part exists to do.  Both hinge axes are FITTED off the mesh -- each bore's
    circular surface is sampled at two stations along its own axis and a
    circle is least-squares fitted to each -- and the pair is then asked the
    three questions that define a twist adapter: are they square to each
    other, how far apart are they, and does their common normal run along the
    arm.  An adapter whose twist is 89 deg is a part that looks right, passes
    every other check here, and fits nothing.

[6] THE SLOT FLOORS, one per end, measured on their own axes.  Pivot A's is a
    flat plane at pocket_r that the mating arm's FACE runs into; pivot B's is
    the same plane turned onto a vertical axis.

[8] THE ANTI-ROTATION SWEEP.  "8.00 across flats" proves nothing: a round hole
    of the same width passes it and lets the nut spin.  The pocket boundary is
    swept instead and asked how far a centred M5 nut turns before its corners
    bind -- 0 deg is a trap, 60 deg is a hole -- with the head counterbore on
    this same part as the control, because it IS a round bore and must read
    free.  Adapted from verify_buckle.py [4].

[10] is where the ORIENTATION is cashed, and on this part that cuts both ways.
    The part lies down, so the layers run the length of the arm and the whole
    underside is on the plate.  The price is that pivot B's hinge axis stands
    VERTICAL, which turns its slot into a horizontal gap with the upper finger
    hanging over it.  So the audit does not ask "is there support in a slot" --
    the answer is yes, deliberately, at pivot B.  It asks the two questions
    that are still worth something: is PIVOT A's joint still perfectly clean
    (it must measure 0.00, because its axis is horizontal and nothing about it
    changed), and is pivot B's ceiling exactly the area its own geometry owes
    and not a millimetre more.
"""
import argparse
import math
import os
import sys
from collections import defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify import (load, bbox, volume, near_axis, ray_intervals,     # noqa: E402
                    ray_hits, normal)
from verify import (U, SLOT_W, FING_W, TAB_R, BORE_D, POCKET_R,       # noqa: E402
                    PRONG_OUT_T, W3_HALF, W2_HALF, ROOT_FILLET,
                    JOINT_CLR, OH_ANG, FACET_TOL,
                    NUT_AF, NUT_T, NUT_WALL, HEAD_D,
                    S_NUT_SIDE, S_PKT_AF, S_PKT_DEPTH, S_HD_D,
                    S_HD_DEPTH, S_BOSS_NUT, S_BOSS_HD, S_BOSS_RIM,
                    S_PIVOT_Z, S_TAB_TOP, S_HEAD_CS)

TOL = 0.06

# ---- the twist's own spec (mirrors twist.scad) -----------------------
TW_L      = 35.0
PZA       = S_PIVOT_Z            # 7.500  pivot A's height; its axis runs along Y
FORK_Z    = 0.0                  # the fork's lower finger sits ON THE BED
FORK_H    = 2*W2_HALF            # 8.900  the 2-prong stack, stood upright
FORK_C    = FORK_Z + W2_HALF     # 4.450  pivot B's datum along its own axis
TW_H0     = S_TAB_TOP            # 15.000 body height at pivot A
TW_H1     = FORK_H               #  8.900 body height at pivot B
TW_CB     = 2.00                 # bottom edge chamfer, 45 deg

PKT_R     = S_PKT_AF/math.sqrt(3)                         # 4.6188
FACE_NUT  = S_NUT_SIDE*(W3_HALF + S_BOSS_NUT)             # -10.35
FACE_HD   = -S_NUT_SIDE*(W3_HALF + S_BOSS_HD)             # +11.35
FLOOR_NUT = FACE_NUT - S_NUT_SIDE*S_PKT_DEPTH             #  -6.05
FLOOR_HD  = FACE_HD + S_NUT_SIDE*S_HD_DEPTH               #  +6.05

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
# Every probe below has to say WHICH PIVOT it is about.  This is the one part
# in the project with two hinge axes at right angles, and a radius test that
# does not name its axis -- or that tests only the plane perpendicular to it --
# excuses an infinite cylinder along the other one.  That exact loophole waved
# every down-facing facet near a knuckle through on the arm; see README
# "Verifying".  So: rad_A is measured in the XZ plane, because axis A runs
# along Y, and rad_B in the XY plane, because axis B runs along Z.
def rad_A(p):
    return math.hypot(p[0], p[2] - PZA)


def rad_B(p):
    return math.hypot(p[0] - TW_L, p[1])


def spans(tris, axis, p, pad=6.0):
    """Occupied intervals along `axis` through point `p`, in world coords."""
    o = list(p)
    o[axis] = -100.0
    t = tris
    for k in range(3):
        if k != axis:
            t = near_axis(t, k, p[k], pad)
    return [(a - 100.0, b - 100.0) for a, b in ray_intervals(t, o, axis)]


def circle_fit(pts):
    """Least-squares circle through (u, v) points.  Returns (uc, vc, r, rms)."""
    n = len(pts)
    su = sum(u for u, _ in pts)
    sv = sum(v for _, v in pts)
    suu = sum(u*u for u, _ in pts)
    svv = sum(v*v for _, v in pts)
    suv = sum(u*v for u, v in pts)
    sa = sum(u*u + v*v for u, v in pts)
    sau = sum((u*u + v*v)*u for u, v in pts)
    sav = sum((u*u + v*v)*v for u, v in pts)
    m = [[suu, suv, su, -sau],
         [suv, svv, sv, -sav],
         [su,  sv,  n,  -sa]]
    for i in range(3):                       # Gaussian elimination
        p = max(range(i, 3), key=lambda r: abs(m[r][i]))
        m[i], m[p] = m[p], m[i]
        for r in range(3):
            if r != i and abs(m[i][i]) > 1e-12:
                f = m[r][i]/m[i][i]
                for c in range(i, 4):
                    m[r][c] -= f*m[i][c]
    if any(abs(m[i][i]) < 1e-12 for i in range(3)):
        return 0.0, 0.0, 0.0, float('inf')      # collinear / too few points
    d, e, f = (m[i][3]/m[i][i] for i in range(3))
    uc, vc = -d/2, -e/2
    r = math.sqrt(max(0.0, uc*uc + vc*vc - f))
    rms = math.sqrt(sum((math.hypot(u - uc, v - vc) - r)**2 for u, v in pts)/n)
    return uc, vc, r, rms


def bore_centre(tris, end, station):
    """Fit one bore's surface at one station along its own axis.

    Sampled on the side of the bore FURTHEST from the material the ray comes
    through, so the reading is a genuine surface crossing and not a grazing
    hit: pivot A from below (through the knuckle), pivot B from -Y (through
    the finger).  Returns (centre, r, rms) with the centre in world coords.
    """
    # The offsets are NUDGED off the round numbers on purpose.  Both pivots sit
    # on a plane where the body's loft starts or ends, and a loft station is a
    # 0.01 mm slab -- a ray cast at exactly x = 0 or x = L grazes a coplanar
    # face, the crossing parity flips, and ray_intervals reports the BORE as
    # solid and the material as void.  It did, and the fitted circle came back
    # as r 2.72 centred at z 2.86 with 427 um of residual, which is at least
    # loud enough to notice.  verify.py nudges by 0.013 for the same reason.
    pts = []
    for off in (-1.763, -1.163, -0.563, 0.037, 0.637, 1.237, 1.837):
        if end == 'A':                       # axis along Y at (x=0, z=PZA)
            iv = spans(tris, 2, [off, station, 0.0], pad=3.0)
            if iv:
                pts.append((off, iv[0][1]))          # bore's lower surface
        else:                                # axis along Z at (x=TW_L, y=0)
            iv = spans(tris, 1, [TW_L + off, 0.0, station], pad=3.0)
            if len(iv) >= 2:
                pts.append((off, iv[0][1]))          # bore's -Y surface
    # A probe that finds nothing has to SAY so.  This returned four points on
    # a mutant whose fork had moved, circle_fit divided by a singular pivot,
    # and the whole run died with a ZeroDivisionError after four PASSes -- so
    # the check that would have caught the mutation, [4], never ran and the
    # mutant scored zero failures.  An instrument that crashes is not a
    # verdict; the caller gets None and turns it into one.
    if len(pts) < 4:
        return None, 0.0, 0.0
    u, v, r, rms = circle_fit(pts)
    if not math.isfinite(rms):
        return None, 0.0, 0.0
    c = ([u, station, v] if end == 'A' else [TW_L + u, v, station])
    return c, r, rms


def wall_r(tsub, y, ang):
    """Radius at which material starts, looking out from pivot A's axis.

    ang = 0 is +X and ang = 90 is +Z, which is UP in the print -- the only
    frame a hex pocket's orientation ever meant anything in.
    """
    a = math.radians(ang)
    h = [q for q in ray_hits(tsub, (0.0, y, PZA), [math.cos(a), 0.0, math.sin(a)])
         if q > 1e-9]
    return h[0] if h else None


def hex_r(phi, theta, af):
    """Boundary radius of a hex of across-flats `af`, turned `theta`, at `phi`.

    The phase differs from verify_buckle.py's by 30 deg and that is not a
    tweak, it is the frame: there `phi = 0` points at one of the pocket's
    FLATS, here it points at a CORNER, because this pocket's flats are up and
    down (arm.scad: "a vertex up would put the roof at 60 deg from vertical")
    and `phi = 0` is +X.  Get it wrong and the sweep measures a nut 30 deg out
    of register with the pocket, which reads as "will not go in square" on a
    pocket that is exactly right -- it did.
    """
    d = ((phi - theta) % 60.0) - 30.0
    return (af/2)/math.cos(math.radians(d))


def max_turn(tris, y, af=NUT_AF):
    """How far a centred hex of across-flats `af` can turn at this y.

    0 deg means its corners bind the instant it moves -- a trap.  30 deg means
    it is past the worst misalignment there is, so by the hexagon's own
    symmetry it turns freely; report that as 60.
    """
    tsub = near_axis(tris, 1, y)
    cache = {}

    def pr(phi):
        key = round(phi % 360.0, 4)
        if key not in cache:
            cache[key] = wall_r(tsub, y, key) or 0.0
        return cache[key]

    def fits(th):
        phis = [th + 30.0 + 60.0*k for k in range(6)] + [2.0*k for k in range(180)]
        return all(pr(p) >= hex_r(p, th, af) - 1e-6 for p in phis)

    if not fits(0.0):
        return -1.0
    if fits(30.0):
        return 60.0
    lo, hi = 0.0, 30.0
    for _ in range(44):
        m = (lo + hi)/2
        if fits(m):
            lo = m
        else:
            hi = m
    return lo


def main():
    global TW_L
    ap = argparse.ArgumentParser()
    ap.add_argument('stl', nargs='?', default='stl/gopro_90_twist.stl')
    ap.add_argument('--length', type=float, default=TW_L)
    args = ap.parse_args()
    TW_L = args.length

    tris = load(args.stl)
    lo, hi = bbox(tris)
    print(f"\n=== {os.path.basename(args.stl)}   "
          f"{len(tris)} facets, {volume(tris):.1f} mm^3")

    # ---------------------------------------------------------------- 1
    print(f"\n[1] the envelope -- L = {TW_L}, and it lies FLAT: pivot A's axis "
          f"runs along Y,\n     pivot B's stands up along Z, and the underside "
          f"is one plane on the bed")
    print(f"     bbox  x [{lo[0]:+.3f}, {hi[0]:+.3f}]  "
          f"y [{lo[1]:+.3f}, {hi[1]:+.3f}]  z [{lo[2]:+.3f}, {hi[2]:+.3f}]")
    check(abs(lo[0] + TAB_R) < 0.05 and abs(hi[0] - (TW_L + TAB_R)) < 0.05,
          f"x spans {lo[0]:.3f}..{hi[0]:.3f} == a knuckle radius either side of "
          f"the two pivots, {TW_L} apart")
    check(abs(lo[1] - FACE_NUT) < TOL and abs(hi[1] - FACE_HD) < TOL,
          f"y spans {lo[1]:+.3f}..{hi[1]:+.3f} == the {2*W3_HALF:.2f} GoPro "
          f"stack plus {S_BOSS_NUT} of nut boss and {S_BOSS_HD} of head boss")
    check(abs(lo[2]) < 0.02 and abs(hi[2] - TW_H0) < 0.05,
          f"z spans {lo[2]:.3f}..{hi[2]:.3f}: the bed, up to pivot A's own "
          f"knuckle diameter {TW_H0} -- nothing stands taller than the joint")

    # ---------------------------------------------------------------- 2
    print("\n[2] THE TWIST -- both hinge axes fitted off the mesh")
    print("     (this is the check no other file makes, and the one failure")
    print("      mode a part can wear without looking wrong)")
    axes = {}
    for end, stations, along in (('A', (-5.0, +5.0), 'Y'),
                                 ('B', (1.45, 7.45), 'Z')):
        cs = []
        for s in stations:
            c, r, rms = bore_centre(tris, end, s)
            if c is None:
                check(False,
                      f"bore {end} is not where the geometry says it is -- a "
                      f"probe at {along}={s:+.2f} found no bore to fit, so "
                      f"nothing below can measure the twist")
                continue
            cs.append(c)
            print(f"     bore {end} at {along}={s:+5.2f}   centre "
                  f"({c[0]:+7.3f},{c[1]:+7.3f},{c[2]:+7.3f})   "
                  f"r {r:.4f}   rms {rms*1000:.0f} um")
            check(abs(2*r - BORE_D) < 0.08,
                  f"bore {end} at {along}={s:+.2f} measures {2*r:.3f} == "
                  f"{BORE_D} across")
            check(rms < 0.02,
                  f"... and is round to {rms*1000:.0f} um rms, so the fit is "
                  f"reading a bore and not something next to one")
        if len(cs) == 2:
            d = [cs[1][k] - cs[0][k] for k in range(3)]
            n = math.sqrt(sum(q*q for q in d))
            axes[end] = ([q/n for q in d], cs[0])
    # No fallback values here on purpose.  Substituting a plausible pair of
    # axes when one could not be found would let the angle and distance checks
    # below report a clean 90.0000 on a part where nothing was measured at all.
    if len(axes) < 2:
        check(False, "the twist itself is UNMEASURABLE on this mesh -- see "
                     "above; the checks that would have judged it are skipped "
                     "rather than fed a guess")
    else:
        (dA, pA), (dB, pB) = axes['A'], axes['B']
        print(f"     axis A direction ({dA[0]:+.5f},{dA[1]:+.5f},{dA[2]:+.5f})")
        print(f"     axis B direction ({dB[0]:+.5f},{dB[1]:+.5f},{dB[2]:+.5f})")
        ang = math.degrees(math.acos(min(1.0, abs(sum(dA[k]*dB[k] for k in range(3))))))
        check(abs(ang - 90.0) < 0.15,
              f"the two hinge axes are {ang:.4f} deg apart -- this is a 90 deg "
              f"twist adapter, and 89 would fit nothing")
        # The orientation argument, measured.  A is horizontal and B is vertical,
        # and that pair is exactly what lying the part down means: A's joint is an
        # arm's joint, B's pays for the layer lines.
        tiltA = math.degrees(math.asin(min(1.0, abs(dA[2]))))
        tiltB = math.degrees(math.asin(min(1.0, abs(dB[2]))))
        check(tiltA < 0.15,
              f"axis A is HORIZONTAL to {tiltA:.4f} deg -- which is what keeps its "
              f"slots vertical slices with nothing in them to support")
        check(abs(tiltB - 90.0) < 0.15,
              f"axis B is VERTICAL to {90-tiltB:.4f} deg -- deliberate, and the "
              f"reason [10] budgets a ceiling in its slot")
        cr = [dA[1]*dB[2] - dA[2]*dB[1],
              dA[2]*dB[0] - dA[0]*dB[2],
              dA[0]*dB[1] - dA[1]*dB[0]]
        cn = math.sqrt(sum(q*q for q in cr))
        cr = [q/cn for q in cr]
        dist = abs(sum((pB[k] - pA[k])*cr[k] for k in range(3)))
        check(abs(dist - TW_L) < 0.05,
              f"they are {dist:.4f} mm apart == the L = {TW_L} this was built to")
        lean = math.degrees(math.acos(min(1.0, abs(cr[0]))))
        check(lean < 0.15,
              f"their common normal is {lean:.4f} deg off the arm's own axis -- "
              f"skew but square, no dogleg and no rise in the AXES, which is what "
              f"the twist actually is")
        print(f"     pivot B's stack sits {FORK_C:.3f} up its own axis against "
              f"pivot A's {PZA:.3f}: the {PZA-FORK_C:.2f} mm step a flat-bottomed "
              f"part with a 15.0 end and an 8.9 end necessarily has")

    # ---------------------------------------------------------------- 3
    xp = -5.0
    print(f"\n[3] GoPro prong grid -- 3-prong end (pivot A), probed along its "
          f"OWN hinge axis Y at x={xp}, z={PZA:.3f}")
    iv = spans(tris, 1, [xp, 0.0, PZA])
    print("     solid spans:", ", ".join(f"[{a:+.3f},{b:+.3f}]={b-a:.3f}"
                                         for a, b in iv))
    check(len(iv) == 3, f"3-prong end has exactly 3 prongs (got {len(iv)})")
    if len(iv) == 3:
        (o1a, o1b), (mA, mB), (o2a, o2b) = iv
        s1, s2 = mA - o1b, o2a - mB
        check(abs(s1 - SLOT_W) < TOL, f"slot 1 width {s1:.3f} == {SLOT_W}")
        check(abs(s2 - SLOT_W) < TOL, f"slot 2 width {s2:.3f} == {SLOT_W}")
        check(abs((o1b + mA)/2 + U) < TOL,
              f"slot 1 centred on {-U} (got {(o1b+mA)/2:+.3f})")
        check(abs((mB + o2a)/2 - U) < TOL,
              f"slot 2 centred on {+U} (got {(mB+o2a)/2:+.3f})")
        check(abs((mB - mA) - FING_W) < TOL,
              f"middle prong {mB-mA:.3f} == {FING_W}")
        check(abs((o1b - o1a) - (PRONG_OUT_T + S_BOSS_NUT)) < TOL,
              f"-Y outer prong {o1b-o1a:.3f} == {PRONG_OUT_T}+{S_BOSS_NUT} boss")
        check(abs((o2b - o2a) - (PRONG_OUT_T + S_BOSS_HD)) < TOL,
              f"+Y outer prong {o2b-o2a:.3f} == {PRONG_OUT_T}+{S_BOSS_HD} boss")
        check(s1 >= U and s2 >= U, "a 3.00 mm GoPro finger enters both slots")
        warn(s1 - U <= 0.35 and s2 - U <= 0.35,
             f"slot slop on a 3.00 finger is {s1-U:.2f}/{s2-U:.2f} mm")

    yq = 5.0
    print(f"\n[4] GoPro prong grid -- the FORK (pivot B), probed along its OWN "
          f"hinge axis Z at x={TW_L}, y={yq}")
    iv = spans(tris, 2, [TW_L, yq, 0.0])
    print("     solid spans:", ", ".join(f"[{a:+.3f},{b:+.3f}]={b-a:.3f}"
                                         for a, b in iv))
    check(len(iv) == 2, f"the fork has exactly 2 fingers (got {len(iv)})")
    if len(iv) == 2:
        (f1a, f1b), (f2a, f2b) = iv
        check(abs((f1b - f1a) - FING_W) < TOL, f"finger 1 {f1b-f1a:.3f} == {FING_W}")
        check(abs((f2b - f2a) - FING_W) < TOL, f"finger 2 {f2b-f2a:.3f} == {FING_W}")
        check(abs((f2a - f1b) - SLOT_W) < TOL,
              f"central gap {f2a-f1b:.3f} == {SLOT_W}")
        check(abs(f1a - FORK_Z) < 0.02,
              f"the lower finger's underside is at z={f1a:.3f} -- ON THE BED, "
              f"which is what makes this part's bottom one flat plane")
        check(abs((f1a + f2b)/2 - FORK_C) < TOL,
              f"the stack is centred on {FORK_C} up its own axis")
        check(f1b - f1a <= U and f2b - f2a <= U,
              "both fingers enter a 3.00 mm GoPro slot")
        check(f2a - f1b >= U, "central gap accepts a 3.00 mm middle prong")

    # ---------------------------------------------------------------- 5
    print("\n[5] the pivot bores")
    iv = spans(tris, 2, [0.037, 0.0, 0.0], pad=3.0)
    gaps = [(iv[i][1], iv[i+1][0]) for i in range(len(iv)-1)]
    g = [q for q in gaps if q[0] < PZA < q[1]]
    check(len(g) == 1, "bore A shows as one gap on a vertical ray")
    if g:
        below, above = PZA - g[0][0], g[0][1] - PZA
        print(f"     bore A: {below:.3f} below the pivot, {above:.3f} above")
        check(abs(below - BORE_D/2) < 0.05 and abs(above - BORE_D/2) < 0.05,
              f"bore A is ROUND -- {below:.3f} below and {above:.3f} above the "
              f"pivot, not a teardrop.  A teardrop only earns its keep pointing "
              f"UP, and this bore now runs across the part like an arm's; "
              f"round buys back 1.10 mm of crown, as arm_simple.scad argues")
    iv = spans(tris, 1, [TW_L, 0.0, FORK_C - SLOT_W/2 - 0.6], pad=3.0)
    check(len(iv) == 2 and abs((iv[1][0] - iv[0][1]) - BORE_D) < 0.06,
          f"bore B is {iv[1][0]-iv[0][1]:.3f} across == {BORE_D}, and being "
          f"VERTICAL it has no roof at all -- nothing to support inside it")

    # ---------------------------------------------------------------- 6
    print("\n[6] the slot floors -- one per end, each on its own axis")
    print("     pivot A: FLAT at pocket_r, the simple arm's floor, unchanged")
    hface = min(PZA, TW_H0 - PZA)
    worst = 0.0
    for z in (PZA - hface + 0.30, PZA - hface/2, PZA, PZA + hface/2,
              PZA + hface - 0.30):
        # Walked INBOARD, +x, toward the body: that is where the floor is.
        # Outboard the slot simply runs off the end of the knuckle and stays
        # open forever, so a probe walking that way measures the loop limit and
        # calls it a slot depth -- it did, and read 19.963.
        reach, shut = 0.0, 0
        for i in range(1, 400):
            xx = i*0.05 + 0.013
            band = [(a, b) for a, b in
                    spans(tris, 1, [xx, 0.0, z], pad=1.0) if a < U < b]
            if not band:
                reach = xx
            else:
                shut += 1
                if shut >= 3:
                    break
        worst = max(worst, abs(reach - POCKET_R))
        print(f"     z={z:6.2f}   slot runs to x={reach:6.3f}  "
              f"(a flat floor owes {POCKET_R})")
    check(worst < 0.20,
          f"pivot A's slot floor is FLAT to {worst:.3f} mm over the part's "
          f"full height -- no gable: standing on end its floors faced DOWN and "
          f"had to be ridged, lying down they are plain vertical planes")
    prof = []
    for dy in (-4.0, -2.0, 0.0, 2.0, 4.0):
        iv = spans(tris, 0, [0.0, dy, FORK_C], pad=1.0)
        seg = [b for a, b in iv if a < TW_L - POCKET_R - 1.0]
        if seg:
            prof.append((dy, max(seg)))
    for dy, x in prof:
        print(f"     pivot B, y={dy:+5.1f}   slot floor at x={x:7.3f} "
              f"(owes {TW_L - POCKET_R:.3f})")
    check(prof and max(abs(x - (TW_L - POCKET_R)) for _, x in prof) < 0.05,
          f"pivot B's floor is the same flat plane at pocket_r from its own "
          f"axis, {TW_L-POCKET_R:.3f} -- turned onto a vertical axis, nothing "
          f"else about it changed")
    check(prof and max(x for _, x in prof) - min(x for _, x in prof) < 0.02,
          f"and it is flat across the slot to "
          f"{max(x for _, x in prof)-min(x for _, x in prof):.3f} mm")
    fold = 2*math.degrees(math.atan2(POCKET_R, TAB_R))
    print(f"     pivot A folds to {fold:.1f} deg, {180-fold:.1f} between two "
          f"of them -- the body is {2*TAB_R} across at that pivot and the slot "
          f"reaches {POCKET_R}, which is the simple arm's flat-floor number")

    # ---------------------------------------------------------------- 7
    print("\n[7] the screw pockets, probed along Y at a radius that clears "
          "both the bore\n     and the countersink cone")
    xq = 3.4          # > (BORE_D/2 + HEAD_CS) = 3.15, < the hex apothem 4.00
    iv = spans(tris, 1, [xq, 0.0, PZA])
    print("     solid spans:", ", ".join(f"[{a:+.3f},{b:+.3f}]={b-a:.3f}"
                                         for a, b in iv))
    check(len(iv) == 3, f"three prongs and two pocket voids (got {len(iv)})")
    if len(iv) == 3:
        nut_floor = iv[0][0] if S_NUT_SIDE < 0 else iv[2][1]
        hd_floor = iv[2][1] if S_NUT_SIDE < 0 else iv[0][0]
        check(abs(nut_floor - FLOOR_NUT) < TOL,
              f"nut pocket floor at y={nut_floor:+.3f} == face {FACE_NUT} + "
              f"{S_PKT_DEPTH} deep")
        check(abs(hd_floor - FLOOR_HD) < TOL,
              f"head counterbore floor at y={hd_floor:+.3f} == face {FACE_HD} "
              f"- {S_HD_DEPTH} deep")
        check(abs(abs(nut_floor - FACE_NUT) - S_PKT_DEPTH) < TOL,
              f"nut pocket is {abs(nut_floor-FACE_NUT):.3f} deep: takes a "
              f"{NUT_T} nut and sinks it {abs(nut_floor-FACE_NUT)-NUT_T:.2f} "
              f"below the face")
        check(abs(abs(hd_floor - FACE_HD) - S_HD_DEPTH) < TOL,
              f"head counterbore is {abs(hd_floor-FACE_HD):.3f} deep: takes a "
              f"{HEAD_D} x 5.00 cap head flush")
        wall_n = abs(abs(nut_floor) - (U + SLOT_W/2))
        check(wall_n >= NUT_WALL - 0.02,
              f"and leaves {wall_n:.3f} mm to the slot behind it "
              f"({wall_n-NUT_WALL:+.3f} on nut_wall {NUT_WALL})")

    ym = (FACE_NUT + FLOOR_NUT)/2          # mid-depth of the nut pocket
    tsub = near_axis(tris, 1, ym)
    up = wall_r(tsub, ym, 90.0)
    side = wall_r(tsub, ym, 0.0)
    check(abs(up - S_PKT_AF/2) < 0.02 and abs(side - PKT_R) < 0.02,
          f"FLATS UP: the pocket wall is {up:.4f} straight up (the apothem) "
          f"and {side:.4f} along the arm (a corner) -- a vertex up would put "
          f"this roof at 60 deg from vertical, which is arm.scad's own "
          f"parenthesis and is why the hex did not move when the part lay down")
    check(TAB_R - PKT_R > 1.50,
          f"the knuckle is a full circle, so every wall round the hex is "
          f"tab_r minus its own reach: {TAB_R-PKT_R:.3f} at the corners, "
          f"{TAB_R-S_PKT_AF/2:.3f} at the flats")

    print("\n[8] IS IT A TRAP?  how far a centred M5 nut turns before it binds")
    print("     (a dimension cannot answer this -- a round 8.00 hole is 8.00")
    print("      across flats too, and the nut spins in it)")
    worst_t = None
    for y in (FACE_NUT + 0.4, FACE_NUT + 1.5, FACE_NUT + 2.8, FLOOR_NUT - 0.15):
        t = max_turn(tris, y)
        print(f"     y={y:7.3f}   turns {t:7.3f} deg")
        if worst_t is None or t > worst_t[1]:
            worst_t = (y, t)
    pred = 30 - math.degrees(math.acos(min(
        1.0, (up/(NUT_AF/2))*math.cos(math.radians(30)))))
    print(f"     predicted from the measured {2*up:.4f} across flats: "
          f"{pred:.3f} deg")
    check(worst_t[1] >= 0.0,
          "the nut goes in square at every depth (a negative reading would "
          "mean the pocket is under 8.00 somewhere and nothing seats)")
    check(abs(worst_t[1] - pred) < 0.05,
          f"worst case {worst_t[1]:.3f} deg at y={worst_t[0]:.3f}, against "
          f"{pred:.3f} predicted -- measurement and geometry agree")
    check(worst_t[1] < 1.0,
          f"{worst_t[1]:.3f} deg is a TRAP: the nut cannot turn, so the screw "
          f"can be driven with a key against it")
    CTRL_AF = 7.00
    ctrl = max_turn(tris, FLOOR_HD + 1.0, af=CTRL_AF)
    check(ctrl >= 60.0,
          f"CONTROL: a {CTRL_AF} hex turns {ctrl:.1f} deg in the ROUND head "
          f"counterbore on this same part == free, so the sweep can tell a "
          f"trap from a hole and the {worst_t[1]:.3f} above is a real reading")

    print("\n[9] the screw -- measured between the faces above, not assumed")
    for L_scr in (16.0, 20.0):
        tip = FLOOR_HD - L_scr
        print(f"     M5x{L_scr:.0f}: head seats at y={FLOOR_HD:+.2f}, tip at "
              f"y={tip:+.2f}, {FLOOR_NUT-tip:.2f} of the nut's {NUT_T} "
              f"engaged, {tip-FACE_NUT:+.2f} to the outer face")
    tip16 = FLOOR_HD - 16.0
    check(FLOOR_NUT - tip16 >= 3.5,
          f"an M5x16 engages {FLOOR_NUT-tip16:.2f} of the nut's {NUT_T} mm")
    check(tip16 > FACE_NUT,
          f"... and its tip stops {tip16-FACE_NUT:.2f} mm inside the pocket, "
          f"so nothing protrudes")
    check((FLOOR_HD - 20.0) < FACE_NUT,
          f"an M5x20 would stand {FACE_NUT-(FLOOR_HD-20.0):.2f} mm proud of "
          f"the nut face -- checked rather than assumed, which is the mistake "
          f"verify_buckle.py [8] exists for")

    # ---------------------------------------------------------------- 10
    print(f"\n[10] printability -- overhangs steeper than {OH_ANG} deg from "
          f"vertical")
    lim = math.sin(math.radians(OH_ANG + FACET_TOL))
    flank_top = PZA - TAB_R*math.cos(math.radians(OH_ANG))       # 2.197
    nut_lo, nut_hi = sorted((FACE_NUT, FLOOR_NUT))
    hd_lo, hd_hi = sorted((FACE_HD, FLOOR_HD))
    cs_lo, cs_hi = sorted((FLOOR_HD, FLOOR_HD - S_NUT_SIDE*S_HEAD_CS))
    rim_n = sorted((FACE_NUT, FACE_NUT - S_NUT_SIDE*S_BOSS_RIM))
    rim_h = sorted((FACE_HD, FACE_HD + S_NUT_SIDE*S_BOSS_RIM))
    z_ceil = FORK_C + SLOT_W/2
    area = defaultdict(float)
    bad_pts = []
    for t in tris:
        n, a = normal(t)
        if n is None or n[2] >= -1e-6:
            continue
        cen = [sum(p[k] for p in t)/3 for k in range(3)]
        if max(p[2] for p in t) < 1e-4:
            area['bed'] += a
            continue
        ra, rb = rad_A(cen), rad_B(cen)
        # PIVOT A's SLOTS.  Its axis is horizontal, so these are vertical
        # slices and there must be nothing here at all.  Keyed on the slot's
        # own Y band AND on the radius about axis A -- the band alone runs the
        # length of the part and would swallow the fork's ceiling.
        in_slotA = (abs(abs(cen[1]) - U) <= SLOT_W/2 + 0.05
                    and ra <= POCKET_R + 0.15)
        # PIVOT B's SLOT CEILING: one plane, at the top of the fork's gap,
        # from its floor outward.  This is the bill for lying the part down.
        # The band reaches root_fillet BELOW that plane on purpose -- the
        # fillet where the floor meets the finger face is part of the same
        # ceiling and rolls off it, and splitting one surface between two
        # classes makes both their predictions meaningless (README, Verifying).
        in_fork = (z_ceil - ROOT_FILLET - 0.05 <= cen[2] <= z_ceil + 0.05
                   and cen[0] >= TW_L - POCKET_R - 0.20)
        # The boss RIM, before the flank it starts tangent to -- the round
        # begins AT the full knuckle radius, so in the other order the same
        # surface would be split between two classes and both predictions
        # would become meaningless.
        in_rim = (S_BOSS_RIM > 0
                  and (rim_n[0] - 0.05 <= cen[1] <= rim_n[1] + 0.05
                       or rim_h[0] - 0.05 <= cen[1] <= rim_h[1] + 0.05)
                  and TAB_R - S_BOSS_RIM - 0.20 <= ra <= TAB_R + 0.15)
        in_flank = (not in_rim and cen[2] < flank_top + 0.05
                    and abs(ra - TAB_R) <= 0.20)
        in_pkt_nut = (nut_lo - 0.05 <= cen[1] <= nut_hi + 0.05
                      and ra <= PKT_R + 0.15)
        in_pkt_hd = (hd_lo - 0.05 <= cen[1] <= hd_hi + 0.05
                     and ra <= S_HD_D/2 + 0.15)
        in_cs = (cs_lo - 0.05 <= cen[1] <= cs_hi + 0.05
                 and ra <= BORE_D/2 + S_HEAD_CS + 0.15)
        in_bore = ra <= BORE_D/2 + 0.15 and abs(cen[1]) <= W3_HALF + S_BOSS_HD
        cls = ('slotA' if in_slotA else 'fork_ceiling' if in_fork
               else 'rim' if in_rim else 'flank' if in_flank
               else 'pkt_nut' if in_pkt_nut else 'pkt_head' if in_pkt_hd
               else 'countersink' if in_cs else 'bore_A' if in_bore else None)
        if -n[2] <= lim:
            continue
        if cls is None:
            area['UNCLASSIFIED'] += a
            bad_pts.append((cen, math.degrees(math.asin(min(1, -n[2]))), a))
        else:
            area[cls] += a
    for k in ('bed', 'flank', 'rim', 'pkt_nut', 'pkt_head', 'countersink',
              'bore_A', 'fork_ceiling', 'slotA', 'UNCLASSIFIED'):
        print(f"     {k:14s} {area[k]:8.2f} mm^2")
    # THE headline, and it is now two claims rather than one.
    check(area['slotA'] < 0.01,
          f"PIVOT A's SLOTS MEASURE {area['slotA']:.3f} mm^2 -- its axis is "
          f"horizontal, so that joint is exactly an arm's and there is nothing "
          f"in it for auto-support to grab")
    check(area['UNCLASSIFIED'] < 0.5,
          f"no unsupported overhang outside the named classes "
          f"({area['UNCLASSIFIED']:.3f} mm^2)")
    if area['UNCLASSIFIED'] >= 0.5:
        for cen, an, a in sorted(bad_pts, key=lambda z: -z[2])[:8]:
            print(f"       at ({cen[0]:+.2f},{cen[1]:+.2f},{cen[2]:+.2f})  "
                  f"{an:.1f} deg  {a:.3f} mm^2")
    # Pivot B's ceiling, held to what its own plan area owes: the fork's disc
    # plus the body between the slot floor and the disc, less the bore.
    # Integrated rather than guessed, because the two overlap.
    n_s, fork_exp = 2000, 0.0
    x0, x1 = TW_L - POCKET_R, TW_L + TAB_R
    dx = (x1 - x0)/n_s
    for i in range(n_s):
        xx = x0 + (i + 0.5)*dx
        hw_body = (TW_L - xx)/(TW_L - 0.0)*0.0 + W2_HALF*0 + TAB_R   # 7.5 flat
        hw = 0.0
        if xx <= TW_L:
            hw = max(hw, hw_body)
        if abs(xx - TW_L) <= TAB_R:
            hw = max(hw, math.sqrt(max(0.0, TAB_R**2 - (xx - TW_L)**2)))
        fork_exp += 2*hw*dx
    fork_exp -= math.pi*(BORE_D/2)**2
    check(0.85*fork_exp <= area['fork_ceiling'] <= 1.15*fork_exp,
          f"pivot B's slot ceiling is {area['fork_ceiling']:.1f} mm^2 against "
          f"the {fork_exp:.1f} its own plan area owes (+/-15%) -- the price of "
          f"lying the part down, and priced, not waved through")
    print(f"     -> that ceiling is a {SLOT_W} mm wafer lying on the LOWER "
          f"finger, open all round: dig it out before the joint goes together")
    # The knuckle flank, and the rim, exactly as the simple arm predicts them.
    rim_exp = 0.0
    nA = 240
    dA_ = (math.pi/2)/nA
    dT = 2*math.pi/(4*nA)
    for i in range(nA):
        aa = (i + 0.5)*dA_
        rad = TAB_R - S_BOSS_RIM*(1 - math.cos(aa))
        for j in range(4*nA):
            th = (j + 0.5)*dT
            if -math.cos(aa)*math.sin(th) > lim:
                rim_exp += rad*dT*S_BOSS_RIM*dA_
    rim_exp *= 2
    check(0.75*rim_exp <= area['rim'] <= 1.25*rim_exp,
          f"boss rim overhang {area['rim']:.1f} mm^2 is the {rim_exp:.1f} an "
          f"r{S_BOSS_RIM} round on 2 bosses owes (+/-25%) -- present, and no "
          f"bigger than the rim it is supposed to be")
    # The knuckle underside.  Only the OUTBOARD half of the stack is exposed
    # -- the inboard half sits inside the body's own prism, which is the first
    # thing lying down buys back -- but both halves of each boss are, because
    # the bosses stand proud of the body in Y.
    arc = TAB_R*math.radians(OH_ANG)
    stack_w = 2*U + FING_W + 2*PRONG_OUT_T - 2*SLOT_W
    boss_w = S_BOSS_NUT + S_BOSS_HD - 2*S_BOSS_RIM
    flank_exp = arc*stack_w + 2*arc*boss_w
    check(0.75*flank_exp <= area['flank'] <= 1.25*flank_exp,
          f"knuckle-flank overhang {area['flank']:.1f} mm^2 is the "
          f"{flank_exp:.1f} owed by a {OH_ANG:.0f} deg arc over the outboard "
          f"half of the stack plus both halves of the bosses (+/-25%)")
    # Pivot A's bore is round, so its top ~90 deg is a ceiling -- but only
    # where it is a BORE: inside either pocket the pocket is the wider hole,
    # and inside either slot there is no material at all.
    bore_exp = (BORE_D/2)*math.radians(2*OH_ANG)*(abs(FLOOR_HD - FLOOR_NUT)
                                                  - 2*SLOT_W)
    check(0.75*bore_exp <= area['bore_A'] <= 1.25*bore_exp,
          f"pivot A's bore roof is {area['bore_A']:.1f} mm^2 == the "
          f"{bore_exp:.1f} a round {BORE_D} bore owes over the "
          f"{abs(FLOOR_HD-FLOOR_NUT)-2*SLOT_W:.1f} mm of material between the "
          f"two pocket floors -- support inside a 5.30 hole, as arm_simple.scad "
          f"accepts and for the same reason")
    pkt_exp = PKT_R*S_PKT_DEPTH
    check(0.75*pkt_exp <= area['pkt_nut'] <= 1.25*pkt_exp,
          f"the nut pocket's roof is {area['pkt_nut']:.1f} mm^2 == the "
          f"{pkt_exp:.1f} of a flat pkt_r-wide ceiling {S_PKT_DEPTH} deep")
    hd_exp = (S_HD_D/2)*math.radians(2*OH_ANG)*S_HD_DEPTH
    check(0.75*hd_exp <= area['pkt_head'] <= 1.25*hd_exp,
          f"the head counterbore's roof is {area['pkt_head']:.1f} mm^2 == the "
          f"{hd_exp:.1f} a round {S_HD_D} bore {S_HD_DEPTH} deep owes")

    # ---------------------------------------------------------------- 11
    print("\n[11] what it stands on")
    print(f"     bed contact {area['bed']:.1f} mm^2 -- the underside is one "
          f"plane: the body, the fork's lower finger, and nothing balanced")
    check(area['bed'] > 3.0*(hi[0] - lo[0]),
          f"{area['bed']:.1f} mm^2 over {hi[0]-lo[0]:.1f} mm of length is "
          f"{area['bed']/(hi[0]-lo[0]):.1f} mm^2 per mm -- enough to hold it "
          f"down without a brim, which the standing orientation was not")
    warn(area['fork_ceiling'] > 0.0,
         f"pivot B's slot carries {area['fork_ceiling']:.1f} mm^2 of support "
         f"BY DESIGN -- it is the price of layer lines that run the length of "
         f"the arm, and it has to come out before the joint will close")

    print()
    if FAIL:
        print(f"{len(FAIL)} CHECK(S) FAILED")
        return 1
    print(f"ALL CHECKS PASSED{f'  ({len(WARN)} warning(s))' if WARN else ''}")
    return 0


if __name__ == '__main__':
    sys.exit(main())
