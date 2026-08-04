# Airboat enclosure — build notes

`main.scad` reorients the chest-stimulator enclosure into the catamaran **airboat hull
box**. One body serves both hulls via `side = "port" | "starboard"`.

## What was decided (with Patrick)

| Question | Answer |
|---|---|
| Base vs brief | **Reorient** to the flat low-profile float box; reuse the stim enclosure's knuckle hinge, snap-lock skirt, lanyard ears, wall/echo idioms. |
| Prop size | **Parametric** `prop_diameter` (default 203 = 8×4.5); the pylon height derives from it automatically. 1045 (254) is a one-line change. |
| Stern cable port | **One 8 mm** gland (`port_stern_d`). |
| Float mount | **Printed cradle bonded to the foam + a 4 mm over-top bungee** (replaces the lanyard ears). The box *drops into* a foam-bonded collar (walls take slide + yaw); an elastic bungee runs athwartship over the top (takes lift/pitch). Holes one long side (tie anchor), hooks the other (quick-release). No hardware through the foam. See "Float-mount cradle" below. |

## Frame mapping (why the reuse works)

The stim enclosure's code frame is kept verbatim so the proven hinge/skirt/print modules
need no edits — only the physical meaning of each axis changes:

```
code X (inner_w=90,  W=95)   = box WIDTH  (athwartship)   -X = OUTBOARD (hinge, XT60) | +X = INBOARD (rod sockets, cable ports)
code Z (inner_h=165, H=170)  = box LENGTH (fore-aft)       +Z = BOW | -Z = STERN (motor pylon)
code Y (inner_d=35,  D=37.5) = box HEIGHT (floor→lid)      Y=0 = LID/TOP | Y=D = FLOOR (on the float)
```

Body prints **floor-down**; print-up = model −y. `side="starboard"` is `mirror([1,0,0])` of
the whole part — inboard/outboard reflect while bow/stern and floor/lid stay put, so the hinge
stays outboard and the sockets stay inboard on both printed parts. A mirror about X leaves every
overhang untouched, so both hulls print supportless equally well.

## Parts and export

```
openscad -o body.stl     -D 'part="body"'  -D 'side="port"'      -D '$fn=128' main.scad
openscad -o lid.stl      -D 'part="lid"'   -D 'side="port"'      -D '$fn=128' main.scad
openscad -o pylon.stl    -D 'part="pylon"'                       -D '$fn=128' main.scad
# starboard hull: same, with -D 'side="starboard"'
# assembly preview:  -D 'part="assembly"' -D 'preview_upright=true' -D 'lid_open=42'
```

- **body** — prints floor on the bed. **lid** — outer face down. **pylon** — laid flat, layers
  along its length (the bending load runs along the layers, not across them).
- The pylon is a **separate part bolted to the stern** — never to the lid, and no fastener
  enters the sealed cavity.

## Verification (all passing)

- Manifold `NoError` for body / lid / pylon on both `side` settings.
- Bed fit (250×210×210): body **130.8×184×39**, lid **106.5×170×7.5**, pylon **30×139.5×44** (laid flat).
- Body+lid nest across X = **242 mm** ≤ 245 budget (thin margin, as the brief warned), long axis along Y.
- **No fastener breaches the cavity** — rod sockets, grub screws, and motor bolts intersect the
  interior void at **0 mm³** (intersection probe). Cable ports are true **through-holes** (probed).
- **Lid opens/closes cleanly** — `render()`-collapsed lid ∩ body = **empty at 0–175°**; seats at 0°.
- **Prop disc clears** the box and the float (0 mm³), on both hulls; stern-prop gap across the beam = 37 mm.
- Rod-socket blind bores are **teardrop, apex print-up** (self-supporting).
- **Pylon prints supportless** — one `linear_extrude` gives a genuinely flat bed face; layers run
  along the mast. Foot-bolt edge wall 3.8 mm; foot↔block bolt holes are coaxial; tongue seats in slot.
