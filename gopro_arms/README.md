# GoPro extension arms — tight fit, two bodies

Parametric replacement for the third-party arms in `inspiration/`. Two things
changed: the prong stack now sits on the **real GoPro 3 mm grid** so a camera
actually clamps, and the square beam was rebuilt — twice. There are two arms
here. They share every millimetre of the GoPro *interface*, so they chain freely
with each other and with real hardware; what differs is the body, the screw
pockets and the bore:

| | `arm.scad` — **streamlined** | `arm_simple.scad` — **simple** |
|---|---|---|
| body | Kamm-tail strut, 20.0 mm chord | slab, 15.0 mm, rounded all round (r2.5) |
| for | under the boat, water flowing past it | everything else |
| 100 mm arm | 16.0 cm³, 100 layers | **15.1 cm³, 75 layers** |
| stack width | 18.3 mm | 21.7 mm |
| knuckle | circle **cut** by the bed, pivot at 5.303 | **full R7.5 circle**, pivot centred at 7.500 |
| walls round the pivot | 1.203 below / 1.033 above | **equal**: 3.500 nut, 3.100 head, 4.850 bore |
| nut | drop-in, one side | **press fit** (−Y) |
| screw head | stands proud | **flush in a Ø8.8 counterbore** (+Y), countersunk |
| pivot bore | 45° teardrop, self-bridging | plain **round**, dead centre in the prong |
| slot floor | cylinder about the pivot | **flat** — folds to 68° between arms |
| articulation | −100…+90° into a GoPro mount | −90…+90°; **arm-to-arm ±105** |
| support | **none** | pockets, bottom edges, bores, knuckle undersides |

PETG · Prusa MK3S · 0.4 nozzle · 0.2 mm layers. The streamlined arm and the
clamp are supportless by construction and should have support turned off
explicitly. **The simple arm is the one part that wants it** — it trades its
self-bridging geometry, and then its cut-off knuckle, for a rounder, tighter,
symmetric part, and the four supported regions are itemised and area-checked
below.

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
  The **simple arm is the exception**: it wants support in the screw pockets,
  under the body's rounded bottom edges, inside the pivot bores, and — since
  the pivot is centred — under the **knuckle undersides**, which are now
  tangent to the bed and leave it at 90°. Use a **55° threshold** and do not
  use "support on build plate only" — the pockets don't touch the plate.
  > **Expect support in the GoPro slots too, and that is fine here.** The
  > *facet* measurement says the slots hold 0.00 mm² of overhang steeper than
  > 45°, but a slicer decides on its own criteria — contour against the previous
  > layer, bridge detection, its own thresholds — and in practice it puts
  > support in them. Observed on the plate, not predicted by the harness. It
  > comes out easily, and the round bores would have put support through that
  > region anyway. **This is only true of the simple arm**: on the streamlined
  > arms and the clamp, support in the slots is the failure the warning above is
  > about, and it must stay off.

  Then **dig the support out of the pockets and slots** before assembly, and run
  a 5 mm drill through the bores if they come out ragged.
- **Use a brim**, on both. The strut stands 20 mm tall on a 5 mm wide foot over
  155 mm of length; that is a narrow footprint for PETG, whose shrinkage will
  lift the ends given the chance. Bed contact is ~750 mm². The simple arm is
  shorter but its rounded bottom leaves only a 3.9 mm footing, **575 mm²** on
  the 100 mm — and its centred pivot makes each knuckle **tangent** to the bed,
  so at the first layer each end grabs a strip only 3.44 mm wide with the outer
  5.78 mm over thin air. The two ends are the part that lifts; brim them.
  `sb_rb = 0` widens the footing from 3.90 to 8.90 mm if that is not enough.
- Bump perimeters to **4–5**. Neither body is over 10 mm thick, so perimeters do
  most of the structural work and the part comes out nearly solid.
- **7 bottom solid layers on the simple arm.** With the pivot centred the walls
  round the pockets are 3.500 and 3.100 mm — 17 and 15 layers at 0.2 mm — so 7
  (1.4 mm) of solid bottom plus the solid skin the slicer lays under each
  pocket void closes them with room to spare. They were 1.303 and 0.903 at the
  original pivot, which is where this setting came from; see *The centred
  pivot*. Infill 40 % gyroid is otherwise plenty; the walls and shells carry
  this part, not the fill.
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

