#!/usr/bin/env python3
"""Measure a rendered arm STL against the GoPro interface + printability spec.

Everything here is measured off the exported mesh, not read back out of the
OpenSCAD source, so it catches modelling mistakes as well as parameter typos.

Usage:  python3 verify.py <arm.stl> --length 100
        python3 verify.py <gauge.stl> --length 21   (gauge Lg = 2*tab_r + 6)
        python3 verify.py <simple.stl> --length 100 --simple

--simple switches the expectations to arm_simple.scad: a slab body instead of
a strut, a screw pocket in BOTH outer prongs instead of a nut trap in one, and
a pivot raised from 5.303 to 6.000.

The MATING interface is checked identically either way, because it IS identical
-- same 3 mm grid, same clearances, same R7.5 envelope; that is the point of
the variant.  The pivot height is not part of that interface: it is measured
from the BED, which no mating part can see.  What it does move is everything
centred on it -- the pocket floors, the bore, the body height, and the angle
the knuckle flank leaves the bed at -- so those expectations move with it.
"""
import argparse
import math
import os
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
# Its two pockets are DIFFERENT, because one shape cannot do both jobs: an M5
# barrel head is 8.50 across, wider than the nut's 8.00 flats.  So the nut
# side is a press-fit hex and the far side is a plain round counterbore.
HEAD_D      = 8.50     # M5 DIN 912 socket cap head, across
HEAD_H      = 5.00     # ... and tall
HEAD_CLR    = 0.30
HEAD_SEAT   = 0.30
S_NUT_SIDE  = -1
S_PKT_AF    = 8.00                                             # == NUT_AF
S_PKT_DEPTH = NUT_T + NUT_SEAT                                 # 4.30
S_HD_D      = HEAD_D + HEAD_CLR                                # 8.80
S_HD_DEPTH  = HEAD_H + HEAD_SEAT                               # 5.30
S_BOSS_NUT  = max(0.0, S_PKT_DEPTH + NUT_WALL - PRONG_OUT_T)   # 2.40
S_BOSS_HD   = max(0.0, S_HD_DEPTH + NUT_WALL - PRONG_OUT_T)    # 3.40
# The simple variant CENTRES the pivot: it sits at TAB_R, so the knuckle is the
# full R7.5 circle, tangent to the bed, and the part is symmetric about the
# pivot plane.  Floor and crown stop being two numbers -- every wall around the
# pivot is TAB_R - half, on both sides.  It is bought with bed contact (the
# knuckle touches on a LINE) and with support (the underside leaves at 90 deg),
# which is affordable only because this is the one variant printed supported.
# So this file checks both sides of that trade: the symmetry it buys, and the
# adhesion it spends.
S_PIVOT_Z   = TAB_R                                            # 7.500
S_TAB_TOP   = S_PIVOT_Z + TAB_R                                # 15.000
LAYER_H     = 0.20     # what the first layer of a tangent knuckle can grab
# 45 deg countersink where the pivot bore breaks into the head counterbore, so
# an ISO 4762 under-head fillet (out to da = 5.70, wider than the 5.30 bore)
# clears and the head seats on its flat annulus instead of on the bore's edge.
S_HEAD_CS   = 0.50
HEAD_DA     = 5.70
SB_H        = TAB_TOP          # body height == knuckle height, so no chord ramp
SB_T        = 2*W2_HALF        # 8.90 -- body width == the 2-prong stack
SB_RT       = 2.50             # top edge rounding
SB_RB       = 2.50             # bottom edge rounding -- a fillet, so it OVERHANGS
SB_BLEND    = 10.0             # sharp knuckle section -> rounded section

# ---- mode-dependent spec, filled in by configure() --------------------
# One entry per pocket: (side, kind, size, depth, boss)
#   'hex'   size is across flats -- a nut trap, press or clearance fit
#   'round' size is the bore diameter -- a seat for a screw head, which needs
#           no anti-rotation, so a hex there would be pretence
PKT_SPEC    = ((-1, 'hex', NUT_AF + NUT_AF_CLR, NUT_DEPTH, BOSS_H),)
PKT_PEAK    = True       # 45 deg self-bridging roof over the top flat
PKT_PRESS   = False      # press fit on the nut rather than a clearance fit
SECTION     = 'strut'
XPROBE      = 5.0        # X to probe the 3-prong grid along Y
BODY_FILLET = 0.0        # bottom-edge fillet radius; 0 = no body underside
                         # overhang to excuse (the strut has a flat Kamm base)
BORE_ROUND  = False      # plain round pivot bore instead of a 45 deg teardrop
HEAD_CS     = 0.0        # countersink at the bore mouth, head side; 0 = none
PKT_FLOOR_MIN = 1.20     # the LOADED pocket's floor: what the streamlined arm
                         # has shipped with.  The simple variant raises it,
                         # because it paid part height for exactly that.
SYMMETRIC   = False      # pivot centred in the part: every wall around it is
                         # the same on both sides, and the knuckle is a full
                         # circle rather than one cut off by the bed
SLOT_FLAT   = False      # slot floor is a plane at POCKET_R rather than a
                         # cylinder about the pivot, so the slot is that deep
                         # at every height instead of only at the pivot


def boss_of(side):
    """Local thickening of one outer prong, 0 if that side carries no pocket."""
    for s, _k, _sz, _d, b in PKT_SPEC:
        if s == side:
            return b
    return 0.0


def pkt_radius(kind, size):
    """Outermost radius of a pocket outline, for the overhang classifier."""
    return size/math.sqrt(3) if kind == 'hex' else size/2


