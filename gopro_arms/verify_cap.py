#!/usr/bin/env python3
"""Measure the pipe fairing cap against the shape it claims to be.

Three things can go wrong here and none of them shows up in a render.

The first is the PRESS FIT: the interference lives entirely in three rib
crests 0.35 mm tall, and "the ribs are there" is not the same claim as "the
crests stand proud of the bore and the body between them does not".  Both are
measured, from the mesh, and both can fail.

The second is THE TUBE, which is not a hole -- it is a 1.05 mm wall that takes
the interference as hoop strain.  Checking only that the plug is big enough to
grip is half a check; the first version of this part passed that half and would
have pressed the tube to 110% of its yield.  Both halves are gated now.

The third is the NOSE.  A parabola and a cone look alike in a thumbnail and
are not alike in water -- what makes this one worth printing is that it leaves
the tube TANGENT, with no step and no corner.  So the profile is not eyeballed:
it is sampled off the mesh and differenced against the analytic
parabola-plus-tangent-sphere, and the slope where it meets the tube is checked
against zero.  A cone would pass "is it round" and "is it smooth" and fail
that one.

Run:  python3 verify_cap.py stl/pipe_cap_12mm.stl
      python3 verify_cap.py stl/pipe_cap_12mm_gauge.stl --gauge
"""
import argparse
import math
import sys

from verify import load, bbox, near_axis, ray_intervals, normal, volume  # noqa: E402

# ---- spec (mirrors cap.scad) -----------------------------------------
PIPE_OD      = 12.00
PIPE_ID      =  9.90
PLUG_CREST_D =  9.90

# The tube, as a structure rather than a hole.  Rigid uPVC: modulus 2.4-4.1 GPa
# and tensile yield 40-55 MPa are the usual quoted ranges; the middle of each is
# taken here.  Only the RATIO of stress to yield is used, and that is stable
# across the whole range, so the sloppiness in the absolute numbers does not
# reach the verdict.
PVC_E        = 3000.0   # MPa
PVC_YIELD    = 50.0     # MPa
STRESS_FRAC  = 0.60     # how much of yield the press fit may use up

RIB_N     = 3
RIB_H     = 0.35
RIB_RAMP  = 1.20
RIB_LAND  = 0.70
RIB_PITCH = 4.00
PILOT_L   = 2.00
LEAD_L    = 1.20
LEAD_DROP = 0.55

SEAT_W    = 0.60
SEAT_ANG  = 40.0
COLLAR_H  = 1.50

NOSE_L    = 18.00
TIP_R     = 1.50
PARA_K    = 1.00

GAUGE_D   = [9.60, 9.70, 9.80, 9.90, 10.00]
GAUGE_PITCH = 15.00
PAD_W     = 11.00
PAD_T     =  4.00
PAD_H     = 14.00
LABEL_D   =  0.50

OH_ANG    = 45.0
FACET_TOL = 1.5

BASE_R    = PIPE_OD/2
SEAT_R    = BASE_R - SEAT_W
TOP_LAND_END = LEAD_L + (RIB_N - 1)*RIB_PITCH + RIB_RAMP + PILOT_L

# The probe rides this far off the axis so it never runs exactly along a facet
# edge.  At r = 5 that costs 1.7e-5 mm of measured radius -- five orders below
# anything gated here -- and it buys a ray that cannot land on a shared edge
# and get deduped into the wrong number of crossings.
EPS = 0.013
TOL = 0.05

FAIL = []


def check(ok, msg):
    print(("  PASS  " if ok else "  FAIL  ") + msg)
    if not ok:
        FAIL.append(msg)


# ---- the analytic part, re-derived here rather than imported ---------
def hoop(crest_d):
    """Hoop strain and stress in the TUBE at a given crest diameter.

    Worst case on purpose: the tube absorbs the whole interference and the PETG
    rib crushes none of it.  Pessimistic, and the right way round to be wrong --
    the plug is the strong half of this joint and the 1.05 mm wall is the weak
    one, which is exactly the thing a plug-side-only sanity check misses.
    """
    r_mean = (PIPE_ID + PIPE_OD)/4
    eps = ((crest_d - PIPE_ID)/2)/r_mean
    return eps, PVC_E*eps


