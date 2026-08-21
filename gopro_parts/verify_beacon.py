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
BODY_H        = 9.50
BODY_FLOOR    = 2.20
BOSS_D        = 30.00
BOSS_PROUD    = 1.80
THREAD_D      = 28.00
THREAD_L      = 6.00
COLLAR_WALL   = 2.00
COLLAR_BORE   = THREAD_D - 2 * COLLAR_WALL      # 24.00
GENERAL_FIT   = 0.25
DOME_H        = 20.30
DOME_D        = 33.00
COLLAR_TOP    = BODY_H + BOSS_PROUD + THREAD_L  # 17.30
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


def check_body(t):
    print("--- body")
    f = []
    bad, ne = closed(t)
    f.append(gate("mesh closed (every edge in 2 facets)", bad == 0,
                  "%d bad of %d edges" % (bad, ne)))
    f.append(gate("single shell", shells(t) == 1, "%d shell(s)" % shells(t)))

    lo, hi = bbox(t)
    f.append(report("overall height", hi[2] - lo[2], COLLAR_TOP + GP_DROP, TOL))
    f.append(report("GoPro finger tip (lowest point)", lo[2], -GP_DROP, TOL))
    f.append(report("outside diameter", hi[0] - lo[0], BODY_D, TOL))
    f.append(report("top of the thread", hi[2], COLLAR_TOP, TOL))

    # The collar -- everything the printed dome screws onto.
    f.append(report("body face the dome seats on",
                    2 * max_outer(t, BODY_H - 0.3), BODY_D, TOL))
    f.append(report("boss diameter (dome's skirt bore rides here)",
                    2 * max_outer(t, BODY_H + BOSS_PROUD / 2), BOSS_D, TOL))
    f.append(report("thread crest diameter",
                    2 * max_outer(t, BODY_H + BOSS_PROUD + THREAD_L / 2, 0.5),
                    THREAD_D, 0.15))
    f.append(report("collar bore (light out, electronics in)",
                    2 * min_inner(t, BODY_H + BOSS_PROUD / 2, 8.0, 14.0),
                    COLLAR_BORE, TOL))

    # Measured, not assumed: how far the boss runs before the thread starts.
    z = transition_z(lambda zz: max_outer(t, zz, 2.0), BODY_H + 0.05,
                     BODY_H + BOSS_PROUD + 1.0, BOSS_D / 2, tol=0.06)
    f.append(report("boss stand-off before the thread",
                    (z - BODY_H) if z else None, BOSS_PROUD, 0.10,
                    "this is where the dome's internal thread starts"))

    # The compartment, and whether the parts can physically be assembled.
    f.append(gate("driver + star fit under the collar",
                  BODY_H - BODY_FLOOR >= PCB_T + STAR_T,
                  "%.1f mm of compartment for %.1f mm of stack"
                  % (BODY_H - BODY_FLOOR, PCB_T + STAR_T)))
    diag = math.hypot(PCB_L, PCB_W)
    f.append(gate("driver passes through the collar bore", COLLAR_BORE > diag + 1.0,
                  "bore %.1f vs driver diagonal %.1f" % (COLLAR_BORE, diag)))
    f.append(gate("LED star passes through the collar bore",
                  COLLAR_BORE > STAR_D + 1.0,
                  "bore %.1f vs star %.1f" % (COLLAR_BORE, STAR_D)))

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
    f.append(report("dome height", hi[2] - lo[2], DOME_H, TOL))
    f.append(report("dome outside diameter", hi[0] - lo[0], DOME_D, TOL))
    f.append(report("skirt bore (rides on the body's boss)",
                    2 * wall_at(t, BOSS_PROUD / 2, 31.0, 13.0, 17.0),
                    BOSS_D + 2 * GENERAL_FIT, TOL))
    if same_as:
        ref = load(same_as)
        # The reference was exported ASCII (full double precision); this one is
        # binary (float32).  They cannot be compared byte for byte -- and a
        # hash of the triangle list answers the wrong question anyway, because
        # the same solid comes back with its facets in a different order and
        # each facet started from a different one of its three corners.  What
        # is being asked is "did any point of this surface MOVE", so compare
        # the two SORTED VERTEX CLOUDS, which no reordering disturbs.
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


def check_fit(body, dome):
    """The one joint left, asked across both meshes at once.

    Neither part can answer this alone: the body knows how far its boss stands
    proud, the dome knows how deep its skirt bore runs before the thread
    starts, and the beacon only closes if those two are the same number.
    """
    print("--- THE JOINT (body boss vs the dome that is already printed)")
    f = []
    boss = 2 * max_outer(body, BODY_H + BOSS_PROUD / 2)
    skirt = 2 * wall_at(dome, BOSS_PROUD / 2, 31.0, 13.0, 17.0)
    clr = skirt - boss
    print("    boss %.3f  into skirt bore %.3f  =  %.3f mm diametral clearance"
          % (boss, skirt, clr))
    f.append(gate("boss enters the dome's skirt bore", 0.2 <= clr <= 1.0,
                  "%.3f mm" % clr))

    zb = transition_z(lambda zz: max_outer(body, zz, 2.0), BODY_H + 0.05,
                      BODY_H + BOSS_PROUD + 1.0, BOSS_D / 2, tol=0.06)
    zd = transition_z(lambda zz: wall_at(dome, zz, 31.0, 13.0, 17.0),
                      0.05, BOSS_PROUD + 1.0, (BOSS_D + 2 * GENERAL_FIT) / 2,
                      tol=0.06)
    body_off = (zb - BODY_H) if zb else None
    print("    thread starts %.3f above the body face, %.3f into the dome"
          % (body_off or -1, zd or -1))
    f.append(gate("thread datums agree",
                  body_off is not None and zd is not None
                  and abs(body_off - zd) < 0.12,
                  "%.3f vs %.3f mm" % (body_off or -1, zd or -1)))

    zt = BOSS_PROUD + THREAD_L / 2
    crest = 2 * max_outer(body, BODY_H + BOSS_PROUD + THREAD_L / 2, 0.5)
    # The female ROOT (major diameter), not its crest: 15.5 keeps the dome's
    # own 33 mm outside wall out of the window.
    root = 2 * max_inner(dome, zt, 12.0, 15.5, 0.5)
    fem_crest = 2 * min_inner(dome, zt, 12.0, 15.5, 0.5)
    print("    male crest %.3f into female root %.3f  =  %.3f mm diametral slop"
          % (crest, root, root - crest))
    print("    female crest %.3f sits in the male groove" % fem_crest)
    f.append(gate("thread has clearance and is not loose",
                  0.2 <= (root - crest) <= 1.4, "%.3f mm" % (root - crest)))
    f.append(gate("female crest clears the male root", fem_crest < crest,
                  "%.3f vs %.3f" % (fem_crest, crest)))
    return all(f)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--body")
    ap.add_argument("--dome")
    ap.add_argument("--same-as")
    a = ap.parse_args()

    ok = True
    if a.selftest:
        print("--- loader + probe selftest")
        ok = not selftest(os.environ.get("TMPDIR", "/tmp")) and ok
    body = load(a.body) if a.body else None
    dome = load(a.dome) if a.dome else None
    if body:
        ok = check_body(body) and ok
    if dome:
        ok = check_dome(dome, a.same_as) and ok
    if body and dome:
        ok = check_fit(body, dome) and ok

    print("\n%s" % ("ALL CHECKS PASSED" if ok else "*** CHECKS FAILED"))
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
