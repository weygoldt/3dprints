# Airboat enclosure — build notes

`main.scad` reorients the chest-stimulator enclosure into the catamaran **airboat hull
box**. One body serves both hulls via `side = "port" | "starboard"`.

## What was decided (with Patrick)

| Question | Answer |
|---|---|
| Base vs brief | **Reorient** to the flat low-profile float box; reuse the stim enclosure's knuckle hinge, snap-lock skirt, wall/echo idioms. |
| Prop size | **Parametric** `prop_diameter` (default 203 = 8×4.5); the pylon height derives from it automatically. 1045 (254) is a one-line change. |
| Stern cable port | **One 8 mm** gland (`port_stern_d`). |
| Float mount | **Through-board screws (current).** The box is screwed DOWN onto the XPS float — screws up through the foam into blind, sealed floor bosses. Superseded the lanyard ears and (earlier) a bonded cradle+bungee. See "Float mount — through-board screw mount" below. |

## Float mount — through-board screw mount (current)

Patrick's decision: **rigidly screw the box down to its XPS foam float** and drop everything else
(the lanyard/zip-tie ears *and* the bonded cradle+bungee that briefly replaced them, and the two
inboard PVC rod sockets). Screws pass **UP through the foam from below** and thread into **blind,
sealed bosses on the floor underside**. Nothing else changes — cable ports/lid gland/XT60 stay sealed.

**Geometry (`[Through-board screw mount]` params + `screw_boss`/`screw_boss_cut`):**
- **4 bosses** at `screw_positions = [±27, ±79]` — a 54 × 158 mm rectangle inset from the corners,
  tucked in the free gaps between the RC components and **merging into the bow/stern end walls** for
  stiffness. Min plan gap to any component = **3.0 mm** (echo-checked against `rc_parts`).
- Each boss is a **solid `boss_od=12` cylinder** rising `boss_rise=12` off the floor **into** the
  chamber (top at Y=23 of the 35 mm chamber). The screw bore is drilled from the **bottom (bed) face
  UPWARD** and stops a **sealed cap** short of the boss top — **so it never reaches the chamber void.**
- **Watertight math:** cap = `boss_h − screw_hole_depth` = 14.5 − `screw_hole_depth` = **4.5 mm**
  (thread, `screw_hole_depth`=10) / 5.5 mm (insert, 9) of solid PLA above every bore (need ≥
  `boss_cap_min`=3). Even a fully over-driven real screw stops on that cap — no leak path.
- **`screw_method` toggle** (mirrors `use_threads`): **`thread`** (**default**, Patrick's call — BOSL2
  models a real internal M4 thread so the screw threads **straight into the PLA, no inserts**; vertical
  → self-supporting; cap 4.5 mm; `thread_len`=10) · **`insert`** (M4 heat-set brass, ⌀5.6 bore, boss OD
  12 → 3.2 mm wall so a hot insert won't split it) · **`selftap`** (⌀3.4 pilot, the screw forms its own,
  *stronger*, thread in solid PLA — the robust fallback if the coarse printed M4×0.7 thread wears from
  repeated field mount/unmount; `thread`+`use_threads=false` behaves the same).
- **Prints the easy way:** floor-DOWN, the bosses stand vertically on the bed (fully supported) and the
  blind bores open at the bed face and run straight up → **self-supporting, no teardrop** (unlike the
  old horizontal rod sockets). Removing the ears + rod sockets *dropped* the body's overhang-risk from
  ~1300 → ~540 mm² and print time to ~8h47m.

**Patrick's hardware (outside the box model):** the foam is soft — use **wide fender washers or a
backing plate under the foam** so the head can't pull through. Max screw length = foam + bore
(`screw_len_est` = `float_thickness + screw_hole_depth` = 60 + 10 = **≤70 mm** for 60 mm foam and the
thread method — the bore already includes the 2.5 mm floor, don't add it twice; **shorter is safer**,
the cap is blind). A smear of sealant on the screw at assembly is optional (the geometry alone is watertight).

**Cross-brace note (float-level, confirm):** the removed PVC rods were also the **hull-to-hull link**.
With each box screwed to its own float, the **box no longer cross-braces the two hulls** — that must be
handled at the float/frame level. The box makes no claim to solve it.

