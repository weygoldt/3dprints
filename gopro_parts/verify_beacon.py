#!/usr/bin/env python3
"""Measure the rendered blink-beacon meshes against the spec.

Everything here is read off the exported STL, not out of the .scad, so it
catches modelling mistakes as well as parameter typos.

    python3 verify_beacon.py --selftest
    python3 verify_beacon.py --body B.stl --dome D.stl \
                             --same-as stl/dome_AS_PRINTED.stl

WHAT THIS IS FOR NOW
--------------------
v3 dropped the LED carrier: the dome threads straight onto the body.  That
deletes the snap this file used to exist to gate, and leaves ONE joint that
matters -- the thread and boss the already-printed dome screws onto.  So the
headline check is a cross-mesh one: take the boss off the body, take the skirt
bore off the dome, and confirm one goes into the other with clearance and at
the same stand-off.  Neither part alone can be asked that.

HOW IT MEASURES
---------------
By slicing the mesh with a horizontal plane and casting a ray out from the
axis, NOT by looking at where vertices happen to be.  A cylindrical wall
between z=a and z=b has vertices at a and b and nowhere in between, so
sampling a band strictly inside a face finds an empty set -- which then reads
as a clean answer.  A single bearing is the same trap one level up: on a
thread it lands in a groove and confidently reports the minor diameter, so
anything hunting a local feature sweeps every bearing.
"""
import argparse
import math
import os
import struct
import sys
from collections import defaultdict

# ---- spec (must mirror rc_boat_blink_beacon.scad) ------------------------
BODY_D        = 33.00
BODY_WALL     = 2.00
BODY_H        = 10.00
BODY_FLOOR    = 2.20
CARRIER_D     = 30.00
CARRIER_PROUD = 1.80
THREAD_D      = 28.00
THREAD_L      = 6.00
COLLAR_WALL   = 2.00
COLLAR_BORE   = THREAD_D - 2 * COLLAR_WALL      # 24.00
GENERAL_FIT   = 0.25
DOME_H        = 20.30
DOME_D        = 33.00
SEAT_DEPTH    = 1.80
CARRIER_T     = SEAT_DEPTH + CARRIER_PROUD      # 3.60
KEY_ACROSS    = 28.00
SEAT_FIT      = 0.20
STAR_POCKET_D = 20.40
STAR_POCKET_DEPTH = 2.15
CARRIER_FLOOR_Z = BODY_H - SEAT_DEPTH           # 8.20
BORE_R        = BODY_D / 2 - BODY_WALL          # 14.50

PCB_L         = 18.00
PCB_W         = 10.00
PCB_T         = 4.50
STAR_D        = 20.00
STAR_T        = 2.00

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

TOL = 0.03               # mm -- faceting slop on a d=30 circle at $fn=128


class MeshError(Exception):
    pass


# ---- loader ---------------------------------------------------------------
def load(path, allow_empty=False):
    """Read an STL, ASCII or binary, and return a list of (v0,v1,v2) triples.

    Raises rather than returning [] for anything it cannot make sense of.  An
    empty mesh is the one failure mode that looks like success downstream.
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


def max_outer(tris, z, step=1.0):
    """Outermost material radius at a height, over EVERY bearing.

    A thread is a helix: a fixed bearing lands in a groove and reports the
    minor diameter as though it were the crest.
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


def _wall_extreme(tris, z, lo, hi, pick, step=1.0):
    segs = section(tris, z)
    best = None
    for i in range(int(360 / step)):
        for s in ray_hits(segs, i * step):
            if lo <= s <= hi and (best is None or pick(s, best)):
                best = s
    if best is None:
        raise MeshError("no wall in [%.2f,%.2f] at z=%.3f" % (lo, hi, z))
    return best


def min_inner(tris, z, lo, hi, step=1.0):
    """Innermost wall crossing inside a window, over every bearing.

    On a FEMALE thread this is the crest -- the thread's minor diameter, the
    bit that pokes inward into the male's groove.
    """
    return _wall_extreme(tris, z, lo, hi, lambda s, b: s < b, step)


