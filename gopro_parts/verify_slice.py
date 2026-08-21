#!/usr/bin/env python3
"""Slice a part with support DISABLED and look for islands.

    python3 verify_slice.py --selftest
    python3 verify_slice.py --config cfg.ini part.stl [--rotate-x 180]

WHY
---
Two printability defects shipped past a harness that measured the mesh very
carefully.  The mesh was never the problem:

  * the carrier previewed as nothing (a CSG normalization blow-up), and
  * the body needed a pile of support, because two PCB rails stood up off a
    floor that -- printed socket-down -- does not exist yet when they start.

An STL cannot answer either question.  Only the slicer can, so ask it.

WHAT COUNTS AS BAD
------------------
Not "unsupported material" -- every bridge is unsupported, that is what a
bridge is.  The distinction that matters is whether the unsupported region is
ANCHORED: a bridge's outline lands on the wall below it, an island's lands on
nothing.  So this rasterizes each layer, finds connected regions, and fails any
region that does not touch the layer beneath it anywhere.

The old rails are exactly such a region: a closed 19 x 1.2 loop appearing in
mid-air at Z 3.6 with nothing under it.  The floor above them is not, even
though it is a 28.5 mm span, because its rim sits on the bore wall.
"""
import argparse
import math
import os
import re
import subprocess
import sys
import tempfile

CELL = 0.6          # mm -- raster cell; ~1.3 extrusion widths
MIN_CELLS = 3       # ignore specks: a region this small is a seam blob


def slice_gcode(stl, config, rotate_x=0, extra=None):
    out = tempfile.mktemp(suffix=".gcode")
    cmd = ["prusa-slicer", "--export-gcode", "--load", config,
           "--skirts", "0", "--support-material=0", "--output", out]
    if rotate_x:
        cmd += ["--rotate-x", str(rotate_x)]
    if extra:
        cmd += extra
    cmd.append(stl)
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(out):
        raise RuntimeError("prusa-slicer failed:\n%s\n%s" % (r.stdout[-2000:], r.stderr[-2000:]))
    return out


def layers(path):
    """[(z, [(x,y), ...]), ...] of extruding move endpoints, densified."""
    z = None
    x = y = None
    cur = []
    out = []
    for line in open(path, errors='replace'):
        if line.startswith(';Z:'):
            if z is not None:
                out.append((z, cur))
            z = float(line[3:])
            cur = []
        elif line.startswith('G1'):
            mx = re.search(r'X([-\d.]+)', line)
            my = re.search(r'Y([-\d.]+)', line)
            nx = float(mx.group(1)) if mx else x
            ny = float(my.group(1)) if my else y
            if ' E' in line and x is not None and nx is not None:
                # Walk the segment so a long move does not leave gaps.
                d = math.hypot(nx - x, ny - y)
                n = max(1, int(d / (CELL / 2)))
                for i in range(n + 1):
                    t = i / n
                    cur.append((x + t * (nx - x), y + t * (ny - y)))
            x, y = nx, ny
    if z is not None:
        out.append((z, cur))
    return out


def cells(pts):
    return {(int(math.floor(px / CELL)), int(math.floor(py / CELL))) for px, py in pts}


def regions(cs):
    """Connected components, 8-neighbour."""
    seen = set()
    out = []
    for c in cs:
        if c in seen:
            continue
        stack = [c]
        seen.add(c)
        comp = []
        while stack:
            cx, cy = stack.pop()
            comp.append((cx, cy))
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    n = (cx + dx, cy + dy)
                    if n in cs and n not in seen:
                        seen.add(n)
                        stack.append(n)
        out.append(comp)
    return out


def dilate(cs):
    out = set()
    for cx, cy in cs:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                out.add((cx + dx, cy + dy))
    return out


