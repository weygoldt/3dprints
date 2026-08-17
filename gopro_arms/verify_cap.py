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
from collections import Counter

from verify import load, bbox, near_axis, ray_intervals, normal, volume  # noqa: E402

# ---- spec (mirrors cap.scad) -----------------------------------------
PIPE_OD      = 12.00
PIPE_ID      =  9.90
PLUG_CREST_D =  9.95

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

# ---- two-part bungee cap (mirrors cap.scad) --------------------------
CORD_D     =  4.00
BODY_D     = 14.00
FLARE_H    =  6.00
LAND_H     = 15.00
THR_D      = 11.50
THR_PITCH  =  2.00
THR_SLOP   =  0.10
SOCK_THR_L =  8.50
BAY_D      = 12.00
BAY_L      =  6.50
SPIG_THR_L =  8.00
SPIG_W     =  1.00
DOME_L     = 20.00
DOME_W     =  1.40
RIM_W      =  0.60

THR_DEPTH  = 0.5412*THR_PITCH          # BOSL2's own profile
THR_MINOR  = THR_D - 2*THR_DEPTH
BODY_R     = BODY_D/2

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



# ---- the same parabola, solved on whichever base is asked for -------
# There are two domes now: the plain cap fairs the 12 mm tube, the bungee cap's
# dome fairs the 14 mm body it screws onto.  One implementation, solved twice.
def _pk_r(u, R):
    return R*(2*u - PARA_K*u*u)/(2 - PARA_K)


def _pk_m(u, R, L):
    return R*(2 - 2*PARA_K*u)/(L*(2 - PARA_K))


def _solve_nose(R, L, target, n=60):
    lo, hi = 0.0, 1.0
    for _ in range(n):
        mid = (lo + hi)/2
        if _pk_r(mid, R)*math.sqrt(1 + _pk_m(mid, R, L)**2) < target:
            lo = mid
        else:
            hi = mid
    u = (lo + hi)/2
    z0 = L*(1 - u)
    r0 = _pk_r(u, R)
    m = _pk_m(u, R, L)
    rho = r0*math.sqrt(1 + m*m)
    zc = z0 - r0*m
    return dict(u=u, z0=z0, r0=r0, m=m, rho=rho, zc=zc, h=zc + rho)


def _nose_r(z, R, L, s):
    """Radius of a nose of base R and nominal length L at height z above base."""
    if z <= s['z0']:
        return _pk_r((L - z)/L, R)
    dz = z - s['zc']
    return math.sqrt(max(0.0, s['rho']**2 - dz*dz))


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


def edge_incidence(tris):
    """Histogram of how many triangles share each edge.

    Every edge of a closed manifold surface has exactly two.  This is here
    because OpenSCAD exported a borecap with 239 edges shared by FOUR -- a ring
    of pinch points where the knot bay's top rim landed exactly on the funnel's
    bottom rim with zero overlap -- and reported "Status: NoError" and
    "manifold" on the way out.  The slicer eats the STL, not OpenSCAD's opinion
    of it, so the STL is what gets counted.
    """
    ec = Counter()
    for tri in tris:
        k = [tuple(p) for p in tri]
        for i in range(3):
            ec[frozenset((k[i], k[(i + 1) % 3]))] += 1
    return Counter(ec.values()), len(ec)


def euler_genus(tris):
    """(chi, genus) of the exported mesh.  Only meaningful if it is manifold."""
    V, ec = set(), set()
    for tri in tris:
        k = [tuple(p) for p in tri]
        for a in k:
            V.add(a)
        for i in range(3):
            ec.add(frozenset((k[i], k[(i + 1) % 3])))
    chi = len(V) - len(ec) + len(tris)
    return chi, (2 - chi)//2


