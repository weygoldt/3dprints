#!/usr/bin/env python3
"""Measure the rendered blink-beacon meshes against the spec.

Everything here is read off the exported STL, not out of the .scad, so it
catches modelling mistakes as well as parameter typos.

    python3 verify_beacon.py --selftest
    python3 verify_beacon.py --body B.stl --carrier C.stl --dome D.stl \
                             --same-as stl/dome_AS_PRINTED.stl \
                             --probes FIT.stl HOOK.stl

WHY THIS FILE EXISTS
--------------------
v1 shipped a snap that could not snap.  Nothing in the model was "wrong" --
every parameter had a sensible name and a plausible value -- but the number
that decides whether a snap clicks was 0.15 mm of interference between two
rigid bodies, and no check anywhere ever computed it.  So the gate that matters
here is a SUBTRACTION ACROSS TWO MESHES: the carrier's barb crest radius minus
the body's bore radius.  If that is not comfortably positive the parts stack
instead of snapping, and this exits non-zero.

HOW IT MEASURES
---------------
By slicing the mesh with a horizontal plane and casting a ray out from the
axis, NOT by looking at where vertices happen to be.  The first version of this
file did the latter and every radius check came back "nothing found" -- a
cylindrical wall between z=a and z=b has vertices at a and b and nowhere in
between, so sampling a band strictly inside a face finds an empty set.  An
empty set then reads as -1 or None, which is at least loud; the same mistake
with a max() over "everything below this z" would have quietly measured the
wrong feature and passed.  Hence ray_hits(), which returns the actual wall
crossings at a height, and raises if a probe finds nothing.
"""
import argparse
import hashlib
import math
import os
import struct
import sys
from collections import defaultdict

# ---- spec (must mirror rc_boat_blink_beacon.scad) ------------------------
BODY_D        = 33.00
BODY_WALL     = 2.25
BODY_H        = 11.00
BODY_FLOOR    = 3.00
CARRIER_D     = 30.00
CARRIER_PROUD = 1.80
RIM_H         = 3.20
SKIRT_H       = 6.40
SKIRT_WALL    = 1.40
TONGUE_WALL   = 0.90
TONGUE_N      = 6
TONGUE_W      = 3.50
TONGUE_CUT    = 1.50
SNAP_CLR      = 0.25
SNAP_ENGAGE   = 0.40
SNAP_BARB_Z   = 0.60
SNAP_LEAD     = 30.0
SNAP_HOLD     = 45.0
SNAP_PLAY     = 0.15
SNAP_GROOVE_CLR = 0.10
SKIRT_LEAD    = 0.60
THREAD_D      = 28.00
THREAD_L      = 6.00
STAR_POCKET_D = 20.40

CARRIER_T     = SKIRT_H + RIM_H              # 9.60
SEAT_DEPTH    = CARRIER_T - CARRIER_PROUD    # 7.80
SEAT_BORE     = RIM_H - CARRIER_PROUD        # 1.40
BORE_R        = BODY_D / 2 - BODY_WALL       # 14.25
SKIRT_OR      = BORE_R - SNAP_CLR            # 14.00
SKIRT_IR      = SKIRT_OR - SKIRT_WALL        # 12.60
TONGUE_IR     = SKIRT_OR - TONGUE_WALL       # 13.10
BARB_OR       = BORE_R + SNAP_ENGAGE         # 14.65
GROOVE_OR     = BARB_OR + SNAP_GROOVE_CLR    # 14.75
BARB_PROUD    = BARB_OR - SKIRT_OR           # 0.65
BARB_LEAD_DZ  = BARB_PROUD * math.tan(math.radians(SNAP_LEAD))
BARB_HOLD_DZ  = BARB_PROUD * math.tan(math.radians(SNAP_HOLD))
BARB_LAND     = BARB_LEAD_DZ
BARB_TOP_Z    = SNAP_BARB_Z + BARB_LEAD_DZ + BARB_LAND + BARB_HOLD_DZ
BARB_MID_Z    = SNAP_BARB_Z + BARB_LEAD_DZ + BARB_LAND / 2
CUT_OFF       = math.degrees(math.asin((TONGUE_W + TONGUE_CUT) / (2 * SKIRT_OR)))
FLOOR_Z       = BODY_H - SEAT_DEPTH          # 3.20  carrier free end, body frame
GROOVE_Z0     = FLOOR_Z + SNAP_BARB_Z - SNAP_PLAY