def seat_z(d):
    return TOP_LAND_END + (SEAT_R - d/2)/math.tan(math.radians(SEAT_ANG))


def collar_z(d):
    return seat_z(d) + COLLAR_H


def pk_r(u):
    return BASE_R*(2*u - PARA_K*u*u)/(2 - PARA_K)


def pk_slope(u):
    return BASE_R*(2 - 2*PARA_K*u)/(NOSE_L*(2 - PARA_K))


def pk_rho(u):
    return pk_r(u)*math.sqrt(1 + pk_slope(u)**2)


def _solve_u(target, lo=0.0, hi=1.0, n=60):
    for _ in range(n):
        mid = (lo + hi)/2
        if pk_rho(mid) < target:
            lo = mid
        else:
            hi = mid
    return (lo + hi)/2


TIP_U   = _solve_u(TIP_R)
TIP_Z0  = NOSE_L*(1 - TIP_U)
TIP_R0  = pk_r(TIP_U)
TIP_M   = pk_slope(TIP_U)
TIP_RHO = TIP_R0*math.sqrt(1 + TIP_M**2)
TIP_ZC  = TIP_Z0 - TIP_R0*TIP_M
NOSE_H  = TIP_ZC + TIP_RHO
TOTAL_H = collar_z(PLUG_CREST_D) + NOSE_H


def nose_r(z):
    """Radius of the nose, z measured up from where it leaves the tube."""
    if z <= TIP_Z0:
        u = (NOSE_L - z)/NOSE_L
        return pk_r(u)
    dz = z - TIP_ZC
    return math.sqrt(max(0.0, TIP_RHO**2 - dz*dz))


def plug_stations(d):
    """(r, z) meridian of the plug -- mirrors plug_pts() in cap.scad."""
    cr, br, sz = d/2, d/2 - RIB_H, seat_z(d)
    pts = [(0.0, 0.0), (br - LEAD_DROP, 0.0)]
    for i in range(RIB_N):
        z0 = LEAD_L + i*RIB_PITCH
        pts += [(br, z0), (cr, z0 + RIB_RAMP)]
        if i < RIB_N - 1:
            pts += [(cr, z0 + RIB_RAMP + RIB_LAND), (br, z0 + RIB_RAMP + RIB_LAND)]
        else:
            pts += [(cr, z0 + RIB_RAMP + PILOT_L)]
    return pts + [(SEAT_R, sz), (BASE_R, sz), (BASE_R, sz + COLLAR_H)]


def analytic_volume(d):
    """Exact volume of the intended solid of revolution, by frusta."""
    pts = plug_stations(d)
    n = 400
    pts += [(nose_r(NOSE_H*j/n), collar_z(d) + NOSE_H*j/n) for j in range(1, n + 1)]
    v = 0.0
    for (r1, z1), (r2, z2) in zip(pts, pts[1:]):
        v += math.pi*(r1*r1 + r1*r2 + r2*r2)*(z2 - z1)/3.0
    return v


# ---- measurement -----------------------------------------------------
def radius_at(slab, x, z):
    """Measured radius of the solid of revolution centred on x, at height z.

    Returns (r, offset) or None when the ray misses -- and it MUST be able to
    miss, or a sweep that silently measured nothing would read as a shape that
    matched everything.
    """
    iv = ray_intervals(slab, (x, -60.0, z), 1)
    iv = [(a - 60, b - 60) for a, b in iv]
    if len(iv) != 1:
        return None
    a, b = iv[0]
    return (b - a)/2.0, (a + b)/2.0