def radial_profile(tris, z0, z1, step=0.05, x=EPS):
    """Inner and outer radius of a hollow solid of revolution, sampled in z.

    Returns [(z, inner, outer)], with inner/outer None where the ray misses.
    """
    slab = near_axis(tris, 0, x)
    out, z = [], z0
    while z <= z1 + 1e-9:
        iv = ray_intervals(slab, (x, -60.0, z), 1)
        pos = [(a - 60, b - 60) for a, b in iv if b - 60 > 0]
        out.append((z,
                    min((a for a, b in pos), default=None),
                    max((b for a, b in pos), default=None)))
        z += step
    return out


def biggest_sphere(prof, lo_z, hi_z, step=0.05):
    """Diameter of the largest sphere that fits inside a chamber profile.

    `prof` is a callable z -> free radius (0 where there is no void).  Brute
    force over centres, bisection on radius -- the chamber is only ~20 mm long
    so this is cheap, and it is the number that actually answers "will my knot
    go in".
    """
    best, best_z = 0.0, 0.0
    zc = lo_z
    while zc <= hi_z:
        a, b = 0.0, 10.0
        for _ in range(40):
            s = (a + b)/2
            ok = True
            zz = zc - s
            while zz <= zc + s:
                d2 = s*s - (zz - zc)**2
                if d2 > 0 and math.sqrt(d2) > prof(zz) + 1e-9:
                    ok = False
                    break
                zz += step
            if ok:
                a = s
            else:
                b = s
        if a > best:
            best, best_z = a, zc
        zc += step
    return 2*best, best_z


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
    ap.add_argument('--bore', action='store_true',
                    help="the bungee cap's anchor half")
    ap.add_argument('--dome', action='store_true',
                    help="the bungee cap's screw-on dome")
    ap.add_argument('--mate', metavar='DOME_STL',
                    help='pass the anchor as <stl> and the dome here: checks '
                         'that the threads fit and measures the assembled '
                         'knot chamber')
    args = ap.parse_args()

    tris = load(args.stl)
    lo, hi = bbox(tris)
    print(f"\n=== {args.stl}  ({len(tris)} facets)")
    print(f"bbox  X {lo[0]:7.3f}..{hi[0]:7.3f}   Y {lo[1]:7.3f}..{hi[1]:7.3f}"
          f"   Z {lo[2]:7.3f}..{hi[2]:7.3f}")

    if args.mate:
        return mate(tris, load(args.mate))
    if args.gauge:
        return gauge(tris, lo, hi)
    if args.bore:
        return borecap(tris, lo, hi)
    if args.dome:
        return domecap(tris, lo, hi)
    return cap(tris, lo, hi)


# =====================================================================
def shell_checks(tris, want_genus, what):
    """Every part gets these.  See edge_incidence() for why."""
    hist, ne = edge_incidence(tris)
    chi, g = euler_genus(tris)
    print(f"     {ne} edges, incidence {dict(hist)}, chi {chi}, genus {g}")
    check(set(hist) == {2},
          f"{what}: every edge shared by exactly two triangles "
          f"(got {dict(hist)}) -- anything else is a pinched, non-manifold mesh")
    check(g == want_genus,
          f"{what}: genus {g} == {want_genus} "
          f"({'a through bore' if want_genus else 'no through bore'})")