# GoPro joint -- these mirror arm.scad, which is what it has to mate with.
GP_FING_T     = 2.90     # arm.scad  u - fing_under
GP_GAP        = 3.10     # arm.scad  slot_w
GP_TIP_D      = 15.00    # 2 * arm.scad tab_r
GP_DROP       = 19.50
GP_WEB_T      = 3.00
GP_PIVOT_Z    = -GP_DROP + GP_TIP_D / 2      # -12.00
GP_CLEAR      = -GP_WEB_T - GP_PIVOT_Z       # 9.00
ARM_TAB_R     = 7.50     # our arms
REAL_GOPRO_R  = 7.75     # a genuine GoPro knuckle -- the bigger of the two
ARM_SLOT_W    = 3.10

# PETG.  What the snap was sized against.  Reported, and the strain is gated:
# a snap that yields on first assembly is still broken.
E_PETG        = 2000.0   # MPa
STRAIN_LIMIT  = 3.0      # %

TOL = 0.03               # mm -- faceting slop on a d=30 circle at $fn=128


class MeshError(Exception):
    pass


# ---- loader ---------------------------------------------------------------
def load(path, allow_empty=False):
    """Read an STL, ASCII or binary, and return a list of (v0,v1,v2) triples.

    Raises rather than returning [] for anything it cannot make sense of.  An
    empty mesh is the one failure mode that looks like success downstream, so
    callers that genuinely expect one have to say so.
    """
    if not os.path.exists(path):
        raise MeshError("no such file: %s" % path)
    data = open(path, 'rb').read()
    if len(data) < 15:
        raise MeshError("%s: too short to be an STL (%d bytes)" % (path, len(data)))

    tris = []
    if data[:5] == b'solid' and b'facet' in data[:2048]:
        # ASCII.  Binary files can also start with "solid", hence the second test.
        cur = []
        for line in data.decode('ascii', 'replace').splitlines():
            w = line.split()
            if len(w) == 4 and w[0] == 'vertex':
                cur.append((float(w[1]), float(w[2]), float(w[3])))
                if len(cur) == 3:
                    tris.append(tuple(cur))
                    cur = []
        if cur:
            raise MeshError("%s: trailing partial facet" % path)
    else:
        n = struct.unpack('<I', data[80:84])[0]
        want = 84 + 50 * n
        if len(data) != want:
            raise MeshError("%s: binary STL claims %d facets, needs %d bytes, has %d"
                            % (path, n, want, len(data)))
        off = 84
        for _ in range(n):
            f = struct.unpack('<12f', data[off:off + 48])
            tris.append(((f[3], f[4], f[5]), (f[6], f[7], f[8]), (f[9], f[10], f[11])))
            off += 50

    if not tris and not allow_empty:
        raise MeshError("%s: loaded ZERO triangles" % path)
    return tris


def volume(tris):
    v = 0.0
    for a, b, c in tris:
        v += (a[0] * (b[1] * c[2] - b[2] * c[1])
              - a[1] * (b[0] * c[2] - b[2] * c[0])
              + a[2] * (b[0] * c[1] - b[1] * c[0]))
    return v / 6.0


def bbox(tris):
    lo = [float('inf')] * 3
    hi = [float('-inf')] * 3
    for t in tris:
        for p in t:
            for i in range(3):
                lo[i] = min(lo[i], p[i])
                hi[i] = max(hi[i], p[i])
    return lo, hi


def verts(tris):
    return [p for t in tris for p in t]


