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
  * the bolt head seat -- a recessed counterbore, or (default) 32 rays on a
    button head's rim proving the face under it is flat and full thickness
  * that the frame is ONE connected shell, and that the bridge between the
    connectors is as wide as the connectors themselves
  * the quarter-round on each outer prong's outside face, read at 45 deg
    where setback == inset
  * the prong / slot grid across the connector, at a height above the nut
    pocket so the pocket cannot be mistaken for a slot
  * the M5 bore radius, read DOWNWARD from the pivot
  * the slot floor -- it has to stop in the PEDESTAL, leaving a web
    that ties the three prong roots together
  * 16 rays up through each connector's footprint, each of which must be
    ONE unbroken solid from the bed: the connector is welded to the plate,
    not a disc perched on it (which is what rev 1 was)
  * both screw pockets, read across the stack in one ray: the nut seat, the
    barrel-head seat, and the wall between the head countersink and the slot
  * the head seat's diameter and its teardrop roof, read straight up
  * the top edge chamfer, as the drop between two probes a known distance apart
  * where the two connectors sit in X
  * every downward-facing facet, against the 45 deg overhang rule

  python3 verify_plate.py stl/gopro_rail_plate.stl
  python3 verify_plate.py stl/gopro_rail_plate_155mm.stl --wide