- **XT60 on the bow wall** (the outboard wall is fully taken by the hinge; probed clear of it).
- Component packing (RC hull): **49 %** of the floor used, no overlaps, ~51 % free for wiring.
- **Overall stack (waterline → prop top): 265 mm.** Print time (0.2 mm, 20 % infill, supportless):
  body ~9h36m, lid ~4h09m, pylon **~3h15m** (the earlier ~2h was a ~62 % underestimate — measured
  3h14m56s in the DFM slice), cradle **~2h25m** (~24 cm³, ~30 g).

### Fixes from the adversarial review (3-lens: brief / correctness / DFM)

- Cable ports were **capped** by the gland boss (not through) → lengthened the cut through the boss tip.
- Motor-mount M4 blind holes were at **clearance** dia (no bite) → thread-forming pilot (`mm_bolt_pilot=3.4`).
- Rod grub screw was at M3 **clearance** → thread-forming pilot (`rod_grub_d=2.5`).
- XT60 flange **collided with the hinge** on the outboard wall → moved to the bow end wall.
- Pylon could **not print supportless** as posed → rebuilt as a single flat extrude.
- Stern motor block **floated 3.75 mm** above the bed (overhang) → extended down to the floor (also spreads load).
- Assembly preview **omitted the connecting rods** → added rod ghosts; fixed the ghost motor axis.
- Dead vars removed; bed-fit echo now tests **true** extents; stack-height echo added.

## Follow-up round — Patrick's review of v0.1 (items 2–6 done, item 1 pending)

Six follow-ups from Patrick's review — all implemented and probe-verified. Items 2–6 are in the
table below; item 1 became a full pylon redesign (its own section, further down).

| # | Ask | What changed |
|---|---|---|
| 2 | Pad mounts the **X BasePlate**, not the motor directly | `pylon_cut` now cuts 4× **M3** on the plate's **outer "+"** pattern (`bp_bolt=32` across each axis, holes at ±16) + a **⌀11.5 teardrop** central clearance for the motor boss. Pad grew to `pad_h=42` (backs the 39.5 plate, ≥3 mm wall at the M3s). Holes open **both sides** (flat-head from the plate, nut behind). Real `BasePlate.stl`/`Motor.stl` `import()` phantoms added (`show_hardware`). The old direct-2212 cuts and `motor_bolt_*`/`motor_slot`/`motor_screw_d`/`motor_bore` params were removed. |
| 3 | Route the local motor leads through a **lid gland**, drop the pylon groove | `lid_gland` hole (⌀12.5, at X=0 Z=−60) pierces the lid panel only, clear of hinge/skirt/locks (≥9.5 mm to the stern lock). The pylon cable-groove is **removed** — mast face is solid again. |
| 4 | Cable ports = **plain holes** (no gland boss) | `cable_port_boss` deleted; ports are clean ⌀12.5 through-holes (gland body + nut form the seal). `port_boss_t` gone. |
| 5 | **BOSL2 metric threads** | `include ../BOSL2/threading.scad`; `tapped_hole()` helper. **M4** tapped in the 4 stern-block pylon-attach holes (teardrop crest, `spin=180` → apex prints up); **M3** tapped in the rod-socket grub holes (vertical axis). `use_threads=false` falls back to thread-forming pilots. |
| 6 | **Third inboard port** for the stim wires, one hull only | `stim_port` (default off, **independent of `side`** — set it on whichever hull you print as the stim box) adds a ⌀12.5 port at Z=0, amidships (clear of both rod sockets and the two other ports). |

**Measured off the real `BasePlate.stl`** (exact cylinders): plate 39.49 sq × 2 mm; central bore ⌀10;
outer "+" (plate→pylon) at (±16,0)/(0,±16) ⌀3 (M3), countersunk; inner 2212 (motor→plate) at
(±9.5,0)/(0,±7.75) ⌀2 — *the plate's business, not the pylon's*.