**The simple arm no longer measures the same range** — it is a 15 mm slab on a
centred pivot, so it carries a full `tab_r` of body *below* the hinge, and it
comes out at ±90 into a mount instead of −100…+90. See *What it does not buy*
below for the full table and for why the nose fairing was never the constraint.

The knuckle style matters here. `tab_style = "trim"` (default) *cuts* the pivot
circle with the bed, so nothing pokes outside the R7.5 joint envelope at any
pivot height. The streamlined arm and the clamp sit at R/√2, where the cut face
leaves the bed at exactly 45° and the part prints unsupported; the simple arm
sits at `tab_r`, where the cut degenerates and the knuckle is the full circle.
The alternative `"pad"` hulls a flat pad under a full-height circle — deeper
knuckle, but the pad sticks ~0.6 mm proud and jams the hinge mid-travel:

| | pad | trim |
|---|---|---|
| into a GoPro mount | −40 … +90° | **−100 … +90°** |
| arm to arm | ±40° | **−90 … +40°** |

## The simple arm (`arm_simple.scad`)

The streamlined arm pays for its section. Under the boat that is the right
trade; on a tripod, a handlebar or a bench it is just cost. This variant spends
the budget differently. **The mating interface is identical** — same 3 mm grid,
same 0.10 clearances, same trimmed knuckle, same R7.5 envelope, same 3.3 mm of
prong free length — so the two chain with each other and with real GoPro
hardware without a thought. What differs is the body, the screw pockets and the
bore, and all three follow from one decision: this variant is printed with
support, so it stops paying for self-bridging geometry it no longer needs.

### The body

A constant slab **exactly as tall as the knuckle** (15.000 mm). That one choice
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
> necessary anyway. It costs ~263 mm² of supported area on a 100 mm arm, running
> the **whole length of the underside**, and narrows the bed footing from 8.90 to
> 3.90 mm. Bed contact drops 942 → 603 mm², both measured off the mesh. Set
> `sb_rb = 0` for a square bottom and the underside support disappears.

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

### Support, in four places

| | area (100 mm arm) | |
|---|---|---|
| screw pockets | 56.49 mm² | hex flat roof + the counterbore's 90° cap |
| body bottom edges | 262.89 mm² | the r2.5 fillets, full length of the underside |
| knuckle undersides | 156.85 mm² | the centred pivot's bill: **tangent to the bed, 90°** |
| pivot bores | 48.80 mm² | round instead of teardropped — **inside a Ø5.3 hole** |
| **unclassified** | **0.00 mm²** | everything else is supportless by construction |

The knuckle undersides are the only one of the four that does **not** grow with
length — an end feature, 156.85 mm² on the 50, the 100 and the 140 alike. On a
50 mm arm they are the *largest* supported region, bigger than the fillets.

**Dig the pocket support out before the nut and the screw go in.** The bore
support is the fiddliest of the three; a 5 mm drill clears it if it comes out
ragged, and the screw seats on the *bottom* of the bore so the top is clearance
either way.

None of these is a round-number cap — the verifier *predicts* each area from the
geometry and checks the measurement against it:

| | predicted | measured |
|---|---|---|
| pockets | 56.49 | 56.49 |
| fillets | 257.75 | 262.89 |
| bores | 45.07 | 48.80 |
| knuckle undersides | 154.31 | 156.85 |
| countersink | 0.00 | 0.00 |

and the fillet prediction tracks at every length (67.95 vs 66.74 at 50 mm,
409.60 vs 419.81 at 140 mm). A pocket of the wrong size, a missing fillet, a
teardrop that crept back or an extra overhang anywhere shows up as a mismatch
instead of passing quietly.

Two of those rows are worth a note. The **bore** prediction is 2.01 mm² lighter
than it used to be because the countersink replaces the first 0.50 mm of the
head-side bore roof with a 45° cone — and a 45° cone sits *on* the budget, which
is why the **countersink** row predicts and measures 0.00 and still gets a check:
cut that cone any steeper and area appears where the harness says there should
be none. The measurements run a few per cent over their predictions throughout,
because a facet that straddles the 46.5° faceting cut is counted whole — the
knuckle undersides land within 1.6 % because at a tangent circle the strip is a
full quarter of arc, wide enough that the straddling facets barely register.

`sb_rb = 0`, `pkt_peak = true`, `bore_round = false` and
`s_pivot_z = tab_r/sqrt(2)` give the supportless part back — square bottom
edges, a nut seating on a 45° peak, a pointed bore, a knuckle cut off at 45°.

### The centred pivot

