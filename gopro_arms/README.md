# GoPro extension arms — tight fit, two bodies

Parametric replacement for the third-party arms in `inspiration/`. Two things
changed: the prong stack now sits on the **real GoPro 3 mm grid** so a camera
actually clamps, and the square beam was rebuilt — twice. There are two arms
here. They share every millimetre of the GoPro joint and differ only in the body
and the screw pockets, so they chain freely with each other:

| | `arm.scad` — **streamlined** | `arm_simple.scad` — **simple** |
|---|---|---|
| body | Kamm-tail strut, 20.0 mm chord | slab, 12.8 mm, rounded all round (r2.5) |
| for | under the boat, water flowing past it | everything else |
| 100 mm arm | 16.0 cm³, 100 layers | **12.8 cm³, 64 layers** |
| stack width | 18.3 mm | 21.7 mm |
| nut | drop-in, one side | **press fit** (−Y) |
| screw head | stands proud | **flush in a Ø8.8 counterbore** (+Y) |
| articulation | −100…+90° into a GoPro mount | identical |
| support | none | none, **except inside the two nut pockets** |

PETG · Prusa MK3S · 0.4 nozzle · 0.2 mm layers. Everything here is supportless
by construction with exactly one exception, called out below: the simple arm's
nut pockets have a flat roof and are meant to be printed supported.

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
> carries *both* pockets. Print that one to tune the **press fit** before
> committing a plate: the nut should need a push, not a hammer, and it should
> not drop in under its own weight. `pkt_af` in `arm_simple.scad` is the knob.

Slicer notes:

- **Support: off for everything except the simple arm.** Nothing on the
  streamlined arms or the clamp overhangs past 45°, but a stock 45–55° threshold
  sits right on that line, and auto-support will then pack PETG into the GoPro
  slots — exactly the surfaces that must stay clean for the joint to close. So
  turn it off explicitly there.
  The **simple arm is the exception**: it wants support in the screw pockets
  *and* under the body's rounded bottom edges. A **55° threshold** picks up
  exactly those — the steepest facet anywhere else is 45.01°, so nothing else
  gets touched and the GoPro slots stay clean (they measure 0.00 mm² of
  overhang). Do not use "support on build plate only"; the pockets don't touch
  the plate. Then **dig the support out of both pockets** before assembly.
- **Use a brim**, on both. The strut stands 20 mm tall on a 5 mm wide foot over
  155 mm of length; that is a narrow footprint for PETG, whose shrinkage will
  lift the ends given the chance. Bed contact is ~750 mm². The simple arm is
  shorter but its rounded bottom leaves only a 3.9 mm footing, ~732 mm² on the
  100 mm — so it is no less exposed than it looks.
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

> This pocket is a **drop-in** fit — `nut_af_clr = 0.20` — and in the hand the
> nut rattles in it. The simple arm's is a press fit instead; see below. Set
> `nut_af_clr = 0.00` here if you reprint these and want the same. Left as-is
> so the arms already printed still match what is written down.

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

**All four edges are rounded, r2.5**, leaving a 3.9 mm flat on top and the same
on the bed. The section is still **not an ellipse** — that is what the
streamlined arm is for — and the verifier holds the line on it: **66 % of the
section height is a dead-straight vertical flank**, and the check fails under
40 %. It also tests that the bottom edge follows an *arc* rather than a straight
cut-back, by measuring the width 45° round the fillet: 7.419 mm against 7.436
predicted for an arc, where a chamfer of the same setback would read 5.364.

> **The bottom fillet is the expensive edge, and it is a deliberate spend.** A
> fillet is tangent to the bed face, so it leaves through **90° of overhang** —
> which is precisely why this was a 45° chamfer until the pockets made support
> necessary anyway. It costs ~260 mm² of supported area on a 100 mm arm, running
> the **whole length of the underside**, and narrows the bed footing from 5.90 to
> 3.90 mm. Bed contact drops 878 → 732 mm². Set `sb_rb = 0` for a square bottom
> and the underside support disappears.

### Two different pockets — a nut trap and a head seat

| | | |
|---|---|---|
| **−Y** | hex **8.00** across flats, **4.30** deep | press fit on an M5 DIN 934 nut |
| **+Y** | round **Ø8.80**, **5.30** deep | M5 barrel head seats **flush**, 0.30 below the face |

Both bear on their pocket **floor**, the inboard end, so screw tension pulls each
onto solid material rather than trying to lift it out. Stack is **21.70 mm**.