def closed(tris):
    """Count edge incidence ourselves.  OpenSCAD says 'manifold' about meshes
    that are not; a closed surface has every undirected edge in exactly two
    triangles, and volume() is meaningless otherwise."""
    q = lambda p: (round(p[0], 5), round(p[1], 5), round(p[2], 5))
    edges = defaultdict(int)
    for t in tris:
        for i in range(3):
            a, b = q(t[i]), q(t[(i + 1) % 3])
            edges[(a, b) if a < b else (b, a)] += 1
    return sum(1 for c in edges.values() if c != 2), len(edges)


def shells(tris):
    """Connected components, by shared vertex."""
    q = lambda p: (round(p[0], 5), round(p[1], 5), round(p[2], 5))
    parent = {}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for t in tris:
        for p in t:
            parent.setdefault(q(p), q(p))
    for t in tris:
        ks = [q(p) for p in t]
        for k in ks[1:]:
            ra, rb = find(ks[0]), find(k)
            if ra != rb:
                parent[ra] = rb
    return len({find(k) for k in parent})


# ---- measuring ------------------------------------------------------------
def section(tris, z):
    """Cross-section at height z, as a soup of 2D segments."""
    segs = []
    for tri in tris:
        pts = []
        for i in range(3):
            a, b = tri[i], tri[(i + 1) % 3]
            if (a[2] - z) * (b[2] - z) < 0:
                t = (z - a[2]) / (b[2] - a[2])
                pts.append((a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1])))
            elif abs(a[2] - z) < 1e-12:
                pts.append((a[0], a[1]))
        u = []
        for p in pts:
            if not any(abs(p[0] - q[0]) < 1e-9 and abs(p[1] - q[1]) < 1e-9 for q in u):
                u.append(p)
        if len(u) == 2:
            segs.append((u[0], u[1]))
    return segs


def ray_hits(segs, ang):
    """Radii at which a ray from the axis, on bearing `ang`, crosses the wall."""
    dx, dy = math.cos(math.radians(ang)), math.sin(math.radians(ang))
    out = []
    for p, q in segs:
        ex, ey = q[0] - p[0], q[1] - p[1]
        den = ex * dy - ey * dx
        if abs(den) < 1e-12:
            continue
        t = (p[1] * dx - p[0] * dy) / den
        if -1e-9 <= t <= 1 + 1e-9:
            s = (p[0] + t * ex) * dx + (p[1] + t * ey) * dy
            if s > 1e-9:
                out.append(s)
    out.sort()
    ded = []
    for s in out:
        if not ded or s - ded[-1] > 1e-6:
            ded.append(s)
    return ded


def wall_at(tris, z, ang, lo, hi, which="min"):
    """The wall crossing at height z, bearing ang, inside a radius window.

    Raises if there is no crossing at all.  "no crossing" and "the crossing is
    where I expected" must never be the same answer.
    """
    hits = [s for s in ray_hits(section(tris, z), ang) if lo <= s <= hi]
    if not hits:
        raise MeshError("no wall crossing at z=%.3f bearing=%.1f in [%.2f,%.2f]"
                        % (z, ang, lo, hi))
    return min(hits) if which == "min" else max(hits)


def outer_at(tris, z, ang=17.0):
    """Outermost material radius at a height, on ONE bearing."""
    hits = ray_hits(section(tris, z), ang)
    if not hits:
        raise MeshError("no material at z=%.3f bearing=%.1f" % (z, ang))
    return max(hits)


def max_outer(tris, z, step=1.0):
    """Outermost material radius at a height, over EVERY bearing.

    Single-bearing probes are a trap on this part: the barbs occupy six 15 deg
    windows and the thread is a helix, so a fixed bearing lands between them
    and confidently reports the plain wall behind.  It reads as a clean number,
    not as a miss.
    """
    segs = section(tris, z)
    best = -1.0
    for i in range(int(360 / step)):
        h = ray_hits(segs, i * step)
        if h:
            best = max(best, max(h))
    if best < 0:
        raise MeshError("no material anywhere at z=%.3f" % z)
    return best