**The pivot sits at `tab_r`, so the knuckle is the full R7.5 circle, tangent to
the bed, and the whole part is a mirror about the pivot plane.**

A pocket centred on the pivot has `floor = pivot − half` and `crown = R − half`,
so **only the floor moves with the pivot** — and a pocket is governed by its
*thinnest* wall. Centring the pivot is simply the choice that maximises the
minimum, at any given height:

| pivot | nut wall, below / above | head wall | under the bore | part height |
|---|---|---|---|---|
| 5.303 (trim, as `arm.scad`) | 1.303 / 3.500 | 0.903 / 3.100 | 2.653 | 12.803 |
| 6.000 (the interim raise) | 2.000 / 3.500 | 1.600 / 3.100 | 3.350 | 13.500 |
| **7.500 (centred)** | **3.500 / 3.500** | **3.100 / 3.100** | **4.850** | 15.000 |

Two numbers become one number, and the bore ends up **dead centre in the prong**.
It is also the *standard* knuckle — a real GoPro's is a full circle. `arm.scad`'s
trim is our printability hack, not the shape the joint is supposed to be, and
this variant no longer needs the hack because it is printed with support.

`arm.scad`'s `tab_profile2d`, `tab_solid`, `pocket` and `bore` take an optional
pivot height defaulting to their own, so the **streamlined arm and the clamp are
untouched** — both stay supportless at 5.303, and the proof is that their
exported meshes are *byte-identical* across the change. There is no second code
path for the full circle either: at `pivot = tab_r` the bed cut degenerates by
itself, because the slab it intersects with spans exactly `0 … 2·tab_r` and
already contains the whole circle.

#### What it costs

| | at 6.000 | at 7.500 |
|---|---|---|
| knuckle underside off the bed | 53.13° | **90°** (tangent) |
| bed chord per knuckle | 9.000 | **0.000** |
| bed contact, 100 mm arm | 714 mm² | **603 mm²** |
| support under the knuckles | 26 mm² | **157 mm²** |
| 100 mm arm | 13537 mm³ | **15065 mm³** |
| into a GoPro mount | −100…+90° | **−90…+90°** |
| arm to arm | −110…+80° | **−80…+80°** |

**The adhesion loss is far smaller than "the chord is zero" suggests** — 603 mm²
against 714. The slab body is a full-width, flat-bottomed block for the first
11 mm at each end, and it was always doing most of the holding; the knuckle
chord it gives up was sitting on top of the body's own footprint anyway. What
*is* gone is the outer half of each end: at the first 0.2 mm layer the knuckle
is only **3.44 mm wide**, so the outer 5.78 mm of each end is over thin air
until support catches it. **Brim it.** If a print lifts at the ends, `sb_rb = 0`
is the first lever — a square bottom edge takes the footing from 3.90 to 8.90 mm
and buys back far more than the chord ever did.

**Articulation is where the real bill lands**, and it is worth being plain about:
arm-to-arm loses 30° on the bed side. The body now sits a full `tab_r` *below*
the pivot instead of 6.00, and that is the direction that costs swing. The
consolation is that the range became **symmetric** — ±80 arm-to-arm, ±90 into a
mount — which is what a mirror-symmetric body must do, and 0° (collinear) still
has wide clearance either side, which is where the arm is actually used.

Two notes on living with it:

- **Both walls are now the loaded wall's wall.** The hex pocket takes the
  press-fit hoop stress and the nut's torque, and it sits in 3.500 mm all round
  against the 1.203 the streamlined arm has been flying with. The check follows
  the geometry: whenever the pivot is centred the harness stops checking a
  minimum and starts checking **floor == crown**, measured off the mesh.
- **Print it solid.** At 0.2 mm layers the thinnest wall is 15 layers, so the
  usual **7 bottom solid layers** covers it with room to spare.

### The slot floor

**The slot between the prongs has a flat floor, not a cylinder about the pivot.**
The cylinder is the obvious shape — it is the negative of the mating knuckle —
but it was costing the whole of the fold range, and for nothing.

The mating knuckle is R7.5 and `pocket_r` is 11.05, so those two surfaces have
**3.55 mm of slack and never touch.** The slot's depth is set by `prong_free`,
which exists to give the prongs length to spring on, not by anything on the
mating part. What the slot floor actually meets is the mating arm's **face** —
and a cylinder is at its shallowest exactly where that face arrives:

| | at the pivot | at the top/bottom face |
|---|---|---|
| cylindrical floor | 11.05 | **8.11** = √(11.05² − 7.5²) |
| flat floor | 11.05 | **11.05** |

That 8.11 was the binding number. The fold obeys

**fold = 2·arctan(reach_at_face / h)**,  h = pivot to face

which gives 94.5° round and **111.5° flat** — 86° between two arms versus **68°**.
Measured, the boolean fit check puts the boundary at ~110°, within a degree of
the geometry.

It costs nothing where prong flex is measured: at the pivot the slot is 11.05
deep either way, so `prong_free` is untouched at 3.30 mm. The bill is **28 mm²
of bed contact**, the same at every length because it is the corner of each slot
at the bed face — 603 → 575 mm² on the 100 mm arm, and 160 → 132 on the gauge.
That last one pushed the gauge under the old flat 150 mm² bed-contact gate, which
was a number sized for a 155 mm arm; peel scales with the length the part
contracts over, so the gate is now **3 mm² per mm of length**, floored at 100.

Going further — a genuinely *convex* floor, bulging past `pocket_r` at the
faces — buys more still (13.05 would give 120°), but it eats the beam's outer
fibre right at the joint, which is where the bending moment is highest. Flat is
the point where the slot stops being the constraint at all.

`pocket()` takes `flat=false` by default, so the streamlined arm and the clamp
keep the cylinder and stay byte-identical.

### The round bore

`arm.scad`'s bore is a 45° teardrop so it can bridge its own roof. **Its bore
stays that way, and so does the clamp's** — both are still printed without
support. Only the simple arm goes round, and it gains something for it: the
teardrop's apex cuts up to z = 9.05, a round bore stops at 7.95, so there is
**4.86 mm of material over the bore instead of 3.75**.

The check inverts rather than disappearing. A teardrop satisfies "roof ≥ round",
so only an equality test proves the point was actually removed — the same trap
the original `>=` bore check fell into, in the other direction.

### The countersink at the bore mouth

Where the Ø5.30 bore breaks into the head counterbore there is a **45°
countersink, 0.50 mm deep**, opening the mouth to Ø6.30.

**A socket cap screw is not a cylinder standing on a disc.** ISO 4762 puts a
fillet under the head and allows it out to **da = 5.70 across — wider than this
bore.** With no relief that fillet lands on the sharp inside corner of the
counterbore, and the head bears on a Ø5.30 *circle* instead of on its own flat
annulus: it stands a hair proud, it rocks, and the whole of the screw tension is
carried on that edge. FDM makes it worse, an inside corner between a horizontal
hole and its counterbore floor being exactly where a perimeter bulges inward.

0.50 mm clears da by 0.30 all round and leaves **1.00 mm of the 1.50 mm floor
wall**. It costs no bearing area worth counting: the head seats out to r 4.25,
and the annulus this eats is r 2.65…3.15 — where the fillet was going to sit
anyway. The screw sits no deeper, because the floor plane it bears on has not
moved.

**Head side only.** A nut's bearing face is flat to its thread, so there is no
fillet to clear; the same cut on the nut side would take 0.50 mm off the wall
behind the pocket that carries the press fit and buy nothing. The harness
measures the bore's width at five depths into the wall — a 45° cone sheds 2 mm
of diameter per mm of depth, so the profile pins the angle, the depth and where
it stops all at once — and then checks the **nut side is still a plain 5.300**.

### What it actually saves

Measured off the exported meshes, so the second boss is paid for in these
numbers, not hidden:

| arm | streamlined | simple | saved |
|---|---|---|---|
| 50 mm | 7973 mm³ | 8663 mm³ | **−9 %** (heavier) |
| 75 mm | 11994 mm³ | 11864 mm³ | 1 % |
| 100 mm | 16016 mm³ | 15065 mm³ | 6 % |
| 140 mm | 22450 mm³ | 20188 mm³ | **10 %** |

**Be honest about this table: the mass advantage is mostly gone, and at 50 mm it
has inverted.** The two bosses are a fixed cost paid at one end, and the centred
pivot added 2.2 mm of height on top of that — the 100 mm arm has gone 12812 →
13537 → 15065 mm³ across the two pivot moves. **Do not pick this variant for
weight.** Pick it for the screw arrangement, the symmetric walls, and the print
time, which still falls further than volume does: 15.0 mm tall instead of 20.0
is **75 layers instead of 100**, each with a shorter perimeter loop, and on a
nearly-solid part that is where the time goes.

### What it does *not* buy