def overhang_report(tris, lo_z, allowed, name):
    """Down-facing area steeper than the budget, bucketed by named zone.

    `allowed` is {label: (z0, z1, cap_mm2, cap_deg)}.  cap_mm2 may be None,
    which means "report the area, gate on the ANGLE instead" -- that is the
    right shape of gate for a thread, where the underside flanks are 60 deg off
    the axis by definition of the profile and the area is simply however much
    thread there is.  What would actually be a bug there is a 90 deg ledge, and
    the angle cap catches that while an area budget would just be a number
    guessed to fit.  Anything steep OUTSIDE every named zone fails outright.

    Naming the exceptions is the point: "no overhangs" is not true of any part
    with a shoulder or a thread, and a gate that only prints the worst number
    teaches you nothing about whether it is the shoulder you designed or a wall
    you did not mean to lean over.
    """
    lim = math.sin(math.radians(OH_ANG + FACET_TOL))
    zones = {k: [0.0, 0.0] for k in allowed}
    stray, stray_worst, bed = 0.0, 0.0, 0.0
    for t in tris:
        n, a = normal(t)
        if n is None or n[2] >= -1e-6:
            continue
        if max(p[2] for p in t) < lo_z + 1e-4:
            bed += a
            continue
        ang = math.degrees(math.asin(min(1, -n[2])))
        z = min(p[2] for p in t)
        hit = None
        for k, (z0, z1, _, _a) in allowed.items():
            if z0 <= z <= z1:
                hit = k
                break
        if hit is None:
            zones  # noqa
            if -n[2] > lim:
                stray += a
            stray_worst = max(stray_worst, ang)
        else:
            zones[hit][1] = max(zones[hit][1], ang)
            if -n[2] > lim:
                zones[hit][0] += a
    print(f"     bed contact {bed:.1f} mm^2")
    for k, (ar, w) in zones.items():
        print(f"     {k:24s} {ar:7.2f} mm^2 unsupported, steepest {w:5.1f} deg")
    print(f"     {'anywhere else':24s} {stray:7.2f} mm^2 unsupported, "
          f"steepest {stray_worst:5.1f} deg")
    for k, (z0, z1, cap, cap_deg) in allowed.items():
        if cap is not None:
            check(zones[k][0] <= cap + 0.5,
                  f"{name}: {k} carries {zones[k][0]:.2f} mm^2 of overhang "
                  f"(budget {cap})")
        check(zones[k][1] <= cap_deg,
              f"{name}: {k} leans {zones[k][1]:.1f} deg, budget {cap_deg} "
              f"-- steeper than the profile allows means a ledge, not a flank")
    check(stray < 0.5,
          f"{name}: nothing outside the named zones is unsupported "
          f"({stray:.3f} mm^2)")
    check(stray_worst <= OH_ANG + FACET_TOL,
          f"{name}: steepest overhang away from those zones "
          f"{stray_worst:.1f} <= {OH_ANG} deg")
    return bed


def bore_geom():
    """Key z stations of the anchor cap, from the spec."""
    sz = seat_z(PLUG_CREST_D)
    flare0 = sz + COLLAR_H
    floor = flare0 + FLARE_H
    top = floor + LAND_H
    return sz, flare0, floor, top


