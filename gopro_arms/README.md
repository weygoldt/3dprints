# GoPro extension arms — tight fit, two bodies

Parametric replacement for the third-party arms in `inspiration/`. Two things
changed: the prong stack now sits on the **real GoPro 3 mm grid** so a camera
actually clamps, and the square beam was rebuilt — twice. There are two arms
here. They share every millimetre of the GoPro joint and differ only in the body
and the screw pockets, so they chain freely with each other:

| | `arm.scad` — **streamlined** | `arm_simple.scad` — **simple** |
|---|---|---|
| body | Kamm-tail strut, 20.0 mm chord | slab, 12.8 mm, chamfered + rounded |
| for | under the boat, water flowing past it | everything else |
| 100 mm arm | 16.0 cm³, 100 layers | **12.8 cm³, 64 layers** |
| stack width | 18.3 mm | 22.7 mm |
| screw | GoPro thumbscrew + captive nut, one side | nut **or** a flush M5 cap head, **either** side |
| articulation | −100…+90° into a GoPro mount | identical |

PETG · Prusa MK3S · 0.4 nozzle · 0.2 mm layers · **no support** — both of them.

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

Opening a file in the OpenSCAD GUI:

- **`main.scad`** is the entry point — pick the part from the `part` dropdown in
  the customizer.
- `arm.scad`, `arm_simple.scad` and `clamp.scad` also render their own part when
  you open them directly, so none comes up as an empty scene. They are libraries
  though, so `main.scad` is still the place to choose parts.

Or one at a time:

```sh
openscad -o out.stl --render -D 'x=0' -D 'part="arm100"' main.scad
```

Parts, streamlined: `gauge`, `arm50`, `arm75`, `arm100`, `arm140`, `set`,
`section`. Simple: `sgauge`, `simple50`, `simple75`, `simple100`, `simple140`,
`sset`, `ssection`. Plus `clamp`. Arm names are **pivot-to-pivot** distance in mm.

> **Print a gauge first.** It is both ends with no beam, ~10 minutes, and it
> tells you whether the 0.10 mm clearances land right on *your* PETG before you
> commit to a plate of long arms — and it carries the nut pocket, so it checks
> that fit too. If it is tight, raise `slot_extra`; if it rattles, lower it.
> Both live at the top of `arm.scad`. 0.10 is deliberately tight because the
> failure being fixed was too *much* clearance, not too little.
>
> `gauge` is the streamlined one; **`sgauge`** is the simple variant's, and it
> carries *both* pockets — print that one if you intend to use a cap screw, so
> you find out whether your nut and your head actually drop in.

Slicer notes:

- **Turn support OFF explicitly.** Do not just trust the default. Nothing on this
  part overhangs past 45°, but a stock 45–55° threshold sits right on that line,
  and auto-support will then pack PETG into the GoPro slots — exactly the surfaces
  that must stay clean for the joint to close.
- **Use a brim.** The strut stands 20 mm tall on a 5 mm wide foot over 155 mm of
  length; that is a narrow footprint for PETG, whose shrinkage will lift the ends
  given the chance. Bed contact is ~750 mm², about a third less than the arms
  these replace, because the section is a strut instead of a slab. The simple
  arm is less exposed — shorter and a wider footing, 878 mm² on the 100 mm — but
  still brim it.
- Bump perimeters to **4–5**. Neither body is over 10 mm thick, so perimeters do
  most of the structural work and the part comes out nearly solid.
- Flat face on the bed — that is the only orientation either is designed for.

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

**The simple arm measures the same range**, angle for angle, despite being a
12.8 mm slab. That is not a rounding artefact — see *What it does not buy* above
for why the nose fairing was never what limited it.

The knuckle style matters here. `tab_style = "trim"` (default) puts the pivot at
R/√2 so the circle is *cut* by the bed; nothing pokes outside the R7.5 joint
envelope. The alternative `"pad"` hulls a flat pad under a full-height circle —
deeper knuckle, but the pad sticks ~0.6 mm proud and jams the hinge mid-travel:

| | pad | trim |
|---|---|---|
| into a GoPro mount | −40 … +90° | **−100 … +90°** |
| arm to arm | ±40° | **−90 … +40°** |

## The simple arm (`arm_simple.scad`)

The streamlined arm pays for its section. Under the boat that is the right
trade; on a tripod, a handlebar or a bench it is just cost. This variant spends
the budget differently. **The joint is byte-for-byte the same** — same 3 mm grid,
same 0.10 clearances, same trimmed knuckle, same teardrop bore, same 3.3 mm of
prong free length — so the two chain with each other and with real GoPro
hardware without a thought.

### The body