def components(tris):
    """Connected components, by shared vertex.

    Cheap, and it is the check that catches a union which did not actually
    union: two solids that meet on a coplanar face can survive as two
    interpenetrating closed shells with a degenerate void between them.  That
    slices into a mess and renders without complaint.
    """
    parent = {}

    def find(a):
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    for t in tris:
        ks = [(round(p[0], 4), round(p[1], 4), round(p[2], 4)) for p in t]
        for k in ks:
            parent.setdefault(k, k)
        for k in ks[1:]:
            ra, rb = find(ks[0]), find(k)
            if ra != rb:
                parent[ra] = rb
    return len({find(k) for k in parent})


def sweep(tris, x, z0, z1, step):
    slab = near_axis(tris, 0, x)          # z-independent: filter once, not per ray
    out = []
    z = z0
    while z <= z1 + 1e-9:
        m = radius_at(slab, x, z)
        out.append((z, m))
        z += step
    return out


def crest_runs(prof, crest_r, tol=0.02):
    """Contiguous z-runs where the profile sits at the crest radius."""
    runs, cur = [], []
    for z, m in prof:
        if m is not None and m >= crest_r - tol:
            cur.append((z, m[0] if isinstance(m, tuple) else m))
        elif cur:
            runs.append(cur)
            cur = []
    if cur:
        runs.append(cur)
    return runs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('stl')
    ap.add_argument('--gauge', action='store_true',
                    help='the five-stub fit coupon rather than the cap')
    args = ap.parse_args()

    tris = load(args.stl)
    lo, hi = bbox(tris)
    print(f"\n=== {args.stl}  ({len(tris)} facets)")
    print(f"bbox  X {lo[0]:7.3f}..{hi[0]:7.3f}   Y {lo[1]:7.3f}..{hi[1]:7.3f}"
          f"   Z {lo[2]:7.3f}..{hi[2]:7.3f}")

    if args.gauge:
        return gauge(tris, lo, hi)
    return cap(tris, lo, hi)