def borecap(tris, lo, hi):
    sz, flare0, floor, top = bore_geom()
    print(f"\nspec: flare {flare0:.2f}..{flare0+FLARE_H:.2f} (12->{BODY_D}), "
          f"socket floor {floor:.2f}, rim {top:.2f}")

    print("\n[1] shell")
    shell_checks(tris, 1, "anchor cap")
    check(abs(hi[2] - top) < 0.03, f"rim face at {hi[2]:.3f} == {top:.3f}")
    rad = max(math.hypot(p[0], p[1]) for t in tris for p in t)
    check(abs(rad - BODY_R) < 0.02, f"greatest radius {rad:.3f} == {BODY_R}")

    prof = radial_profile(tris, 0.2, top - 0.1, 0.05)

    print("\n[2] it is still the same plug -- the gauge sizes this one too")
    crest = max((o for z, i, o in prof if z < sz - 0.6 and o), default=0)
    check(abs(crest - PLUG_CREST_D/2) < 0.03,
          f"rib crest {2*crest:.3f} == {PLUG_CREST_D}")

    print(f"\n[3] the 12 -> {BODY_D} cone -- what keeps the joint at the tube")
    print("    from being a forward-facing step")
    r0 = [o for z, i, o in prof if abs(z - flare0) < 0.06 and o]
    r1 = [o for z, i, o in prof if abs(z - (flare0 + FLARE_H)) < 0.06 and o]
    if r0 and r1:
        half = math.degrees(math.atan2(r1[0] - r0[0], FLARE_H))
        print(f"     {2*r0[0]:.3f} -> {2*r1[0]:.3f} over {FLARE_H} mm, "
              f"{half:.1f} deg half-angle")
        check(abs(2*r0[0] - PIPE_OD) < 0.05, f"cone starts at the tube's {PIPE_OD}")
        check(abs(2*r1[0] - BODY_D) < 0.05, f"and reaches {BODY_D}")
        check(half < 12, f"half-angle {half:.1f} deg is gentle enough to stay attached")

    print("\n[4] cord bore and the knot bay")
    cb = [i for z, i, o in prof if 3 < z < floor - 1 and i]
    if cb:
        print(f"     cord bore {2*min(cb):.3f} mm (want {CORD_D})")
        check(abs(2*min(cb) - CORD_D) < 0.08, f"cord bore == {CORD_D}")
    bay = [i for z, i, o in prof if floor + 0.3 < z < floor + BAY_L - 1.9 and i]
    if bay:
        print(f"     knot bay {2*max(bay):.3f} mm dia (want {BAY_D})")
        check(abs(2*max(bay) - BAY_D) < 0.08, f"bay == {BAY_D}")
        check(BAY_D > THR_MINOR + 1.0,
              f"the bay is wider than the thread's {THR_MINOR:.2f} minor, so the "
              f"knot drops clear of anything the dome sweeps")

    print("\n[5] the socket thread")
    thr = [i for z, i, o in prof if top - SOCK_THR_L + 0.4 < z < top - 0.3 and i]
    if thr:
        crestr, root = min(thr), max(thr)
        print(f"     crest r {crestr:.3f}, root r {root:.3f}, "
              f"depth {root - crestr:.3f}  (BOSL2 profile: {THR_DEPTH:.3f})")
        check(root - crestr > 0.8*THR_DEPTH,
              f"it is a real thread, depth {root-crestr:.3f} -- pre-boring to "
              f"the major diameter leaves a smooth hole with a 0.2 mm helical "
              f"scratch in it, and that still looks like a thread in a render")
        print(f"     entry choke {2*crestr:.3f} mm -- the knot is pushed past this")

    print(f"\n[6] printability -- and the thread is the interesting one")
    print("    (a 60 deg profile puts its underside flanks 60 deg off the axis,")
    print("     over the 45 deg budget.  That is true of EVERY vertical-axis")
    print("     thread, it is what thr_slop exists to absorb, and support is")
    print("     not the answer -- you could never get it out of an 11.5 bore)")
    bed = overhang_report(tris, 0.0, {
        "seat on the tube end": (sz - 0.2, sz + 0.2, 22.0, 90.1),
        "bay/funnel junction":  (floor + BAY_L - 2.0, top - SOCK_THR_L,
                                 1.0, 90.1),
        # area is however much thread there is; 62 deg is the profile's own
        # flank plus the helix's lead angle, and anything past it is a ledge
        "socket thread":        (top - SOCK_THR_L - 0.2, top + 0.1, None, 62.0),
    }, "anchor cap")
    print(f"     NOTE {top:.1f} mm tall on {bed:.0f} mm^2 of bed -- "
          f"the cord bore makes the footprint a RING.  Brim.")
    check(bed > 15, f"bed contact {bed:.1f} mm^2")
    return report()