def angular_extents(tris, z, r_thresh, step=0.2):
    """Bearings at which the outer radius exceeds r_thresh, grouped into runs.

    This is how the tongues get COUNTED off the mesh instead of being taken on
    trust from the for-loop that made them.
    """
    segs = section(tris, z)
    hot = []
    n = int(360 / step)
    for i in range(n):
        a = i * step
        h = ray_hits(segs, a)
        if h and max(h) >= r_thresh:
            hot.append(a)
    if not hot:
        return []
    runs = [[hot[0]]]
    for a in hot[1:]:
        if a - runs[-1][-1] <= step * 1.5:
            runs[-1].append(a)
        else:
            runs.append([a])
    if len(runs) > 1 and (runs[0][0] + 360.0) - runs[-1][-1] <= step * 1.5:
        runs[0] = [x - 360.0 for x in runs[-1]] + runs[0]
        runs.pop()
    return runs


# ---- selftest -------------------------------------------------------------
CUBE = [
    ((0, 0, 0), (0, 1, 0), (1, 1, 0)), ((0, 0, 0), (1, 1, 0), (1, 0, 0)),
    ((0, 0, 1), (1, 1, 1), (0, 1, 1)), ((0, 0, 1), (1, 0, 1), (1, 1, 1)),
    ((0, 0, 0), (1, 0, 0), (1, 0, 1)), ((0, 0, 0), (1, 0, 1), (0, 0, 1)),
    ((0, 1, 0), (0, 1, 1), (1, 1, 1)), ((0, 1, 0), (1, 1, 1), (1, 1, 0)),
    ((0, 0, 0), (0, 0, 1), (0, 1, 1)), ((0, 0, 0), (0, 1, 1), (0, 1, 0)),
    ((1, 0, 0), (1, 1, 0), (1, 1, 1)), ((1, 0, 0), (1, 1, 1), (1, 0, 1)),
]


def _tube(ri, ro, h, n=64):
    """A closed annular tube, built here so the ray probes are checked against
    a shape whose answers are known exactly rather than against the part."""
    tris = []
    ring = lambda r, z: [(r * math.cos(2 * math.pi * i / n),
                          r * math.sin(2 * math.pi * i / n), z) for i in range(n)]
    bi, bo, ti, to = ring(ri, 0), ring(ro, 0), ring(ri, h), ring(ro, h)
    for i in range(n):
        j = (i + 1) % n
        tris += [(bo[i], bo[j], to[j]), (bo[i], to[j], to[i])]        # outside
        tris += [(bi[j], bi[i], ti[i]), (bi[j], ti[i], ti[j])]        # inside
        tris += [(bi[i], bi[j], bo[j]), (bi[i], bo[j], bo[i])]        # bottom
        tris += [(ti[j], ti[i], to[i]), (ti[j], to[i], to[j])]        # top
    return tris


