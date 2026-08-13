#!/usr/bin/env python3
"""Measure the pipe clamp mesh against the GoPro interface + clamp mechanics.

The interesting checks are not the dimensions but the MECHANISM: does the
flange actually have room to travel before it bottoms on the mating middle
prong, and is the split genuinely open all the way to the bore.
"""
import math
import sys

from verify import load, bbox, near_axis, ray_intervals, normal   # noqa: E402

# ---- spec (mirrors clamp.scad / arm.scad) ----------------------------
TAB_R      = 7.50
PIVOT_Z    = TAB_R/math.sqrt(2)
TAB_TOP    = PIVOT_Z + TAB_R
BORE_D     = 5.30
OH_ANG     = 45.0
FACET_TOL  = 1.5

PIPE_D     = 12.00
PIPE_CLR   = 0.30
WALL       = 3.00
CLAMP_H    = 16.00
FING_T     = 2.40
FING_OUT   = 4.35
NECK_CLR   = 0.50

SERRATE    = True
TOOTH_N    = 30
TOOTH_W    = 0.70
TOOTH_D    = 0.32
TOOTH_R0   = 4.80
TOOTH_R1   = 11.10

CL_BORE_R  = (PIPE_D + PIPE_CLR)/2      # 6.15
COLL_R     = CL_BORE_R + WALL           # 9.15
COLL_X     = TAB_R + COLL_R + NECK_CLR  # 17.15
SPLIT_G    = 2*(FING_OUT - FING_T)      # 3.90

# mating 3-prong geometry: real GoPro, then our own arm
MATES = (("real GoPro", 3.00, 4.50), ("our arm", 2.90, 4.55))

TOL = 0.05
FAIL = []


def check(ok, msg):
    print(("  PASS  " if ok else "  FAIL  ") + msg)
    if not ok:
        FAIL.append(msg)