def domecap(tris, lo, hi):
    print("\n[1] shell")
    shell_checks(tris, 0, "dome")
    check(abs(lo[2] + SPIG_THR_L) < 0.05, f"spigot ends at {lo[2]:.3f}")
    rad = max(math.hypot(p[0], p[1]) for t in tris for p in t)
    print(f"     greatest radius {rad:.3f}, height {hi[2]-lo[2]:.3f}, rim datum z=0")
    check(abs(rad - BODY_R) < 0.02, f"nothing proud of {BODY_D} ({rad:.3f})")

    print("\n[2] the dome is the same parabola, solved on the 14 mm base")
    s = _solve_nose(BODY_R, DOME_L, TIP_R)
    prof = radial_profile(tris, 0.05, hi[2] - 0.15, 0.05)
    worst, n = 0.0, 0
    for z, i, o in prof:
        if o is None:
            continue
        n += 1
        worst = max(worst, abs(o - _nose_r(z, BODY_R, DOME_L, s)))
    print(f"     height {hi[2]:.3f} (nominal {DOME_L}), {n} samples, "
          f"worst deviation {worst:.4f} mm")
    check(n > 300, f"the dome was actually sampled ({n} points)")
    check(worst < 0.03, f"dome matches the parabola to {worst:.4f} mm")
    seg = [(z, o) for z, i, o in prof if 0.05 <= z <= 1.0 and o]
    if len(seg) > 10:
        slope = (seg[0][1] - seg[-1][1])/(seg[-1][0] - seg[0][0])
        print(f"     |dr/dz| off the rim {slope:.4f} "
              f"(a cone would read {BODY_R/DOME_L:.4f})")
        check(slope < 0.05, f"dome leaves the {BODY_D} body tangent ({slope:.4f})")
        check(abs(seg[0][1] - BODY_R) < 0.03, "and flush with it")

    print("\n[3] the spigot thread -- and how much of it is really thread")
    full = radial_profile(tris, -SPIG_THR_L - 0.1, 0.0, 0.02)
    thr = [o for z, i, o in full if o and -SPIG_THR_L + 0.7 <= z <= -1.0]
    if thr:
        core, major = min(thr), max(thr)
        print(f"     core r {core:.3f}, major r {major:.3f}, depth {major-core:.3f}")
        check(abs(2*major - THR_D) < 0.10, f"major {2*major:.3f} == {THR_D}")
        check(major - core > 0.8*THR_DEPTH, f"depth {major-core:.3f} is a thread")
    # SPIG_THR_L is not the engagement.  The lead-in eats the bottom and the rim
    # chamfer buries the top, so count the band where the crests actually stand
    # at the major diameter -- dividing the nominal length by the pitch would
    # have called the first cut 2.25 turns when the part had about one.
    at_major = [z for z, i, o in full if o and o >= THR_D/2 - 0.06]
    if at_major:
        span = max(at_major) - min(at_major)
        turns = span/THR_PITCH
        print(f"     crests reach {THR_D/2:.2f} over z {min(at_major):+.2f}"
              f"..{max(at_major):+.2f} = {span:.2f} mm = {turns:.1f} full turns")
        check(turns >= 2.5,
              f"{turns:.1f} turns of real engagement -- nominal length over "
              f"pitch would have claimed {SPIG_THR_L/THR_PITCH:.1f}")
    check(SPIG_THR_L < SOCK_THR_L,
          f"spigot thread {SPIG_THR_L} is shorter than the socket's {SOCK_THR_L}, "
          f"so the RIM is the stop and the joint actually closes")

    print(f"\n[4] printability")
    print("    the hollow dome is the part that looks like it needs support and")
    print("    does not: the cavity follows the parabola in, so its ceiling")
    print("    never leans past ~32 deg")
    bed = overhang_report(tris, lo[2], {
        "spigot thread": (-SPIG_THR_L - 0.1, -0.9, None, 62.0),
        "rim seat":      (-0.01, 0.01, 26.0, 90.1),
    }, "dome")
    print(f"     NOTE {hi[2]-lo[2]:.1f} mm tall on {bed:.0f} mm^2 of bed -- the")
    print(f"     footprint is only the spigot's end ring.  BRIM IS NOT OPTIONAL.")
    check(bed > 10, f"bed contact {bed:.1f} mm^2")
    return report()