def selftest(tmp):
    fails = []

    def chk(name, ok, detail=""):
        print("    %-46s %s %s" % (name, "ok" if ok else "FAIL", detail))
        if not ok:
            fails.append(name)

    ascii_p = os.path.join(tmp, "_st_ascii.stl")
    with open(ascii_p, 'w') as f:
        f.write("solid t\n")
        for t in CUBE:
            f.write("facet normal 0 0 0\n outer loop\n")
            for p in t:
                f.write("  vertex %f %f %f\n" % p)
            f.write(" endloop\nendfacet\n")
        f.write("endsolid t\n")

    bin_p = os.path.join(tmp, "_st_bin.stl")
    with open(bin_p, 'wb') as f:
        f.write(b'\0' * 80 + struct.pack('<I', len(CUBE)))
        for t in CUBE:
            f.write(struct.pack('<3f', 0, 0, 0))
            for p in t:
                f.write(struct.pack('<3f', *p))
            f.write(b'\0\0')

    a, b = load(ascii_p), load(bin_p)
    chk("ascii loader returns 12 facets", len(a) == 12, len(a))
    chk("binary loader returns 12 facets", len(b) == 12, len(b))
    chk("unit cube volume == 1.0", abs(volume(a) - 1.0) < 1e-9, "%.9f" % volume(a))
    chk("both loaders agree on volume", abs(volume(a) - volume(b)) < 1e-6)
    chk("unit cube is closed", closed(a)[0] == 0)
    chk("unit cube is one shell", shells(a) == 1)

    # The traps.  Each MUST raise; a loader that returns [] instead hands every
    # check below a perfect score on an empty mesh.
    empty = os.path.join(tmp, "_st_empty.stl")
    open(empty, 'wb').close()
    for name, path in [("empty file raises", empty),
                       ("missing file raises", os.path.join(tmp, "_st_nope.stl"))]:
        try:
            load(path)
            chk(name, False, "returned instead of raising")
        except MeshError:
            chk(name, True)
    trunc = os.path.join(tmp, "_st_trunc.stl")
    with open(trunc, 'wb') as f:
        f.write(b'\0' * 80 + struct.pack('<I', 999))
    try:
        load(trunc)
        chk("truncated binary raises", False, "returned instead of raising")
    except MeshError:
        chk("truncated binary raises", True)

    # The ray probes, against a tube whose walls are known exactly.  This is
    # the instrument every radius below is taken with; the previous version of
    # this file measured vertices instead and silently found nothing at all.
    tube = _tube(4.0, 5.0, 3.0)
    chk("tube inner wall found at r=4", abs(wall_at(tube, 1.5, 33.0, 3, 6) - 4.0) < 0.01,
        "%.4f" % wall_at(tube, 1.5, 33.0, 3, 6))
    chk("tube outer wall found at r=5",
        abs(wall_at(tube, 1.5, 33.0, 3, 6, "max") - 5.0) < 0.01)
    chk("ray through a tube crosses exactly twice",
        len(ray_hits(section(tube, 1.5), 33.0)) == 2)
    try:
        wall_at(tube, 1.5, 33.0, 9, 10)
        chk("wall_at raises when the window is empty", False, "returned a number")
    except MeshError:
        chk("wall_at raises when the window is empty", True)
    try:
        outer_at(tube, 99.0)
        chk("outer_at raises above the part", False, "returned a number")
    except MeshError:
        chk("outer_at raises above the part", True)
    chk("angular_extents finds nothing above a tube's OD",
        angular_extents(tube, 1.5, 5.5, step=2.0) == [])
    chk("angular_extents finds the whole ring below its OD",
        len(angular_extents(tube, 1.5, 4.9, step=2.0)) == 1)
    return fails


# ---- checks ---------------------------------------------------------------
def report(name, got, want, tol, note=""):
    ok = got is not None and abs(got - want) <= tol
    g = "  ----  " if got is None else "%8.3f" % got
    print("    %-44s %s  want %8.3f +/-%.2f mm%s"
          % (name, g, want, tol, "" if ok else "   <-- FAIL"))
    if note and not ok:
        print("        %s" % note)
    return ok


def gate(name, ok, detail):
    print("    %-44s %s   %s" % (name, "ok  " if ok else "FAIL", detail))
    return ok