**Verification (all passing, house style):** all parts `NoError` and **1 shell** on both `side`, with
`stim_port` and `use_threads` on/off; **no fastener breaches the cavity** (thread cuts ∩ cavity = 0 mm³,
even with the bigger thread major dia); ports open into the cavity (through-holes); lid still seats at
**0 interference**; M3 grub reaches the rod bore (107.8 mm³, locks the rod); bed nest still **242 ≤ 245**.
Print-orientation checks: M4 block-thread teardrop apex verified **up**; pad central bore teardrop apex
verified **up** (Z reach 8.13 vs round 5.75). A 5-lens adversarial review (brief/geometry/DFM/watertight/
regression) surfaced exactly one real issue — the pad central bore was a plain horizontal cylinder that
would droop — now teardropped.

### Toggles added this round

```
stim_port = true      # print the stim hull (adds the 3rd inboard port)
use_threads = false   # fall back to thread-forming pilots if BOSL2 threads print poorly
show_hardware = false # hide the BasePlate/Motor import phantoms in the assembly preview
```

### Item 1 — pylon redesigned as a full-height buttress (v0.2)

Patrick originally asked to flip the gusset to the bow. Probing killed that idea — a forward gusset
**collides with the stern block by ~3839 mm³** at the root and sits on the *compression* side. But the
discussion surfaced the **real** problem: the old gusset was thickest at the **mast root** with only a
thin foot below it, while a cantilever's bending moment is **maximum at the base**. So the reinforcement
was in the wrong place. The fix (Patrick's call) keeps the gusset aft and rebuilds the pylon:

- **Full-height triangular buttress** — forward face flat at X=0 (block-mating plane), aft face tapering
  from `base_aft` (=`pylon_root_t`+`pylon_gusset`=24) at the **foam base** down to `pylon_root_t` (8) at
  the tip. Deepest section where the moment peaks; the aft taper doubles as the streamlined trailing edge.
- **Filleted transitions** — `offset(r=pylon_fillet) offset(delta=-pylon_fillet)` rounds the concave
  junctions (pad↔mast, base); the register tongue is unioned after so it stays crisp.
- **Trimmed width** — `pylon_width` 44 → **42** (the floor set by the motor "+" pattern at ±16 + ≥3 mm
  walls). A true airfoil (narrow athwartship) was rejected: it can't be a single flat extrude without the
  layers running *across* the bending load. `mm_bolt_x` 32 → 28 so the foot-bolt counterbores clear the
  narrower edge (block tapped holes follow to ±14).
- **Counterbored foot bolts** — each M4 gets a ⌀`foot_cbore_d` (7.5) counterbore cut ~`foot_cbore_h` (5)
  mm in from the actual tapered surface, so the heads stay recessed/drivable through the thick base.

Trade noted: the 4-bolt envelope drops to ~38 mm (from 41), but the full-height buttress + register tongue
now carry the moment and the bolts mainly clamp. Still ONE `linear_extrude` → supportless, layers along
the mast. Verified: 1 shell both sides, cavity-breach 0, all echo walls ≥3 mm.

## Float-mount cradle (Task B — replaces the lanyard ears)

`part="cradle"` (new render target). A **separate printed collar bonded to the XPS foam float**;
the box **drops into** it and a **4 mm elastic bungee** clamps over the top. Division of labour for
a top-heavy, differential-thrust craft: the rigid cradle takes **slide + yaw**, the elastic bungee
takes only the **lift/pitch preload** (constant tension as the foam compresses; on/off in a second).
**No fastener touches the sealed box** — pure capture + bonding (PU / epoxy / low-temp hot-melt on
XPS; not solvent cement). The lanyard/zip-tie ears are **deleted**.

**Geometry** (keyed to the box floor 95 × 170, corner_r 5; box model frame, floor at Y=D=37.5):
- **Rounded-rect capture-wall ring**, uniform **6 mm** tall (`cradle_wall_h`) — capped by the low
  inboard cable ports (bottoms ~7.25 mm above the floor; the wall top clears them by 1.3 mm). The
  other faces clear their features with margin (bow XT60 flange by 4.8 mm; outboard hinge leaf by
  14.1 mm), so one uniform height satisfies every side.
- **Outward glue-foot flange** (8 mm wide × 3 mm) for bond area + a spread, stable base on the foam.
- **Stern central relief** (`cradle_stern_relief`=54, ≥ the 50-wide motor block) — the wall+flange
  are cut away amidships at the stern so the motor block passes aft through the gap; the stern
  corners stay to capture that end.
- **Drop-in pocket** = box outline + `cradle_clear`=0.4 all round (prints-slop + easy insertion).
- **Bungee anchors/hooks** (`n_bungee`=2 transverse runs at **Z=±18** — see the gland clearance below):
  - **Anchor tabs** (tie side) — a rounded post with a fore-aft **teardrop tie-hole** (⌀5.5 > 4 mm
    cord); the bungee's fixed end threads through and knots.
  - **Bails** (quick-release side) — an **inverted-U staple** (two legs + a bridged top bar). Because
    the bungee tension pulls **up-and-inboard**, the retainer must cap it from *above*; a bail is the
    only clean **supportless** over-the-top retainer (the bar is a short bridge between two
    bed-supported legs). Suits a hook-ended bungee (clip the bar) or a loop (thread under the bar).
- **Inboard gland clearance (an adversarial review caught this).** The installed cable **glands** —
  the hex/dome that protrudes *inboard* from each port at Z=±35 (⌀~`cradle_gland_od`=18) — share the
  inboard space with the cradle's inboard wall + anchor tabs. A bare-hole clearance check missed it; a
  probe against the modeled gland hardware found the anchor tabs at the old Z=±45 fouling the glands by
  ~200-600 mm³. Fixes: (a) the bungee lines moved to **Z=±18** (the clear amidships window between the
  ±35 glands — the elastic bungee does position-insensitive *anti-lift*, and the walls take yaw/slide,
  so a mass-bracketing amidships pair is fine; the echo's **gland/rod-boss-aware** `anchor-tab Z-gap`
  check now flags any fouling position, and reports the two clear windows: amidships |Z|<21 or the ends
  |Z|≥78); (b) the inboard wall is **scalloped** at each port so the gland *body* (not just the hole)
  clears; (c) the glands are now modeled (`ghost_glands`) in the preview + probes.
- **Sides:** `hooks_outboard`=true (default) puts the **bails OUTBOARD** (easy field reach; clears the
  lid hinge + swing) and the **holes INBOARD**; flip it to swap. Mirrors with `side` via `apply_side`,
  so holes/bails swap X-sign but stay physically inboard/outboard on both hulls (like the hinge).
- **Recess:** `cradle_recess`=0 = **top-bonded v1** (box floor sits on the foam through the open
  pocket). `cradle_recess`>0 is a documented v2 hook (sink the box into a foam pocket) that would
  also need inboard foam relief for the ports — not built.

**Prints bonding-face DOWN** (`oriented("cradle")` = same transform as the body: the foam-bond plane
on the bed, walls up) → one flat bed face, **supportless**.

### Verification (all passing, house style — same probes as the box)
- `part="cradle"` renders **NoError**, **1 shell** on both `side` settings; mesh bbox **121.8 × 192.8
  × 16 mm** (fits 250×210×210).
- **Box drops in, no interference (incl. installed glands):** `cradle ∩ (body ∪ lid ∪ ghost_glands)`
  seated = **0 mm³** (empty STL) on port + starboard **and** with `stim_port` on (3rd gland) — walls/
  bails/tabs clear the cable ports+glands, rod bosses, XT60, hinge, motor block, and lid. (Positive
  control: forcing `cradle_clear=-2` gives 5804 mm³, so the probe genuinely detects overlap.)
- **Lid still opens:** `cradle ∩ swung lid` = **0 mm³** at lid_open 0–175° (the outboard bails never
  foul the swing — the lid goes up-and-over, the bails stay low).
- **Prints supportless:** PrusaSlicer (MK3S PLA profile, supports off) emits **0 support material**;
  ~56 mm overhang perimeter (the bail bridges only — the pylon had 193 mm and passed). ~2h23m.
- **Watertight:** `cradle ∩ interior-cavity-void` = **0 mm³**; the cradle is entirely external and needs
  **no fastener** into the box (capture + bond only).
- Assembly preview shows the box **seated in the cradle on the `ghost_float`**, both hulls, with the
  gland ghosts.
- **Adversarial review (6-dimension Workflow + per-finding skeptics):** 5 of 6 dimensions passed on the
  first cut; the box-capture dimension caught the **gland collision** above (my seated probe saw only
  the *printed* box, not the installed hardware) — fixed as described, then re-verified at 0 mm³.

### To confirm before printing (cradle)
1. **Measure your cable gland's OD** — `cradle_gland_od` (default 18) drives the inboard clearance (the
   anchor-tab Z-gap + the port wall relief). If yours is bigger, the echo's `anchor-tab Z-gap` check
   will warn and you may need to nudge `bungee_z`.