def max_inner(tris, z, lo, hi, step=1.0):
    """Outermost wall crossing inside a window, over every bearing.

    On a FEMALE thread this is the ROOT -- the thread's major diameter, which
    is what a male crest actually has to fit inside.  The window has to
    exclude the part's own outside wall or this just measures that.
    """
    return _wall_extreme(tris, z, lo, hi, lambda s, b: s > b, step)


def transition_z(fn, z0, z1, want, tol=0.05, steps=240):
    """Walk z and return where fn(z) stops being `want` (within tol).

    Used to measure a STAND-OFF -- how far the boss runs before the thread
    starts -- off the mesh instead of trusting the parameter that drew it.
    """
    last = None
    for i in range(steps + 1):
        z = z0 + (z1 - z0) * i / steps
        try:
            v = fn(z)
        except MeshError:
            v = None
        ok = v is not None and abs(v - want) <= tol
        if last is not None and last and not ok:
            return z
        last = ok
    return None


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
    """A closed annular tube, so the ray probes get checked against a shape
    whose answers are known exactly rather than against the part."""
    tris = []
    ring = lambda r, z: [(r * math.cos(2 * math.pi * i / n),
                          r * math.sin(2 * math.pi * i / n), z) for i in range(n)]
    bi, bo, ti, to = ring(ri, 0), ring(ro, 0), ring(ri, h), ring(ro, h)
    for i in range(n):
        j = (i + 1) % n
        tris += [(bo[i], bo[j], to[j]), (bo[i], to[j], to[i])]
        tris += [(bi[j], bi[i], ti[i]), (bi[j], ti[i], ti[j])]
        tris += [(bi[i], bi[j], bo[j]), (bi[i], bo[j], bo[i])]
        tris += [(ti[j], ti[i], to[i]), (ti[j], to[i], to[j])]
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

    # The ray probes, against a tube whose walls are known exactly.
    tube = _tube(4.0, 5.0, 3.0)
    chk("tube inner wall found at r=4",
        abs(wall_at(tube, 1.5, 33.0, 3, 6) - 4.0) < 0.01,
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
        max_outer(tube, 99.0)
        chk("max_outer raises above the part", False, "returned a number")
    except MeshError:
        chk("max_outer raises above the part", True)

    # A stepped tube, so transition_z is checked against a step whose height
    # is known.  Without this the stand-off measurement is unfalsifiable.
    step = _tube(4.0, 5.0, 2.0) + [((p[0], p[1], p[2] + 2.0) for p in t)
                                   for t in []]
    two = _tube(4.0, 6.0, 2.0)
    shifted = [tuple((p[0], p[1], p[2] + 2.0) for p in t) for t in _tube(4.0, 5.0, 2.0)]
    z = transition_z(lambda zz: max_outer(two + shifted, zz), 0.1, 3.9, 6.0)
    chk("transition_z finds a step at 2.0", z is not None and abs(z - 2.0) < 0.08,
        "%.3f" % z if z else "none")
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


def across_flats(tris, z):
    """Full width along X and along Y of a section.

    The key flats are cut on Y, so Y is the across-flats width while X still
    reaches the full circle.  Two numbers off one section, which is what makes
    "is it actually keyed" answerable rather than assumed.
    """
    segs = section(tris, z)
    xs = [p[0] for s in segs for p in s]
    ys = [p[1] for s in segs for p in s]
    if not xs:
        raise MeshError("no section at z=%.3f" % z)
    return max(xs) - min(xs), max(ys) - min(ys)


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

    # The counterbore the carrier drops into, and its key.
    zc = CARRIER_FLOOR_Z + SEAT_DEPTH / 2
    f.append(report("counterbore bore (round direction)",
                    2 * wall_at(t, zc, 0.0, 10.0, 16.0),
                    CARRIER_D + SEAT_FIT, 0.06))
    f.append(report("counterbore key (across the flats)",
                    2 * wall_at(t, zc, 90.0, 10.0, 16.0),
                    KEY_ACROSS + SEAT_FIT, 0.06))
    f.append(report("plain bore below the counterbore",
                    2 * wall_at(t, (BODY_FLOOR + CARRIER_FLOOR_Z) / 2,
                                31.0, 10.0, 16.0),
                    BODY_D - 2 * BODY_WALL, TOL))
    f.append(gate("compartment holds the driver",
                  CARRIER_FLOOR_Z - BODY_FLOOR >= PCB_T + 1.0,
                  "%.1f mm for a %.1f mm board"
                  % (CARRIER_FLOOR_Z - BODY_FLOOR, PCB_T)))

    # GoPro grid.
    ys = sorted({round(p[1], 3) for p in verts(t) if p[2] < -GP_WEB_T - 0.5})
    f.append(report("2-prong stack width", max(ys) - min(ys),
                    2 * GP_FING_T + GP_GAP, TOL))
    inner = [y for y in ys if abs(y) < 3.0]
    f.append(report("centre gap (takes the arm's middle prong)",
                    max(inner) - min(inner), GP_GAP, TOL))
    f.append(report("knuckle diameter", 2 * max(
        math.hypot(p[0], p[2] - GP_PIVOT_Z) for p in verts(t)
        if p[2] < GP_PIVOT_Z + 1.0), GP_TIP_D, TOL))
    f.append(gate("web clears the mating knuckle",
                  GP_CLEAR >= REAL_GOPRO_R + 1.0,
                  "pivot sits %.2f below the web; our arms R%.2f, a real GoPro "
                  "R%.2f -- v1's 6.50 is what stopped the screw"
                  % (GP_CLEAR, ARM_TAB_R, REAL_GOPRO_R)))
    return all(f)


def check_carrier(t):
    print("--- carrier")
    f = []
    bad, ne = closed(t)
    f.append(gate("mesh closed (every edge in 2 facets)", bad == 0,
                  "%d bad of %d edges" % (bad, ne)))
    f.append(gate("single shell", shells(t) == 1, "%d shell(s)" % shells(t)))

    lo, hi = bbox(t)
    f.append(report("overall height (disc + thread)", hi[2] - lo[2],
                    CARRIER_T + THREAD_L, TOL))
    # The whole point of v4: nothing hangs below the underside, so it prints
    # flat on the bed with no support anywhere.
    f.append(gate("underside is flat -- nothing hangs below it",
                  abs(lo[2]) < 1e-6, "lowest point z=%.4f" % lo[2]))

    f.append(report("rim diameter (the dome rides on this)",
                    2 * max_outer(t, CARRIER_T - CARRIER_PROUD / 2),
                    CARRIER_D, TOL))
    rnd, key = across_flats(t, SEAT_DEPTH / 2)
    f.append(report("keyed seat, round direction", rnd, CARRIER_D, TOL))
    f.append(report("keyed seat, across the flats", key, KEY_ACROSS, TOL))
    f.append(gate("the seat really is keyed, not round", rnd - key > 1.0,
                  "%.2f mm of flat, which is what stops it spinning"
                  % (rnd - key)))
    f.append(report("thread crest diameter",
                    2 * max_outer(t, CARRIER_T + THREAD_L / 2, 0.5),
                    THREAD_D, 0.15))
    f.append(report("star pocket diameter",
                    2 * wall_at(t, CARRIER_T - STAR_POCKET_DEPTH / 2,
                                31.0, 5.0, 14.0),
                    STAR_POCKET_D, TOL))
    f.append(gate("opaque floor left under the star",
                  CARRIER_T - STAR_POCKET_DEPTH >= 1.0,
                  "%.2f mm" % (CARRIER_T - STAR_POCKET_DEPTH)))
    f.append(gate("star drops in through the threaded collar",
                  COLLAR_BORE > STAR_D + 1.0,
                  "collar bore %.1f vs star %.1f" % (COLLAR_BORE, STAR_D)))
    return all(f)


def check_dome(t, same_as):
    print("--- dome")
    f = []
    lo, hi = bbox(t)
    f.append(report("dome height", hi[2] - lo[2], DOME_H, TOL))
    f.append(report("dome outside diameter", hi[0] - lo[0], DOME_D, TOL))
    if same_as:
        ref = load(same_as)
        # The reference was exported ASCII (double precision), this one binary
        # (float32), so they cannot be compared byte for byte -- and hashing the
        # triangle list asks the wrong question, because the same solid comes
        # back with its facets reordered and each started from a different
        # corner.  Compare SORTED VERTEX CLOUDS, which no reordering disturbs.
        a, b = sorted(verts(t)), sorted(verts(ref))
        dev = (max(abs(x - y) for pa, pb in zip(a, b) for x, y in zip(pa, pb))
               if len(a) == len(b) else float('inf'))
        rel = abs(volume(t) - volume(ref)) / abs(volume(ref))
        print("    vs the mesh on the printer: %d vs %d facets, largest vertex "
              "movement %.2e mm" % (len(t), len(ref), dev))
        f.append(gate("dome geometry UNCHANGED from the printed part",
                      len(a) == len(b) and dev < 1e-4 and rel < 1e-6,
                      "the dome on the printer still fits"
                      if dev < 1e-4 else "THE DOME MOVED -- reprint required"))
    return all(f)


def check_fit(carrier, body, dome):
    """Both joints, each asked across two meshes at once.

    No single part can answer either: the carrier knows how far its rim stands
    proud, the dome knows how deep its skirt bore runs, the body knows how wide
    its counterbore is.
    """
    print("--- THE JOINTS")
    f = []
    rim = 2 * max_outer(carrier, CARRIER_T - CARRIER_PROUD / 2)
    skirt = 2 * wall_at(dome, CARRIER_PROUD / 2, 31.0, 13.0, 17.0)
    print("    carrier rim %.3f into dome skirt bore %.3f  =  %.3f mm clearance"
          % (rim, skirt, skirt - rim))
    f.append(gate("carrier enters the dome's skirt bore",
                  0.2 <= skirt - rim <= 1.0, "%.3f mm" % (skirt - rim)))

    crest = 2 * max_outer(carrier, CARRIER_T + THREAD_L / 2, 0.5)
    zt = CARRIER_PROUD + THREAD_L / 2
    # The female ROOT (major diameter), not its crest: the 15.5 ceiling keeps
    # the dome's own 33 mm outside wall out of the window.
    root = 2 * max_inner(dome, zt, 12.0, 15.5, 0.5)
    print("    male crest %.3f into female root %.3f  =  %.3f mm slop"
          % (crest, root, root - crest))
    f.append(gate("thread has clearance and is not loose",
                  0.2 <= (root - crest) <= 1.4, "%.3f mm" % (root - crest)))

    # And the seat -- including the key, which is the only thing stopping the
    # carrier turning while the dome is screwed down onto it.
    zc_b = CARRIER_FLOOR_Z + SEAT_DEPTH / 2
    zc_c = SEAT_DEPTH / 2
    # The BODY's seat is a HOLE, so it is measured by ray -- the first wall the
    # ray meets on each axis.  The CARRIER's seat is SOLID, so it is measured by
    # extent.  Using a ray on the carrier too is what reported "13.600 into
    # 30.200": the innermost thing a ray meets there is a wire hole.
    c_rnd, c_key = across_flats(carrier, zc_c)
    b_rnd = 2 * wall_at(body, zc_b, 0.0, 10.0, 16.0)
    b_key = 2 * wall_at(body, zc_b, 90.0, 10.0, 16.0)
    for name, seat, part_w in [("round", b_rnd, c_rnd), ("key  ", b_key, c_key)]:
        clr = seat - part_w
        print("    seat %s carrier %.3f into body %.3f  =  %.3f mm"
              % (name, part_w, seat, clr))
        f.append(gate("carrier seats in the body (%s)" % name.strip(),
                      0.05 <= clr <= 0.6, "%.3f mm" % clr))
    return all(f)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--body")
    ap.add_argument("--carrier")
    ap.add_argument("--dome")
    ap.add_argument("--same-as")
    a = ap.parse_args()

    ok = True
    if a.selftest:
        print("--- loader + probe selftest")
        ok = not selftest(os.environ.get("TMPDIR", "/tmp")) and ok
    body = load(a.body) if a.body else None
    carrier = load(a.carrier) if a.carrier else None
    dome = load(a.dome) if a.dome else None
    if body:
        ok = check_body(body) and ok
    if carrier:
        ok = check_carrier(carrier) and ok
    if dome:
        ok = check_dome(dome, a.same_as) and ok
    if body and carrier and dome:
        ok = check_fit(carrier, body, dome) and ok

    print("\n%s" % ("ALL CHECKS PASSED" if ok else "*** CHECKS FAILED"))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