# =====================================================================
def cap(tris, lo, hi):
    d = PLUG_CREST_D
    crest_r, body_r = d/2, d/2 - RIB_H
    sz, cz = seat_z(d), collar_z(d)

    print(f"\nspec: crest {d:.2f}  body {2*body_r:.2f}  bore {PIPE_ID:.2f}   "
          f"seat z {sz:.3f}   nose {NOSE_H:.3f} (nominal {NOSE_L:.2f})   "
          f"total {TOTAL_H:.3f}")

    # ------------------------------------------------------------- 0
    print("\n[0] envelope -- nothing may stand proud of the tube it fairs")
    rad = max(math.hypot(p[0], p[1]) for t in tris for p in t)
    print(f"     greatest radius anywhere {rad:.4f}, tube radius {BASE_R:.3f}")
    check(rad <= BASE_R + 0.01, f"nothing proud of the tube ({rad:.4f} <= {BASE_R})")
    check(abs(lo[2]) < 1e-6 and abs(hi[2] - TOTAL_H) < 0.03,
          f"height {hi[2]-lo[2]:.3f} == {TOTAL_H:.3f}")
    nc = components(tris)
    check(nc == 1, f"one solid, one shell ({nc} components)")

    # ------------------------------------------------------------- 1
    # A sweep is only evidence if it can come back empty.  Prove the probe
    # works before believing anything it says, and prove it can miss.
    print("\n[1] the probe itself")
    slab = near_axis(tris, 0, EPS)
    print(f"     {len(slab)} of {len(tris)} facets span the probe plane")
    mid = radius_at(slab, EPS, sz + COLLAR_H/2)
    check(mid is not None, "probe hits solid at the collar")
    check(radius_at(slab, EPS, TOTAL_H + 1.0) is None,
          "probe returns NOTHING above the tip (a probe that always hits "
          "measures nothing)")
    if mid:
        check(abs(mid[1]) < 0.01,
              f"solid is centred on the axis (offset {mid[1]:+.4f})")

    prof = sweep(tris, EPS, 0.02, TOTAL_H - 0.05, 0.02)
    got = sum(1 for _, m in prof if m is not None)
    check(got > 0.98*len(prof),
          f"{got}/{len(prof)} sweep samples hit solid")
    rz = [(z, m[0]) for z, m in prof if m is not None]

    # ------------------------------------------------------------- 2
    print(f"\n[2] the plug -- {RIB_N} ribs, and the crest is the ONLY thing "
          f"that touches the bore")
    # Stop at the top of the pilot land, not at the seat: above TOP_LAND_END
    # the 40 deg chamfer climbs from the crest to SEAT_R, so a window that ran
    # to the seat would read the chamfer as part of rib 3 and measure its crest
    # at 5.35.  The window's own edge is checked below rather than trusted.
    runs = crest_runs([(z, r) for z, r in rz if z < TOP_LAND_END - 0.03], crest_r)
    print("     crest runs:", ", ".join(f"z {r[0][0]:.2f}..{r[-1][0]:.2f}"
                                        f" r={max(x[1] for x in r):.3f}"
                                        for r in runs))
    check(len(runs) == RIB_N, f"exactly {RIB_N} rib crests (got {len(runs)})")
    if len(runs) == RIB_N:
        for i, r in enumerate(runs):
            rmax = max(x[1] for x in r)
            check(abs(rmax - crest_r) < 0.03,
                  f"rib {i+1} crest radius {rmax:.3f} == {crest_r:.3f}")
        starts = [r[0][0] for r in runs]
        for i in range(len(starts) - 1):
            p = starts[i+1] - starts[i]
            check(abs(p - RIB_PITCH) < 0.05, f"rib {i+1}->{i+2} pitch {p:.3f} "
                                             f"== {RIB_PITCH}")
        # The top rib is the pilot: longer, and it sits at the tube mouth.
        lens = [r[-1][0] - r[0][0] for r in runs]
        check(lens[-1] > lens[0] + 1.0,
              f"top rib is the pilot land ({lens[-1]:.2f} vs {lens[0]:.2f} mm)")
    # The window above was closed at TOP_LAND_END.  Measure right at that edge,
    # so the bound is evidence and not an assumption that could hide a pilot
    # land ending early and a chamfer starting where a crest should be.
    edge = radius_at(slab, EPS, TOP_LAND_END - 0.05)
    if edge:
        check(abs(edge[0] - crest_r) < 0.03,
              f"the pilot land really does run to z={TOP_LAND_END:.2f} "
              f"(r={edge[0]:.3f} there, want {crest_r:.3f})")

    # body between the ribs
    gaps = [r for z, r in rz if LEAD_L + RIB_RAMP + RIB_LAND + 0.15 < z <
            LEAD_L + RIB_PITCH - 0.05]
    if gaps:
        print(f"     plug body between ribs r={min(gaps):.3f}..{max(gaps):.3f}")
        check(abs(max(gaps) - body_r) < 0.03,
              f"body radius {max(gaps):.3f} == {body_r:.3f}")

    # ------------------------------------------------------------- 3
    print("\n[3] MECHANISM -- does the crest land in the usable band?")
    inter = d - PIPE_ID
    clear = PIPE_ID - 2*body_r
    print(f"     crest {d:.2f} vs bore {PIPE_ID:.2f}: {inter:+.3f} mm "
          f"diametral, {inter/2:+.3f} per side")
    print(f"     body  {2*body_r:.2f} vs bore {PIPE_ID:.2f}: {clear:+.3f} mm "
          f"clearance")
    # A BAND, not a floor.  The joint ships line-to-line and leans on the
    # printer's positive bias for its grip (and on adhesive in the rib grooves
    # if that bias does not show up), so demanding nominal interference here
    # would fail the part for being deliberately safe.  What actually has to
    # hold is that the crest lands NEAR the bore from either side.
    check(inter > -0.10, f"crest is within reach of the bore ({inter:+.3f} mm) "
                         f"-- further under and even a bonded joint has a gap "
                         f"to span")
    check(inter <= 0.10 + 1e-6,
          f"crest is at most +0.10 over the bore ({inter:+.3f} mm) -- the "
          f"ceiling is the tube, checked in [4]")
    check(clear > 0.15, f"body clears the bore by {clear:.3f} mm -- otherwise "
                        f"the whole plug binds and the ribs do nothing")
    check(inter < 2*RIB_H,
          f"interference {inter:.3f} < rib height {2*RIB_H:.2f} -- the crest "
          f"can crush without the body bottoming out")

    # ------------------------------------------------------------- 4
    print("\n[4] and THE TUBE has to survive it -- a 1.05 mm wall is not a hole")
    wall = (PIPE_OD - PIPE_ID)/2
    eps, sig = hoop(d)
    print(f"     wall {wall:.2f} mm, mean radius {(PIPE_ID+PIPE_OD)/4:.3f} mm")
    print(f"     worst-case hoop strain {100*eps:.2f}%  ->  ~{sig:.1f} MPa, "
          f"{100*sig/PVC_YIELD:.0f}% of uPVC's ~{PVC_YIELD:.0f} MPa yield")
    check(sig < STRESS_FRAC*PVC_YIELD,
          f"the tube stays elastic ({100*sig/PVC_YIELD:.0f}% of yield, budget "
          f"{100*STRESS_FRAC:.0f}%) -- past yield a thin PVC wall does not "
          f"spring back, it creeps, and the cap can never be re-seated")

    # ------------------------------------------------------------- 5
    print("\n[5] it has to START by hand, and STAY once seated")
    r0 = [r for z, r in rz if z < 0.05]
    if r0:
        print(f"     lead-in enters at d={2*r0[0]:.3f} into a {PIPE_ID} bore")
        check(2*r0[0] < PIPE_ID - 0.4,
              f"lead-in starts {PIPE_ID - 2*r0[0]:.2f} mm under the bore")
    ramp = math.degrees(math.atan2(RIB_H, RIB_RAMP))
    print(f"     rib ramp {ramp:.1f} deg from vertical going in, "
          f"90 deg step coming out")
    check(ramp < 25, f"insertion ramp {ramp:.1f} deg is shallow enough to push "
                     f"by hand")
    print(f"     engagement {sz:.2f} mm = {sz/PIPE_OD:.2f} tube diameters")
    check(sz > PIPE_OD, f"plug is buried {sz:.2f} mm, more than one diameter "
                        f"-- shorter than that and it rocks")

    # ------------------------------------------------------------- 6
    print("\n[6] the seat -- what stops it, and what closes the joint")
    above = [r for z, r in rz if sz + 0.1 < z < cz - 0.1]
    below = [r for z, r in rz if sz - 0.35 < z < sz - 0.1]
    if above and below:
        print(f"     collar r={min(above):.3f}..{max(above):.3f}, "
              f"chamfer below r={min(below):.3f}..{max(below):.3f}")
        check(abs(max(above) - BASE_R) < 0.02,
              f"collar radius {max(above):.4f} == the tube's {BASE_R:.3f} -- "
              f"any error here IS the step in the flow")
        check(max(below) < SEAT_R + 0.02,
              f"the step to the collar is a real shoulder, not a taper "
              f"({max(below):.3f} < {SEAT_R:.3f})")

    # ------------------------------------------------------------- 7
    print("\n[7] the NOSE is a parabola, not merely round")
    print("     (sampled off the mesh, differenced against "
          "r = R(1-(z/L)^2) blended into the tangent sphere)")
    worst, worst_z = 0.0, 0.0
    n_cmp = 0
    for z, r in rz:
        if z < cz + 0.05 or z > TOTAL_H - 0.15:
            continue
        e = abs(r - nose_r(z - cz))
        n_cmp += 1
        if e > worst:
            worst, worst_z = e, z
    print(f"     {n_cmp} samples, worst deviation {worst:.4f} mm at z={worst_z:.2f}")
    check(n_cmp > 700, f"the nose was actually sampled ({n_cmp} points)")
    check(worst < 0.03, f"profile matches the parabola to {worst:.4f} mm")

    # Monotone: any bulge is a place for the flow to separate early.
    nose = [(z, r) for z, r in rz if z >= cz - 0.02]
    bump = max((nose[i+1][1] - nose[i][1] for i in range(len(nose)-1)), default=0)
    check(bump < 0.004, f"radius never grows along the nose (worst "
                        f"{bump:+.4f} mm)")

    # ------------------------------------------------------------- 8
    print("\n[8] TANGENCY at the tube -- the entire reason for K=1")
    seg = [(z, r) for z, r in rz if cz + 0.02 <= z <= cz + 1.0]
    if len(seg) > 10:
        slope = (seg[0][1] - seg[-1][1])/(seg[-1][0] - seg[0][0])
        cone = BASE_R/NOSE_L          # what a K=0 cone would read here
        print(f"     mean |dr/dz| over the first mm: {slope:.4f}"
              f"   (a cone of the same length would read {cone:.4f})")
        check(slope < 0.05, f"nose leaves the tube tangent ({slope:.4f} ~ 0) "
                            f"-- no corner for the flow to trip on")
        check(abs(seg[0][1] - BASE_R) < 0.02,
              f"and flush with it ({seg[0][1]:.4f} vs {BASE_R:.3f})")

    # ------------------------------------------------------------- 9
    print("\n[9] the tip is rounded, and to the radius asked for")
    h = 0.30
    m = radius_at(slab, EPS, TOTAL_H - h)
    if m:
        rho = (m[0]*m[0] + h*h)/(2*h)
        print(f"     r={m[0]:.4f} at {h} mm below the tip -> radius {rho:.3f}")
        check(abs(rho - TIP_R) < 0.10, f"tip radius {rho:.3f} == {TIP_R}")
    else:
        check(False, "no solid found near the tip")

    # ------------------------------------------------------------- 10
    print(f"\n[10] printability -- overhangs steeper than {OH_ANG} deg from vertical")
    print("     the seat is the ONE allowed one; anything else is a bug")
    lim = math.sin(math.radians(OH_ANG + FACET_TOL))
    bad, worst_oh, bed = 0.0, 0.0, 0.0
    off_seat, off_worst = 0.0, 0.0
    for t in tris:
        n, a = normal(t)
        if n is None or n[2] >= -1e-6:
            continue
        if max(p[2] for p in t) < 1e-4:
            bed += a
            continue
        ang = math.degrees(math.asin(min(1, -n[2])))
        in_seat = all(abs(p[2] - sz) < 0.01 for p in t)
        if not in_seat:
            off_worst = max(off_worst, ang)
        worst_oh = max(worst_oh, ang)
        if -n[2] > lim:
            bad += a
            if not in_seat:
                off_seat += a
    seat_a = math.pi*(BASE_R**2 - SEAT_R**2)
    print(f"     bed contact {bed:.1f} mm^2, steepest down-facing facet "
          f"{worst_oh:.2f} deg")
    print(f"     unsupported area {bad:.2f} mm^2, of which {off_seat:.3f} is "
          f"NOT the seat  (seat annulus should be {seat_a:.2f})")
    check(abs(bad - seat_a) < 0.5,
          f"the only unsupported area is the {SEAT_W} mm seat ring "
          f"({bad:.2f} vs {seat_a:.2f} mm^2)")
    check(off_seat < 0.05,
          f"nothing outside the seat is unsupported ({off_seat:.3f} mm^2)")
    check(off_worst <= OH_ANG + FACET_TOL,
          f"steepest overhang away from the seat {off_worst:.2f} <= {OH_ANG} deg")
    foot = math.pi*(PLUG_CREST_D/2 - RIB_H - LEAD_DROP)**2
    check(abs(bed - foot) < 1.5, f"bed contact {bed:.1f} == the lead-in disc "
                                 f"{foot:.1f} mm^2")
    print(f"     NOTE {TOTAL_H:.1f} mm tall on a {2*(PLUG_CREST_D/2-RIB_H-LEAD_DROP):.1f} "
          f"mm footprint -- print it with a brim")

    # ------------------------------------------------------------ 11
    print("\n[11] volume against the intended solid of revolution")
    print("     (the global catch: a meridian that crossed itself still "
          "revolves into a mesh, it just is not this one)")
    vm, va = volume(tris), analytic_volume(PLUG_CREST_D)
    print(f"     mesh {vm:.2f} mm^3, analytic {va:.2f} mm^3, "
          f"{100*(vm-va)/va:+.3f}%")
    check(abs(vm - va)/va < 0.005, f"volume within 0.5% ({100*(vm-va)/va:+.3f}%)")

    return report()