A constant slab **exactly as tall as the knuckle** (12.803 mm). That one choice
removes the chord ramp entirely: the top face is a single flat plane from knuckle
to knuckle and the loft only has to flare the *width*, 15.9 → 8.9 mm.

Edges are smoothed but the section is **not an ellipse** — that is what the
streamlined arm is for, and an ellipse is unprintable here anyway:

- bottom edges: **45° chamfer**, 1.5 mm. Not a fillet — a fillet turns down
  through vertical as it approaches the bed and overhangs. The chamfer sits
  exactly on the 45° budget the rest of the part already spends.
- top edges: **r2.5 rounding**, leaving a 3.9 mm flat on top. Upward-facing, so
  it costs nothing.
- **72 % of the section height is a dead-straight vertical flank.** `verify.py`
  measures that fraction and fails under 40 %, which is the check that encodes
  "smoothed, not faired".

Bed contact goes *up*, 772 → 878 mm² on a 100 mm arm, because a 5.9 mm chamfered
footing is wider than the strut's 5.0 mm Kamm base.

### One pocket, two jobs

Both outer prongs carry a pocket, so the nut goes on **whichever side you can
reach** and the other pocket swallows a screw head. Both parts bear on the pocket
**floor**, which is the inboard end, so screw tension pulls each onto solid
material rather than trying to lift it out.

The pocket has to be one shape doing two jobs, and the two jobs disagree:

|  | across | so the pocket needs |
|---|---|---|
| M5 DIN 934 nut | 8.00 flats, 9.24 corners | flats ≥ 8.0, corners ≥ 9.24 |
| M5 DIN 912 cap head | 8.50 round | flats ≥ 8.5 |

The head is *wider across its flats than the nut is*, so a pocket that swallows
the head cannot also be a zero-slop nut trap. It is sized to the head — **8.80
across flats** — and the nut then has some rotational play in it. How much is the
number that matters, and it is measured off the mesh, not asserted:

```
pocket   8.80 flats -> flat at r4.400, corner at r5.081
M5 nut   8.00 flats -> flat at r4.000, corner at r4.619
```

The nut's **corners stand outside the pocket's flats**, so it wedges after
**24°**. That is all a nut trap has to do — hold it still while the screw is
driven. The nut also floats ~0.4 mm sideways, which is a feature: the screw pulls
it into line instead of fighting a pocket too tight to move.

> **A button head does not fit, and the geometry says so rather than taste.**
> ISO 7380 M5 is 9.50 across, so its pocket would need 9.80 across flats, and the
> 45° roof peak over that flat lands at z = 13.03 against a knuckle crown of
> 12.80 — the pocket would burst out of the top of the knuckle. `arm_simple.scad`
> asserts on it at render time. Use a **socket cap head**. As built, the peak
> clears by 0.56 mm and the pocket floor leaves 0.90 mm to the bed.

### What to put through it

Stack is 22.70 mm wide; each pocket is 5.30 deep, which swallows a 5.0 mm cap
head flush and leaves an M5 nut 1.3 mm below the face.

| | |
|---|---|
| **M5×16 socket cap + M5 nut** | nothing protrudes at either face — the low-profile mount |
| M5×18 socket cap + M5 nut | 0.6 mm of thread proud of the far face |
| M5 hex-head bolt + free nut | the bolt head is 8.0 AF, so the pocket traps *it* — drive from the nut end |
| GoPro thumbscrew + M5 nut | as `arm.scad`, but now with a choice of side |

### What it actually saves

Measured off the exported meshes, so the second boss is paid for in these
numbers, not hidden:

| arm | streamlined | simple | saved |
|---|---|---|---|
| 50 mm | 7973 mm³ | 7305 mm³ | 8 % |
| 75 mm | 11994 mm³ | 10029 mm³ | 16 % |
| 100 mm | 16016 mm³ | 12754 mm³ | **20 %** |
| 140 mm | 22450 mm³ | 17113 mm³ | **24 %** |

The saving grows with length because the two bosses are a fixed cost paid at one
end: on the 50 mm arm they eat most of it. **If you want a short arm, the
streamlined one is barely heavier** — pick the simple one there for the screw
arrangement, not for the mass. Print time falls further than volume does: 12.8 mm
tall instead of 20.0 is **64 layers instead of 100**, each with a shorter
perimeter loop, and on a nearly-solid part that is where the time goes.

### What it does *not* buy

**Articulation is unchanged** — identical to the streamlined arm at every angle
tested (−100…+90 into a GoPro mount, −110…+80 arm to arm). This looks like it
should have improved, so it is worth saying why it did not: what limits the swing
is the full-height, full-width block between the pivot and the end of the slots,
and that block is *identical* in both arms because the slots have to run out to
`pocket_r` either way. The 20 mm chord was never the binding constraint; it only
starts ramping up once it is already clear of it.