--wide checks the 155 x 40 variant, whose single connector is turned a quarter
turn.  Rather than fork every connector check onto the other axis, the MESH is
rotated -90 deg about Z first, which puts that connector back on the default
frame -- so the prong grid, the pockets, the bore and the weld rays below are
the same code reading the same numbers, and only the plate's own dimensions and
bolt grid swap over.  A rotation is not a mirror: it cannot hide a handedness
error, and it leaves every z unchanged, so the overhang scan is untouched.
"""
import argparse
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from verify import load, volume, bbox, near_axis, ray_intervals, normal  # noqa: E402

# ---- the spec, copied from plate.scad -------------------------------
GRID_X, GRID_Y = 62.0, 40.0
BOLT_D, CBORE_D, CBORE_H = 4.5, 7.5, 0.0
BOLT_HEAD_D = 7.6                  # ISO 7380 button head, bears on the face
PLATE_T, EDGE_MARGIN, CORNER_R = 5.0, 8.0, 4.0
FRAME, PAD_R, RIB_HW = True, 6.0, 6.0
PLATE_X, PLATE_Y = GRID_X + 2*PAD_R, GRID_Y + 2*PAD_R
TAB_R, U, SLOT_W, W3_HALF = 7.50, 3.00, 3.10, 7.95
PRONG_OUT, BORE_D = 3.40, 5.30
BOSS_H = 2.40                      # nut-side local thickening
HD_D, HD_DEPTH, BOSS_HD = 8.80, 5.30, 3.40   # barrel head seat, head side
NUT_DEPTH, NUT_WALL, HEAD_CS = 4.30, 1.50, 0.50
TOP_CHAM = 1.0
BOSS_SKIRT, NODE_MARGIN, BOSS_RIM_R = 1.5, 1.5, 1.25
BOSS_R = 7.50                      # local pocket-boss radius
BOSS_X, BOSS_HW, BOSS_RISER = 18.0, 7.50, 5.0
CONNECTORS = [-BOSS_X, BOSS_X]     # centres along X, in the connector's frame
DISC_Z = PLATE_T + BOSS_RISER      # 13.0 -- lowest point of the knuckle disc
PIVOT_Z = DISC_Z + TAB_R           # 20.5
TAB_TOP = PIVOT_Z + TAB_R          # 28.0
SLOT_SINK = 0.4
SLOT_Z = DISC_Z - SLOT_SINK        # 12.6 -- floor, still inside the pedestal
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


def hole_near(tris, axis, origin, nominal):
    """The empty gap in the solid nearest `nominal` along `axis`.

    The solid slab gave one continuous span per ray, so a hole was simply the
    gap between spans.  The frame does not: a ray along a bolt row meets a pad,
    then air, then the far pad.  So pick the gap whose centre is nearest where
    the hole is supposed to be, and let the caller check it landed."""
    iv = spans(tris, origin, axis, pad=3.0)
    gaps = [(iv[i][1], iv[i+1][0]) for i in range(len(iv) - 1)]
    if not gaps:
        return None
    return min(gaps, key=lambda g: abs((g[0] + g[1])/2 - nominal))


def shell_count(tris, q=1e-3):
    """Connected components, by shared (quantised) vertices.

    A skeleton is only a part if it is ONE piece.  Every other check here is
    local -- a strut that failed to reach its pad would leave the pad floating
    and every measurement of it would still pass."""
    parent = {}

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb

    for t in tris:
        ks = [(round(p[0]/q), round(p[1]/q), round(p[2]/q)) for p in t]
        for k in ks:
            parent.setdefault(k, k)
        union(ks[0], ks[1])
        union(ks[1], ks[2])
    return len({find(k) for k in parent})


def shell_selftest():
    """shell_count() is the only check here that could quietly always say 1.

    A cube is one shell; the same cube plus a copy 100 mm away is two.  If this
    instrument cannot tell those apart it cannot tell a detached pad either.
    """
    def cube(dx):
        v = [[dx+x, y, z] for x, y, z in
             [[0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0],
              [0, 0, 1], [1, 0, 1], [1, 1, 1], [0, 1, 1]]]
        f = [[0, 1, 2], [0, 2, 3], [4, 6, 5], [4, 7, 6], [0, 4, 5], [0, 5, 1],
             [1, 5, 6], [1, 6, 2], [2, 6, 7], [2, 7, 3], [3, 7, 4], [3, 4, 0]]
        return [[v[i] for i in t] for t in f]
    one, two = shell_count(cube(0)), shell_count(cube(0) + cube(100))
    ok = one == 1 and two == 2
    print(f"  {'OK  ' if ok else 'FAIL'} shell_count: one cube -> {one}, "
          f"two disjoint cubes -> {two} (want 1 and 2)")
    return 0 if ok else 1


def rotz_minus90(tris):
    """-90 deg about Z: (x, y, z) -> (y, -x, z).  A proper rotation, so winding
    and therefore every normal survives; z is untouched."""
    return [[[p[1], -p[0], p[2]] for p in t] for t in tris]


def main():
    global GRID_X, GRID_Y, PLATE_X, PLATE_Y, BOSS_X, CONNECTORS, FRAME
    ap = argparse.ArgumentParser()
    ap.add_argument('stl', nargs='?')
    ap.add_argument('--wide', action='store_true',
                    help='the 155 x 40 variant: one connector, yawed 90 deg')
    ap.add_argument('--selftest', action='store_true',
                    help='prove the connectivity instrument can count to two')
    args = ap.parse_args()
    if args.selftest:
        return shell_selftest()
    if not args.stl:
        ap.error('an STL is required unless --selftest')

    tris = load(args.stl)
    if not tris:
        print("*** empty mesh -- every measurement below would false-pass")
        return 1
    if args.wide:
        # Read in the rotated frame: the long 155 span lands along Y, the 40 mm
        # short span along X, and the connector comes back to yaw 0 at the
        # origin.  Everything below is then the default code.
        tris = rotz_minus90(tris)
        GRID_X, GRID_Y = 40.0, 155.0
        # The wide plate keeps the SOLID slab for now -- its skeleton needs its
        # own truss, see plate.scad -- so it is sized off edge_margin, not pads.
        FRAME = False
        PLATE_X, PLATE_Y = GRID_X + 2*EDGE_MARGIN, GRID_Y + 2*EDGE_MARGIN
        BOSS_X, CONNECTORS = 0.0, [0.0]
        print("[--wide] mesh rotated -90 deg about Z; grid now "
              f"{GRID_X} x {GRID_Y}, SOLID slab {PLATE_X} x {PLATE_Y}, "
              f"{len(CONNECTORS)} connector\n")
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
          f"(plate {PLATE_T} + riser {BOSS_RISER} + disc {2*TAB_R})")

    # ---- plate thickness, and the frame is ONE piece ----------------
    # Probed on the spine at the origin rather than out at (0, 24): the frame
    # has no material out there, which is the whole point of it.
    print("\nplate")
    at = [0.0, 0.0, 0.0] if FRAME else [0.0, 24.0, 0.0]
    iv = spans(tris, at, 2)
    check(len(iv) == 1 and abs(iv[0][0]) < TOL and abs(iv[0][1] - PLATE_T) < TOL,
          f"solid {PLATE_T} mm thick at ({at[0]:.0f}, {at[1]:.0f}): {fmt(iv)}")
    if FRAME:
        n = shell_count(tris)
        check(n == 1,
              f"the frame is ONE connected shell ({n} found) -- a strut that "
              f"missed its pad would leave the pad floating and every local "
              f"measurement of it would still pass")

    # ---- the bolt grid, read as the GAPS in a solid span ------------
    # A ray at z = 1 is below the counterbore, so what it sees is the M4
    # clearance hole and nothing else.  Two holes on the ray -> three solid
    # spans; the two gaps ARE the holes, centre and diameter both.
    print("\nbolt grid (M4 clearance, measured at z = 1.0, hole by hole)")
    got = []
    for sx in (-1, 1):
        for sy in (-1, 1):
            bx, by = sx*GRID_X/2, sy*GRID_Y/2
            gx = hole_near(tris, 0, [0.0, by, 1.0], bx)
            gy = hole_near(tris, 1, [bx, 0.0, 1.0], by)
            if gx is None or gy is None:
                check(False, f"no hole found near ({bx:+.1f}, {by:+.1f})")
                continue
            cx, dx = (gx[0]+gx[1])/2, gx[1]-gx[0]
            cy, dy = (gy[0]+gy[1])/2, gy[1]-gy[0]
            got.append((cx, cy))
            check(abs(cx - bx) < TOL and abs(cy - by) < TOL
                  and abs(dx - BOLT_D) < TOL and abs(dy - BOLT_D) < TOL,
                  f"hole at ({cx:+.3f}, {cy:+.3f}) == ({bx:+.1f}, {by:+.1f}), "
                  f"d {dx:.3f} x {dy:.3f} == {BOLT_D}")
    if len(got) == 4:
        px = max(c[0] for c in got) - min(c[0] for c in got)
        py = max(c[1] for c in got) - min(c[1] for c in got)
        check(abs(px - GRID_X) < TOL and abs(py - GRID_Y) < TOL,
              f"grid measures {px:.3f} x {py:.3f} == {GRID_X} x {GRID_Y}")

    # ---- counterbore ------------------------------------------------
    # Straight down the hole axis must be clear THROUGH; a ray 3.0 mm off it
    # is inside the counterbore but outside the clearance hole, so it reads
    # the seat height and nothing else.
    print("\nbolt head seat"
          + (" (M4 socket head, recessed)" if CBORE_H > 0
             else " (M4 BUTTON head, bearing on the face)"))
    iv = spans(tris, [GRID_X/2, GRID_Y/2, 0.0], 2, pad=1.0)
    check(len(iv) == 0, f"hole axis is clear through: {fmt(iv) or 'nothing'}")
    if CBORE_H > 0:
        r = (BOLT_D/2 + CBORE_D/2)/2
        iv = spans(tris, [GRID_X/2 + r, GRID_Y/2, 0.0], 2, pad=1.0)
        seat = PLATE_T - CBORE_H
        check(len(iv) == 1 and abs(iv[0][0]) < TOL and abs(iv[0][1] - seat) < TOL,
              f"seat at z = {iv[0][1] if iv else float('nan'):.3f} == {seat}")
    else:
        # A button head bears on the top face, so what has to be true is that
        # the face is FLAT and FULL THICKNESS right out to the rim of the head,
        # and that nothing stands above it for a driver to hit.
        bad = []
        for sx in (-1, 1):
            for sy in (-1, 1):
                for k in range(8):
                    a = math.radians(45*k)
                    o = [sx*GRID_X/2 + (BOLT_HEAD_D/2)*math.cos(a),
                         sy*GRID_Y/2 + (BOLT_HEAD_D/2)*math.sin(a), 0.0]
                    iv = spans(tris, o, 2, pad=1.0)
                    if len(iv) != 1 or abs(iv[0][0]) > TOL \
                            or abs(iv[0][1] - PLATE_T) > TOL:
                        bad.append((round(o[0], 2), round(o[1], 2), fmt(iv)))
        check(not bad,
              f"32 rays on the d{BOLT_HEAD_D} head rim: full {PLATE_T} mm of "
              f"flat face under every one, nothing above"
              + (f" -- {bad[:3]}" if bad else ""))

    # ---- the connector's prong / slot grid --------------------------
    # Read down in the PEDESTAL, at DISC_Z + 1.5.  It used to be read just
    # under the crown, which was fine until the outer rims were rounded: a
    # quarter-round pulls the section in near the end faces, so up there the
    # stack no longer reaches p_y_lo/p_y_hi and the reading was of the rim, not
    # the grid.  Down here it is below both screw pockets (so neither can be
    # miscounted as a slot), above the slot floor (so the slots are open), and
    # well inboard of the rims.
    zg = DISC_Z + 1.5
    print(f"\nconnector grid (GoPro 3-prong, at z = disc + 1.5 = {zg})")
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
        want = sorted([PRONG_OUT + BOSS_H, PRONG_OUT + BOSS_HD])
        check(all(abs(a - b) < TOL for a, b in zip(sorted(outer), want)),
              f"outer prongs {outer[0]:.3f} / {outer[1]:.3f} -- thickened to "
              f"{want[0]} for the nut and {want[1]} for the barrel head")
        check(abs(iv[0][0] + (W3_HALF + BOSS_H)) < TOL
              and abs(iv[2][1] - (W3_HALF + BOSS_HD)) < TOL,
              f"stack spans {iv[0][0]:.3f} .. {iv[2][1]:.3f} == "
              f"{-(W3_HALF+BOSS_H)} .. {W3_HALF+BOSS_HD} "
              f"({iv[2][1]-iv[0][0]:.3f} mm wide)")

    # ---- the rounded outside faces ----------------------------------
    # A quarter round is symmetric at 45 deg: however far back from the end face
    # you stand, the section is pulled in by the same amount.  So one reading
    # proves both that the rim is there and that its radius is right -- and it
    # is a reading no square-edged prong can produce.
    print("\nrounded outside faces of the outer prongs")
    back = BOSS_RIM_R*(1 - math.sin(math.radians(45)))

    def hw_at(y):
        allsp = spans(tris, [0.0, y, zg], 0, pad=14.0)
        mine = [sp for sp in allsp if sp[0] <= BOSS_X <= sp[1]]
        return (mine[0][1] - mine[0][0])/2 if mine else float('nan')

    for y, want, what in (
            (W3_HALF + BOSS_HD - BOSS_RIM_R - 0.5, BOSS_HW, "inboard of the rim"),
            (W3_HALF + BOSS_HD - back, BOSS_HW - back, "45 deg into the rim")):
        got = hw_at(y)
        check(abs(got - want) < TOL,
              f"{what} (y {y:.3f}): half-width {got:.3f} == {want:.3f}")

    # ---- the bridge between connectors ------------------------------
    if FRAME and len(CONNECTORS) > 1:
        print("\nbridge between connectors")
        pad_w = (W3_HALF + BOSS_H) + (W3_HALF + BOSS_HD) \
            + 2*BOSS_SKIRT + 2*NODE_MARGIN
        pad_c = ((W3_HALF + BOSS_HD) - (W3_HALF + BOSS_H))/2
        iv = spans(tris, [0.0, 0.0, 1.0], 1, pad=3.0)
        w = (iv[0][1] - iv[0][0]) if len(iv) == 1 else float('nan')
        c = ((iv[0][0] + iv[0][1])/2) if len(iv) == 1 else float('nan')
        check(len(iv) == 1 and abs(w - pad_w) < TOL and abs(c - pad_c) < TOL,
              f"{w:.3f} mm wide at the origin == {pad_w:.3f}, centred {c:+.3f} "
              f"== {pad_c:+.3f} -- as wide as the connector, no waist: {fmt(iv)}")

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
    print("\nslot floor (it must stop in the PEDESTAL, not in the plate)")
    iv = spans(tris, [BOSS_X, U, 0.0], 2, pad=1.0)
    if check(len(iv) == 1, f"solid from the bed to the floor, then open sky: {fmt(iv)}"):
        check(abs(iv[0][1] - SLOT_Z) < TOL,
              f"floor at z = {iv[0][1]:.3f} == {SLOT_Z} -- {SLOT_SINK} under the "
              f"disc (all the clearance a knuckle of radius {TAB_R} can need)")
        web = iv[0][1] - PLATE_T
        check(web > 0.5,
              f"and {web:.3f} mm of pedestal web left under the slot, tying the "
              f"three prong roots together (rev 1 had none -- the slot reached "
              f"the plate)")

    # ---- the two screw pockets, read across the stack ---------------
    # A ray along Y, offset in X, is OUTSIDE the M5 bore (r 2.65) but still
    # inside both pockets, so one reading gives both floors and both walls.
    # Solid runs: nut-pocket floor -> slot, centre prong, slot -> head seat.
    #
    # The offset matters.  The countersink at the head-seat floor is a 45 deg
    # cone from r CS_R = bore_d/2 + head_cs down to bore_d/2, so a ray closer
    # to the axis than CS_R clips it and reads a floor that much deeper.  At
    # 3.5 the cone is missed entirely and the seat is measured clean; at 3.0 it
    # is clipped by exactly CS_R - 3.0, which is how the countersink itself
    # gets measured two lines further down.
    print("\nscrew pockets (M5 nut one side, barrel head the other)")
    CS_R = BORE_D/2 + HEAD_CS          # 3.15
    iv = spans(tris, [BOSS_X + 3.5, 0.0, PIVOT_Z], 1, pad=3.0)
    if check(len(iv) == 3, f"three solid runs across the stack: {fmt(iv)}"):
        nut_floor, hd_floor = iv[0][0], iv[2][1]
        check(abs((W3_HALF + BOSS_H) + nut_floor - NUT_DEPTH) < TOL,
              f"nut pocket {(W3_HALF+BOSS_H)+nut_floor:.3f} deep == {NUT_DEPTH} "
              f"(floor at y {nut_floor:.3f})")
        check(abs((W3_HALF + BOSS_HD) - hd_floor - HD_DEPTH) < TOL,
              f"head seat {(W3_HALF+BOSS_HD)-hd_floor:.3f} deep == {HD_DEPTH} "
              f"(floor at y {hd_floor:+.3f}) -- an M5 cap head drops in flush")
        check(abs((hd_floor - (U + SLOT_W/2)) - NUT_WALL) < TOL,
              f"{hd_floor-(U+SLOT_W/2):.3f} mm of wall between the head seat "
              f"and the slot behind it == {NUT_WALL}")
        # The countersink, measured as how much deeper the floor reads once the
        # ray is inside the cone.  A 45 deg cone means depth == CS_R - offset.
        iv2 = spans(tris, [BOSS_X + 3.0, 0.0, PIVOT_Z], 1, pad=3.0)
        if check(len(iv2) == 3, f"same ray 0.5 nearer the axis: {fmt(iv2)}"):
            bite = hd_floor - iv2[2][1]
            check(abs(bite - (CS_R - 3.0)) < TOL,
                  f"countersink takes the floor {bite:.3f} deeper at 3.0 vs 3.5 "
                  f"off-axis == {CS_R-3.0:.3f} -> a 45 deg relief out to "
                  f"r {CS_R}, so the head bears on a flat annulus not an edge")
    # Diameter and roof of the head seat, read straight up through it.  y = 8.0
    # is inside the pocket (its floor is at 6.05); the void runs from the
    # counterbore radius below the pivot to the TEARDROP APEX above it, and the
    # apex is the number the assert in plate.scad is really about.
    iv = spans(tris, [BOSS_X, 8.0, 0.0], 2, pad=1.0)
    apex = PIVOT_Z + (HD_D/2)/math.cos(math.radians(OH_ANG))
    if check(len(iv) == 2, f"head seat is a through-void in Z: {fmt(iv)}"):
        check(abs((PIVOT_Z - iv[0][1]) - HD_D/2) < TOL,
              f"counterbore floor {PIVOT_Z-iv[0][1]:.3f} below the pivot == "
              f"r {HD_D/2} (d{HD_D})")
        check(abs(iv[1][0] - apex) < TOL,
              f"teardrop apex at z {iv[1][0]:.3f} == {apex:.3f}, and the crown "
              f"is {TAB_TOP} -- {TAB_TOP-iv[1][0]:.3f} mm of roof left")

    # ---- the top edge chamfer ---------------------------------------
    # Two rays a known distance apart, near the edge: on a 45 deg break the
    # top surface has to drop by exactly the distance they are apart.
    print("\ntop edge chamfer")
    # On the frame there is no slab edge to probe: the free rim is the OUTBOARD
    # side of each bolt pad, so walk in from there along the outward radius.
    if FRAME:
        bx, by = GRID_X/2, GRID_Y/2
        n = math.hypot(bx, by)
        ux, uy = bx/n, by/n
        probes = (("pad rim", lambda d: [bx + (PAD_R - d)*ux,
                                         by + (PAD_R - d)*uy, 0.0]),)
    else:
        probes = (("X edge", lambda d: [PLATE_X/2 - d, 0.0, 0.0]),
                  ("Y edge", lambda d: [0.0, PLATE_Y/2 - d, 0.0]))
    for axis_name, pt in probes:
        a = spans(tris, pt(0.25), 2, pad=1.0)
        b = spans(tris, pt(0.75), 2, pad=1.0)
        if not check(len(a) == 1 and len(b) == 1,
                     f"{axis_name}: solid under both probes: {fmt(a)} / {fmt(b)}"):
            continue
        drop_a, drop_b = PLATE_T - a[0][1], PLATE_T - b[0][1]
        check(abs(drop_a - 0.75) < TOL and abs(drop_b - 0.25) < TOL,
              f"{axis_name}: top drops {drop_a:.3f} at 0.25 in and {drop_b:.3f} "
              f"at 0.75 in -> 45 deg, {TOP_CHAM} mm break")

    # ---- the connector is WELDED to the plate, not perched on it ----
    # This is the check rev 1 would have failed and the reason the pedestal
    # exists.  There, the knuckle was a disc TANGENT to the plate, so a ray up
    # through the footprint met the plate, then a GAP of air, then the disc --
    # two intervals.  With the pedestal every ray inside the footprint is ONE
    # continuous solid from the bed to the top of the section.  Offsets in X
    # avoid the M5 bore (it is a tunnel along Y, so it would split any ray
    # closer than its radius to the axis); offsets in Y sit in the two outer
    # prongs and clear of the nut pocket at y <= -6.05.
    print("\nconnector welded to the plate (no gap at the root)")
    broken = []
    for cx in CONNECTORS:
        for dx in (-7.0, -5.0, 5.0, 7.0):
            for dy in (5.0, -5.0):
                iv = spans(tris, [cx + dx, dy, 0.0], 2, pad=1.0)
                top = DISC_Z + TAB_R + math.sqrt(max(0.0, TAB_R**2 - dx**2))
                if len(iv) != 1 or abs(iv[0][0]) > TOL or abs(iv[0][1] - top) > TOL:
                    broken.append((round(cx + dx, 1), dy, fmt(iv) or 'nothing'))
    check(not broken,
          f"{len(CONNECTORS)*8} rays up through the footprint, each ONE unbroken "
          f"span from the bed to the section top"
          + (f" -- broken at {broken[:3]}" if broken else ""))
    # And the pedestal really is the full 2*BOSS_HW wide: a ray just OUTSIDE
    # it, at the same height, must miss.  Without this the check above would
    # pass on a pedestal 1 mm wide.
    # The ray runs the whole length of the plate and meets BOTH connectors, so
    # take the span that actually contains this connector's axis.
    # ray_intervals returns offsets FROM THE ORIGIN, so scan from x = 0 and
    # the numbers come back as plain X coordinates.
    allsp = spans(tris, [0.0, 5.0, DISC_Z - 1.0], 0, pad=12.0)
    mine = [s for s in allsp if s[0] <= BOSS_X <= s[1]]
    check(len(mine) == 1 and abs((mine[0][1] - mine[0][0]) - 2*BOSS_HW) < TOL,
          f"pedestal is {(mine[0][1]-mine[0][0]) if mine else float('nan'):.3f} "
          f"mm wide in X at z = {DISC_Z-1.0} == {2*BOSS_HW} "
          f"(spans on the ray: {fmt(allsp)})")

    # ---- where the connectors sit -----------------------------------
    print("\nconnector placement")
    iv = spans(tris, [0.0, 0.0, zg], 0, pad=3.0)
    if check(len(iv) == len(CONNECTORS),
             f"{len(CONNECTORS)} connector(s) on the ray: {fmt(iv)}"):
        cs = sorted((a+b)/2 for a, b in iv)
        check(all(abs(c - w) < TOL for c, w in zip(cs, sorted(CONNECTORS))),
              f"centres {[round(c,3) for c in cs]} == {sorted(CONNECTORS)}")
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
                o = [sx*GRID_X/2 + r*math.cos(a), sy*GRID_Y/2 + r*math.sin(a), 0.0]  # noqa: E501
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
    worst, worst_z, bad, bad_area, biggest = 0.0, 0.0, 0, 0.0, 0.0
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
            biggest = max(biggest, a)
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
    # Gate on AREA, not facet count.  Where the pedestal and its skirt pierce
    # the plate's top plane, CGAL triangulates that plane around the
    # intersection curve and leaves collinear slivers -- one here, 1.7e-06 mm^2,
    # nz -1.0, three points that are the same straight line to machine
    # precision.  That is a tessellation artifact, not a surface that can
    # droop: a single 0.4 x 0.2 extrusion bead is ~0.08 mm^2, so the threshold
    # below is an eighth of the smallest thing a printer can lay down, and four
    # orders of magnitude under what the -D boss_hw negative control reports.
    # Any SINGLE facet over it fails, so this cannot swallow a real overhang.
    AREA_EPS = 0.01
    check(bad_area <= AREA_EPS and biggest <= AREA_EPS,
          f"{bad} facet(s), {bad_area:.3g} mm^2 total / {biggest:.3g} mm^2 "
          f"largest, face down past the rule (budget {AREA_EPS} mm^2 = 1/8 of "
          f"one extrusion bead); steepest downward facet nz {steep:.4f} at "
          f"z {steep_z:.2f}, the rule is {lim + 0.02:.4f}"
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