**Articulation is not just unimproved — the centred pivot costs some.** The body
was never the binding constraint: what limits the swing is the full-height,
full-width block between the pivot and the end of the slots, identical in both
arms because the slots have to run out to `pocket_r` either way. But *height*
below the pivot is exactly what that block is made of, and centring the pivot
puts a full `tab_r` under it:

| | streamlined | simple @ 5.303 | simple @ 6.000 | simple @ 7.500 | **+ flat slot** |
|---|---|---|---|---|---|
| into a GoPro mount | −100…+90 | −100…+90 | −100…+90 | −90…+90 | −90…+90 |
| our end into a socket | −90…+100 | −90…+100 | −90…+100 | −90…+90 | −90…+90 |
| arm to arm | −110…+80 | −110…+80 | −110…+80 | −80…+80 | **−105…+105** |

Centring the pivot cost arm-to-arm 30° — a full `tab_r` of body now hangs under
the hinge, and that is the direction that costs swing. **The flat slot floor
gives 25° of it back**, and then some: two arms now close to **68° between
them**, where the old cylindrical floor could not beat 86°. See *The slot floor*
below; that is where the fold was actually being lost.

The mount cases stay at ±90 because the flat floor does not help there — what
stops them is the synthetic reference's own body, a solid 15 mm block whose near
face is tangent to R7.5, not anything on our part. Every range is now
**symmetric**, which is what a mirror-symmetric body must do.

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

## Quick-release buckle (`part="buckle"`)

The one part here we did not draw. `buckle.scad` **imports**
`inspiration/Quck Release v3 clip.STL` and changes it in one way: it stops
taking a GoPro hand screw and starts taking the pairing the simple arm is built
around — an M5 socket cap head one side, a press-fit M5 nut the other. The
body, the latch, the rails and the 3-prong joint are the donor's and are not
touched.

### What the donor actually is

Everything below is measured off the mesh, not read off a drawing:

| | |
|---|---|
| hinge axis | along **X** |
| pivot | y 15.240, z 12.700; bore **5.461** through all three prongs |
| knuckle | **R 7.3655**, flat to ±0.0006 over its whole free arc (−80…+90°) |
| slots | x 11.506…14.681 and 17.856…21.031, both **3.175** |
| middle prong | x 14.681…17.856, **3.175** |
| far outer prong | x 21.031…23.635 — only **2.604**, well under a unit |
| prints on | the **y = 0** plane: 718 mm², nearly 4× the next largest face. **+Y is up.** |

> **The grid is imperial.** Both slots and the middle prong are 3.175 = 1/8″.
> Our arms are built on a 3.00 mm grid with a 3.10 slot, so **this buckle's
> middle prong is 0.075 wider than our 2-prong end's central gap.** That is a
> real interference, not mesh noise — it reads 3.175 at every radius and every
> angle probed. It is the donor's tolerance, not ours, and nothing here loosens
> our arm to suit it. Ease the buckle's middle prong or squeeze it: 0.075 total
> across a PETG finger is a firm push, not a jam.

Note also that the two outer prongs are **not** on the grid and not equal to
each other, so do not predict either outer face from the 1/8″ pattern.

### The donor already had the nut trap

The low-x prong carries a boss standing out to x 5.0164 with a hexagon cut into
it, floor at x 8.903. That hexagon measures **8.0010 across flats** — the same
nominal 8.00 as `pkt_af`, arrived at independently — and it is **flats up** in
the print orientation, the same choice `arm_simple.scad` argues for. So the nut
pocket is not something this file invents. All that was missing was **0.413 mm
of depth**: at 3.887 the donor's pocket is shallower than a 4.00 mm DIN 934 nut
and leaves it standing 0.113 proud.

We re-cut it anyway, at our own `pkt_af` and `pkt_depth`, for a reason that is
not cosmetic: **a pocket the donor owns is a pocket that changes silently if the
donor mesh is ever re-exported.** Cutting it here makes the depth ours and makes
it something `verify_buckle.py` can hold to a number. Our hex is 0.0005 narrower
on the radius, so in practice the donor's own walls still govern the fit and
only the floor moves — from 8.903 to 9.316, spending 0.413 of a 2.603 mm wall
and leaving **2.190**, still 0.690 over `nut_wall`.

### Where each pocket goes — not a choice

The donor decided it. Its nut trap is in the low-x prong; the hand screw's head
bore against the plain high-x face at x 23.635. So the head counterbore goes
where the head already went, and the nut stays where the nut already is.
Swapping them would mean filling a good 8.00 hex and cutting a new one 18 mm
away — three changes to save none.

