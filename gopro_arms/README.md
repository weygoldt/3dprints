# GoPro extension arms — tight fit, streamlined

Parametric replacement for the third-party arms in `inspiration/`. Two things
changed: the prong stack now sits on the **real GoPro 3 mm grid** so a camera
actually clamps, and the square beam became a **streamlined strut** because these
hang under a boat and have water flowing past them.

PETG · Prusa MK3S · 0.4 nozzle · 0.2 mm layers · **no support**.

---

## What was wrong with the originals

Measured straight off `inspiration/7.5cm_Gopro_Arm.stl`:

| | original | this design | GoPro nominal |
|---|---|---|---|
| 3-prong: outer prongs | 2.70 | **3.40** (reinforced) | 3.00 |
| 3-prong: middle prong | 2.50 | **2.90** | 3.00 |
| 3-prong: slots | **4.00** | **3.10** | 3.00 |
| 3-prong: stack width | 15.90 | 15.90 | 15.00 |
| 2-prong: fingers | 3.40 | **2.90** | 3.00 |
| 2-prong: central gap | 3.70 | **3.10** | 3.00 |
| pivot bore | 5.30 | 5.30 | M5 |
| knuckle radius | 7.503 | 7.50 | 7.5 |
| beam section | 9.30 × 14.93 rectangle | strut, 10.0 × 20.0 | — |

A nominal 3.00 mm GoPro finger dropped into a **4.00 mm** slot has 1.0 mm of
rattle, and the original's own 3.40 fingers sat in a 3.70 gap. With that much
slop the prongs bottom out against each other before the faces ever grip, so the
thumbscrew cannot clamp the joint no matter how hard you turn it.

Everything here is on a ±3.00 mm grid with **0.10 mm** of clearance per feature:
slots are 3.10 (accept a 3.00 finger), fingers are 2.90 (enter a 3.00 slot). That
is a slip fit that still leaves the screw something to squeeze.

The originals also **needed support material** — their knuckle is a full circle
sitting tangent on the bed, i.e. a knife edge. This one is cut flat by the bed.

> **Not backward-compatible with the old arms.** The originals' 2-prong fingers
> measure **3.40 mm** and will not enter these **3.10 mm** slots. These arms chain
> with each other and with real GoPro hardware; they do not chain onto an old
> arm's 2-prong end. (The reverse works: our 2.90 fingers drop into their sloppy
> 4.00 slots — loosely, which is the problem being fixed.)

## Print it

```sh
./build.sh            # renders every part to stl/ and verifies each one
```

Or one at a time:

```sh
openscad -o out.stl --render -D 'x=0' -D 'part="arm100"' main.scad
```

Parts: `gauge`, `arm50`, `arm75`, `arm100`, `arm140`, `set`, `section`.
Arm names are **pivot-to-pivot** distance in mm.

> **Print `gauge` first.** It is both ends with no beam, ~10 minutes, and it
> tells you whether the 0.10 mm clearances land right on *your* PETG before you
> commit to a plate of long arms — and it carries the nut pocket, so it checks
> that fit too. If it is tight, raise `slot_extra`; if it rattles, lower it.
> Both live at the top of `arm.scad`. 0.10 is deliberately tight because the
> failure being fixed was too *much* clearance, not too little.

Slicer notes:

- **Turn support OFF explicitly.** Do not just trust the default. Nothing on this
  part overhangs past 45°, but a stock 45–55° threshold sits right on that line,
  and auto-support will then pack PETG into the GoPro slots — exactly the surfaces
  that must stay clean for the joint to close.
- **Use a brim.** The strut stands 20 mm tall on a 5 mm wide foot over 155 mm of
  length; that is a narrow footprint for PETG, whose shrinkage will lift the ends
  given the chance. Bed contact is ~750 mm², about a third less than the arms
  these replace, because the section is a strut instead of a slab.
- Bump perimeters to **4–5**. The strut is only 10 mm thick, so perimeters do
  most of the structural work and the part comes out nearly solid.
- Flat face on the bed — that is the only orientation this is designed for.

## Prong flex

The slots run **3.3 mm past** the mating knuckle (`prong_free = 2.5`, pocket
radius 11.05 vs the R7.5 + 0.25 mating envelope). Without that the prongs root
out exactly where the mating part sits, so all the spread needed to get a camera
in and out lands on the root fillet.

Root stress in a cantilever goes as `t/L²`, so moving the root from r=8.55 out to
r=11.05 is worth roughly **40 % less root stress** for the same spread, and makes
the prong about **2.2× more compliant** — it springs instead of hinging. (Scaling
argument, not FEA, but the exponent is what matters here.)

The width flare starts *where the slots end* rather than at the knuckle edge, so
the prong root sits in full-thickness 3.40 mm material instead of in the taper.
Two things fell out of that for free:

- there are now **no sub-45° surfaces anywhere** — even the slot-roof bridges the
  previous revision had are gone (0.00 mm²), because the slots run past the point
  where the body starts to rise;
- arm-to-arm articulation went from −90…+40° to **−110…+80°**.

Tips stay at R7.5 — that is the standard, and our 2-prong fingers have to enter a
real GoPro's R7.75 pocket, so the length had to come from the root end.

## Captive M5 nut

The 3-prong end carries a hex pocket for a standard **M5 DIN 934** nut (8.0 across
flats, 4.0 thick), so the GoPro thumbscrew pulls up one-handed instead of needing
a spanner on the back.

The outer prong is only 3.40 thick — thinner than the nut — so that prong is
locally thickened by **2.40 mm**. The boss reuses the knuckle silhouette, so it
stands on the bed like everything else and fades to nothing at the edge of the
R7.5 circle rather than leaving a step. Local stack width is **18.3 mm**; it sits
outboard of any mating part, so it costs no articulation (measured: the ranges
below are identical with and without it).