The hex is modelled at nominal 8.00 because FDM lays a pocket down slightly
undersize and that is where the interference comes from — asking for it in the
model *as well* stacks the same tolerance twice.

Both pockets started out 8.80, sized to swallow the barrel head. That leaves the
nut **0.80 mm of play**, and it rattles — the streamlined arm already rattles at
0.20. Sizing them both to the nut fixes the rattle and throws the flush head
away instead: 8.50 will not enter 8.00 flats *at all*, so the head stands fully
proud.

> **Neither compromise is necessary once the two pockets stop having to match.**
> A screw head needs a **seat**; only a nut needs **anti-rotation**. So the head
> gets a round bore and the nut gets a hex, each sized and sunk for exactly what
> goes in it. A hex on the head side would be pretence — and would foul the head
> besides.

What it costs is the nut going on either side: it now lives on `nut_side`
permanently. With a press fit that is what happens anyway — you press it in once
and leave it, and the thing you actually need to reach is the screw head.

For the record, so nobody re-derives it: a barrel head needs 4.25 mm of
clearance in *every* radial direction and a nut that will not rattle needs the
flats at 4.00, so **no single outline satisfies both.** Stepping *one* pocket
doesn't rescue it either — the nut has to pass through the head counterbore to
reach the hex below, so that counterbore must clear the nut's 9.24
across-corners, the two depths add instead of overlapping, and the stack goes
past 30 mm to recess 5 mm of screw head.

### What to put through it

| | |
|---|---|
| **M5×16 socket cap + M5 nut** | what it is built around. Head 0.30 below its face, nut 0.30 below its own, tip stopping 0.40 inside the nut pocket with 3.9 of the nut's 4.0 mm engaged — **nothing protrudes anywhere.** Driven with a 4 mm key, which is far more torque than a thumbscrew and is half the point. |
| GoPro thumbscrew + M5 nut | as `arm.scad`; the head just sits proud |

### Support, in two places

| | area (100 mm arm) | |
|---|---|---|
| screw pockets | 56.49 mm² | hex flat roof + the round bore's 90° cap |
| body bottom edges | 262.89 mm² | the r2.5 fillets, full length of the underside |
| **unclassified** | **0.00 mm²** | everything else is supportless by construction |

**Dig the pocket support out before the nut and the screw go in.**