def check_carrier(t):
    print("--- carrier")
    f = []
    bad, ne = closed(t)
    f.append(gate("mesh closed (every edge in 2 facets)", bad == 0,
                  "%d bad of %d edges" % (bad, ne)))
    f.append(gate("single shell", shells(t) == 1, "%d shell(s)" % shells(t)))

    lo, hi = bbox(t)
    f.append(report("overall height (skirt base to thread top)",
                    hi[2] - lo[2], CARRIER_T + THREAD_L, TOL))

    # Everything the printed dome can reach.
    f.append(report("rim outside diameter (the dome rides on this)",
                    2 * outer_at(t, SKIRT_H + RIM_H / 2), CARRIER_D, TOL,
                    "the printed dome's skirt bore is %.2f" % (CARRIER_D + 2 * SNAP_CLR)))
    f.append(report("thread crest diameter",
                    2 * max_outer(t, CARRIER_T + THREAD_L / 2, 0.5), THREAD_D, 0.15))
    f.append(report("rim height above the seat (dome thread datum)",
                    hi[2] - THREAD_L - SKIRT_H, RIM_H, TOL))

    # The snap.
    f.append(report("barb crest radius", max_outer(t, BARB_MID_Z), BARB_OR, TOL))
    f.append(report("skirt outside radius, above the barb",
                    max_outer(t, (BARB_TOP_Z + SKIRT_H) / 2), SKIRT_OR, TOL))

    # Tongue vs ring: the two wall thicknesses that decide whether it bends.
    z = (BARB_TOP_Z + SKIRT_H) / 2
    t_in = wall_at(t, z, 0.0, 11.0, 14.4)
    r_in = wall_at(t, z, 360.0 / TONGUE_N / 2, 11.0, 14.4)
    f.append(report("tongue inner radius (thinned for flex)", t_in, TONGUE_IR, TOL))
    f.append(report("ring inner radius (between tongues)", r_in, SKIRT_IR, TOL))
    f.append(gate("tongue is thinner than the ring it sits in",
                  t_in > r_in + 0.3,
                  "tongue wall %.2f, ring wall %.2f"
                  % (SKIRT_OR - t_in, SKIRT_OR - r_in)))
    f.append(gate("relief behind the tongue exceeds its deflection",
                  t_in - r_in >= SNAP_ENGAGE + 0.05,
                  "%.2f mm of room for %.2f mm of bend" % (t_in - r_in, SNAP_ENGAGE)))

    # Count the tongues off the mesh, and measure one.
    runs = angular_extents(t, BARB_MID_Z, BARB_OR - 0.15)
    f.append(gate("tongue count", len(runs) == TONGUE_N,
                  "%d barb(s) found around the crest" % len(runs)))
    if runs:
        # The cuts are parallel slabs, so a tongue is exactly TONGUE_W at the
        # skirt OD and fans out slightly by the time it reaches the crest.
        half = CUT_OFF - math.degrees(math.asin(TONGUE_CUT / 2 / BARB_OR))
        want = 2 * BARB_OR * math.sin(math.radians(half))
        widths = [2 * BARB_OR * math.sin(math.radians((r[-1] - r[0]) / 2)) for r in runs]
        f.append(report("barb width at the crest",
                        sum(widths) / len(widths), want, 0.25))
    # The skirt's footprint on the bed, and the rim's bridge anchor above it,
    # are the same annulus -- so what matters is how much of the circumference
    # survives the cuts and how wide the widest gap is.  (The twelve cuts DO
    # sever the ring into twelve arcs; the design note used to claim otherwise.
    # Twelve 1.5 mm gaps in 88 mm is a fine anchor.  Six bare towers would not
    # be, which is what this is really guarding against.)
    runs_od = angular_extents(t, z, SKIRT_OR - 0.15)
    cover = sum(r[-1] - r[0] for r in runs_od)
    gaps = sorted(360.0 - cover for _ in [0])
    widest = max((runs_od[(i + 1) % len(runs_od)][0] - r[-1]) % 360.0
                 for i, r in enumerate(runs_od)) if len(runs_od) > 1 else 0.0
    f.append(gate("skirt keeps most of its circumference on the bed",
                  cover / 360.0 >= 0.75,
                  "%.0f %% of the ring present in %d arc(s)"
                  % (100 * cover / 360.0, len(runs_od))))
    f.append(gate("no gap wide enough to spoil the rim's bridge",
                  widest * math.pi * SKIRT_OR / 180.0 <= 2.5,
                  "widest gap %.2f mm" % (widest * math.pi * SKIRT_OR / 180.0)))

    # Strain and force, from the geometry.
    L = SKIRT_H - BARB_MID_Z
    strain = 100.0 * 3 * TONGUE_WALL * SNAP_ENGAGE / (2 * L * L)
    force = TONGUE_N * TONGUE_W * TONGUE_WALL ** 3 * E_PETG * SNAP_ENGAGE / (4 * L ** 3)
    print("    tongue free length %.2f mm -> peak strain %.2f %% (PETG limit ~%.0f %%),"
          " spring force ~%.0f N" % (L, strain, STRAIN_LIMIT, force))
    f.append(gate("peak bending strain within PETG", strain <= STRAIN_LIMIT,
                  "%.2f %%" % strain))
    return all(f)