2. **Bungee position** — default **Z=±18** (amidships pair, brackets the mass, clears the inboard
   glands + rod bosses). Want more anti-pitch? Widen toward the ends — `bungee_z≈78–80` is the other
   clear window (the echo confirms the gap; note it lands near the corner). The bungee is elastic, so
   anti-lift (its main job) is position-insensitive.
3. **Bungee ends** — the bails suit a **4 mm bungee with hook ends** (clip the bar) or a plain loop
   (thread under the bar). If yours is bare cord, the anchor holes + bails still work; confirm the
   end hardware so we can tune throat width (`hook_out`) if needed.
4. **Hook side** — default `hooks_outboard=true` (bails outboard, easy reach, clears the hinge). Flip
   to `false` if you'd rather reach the inboard side.
5. **Brim it, ≤8 mm** — the slicer flags *Low bed adhesion* (thin ring on a large footprint, like the
   lid); add a **~5 mm brim** (cap at ~8 mm — the 193 mm length leaves only ~8.8 mm/side on the 210 mm
   bed axis). Supportless either way.
6. **Real foam geometry** — `float_thickness` (60) is still an assumption; only matters if you
   parametrize `cradle_recess`. The cradle itself keys off the *box*, so it's independent of the float.
7. **Capture depth** — walls are a uniform 6 mm (the inboard ports cap it). If you want deeper capture
   on the outboard/bow/stern, those faces have room (per-side heights, a small change) — say the word.

