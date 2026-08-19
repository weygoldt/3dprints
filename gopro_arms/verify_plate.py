#!/usr/bin/env python3
"""Measure the exported RAIL PLATE mesh against plate.scad's spec.

fitcheck.py --plate proves the connector does not FOUL a nominal GoPro part.
It cannot prove the connector is THERE: an intersection with a part that was
never built is also 0.000 mm^3, and so is an intersection with a plate whose
bolt grid landed 6 mm off.  So everything here is read back off the exported
triangles with rays, not out of the .scad file:

  * the bolt grid, measured as the GAP between solid spans along a ray at
    z = 1 mm -- which gives the 62 x 40 spacing AND the clearance diameter
    from the same reading
  * the counterbore seat and depth
  * the prong / slot grid across the connector, at a height above the nut
    pocket so the pocket cannot be mistaken for a slot
  * the M5 bore radius, read DOWNWARD from the pivot
  * the slot floor, i.e. how far the slot actually sinks into the plate
  * where the two connectors sit in X
  * every downward-facing facet, against the 45 deg overhang rule

  python3 verify_plate.py stl/gopro_rail_plate.stl
"""
import argparse
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify import load, volume, bbox, near_axis, ray_intervals, normal  # noqa: E402

# ---- the spec, copied from plate.scad -------------------------------
GRID_X, GRID_Y = 62.0, 40.0
BOLT_D, CBORE_D, CBORE_H = 4.5, 7.5, 4.4
PLATE_T, EDGE_MARGIN, CORNER_R = 8.0, 8.0, 4.0
PLATE_X, PLATE_Y = GRID_X + 2*EDGE_MARGIN, GRID_Y + 2*EDGE_MARGIN
TAB_R, U, SLOT_W, W3_HALF = 7.50, 3.00, 3.10, 7.95
PRONG_OUT, BORE_D = 3.40, 5.30
BOSS_H = 2.40                      # nut-side local thickening
BOSS_X = 18.0
PIVOT_Z = PLATE_T + TAB_R          # 15.5
TAB_TOP = PIVOT_Z + TAB_R          # 23.0
SLOT_SINK = 0.4
OH_ANG = 45.0

TOL = 0.05                         # mm; mesh is a tessellation, not algebra

fails = []
warns = []


def check(ok, msg):
    print(("  OK   " if ok else "  FAIL ") + msg)
    if not ok:
        fails.append(msg)
    return ok


def warn(ok, msg):
    print(("  OK   " if ok else "  WARN ") + msg)
    if not ok:
        warns.append(msg)
    return ok


def spans(tris, origin, axis, pad=2.0):
    """Solid intervals along `axis` through `origin`, prefiltered."""
    keep = tris
    for a in range(3):
        if a != axis:
            keep = near_axis(keep, a, origin[a], pad)
    return ray_intervals(keep, origin, axis)


