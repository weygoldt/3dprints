# Handoff: airboat enclosure (OpenSCAD)

## What we're building

Two 3D-printed electronics enclosures that sit on two styrofoam floats, joined into a catamaran
airboat. The boat carries an electric-eel EOD emulator around a field site while playing back
stimuli, with the playback electrode towed behind on a tether.

- **RC hull** — receiver, 2x ESC, 3S LiPo, optocoupler isolation board
- **Stim hull** — Teensy stimulator, its own cell, electrode lead

Each hull carries **one air-prop motor**. Both ESCs live in the RC box, so the far motor's three
phase wires cross between the hulls.

## Starting point

You are working on a **copy** of the existing eeltracker enclosure project in a new directory.
**Read the existing source first** and inventory what's there before changing anything — this brief
describes intent, not the current parameter names.

**Preserve unchanged:**
- The closing lid and its sealing/latching arrangement
- The existing fixture points on the bottom face (these bolt the enclosure to the float — already solved)
- Existing port holes, unless they conflict with new geometry

**Do not** restructure the project, rename existing parameters, or "clean up" code that isn't in scope.

---

## Hard constraints

### Print volume — Prusa MK3S

**250 x 210 x 210 mm.** Every part must fit, in the orientation it should actually be printed in.

**Bed layout requirement: the enclosure body and its lid must nest together on one bed.** The pylons
print on a separate bed — do not try to fit them alongside.

Only one orientation works. Both parts go with their **long axis along Y** (the 210 mm axis), placed
side by side across X:

    box_outer_width + boss_protrusion + lid_width + gap  <=  245 mm

With ~102 mm outer width and ~20 mm of rod-boss protrusion that comes to roughly 236 mm — it fits,
but the margin is thin. Rotating 90 degrees does **not** work: the two widths sum past 210 mm.

If the numbers stop fitting, **report it and ask** rather than silently shrinking the box. The
options are printing the lid on its own bed, or reducing box length — Patrick's call.

### Interchangeability

Both hulls use the **same body**. A single parameter `side = "port" | "starboard"` mirrors the
side-dependent features (PVC rod sockets, cable ports) about the boat centreline. The body is
otherwise symmetric.

Keep the **lid hinge on the outboard face** in boat coordinates, i.e. it does *not* flip with `side`.
Both lids then open away from the centreline, so you never have to reach between the hulls or around
the connecting rods to open a box.

### Low profile, single layer

**Nothing stacks.** All components lie flat, side by side, on the enclosure floor. Internal height is
set by the tallest single item, not by a stack.

- Tallest item is the 3S LiPo at **26.5 mm** (75 x 34 mm footprint)
- Target **~35 mm internal height** — enough for the LiPo plus wire routing above it
- Every millimetre of box height raises the thrust line and the centre of gravity on an already
  top-heavy airboat

### Enclosure size

- Internal floor: **90 mm wide x 150-180 mm long**
- Internal height: **~35 mm**

Packing check for the RC hull on a 90 x 165 mm floor, all flat:

| Item | Footprint |
|---|---|
| 3S LiPo | 75 x 34 mm |
| 2x ESC | ~45 x 25 mm each |
| FS-iA6B receiver | ~47 x 27 mm |
| Optocoupler perfboard | ~40 x 30 mm |

Total ~7,500 mm² of 14,850 mm² available. Roughly half the floor stays free for wiring and the
XT60 Y-lead. The stim hull is emptier, so the RC hull is the binding case.

---

## Task 1 — Motor mount (highest priority)

### Motor

A2212-class 2212 brushless outrunner:
- Body diameter 28 mm, height ~19-28 mm
- Shaft 3.17 mm
- Mounting: the standard 2212 cross pattern — **four M3 holes, one pair 16 mm apart, the other pair
  19 mm apart**, i.e. holes at (±8, 0) and (0, ±9.5)
- M3.2 clearance holes; parameterise both spacings separately
- Central bore >= 10 mm to clear the shaft boss and circlip

> **Verify the hole pattern against the actual motor with calipers before printing.** Cheap A2212s
> vary. Consider making the four holes short radial slots (±1 mm) so a slightly different pattern
> still bolts up.

### Prop clearance geometry

Working figures (parameterise all of them):

| Parameter | Value |
|---|---|
| `prop_diameter` | 254 mm (1045) |
| `float_thickness` | 60 mm |
| `float_freeboard` | ~42 mm at ~2 kg all-up |
| `box_outer_height` | ~45 mm |
| `prop_clearance_margin` | 20 mm |

**Place the prop disc aft of the enclosure's rear wall, sweeping over the float.** Then only the
float sets the vertical requirement:

    hub_height_above_water >= prop_radius + float_freeboard + margin
                           =  127 + 42 + 20  =  189 mm

which puts the hub roughly **100-110 mm above the box top**. If the disc were allowed to overlap the
box footprint, the requirement jumps to ~234 mm — avoid that.