## Prop clearance (parametric)

```
hub_above_water = prop_radius + float_freeboard + prop_clearance_margin
                = 101.5 + 42 + 20 = 163.5 mm   (8×4.5)
disc lowest point clears the float top by prop_clearance_margin (20 mm)
pylon rise above the box floor = 121.5 mm ; hub ~84 mm above the box top
```

Change `prop_diameter` to 254 (1045) and the pylon grows to ~110 mm above the box top — one line.

## Open items to confirm before printing

1. **Pylon buttress (item 1)** — the mast is a full-height buttress (`base_aft`=24 → 8), width trimmed
   to 42, foot bolts counterbored. Tune `pylon_gusset` (base thickness), `pylon_fillet`, and
   `foot_cbore_*` to taste. See "Item 1 — pylon redesigned as a full-height buttress" above.
2. **BasePlate holes** — the pad matches the plate's **outer "+"** (⌀3/M3 at ±16) measured off
   `BasePlate.stl`. Confirm your plate matches (`bp_bolt`, `bp_size`, `bp_bore`).
3. **Gland sizes** — every gland hole defaults to **⌀12.5 (PG7)**: `port_stern_d`, `port_bow_d`,
   `port_stim_d`, `lid_gland_d`. Set them to your actual glands (PG9 = 15.2, M12 = 12).
4. **Threads print quality** — `use_threads=true` models real BOSL2 M4/M3. If they print poorly on
   the MK3S, set `use_threads=false` for thread-forming pilots (`mm_bolt_pilot` / `rod_grub_d`).
5. **`beam_target`** (default 240 mm) sets the rod length (144 mm) and must exceed `prop_diameter`
   or the two stern props collide — echo-checked. Confirm the catamaran beam you want.
6. **Float dimensions** — `float_thickness` (60) and `float_freeboard` (42) at ~2 kg all-up are
   assumptions; they set the prop clearance. Confirm against the real float at load.
7. **Which hull is the stim hull** — set `stim_port=true` on that print (independent of `side`).