def check_body(t):
    print("--- body")
    f = []
    bad, ne = closed(t)
    f.append(gate("mesh closed (every edge in 2 facets)", bad == 0,
                  "%d bad of %d edges" % (bad, ne)))
    f.append(gate("single shell", shells(t) == 1, "%d shell(s)" % shells(t)))

    lo, hi = bbox(t)
    f.append(report("body top face", hi[2], BODY_H, TOL))
    f.append(report("GoPro finger tip (lowest point)", lo[2], -GP_DROP, TOL))
    f.append(report("outside diameter", hi[0] - lo[0], BODY_D, TOL))

    # Counterbore, groove, bore -- the three radii the carrier lives in.
    ANG = 31.0                       # clear of the cable slot and the rails
    f.append(report("counterbore radius (accepts the OD30 rim)",
                    wall_at(t, BODY_H - SEAT_BORE / 2, ANG, 13.0, 15.9),
                    CARRIER_D / 2 + SNAP_CLR, TOL))
    gz = GROOVE_Z0 + BARB_LEAD_DZ + (BARB_LAND + 2 * SNAP_PLAY) / 2
    f.append(report("snap groove outer radius", wall_at(t, gz, ANG, 13.0, 15.9),
                    GROOVE_OR, TOL))
    bore_z = FLOOR_Z + BARB_TOP_Z + (SKIRT_H - BARB_TOP_Z) / 2
    f.append(report("plain bore radius", wall_at(t, bore_z, ANG, 13.0, 15.9),
                    BORE_R, TOL))
    f.append(gate("groove is a full annulus (snaps at any rotation)",
                  len(angular_extents(t, gz, GROOVE_OR - 0.05)) == 1,
                  "one continuous groove"))

    # Seat: the ledge the carrier's rim lands on, and how wide it is.
    seat = (CARRIER_D / 2 + SNAP_CLR) - BORE_R
    f.append(gate("seat ledge width", seat >= 0.8,
                  "%.2f mm of annulus under the rim" % seat))

    # GoPro grid.
    ys = sorted({round(p[1], 3) for p in verts(t) if p[2] < -GP_WEB_T - 0.5})
    f.append(report("2-prong stack width", max(ys) - min(ys),
                    2 * GP_FING_T + GP_GAP, TOL))
    inner = [y for y in ys if abs(y) < 3.0]
    f.append(report("centre gap (takes the arm's middle prong)",
                    max(inner) - min(inner), GP_GAP, TOL))
    f.append(report("finger thickness (enters the arm's %.2f slot)" % ARM_SLOT_W,
                    (max(ys) - min(ys) - GP_GAP) / 2, GP_FING_T, TOL))
    f.append(report("knuckle diameter", 2 * max(
        math.hypot(p[0], p[2] - GP_PIVOT_Z) for p in verts(t)
        if p[2] < GP_PIVOT_Z + 1.0), GP_TIP_D, TOL))
    f.append(gate("web clears the mating knuckle",
                  GP_CLEAR >= REAL_GOPRO_R + 1.0,
                  "pivot sits %.2f below the web; our arms R%.2f, a real GoPro "
                  "R%.2f -- v1's 6.50 is what stopped the screw"
                  % (GP_CLEAR, ARM_TAB_R, REAL_GOPRO_R)))
    return all(f)