> **Flag for Patrick:** dropping to **8x4.5 props (203 mm)** cuts the required hub height to ~163 mm,
> which is ~76 mm above the box top — a third shorter and much stiffer, still ~450 g of static thrust
> per motor against maybe 0.1 N of tether drag. Keep `prop_diameter` parametric so this is one line.

### Pylon — print it as a separate part

**The pylon must be a separate printed part bolted to the enclosure body.** Two reasons:

1. **Layer orientation.** The pylon's dominant load is bending. Printed standing on the bed, the
   tensile stress runs across layer lines — the weakest possible orientation. Printed **lying flat**,
   layers run along its length and carry the load properly. At ~130-150 mm it fits the 250 mm bed
   axis easily when flat.
2. It keeps the enclosure print short, and lets Patrick reprint a different pylon if the prop size
   changes without reprinting the box.

Structure:
- **Bolt to the enclosure body, never to the lid.** The lid must stay removable without disturbing
  motor alignment, and thrust must not load the lid seal.
- Load case: ~6 N thrust at the hub, plus continuous vibration. At a ~150 mm lever, ~0.9 Nm bending
  at the root.
- Joint: a tongue or socket that seats into an external boss on the rear wall so the bolts are not
  in pure shear, plus **4x M4 spread over >= 40 mm**.
- **Route no fasteners through the sealed cavity.** Mount to external bosses only.
- Gusseted/triangulated, minimum 4 mm wall at the root, 5 mm minimum motor pad.
- Provide a routing channel or clip path down the pylon for the three motor leads, and keep them
  short — they are the main EMI radiator in this build.

---

## Task 2 — PVC rod sockets

The hulls are joined by a **12 mm PVC rod at the bow and a second at the stern**. Each enclosure
carries two sockets on its inboard side wall — the side selected by `side`.

- Bore **12.4 mm** for a nominal 12 mm rod (parametric `rod_clearance`, start 0.4 mm)
- Socket depth >= 25 mm
- **Blind sockets — they must not break through into the enclosure interior.** Watertightness is the
  point. Leave >= 3 mm of solid wall at the bottom of each bore.
- Cross-drilled M3 hole for a grub screw to lock the rod, or a split clamp with a single M3
- Both sockets share one `rod_axis_height`. Bow and stern sockets must be **coaxial**, and identical
  on both hulls, or the catamaran sits skewed.
- Socket depth plus rod length sets the beam. Expose `beam_target` and derive.
- Check the boss protrusion against the bed-layout budget above.

**Printability:** these bores are horizontal, so their top surface is an unsupported overhang and a
12.4 mm round bore will sag there. Give the bore a **teardrop or chamfered-apex profile** so it
self-supports, or the rod will bind on a drooped ceiling. Do not rely on support material inside a
blind bore.

Reinforce around the sockets — all hull-to-hull load passes through them, including twisting from
differential thrust.

---

## Task 3 — Cable ports

On the inboard face, selected by `side`, matching between the two hulls.

| Position | Carries | Notes |
|---|---|---|
| Stern | 3x motor phase wires, RC box -> far motor | See sizing note |
| Bow | Optocoupler -> Teensy signal cable | 2 signal + 1 ground, thin |

- Target 6 mm holes for cable barbs/glands, parametric `port_diameter`
- These are through-holes and the main leak path. Model for a proper gland or barb with a shoulder,
  not a bare hole.

> **Sizing flag:** three 18 AWG silicone leads bundle to roughly 5.5-6 mm, very tight in a 6 mm port.
> Recommend either an **8 mm stern port** or three separate 3.5 mm ports. Ask Patrick.

---

## Deliverables

1. Modified OpenSCAD source with a documented parameter block at the top
2. Both hulls renderable from one file via `side`
3. Pylon as a separate module with its own export target
4. An assembly preview showing both hulls, rods, motors, and prop discs **at true diameter** — so
   clearance is checked visually rather than trusted
5. STL export targets: enclosure body, lid, pylon

## Verification before handing back

- Render and export all STLs; confirm `openscad` reports no manifold errors
- **Confirm every part fits 250 x 210 x 210 mm in its intended print orientation** — report the
  bounding box of each
- **Confirm the body and lid nest together on one bed**, long axis along Y, and report the combined
  X footprint against the 245 mm budget
- Confirm the prop disc at full diameter intersects nothing in the assembly view
- Confirm no rod socket, port, or pylon fastener breaks into the sealed cavity
- Confirm the lid still opens and closes with the pylon in place, on both `side` settings
- Report the resulting beam, hub height above water, overall stack height, and estimated print time

## Open questions — ask, don't guess

1. 1045 props as bought, or drop to 8x4.5 for a shorter, stiffer pylon?
2. Stern port: one 8 mm hole or three small ones?
3. Actual measured A2212 bolt pattern and body height
4. Final float length and thickness — the freeboard figure above assumes 60 mm thick at ~2 kg all-up
5. Confirmed internal height of the existing enclosure, and whether 35 mm is a reduction or an increase
