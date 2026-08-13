#!/usr/bin/env python3
"""Measure a rendered arm STL against the GoPro interface + printability spec.

Everything here is measured off the exported mesh, not read back out of the
OpenSCAD source, so it catches modelling mistakes as well as parameter typos.

Usage:  python3 verify.py <arm.stl> --length 100
        python3 verify.py <gauge.stl> --length 21   (gauge Lg = 2*tab_r + 6)
        python3 verify.py <simple.stl> --length 100 --simple

--simple switches the expectations to arm_simple.scad: a slab body instead of
a strut, and a screw pocket in BOTH outer prongs instead of a nut trap in one.
Everything about the GoPro interface itself is checked identically either way,
because it IS identical -- that is the point of the variant.
"""
import argparse
import math
import struct
import sys
from collections import defaultdict

# ---- spec (must mirror arm.scad) -------------------------------------
U           = 3.00
SLOT_W      = 3.10     # u + slot_extra
FING_W      = 2.90     # u - fing_under
TAB_R       = 7.50
BORE_D      = 5.30
PRONG_OUT_T = 3.40
JOINT_CLR   = 0.25
ROOT_FILLET = 0.80
PRONG_FREE  = 2.50     # extra slot depth past the mating knuckle, for flex
POCKET_R    = TAB_R + JOINT_CLR + ROOT_FILLET + PRONG_FREE
OH_ANG      = 45.0
FACET_TOL   = 1.5      # deg -- the knuckle flank IS 45 deg, so faceting of the
                       # circle puts individual triangles a fraction over it
BEAM_T      = 10.0
BEAM_C      = 20.0
BASE_W      = 5.0
W3_HALF     = U + SLOT_W/2 + PRONG_OUT_T   # 7.95
W2_HALF     = U + FING_W/2                 # 4.45
# captive M5 nut in the -Y outer prong of the 3-prong end
NUT_AF      = 8.00
NUT_AF_CLR  = 0.20
NUT_T       = 4.00
NUT_SEAT    = 0.30
NUT_WALL    = 1.50
NUT_DEPTH   = NUT_T + NUT_SEAT             # 4.30
BOSS_H      = max(0.0, NUT_DEPTH + NUT_WALL - PRONG_OUT_T)   # 2.40
# knuckle style "trim": the circle is cut by the bed at R/sqrt(2), which is the
# deepest the pivot can sit while the flanks still leave the bed at 45 deg.
PIVOT_Z     = TAB_R/math.sqrt(2)           # 5.303
TAB_TOP     = PIVOT_Z + TAB_R              # 12.803
# An M5 nut's own circumradius.  This is the number that decides whether a
# pocket is a nut TRAP or just a hole the nut spins in.
NUT_CORNER  = NUT_AF/math.sqrt(3)          # 4.619

# ---- the SIMPLE variant (arm_simple.scad) ----------------------------
# Its pocket is a PRESS FIT on the nut, not a seat for a screw head.  An M5
# barrel head is 8.50 across -- wider than the nut's 8.00 flats -- so one
# pocket cannot do both, and sized for the head the nut rattles.
HEAD_D      = 8.50     # M5 DIN 912 socket cap head, across
HEAD_H      = 5.00     # ... and tall
HEAD_CLR    = 0.30
HEAD_SEAT   = 0.30
S_PKT_AF    = 8.00                                             # == NUT_AF
S_PKT_DEPTH = NUT_T + NUT_SEAT                                 # 4.30
S_BOSS_H    = max(0.0, S_PKT_DEPTH + NUT_WALL - PRONG_OUT_T)   # 2.40 per side
SB_H        = TAB_TOP          # body height == knuckle height, so no chord ramp
SB_T        = 2*W2_HALF        # 8.90 -- body width == the 2-prong stack
SB_CHAM     = 1.50             # 45 deg bottom chamfer
SB_RT       = 2.50             # top edge rounding

# ---- mode-dependent spec, filled in by configure() --------------------
BOSS_M      = BOSS_H     # local thickening of the -Y outer prong
BOSS_P      = 0.0        # ... and the +Y one
PKT_AF      = NUT_AF + NUT_AF_CLR
PKT_R       = PKT_AF/math.sqrt(3)
PKT_DEPTH   = NUT_DEPTH
PKT_SIDES   = (-1,)
PKT_HEAD_D  = None       # the screw head the pocket must also swallow
PKT_PEAK    = True       # 45 deg self-bridging roof over the top flat
PKT_PRESS   = False      # press fit on the nut rather than a clearance fit
SECTION     = 'strut'
XPROBE      = 5.0        # X to probe the 3-prong grid along Y