The far prong is only **2.604** thick, and a 5.00 mm cap head sunk `head_seat`
below flush wants `hd_depth + nut_wall` = 6.80. Hence a **4.196 mm boss**.

### The boss, and the one envelope rule

Nothing may poke outside R7.5 about the pivot or the hinge jams part-way through
its travel. The boss is a disc of the **donor's own** knuckle radius, 7.3655,
not our `tab_r` of 7.50 — so it is provably not one micron outside a silhouette
the part already had, and it clears the R7.5 rule by 0.135 into the bargain.
Same trick as `side_boss()` in `arm_simple.scad`, with the donor's circle
standing in for `tab_solid()`.

**It costs nothing in bounding box.** The donor's own body already reaches
x 32.537, well past the 27.831 the boss stops at, so the part does not get one
micron bigger. The flex insert is clear too, by a wide margin: its nearest
vertex to the pivot axis is at r 10.388, and there is no insert material at all
inside r 9.0.

What the boss does *not* share with `arm_simple`'s bosses is a footing. There
the knuckle is tangent to the bed and the boss stands on it. Here the knuckle
floats — its lowest point is y 7.8745 — and the buckle's own body runs beneath
as a shelf falling from y 7.457 to 6.819. So the boss underside starts **0.42 mm
above solid material where it begins and 1.06 mm above it where it ends**: two
to five layers of air at 0.2 mm, directly over a wide flat shelf. A short
bridge, not a cliff.

### Print it

**Not** like the arms. This part prints on its **y = 0 face** (`+Y` up) and it
**needs support**, in the same four places `arm_simple` does and for the same
reasons: the hex roof is flat, the head counterbore's roof is a ceiling however
you cut it, the donor's pivot bore is round, and the boss underside bridges to
the shelf. **Dig the pockets out before the nut and the screw go in.**

**What fits it: an M5×16 socket cap + M5 nut**, driven with a 4 mm key instead
of a thumb. Head sunk 0.30 below the boss face, nut 0.30 below its own.

The screw length is a genuine either/or, and worth stating because the obvious
guess is wrong. The head bears on its counterbore floor at x 22.531 and the nut
spans 5.316…9.316, so a shank needs **17.215** to fill the nut and may not
exceed **17.515** before it pokes out of the boss face. **Nothing standard lands
in that 0.30 mm window:**

| | |
|---|---|
| M5×16 | 2.785 of the nut's 4.00 engaged, **nothing proud anywhere** |
| M5×18 | the whole nut, standing **0.485 proud** of the boss face |
| M5×20 | the whole nut, standing **2.485 proud** — no |

Buy the 16. 2.785 mm is ~3.5 turns of steel on steel, and this joint fails in
the PETG round the pocket long before an M5 thread strips, so the extra
engagement buys nothing — while half a millimetre of screw sticking out of a
part whose whole job is to be clipped on and off costs snagging.
`verify_buckle.py` `[8]` re-derives every number above from the mesh, because
the file previously claimed an M5×20 with "nothing protruding", which is wrong
by 2.5 mm — exactly the kind of number nobody checks until they are holding the
part and the screw.

## Verifying

```sh
python3 verify.py --selftest                                      # the LOADER first
python3 verify.py stl/gopro_arm_100mm.stl --length 100            # measures the MESH
python3 verify.py stl/gopro_arm_simple_100mm.stl --length 100 --simple
python3 verify_buckle.py stl/gopro_qr_buckle.stl                  # the buckle
python3 fitcheck.py                                               # mating interference
python3 fitcheck.py --simple
python3 fitcheck.py --simple --chain     # also arm-to-arm, which is slower
```

### The loader, and a fourth way to pass a bad part

`build.sh` now runs `verify.py --selftest` **first**, because every check in
every harness reaches the mesh through one function and its failure mode was
silent.

`load()` decided binary-vs-ASCII on whether the file began with the bytes
`solid`. A binary STL's 80-byte header is free-form, and plenty of exporters
open it with the part name — **both `inspiration/Quck Release v3 *.STL` begin
with the literal ASCII `solid `.** So a 141 034-facet binary mesh went down the
ASCII branch, found no `vertex` lines, and returned an **empty list**. That is
not a cosmetic misparse: `volume()` of nothing is 0.0, an empty `bbox()` comes
back inverted, and **`fitcheck.py` reads 0.0 mm³ as zero interference — a
perfect fit at every hinge angle.** Same class of false pass as the three the
adversarial review found, and it was live.