def configure(simple):
    """Point the spec at one variant or the other.

    The body section, the screw pockets and the PIVOT HEIGHT move.  Every
    number the mating joint can actually feel -- the 3 mm grid, the clearances,
    the R7.5 envelope -- stays exactly where it is, which is what makes the two
    variants interchangeable in a chain.
    """
    global PKT_SPEC, PKT_PEAK, PKT_PRESS, SECTION, XPROBE, BODY_FILLET
    global BORE_ROUND, HEAD_CS, PKT_FLOOR_MIN, PIVOT_Z, TAB_TOP, SB_H
    global SYMMETRIC, SLOT_FLAT
    if not simple:
        return
    SYMMETRIC = abs(S_PIVOT_Z - TAB_R) < 1e-9
    SLOT_FLAT = True
    # The pivot moves, so everything measured off it moves with it: the probe
    # heights, the pocket floors, the bore, the body height, the flank angle.
    PIVOT_Z = S_PIVOT_Z
    TAB_TOP = S_TAB_TOP
    SB_H = S_TAB_TOP
    # A centred pivot puts the loaded pocket's floor at TAB_R - NUT_AF/2.
    PKT_FLOOR_MIN = 1.90 if not SYMMETRIC else TAB_R - NUT_AF/2 - 0.10
    BODY_FILLET = SB_RB
    BORE_ROUND = True
    HEAD_CS = S_HEAD_CS
    PKT_SPEC = ((S_NUT_SIDE,  'hex',   S_PKT_AF, S_PKT_DEPTH, S_BOSS_NUT),
                (-S_NUT_SIDE, 'round', S_HD_D,   S_HD_DEPTH,  S_BOSS_HD))
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
# Sniff the LAYOUT, not the leading bytes.  A binary STL's 80-byte header is
# free-form, and plenty of exporters open it with the part name -- both
# `inspiration/Quck Release v3 *.STL` begin with the literal ASCII "solid ".
# Deciding on that prefix sent a 141034-facet binary mesh down the ASCII
# branch, where it found no `vertex` lines and returned an EMPTY list.  That is
# not a cosmetic misparse: volume() of nothing is 0.0, and fitcheck.py reads
# 0.0 mm^3 as ZERO INTERFERENCE, i.e. a perfect fit at every hinge angle.  A
# loader that cannot read a file has to say so, not certify it.
#
# `84 + 50*n == filesize` is the discriminator.  It is not a heuristic: it is
# the binary format's own definition, and for an ASCII file to pass it the four
# bytes at offset 80 would have to spell out that file's own length.
def load(path):
    """Triangles from an STL, binary or ASCII.  Never silently empty."""
    size = os.path.getsize(path)
    with open(path, 'rb') as f:
        head = f.read(84)
        n = struct.unpack('<I', head[80:84])[0] if len(head) == 84 else -1
        if 84 + 50*n == size:
            data = f.read()
            tris = []
            for i in range(n):
                v = struct.unpack('<12f', data[i*50:i*50+48])
                tris.append((v[3:6], v[6:9], v[9:12]))
        else:
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
    if not tris:
        # The arithmetic goes in the message on purpose.  The one shape this
        # loader is deliberately stricter about than the old one is a binary
        # file with TRAILING bytes: 84 + 50n misses the size, so it is tried as
        # ASCII and finds nothing.  No file here is written that way, and a
        # speculative fallback would be a code path nothing ever exercises --
        # so it fails instead, and says enough to diagnose it in one look.
        raise ValueError(
            f"{path}: parsed 0 facets. {size} bytes; the header claims {n} "
            f"facets, which wants {84 + 50*n} ({84 + 50*n - size:+d}). "
            f"Refusing to return an empty mesh -- downstream that measures as "
            f"volume 0.0, which reads as a perfect fit.")
    return tris


# ---- loader self-test ------------------------------------------------
# Every other check in this file stands on load(), and its failure mode is
# SILENT: a mesh it cannot read measures 0.0 mm^3 and an inverted bbox, and
# fitcheck.py certifies 0.0 mm^3 as zero interference.  So the loader is tested
# directly, and the test carries a MUTATION CONTROL -- [L4] runs the OLD prefix
# sniff on the same adversarial file and demands that it fail.  Without that,
# [L3] would pass just as happily against the bug it exists to catch, which is
# the same trap fitcheck.py's ctrl_* run guards against.
def _cube_tris(s=2.0):
    """12 facets of an s-cube at the origin.  Volume s^3, bbox 0..s."""
    v = [(x*s, y*s, z*s) for x in (0, 1) for y in (0, 1) for z in (0, 1)]
    quads = [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1),
             (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]
    tris = []
    for a, b, c, d in quads:
        tris.append((v[a], v[b], v[c]))
        tris.append((v[a], v[c], v[d]))
    return tris


def _write_binary_stl(path, tris, header):
    """Binary STL with a chosen 80-byte header -- the point of the test."""
    with open(path, 'wb') as f:
        f.write(header.encode()[:80].ljust(80, b'\0'))
        f.write(struct.pack('<I', len(tris)))
        for t in tris:
            f.write(struct.pack('<3f', 0.0, 0.0, 0.0))
            for p in t:
                f.write(struct.pack('<3f', *p))
            f.write(b'\0\0')


def _write_ascii_stl(path, tris):
    with open(path, 'w') as f:
        f.write('solid test\n')
        for t in tris:
            f.write(' facet normal 0 0 0\n  outer loop\n')
            for p in t:
                f.write('   vertex %.6f %.6f %.6f\n' % p)
            f.write('  endloop\n endfacet\n')
        f.write('endsolid test\n')


def _load_prefix_sniff(path):
    """load() as it was, deciding on the leading bytes.

    Kept ONLY as [L4]'s control.  If this reads the adversarial file correctly
    then the file does not reproduce the bug and [L3] proves nothing.
    """
    with open(path, 'rb') as f:
        head = f.read(84)
        if head[:5] == b'solid':
            f.seek(0)
            tris, vs = [], []
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