## Pipe clamp (`part="clamp"`)

A split collar for a **12 mm pipe** whose two flanges *are* the GoPro fingers.
No clamp screw of its own: slip the collar over the pipe, push the flanges into
a 3-prong end, tighten the arm's thumbscrew, and the collar closes on the pipe.

> **`pipe_d` is the pipe's OUTSIDE diameter, assumed 12.0 mm.** If your "12 mm"
> pipe is a nominal-*bore* size its OD is more like 16–18 mm. Measure it and
> change the one line.

**The thing that makes or breaks this design.** The 3-prong's **middle prong is
a hard stop** sitting in the flange gap — the flanges can only move until they
touch it. With standard 2.90 mm fingers in 3.10 mm slots that is 0.20 mm of
squeeze, and the lever from the pivot down to the split turns it into ~0.10 mm
at the bore. That would be a rattle, not a clamp.

So the flanges are deliberately **undersize (2.40 mm) and sit outboard (outer
face at ±4.35)**, which leaves the gap wider than the middle prong on purpose.
Measured off the mesh:

| mating 3-prong | flange travel | bore closure |
|---|---|---|
| real GoPro (3.00 prong, 4.50 wall) | 0.900 mm | **0.475 mm** |
| our arm (2.90 prong, 4.55 wall) | 1.000 mm | **0.528 mm** |

Against a 0.30 mm slip fit, so the pipe is gripped well before the flanges bottom
out. Both failure directions are graceful: an oversize pipe means the flanges
never reach the middle prong and the whole screw load goes into the grip; an
undersize pipe means they bottom out and the joint still clamps.

Bore closure is less than flange travel because the collar rotates about its far
side — `closure = travel × 2a/(D + a)`, with `a` the bore radius and `D` the
pivot-to-collar distance. Moving the collar closer to the pivot would improve the
ratio, but it has to clear the mating knuckle's R7.5 sweep; it currently clears
by 0.50 mm.

The pipe axis runs along **Z, the build direction**, so the bore is a plain
vertical hole — round where it matters, no support, 45° lead-ins both ends. That
also fixes the orientation: the GoPro screw squeezes along Y, so the collar has
to lie in the XY plane for the squeeze to close the split at all.

Clear articulation in our own arm: **−110 … +90°**.

## Verifying

```sh
python3 verify.py stl/gopro_arm_100mm.stl --length 100            # measures the MESH
python3 verify.py stl/gopro_arm_simple_100mm.stl --length 100 --simple
python3 fitcheck.py                                               # mating interference
python3 fitcheck.py --simple
python3 fitcheck.py --simple --chain     # also arm-to-arm, which is slower
```

`--simple` swaps in the slab-section and two-pocket expectations. Everything
about the GoPro interface is checked identically either way, because it *is*
identical — that is the claim the shared checks exist to defend.

`verify_clamp.py` does the same for the clamp, and its most useful check is not
a dimension: it computes the flange travel and resulting bore closure and fails
if the closure does not beat the slip fit, i.e. if the clamp could never grip.

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

The simple variant's checks were built the same way, because the obvious ones are
the blind ones. Measuring "pocket is 8.80 across flats" proves nothing on its own
— **a plain round hole of the same width passes it and lets the nut spin.** So
the pocket check does not measure a dimension, it answers the two questions the
pocket exists for: it sweeps the pocket's radius by ray-casting and reports how
far a centred M5 nut can turn before its corners bind (24.0° as built; a round
hole reads 60.0°, i.e. free), and whether the inscribed circle really admits a
Ø8.5 cap head. The outline is convex, so testing the nut's six corners is a sound
test of containment rather than an approximation.

Six mutants, each aimed at one new claim, all caught:

| mutant | caught by |
|---|---|
| pocket sized to the nut alone (the naive design) | cap head no longer seats |
| pocket turned into a round hole of the same width | nut turns 60.0°, i.e. not trapped |
| section replaced with a true ellipse | straight flank falls to 10 % (<40 %) |
| bottom edge filleted instead of chamfered | 82.5° overhang, 157 mm² unsupported |
| only one pocket, as `arm.scad` has | every `+Y` pocket check |
| button head instead of a cap head | `assert` at render time — it never builds |

## Reinforcement, and where it is still weakest

- outer prongs of the 3-prong end **3.40** vs 2.70 (+26 %); they carry the clamp,
  and the nut-side one is 5.80 thick where the boss is — **6.80 on both sides**
  on the simple arm, which carries two
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