Two fixes, because there were two links:

- `load()` now sniffs the **layout**, not the leading bytes: `84 + 50n ==
  filesize`. That is not a heuristic, it is the binary format's own definition,
  and for an ASCII file to pass it the four bytes at offset 80 would have to
  spell out that file's own length. It also **raises rather than returning
  empty** — a loader that cannot read a file has to say so, not certify it.
- `fitcheck.py` wrapped `volume(load(out))` in `except Exception: v = 0.0`,
  which turned every way of failing to *read* a mesh back into "no
  interference". By that point the render has succeeded and the file is ≥ 100
  bytes, so there is no benign parse failure left to absorb. The wrapper is
  gone.

`--selftest` covers both encodings, and its `[L3]` is the regression: a binary
STL whose header begins `solid` must read as 12 facets, not 0. `[L4]` is its
**control** — it runs the *old* prefix sniff on the same fixture and demands
that it fail. Without that, `[L3]` would pass just as happily against the bug it
exists to catch. Restoring the bug turns the suite red in four places.

`--simple` swaps in the slab-section and two-pocket expectations. Everything
about the GoPro interface is checked identically either way, because it *is*
identical — that is the claim the shared checks exist to defend.

`verify_clamp.py` does the same for the clamp, and its most useful check is not
a dimension: it computes the flange travel and resulting bore closure and fails
if the closure does not beat the slip fit, i.e. if the clamp could never grip.

`verify.py` measures the exported mesh by ray-casting, not the OpenSCAD source,
so it catches modelling mistakes as well as parameter typos: prong grid at both
ends, bore geometry, a full overhang audit, the R7.5 joint envelope, the strut
profile, and — on the simple variant — the countersink, swept at five depths
into the pocket floor wall.

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

Twenty-four mutants, each aimed at one claim, all caught:

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
| teardrop bore put back on the simple arm | roof 9.748 ≠ 8.650, bore ceiling 0.0 ≠ 45.1 |
| clamp teeth cut 0.60 deep (> half-width) | 60.81° overhang, 72 mm² unsupported |
| countersink removed | `assert` at render time — the mouth would not clear da 5.70 |
| countersink cut at 63° instead of 45° | the profile reads 5.300 at 0.25 mm deep, not 5.800 |
| countersink cut on the nut side too | the nut side reads 6.200, not a plain 5.300 |
| pivot dropped back to 5.303 | `assert` at render time — the floors fall under 1.50 |
| ... and again with those asserts defeated | 28 checks, from the bore floor outward |
| pivot moved off centre by 0.25 | 27 checks; part 14.750 ≠ 15.000 tall, bore 4.607 under / 5.107 over |
| knuckle cut flat again while the spec says tangent | 9 checks; the first layer reaches 0.000 where a tangent circle owes 1.720 |
| head counterbore 0.4 deeper | 7 checks; depth 5.700 ≠ 5.30 and the boss grows with it |
| nut pocket widened to 8.80 | walls 3.100 ≠ 3.500, and +0.800 on the nut is not a press fit |
| slot floor reverted to a cylinder | floor deviates 2.687 mm; fold drops to 96.2° |
| slot floor kept flat but pulled in 1.5 mm | prong free length 1.76 < 2.5, floor deviates 1.537 |
| hex pocket rotated 30°, vertex down | both walls drop to 2.881, and the roof bursts 0.6 mm higher |

That last one is the useful kind: it proves the *depth ≤ half-width* rule that
keeps the serrations printable is a real constraint the harness enforces, not a
comment someone can quietly ignore.

Two more clamp mutants — flanges left smooth, and teeth at 24 instead of 30 —
were caught when the teeth were on (groove depth 0.000; pitch 15.00° ≠ 12.00°).
They stay valid, but `verify_clamp.py`'s check `[7]` is skipped while `serrate`
is off, so re-enable both flags before trusting it again. (`verify.py` has a
`[7]` of its own now — the countersink — which is unrelated.)

**The head-pocket-too-shallow mutant found a real bug in the harness**, which is
what mutation testing is for. The depth check was taking the *outer face* from
the spec and only the *floor* from the mesh, so a pocket with the wrong boss
measured 5.300 while actually being 2.300 deep — the error hid in the face. It
now reads both ends off the mesh.

### The buckle (`verify_buckle.py`)