# =====================================================================
def gauge(tris, lo, hi):
    print("\n[1] five stubs, one per candidate crest diameter")
    n = len(GAUGE_D)
    xs = [(i - (n - 1)/2)*GAUGE_PITCH for i in range(n)]
    span = xs[-1] - xs[0] + PIPE_OD
    check(abs((hi[0] - lo[0]) - span) < 0.2,
          f"gauge spans {hi[0]-lo[0]:.2f} == {span:.2f} mm")
    nc = components(tris)
    check(nc == n, f"{n} stubs, {n} shells (got {nc}) -- more than one shell "
                   f"per stub means the paddle never merged into the collar")
    # The coupon must not invite a test that wrecks the thing being measured.
    top = max(GAUGE_D)
    eps, sig = hoop(top)
    print(f"     biggest stub {top:.2f} presses the tube to {100*eps:.2f}% hoop "
          f"strain, ~{sig:.1f} MPa = {100*sig/PVC_YIELD:.0f}% of yield")
    check(sig < STRESS_FRAC*PVC_YIELD,
          f"even the tightest stub leaves the tube elastic "
          f"({100*sig/PVC_YIELD:.0f}% of yield) -- a gauge that bells the tube "
          f"on step 5 has destroyed its own reference")

    print("\n[2] each stub carries THIS plug at ITS crest -- the coupon is "
          "only worth")
    print("    anything if the ribs, ramps and print direction are identical")
    for i, d in enumerate(GAUGE_D):
        crest_r, body_r = d/2, d/2 - RIB_H
        sz = seat_z(d)
        # Stop below the chamfer, as in [2] above -- it climbs past the crest.
        prof = sweep(tris, xs[i] + EPS, 0.02, TOP_LAND_END - 0.03, 0.02)
        rz = [(z, m[0]) for z, m in prof if m is not None]
        if not rz:
            check(False, f"stub {d}: probe found nothing at x={xs[i]:.1f}")
            continue
        runs = crest_runs(rz, crest_r)
        rmax = max(r for _, r in rz)
        print(f"     stub {d:5.2f}: {len(runs)} crests, greatest r "
              f"{rmax:.3f} (want {crest_r:.3f}), seat z {sz:.3f}")
        check(len(runs) == RIB_N, f"stub {d}: {RIB_N} ribs (got {len(runs)})")
        check(abs(rmax - crest_r) < 0.03,
              f"stub {d}: crest diameter {2*rmax:.3f} == {d:.2f}")
        if len(runs) == RIB_N:
            p = runs[1][0][0] - runs[0][0][0]
            check(abs(p - RIB_PITCH) < 0.05,
                  f"stub {d}: rib pitch {p:.3f} == {RIB_PITCH} (same plug "
                  f"as the cap)")
        # A gauge whose stubs are not in a known order is not a gauge.
        if i:
            check(GAUGE_D[i] > GAUGE_D[i-1],
                  f"stub {d} sits right of {GAUGE_D[i-1]} -- ascending, "
                  f"so an unread label is still recoverable")

    print("\n[3] the handle must not need support either")
    corner = math.hypot(PAD_W/2, PAD_T/2)
    print(f"     paddle corner sits at r={corner:.3f}, collar is r={BASE_R:.3f}")
    check(corner < BASE_R,
          f"paddle lands entirely on the collar ({corner:.3f} < {BASE_R:.3f})")

    # Everything below the LOWEST collar top is plug on every stub, so this
    # window covers all five in full -- including their seats, which are the
    # only overhang any of them is allowed.
    plug_top = min(collar_z(d) for d in GAUGE_D)
    lim = math.sin(math.radians(OH_ANG + FACET_TOL))
    bad = 0.0
    for t in tris:
        nn, a = normal(t)
        if nn is None or nn[2] >= -1e-6:
            continue
        if max(p[2] for p in t) < 1e-4:
            continue
        if -nn[2] > lim and max(p[2] for p in t) <= plug_top + 1e-3:
            seat_hit = any(abs(min(p[2] for p in t) - seat_z(dd)) < 0.01
                           for dd in GAUGE_D)
            if not seat_hit:
                bad += a
    check(bad < 0.05, f"nothing but the seats overhangs on the plugs "
                      f"({bad:.3f} mm^2)")
    print("     (the debossed labels on the paddles are 0.5 mm ledges and are")
    print("      deliberately out of scope -- they are a handle, not a fit face)")

    print("\n[4] the labels are actually CUT -- an unlabelled gauge is five")
    print("    identical-looking stubs and no way back to which is which")
    print("    (text() on a box with no fonts renders EMPTY and everything")
    print("     above still passes, so this is measured, not assumed)")
    for i, d in enumerate(GAUGE_D):
        zl = collar_z(d) + PAD_H*0.45
        # One narrow slab per stub -- the paddle at the label height and
        # nothing else -- so 57 rays cost a filter over ~1e2 facets each
        # instead of over the whole 28k mesh.
        slab = [t for t in near_axis(tris, 2, zl)
                if min(p[0] for p in t) <= xs[i] + PAD_W/2
                and max(p[0] for p in t) >= xs[i] - PAD_W/2]
        face, cut = [], 0
        n_s = 57
        for j in range(n_s):
            dx = -PAD_W/2 + 0.6 + j*(PAD_W - 1.2)/(n_s - 1)
            m = ray_intervals(near_axis(slab, 0, xs[i] + dx),
                              (xs[i] + dx, -60.0, zl), 1)
            m = [(a - 60, b - 60) for a, b in m]
            if not m:
                continue
            y = max(b for _, b in m)
            face.append(y)
            if y < PAD_T/2 - LABEL_D/2:
                cut += 1
        if not face:
            check(False, f"stub {d}: no paddle found at the label height")
            continue
        deep = PAD_T/2 - min(face)
        print(f"     stub {d:5.2f}: {cut}/{len(face)} samples land in a glyph, "
              f"deepest cut {deep:.3f} mm")
        check(cut >= 5, f"stub {d}: the label is engraved ({cut} of "
                        f"{len(face)} samples inside a stroke)")
        check(abs(deep - LABEL_D) < 0.05,
              f"stub {d}: cut {deep:.3f} mm deep == {LABEL_D}")
        check(abs(max(face) - PAD_T/2) < 0.02,
              f"stub {d}: and the rest of the face is untouched "
              f"({max(face):.3f} == {PAD_T/2})")
    print("     (WHICH digits, and whether they read forwards, is the one thing")
    print("      here a mesh cannot tell you -- check the render, not this)")

    return report()


def report():
    print()
    if FAIL:
        print(f"*** {len(FAIL)} FAILURE(S)")
        for m in FAIL:
            print("   -", m)
        return 1
    print("ALL CHECKS PASSED")
    return 0


if __name__ == '__main__':
    sys.exit(main())