def main(path):
    tris = load(path)
    lo, hi = bbox(tris)
    print(f"\n=== {path}  ({len(tris)} facets)")
    print(f"bbox  X {lo[0]:7.3f}..{hi[0]:7.3f}   Y {lo[1]:7.3f}..{hi[1]:7.3f}"
          f"   Z {lo[2]:7.3f}..{hi[2]:7.3f}")

    # ------------------------------------------------------------- 1
    print("\n[1] flanges = GoPro 2-prong fingers (probed along Y at x=-3, pivot height)")
    iv = ray_intervals(near_axis(tris, 0, -3.0), (-3.0, -50.0, PIVOT_Z), 1)
    iv = [(a-50, b-50) for a, b in iv]
    print("     solid spans:", ", ".join(f"[{a:+.3f},{b:+.3f}]={b-a:.3f}" for a, b in iv))
    check(len(iv) == 2, f"exactly 2 flanges (got {len(iv)})")
    if len(iv) == 2:
        (f1a, f1b), (f2a, f2b) = iv
        check(abs((f1b-f1a) - FING_T) < TOL, f"flange 1 thickness {f1b-f1a:.3f} == {FING_T}")
        check(abs((f2b-f2a) - FING_T) < TOL, f"flange 2 thickness {f2b-f2a:.3f} == {FING_T}")
        check(abs((f2a-f1b) - SPLIT_G) < TOL, f"flange gap {f2a-f1b:.3f} == {SPLIT_G}")
        check(abs(f2b - FING_OUT) < TOL, f"outer face {f2b:+.3f} == {FING_OUT}")

        # ---------------------------------------------------------- 2
        print("\n[2] MECHANISM -- travel before the flanges bottom on the middle prong")
        for name, mid, slot_out in MATES:
            fits = f2b <= slot_out - 0.02
            travel = 2*(f2a - mid/2)          # both flanges move inward
            closure = travel * (2*CL_BORE_R)/(COLL_X + CL_BORE_R)
            print(f"     vs {name:10s} (middle prong {mid}, slot wall {slot_out}):")
            print(f"        inserts: {'yes' if fits else 'NO'}   "
                  f"flange travel {travel:.3f} mm   bore closure {closure:.3f} mm")
            check(fits, f"flange enters the {name} slot ({f2b:.2f} vs wall {slot_out})")
            check(closure > PIPE_CLR + 0.10,
                  f"{name}: bore closes {closure:.3f} mm, beats the {PIPE_CLR} slip fit "
                  f"with margin (else it never grips)")

    # ------------------------------------------------------------- 3
    print("\n[3] pipe bore (probed along Y through the collar centre)")
    ivb = ray_intervals(near_axis(tris, 0, COLL_X), (COLL_X, -50.0, CLAMP_H/2), 1)
    ivb = [(a-50, b-50) for a, b in ivb]
    print("     solid spans:", ", ".join(f"[{a:+.3f},{b:+.3f}]={b-a:.3f}" for a, b in ivb))
    check(len(ivb) == 2, f"collar wall either side of the bore (got {len(ivb)} spans)")
    if len(ivb) == 2:
        d = ivb[1][0] - ivb[0][1]
        print(f"     bore diameter {d:.3f} mm  (pipe {PIPE_D} + {PIPE_CLR} slip fit)")
        check(abs(d - (PIPE_D + PIPE_CLR)) < 0.08, f"bore {d:.3f} == {PIPE_D+PIPE_CLR}")
        check(abs((ivb[0][1]-ivb[0][0]) - WALL) < 0.08, f"wall {ivb[0][1]-ivb[0][0]:.3f} == {WALL}")

    # ------------------------------------------------------------- 4
    print("\n[4] the split must reach the bore ACROSS ITS WHOLE WIDTH")
    print("     (the centreline alone is the one place a short cut still looks")
    print("      open -- the bore is round, so its edge recedes off-centre)")
    worst_web = 0.0
    worst_y = 0.0
    for i in range(41):
        y = -SPLIT_G/2 + i*SPLIT_G/40
        y = max(min(y, SPLIT_G/2 - 0.02), -SPLIT_G/2 + 0.02)
        ivx = ray_intervals(near_axis(tris, 1, y), (-60.0, y, CLAMP_H/2), 0)
        ivx = [(a-60, b-60) for a, b in ivx]
        web = sum(b-a for a, b in ivx if a < COLL_X)
        if web > worst_web:
            worst_web, worst_y = web, y
    print(f"     worst leftover material across the split: {worst_web:.4f} mm at y={worst_y:+.2f}")
    check(worst_web < 0.01,
          f"split is open at every y (worst web {worst_web:.4f} mm) -- "
          f"anything here bridges the C shut and stops it flexing")

    # ------------------------------------------------------------- 5
    print("\n[5] collar must clear the mating knuckle's R7.5 sweep")
    gap = (COLL_X - COLL_R) - TAB_R
    print(f"     collar inner edge sits {COLL_X-COLL_R:.2f} from the pivot, "
          f"{gap:.2f} mm clear of R{TAB_R}")
    check(gap > 0.2, f"collar clears the knuckle circle by {gap:.2f} mm")

    # ------------------------------------------------------------- 6
    print(f"\n[6] printability -- overhangs steeper than {OH_ANG} deg from vertical")
    lim = math.sin(math.radians(OH_ANG + FACET_TOL))
    bad = 0.0
    worst = 0.0
    bed = 0.0
    for t in tris:
        n, a = normal(t)
        if n is None or n[2] >= -1e-6:
            continue
        if max(p[2] for p in t) < 1e-4:
            bed += a
            continue
        ang = math.degrees(math.asin(min(1, -n[2])))
        worst = max(worst, ang)
        if -n[2] > lim:
            bad += a
    print(f"     bed contact {bed:.1f} mm^2, steepest down-facing facet {worst:.2f} deg")
    check(bad < 0.5, f"no unsupported overhang ({bad:.3f} mm^2)")
    check(worst <= OH_ANG + FACET_TOL, f"steepest overhang {worst:.2f} <= {OH_ANG} deg")
    check(bed > 80, f"bed contact {bed:.1f} mm^2 is enough to hold it down")

    # ------------------------------------------------------------- 7
    if SERRATE:
        print("\n[7] flange serrations -- what stops the joint angle creeping")
        print("     (this joint has only 2 friction interfaces where a normal")
        print("      GoPro joint has 4, so friction alone was never going to")
        print("      hold it -- the teeth have to index it mechanically)")
        R = 8.0                       # inside the toothed band, in solid material
        faces = []
        for i in range(209):
            a = math.radians(-38 + 0.5*i)
            x = R*math.cos(a)
            z = PIVOT_Z + R*math.sin(a)
            iv = ray_intervals(near_axis(tris, 0, x), (x, -50.0, z), 1)
            iv = [(p-50, q-50) for p, q in iv]
            if len(iv) == 2:
                faces.append((-38 + 0.5*i, iv[-1][1], iv[0][0]))
        check(len(faces) > 180, f"swept the flange face at r={R} ({len(faces)} samples)")
        if faces:
            land = max(f[1] for f in faces)
            floor = min(f[1] for f in faces)
            depth = land - floor
            print(f"     face rides between {floor:.3f} (groove) and {land:.3f} (land)")
            check(abs(land - FING_OUT) < TOL,
                  f"land still sits at the nominal face {land:.3f} == {FING_OUT} "
                  f"-- teeth are cut IN, so insertion clearance is untouched")
            check(abs(depth - TOOTH_D) < 0.06,
                  f"groove depth {depth:.3f} == {TOOTH_D}")
            # symmetry: the -Y flange must carry the same pattern
            asym = max(abs(f[1] + f[2]) for f in faces)
            check(asym < 0.06, f"both flanges carry the same teeth (worst "
                               f"asymmetry {asym:.3f} mm)")
            # A depth measurement alone would pass a face with ONE groove in it.
            # Count the grooves and check the angular pitch.
            thr = land - depth/2
            runs = []
            cur = []
            for ang, yp, _ in faces:
                if yp < thr:
                    cur.append(ang)
                elif cur:
                    runs.append(sum(cur)/len(cur))
                    cur = []
            if cur:
                runs.append(sum(cur)/len(cur))
            # Bearing land measured AT the land plane.  Counting everything
            # above half-depth instead would call the flanks of the V "land"
            # and overstate the contact area by ~20 points.
            land_frac = sum(1 for f in faces if f[1] >= land - 0.05)/len(faces)
            print(f"     {len(runs)} grooves over the swept arc, "
                  f"{100*land_frac:.0f}% of the face left as bearing land")
            check(len(runs) >= 6, f"the face is serrated, not nicked once "
                                  f"({len(runs)} grooves found)")
            if len(runs) >= 2:
                pitch = (runs[-1] - runs[0])/(len(runs) - 1)
                print(f"     angular pitch {pitch:.2f} deg  "
                      f"-> the angle indexes in {pitch:.0f} deg steps")
                check(abs(pitch - 360/TOOTH_N) < 0.5,
                      f"pitch {pitch:.2f} == {360/TOOTH_N:.2f} deg ({TOOTH_N} teeth)")
            # Teeth that eat the whole face would trade friction for nothing.
            check(land_frac > 0.40,
                  f"{100*land_frac:.0f}% of the face still bears load (>40%) -- "
                  f"the teeth bite without throwing away the friction area")

    print()
    if FAIL:
        print(f"*** {len(FAIL)} FAILURE(S)")
        for m in FAIL:
            print("   -", m)
        return 1
    print("ALL CHECKS PASSED")
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1]))