def selftest():
    """Prove load() reads what it claims to, and fails loudly when it cannot."""
    import tempfile
    cube = _cube_tris(2.0)                      # 12 facets, volume 8.000
    d = tempfile.mkdtemp(prefix='verify_selftest_')
    plain = os.path.join(d, 'plain.stl')
    adver = os.path.join(d, 'adversarial.stl')
    asc = os.path.join(d, 'ascii.stl')
    junk = os.path.join(d, 'junk.stl')
    _write_binary_stl(plain, cube, 'OpenSCAD Model\n')
    # The exact shape of the bug: a BINARY mesh whose free-form 80-byte header
    # opens with the part name, which happens to start "solid".  Both
    # inspiration/Quck Release v3 *.STL are written this way.
    _write_binary_stl(adver, cube, 'solid Quck Release v3 clip')
    _write_ascii_stl(asc, cube)
    with open(junk, 'wb') as f:
        f.write(b'solid nothing at all\nendsolid nothing at all\n' * 8)

    print("\n=== load() self-test")
    print("\n[L1] binary STL, ordinary header")
    t = load(plain)
    check(len(t) == 12, f"12 facets (got {len(t)})")
    check(abs(volume(t) - 8.0) < 1e-6, f"volume 8.000 (got {volume(t):.6f})")

    print("\n[L2] ASCII STL, same cube -- both encodings must agree")
    t = load(asc)
    check(len(t) == 12, f"12 facets (got {len(t)})")
    check(abs(volume(t) - 8.0) < 1e-6, f"volume 8.000 (got {volume(t):.6f})")

    print("\n[L3] REGRESSION: binary STL whose header begins 'solid'")
    t = load(adver)
    check(len(t) == 12,
          f"read as binary -- 12 facets, not 0 (got {len(t)})")
    check(abs(volume(t) - 8.0) < 1e-6,
          f"volume 8.000, not the 0.000 an empty mesh measures "
          f"(got {volume(t):.6f})")
    lo, hi = bbox(t)
    check(hi[0] > lo[0],
          f"bbox is the right way round ({lo[0]:.3f}..{hi[0]:.3f}) -- an empty "
          f"mesh returns it inverted, which reads as a part with no extent")

    print("\n[L4] CONTROL -- the old prefix sniff on the same file; must FAIL")
    old = _load_prefix_sniff(adver)
    check(len(old) == 0,
          f"prefix sniff returns {len(old)} facets, so the fixture really does "
          f"reproduce the bug and [L3] has teeth")

    print("\n[L5] an unreadable file RAISES rather than measuring as empty")
    try:
        load(junk)
        check(False, "load() returned instead of raising on a 0-facet parse")
    except ValueError:
        check(True, "ValueError, so 'cannot read it' can never reach a caller "
                    "disguised as 'nothing is there'")

    print()
    if FAIL:
        print(f"*** {len(FAIL)} FAILURE(S)")
        for m in FAIL:
            print("   -", m)
        return 1
    print("LOADER SELF-TEST PASSED")
    return 0


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
    ap.add_argument('stl', nargs='?')
    ap.add_argument('--length', type=float)
    ap.add_argument('--gauge', action='store_true')
    ap.add_argument('--simple', action='store_true',
                    help='expect arm_simple.scad: slab body, pocket both sides')
    ap.add_argument('--selftest', action='store_true',
                    help='test load() itself; needs no STL')
    args = ap.parse_args()
    if args.selftest:
        return selftest()
    if args.stl is None or args.length is None:
        ap.error('need <stl> and --length (or --selftest)')
    configure(args.simple)
    L = args.length

    tris = load(args.stl)
    lo, hi = bbox(tris)
    print(f"\n=== {args.stl}  ({len(tris)} facets)")
    print(f"bbox  X {lo[0]:8.3f} .. {hi[0]:8.3f}   ({hi[0]-lo[0]:.3f})")
    print(f"      Y {lo[1]:8.3f} .. {hi[1]:8.3f}   ({hi[1]-lo[1]:.3f})")
    print(f"      Z {lo[2]:8.3f} .. {hi[2]:8.3f}   ({hi[2]-lo[2]:.3f})")
    print(f"volume {volume(tris):.1f} mm^3")
    if SYMMETRIC:
        print(f"\n[0] symmetry -- the pivot is centred, so the part is a "
              f"mirror about z={PIVOT_Z:.3f}")
        check(abs((hi[2]-lo[2]) - 2*PIVOT_Z) < 0.05,
              f"part is {hi[2]-lo[2]:.3f} tall == 2 x the {PIVOT_Z:.3f} pivot "
              f"-- as much knuckle under the bore as over it")

    # ---------------------------------------------------------------- 1
    # The probe X sits inside the R7.5 knuckle but outboard of both the 2.65
    # bore radius and the pocket's across-corners radius, so the ray sees
    # nothing but prongs.  Land it inside the pocket and the 1.50 mm floor
    # wall reads as the whole outer prong -- see configure().
    XP = XPROBE
    face_meas = {}      # measured outer face of each stack side, for [6]
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
        face_meas[-1], face_meas[+1] = o1a, o2b
        boss_m, boss_p = boss_of(-1), boss_of(+1)
        check(abs((o1b-o1a)-(PRONG_OUT_T+boss_m)) < TOL,
              f"-Y outer prong {o1b-o1a:.3f} == {PRONG_OUT_T}+{boss_m} boss")
        check(abs((o2b-o2a)-(PRONG_OUT_T+boss_p)) < TOL,
              f"+Y outer prong {o2b-o2a:.3f} == {PRONG_OUT_T}+{boss_p} boss "
              f"(reinforced from the original's 2.70)")
        check(abs(o2b - (W3_HALF+boss_p)) < TOL,
              f"+Y outer face at {o2b:+.3f} == {W3_HALF+boss_p:.2f}")
        check(abs(o1a + W3_HALF + boss_m) < TOL,
              f"-Y outer face at {o1a:+.3f} == {-(W3_HALF+boss_m):.2f}")
        print(f"     stack width {o2b-o1a:.3f} mm "
              f"(the {2*W3_HALF:.1f} GoPro stack plus {boss_m}+{boss_p} of boss)")
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
        # 0.013 off the pivot's own X, for the same reason [4c] samples off
        # x=7.500: a ray on an exact geometric plane grazes coincident facets
        # and comes back with an odd crossing count.  x=px is now TWO such
        # planes at once -- the body loft's first station, and (with the pivot
        # centred) the line where the knuckle circle touches the bed.  Straight
        # up the pivot the ray reads the tangent facet as a 0.003 mm slab of
        # its own and loses the bore entirely.  The offset costs 0.00003 mm of
        # bore half-height, which is four orders below the tolerance.
        ivz = ray_intervals(tY, (px + 0.013, yprobe, -50.0), 2)
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
            apex = PIVOT_Z + BORE_D/2*math.sqrt(2)
            if BORE_ROUND:
                # The inverse of the teardrop check, and just as necessary: a
                # teardrop satisfies "roof >= round", so only an equality test
                # proves the point was actually removed.
                check(abs(g[1] - (PIVOT_Z + BORE_D/2)) < 0.06,
                      f"bore {name} roof z={g[1]:.3f} is ROUND, stopping at "
                      f"{PIVOT_Z+BORE_D/2:.3f} (a teardrop would reach {apex:.3f}) "
                      f"-- {TAB_TOP-g[1]:.2f} mm of crown over it")
            else:
                # A PLAIN ROUND hole tops out at PIVOT_Z + BORE_D/2.  Requiring
                # merely ">= that" passes a round hole and verifies no teardrop
                # at all; the 45 deg apex must stand clearly above it.
                check(g[1] >= PIVOT_Z + BORE_D/2 + 0.8,
                      f"bore {name} roof z={g[1]:.3f} is a TEARDROP apex "
                      f"(a round hole would stop at {PIVOT_Z+BORE_D/2:.3f}, "
                      f"45 deg apex {apex:.3f})")
            check(g[0] > 2.0, f"bore {name} floor leaves {g[0]:.3f} mm of material under the bore")
            if SYMMETRIC:
                check(abs(g[0] - (TAB_TOP - g[1])) < 0.06,
                      f"bore {name} sits DEAD CENTRE: {g[0]:.3f} under it, "
                      f"{TAB_TOP-g[1]:.3f} over it")
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
    # The knuckle FLANK.  The circle is cut by the bed, so it leaves the bed at
    # asin(PIVOT_Z/TAB_R) from vertical: exactly OH_ANG at the streamlined
    # arm's 5.303 pivot, and 53.13 deg at the simple variant's raised 6.00.
    # Nothing can buy that back -- padding the flank out to 45 deg needs
    # material at R8.49 from the pivot, outside the R7.5 envelope a mating
    # GoPro sweeps -- so on the supported variant it is excused.  Excused, and
    # then pinned: to the angle the pivot height dictates, to the strip below
    # the 45 deg tangent, and to the area that strip actually owes.
    flank_oh = math.degrees(math.asin(min(1.0, PIVOT_Z/TAB_R)))
    flank_top = PIVOT_Z - TAB_R*math.cos(math.radians(OH_ANG))
    # The countersink's own Y band, so it can be told apart from the bore it
    # opens into.  A 45 deg cone sits exactly ON the overhang budget, so it
    # owes no area -- but it has to be NAMED, or it lands in the unclassified
    # bucket and the headline "steepest facet" quietly becomes a report on a
    # cone that is supposed to be there.
    cs_floor = -S_NUT_SIDE*(W3_HALF + S_BOSS_HD - S_HD_DEPTH)
    cs_lo, cs_hi = sorted((cs_floor, cs_floor + S_NUT_SIDE*HEAD_CS))
    worst_oh = 0.0
    bed = 0.0
    slot_area = 0.0
    pkt_area = 0.0
    fil_area = 0.0
    bore_area = 0.0
    flank_area = 0.0
    flank_worst = 0.0
    cs_area = 0.0
    cs_worst = 0.0
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
            for side, kind, size, depth, boss in PKT_SPEC:
                y_out = side*(W3_HALF + boss)
                lo_y, hi_y = sorted((y_out, y_out - side*depth))
                if (r0 <= pkt_radius(kind, size) + 0.15
                        and lo_y - 0.05 <= cen[1] <= hi_y + 0.05):
                    in_pkt = True
        # The knuckle flank, on the strip between the 45 deg tangent and the
        # bed.  Tested on the RADIUS from the pivot, so it cannot excuse
        # anything but the cut circle itself -- and it has to come before the
        # body fillet below, which would otherwise swallow the knuckles too
        # (it excuses everything under z = BODY_FILLET along the whole arm).
        in_flank = (flank_oh > OH_ANG + 1e-9
                    and cen[2] < flank_top + 0.05
                    and abs(min(r0, r1) - TAB_R) <= 0.15)
        # The body's bottom-edge FILLET.  A fillet is tangent to the bed face,
        # so it leaves through 90 deg of overhang -- deliberate here, and the
        # reason this edge was a 45 deg chamfer until the pockets forced
        # support anyway.  It lives low down, along the body, and nowhere else.
        in_fillet = (BODY_FILLET > 0
                     and cen[2] < BODY_FILLET + 0.05
                     and 0.0 <= cen[0] <= L)
        # The pivot bore's roof, once the teardrop is gone.  Keyed on distance
        # from the bore AXIS in XZ, which is a genuine 2D test -- the bore runs
        # in Y, so there is no infinite-cylinder loophole to fall into here.
        in_bore = BORE_ROUND and min(r0, r1) <= BORE_D/2 + 0.15
        in_cs = (HEAD_CS > 0
                 and min(r0, r1) <= BORE_D/2 + HEAD_CS + 0.15
                 and cs_lo - 0.05 <= cen[1] <= cs_hi + 0.05)
        if (not in_slot and not in_pkt and not in_fillet and not in_bore
                and not in_flank and not in_cs):
            worst_oh = max(worst_oh, ang_oh)
        if in_flank:
            flank_worst = max(flank_worst, ang_oh)
        if in_cs and not in_bore:
            cs_worst = max(cs_worst, ang_oh)
        if -n[2] <= lim:                  # within the 45 deg budget + faceting
            continue
        # classify: is it the roof of a slot pocket (a short bridge)?
        if in_slot:
            slot_area += a
        elif in_pkt:
            pkt_area += a
        elif in_flank:
            flank_area += a
        elif in_cs:
            cs_area += a
        elif in_fillet:
            fil_area += a
        elif in_bore:
            bore_area += a
        else:
            bad[round(cen[0], 0)] += a
            bad_pts.append((cen, math.degrees(math.asin(min(1, -n[2]))), a))
    print(f"     steepest facet OUTSIDE the slot roofs {worst_oh:6.2f} deg from vertical")
    print(f"     bed contact area           {bed_area:8.2f} mm^2")
    print(f"     slot-roof bridging area    {slot_area:8.2f} mm^2  (spans the {SLOT_W} mm slot)")
    if not PKT_PEAK:
        print(f"     screw-pocket ROOF area     {pkt_area:8.2f} mm^2  "
              f"(THIS is what needs support)")
    if BODY_FILLET > 0:
        # Predict it: the arc steeper than the budget is r*acos(lim), and the
        # fillet runs the body's length scaled by the same blend the section
        # uses, whose integral is (span - one blend length).
        arc = BODY_FILLET*math.acos(lim)
        eff = max(0.0, (L - 2*POCKET_R) - SB_BLEND)
        fil_exp = 2*arc*eff
        print(f"     body bottom-FILLET area    {fil_area:8.2f} mm^2  "
              f"(vs {fil_exp:.2f} predicted -- r{BODY_FILLET} along {eff:.1f} mm, "
              f"BOTH edges, needs support)")
    if BORE_ROUND:
        # Predicted the same way: the >45 deg arc of a round hole, times the
        # length of MATERIAL the bore actually passes through -- both pocket
        # floors and the middle prong at end A, both fingers at end B.
        bore_arc = 2*(BORE_D/2)*math.acos(lim)
        # ... less the countersink, which replaces its first HEAD_CS mm of
        # cylindrical roof with a 45 deg cone that is inside the budget.
        bore_len = (2*NUT_WALL + FING_W - HEAD_CS) + 2*FING_W
        bore_exp = bore_arc*bore_len
        print(f"     pivot-BORE roof area       {bore_area:8.2f} mm^2  "
              f"(vs {bore_exp:.2f} predicted -- round, not a teardrop, so it "
              f"needs support inside a {BORE_D} hole)")
    if flank_oh > OH_ANG:
        # The strip steeper than the budget runs from the acos(lim) ray to the
        # bed cut, and it is exposed only where the slab body does not bury it:
        # at end A the free half less both slots, plus the two bosses standing
        # proud of the body on the other half; at end B the free half less the
        # central gap, the body side being exactly as wide as the knuckle.
        flank_arc = TAB_R*(math.acos(lim) - math.acos(min(1.0, PIVOT_Z/TAB_R)))
        flank_wid = ((2*W3_HALF + boss_of(-1) + boss_of(+1) - 2*SLOT_W)
                     + (boss_of(-1) + boss_of(+1))
                     + (2*W2_HALF - SLOT_W))
        flank_exp = flank_arc*flank_wid
        shape = "full circle, tangent to the bed" if SYMMETRIC else "cut circle"
        print(f"     knuckle-FLANK area         {flank_area:8.2f} mm^2  "
              f"(vs {flank_exp:.2f} predicted -- the {shape} leaves the bed at "
              f"{flank_oh:.2f} deg, not {OH_ANG}, because the pivot is at "
              f"{PIVOT_Z:.2f}; {flank_arc:.2f} mm of arc along {flank_wid:.1f} "
              f"mm of knuckle)")
    print(f"     unclassified overhang area {sum(bad.values()):8.2f} mm^2")
    # What this is really guarding is PEEL, and peel scales with the length the
    # part contracts over -- a 155 mm arm lifting its ends is the failure, a
    # 36 mm coupon is not the same animal.  A flat 150 applied to both was a
    # number that happened to fit the arms; per-mm-of-length says what is
    # actually meant, with a floor so a tiny part still has to stand on
    # something.  The simple arm's ends are the exposed part either way: its
    # knuckles are tangent to the bed, so read this next to the first-layer
    # reach reported below, not on its own.
    bed_min = max(100.0, 3.0*(hi[0] - lo[0]))
    check(bed_area > bed_min,
          f"bed contact {bed_area:.1f} mm^2 > {bed_min:.0f} "
          f"({bed_area/(hi[0]-lo[0]):.1f} mm^2 per mm of length) is enough to "
          f"hold the part down")
    check(sum(bad.values()) < 0.5,
          f"no unsupported overhang outside the slot roofs ({sum(bad.values()):.3f} mm^2)")
    if bad_pts:
        for cen, ang, a in sorted(bad_pts, key=lambda z: -z[2])[:8]:
            print(f"       at ({cen[0]:.2f},{cen[1]:.2f},{cen[2]:.2f})  {ang:.1f} deg  {a:.3f} mm^2")
    # the slot roof is only acceptable because it bridges a narrow slot
    if BODY_FILLET > 0:
        check(0.75*fil_exp <= fil_area <= 1.25*fil_exp,
              f"body fillet overhang {fil_area:.1f} mm^2 is the {fil_exp:.1f} an "
              f"r{BODY_FILLET} fillet owes (+/-25%) -- present, and no bigger "
              f"than the edge it is supposed to be")
    if HEAD_CS > 0:
        print(f"     bore-mouth COUNTERSINK      {cs_area:8.2f} mm^2  "
              f"(steepest facet {cs_worst:.2f} deg -- a 45 deg cone sits ON "
              f"the budget, so it owes no area and needs no support)")
        check(cs_area < 0.5,
              f"the countersink is a {OH_ANG} deg cone, not steeper: it adds "
              f"{cs_area:.2f} mm^2 of overhang past the budget (cap 0.5)")
    if flank_oh > OH_ANG:
        # The strip is the narrowest of the three excused bands (under a
        # millimetre of arc), so the facets that straddle the faceting cut are
        # a bigger share of it than they are of the fillet or the bore -- hence
        # a wider band than those get.
        check(0.70*flank_exp <= flank_area <= 1.30*flank_exp,
              f"knuckle-flank overhang {flank_area:.1f} mm^2 is the "
              f"{flank_exp:.1f} the {shape} owes (+/-30%) -- what the pivot "
              f"height costs, and nothing else hiding at R{TAB_R}")
        # The angle itself, both ways.  Too steep means the knuckle is not the
        # shape it claims; too shallow means the pivot never actually moved and
        # the whole trade was not made.
        check(abs(flank_worst - flank_oh) <= FACET_TOL,
              f"the flank leaves the bed at {flank_worst:.2f} deg, which is "
              f"the {flank_oh:.2f} a pivot at {PIVOT_Z:.2f} dictates "
              f"(+/-{FACET_TOL} of faceting)")
        # And the part it is paid out of.  With the pivot centred the circle is
        # TANGENT to the bed, so the chord is zero and the knuckle touches on a
        # LINE -- there is no chord left to hold to a minimum.  What is worth
        # measuring instead is how much of the knuckle the FIRST LAYER grabs,
        # because that, plus the brim, is the whole of the end's grip.  The
        # gate is the bed-contact check above, which the slab body carries.
        chord = 2*math.sqrt(max(0.0, TAB_R**2 - PIVOT_Z**2))
        reach = math.sqrt(max(0.0, TAB_R**2 - (PIVOT_Z - LAYER_H)**2))
        print(f"     knuckle bed chord {chord:.2f} mm "
              f"({2*TAB_R/math.sqrt(2):.2f} at the streamlined arm's pivot); "
              f"at the first {LAYER_H} mm layer the knuckle is {2*reach:.2f} mm "
              f"wide, so the outer {TAB_R-reach:.2f} mm of each end is over "
              f"thin air -- BRIM IT")
        # Measured, not just predicted: walk in from -X at one layer height and
        # find where knuckle A actually starts.
        tz = near_axis(near_axis(tris, 2, LAYER_H), 1, 0.0)
        ivl = [(a-50, b-50)
               for a, b in ray_intervals(tz, (-50.0, 0.0, LAYER_H), 0)]
        if ivl:
            got = -ivl[0][0]
            check(abs(got - reach) < 0.15,
                  f"knuckle A reaches x={ivl[0][0]:+.3f} at the first layer, "
                  f"the {-reach:+.3f} a circle {PIVOT_Z:.2f} up owes -- the "
                  f"knuckle really is tangent, not floating and not cut flat")
    if BORE_ROUND:
        check(0.70*bore_exp <= bore_area <= 1.30*bore_exp,
              f"bore roof overhang {bore_area:.1f} mm^2 is the {bore_exp:.1f} a "
              f"round {BORE_D} bore owes (+/-30%) -- the teardrop really is gone, "
              f"and nothing else hides in the bore's radius")
    check(SLOT_W <= 3.5, f"slot-roof bridge span is {SLOT_W} mm (PETG bridges this)")
    check(slot_area < 40.0,
          f"excused slot-roof area {slot_area:.2f} mm^2 stays small (cap 40)")
    if not PKT_PEAK:
        # The pocket roofs are excused because they are SUPPORTED, not because
        # they bridge.  So don't wave them through under a round-number cap --
        # predict the area each pocket shape owes and check against THAT, which
        # also catches a pocket of the wrong size or a missing one.
        #   hex   the top flat, one side length (size/sqrt3) wide
        #   round the arc of the bore steeper than 45 deg, which is the 90 deg
        #         cap over the top: pi*R/2 of arc
        exp = 0.0
        for _s, kind, size, depth, _b in PKT_SPEC:
            exp += (size/math.sqrt(3) if kind == 'hex'
                    else math.pi*size/4) * depth
        print(f"     ... against {exp:.2f} mm^2 predicted by the pocket shapes")
        check(0.65*exp <= pkt_area <= 1.35*exp,
              f"supported roof area {pkt_area:.2f} mm^2 is the {exp:.2f} these "
              f"two pockets owe (+/-35%) -- not more, and not nothing")
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

    # ---------------------------------------------------------------- 4d
    # [4c] measures the slot at the PIVOT, which is where it is deepest on a
    # cylindrical floor and therefore flatters it.  What actually decides how
    # far the joint folds is the slot's reach at the height of the part's TOP
    # and BOTTOM faces, because the surface a mating arm runs into is its own
    # face, not its knuckle:
    #
    #     fold = 2*atan(reach_at_face / h),   h = pivot to face
    #
    # A cylindrical floor pulls back to sqrt(POCKET_R^2 - h^2) there -- 8.11 of
    # the nominal 11.05 at h = 7.5 -- and that shortfall, not the pivot height,
    # is what held the fold to 94.5 deg.  A flat floor holds the full POCKET_R
    # at every height and the fold opens to 111.7.
    print("\n[4d] slot floor profile -- the surface that decides the fold")
    h_face = min(PIVOT_Z - lo[2], hi[2] - PIVOT_Z)

    def slot_reach(z, px=0.0, yslot=U):
        """How far the slot at `yslot` runs from the pivot, at height z."""
        out, shut = 0.0, 0
        for i in range(1, 400):
            xx = px + i*0.05 + 0.013
            iv = [(a-50, b-50) for a, b in
                  ray_intervals(near_axis(tris, 0, xx), (xx, -50.0, z), 1)]
            if not any(a < yslot < b for a, b in iv):
                out, shut = xx - px, 0
            else:
                shut += 1
                if shut >= 3:
                    break
        return out

    # Sample the band the fold geometry actually lives in: +/- h_face about the
    # pivot.  Going higher than that is meaningless on the STRUT, whose section
    # tapers to a 0.4 mm nose -- a ray at the slot's y would sail straight past
    # the part and read the slot as open forever.
    zs = [PIVOT_Z - h_face + 0.30, PIVOT_Z - h_face/2, PIVOT_Z,
          PIVOT_Z + h_face/2, PIVOT_Z + h_face - 0.30]
    worst_dev = 0.0
    for z in zs:
        got = slot_reach(z)
        exp = (POCKET_R if SLOT_FLAT
               else math.sqrt(max(0.0, POCKET_R**2 - (z - PIVOT_Z)**2)))
        worst_dev = max(worst_dev, abs(got - exp))
        print(f"     z={z:6.2f}  slot runs to x={got:6.3f}  "
              f"({'flat' if SLOT_FLAT else 'round'} floor owes {exp:.3f})")
    check(worst_dev < 0.20,
          f"the slot floor is {'FLAT' if SLOT_FLAT else 'a cylinder'} "
          f"-- worst deviation {worst_dev:.3f} mm over the part's full height")
    # The fold formula assumes a body of CONSTANT height, so it belongs to the
    # slab only.  On the strut the chord ramps 12.803 -> 20.0 over the 12 mm
    # after the slots end, so `h` is not one number and the ramp, not the slot,
    # is what binds -- which is why that variant measures -110..+80 instead of
    # anything this would predict.
    if SECTION == 'slab':
        face_reach = slot_reach(PIVOT_Z - h_face + 0.30)
        fold = 2*math.degrees(math.atan2(face_reach, h_face))
        rnd = 2*math.degrees(math.atan2(
            math.sqrt(max(0.0, POCKET_R**2 - h_face**2)), h_face))
        print(f"     at the bottom face the slot reaches {face_reach:.2f}, so "
              f"two arms fold to {fold:.1f} deg -- {180-fold:.1f} deg between "
              f"them (a cylindrical floor would give {rnd:.1f}, "
              f"{180-rnd:.1f} between)")
        if SLOT_FLAT:
            check(fold > 100.0,
                  f"the joint folds {fold:.1f} deg, so two arms close to "
                  f"{180-fold:.1f} deg -- under the 90 the round floor could "
                  f"not beat")

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
        # Bottom flat, measured off the bed face itself.  Unwinding a 45 deg
        # chamfer from the first sample is what this used to do, and a fillet
        # is not a straight line, so that would now read the wrong number.
        ysb = [p[1] for t in tM for p in t if abs(p[2]) < 1e-3]
        base = (max(ysb) - min(ysb)) if ysb else 0.0
        rb = (SB_T - base)/2
        print(f"     height (Z extent)       {height:.3f} mm")
        print(f"     max width               {wmax:.3f} mm")
        print(f"     bed footing at z=0      {base:.3f} mm -> bottom radius {rb:.3f}")
        check(abs(height-SB_H) < 0.05,
              f"body height {height:.3f} == knuckle height {SB_H:.3f} (no chord ramp)")
        check(abs(wmax-SB_T) < 0.15, f"max width {wmax:.3f} == {SB_T}")
        check(abs(rb-SB_RB) < 0.15,
              f"bottom edges are rounded r{rb:.2f} == r{SB_RB}, leaving a "
              f"{base:.3f} mm bed footing")
        # ... and rounded on an ARC, not just cut back.  A chamfer of the same
        # setback would sit 0.73 mm inboard of the fillet at 45 deg round it.
        if SB_RB > 0:
            z45 = SB_RB*(1 - math.sqrt(0.5))
            # the sample AT z45 -- not the min above it, which finds the top
            # rounding instead and reads the section's other end entirely
            w45 = min(prof, key=lambda zw: abs(zw[0]-z45))[1]
            exp45 = SB_T - 2*SB_RB*(1 - math.sqrt(0.5))
            print(f"     width at 45 deg round   {w45:.3f} mm (arc predicts {exp45:.3f}, "
                  f"a chamfer would give {SB_T-2*SB_RB+2*z45:.3f})")
            check(abs(w45-exp45) < 0.20,
                  f"the bottom edge follows an ARC ({w45:.3f} vs {exp45:.3f} at "
                  f"45 deg round it), not a straight cut-back")
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
    for side, kind, size, depth, boss in PKT_SPEC:
        tag = '-Y' if side < 0 else '+Y'
        # MEASURED outer face, not the spec one.  Taking it from the spec makes
        # the depth check read (spec face - measured floor), which passes on a
        # pocket whose boss is wrong -- the depth error hides in the face.
        y_out = face_meas.get(side, side*(W3_HALF + boss))
        y_mid = y_out - side*depth/2
        rad = pkt_radius(kind, size)
        job = ('press-fit M5 nut' if kind == 'hex' and PKT_PRESS
               else 'M5 nut trap' if kind == 'hex'
               else f'counterbore, {HEAD_D} barrel head')
        print(f"\n   pocket {tag}  {kind} {size} x {depth} deep -- {job}")
        print(f"     outer face y={y_out:+.3f}, probed at y={y_mid:+.3f}")
        tN = near_axis(tris, 1, y_mid)

        # widest extent, measured along X through the pivot
        ivx = ray_intervals(near_axis(tN, 2, PIVOT_Z), (-50.0, y_mid, PIVOT_Z), 0)
        ivx = [(a-50, b-50) for a, b in ivx]
        gx = [(ivx[i][1], ivx[i+1][0]) for i in range(len(ivx)-1)]
        if gx:
            ac = gx[0][1]-gx[0][0]
            lbl = 'across corners' if kind == 'hex' else 'bore diameter'
            print(f"     {lbl} {ac:.3f} mm")
            check(abs(ac - 2*rad) < 0.08,
                  f"pocket {tag} {lbl} {ac:.3f} == {2*rad:.3f}")

        # Z extent.  A hex's flats and a round bore's walls both sit at
        # size/2 off the pivot, so the same two numbers cover either.
        ivz = ray_intervals(near_axis(tN, 0, 0.0), (0.0, y_mid, -50.0), 2)
        ivz = [(a-50, b-50) for a, b in ivz]
        gz = [(ivz[i][1], ivz[i+1][0]) for i in range(len(ivz)-1)]
        if gz:
            lo_z, hi_z = gz[0]
            crown = TAB_TOP - hi_z
            print(f"     Z void {lo_z:.3f} .. {hi_z:.3f}, crown above the roof {crown:.3f}")
            check(abs(lo_z - (PIVOT_Z - size/2)) < 0.06,
                  f"pocket {tag} floor at {lo_z:.3f} == {PIVOT_Z-size/2:.3f}")
            if kind == 'hex' and PKT_PEAK:
                check(hi_z >= PIVOT_Z + size/2 + 0.5,
                      f"pocket {tag} 45 deg peak at {hi_z:.3f} clears the top "
                      f"flat {PIVOT_Z+size/2:.3f} (no droop)")
            else:
                roof = 'roof is FLAT' if kind == 'hex' else 'bore tops out'
                check(abs(hi_z - (PIVOT_Z + size/2)) < 0.06,
                      f"pocket {tag} {roof} at {hi_z:.3f} == "
                      f"{PIVOT_Z+size/2:.3f} (support carries it)")
            # A pocket centred on the pivot is ALWAYS thinner underneath: the
            # trimmed knuckle puts the pivot PIVOT_Z above the bed but TAB_R
            # below the crown, and only the floor moves with the pivot.  The
            # simple variant raises it and pays for the floor in part height
            # and flank angle; the streamlined arm and the clamp cannot,
            # because they are printed without support.
            above = TAB_TOP - hi_z
            print(f"     wall to the bed {lo_z:.3f}, to the crown {above:.3f}"
                  + (f"  ({above/lo_z:.1f}x thicker on top)" if lo_z > 0.01 else ""))
            if SYMMETRIC:
                # The whole point of centring the pivot: a pocket is governed
                # by its THINNEST wall, and floor == crown is what maximises
                # that for a given part height.  Measured off the mesh at both
                # ends, so a pocket that drifted off the pivot shows up here
                # rather than in a comment.
                check(abs(lo_z - above) < 0.05,
                      f"pocket {tag} is SYMMETRIC about the pivot: {lo_z:.3f} "
                      f"below == {above:.3f} above (delta "
                      f"{abs(lo_z-above):.4f})")
            check(lo_z >= 0.80,
                  f"pocket {tag} leaves {lo_z:.3f} mm to the bed (floor 0.80)")
            if kind == 'hex':
                # The one that matters: this pocket takes the press fit's hoop
                # stress and the nut's anti-rotation torque.  Benchmark it
                # against a part that has actually been printed and used
                # rather than against a number someone picked.
                # On the simple variant this is 1.90, not the streamlined
                # arm's 1.203: the pivot was RAISED to buy that floor, at 1 mm
                # of part height per 1 mm of pivot, and a part that passed at
                # 1.203 again would have paid the height and given the floor
                # back.
                check(lo_z >= PKT_FLOOR_MIN,
                      f"the LOADED pocket's floor is {lo_z:.3f} >= "
                      f"{PKT_FLOOR_MIN} -- this is the one taking press-fit "
                      f"hoop stress and nut torque")
            check(crown >= 0.45,
                  f"pocket {tag} roof stays {crown:.3f} mm inside the knuckle "
                  f"crown (a wider pocket would burst out of the top)")

        # depth and floor wall
        got = None
        if ivd:
            span = ivd[0] if side < 0 else ivd[-1]
            wall = span[1]-span[0]
            floor_y = span[0] if side < 0 else span[1]
            got = abs(floor_y - y_out)
            check(abs(wall - NUT_WALL) < TOL,
                  f"pocket {tag} floor leaves {wall:.3f} mm before the slot == {NUT_WALL}")
            check(abs(got - depth) < TOL,
                  f"pocket {tag} depth {got:.3f} == {depth}")

        # --- what the pocket is FOR -----------------------------------------
        # Measuring "8.00 across flats" proves nothing on its own: a round hole
        # of the same width passes it and lets the nut spin.  So sweep the
        # radius and ask the question the pocket exists to answer.  The hex
        # outline is convex, so a nut is inside it exactly when its six corners
        # are -- a corner sweep is sound, not an approximation.
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
        rmax = max(prof_r.values())

        if kind == 'hex':
            psis = [0.5*i for i in range(120)]      # one 60 deg hex period
            fits = [p for p in psis
                    if all(r_at(p + 60*j) >= NUT_CORNER for j in range(6))]
            turn = 60.0*len(fits)/len(psis)
            fit = 2*rmin - NUT_AF               # negative == interference
            how = ('INTERFERENCE' if fit < -0.005
                   else 'line-to-line' if fit <= 0.005 else 'clearance')
            print(f"     across flats {2*rmin:.3f} mm -> {fit:+.3f} on a nominal "
                  f"{NUT_AF} nut ({how})")
            print(f"     a centred M5 nut can turn {turn:.1f} deg before it wedges")
            if PKT_PRESS:
                # A press fit is the absence of play, so measure that there is
                # none -- and separately that it is not so deep nothing seats.
                check(fit <= 0.05,
                      f"pocket {tag}: {fit:+.3f} on the nut is a PRESS fit, not "
                      f"a drop-in one (<= +0.05)")
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
        else:
            print(f"     inscribed {2*rmin:.3f} mm, out-of-round "
                  f"{rmax-rmin:.3f} mm  (barrel head {HEAD_D})")
            check(2*rmin >= HEAD_D + 0.10,
                  f"pocket {tag}: a {HEAD_D} barrel head SEATS in it "
                  f"({2*rmin:.3f} bore, {2*rmin-HEAD_D:+.3f} clearance)")
            # A hex here would be pretence, and would also foul the head.
            check(rmax - rmin < 0.10,
                  f"pocket {tag} really is ROUND (out-of-round {rmax-rmin:.3f}) "
                  f"-- a head needs a seat, not anti-rotation")
            check(2*rmin <= HEAD_D + 0.60,
                  f"pocket {tag}: {2*rmin-HEAD_D:+.3f} on the head is a seat, "
                  f"not a hole it wanders in")
            # The whole point of this pocket: measured off the mesh, not read
            # back out of the spec that generated it.
            if got is not None:
                check(got >= HEAD_H + 0.20,
                      f"pocket {tag} is {got:.3f} deep, so a {HEAD_H} mm barrel "
                      f"head sits {got-HEAD_H:.2f} mm BELOW the face, not proud "
                      f"of it")

    # ---------------------------------------------------------------- 7
    if HEAD_CS > 0:
        print("\n[7] countersink at the bore mouth, head side")
        print("     a socket cap screw is not a cylinder standing on a disc:")
        print(f"     ISO 4762 allows the under-head fillet out to da = "
              f"{HEAD_DA}, wider than this {BORE_D} bore, so with no relief the")
        print("     head bears on the bore's EDGE instead of its own annulus")

        def hole_d(y):
            """Bore width across X at height PIVOT_Z, on the plane y."""
            tN = near_axis(near_axis(tris, 1, y), 2, PIVOT_Z)
            ivx = [(a-50, b-50)
                   for a, b in ray_intervals(tN, (-50.0, y, PIVOT_Z), 0)]
            gx = [(ivx[i][1], ivx[i+1][0]) for i in range(len(ivx)-1)]
            near = [g for g in gx if abs((g[0]+g[1])/2) < 3]
            return (near[0][1]-near[0][0]) if near else float('nan')

        hd_side = -S_NUT_SIDE
        y_out = face_meas.get(hd_side, hd_side*(W3_HALF + S_BOSS_HD))
        floor_y = y_out - hd_side*S_HD_DEPTH
        print(f"     head-pocket floor at y={floor_y:+.3f}, "
              f"{NUT_WALL} mm of wall behind it")
        # Sweep INTO the wall.  A 45 deg cone sheds 2 mm of diameter per mm of
        # depth, so the profile pins the angle and the depth at once -- and the
        # samples past HEAD_CS pin where it stops, which is what keeps it from
        # eating through the wall the head bears on.
        for t in (0.05, 0.25, 0.45, 0.75, 1.20):
            y = floor_y - hd_side*t
            got = hole_d(y)
            exp = BORE_D + 2*max(0.0, HEAD_CS - t)
            tail = "countersunk" if t < HEAD_CS else "plain bore"
            check(abs(got - exp) < 0.08,
                  f"{t:.2f} mm into the wall the hole is {got:.3f} == "
                  f"{exp:.2f} ({tail})")
        # What it is FOR, at the plane where the fillet is widest.
        mouth = hole_d(floor_y - hd_side*0.05)
        check(mouth >= HEAD_DA + 0.15,
              f"at the floor the bore is opened to {mouth:.3f}, clearing a "
              f"{HEAD_DA} under-head fillet by {mouth-HEAD_DA:+.3f} -- the head "
              f"seats on the floor, not on the bore's edge")
        # And it is on ONE side.  A nut's bearing face is flat to its thread,
        # so the same cut on the nut side would only thin the wall behind the
        # pocket that carries the press fit.
        nut_y = face_meas.get(S_NUT_SIDE, S_NUT_SIDE*(W3_HALF + S_BOSS_NUT))
        nut_floor = nut_y - S_NUT_SIDE*S_PKT_DEPTH
        nut_mouth = hole_d(nut_floor - S_NUT_SIDE*0.05)
        check(abs(nut_mouth - BORE_D) < 0.08,
              f"the NUT side is left at {nut_mouth:.3f} == {BORE_D}, "
              f"uncountersunk -- a nut has no fillet to clear")

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