Neither exemption is a round-number cap — the verifier *predicts* both areas
from the geometry and checks the measurement against them. The pockets owe
56.49 mm² (hex top flat + the bore's >45° arc) and measure 56.49. The fillets
owe 2 × r·acos(lim) × the blended body length, 257.75 mm², and measure 262.89 —
within 2 %, and it tracks at every arm length (67.95 vs 66.74 at 50 mm, 409.60
vs 419.81 at 140 mm). A pocket of the wrong size, a missing fillet or an extra
overhang anywhere shows up as a mismatch instead of passing quietly.

Set `pkt_peak = true` and `sb_rb = 0` to get the supportless part back — square
bottom edges, and a nut seating against a 45° peak instead of a flat roof.

### What it actually saves

Measured off the exported meshes, so the second boss is paid for in these
numbers, not hidden:

| arm | streamlined | simple | saved |
|---|---|---|---|
| 50 mm | 7973 mm³ | 7363 mm³ | 8 % |
| 75 mm | 11994 mm³ | 10087 mm³ | 16 % |
| 100 mm | 16016 mm³ | 12812 mm³ | **20 %** |
| 140 mm | 22450 mm³ | 17171 mm³ | **24 %** |

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

### Optional serrated flanges (`serrate`, default **off**)

An early print held the pipe beautifully and the *hinge angle* still crept under
load — but that was against an **older arm whose slots did not run as deep**.
Against the current arm the same clamp holds both the pipe and the angle fine,
so the teeth are off by default. The reason the slot depth mattered is worth
keeping, because it says exactly when you would want them back.

This joint is the marginal one in the chain, structurally:

```
at the pivot, across Y:  prong | flange | VOID | middle prong | VOID | flange | prong
```

**A normal GoPro joint stacks solid there** — prong, finger, prong, finger,
prong — so the screw squeezes **four** friction interfaces. This clamp cannot:
the flange gap has to stay wider than the middle prong or the collar could never
close, so the middle prong floats and only **two** interfaces carry load. Same
screw force, half the holding torque — at the one joint in the chain carrying the
whole arm and camera on the longest lever. Worse, it is self-defeating in the
good case: on a true 12.0 pipe the collar grips after ~0.28 mm of the 0.50 mm
travel, so ~0.22 mm of that void never closes at all. *The better your pipe fits,
the softer the joint.*

**What rescues it is the other half of the equation — the radius that torque
acts at.** Friction torque is `μ·F·r_eff`, and because the arm's slots run out
to `pocket_r` = 11.05 instead of stopping at the knuckle, the contact annulus is
2.65…11.05 and `r_eff` = **7.71 mm**. On the older arm, whose slots stopped near
8.55, it was **6.12** — about **26 % less holding torque** for the same screw
force, at higher contact pressure. That is the whole difference between the
angle creeping and not. The prong free length was added for spring, and it
bought joint grip as a side effect.

So: **turn the teeth on only if the angle actually creeps.** The likeliest case
is a **real GoPro 3-prong**, whose slots stop at R7.5 and whose `r_eff` is
therefore ~5.46 — roughly 30 % down on our own arm's.

With `serrate = true` you get **30 radial V-grooves cut into each face**, 12°
indexing, biting into the mating prong to hold the angle mechanically. Closing
the void instead is *not* an option — the travel it would remove is exactly the
travel that grips the pipe.

They are not free. The grooves take **~39 % of the bearing area**, index the
hinge in discrete steps instead of continuously, and emboss their pattern into
the mating prong face — that embossing *is* the mechanism. Against a joint that
already holds, that is three costs for no benefit.

- **Cut in, never proud.** The land stays at `fing_out` = 4.35, so insertion
  clearance and collar travel are untouched and every number above still holds.
- **Printability sets the depth.** A groove whose radial line runs horizontal has
  its walls facing up and down, and a symmetric V stays inside the 45° budget
  only while *depth ≤ half-width*. 0.32 deep on 0.70 wide puts them at 42.4°.
- **The inner end ramps in.** A square end is a plane normal to its own radius,
  so on the upward-pointing grooves it is a flat ceiling — 84° of overhang,
  measured, on the first cut of this. A 1.0 mm run-in puts it at 17.8°.
- **61 % of the face is still bearing land**, so the teeth bite without throwing
  away the friction that was already there.

Serrated or not, the clamp is supportless: 0.000 mm² unsupported, steepest
facet 45.00°.

Teeth would go on the **clamp only**. The arms keep smooth slot walls, because
real GoPro fingers are serrated at their own pitch and meshing two mismatched
patterns seats worse than a tooth biting into a flat.

To switch them on: set `serrate = true` in `clamp.scad` **and** `SERRATE = True`
in `verify_clamp.py` — the verifier mirrors the model by hand here, as it does
everywhere else, and check `[7]` only runs when it is on.

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

Eleven mutants, each aimed at one claim, all caught:

| mutant | caught by |
|---|---|
| nut pocket back to 8.80 | +0.800 on the nut, 24° of rotation — not a press fit |
| both pockets hex (no head seat) | +Y reads 9.238 across corners, not a Ø8.800 bore |
| both pockets round (nut would spin) | −Y across-corners 8.800 ≠ 9.238, floor moves 0.4 |
| head pocket too shallow | depth 2.300 ≠ 5.30; head would sit 2.70 *proud* |
| head counterbore undersize | `assert` at render time — it would not seat |
| hex peak put back while the spec says flat | roof at 11.613 ≠ 9.303, ceiling area 36.62 ≠ 56.49 |
| section replaced with a true ellipse | bottom radius reads r4.45, footing 0.000 mm |
| bottom edges left square | fillet area 0.0 ≠ 257.8, footing 8.900 mm |
| bottom edge chamfered instead of filleted | fillet area 0.0, and the arc test reads 5.350 not 7.436 |
| bottom fillet at r4.40 instead of r2.5 | fillet area 463.0 ≠ 257.8, footing down to 0.100 mm |
| clamp teeth cut 0.60 deep (> half-width) | 60.81° overhang, 72 mm² unsupported |

That last one is the useful kind: it proves the *depth ≤ half-width* rule that
keeps the serrations printable is a real constraint the harness enforces, not a
comment someone can quietly ignore.

Two more clamp mutants — flanges left smooth, and teeth at 24 instead of 30 —
were caught when the teeth were on (groove depth 0.000; pitch 15.00° ≠ 12.00°).
They stay valid, but check `[7]` is skipped while `serrate` is off, so re-enable
both flags before trusting it again.

**The head-pocket-too-shallow mutant found a real bug in the harness**, which is
what mutation testing is for. The depth check was taking the *outer face* from
the spec and only the *floor* from the mesh, so a pocket with the wrong boss
measured 5.300 while actually being 2.300 deep — the error hid in the face. It
now reads both ends off the mesh.

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