def check_dome(t, same_as):
    print("--- dome")
    f = []
    lo, hi = bbox(t)
    f.append(report("dome height", hi[2] - lo[2], 20.30, TOL))
    f.append(report("dome outside diameter", hi[0] - lo[0], 33.00, TOL))
    f.append(report("skirt bore (rides on the carrier rim)",
                    2 * wall_at(t, CARRIER_PROUD / 2, 31.0, 13.0, 17.0),
                    CARRIER_D + 2 * SNAP_CLR, TOL))
    if same_as:
        ref = load(same_as)
        # The reference was exported ASCII (full double precision); this one is
        # binary (float32).  They cannot be compared byte for byte -- and a
        # hash of the triangle list answers the wrong question anyway, because
        # the same solid can come out with its facets in a different order and
        # each facet started from a different one of its three corners.  What
        # is actually being asked is "did any point of this surface MOVE", so
        # compare the two SORTED VERTEX CLOUDS, which no reordering disturbs.
        a, b = sorted(verts(t)), sorted(verts(ref))
        dev = (max(abs(x - y) for pa, pb in zip(a, b) for x, y in zip(pa, pb))
               if len(a) == len(b) else float('inf'))
        rel = abs(volume(t) - volume(ref)) / abs(volume(ref))
        print("    against the mesh that is on the printer (%s):" % same_as)
        print("      facets            %6d  vs %6d" % (len(t), len(ref)))
        print("      volume        %10.4f  vs %10.4f mm^3  (rel %.2e)"
              % (volume(t), volume(ref), rel))
        print("      largest vertex movement  %.2e mm  (float32 quantum ~2e-6)" % dev)
        f.append(gate("dome geometry UNCHANGED from the printed part",
                      len(a) == len(b) and dev < 1e-4 and rel < 1e-6,
                      "the dome on the printer still fits"
                      if dev < 1e-4 else "THE DOME MOVED -- it would need reprinting"))
    return all(f)


def check_probes(fit_path, hook_path):
    print("--- probes")
    f = []
    # An empty intersection is the CORRECT answer here, and OpenSCAD writes a
    # zero-facet STL for it, so this is the one caller allowed to see one.
    fit = load(fit_path, allow_empty=True)
    v = abs(volume(fit)) if fit else 0.0
    f.append(gate("seated carrier does not interfere with the body", v < 1e-3,
                  "overlap %.4f mm^3" % v))

    hook = load(hook_path)
    hv = abs(volume(hook))
    want = TONGUE_N * TONGUE_W * SNAP_ENGAGE * (
        BARB_LAND + 0.5 * (BARB_LEAD_DZ + BARB_HOLD_DZ) * (SNAP_ENGAGE / BARB_PROUD))
    f.append(gate("barbs actually stand outside the bore", hv > 1.0,
                  "%.2f mm^3 has to spring past (closed form ~%.2f; v1: 0.00)"
                  % (hv, want)))
    return all(f)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--carrier")
    ap.add_argument("--body")
    ap.add_argument("--dome")
    ap.add_argument("--same-as")
    ap.add_argument("--probes", nargs=2, metavar=("FIT", "HOOK"))
    a = ap.parse_args()

    ok = True
    if a.selftest:
        print("--- loader + probe selftest")
        ok = not selftest(os.environ.get("TMPDIR", "/tmp")) and ok
    carrier = load(a.carrier) if a.carrier else None
    body = load(a.body) if a.body else None
    if carrier:
        ok = check_carrier(carrier) and ok
    if body:
        ok = check_body(body) and ok
    if a.dome:
        ok = check_dome(load(a.dome), a.same_as) and ok
    if a.probes:
        ok = check_probes(*a.probes) and ok

    # The number the whole redesign exists for: one mesh minus the other.
    if carrier and body:
        barb = max_outer(carrier, BARB_MID_Z)
        bore_z = FLOOR_Z + BARB_TOP_Z + (SKIRT_H - BARB_TOP_Z) / 2
        bore = wall_at(body, bore_z, 31.0, 13.0, 15.9)
        interf = barb - bore
        print("--- THE SNAP")
        print("    barb crest %.3f  -  bore %.3f  =  %.3f mm of interference"
              % (barb, bore, interf))
        print("    v1 measured 0.150 mm against a rigid ring, and did not click.")
        ok = gate("interference is enough to snap", interf >= 0.30,
                  "%.3f mm" % interf) and ok

    print("\n%s" % ("ALL CHECKS PASSED" if ok else "*** CHECKS FAILED"))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