def configure(simple):
    """Point the spec at one variant or the other.

    Only the body section and the screw pockets move; every GoPro interface
    number stays exactly where it is, which is what makes the two variants
    interchangeable in a chain.
    """
    global BOSS_M, BOSS_P, PKT_AF, PKT_R, PKT_DEPTH, PKT_SIDES
    global PKT_HEAD_D, PKT_PEAK, PKT_PRESS, SECTION, XPROBE
    if not simple:
        return
    BOSS_M = BOSS_P = S_BOSS_H
    PKT_AF = S_PKT_AF
    PKT_R = PKT_AF/math.sqrt(3)
    PKT_DEPTH = S_PKT_DEPTH
    PKT_SIDES = (-1, +1)
    PKT_HEAD_D = None        # 8.50 head vs 8.00 flats: it cannot recess
    PKT_PEAK = False         # flat roof, printed with support
    PKT_PRESS = True
    SECTION = 'slab'
    # The grid probe has to clear the pocket's across-corners radius (4.619
    # here).  Land it inside the pocket and the 1.50 mm floor wall reads as
    # the whole outer prong.
    XPROBE = 6.0


TOL = 0.05     # mm, mesh/faceting tolerance
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


# ---- mesh ------------------------------------------------------------
def load(path):
    with open(path, 'rb') as f:
        head = f.read(84)
        if head[:5] == b'solid':
            f.seek(0)
            tris = []
            vs = []
            for line in f:
                s = line.split()
                if s and s[0] == b'vertex':
                    vs.append(tuple(float(x) for x in s[1:4]))
                    if len(vs) == 3:
                        tris.append(tuple(vs))
                        vs = []
            return tris
        n = struct.unpack('<I', head[80:84])[0]
        data = f.read()
    tris = []
    for i in range(n):
        v = struct.unpack('<12f', data[i*50:i*50+48])
        tris.append((v[3:6], v[6:9], v[9:12]))
    return tris


def near_axis(tris, axis, val, pad=0.0):
    """Triangles whose extent along `axis` contains `val` -- ray prefilter."""
    out = []
    for t in tris:
        lo = min(p[axis] for p in t)
        hi = max(p[axis] for p in t)
        if lo - pad <= val <= hi + pad:
            out.append(t)
    return out


def normal(t):
    a, b, c = t
    u = [b[k]-a[k] for k in range(3)]
    w = [c[k]-a[k] for k in range(3)]
    cr = [u[1]*w[2]-u[2]*w[1], u[2]*w[0]-u[0]*w[2], u[0]*w[1]-u[1]*w[0]]
    m = math.sqrt(sum(x*x for x in cr))
    if m < 1e-12:
        return None, 0.0
    return [x/m for x in cr], 0.5*m


def bbox(tris):
    lo = [1e9]*3
    hi = [-1e9]*3
    for t in tris:
        for p in t:
            for k in range(3):
                lo[k] = min(lo[k], p[k])
                hi[k] = max(hi[k], p[k])
    return lo, hi


def volume(tris):
    """Signed volume via the divergence theorem."""
    v = 0.0
    for a, b, c in tris:
        v += (a[0]*(b[1]*c[2]-b[2]*c[1])
              - a[1]*(b[0]*c[2]-b[2]*c[0])
              + a[2]*(b[0]*c[1]-b[1]*c[0]))
    return abs(v)/6.0


# ---- ray casting -----------------------------------------------------
def ray_hits(tris, origin, d):
    """Sorted, deduped surface crossings along direction `d` from `origin`."""
    hits = []
    for a, b, c in tris:
        e1 = [b[k]-a[k] for k in range(3)]
        e2 = [c[k]-a[k] for k in range(3)]
        h = [d[1]*e2[2]-d[2]*e2[1], d[2]*e2[0]-d[0]*e2[2], d[0]*e2[1]-d[1]*e2[0]]
        det = sum(e1[k]*h[k] for k in range(3))
        if abs(det) < 1e-12:
            continue
        inv = 1.0/det
        s = [origin[k]-a[k] for k in range(3)]
        u = inv*sum(s[k]*h[k] for k in range(3))
        if u < -1e-9 or u > 1+1e-9:
            continue
        q = [s[1]*e1[2]-s[2]*e1[1], s[2]*e1[0]-s[0]*e1[2], s[0]*e1[1]-s[1]*e1[0]]
        v = inv*sum(d[k]*q[k] for k in range(3))
        if v < -1e-9 or u+v > 1+1e-9:
            continue
        t = inv*sum(e2[k]*q[k] for k in range(3))
        hits.append(t)
    hits.sort()
    # dedupe coincident hits (shared edges)
    ded = []
    for h in hits:
        if not ded or abs(h-ded[-1]) > 1e-6:
            ded.append(h)
    return ded