def fmt(iv):
    return ", ".join(f"[{a:.3f}, {b:.3f}]" for a, b in iv)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('stl')
    args = ap.parse_args()

    tris = load(args.stl)
    if not tris:
        print("*** empty mesh -- every measurement below would false-pass")
        return 1
    lo, hi = bbox(tris)
    vol = volume(tris)
    print(f"{args.stl}: {len(tris)} facets, {vol:.1f} mm^3, "
          f"bbox {lo[0]:.2f}..{hi[0]:.2f} x {lo[1]:.2f}..{hi[1]:.2f} x "
          f"{lo[2]:.2f}..{hi[2]:.2f}\n")

    # ---- envelope ---------------------------------------------------
    print("envelope")
    check(abs((hi[0]-lo[0]) - PLATE_X) < TOL,
          f"plate length {hi[0]-lo[0]:.3f} == {PLATE_X}")
    check(abs((hi[1]-lo[1]) - PLATE_Y) < TOL,
          f"plate width  {hi[1]-lo[1]:.3f} == {PLATE_Y}")
    check(abs(lo[2]) < TOL and abs(hi[2] - TAB_TOP) < TOL,
          f"stands on the bed and tops out at {hi[2]:.3f} == {TAB_TOP} "
          f"(plate {PLATE_T} + knuckle {2*TAB_R})")

    # ---- plate thickness, clear of every feature --------------------
    print("\nplate")
    iv = spans(tris, [0.0, 24.0, 0.0], 2)
    check(len(iv) == 1 and abs(iv[0][0]) < TOL and abs(iv[0][1] - PLATE_T) < TOL,
          f"solid {PLATE_T} mm thick at (0, 24): {fmt(iv)}")

    # ---- the bolt grid, read as the GAPS in a solid span ------------
    # A ray at z = 1 is below the counterbore, so what it sees is the M4
    # clearance hole and nothing else.  Two holes on the ray -> three solid
    # spans; the two gaps ARE the holes, centre and diameter both.
    print("\nbolt grid (M4 clearance, measured at z = 1.0)")
    for axis, at, pitch, half, name in [
            (0, [0.0, GRID_Y/2, 1.0], GRID_X, PLATE_X/2, "X (rail to rail)"),
            (1, [GRID_X/2, 0.0, 1.0], GRID_Y, PLATE_Y/2, "Y (along a rail)")]:
        iv = spans(tris, at, axis, pad=3.0)
        if not check(len(iv) == 3, f"{name}: 3 solid spans (2 holes): {fmt(iv)}"):
            continue
        check(abs(iv[0][0] + half) < TOL and abs(iv[2][1] - half) < TOL,
              f"{name}: edges at +/-{half} ({iv[0][0]:.3f} .. {iv[2][1]:.3f})")
        holes = [(iv[0][1], iv[1][0]), (iv[1][1], iv[2][0])]
        cs = [(a+b)/2 for a, b in holes]
        ds = [b-a for a, b in holes]
        check(all(abs(d - BOLT_D) < TOL for d in ds),
              f"{name}: bore d {ds[0]:.3f} / {ds[1]:.3f} == {BOLT_D}")
        check(abs((cs[1]-cs[0]) - pitch) < TOL and abs(cs[0]+cs[1]) < TOL,
              f"{name}: centres {cs[0]:+.3f} / {cs[1]:+.3f} -> pitch "
              f"{cs[1]-cs[0]:.3f} == {pitch}, symmetric about 0")

    # ---- counterbore ------------------------------------------------
    # Straight down the hole axis must be clear THROUGH; a ray 3.0 mm off it
    # is inside the counterbore but outside the clearance hole, so it reads
    # the seat height and nothing else.
    print("\ncounterbore (M4 socket head)")
    iv = spans(tris, [GRID_X/2, GRID_Y/2, 0.0], 2, pad=1.0)
    check(len(iv) == 0, f"hole axis is clear through: {fmt(iv) or 'nothing'}")
    r = (BOLT_D/2 + CBORE_D/2)/2      # 3.0 -- between the two radii
    iv = spans(tris, [GRID_X/2 + r, GRID_Y/2, 0.0], 2, pad=1.0)
    seat = PLATE_T - CBORE_H
    check(len(iv) == 1 and abs(iv[0][0]) < TOL and abs(iv[0][1] - seat) < TOL,
          f"seat at z = {iv[0][1] if iv else float('nan'):.3f} == {seat} "
          f"-> {CBORE_H} deep, {seat} mm of material under the head")

    # ---- the connector's prong / slot grid --------------------------
    # Read at z = TAB_TOP - 0.6: above the nut pocket's 45 deg peak, so the
    # pocket cannot be counted as a slot, and still inside the knuckle.
    print("\nconnector grid (GoPro 3-prong, at z = top - 0.6)")
    zg = TAB_TOP - 0.6
    iv = spans(tris, [BOSS_X, 0.0, zg], 1, pad=3.0)
    if check(len(iv) == 3, f"three prongs on the ray: {fmt(iv)}"):
        slots = [(iv[0][1], iv[1][0]), (iv[1][1], iv[2][0])]
        sc = [(a+b)/2 for a, b in slots]
        sw = [b-a for a, b in slots]
        check(all(abs(w - SLOT_W) < TOL for w in sw),
              f"slot width {sw[0]:.3f} / {sw[1]:.3f} == {SLOT_W} "
              f"(a nominal 3.00 finger enters)")
        check(all(abs(abs(c) - U) < TOL for c in sc),
              f"slot centres {sc[0]:+.3f} / {sc[1]:+.3f} == +/-{U} "
              f"(the GoPro 3 mm grid)")
        centre = iv[1][1] - iv[1][0]
        check(abs(centre - 2*(U - SLOT_W/2)) < TOL,
              f"centre prong {centre:.3f} == {2*(U-SLOT_W/2):.2f}")
        outer = [iv[0][1]-iv[0][0], iv[2][1]-iv[2][0]]
        check(abs(max(outer) - (PRONG_OUT + BOSS_H)) < TOL
              and abs(min(outer) - PRONG_OUT) < TOL,
              f"outer prongs {outer[0]:.3f} / {outer[1]:.3f} -- one plain "
              f"{PRONG_OUT}, one thickened to {PRONG_OUT+BOSS_H} for the nut")
        check(abs(iv[2][1] - W3_HALF) < TOL,
              f"stack reaches +{iv[2][1]:.3f} == {W3_HALF} on the plain side")

    # ---- the M5 bore, measured downward from the pivot --------------
    print("\nM5 thumbscrew bore")
    iv = spans(tris, [BOSS_X, 0.0, 0.0], 2, pad=1.0)
    if check(len(iv) == 2, f"centre prong is bored: {fmt(iv)}"):
        check(abs((PIVOT_Z - iv[0][1]) - BORE_D/2) < TOL,
              f"bore floor {iv[0][1]:.3f} sits {PIVOT_Z-iv[0][1]:.3f} below the "
              f"pivot == r {BORE_D/2}")
        check(iv[1][1] - hi[2] > -TOL,
              f"and the knuckle closes over it again by {iv[1][1]-iv[1][0]:.3f} mm")
    # Along the hinge axis the bore is a tunnel: a ray down it must meet
    # nothing at all, or a prong is not bored through.
    iv = spans(tris, [BOSS_X, 0.0, PIVOT_Z], 1, pad=3.0)
    check(len(iv) == 0,
          f"bore runs clear through all three prongs: {fmt(iv) or 'nothing'}")

    # ---- slot floor -------------------------------------------------
    print("\nslot floor (how far the slot sinks into the plate)")
    iv = spans(tris, [BOSS_X, U, 0.0], 2, pad=1.0)
    if check(len(iv) == 1, f"slot is open to the sky: {fmt(iv)}"):
        sink = PLATE_T - iv[0][1]
        check(abs(sink - SLOT_SINK) < TOL,
              f"floor at z = {iv[0][1]:.3f} -> sinks {sink:.3f} == {SLOT_SINK} "
              f"(clearance for a knuckle tangent to the plate, no more)")

    # ---- where the connectors sit -----------------------------------
    print("\nconnector placement")
    iv = spans(tris, [0.0, 0.0, zg], 0, pad=3.0)
    if check(len(iv) == 2, f"two connectors on the ray: {fmt(iv)}"):
        cs = [(a+b)/2 for a, b in iv]
        check(all(abs(abs(c) - BOSS_X) < TOL for c in cs),
              f"centres {cs[0]:+.3f} / {cs[1]:+.3f} == +/-{BOSS_X}")
    # A hex key has to reach every screw.  Not "the numbers say it clears" --
    # ray straight DOWN the counterbore at four points on its seat and demand
    # each one meets the seat first and nothing at all above it.  This is the
    # check a connector nudged over a bolt would trip.
    r = (BOLT_D/2 + CBORE_D/2)/2
    blocked = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            for k in range(8):
                a = math.radians(45*k)
                o = [sx*GRID_X/2 + r*math.cos(a), sy*GRID_Y/2 + r*math.sin(a), 0.0]
                iv = spans(tris, o, 2, pad=1.0)
                if len(iv) != 1 or abs(iv[0][1] - (PLATE_T - CBORE_H)) > TOL:
                    blocked.append((round(o[0], 2), round(o[1], 2), fmt(iv)))
    check(not blocked,
          "all 4 counterbores are open to the sky (32 rays) "
          + (f"-- blocked at {blocked[:3]}" if blocked else ""))

    # ---- printability ------------------------------------------------
    # Everything that faces downward more steeply than the overhang rule,
    # ignoring the bed itself.  This is the check that would catch a knuckle
    # dropped straight onto the plate without the pad.
    print(f"\noverhangs (nothing may face down flatter than {OH_ANG} deg "
          f"from vertical)")
    lim = -math.cos(math.radians(OH_ANG)) - 0.02
    worst, worst_z, bad, bad_area = 0.0, 0.0, 0, 0.0
    for t in tris:
        n, a = normal(t)
        if n is None:
            continue
        zc = sum(p[2] for p in t)/3.0
        if zc < 0.02:                      # the bed face
            continue
        if n[2] < lim:
            bad += 1
            bad_area += a
            if n[2] < worst:
                worst, worst_z = n[2], zc
    # Report the steepest downward facet even when it passes: "0 bad facets"
    # on a part with no downward faces at all would be a check that never had
    # anything to grade.
    steep, steep_z = 0.0, 0.0
    for t in tris:
        n, _ = normal(t)
        if n is None or sum(p[2] for p in t)/3.0 < 0.02:
            continue
        if n[2] < steep:
            steep, steep_z = n[2], sum(p[2] for p in t)/3.0
    check(bad == 0,
          f"{bad} facet(s), {bad_area:.2f} mm^2, face down past the rule; "
          f"steepest downward facet nz {steep:.4f} at z {steep_z:.2f} "
          f"(the rule is {lim + 0.02:.4f})"
          + (f" -- worst {worst:.3f} at z {worst_z:.2f}" if bad else ""))

    print()
    if fails:
        print(f"PLATE FAILED -- {len(fails)} check(s)")
        for f in fails:
            print("   " + f)
        return 1
    print("PLATE OK" + (f"  ({len(warns)} warning(s))" if warns else ""))
    return 0


if __name__ == '__main__':
    sys.exit(main())