**Verification (all passing, house style — `probe.scad` intersection-volume probes with positive
controls):**
- body (port + starboard) / lid / pylon: `NoError`, **1 shell**; port ≡ starboard volume (mirror exact).
- **WATERTIGHT — every screw bore ∩ the sealed chamber = 0 mm³** for insert/thread/selftap, both sides.
  The probe's positive controls fire (over-deep bore → 148 mm³; boss under the LiPo → 1356 mm³), so the
  0 is real detection, not a dead probe.
- Boss ∩ each RC component = 0; boss ∩ stern motor block = 0; closed lid ∩ body = 0 (the nested-
  difference `body()` restructure still seats the lid).
- **Supportless** floor-down slice (MK3S PLA): **0 support material** (insert *and* thread methods).

## Frame mapping (why the reuse works)

The stim enclosure's code frame is kept verbatim so the proven hinge/skirt/print modules
need no edits — only the physical meaning of each axis changes:

```
code X (inner_w=90,  W=95)   = box WIDTH  (athwartship)   -X = OUTBOARD (hinge, XT60) | +X = INBOARD (cable ports)
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
- Bed fit (250×210×210): body **105×184×40.5** (narrower — ears + rod bosses gone, bosses are internal), lid **106.5×170×7.5**, pylon laid flat.
- Body+lid nest across X = **217 mm** ≤ 245 budget (comfortable now the ears + rod bosses are gone), long axis along Y.
- **No fastener breaches the cavity** — the through-board screw bores and the motor bolts intersect the
  interior void at **0 mm³** (intersection probe, positive-control verified). Cable ports are true
  **through-holes** (probed).
- **Lid opens/closes cleanly** — `render()`-collapsed lid ∩ body = **empty at 0–175°**; seats at 0°.
- **Prop disc clears** the box and the float (0 mm³), on both hulls; stern-prop gap across the beam = 37 mm.
- Through-board screw bores are **vertical** (open at the bed face, run straight up) → self-supporting, no teardrop.
- **Pylon prints supportless** — one `linear_extrude` gives a genuinely flat bed face; layers run
  along the mast. Foot-bolt edge wall 3.8 mm; foot↔block bolt holes are coaxial; tongue seats in slot.
- **XT60 on the bow wall** (the outboard wall is fully taken by the hinge; probed clear of it).
- Component packing (RC hull): **49 %** of the floor used, no overlaps, ~51 % free for wiring.
- **Overall stack (waterline → prop top): 265 mm.** Print time (0.2 mm, 20 % infill, supportless):
  body ~9h44m, lid ~4h10m, pylon ~2h.

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
3. **Gland sizes** — every gland hole is now **⌀12 (MEASURED by Patrick, 2026-08-04)**: `port_stern_d`,
   `port_bow_d`, `port_stim_d`, `lid_gland_d`. The installed footprint `port_ftp=19` drives the inboard
   spacing check (not the 12 hole). Confirm both against your glands.
4. **Threads print quality** — `use_threads=true` models real BOSL2 M4/M3. If they print poorly on
   the MK3S, set `use_threads=false` for thread-forming pilots (`mm_bolt_pilot` / `rod_grub_d`).
5. **`beam_target`** (default 240 mm) must exceed `prop_diameter` or the two stern props collide —
   echo-checked (the rods that used to span it are gone). Confirm the catamaran beam you want, **and
   how the two floats are cross-braced now the rods are removed** (float-level, outside the box).
6. **Float dimensions** — `float_thickness` (60) and `float_freeboard` (42) at ~2 kg all-up are
   assumptions; they set the prop clearance. Confirm against the real float at load.
7. **Which hull is the stim hull** — set `stim_port=true` on that print (independent of `side`).
8. **Screw mount** — 4× M4 at `screw_positions=[±27,±79]`, default `screw_method="thread"` (screw
   straight into printed M4 threads — no inserts). Confirm the count/positions clear your real component
   layout; if the coarse printed M4×0.7 threads wear from repeated mount/unmount, switch to `selftap`
   (screw self-taps a stronger thread) or `insert` (heat-set brass). Foam thickness (`float_thickness=60`)
   sets the **max** screw length (`screw_len_est` ≤70 mm; shorter is safer). Wide fender washer / backing
   plate under the soft foam so the head can't pull through.
