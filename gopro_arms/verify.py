#!/usr/bin/env python3
"""Measure a rendered arm STL against the GoPro interface + printability spec.

Everything here is measured off the exported mesh, not read back out of the
OpenSCAD source, so it catches modelling mistakes as well as parameter typos.

Usage:  python3 verify.py <arm.stl> --length 100
        python3 verify.py <gauge.stl> --length 21   (gauge Lg = 2*tab_r + 6)
"""
import argparse
import math
import struct
import sys
from collections import defaultdict

# ---- spec (must mirror arm.scad) -------------------------------------
U           = 3.00
SLOT_W      = 3.20     # u + slot_extra
FING_W      = 2.80     # u - fing_under
TAB_R       = 7.50
BORE_D      = 5.30
PRONG_OUT_T = 3.40
JOINT_CLR   = 0.25
ROOT_FILLET = 0.80
POCKET_R    = TAB_R + JOINT_CLR + ROOT_FILLET
OH_ANG      = 45.0
FACET_TOL   = 1.5      # deg -- the knuckle flank IS 45 deg, so faceting of the
                       # circle puts individual triangles a fraction over it
BEAM_T      = 10.0
BEAM_C      = 20.0
BASE_W      = 5.0
W3_HALF     = U + SLOT_W/2 + PRONG_OUT_T   # 8.00
W2_HALF     = U + FING_W/2                 # 4.40
# knuckle style "trim": the circle is cut by the bed at R/sqrt(2), which is the
# deepest the pivot can sit while the flanks still leave the bed at 45 deg.
PIVOT_Z     = TAB_R/math.sqrt(2)           # 5.303
TAB_TOP     = PIVOT_Z + TAB_R              # 12.803

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
def ray_intervals(tris, origin, axis):
    """Occupied intervals along `axis` through `origin` (Moller-Trumbore)."""
    d = [0.0, 0.0, 0.0]
    d[axis] = 1.0
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
    return [(ded[i], ded[i+1]) for i in range(0, len(ded)-1, 2)]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('stl')
    ap.add_argument('--length', type=float, required=True)
    ap.add_argument('--gauge', action='store_true')
    args = ap.parse_args()
    L = args.length

    tris = load(args.stl)
    lo, hi = bbox(tris)
    print(f"\n=== {args.stl}  ({len(tris)} facets)")
    print(f"bbox  X {lo[0]:8.3f} .. {hi[0]:8.3f}   ({hi[0]-lo[0]:.3f})")
    print(f"      Y {lo[1]:8.3f} .. {hi[1]:8.3f}   ({hi[1]-lo[1]:.3f})")
    print(f"      Z {lo[2]:8.3f} .. {hi[2]:8.3f}   ({hi[2]-lo[2]:.3f})")
    print(f"volume {volume(tris):.1f} mm^3")

    # ---------------------------------------------------------------- 1
    print("\n[1] GoPro prong grid -- 3-prong end (x=0), probed along Y at z=12")
    tA = near_axis(tris, 0, 0.0)
    iv = ray_intervals(tA, (0.0, -50.0, 12.0), 1)
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
        check(abs((o1b-o1a)-PRONG_OUT_T) < TOL, f"outer prong 1 {o1b-o1a:.3f} == {PRONG_OUT_T} (reinforced)")
        check(abs((o2b-o2a)-PRONG_OUT_T) < TOL, f"outer prong 2 {o2b-o2a:.3f} == {PRONG_OUT_T} (reinforced)")
        check(abs((o2b-o1a)-2*W3_HALF) < TOL, f"stack width {o2b-o1a:.3f} == {2*W3_HALF}")
        # the real acceptance test: does a nominal 3.00 GoPro finger fit?
        check(slot1 >= U and slot2 >= U, "a 3.00 mm GoPro finger enters both slots")
        warn(slot1-U <= 0.35 and slot2-U <= 0.35,
             f"slot slop on a 3.00 finger is {slot1-U:.2f}/{slot2-U:.2f} mm (want <=0.35)")

    print("\n[2] GoPro prong grid -- 2-prong end (x=L), probed along Y at z=12")
    tB = near_axis(tris, 0, L)
    iv = ray_intervals(tB, (L, -50.0, 12.0), 1)
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
            check(g[1] >= PIVOT_Z + BORE_D/2 - TOL,
                  f"bore {name} roof at z={g[1]:.3f} >= {PIVOT_Z+BORE_D/2:.3f} (teardrop clears the bore)")
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
        r0 = math.hypot(cen[0]-0.0, cen[2]-PIVOT_Z)
        r1 = math.hypot(cen[0]-L,   cen[2]-PIVOT_Z)
        in_slot = min(r0, r1) <= POCKET_R + 0.15
        if not in_slot:
            worst_oh = max(worst_oh, ang_oh)
        if -n[2] <= lim:                  # within the 45 deg budget + faceting
            continue
        # classify: is it the roof of a slot pocket (a short bridge)?
        if in_slot:
            slot_area += a
        else:
            bad[round(cen[0], 0)] += a
            bad_pts.append((cen, math.degrees(math.asin(min(1, -n[2]))), a))
    print(f"     steepest facet OUTSIDE the slot roofs {worst_oh:6.2f} deg from vertical")
    print(f"     bed contact area           {bed_area:8.2f} mm^2")
    print(f"     slot-roof bridging area    {slot_area:8.2f} mm^2  (spans the {SLOT_W} mm slot)")
    print(f"     unclassified overhang area {sum(bad.values()):8.2f} mm^2")
    check(bed_area > 150, f"bed contact {bed_area:.1f} mm^2 is enough to hold the part down")
    check(sum(bad.values()) < 0.5,
          f"no unsupported overhang outside the slot roofs ({sum(bad.values()):.3f} mm^2)")
    if bad_pts:
        for cen, ang, a in sorted(bad_pts, key=lambda z: -z[2])[:8]:
            print(f"       at ({cen[0]:.2f},{cen[1]:.2f},{cen[2]:.2f})  {ang:.1f} deg  {a:.3f} mm^2")
    # the slot roof is only acceptable because it bridges a narrow slot
    check(SLOT_W <= 3.5, f"slot-roof bridge span is {SLOT_W} mm (PETG bridges this)")
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

    # ---------------------------------------------------------------- 5
    if not args.gauge:
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