The pocket is oriented with hex **flats top and bottom** — a vertex up would put
the roof at 60° from vertical — and carries a 45° peak above the top flat so
nothing droops into it while it bridges. Pocket floor leaves 1.50 mm before the
slot breaks through.

For a nyloc (DIN 985, 5.0 thick) set `nut_t = 5.0`; the boss grows to match.
Because the nut sits at the far face, the thumbscrew needs roughly **18 mm** of
thread under the head to engage it fully.

## Mount it

```
   +X  arm length, points DOWN in use, camera at the far end
   +Y  hinge axis — ATHWARTSHIP (port/starboard)
   +Z  fore-aft AND the build direction
         Z = 0   flat face  →  AFT
         Z = 20  rounded nose  →  FORWARD
```

**Mount with the flat face aft and the rounded nose into the flow.** The section
is symmetric left/right, so port vs starboard does not matter — only which way
the flat face looks.

The hinge axis is athwartship on purpose: consecutive GoPro joints have parallel
axes, so the whole chain articulates in one plane, and you want that plane to be
the vertical fore-aft one so the joint *tilts the camera up and down*.

## The section

A Kamm-tail strut, not an ellipse — the flat face is the truncated tail, not a
blunt base:

- flat trailing base **5.0 mm** (the bit on the bed, facing aft)
- max thickness **10.0 mm** at 30 % of chord behind the nose
- chord **20.0 mm**, rounded nose, leading-edge radius ≈ 4.2 mm
- **fineness ratio 2.0** vs the original's 1.6 rectangle with four sharp corners

Truncating the tail rather than running it to a point is what makes it printable:
the section widens off the bed at only **16.7°** from vertical, so nothing
overhangs. The win over the original is less about peak drag and more about
**vortex shedding** — a sharp-cornered rectangular beam sheds a strong alternating
wake, which is what shakes the camera.

## Articulation — a real trade-off

Measured with `fitcheck.py` as boolean interference against a synthetic,
exactly-nominal GoPro part. Range with **zero** interference:

| pairing | clear range |
|---|---|
| into a GoPro mount | −100 … +90° |
| our end into a GoPro socket | −90 … +100° |
| arm to arm | −110 … +80° |
| *original arms, same test* | *every angle* |

The originals never foul because their body is a 15 mm slab exactly matching the
knuckle diameter — two such slabs sharing a pivot cannot collide. A 20 mm nose
fairing gives that up. Collinear (0°) has wide clearance either side, which is
where an arm hanging under a boat actually sits, so this is a deliberate cost of
the streamlining rather than a defect.

The knuckle style matters here. `tab_style = "trim"` (default) puts the pivot at
R/√2 so the circle is *cut* by the bed; nothing pokes outside the R7.5 joint
envelope. The alternative `"pad"` hulls a flat pad under a full-height circle —
deeper knuckle, but the pad sticks ~0.6 mm proud and jams the hinge mid-travel:

| | pad | trim |
|---|---|---|
| into a GoPro mount | −40 … +90° | **−100 … +90°** |
| arm to arm | ±40° | **−90 … +40°** |

## Verifying

```sh
python3 verify.py stl/gopro_arm_100mm.stl --length 100   # measures the MESH
python3 fitcheck.py                                       # mating interference
```

`verify.py` measures the exported mesh by ray-casting, not the OpenSCAD source,
so it catches modelling mistakes as well as parameter typos: prong grid at both
ends, bore geometry, a full overhang audit, the R7.5 joint envelope, and the
strut profile.

`fitcheck.py` runs a boolean intersection against an ideal GoPro part and reports
the volume. It includes a **control** that drives the mating part 1 mm off-axis
and must report non-zero — if the control ever reads zero the probe is blind and
the other numbers mean nothing. `build.sh` gates on it.

Both harnesses were themselves attacked by an adversarial review, which found
three ways they could pass a bad part, now fixed:

- the overhang classifier excused an **infinite cylinder in Y** around each pivot,
  so any down-facing facet near a knuckle was waved through as a "slot roof". It
  now also requires the facet to be inside an actual slot's Y band.
- the bore check used `>=`, which a **plain round hole** satisfies; it now
  requires the 45° teardrop apex to stand clearly above where a round hole stops.
- `fitcheck.py` read a **failed render as zero interference**. OpenSCAD also exits
  non-zero on a legitimately empty result, so returncode alone conflates the two;
  it now discriminates on the empty-object message and raises on anything else.
- the articulation summary printed `min..max` of the clear angles, which would
  hide a hinge that **jams solid mid-travel**. It now reports the contiguous band
  through collinear and names any unreachable islands.

The checks are mutation-tested: a plain round bore, a 3.50 mm slot, and a `pad`
knuckle each fail loudly.

## Reinforcement, and where it is still weakest

- outer prongs of the 3-prong end **3.40** vs 2.70 (+26 %); they carry the clamp,
  and the nut-side one is 5.80 thick where the boss is
- **0.80 mm fillet** at the slot floor, placed *outside* the R7.5 mating envelope
  so it never eats into the slot width the mating knuckle needs
- the flare from the 10 mm beam to the 16 mm stack is solid
- PETG rather than PLA
- the arm lies flat, so bending stress runs along X — in-plane for every layer,
  never across them

The thinnest load path is the 2-prong end's **2.80 mm fingers**, which is fixed
by the standard and cannot be thickened. The `"trim"` knuckle also leaves only
**2.65 mm** of material under the pivot bore (the originals had 4.85). The full
4.85 mm remains on the loaded side and around the bore radially, so this mostly
costs the reverse-load direction.