def mate(bore, dome):
    sz, flare0, floor, top = bore_geom()
    print("\n[1] do the threads actually fit each other?")
    fem = [i for z, i, o in radial_profile(bore, top - SOCK_THR_L + 0.4,
                                           top - 0.3, 0.04) if i]
    mal = [o for z, i, o in radial_profile(dome, -SPIG_THR_L + 0.7, -1.0, 0.04) if o]
    if fem and mal:
        f_crest, f_root = min(fem), max(fem)
        m_core, m_major = min(mal), max(mal)
        c_root = f_root - m_major
        c_crest = f_crest - m_core
        print(f"     female  crest {f_crest:.3f}  root  {f_root:.3f}")
        print(f"     male    core  {m_core:.3f}  major {m_major:.3f}")
        print(f"     clearance at the roots {c_root:+.3f}, at the crests "
              f"{c_crest:+.3f}   (4*slop = {4*THR_SLOP:.2f} diametral)")
        check(c_root > 0.02,
              f"male major clears the female root by {c_root:+.3f} mm -- "
              f"negative here and the two simply will not go together")
        check(c_crest > 0.02,
              f"female crest clears the male core by {c_crest:+.3f} mm")
        check(c_root < 0.45 and c_crest < 0.45,
              "and neither clearance is so big the joint rattles")

    print("\n[2] the outside has to be continuous across the joint")
    rb = max(math.hypot(p[0], p[1]) for t in bore for p in t)
    rd = max(math.hypot(p[0], p[1]) for t in dome for p in t)
    print(f"     anchor {2*rb:.3f} mm, dome rim {2*rd:.3f} mm")
    check(abs(rb - rd) < 0.05, f"no step at the joint ({2*rb:.3f} vs {2*rd:.3f})")

    print("\n[3] THE KNOT CHAMBER, measured off both meshes on the rim datum")
    tbl = {}
    for z, i, o in radial_profile(bore, floor - 0.2, top - 0.05, 0.05):
        if i is not None:
            tbl[round(z - top, 2)] = i
    for z, i, o in radial_profile(dome, -SPIG_THR_L + 0.05, -0.05, 0.05):
        if i is not None:                    # the spigot's bore wins where it is
            k = round(z, 2)
            tbl[k] = min(tbl.get(k, 99.0), i)
    zs = sorted(tbl)

    def R(z):
        if z < zs[0] or z > zs[-1]:
            return 0.0
        return tbl[min(zs, key=lambda a: abs(a - z))]

    dia, at = biggest_sphere(R, zs[0] + 0.2, zs[-1] - 0.2, 0.05)
    bay_zone = [tbl[z] for z in zs if z < -(SOCK_THR_L + 0.6)]
    choke = [tbl[z] for z in zs if -SOCK_THR_L < z < -0.4]
    print(f"     bay          {2*max(bay_zone):5.2f} mm dia")
    # Two different numbers and they answer different questions.  The knot is
    # pushed in with the dome OFF, so what it has to pass is the socket
    # thread's crest.  Once the dome is on, the spigot's bore is the narrowest
    # thing above the bay -- that is what bounds the sphere below, not entry.
    print(f"     entry, dome OFF   {THR_MINOR + 4*THR_SLOP:5.2f} mm  "
          f"(the socket thread's crests -- the knot is pushed past this)")
    print(f"     spigot bore       {2*min(choke):5.2f} mm  "
          f"(assembled; sits ABOVE the bay, so it caps the sphere not the entry)")
    print(f"     LARGEST SPHERE THAT FITS: {dia:.2f} mm, centred {at:+.2f} "
          f"from the rim")
    check(dia > 1.6*CORD_D,
          f"the chamber swallows a {dia:.2f} mm ball = {dia/CORD_D:.1f} cord "
          f"diameters, which is a tight overhand knot in {CORD_D} mm bungee")
    check(2*max(bay_zone) > THR_MINOR + 1.0,
          f"and the bay ({2*max(bay_zone):.2f}) is wider than the thread, so "
          f"the knot sits below everything the dome sweeps on its way down")
    return report()


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