def ray_intervals(tris, origin, axis):
    """Occupied intervals along `axis` through `origin` (Moller-Trumbore)."""
    d = [0.0, 0.0, 0.0]
    d[axis] = 1.0
    ded = ray_hits(tris, origin, d)
    return [(ded[i], ded[i+1]) for i in range(0, len(ded)-1, 2)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('stl')
    ap.add_argument('--length', type=float, required=True)
    ap.add_argument('--gauge', action='store_true')
    ap.add_argument('--simple', action='store_true',
                    help='expect arm_simple.scad: slab body, pocket both sides')
    args = ap.parse_args()
    configure(args.simple)
    L = args.length

    tris = load(args.stl)
    lo, hi = bbox(tris)
    print(f"\n=== {args.stl}  ({len(tris)} facets)")
    print(f"bbox  X {lo[0]:8.3f} .. {hi[0]:8.3f}   ({hi[0]-lo[0]:.3f})")
    print(f"      Y {lo[1]:8.3f} .. {hi[1]:8.3f}   ({hi[1]-lo[1]:.3f})")
    print(f"      Z {lo[2]:8.3f} .. {hi[2]:8.3f}   ({hi[2]-lo[2]:.3f})")
    print(f"volume {volume(tris):.1f} mm^3")

    # ---------------------------------------------------------------- 1
    # The probe X sits inside the R7.5 knuckle but outboard of both the 2.65
    # bore radius and the pocket's across-corners radius, so the ray sees
    # nothing but prongs.  Land it inside the pocket and the 1.50 mm floor
    # wall reads as the whole outer prong -- see configure().
    XP = XPROBE
    print(f"\n[1] GoPro prong grid -- 3-prong end, probed along Y at x={XP}, z={PIVOT_Z:.3f}")
    tA = near_axis(tris, 0, XP)
    iv = ray_intervals(tA, (XP, -50.0, PIVOT_Z), 1)
    iv = [(a-50, b-50) for a, b in iv]
    print("     solid spans:", ", ".join(f"[{a:+.3f},{b:+.3f}]={b-a:.3f}" for a, b in iv))
    check(len(iv) == 3, f"3-prong end has exactly 3 prongs (got {len(iv)})")
    if len(iv) == 3:
        (o1a, o1b), (mA, mB), (o2a, o2b) = iv
        slot1 = mA - o1b
        slot2 = o2a - mB
        check(abs(slot1-SLOT_W) < TOL, f"slot 1 width {slot1:.3f} == {SLOT_W}")
        check(abs(slot2-SLOT_W) < TOL, f"slot 2 width {slot2:.3f} == {SLOT_W}")
        check(abs((o1b+mA)/2 + U) < TOL, f"slot 1 centred on {-U} (got {(o1b+mA)/2:+.3f})")
        check(abs((mB+o2a)/2 - U) < TOL, f"slot 2 centred on {+U} (got {(mB+o2a)/2:+.3f})")
        check(abs((mB-mA)-FING_W) < TOL, f"middle prong {mB-mA:.3f} == {FING_W} (enters a 3.00 slot)")
        check(abs((o1b-o1a)-(PRONG_OUT_T+BOSS_M)) < TOL,
              f"-Y outer prong {o1b-o1a:.3f} == {PRONG_OUT_T}+{BOSS_M} boss")
        check(abs((o2b-o2a)-(PRONG_OUT_T+BOSS_P)) < TOL,
              f"+Y outer prong {o2b-o2a:.3f} == {PRONG_OUT_T}+{BOSS_P} boss "
              f"(reinforced from the original's 2.70)")
        check(abs(o2b - (W3_HALF+BOSS_P)) < TOL,
              f"+Y outer face at {o2b:+.3f} == {W3_HALF+BOSS_P:.2f}")
        check(abs(o1a + W3_HALF + BOSS_M) < TOL,
              f"-Y outer face at {o1a:+.3f} == {-(W3_HALF+BOSS_M):.2f}")
        print(f"     stack width {o2b-o1a:.3f} mm "
              f"(the {2*W3_HALF:.1f} GoPro stack plus {BOSS_M}+{BOSS_P} of boss)")
        # the real acceptance test: does a nominal 3.00 GoPro finger fit?
        check(slot1 >= U and slot2 >= U, "a 3.00 mm GoPro finger enters both slots")
        warn(slot1-U <= 0.35 and slot2-U <= 0.35,
             f"slot slop on a 3.00 finger is {slot1-U:.2f}/{slot2-U:.2f} mm (want <=0.35)")

    XQ = L - 5.0
    print(f"\n[2] GoPro prong grid -- 2-prong end, probed along Y at x={XQ}, z={PIVOT_Z:.3f}")
    tB = near_axis(tris, 0, XQ)
    iv = ray_intervals(tB, (XQ, -50.0, PIVOT_Z), 1)
    iv = [(a-50, b-50) for a, b in iv]
    print("     solid spans:", ", ".join(f"[{a:+.3f},{b:+.3f}]={b-a:.3f}" for a, b in iv))
    check(len(iv) == 2, f"2-prong end has exactly 2 fingers (got {len(iv)})")
    if len(iv) == 2:
        (f1a, f1b), (f2a, f2b) = iv
        check(abs((f1b-f1a)-FING_W) < TOL, f"finger 1 {f1b-f1a:.3f} == {FING_W}")
        check(abs((f2b-f2a)-FING_W) < TOL, f"finger 2 {f2b-f2a:.3f} == {FING_W}")
        check(abs((f2a-f1b)-SLOT_W) < TOL, f"central gap {f2a-f1b:.3f} == {SLOT_W}")
        check(abs((f1a+f1b)/2 + U) < TOL, f"finger 1 centred on {-U} (got {(f1a+f1b)/2:+.3f})")
        check(abs((f2a+f2b)/2 - U) < TOL, f"finger 2 centred on {+U} (got {(f2a+f2b)/2:+.3f})")
        check(f1b-f1a <= U and f2b-f2a <= U, "both fingers enter a 3.00 mm GoPro slot")
        check(f2a-f1b >= U, "central gap accepts a 3.00 mm GoPro middle prong")

    # ---------------------------------------------------------------- 3
    print("\n[3] pivot bores")
    for name, px in (("A", 0.0), ("B", L)):
        # probe across the bore in Z at the pivot, inside a prong
        # end A: +/-3.0 is a slot -- probe the middle prong.  end B: it is a finger.
        yprobe = 0.0 if name == "A" else -U
        tY = near_axis(tris, 1, yprobe)
        ivz = ray_intervals(tY, (px, yprobe, -50.0), 2)
        ivz = [(a-50, b-50) for a, b in ivz]
        gaps = [(ivz[i][1], ivz[i+1][0]) for i in range(len(ivz)-1)]
        print(f"     bore {name}: solid Z spans {['%.3f..%.3f' % g for g in ivz]}")
        bore_gaps = [g for g in gaps if abs((g[0]+g[1])/2 - PIVOT_Z) < 3]
        check(len(bore_gaps) == 1, f"bore {name}: exactly one void through the prong")
        if bore_gaps:
            g = bore_gaps[0]
            # the round part of the teardrop sits below the pivot axis
            check(abs(g[0] - (PIVOT_Z - BORE_D/2)) < TOL,
                  f"bore {name} floor at z={g[0]:.3f} == {PIVOT_Z-BORE_D/2:.3f} (M5 seats on the round)")
            # A PLAIN ROUND hole tops out at PIVOT_Z + BORE_D/2.  Requiring
            # merely ">= that" passes a round hole and verifies no teardrop at
            # all; the 45 deg apex must stand clearly above it.
            apex = PIVOT_Z + BORE_D/2*math.sqrt(2)
            check(g[1] >= PIVOT_Z + BORE_D/2 + 0.8,
                  f"bore {name} roof z={g[1]:.3f} is a TEARDROP apex "
                  f"(a round hole would stop at {PIVOT_Z+BORE_D/2:.3f}, 45 deg apex {apex:.3f})")
            check(g[0] > 2.0, f"bore {name} floor leaves {g[0]:.3f} mm of material under the bore")
        # width across the bore in Y-free direction: probe X through the pivot
        ivx = ray_intervals(near_axis(tY, 2, PIVOT_Z), (-50.0, yprobe, PIVOT_Z), 0)
        ivx = [(a-50, b-50) for a, b in ivx]
        xg = [(ivx[i][1], ivx[i+1][0]) for i in range(len(ivx)-1)]
        near = [g for g in xg if abs((g[0]+g[1])/2 - px) < 3]
        if near:
            d = near[0][1]-near[0][0]
            check(abs(d - BORE_D) < TOL+0.06, f"bore {name} diameter {d:.3f} == {BORE_D}")

    # ---------------------------------------------------------------- 4
    print(f"\n[4] printability -- overhangs steeper than {OH_ANG} deg from vertical")
    lim = math.sin(math.radians(OH_ANG + FACET_TOL))
    worst_oh = 0.0
    bed = 0.0
    slot_area = 0.0
    pkt_area = 0.0
    bad = defaultdict(float)
    bad_pts = []
    bed_area = 0.0
    for t in tris:
        n, a = normal(t)
        if n is None:
            continue
        if n[2] >= -1e-6:
            continue                      # upward facing or vertical: fine
        zmax = max(p[2] for p in t)
        if zmax < 1e-4:                   # the bed face itself
            bed_area += a
            continue
        ang_oh = math.degrees(math.asin(min(1, -n[2])))
        cen = [sum(p[k] for p in t)/3 for k in range(3)]
        # A slot roof is the pocket cylinder AND one of the slot's Y bands.
        # Testing the XZ radius alone exempted an INFINITE CYLINDER IN Y, so
        # every down-facing facet anywhere near a knuckle was waved through.
        r0 = math.hypot(cen[0]-0.0, cen[2]-PIVOT_Z)
        r1 = math.hypot(cen[0]-L,   cen[2]-PIVOT_Z)
        yb = SLOT_W/2 + 0.05
        in_slot = ((r0 <= POCKET_R + 0.15 and abs(abs(cen[1]) - U) <= yb) or
                   (r1 <= POCKET_R + 0.15 and abs(cen[1]) <= yb))
        # The screw pocket's flat roof, when it is printed with support
        # instead of bridging itself.  Same trap as the slot roofs: an XZ
        # radius test alone excuses an infinite cylinder in Y, so the facet
        # also has to lie in the pocket's own Y band.
        in_pkt = False
        if not PKT_PEAK:
            for side in PKT_SIDES:
                y_out = side*(W3_HALF + (BOSS_M if side < 0 else BOSS_P))
                lo_y, hi_y = sorted((y_out, y_out - side*PKT_DEPTH))
                if (r0 <= PKT_R + 0.15
                        and lo_y - 0.05 <= cen[1] <= hi_y + 0.05):
                    in_pkt = True
        if not in_slot and not in_pkt:
            worst_oh = max(worst_oh, ang_oh)
        if -n[2] <= lim:                  # within the 45 deg budget + faceting
            continue
        # classify: is it the roof of a slot pocket (a short bridge)?
        if in_slot:
            slot_area += a
        elif in_pkt:
            pkt_area += a
        else:
            bad[round(cen[0], 0)] += a
            bad_pts.append((cen, math.degrees(math.asin(min(1, -n[2]))), a))
    print(f"     steepest facet OUTSIDE the slot roofs {worst_oh:6.2f} deg from vertical")
    print(f"     bed contact area           {bed_area:8.2f} mm^2")
    print(f"     slot-roof bridging area    {slot_area:8.2f} mm^2  (spans the {SLOT_W} mm slot)")
    if not PKT_PEAK:
        print(f"     screw-pocket ROOF area     {pkt_area:8.2f} mm^2  "
              f"(flat ceiling {PKT_R:.2f} mm wide -- THIS is what needs support)")
    print(f"     unclassified overhang area {sum(bad.values()):8.2f} mm^2")
    check(bed_area > 150, f"bed contact {bed_area:.1f} mm^2 is enough to hold the part down")
    check(sum(bad.values()) < 0.5,
          f"no unsupported overhang outside the slot roofs ({sum(bad.values()):.3f} mm^2)")
    if bad_pts:
        for cen, ang, a in sorted(bad_pts, key=lambda z: -z[2])[:8]:
            print(f"       at ({cen[0]:.2f},{cen[1]:.2f},{cen[2]:.2f})  {ang:.1f} deg  {a:.3f} mm^2")
    # the slot roof is only acceptable because it bridges a narrow slot
    check(SLOT_W <= 3.5, f"slot-roof bridge span is {SLOT_W} mm (PETG bridges this)")
    check(slot_area < 40.0,
          f"excused slot-roof area {slot_area:.2f} mm^2 stays small (cap 40)")
    if not PKT_PEAK:
        # The pocket roof is excused because it is SUPPORTED, not because it
        # bridges.  Cap it anyway so the exemption cannot quietly grow to
        # cover a modelling mistake somewhere else in the pocket's Y band.
        check(pkt_area < 60.0,
              f"supported pocket-roof area {pkt_area:.2f} mm^2 is only the two "
              f"ceilings it should be (cap 60)")
        check(pkt_area > 1.0,
              f"the pocket roof really is flat ({pkt_area:.2f} mm^2) -- with "
              f"pkt_peak off there must BE a ceiling to support")
    check(worst_oh <= OH_ANG + FACET_TOL,
          f"steepest non-slot overhang {worst_oh:.2f} deg <= {OH_ANG} deg (+faceting)")

    print("\n[4b] joint envelope -- the FREE end of each knuckle must stay inside R7.5")
    print("     (a mating body sweeps the R7.5 circle; anything poking out of it")
    print("      past the pivot is what jams the hinge part-way through its travel)")
    for name, px, sgn in (("A", 0.0, -1), ("B", L, +1)):
        worst = 0.0
        for t in tris:
            for p in t:
                if sgn*(p[0]-px) <= 0:      # only material past the pivot
                    continue
                worst = max(worst, math.hypot(p[0]-px, p[2]-PIVOT_Z))
        print(f"     knuckle {name}: max radius beyond the pivot {worst:.3f} mm")
        check(worst <= TAB_R + 0.02,
              f"knuckle {name} free end inside R{TAB_R} (max {worst:.3f})")

    print("\n[4c] prong free length -- how far the slots run past the mating knuckle")
    for name, px, sgn in (("A", 0.0, +1), ("B", L, -1)):
        # walk +x from the pivot along a slot and find where it closes up
        yslot = U if name == "A" else 0.0
        reach = 0.0
        shut = 0
        for i in range(1, 400):
            # 0.013 offset keeps samples off exact geometric planes (x=7.500 is
            # the knuckle's tangent plane, where a ray grazes coincident facets
            # and returns an odd crossing count)
            xx = px + sgn*(i*0.05 + 0.013)
            iv = ray_intervals(near_axis(tris, 0, xx), (xx, -50.0, PIVOT_Z), 1)
            iv = [(a-50, b-50) for a, b in iv]
            # slot still open if no solid spans the slot centre
            if not any(a < yslot < b for a, b in iv):
                reach = abs(xx - px)
                shut = 0
            else:
                shut += 1
                if shut >= 3:      # ignore single-sample grazing glitches
                    break
        free = reach - (TAB_R + JOINT_CLR)
        print(f"     knuckle {name}: slot runs to r={reach:.2f}, "
              f"{free:.2f} mm past the R{TAB_R}+{JOINT_CLR} mating envelope")
        check(free >= PRONG_FREE - 0.35,
              f"knuckle {name} prongs have >= {PRONG_FREE} mm of free length "
              f"to flex on (got {free:.2f})")

    # ---------------------------------------------------------------- 5
    if not args.gauge and SECTION == 'slab':
        print("\n[5] slab section at mid-beam")
        xm = L/2
        tM = near_axis(tris, 0, xm)
        prof = []
        for i in range(1, 512):
            z = i*SB_H/512
            iv2 = ray_intervals(tM, (xm, -50.0, z), 1)
            if iv2:
                prof.append((z, iv2[0][1]-iv2[0][0]))
        wmax = max(w for _, w in prof)
        height = hi[2] - lo[2]
        base = prof[0][1] - 2*prof[0][0]        # unwind the 45 deg chamfer to z=0
        print(f"     height (Z extent)       {height:.3f} mm")
        print(f"     max width               {wmax:.3f} mm")
        print(f"     base width at z=0       {base:.3f} mm")
        check(abs(height-SB_H) < 0.05,
              f"body height {height:.3f} == knuckle height {SB_H:.3f} (no chord ramp)")
        check(abs(wmax-SB_T) < 0.15, f"max width {wmax:.3f} == {SB_T}")
        check(abs(base-(SB_T-2*SB_CHAM)) < 0.15,
              f"bottom chamfer leaves a {base:.3f} mm bed footing == {SB_T-2*SB_CHAM}")
        # bottom chamfer angle: the flank must not lean past the overhang budget
        rise = [(z, w) for z, w in prof if w < SB_T - 0.02 and z < SB_H/2]
        worst = 0.0
        for i in range(1, len(rise)):
            dz = rise[i][0]-rise[i-1][0]
            dw = (rise[i][1]-rise[i-1][1])/2
            if dz > 0:
                worst = max(worst, math.degrees(math.atan2(dw, dz)))
        print(f"     bottom chamfer angle    {worst:.1f} deg from vertical")
        check(worst <= OH_ANG + 0.5,
              f"bottom edge is a {worst:.1f} deg CHAMFER, not a fillet "
              f"(a fillet turns down through vertical and overhangs)")
        # Top edge rounding, measured off the top FACE itself.  A ray one
        # sample below the apex is still on the fillet and reads ~0.6 mm wide;
        # the flat is only flat exactly at z = SB_H.
        ys = [p[1] for t in tM for p in t if abs(p[2]-SB_H) < 1e-3]
        wtop = (max(ys) - min(ys)) if ys else 0.0
        rt = (SB_T - wtop)/2
        print(f"     top flat {wtop:.3f} mm -> edge radius {rt:.3f} mm")
        check(abs(rt-SB_RT) < 0.15,
              f"top edges are eased r{rt:.2f} == r{SB_RT} (smoothed, not knife-edged)")
        # THE section requirement: smoothed edges, but explicitly NOT an ellipse.
        # An ellipse has no straight flank anywhere; this must have a long one.
        straight = sum(1 for _, w in prof if abs(w-SB_T) < 0.05)/len(prof)
        print(f"     straight flank          {100*straight:.0f}% of the height")
        check(straight >= 0.40,
              f"{100*straight:.0f}% of the section is a STRAIGHT vertical flank "
              f"(>=40%) -- edges are smoothed, the section is not an ellipse")

    if not args.gauge and SECTION == 'strut':
        print("\n[5] strut section at mid-beam")
        xm = L/2
        tM = near_axis(tris, 0, xm)
        ivy = ray_intervals(tM, (xm, -50.0, 0.02), 1)
        base = (ivy[0][1]-ivy[0][0]) if ivy else 0
        print(f"     base width at z=0.02    {base:.3f} mm")
        check(abs(base-BASE_W) < 0.15, f"flat trailing base {base:.3f} == {BASE_W}")
        # max thickness and its height
        best = (0, 0)
        prof = []
        for i in range(1, 400):
            z = i*BEAM_C/400
            iv2 = ray_intervals(tM, (xm, -50.0, z), 1)
            if not iv2:
                continue
            w = iv2[0][1]-iv2[0][0]
            prof.append((z, w))
            if w > best[0]:
                best = (w, z)
        tmax, ztmax = best
        chord = hi[2] - lo[2]
        print(f"     max thickness           {tmax:.3f} mm at z={ztmax:.3f}")
        print(f"     chord (Z extent)        {chord:.3f} mm")
        print(f"     fineness ratio          {chord/tmax:.2f}")
        check(abs(tmax-BEAM_T) < 0.15, f"max thickness {tmax:.3f} == {BEAM_T}")
        check(abs(chord-BEAM_C) < 0.25, f"chord {chord:.3f} == {BEAM_C}")
        check(chord/tmax > 1.8, f"fineness {chord/tmax:.2f} > 1.8 (streamlined, not bluff)")
        check(abs(ztmax/chord - 0.70) < 0.06,
              f"max thickness at {100*ztmax/chord:.0f}% of chord from the base "
              f"(= {100*(1-ztmax/chord):.0f}% behind the nose)")
        # monotone rise from the base to max thickness == self-supporting
        rise = [(z, w) for z, w in prof if z <= ztmax]
        worst = 0
        for i in range(1, len(rise)):
            dz = rise[i][0]-rise[i-1][0]
            dw = (rise[i][1]-rise[i-1][1])/2
            if dz > 0:
                worst = max(worst, math.degrees(math.atan2(dw, dz)))
        print(f"     steepest flank angle    {worst:.1f} deg from vertical")
        check(worst <= OH_ANG, f"section flanks {worst:.1f} deg <= {OH_ANG} deg")

    # ---------------------------------------------------------------- 6
    print("\n[6] screw pocket(s) in the 3-prong end")
    ivd = ray_intervals(near_axis(tris, 0, 3.5), (3.5, -50.0, PIVOT_Z), 1)
    ivd = [(a-50, b-50) for a, b in ivd]
    print("     solid spans at x=3.5:",
          ", ".join(f"[{a:+.3f},{b:+.3f}]={b-a:.3f}" for a, b in ivd))
    turns = {}
    for side in PKT_SIDES:
        tag = '-Y' if side < 0 else '+Y'
        boss = BOSS_M if side < 0 else BOSS_P
        y_out = side*(W3_HALF + boss)
        y_mid = y_out - side*PKT_DEPTH/2
        print(f"\n   pocket {tag}  (outer face y={y_out:+.3f}, probed at y={y_mid:+.3f})")
        tN = near_axis(tris, 1, y_mid)

        # across corners, measured along X through the pivot
        ivx = ray_intervals(near_axis(tN, 2, PIVOT_Z), (-50.0, y_mid, PIVOT_Z), 0)
        ivx = [(a-50, b-50) for a, b in ivx]
        gx = [(ivx[i][1], ivx[i+1][0]) for i in range(len(ivx)-1)]
        if gx:
            ac = gx[0][1]-gx[0][0]
            print(f"     across corners {ac:.3f} mm")
            check(abs(ac - 2*PKT_R) < 0.08,
                  f"pocket {tag} across corners {ac:.3f} == {2*PKT_R:.3f}")

        # across flats + 45 deg roof peak, measured along Z
        ivz = ray_intervals(near_axis(tN, 0, 0.0), (0.0, y_mid, -50.0), 2)
        ivz = [(a-50, b-50) for a, b in ivz]
        gz = [(ivz[i][1], ivz[i+1][0]) for i in range(len(ivz)-1)]
        if gz:
            lo_z, hi_z = gz[0]
            crown = TAB_TOP - hi_z
            print(f"     Z void {lo_z:.3f} .. {hi_z:.3f}, crown above the roof {crown:.3f}")
            check(abs(lo_z - (PIVOT_Z - PKT_AF/2)) < 0.06,
                  f"pocket {tag} bottom flat at {lo_z:.3f} == {PIVOT_Z-PKT_AF/2:.3f} "
                  f"(across flats {PKT_AF})")
            if PKT_PEAK:
                check(hi_z >= PIVOT_Z + PKT_AF/2 + 0.5,
                      f"pocket {tag} 45 deg peak at {hi_z:.3f} clears the top "
                      f"flat {PIVOT_Z+PKT_AF/2:.3f} (no droop)")
            else:
                check(abs(hi_z - (PIVOT_Z + PKT_AF/2)) < 0.06,
                      f"pocket {tag} roof is FLAT at {hi_z:.3f} == "
                      f"{PIVOT_Z+PKT_AF/2:.3f} (no peak; support carries it)")
            check(lo_z > 0.8, f"pocket {tag} leaves {lo_z:.3f} mm of material to the bed")
            check(crown >= 0.45,
                  f"pocket {tag} roof stays {crown:.3f} mm inside the knuckle "
                  f"crown (a wider pocket would burst out of the top)")

        # depth and floor wall
        if ivd:
            span = ivd[0] if side < 0 else ivd[-1]
            wall = span[1]-span[0]
            floor_y = span[0] if side < 0 else span[1]
            depth = abs(floor_y - y_out)
            check(abs(wall - NUT_WALL) < TOL,
                  f"pocket {tag} floor leaves {wall:.3f} mm before the slot == {NUT_WALL}")
            check(abs(depth - PKT_DEPTH) < TOL,
                  f"pocket {tag} depth {depth:.3f} == {PKT_DEPTH}")

        # --- what the pocket is FOR: hold a nut, swallow a head ------------
        # Measuring "across flats == 8.80" proves nothing on its own -- a plain
        # round hole of the same width passes it and lets the nut spin.  So
        # sweep the pocket's radius and ask the two questions directly.
        # The outline (hex + 45 deg peak) is convex, so a hex nut is inside it
        # exactly when its six corners are; a corner sweep is sound, not an
        # approximation.
        step = 2.0
        prof_r = {}
        for k in range(int(360/step)):
            th = 0.5 + step*k
            c, s = math.cos(math.radians(th)), math.sin(math.radians(th))
            hs = [h for h in ray_hits(tN, (0.0, y_mid, PIVOT_Z), (c, 0.0, s))
                  if h > 1e-6]
            prof_r[th] = hs[0] if hs else float('inf')
        ths = sorted(prof_r)

        def r_at(a, _p=prof_r, _t=ths):
            a %= 360.0
            return _p[min(_t, key=lambda t: min(abs(t-a), 360-abs(t-a)))]

        rmin = min(prof_r.values())
        psis = [0.5*i for i in range(120)]          # one 60 deg hex period
        fits = [p for p in psis
                if all(r_at(p + 60*j) >= NUT_CORNER for j in range(6))]
        turn = 60.0*len(fits)/len(psis)
        turns[side] = turn
        # Across-flats measured off the mesh, against a nominal M5 nut.
        # Negative == interference == press fit.
        fit = 2*rmin - NUT_AF
        kind = ('INTERFERENCE' if fit < -0.005
                else 'line-to-line' if fit <= 0.005 else 'clearance')
        print(f"     across flats {2*rmin:.3f} mm -> {fit:+.3f} on a nominal "
              f"{NUT_AF} nut ({kind})")
        print(f"     a centred M5 nut can turn {turn:.1f} deg before it wedges")
        if PKT_PRESS:
            # A press fit is the absence of play, so the thing to measure is
            # that there is none -- and separately that the interference is
            # not so deep that no nut will ever go home.
            check(fit <= 0.05,
                  f"pocket {tag}: {fit:+.3f} on the nut is a PRESS fit, not a "
                  f"drop-in one (<= +0.05)")
            check(fit >= -0.25,
                  f"pocket {tag}: {fit:+.3f} is still drivable -- more than "
                  f"0.25 under and nothing seats it")
            check(turn < 2.0,
                  f"pocket {tag}: the nut has no room to turn at all "
                  f"({turn:.1f} deg) -- that is what stops the rattle")
        else:
            check(turn > 0.5, f"pocket {tag}: an M5 nut actually DROPS IN "
                              f"(free orientation span {turn:.1f} deg > 0)")
            check(turn < 45.0, f"pocket {tag}: the nut is TRAPPED, not just "
                               f"loose -- it wedges after {turn:.1f} deg (a "
                               f"round hole would read 60.0)")
        if PKT_HEAD_D is not None:
            check(rmin >= PKT_HEAD_D/2 + 0.05,
                  f"pocket {tag}: an M5 socket cap head ({PKT_HEAD_D}) seats in it "
                  f"(inscribed {2*rmin:.3f})")
    if len(turns) == 2:
        print()
        check(abs(turns[-1] - turns[+1]) < 1.0,
              f"both pockets are the same pocket ({turns[-1]:.1f} vs "
              f"{turns[+1]:.1f} deg) -- the nut can go on either side")

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
    sys.exit(main())