Two questions, and they need different instruments.

**What we added** is measured off the finished mesh by ray-casting, the same way
`verify.py` measures an arm. Every number is checked against a *prediction from
the geometry*, never against a round number: the nut floor lands at 9.316 =
face 5.0164 + `pkt_depth`; the head floor at 22.531 = boss face 27.831 −
`hd_depth`, leaving exactly `nut_wall`; the relief measures 5.661 / 5.961 /
6.261 at 0.10 / 0.25 / 0.40 mm out from its start, i.e. a true 45°.

**What we did not touch** cannot be measured that way at all. "The rest of the
buckle is unchanged" is a claim about two *sets*, and a pocket cut in the wrong
place measures exactly as well as one cut in the right place. So `[2]` renders
the two set differences through `buckle_diff.scad` and measures those:

| | |
|---|---|
| `added` | `buckle()` − donor. Must be **459.926 mm³** against 459.969 predicted from the boss area less the Ø8.8 bore, × 4.196. |
| `removed` | donor − `buckle()`. 56.743 mm³, both pockets. |
| `*_stray` | each of the above minus a conservative fence round where the change is *allowed* to be. Both read **0.000000 mm³**. |
| `ctrl` | the donor differenced against itself shifted 0.5 mm. Must be non-zero — 769.6 mm³ — or the boolean-and-measure path is blind. |

The fences in `buckle_diff.scad` are written out as plain numbers rather than
built from `buckle.scad`'s own modules, deliberately: **a bound that shared code
with the thing it bounds would agree with its bugs.**

`[2]` is measured by *volume*, never by vertex position. Differencing two meshes
that share most of their surfaces leaves coplanar, **zero-volume shells** strewn
over the coincident faces; they are not material, but they do move a bounding
box. An early version of this check failed on exactly that while the geometry
underneath was already correct.

The check that matters most is `[4]`, and it is not a dimension — measuring
"8.00 across flats" proves nothing, because a **round** 8.00 hole is 8.00 across
flats too and the nut spins in it. `[4]` sweeps the pocket's own boundary and
asks how far a centred M5 nut turns before its corners bind: **0.012°** as
built, against 0.012° predicted from the measured 8.0010 across flats. Its
control is the head counterbore — a genuine round bore on the same part, which
must read *free*. It is swept with a 7.00 hex rather than the nut, and that is
the point `arm_simple.scad` makes rather than a fudge: an M5 nut is 9.2376
across corners and will not enter an 8.80 bore at any angle, so asking the sweep
about a nut there gets the correct answer "does not fit", which tests nothing. A
7.00 hex clears 8.80 and reads **60.0° = free** there against 21.84° in the hex
pocket, which is the discrimination the control exists to demonstrate.

Nine mutants, each aimed at one claim, all caught:

| mutant | caught by |
|---|---|
| nut pocket made round (`$fn` 6 → 96) | not a hexagon; 9.2327 across flats; turns 60° |
| nut hex 10 % oversize | 8.800 across flats; turns 12.29°; 8.84 mm³ outside the fences |
| nut pocket 0.4 too shallow | floor 8.916 ≠ 9.316; nut would stand 0.100 proud |
| boss grown to r 7.45 | added 476.4 ≠ 459.97 mm³; 9.70 mm³ outside the fence; bbox grows in Y |
| countersink removed | relief rises 0.000/mm, not 45°; mouth 5.461 misses da 5.70 by −0.239 |
| an extra notch cut in the middle prong | 6.000 mm³ of removed material outside both fences |
| head pocket driven 1 mm off the pivot | 2.0000 out of round; 6.800 across; and `[4]`'s control trips |
| nut pocket put on the head prong | floor reads the donor's own 8.903, depth 3.886 — our cut is missing |
| boss 0.5 too thin | `assert` at render time — the floor wall falls under `nut_wall` |

**The first attempt at the notch mutant was a dud, and that is worth recording.**
It cut a 3 × 3 mm cube centred on the pivot axis — which sits entirely inside
the donor's own Ø5.461 bore, removes nothing, and leaves the part unbroken. The
harness passed it because it was *correct* to pass it. A mutation that does not
actually change the part tests nothing; check that it bit before believing a
green result.

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

On the **simple arm that last number is 4.85 mm**, not 2.65 — with the pivot
centred the bore sits dead centre in the prong and carries the full 4.85 on
*both* sides, which is what the originals had. The reverse-load direction stops
being a weak direction at all on that variant.