def find_islands(gcode):
    ls = layers(gcode)
    bad = []
    prev = None
    for z, pts in ls:
        if not pts:
            continue
        cs = cells(pts)
        if prev is not None:
            below = dilate(prev)
            for comp in regions(cs):
                if len(comp) < MIN_CELLS:
                    continue
                if not any(c in below for c in comp):
                    xs = [c[0] * CELL for c in comp]
                    ys = [c[1] * CELL for c in comp]
                    bad.append((z, len(comp),
                                (min(xs), max(xs)), (min(ys), max(ys))))
        prev = cs
    return bad, len(ls)


# ---- selftest -------------------------------------------------------------
def selftest():
    """The detector has to see an island that IS there and not invent one that
    is not.  Both halves matter: a probe that never fires is not a gate."""
    ok = True

    # A tower with a detached blob floating above nothing.
    tower = [(0.2 * i, [(x * 0.3, y * 0.3) for x in range(20) for y in range(20)])
             for i in range(1, 6)]
    tower.append((1.2, [(x * 0.3, y * 0.3) for x in range(20) for y in range(20)]
                  + [(50 + x * 0.3, 50 + y * 0.3) for x in range(20) for y in range(20)]))

    def check(ls):
        bad = []
        prev = None
        for z, pts in ls:
            cs = cells(pts)
            if prev is not None:
                below = dilate(prev)
                for comp in regions(cs):
                    if len(comp) >= MIN_CELLS and not any(c in below for c in comp):
                        bad.append((z, len(comp)))
            prev = cs
        return bad

    got = check(tower)
    print("    %-46s %s %s" % ("detached blob is reported", "ok" if got else "FAIL", got))
    ok = ok and bool(got)

    stack = [(0.2 * i, [(x * 0.3, y * 0.3) for x in range(20) for y in range(20)])
             for i in range(1, 7)]
    got = check(stack)
    print("    %-46s %s %s" % ("plain stack is NOT reported", "ok" if not got else "FAIL", got))
    ok = ok and not got

    # A ring whose inside closes over -- a bridge.  Anchored, so it must pass.
    ring = []
    for i in range(1, 6):
        pts = [(15 + 14 * math.cos(a / 30 * math.pi), 15 + 14 * math.sin(a / 30 * math.pi))
               for a in range(60)]
        ring.append((0.2 * i, pts))
    # A real bridged lid is dense parallel extrusions, not a few concentric
    # rings -- five rings 3 mm apart rasterize as five disconnected regions and
    # the detector rightly calls four of them islands.  Fill it like a slicer
    # would, on a grid finer than one extrusion width.
    lid = [(15 + i * 0.4, 15 + j * 0.4)
           for i in range(-35, 36) for j in range(-35, 36)
           if math.hypot(i * 0.4, j * 0.4) <= 14.0]
    ring.append((1.2, lid))
    got = check(ring)
    print("    %-46s %s %s" % ("a bridged lid is NOT reported", "ok" if not got else "FAIL", got))
    ok = ok and not got
    return ok


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stl", nargs="?")
    ap.add_argument("--config")
    ap.add_argument("--rotate-x", type=float, default=0)
    ap.add_argument("--label", default="")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()

    if a.selftest:
        sys.exit(0 if selftest() else 1)

    g = slice_gcode(a.stl, a.config, a.rotate_x)
    bad, n = find_islands(g)
    used = ""
    for line in open(g, errors='replace'):
        if line.startswith('; filament used [cm3]'):
            used = line.split('=')[1].strip() + " cm3"
        if line.startswith('; estimated printing time (normal mode)'):
            used += ", " + line.split('=')[1].strip()
    os.unlink(g)

    name = a.label or os.path.basename(a.stl)
    if bad:
        print("    %-28s FAIL  %d island(s) with nothing beneath them:" % (name, len(bad)))
        for z, nc, xr, yr in bad[:6]:
            print("        Z=%.2f  %d cells  x %.1f..%.1f  y %.1f..%.1f"
                  % (z, nc, xr[0], xr[1], yr[0], yr[1]))
        print("        -- these need support.  Cut the feature INTO a surface")
        print("           instead of standing it ON one, or accept support.")
        sys.exit(1)
    print("    %-28s ok    prints support-free (%s, %d layers)" % (name, used, n))


if __name__ == "__main__":
    main()
