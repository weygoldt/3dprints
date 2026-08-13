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
- **`screw_method` toggle** (mirrors `use_threads`): **`insert`** (**default**, Patrick's call — M4
  heat-set brass, ⌀5.6 vertical bore installed from the bed face; boss OD 12 = 2× a 6.0 mm insert OD so a
  hot insert won't split it; cap 5.5 mm; strongest/reusable) · **`thread`** (BOSL2 models a real internal
  M4 thread so the screw threads straight into the PLA, no inserts; vertical → self-supporting; cap 4.5 mm;
  `thread_len`=10) · **`selftap`** (⌀3.4 pilot, the screw forms its own,
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

The model is **split into one file per part** — open a file to render that part
(the old `-D 'part='` selector is gone). All shared parameters, the DERIVED values,
the ECHO fit-check, and the shared helper/mechanism modules live in `common.scad`,
which every other file `include`s.

```
openscad -o body.stl   -D 'side="port"' -D '$fn=128' body.scad
openscad -o lid.stl    -D 'side="port"' -D '$fn=128' lid.scad
openscad -o pylon.stl                   -D '$fn=128' pylon.scad
# starboard hull: same, with -D 'side="starboard"'
# assembly preview (both hulls, ghosts, hardware phantoms):
openscad main.scad     # or add -D 'preview_upright=true' -D 'lid_open=42'
```

**File layout**

- `common.scad` — all parameters, DERIVED values, the ECHO fit-check, the shared
  helpers (`rprism`, `tapped_hole`), the shared hinge / snap-lock primitives, the
  orientation helpers, and the two BOSL2 `include`s. Included by every other file.
- `body.scad` — `body()` + its body-only submodules → **prints floor on the bed**.
- `lid.scad` — `lid()` + its lid-only submodules → **outer face down**.
- `pylon.scad` — `pylon()`/`pylon_cut()` → **laid flat**, layers along its length
  (the bending load runs along the layers, not across them).
- `main.scad` — the **assembly preview**: `include <common.scad>` + `use` of the
  three part files, plus the motor / float / prop / screw phantoms and the scene.

- The pylon is a **separate part bolted to the stern** — never to the lid, and no
  fastener enters the sealed cavity.

> This split is a pure, behaviour-preserving refactor: the exported STLs are
> byte-for-byte identical to the pre-split monolith at the same `$fn`.

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
| 3 | Route the local motor leads through a **lid gland**, drop the pylon groove | `lid_gland` hole (⌀12.5, at X=0 Z=−60) pierces the lid panel only, clear of hinge/skirt/locks (≥9.5 mm to the stern lock). The pylon cable-groove is **removed** — mast face is solid again. *(Superseded 2026-08-06: motors now exit via the inboard side glands, so this lid hole became the on/off switch — `lid_switch*`. See the pre-print refinement round.)* |
| 4 | Cable ports = **plain holes** (no gland boss) | `cable_port_boss` deleted; ports are clean ⌀12.5 through-holes (gland body + nut form the seal). `port_boss_t` gone. |
| 5 | **BOSL2 metric threads** | `include ../BOSL2/threading.scad`; `tapped_hole()` helper. **M4** tapped in the 4 stern-block pylon-attach holes (teardrop crest, `spin=180` → apex prints up); **M3** tapped in the rod-socket grub holes (vertical axis). `use_threads=false` falls back to thread-forming pilots. |
| 6 | **Third inboard port** for the stim wires, one hull only | `stim_port` (default off, **independent of `side`** — set it on whichever hull you print as the stim box) adds a ⌀12.5 port at Z=0, amidships (clear of both rod sockets and the two other ports). *(Superseded 2026-08-06 by `box_role`, which selects the whole gland set per box — see the pre-print refinement round.)* |

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
stim_port = true      # (superseded 2026-08-06 by box_role="stim") print the stim hull
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

## Pre-print refinement round (2026-08-06) — fixes before the first print

Patrick's final pass on the printed pylon + lid before the first production print. All three are
echo-verified and rendered.

| # | Ask | What changed |
|---|---|---|
| 1 | **Forward pylon slope should start at the top**, like the aft face — not ¾ of the way up | The forward gusset was a *short* bracket topping out mid-mast in a **point** (a stress concentrator right where the slope started). It is now a **full-height taper**: `fg_y1 = pad_y0 − fwd_gusset_top_gap` carries the forward slope from the bearing foot on the block top all the way up to **just below the motor pad**, mirroring the aft buttress taper. Spreads the bending-section change over the whole mast instead of stepping it mid-span. `fwd_gusset_rise` (mid-mast apex height) is replaced by `fwd_gusset_top_gap` (clearance below the pad). Still one flat `linear_extrude` → supportless; still bears aft of the lid. |
| 2 | **Lid underside ribs**: too deep, uneven (bars overshoot), and crowd the switch hole | Rib grid rebuilt as an **even waffle**: `rib_h` 5 → **3** (shallower — the ribs stiffen the panel, they don't fill the cavity); every internal rib now runs **ring-to-ring** (terminates on the perimeter ring → no overshooting/ragged free ends); `rib_xs`/`rib_zs` re-spaced (`[−20,0,20]`/`[−42,0,42]`) into even bays. **The switch keep-out is a full rectangle, not a disc** (2nd pass — a disc left the chunky flip switch's corners over ribs): `lid_ribs_mod` KILLS every rib within `switch_ftp` (**30×15**, the switch's inner-body footprint) + `switch_clear` (3 mm each side). |
| 3 | **Role-based cable glands**, tied to the hull; assembly shows both boxes | The gland SET now **follows the hull** (Patrick's 2nd pass): **`rc_side = "port" \| "starboard"`** names which hull carries the RC/boat electronics (the other is the stimulator). `role_of_side(side)` derives `box_role`, so a `side` render gets that hull's correct bores automatically, and **`main.scad` draws each hull with its own set** — the preview is the real boat: one RC box (3 glands) + one stim box (2). **rc** (boat electronics): 2 motor glands **aft** by the pylon at Z=−72/−48 (same-side + opposite-side motor, one 3-wire bundle each) + 1 control gland **forward** at Z=55 (kept away from the motor phase wires). **stim**: 2 glands both **forward** — signal-IN (Z=55, from the RC receiver) + electrode-OUT (Z=30). All ⌀12 on the inboard +X wall at Y=24. `body(role)` takes the role so the assembly can pass each hull's; `-D box_role=…` still forces it. The old `port_stern/bow/stim` params + `stim_port` are gone. The freed-up **lid hole is now the on/off switch** (`lid_switch*`, was `lid_gland*`; **bore 12.2** for the flip switch — the local motor no longer routes through the lid). |

| 4 | **Rotate the motor-mount bores 45° (＋ → ✕)** to shrink the pad and pull the slopes further up | The 4 M3 plate bolts stay on the same bolt circle (r `bp_bolt/2`=16) but rotate 45° to an **X** — mount the BasePlate turned 45°. New derived `bp_axis = (bp_bolt/2)/√2` ≈ **11.3**: the bolts' reach along the pad **axes** drops from 16 to 11.3, so `pad_h = 2·bp_axis + 2·bp_edge` shrinks **42 → 32.6 mm**. That raises `pad_y0` (116 → 121) and the forward slope apex (114 → 119, climb 75 → **80 mm**). The (rigid) 39.5 plate now **overhangs** the smaller pad — bolted at 4 points, overhang in free air at the tip. `pylon.scad` bores the X pattern; the `main.scad` plate/motor phantoms clock 45° **about X** (the pad-plane normal — a Z clock would tilt them out of plane) to match; pad-fit echoes rewritten (pad-holds-bolts + plate-overhangs, X-bolt edge wall 3.3 mm ≥ 3). |
| 5 | **Body foot bottom edge mismatched the square block foot** (chamfer left a gap where the body meets the stern block) | New `foot_chamfer` toggle, **default OFF**: `foot_chamfer_cut` (the 45° body-foot bottom bevel) is disabled, so the body's bottom edge is square like the block's foot — no gap at the transition, and the whole bottom seats flush on the bed (easier first layer). `edge_ch` still chamfers the lid top edge + block aft corners; flip `foot_chamfer=true` to restore the finished foot edge. |
| 6 | **Splash-seal lip won't print well** — remove it | `seal_gasket` → **OFF**. The inboard sealing lip was a full-perimeter *cantilevered overhang* at the top of the print → the slicer wants support **inside** the 40 mm-deep box (awkward to remove, and it mars the sealing face). It only ever bought SPLASH resistance (a capsize floods the box through the glands/lid regardless), and the lid's **overlap skirt + snap locks still shed the bulk of prop spray**. Fallback if testing shows intrusion: stick adhesive foam weatherstrip on the flat rim — no printed lip needed. `seal_lip`/`seal_groove` code kept behind the toggle (`seal_gasket=true` restores). |

**Verification:** all parts `NoError`; port body (RC, 3 glands) and starboard (stim, 2) export as *different*
geometry (extra hole); both roles pass the gland-spacing (≥3 mm footprint gap) and flat-wall echo checks;
the switch keep-out clears the skirt (20.9 mm) and stern lock (12.8 mm); forward-slope apex tops out just
below the pad; the X bores keep a 3.3 mm pad edge wall and 7 mm flat above the top screws.

## Post-print refinement — snap closure (2026-08-06) — after the first printed lid popped open

The first printed lid closes but the snap is weak (pops open on a knock) and the **inboard-edge dents looked
unprofessional**: three of them overlapped into one ragged blob in the middle of the housing.

| # | Ask | What changed |
|---|---|---|
| 1 | **Snappier** — deeper groove, stronger lid protrusion | `bump_h` **0.25 → 0.38** (≈1.5× deeper engagement). 0.25 mm was so shallow a <0.25 mm accidental lift unseated it; 0.38 mm is the deepest that still keeps **≥0.8 mm PLA behind the dent to the sealed chamber** — `wall 2.5 − step 1.2 − dent 0.48 = 0.82 mm`, a hair above the watertight bar (0.4 would sit exactly on it, no margin). `bump_w` **1.0 → 1.2** widens the wedge base so the deeper bump's lead-in ramp stays ~32° (firm but still hand-closeable) instead of getting too steep to seat. Depth is capped by watertightness, not by feel — if it still pops, add locks or steepen the *exit* ramp rather than cut deeper. |
| 2 | **3 overlapping grooves in the middle look unprofessional** | `lock_zs` **`[55,15,0,−15,−55]` → `[55,27.5,0,−27.5,−55]`** (even 27.5 mm pitch). The old middle three sat on **15 mm centres** while each dent is **16.8 mm** long (16 mm × the 5% dent margin) → they physically overlapped into one merged, wavy recess. Even pitch > dent length gives **5 discrete dents with a ~10.7 mm clean gap each** → tidy rim *and* a crisper snap (each bump now seats in its own dent instead of two bumps sharing one merged pocket). Still 7 locks total (5 inboard + bow + stern end). |
| 3 | **Sub-2 mm wall at the snaps feels flimsy** — make it bigger | The snap joint intrinsically splits the wall into two overlapping leaves (body **band** + lid **skirt**), so the band was only ~1.3 mm and ~0.82 mm behind each dent (sat exactly on the watertight bar). Beefed **both leaves**: `wall` **2.5 → 3.0** and `skirt_t` **1.1 → 1.4**. `W/H/D` are derived (`inner + 2·wall`), so this grows the **outer** box ~1 mm and leaves the electronics cavity untouched. Result: band **1.3 → 1.5 mm**, behind-dent **0.82 → 1.02 mm** (real margin now), lid skirt **1.1 → 1.4 mm**, closed joint composite **~2.4 → ~2.9 mm**. `step = skirt_t + clearance` moves with the skirt so the bump↔dent clearance stays 0.1 mm — **the snap geometry is unchanged**. Cost: ~+30–40 g PLA / +1–2 h print per hull; +1 mm outer footprint (trivial for the foam float). The extra behind-dent margin also leaves headroom to deepen the snap to ~0.5 later if it still pops. |

Two new echo guards (in `common.scad`, under `--- lid overlap + snap locks ---`): **`wall behind the snap dents`**
(warns if the dent thins the sealed inboard wall below the 0.8 mm bar — this is what caps `bump_h`) and **`inboard
dents: min pitch / clean gap`** (warns if any adjacent pair overlaps/crowds → the "looks unclean" trap). Replaces
the old coarse `step >= wall − 1.0` check, which ignored the dent depth entirely.

**Verification:** body/lid/main all `NoError` (with wall 3.0 + skirt 1.4 baked in); `skirt 1.4 × 3 deep over a
1.5 band`; `wall behind the dents = 1.02 mm OK (≥0.8)`; `inboard dents: min pitch 27.5 mm, clean gap 10.7 mm OK
(discrete, tidy)`; hinge swing gap 0.117 mm OK; bed 106 × 200 (fits). The dents are shallow surface features
(0.38–0.48 mm on a 185 mm edge), so a section render can't show the pattern convincingly — the echoes are the proof.

**Worktree gotcha (this session):** the main checkout `/home/weygoldt/wrk/3dprints/boat_enclosure/` and the
`airboat-enclosure` worktree BOTH have `boat_enclosure/common.scad`, so a bare `cd boat_enclosure && openscad …`
can render the *wrong* (main, older) tree depending on where the shell resets. Always render with the **absolute
worktree path** (`…/.claude/worktrees/airboat-enclosure/boat_enclosure/<part>.scad`).

## Post-print refinement — hinge→lid transition (2026-08-06)

Patrick: the door-leaf knuckles meet the lid edge roughly — the **lid's edge chamfer got chopped by the
hinge leaf's sharp square corners on the OUTSIDE (deck) face**. Fix (`door_leaf` in lid.scad): the door leaf
is now a **flush plate carrying the SAME `edge_ch` 45° chamfer on its outer/deck edges as the lid** (built
with the lid's own `chamfered_slab`), so the leaf's edges bevel to match the lid instead of ending in sharp
square corners — the chamfer treatment reads continuous. The plate is flush with the lid top (Y=0), rooted
`door_web_merge` = 3 mm into the lid, and stays full to the deck so the barrel keeps print support; pin bore,
swing gap (0.117 mm), and all manifolds unchanged. **Two dead-end iterations before this** (both misread the
complaint as the *inner* face): (1) RAMPED the leaf top down to the surface — left a thin proud wedge with a
sharp inboard corner on the inner face; (2) flush leaf with no chamfer — clean inner face but the *outer*
edge was still sharp, which is what Patrick actually meant. **Geometric limit worth remembering:** the barrel
*must* tie into the deck for bed support, so the chamfer can't run perfectly unbroken *through* a knuckle —
but the break is now a matching bevel, not a sharp step (inherent to a knuckle hinge). **Debugging the
right target took two wrong guesses — "on the outside of the hinge" = the deck/outer face, not the inner
rib face.**

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
3. **Gland / switch sizes** — every side gland hole is **⌀12 (`port_gland_d`, MEASURED 2026-08-04)**; the
   installed footprint `port_ftp=19` drives the inboard spacing check (not the 12 hole). The lid **switch**
   is **⌀12.2 bore (`lid_switch_d`)** with a **30×15 rib-free keep-out (`switch_ftp`)** for its inner body
   — confirm both, and swap `switch_ftp` to `[15,30]` if your flip switch is rotated 90°.
4. **Threads print quality** — `use_threads=true` models real BOSL2 M4/M3. If they print poorly on
   the MK3S, set `use_threads=false` for thread-forming pilots (`mm_bolt_pilot` / `rod_grub_d`).
5. **`beam_target`** (default 240 mm) must exceed `prop_diameter` or the two stern props collide —
   echo-checked (the rods that used to span it are gone). Confirm the catamaran beam you want, **and
   how the two floats are cross-braced now the rods are removed** (float-level, outside the box).
6. **Float dimensions** — `float_thickness` (60) and `float_freeboard` (42) at ~2 kg all-up are
   assumptions; they set the prop clearance. Confirm against the real float at load.
7. **Which hull is which** — the gland set follows the hull via **`rc_side`** (default `"port"` = the RC/boat-
   electronics box; the other hull is the stimulator). **CONFIRM this matches your physical boat** (a mirror is
   invisible to a probe): with `rc_side="port"`, `side="port"` → RC bores (2 aft motor + 1 fwd control),
   `side="starboard"` → stim bores (signal-in + electrode-out). Flip `rc_side` if your boat is the other way.
   `main.scad` draws both hulls with their own sets. (`-D box_role="rc"|"stim"` still forces a single render.)
8. **Screw mount** — 4× M4 at `screw_positions=[±27,±79]`, default `screw_method="insert"` (M4 heat-set
   brass, melted in from the bed face — install 4 before assembly). Confirm the count/positions clear your
   real component layout; printed-thread fallbacks exist (`selftap` = screw self-taps a stronger thread;
   `thread` = straight into a printed M4 thread) if you'd rather skip inserts. Foam thickness
   (`float_thickness=60`) sets the **max** screw length (`screw_len_est` ≤70 mm; shorter is safer). The
   **stern-block** pylon-attach holes likewise default to `mm_bolt_method="insert"` (4 more M4 inserts,
   melted in from the block aft face). Wide fender washer / backing
   plate under the soft foam so the head can't pull through.

## Propeller guard — flat arc grille + supportless shroud (`propguard.scad`, 2026-08-13)

A best-effort **prop guard** for the 8×4.5 (203 mm) pusher prop, to keep reeds/grass/branches off the disc.
Params + derived live in **`common.scad`** (search "PROP GUARD") so `main.scad` draws it on each hull; the
geometry, echoes, and standalone render are in `propguard.scad`. Bolts into the motor-mount sandwich on the
pad's 4× M3 (`bp_pitch` square, ±`bp_axis`) + 11.5 boss bore — no new holes; M3 screws get `guard_t` longer.

**Design (Patrick's steers this session, in order):**
1. **FLAT, not a 3D cage** — the boat runs FORWARD ~99% of the time, so a flat grille on the **intake side**
   intercepts what comes head-on. A 3D "basket" was built first and killed on DFM (35–52 cm³ support in every
   orientation, ~4.6 cm² bed contact → warp). The flat plate prints face-down, **supportless**.
2. **PARTIAL arc — TOP + OUTBOARD only** (`guard_arc`=135° ⇒ 62% removed, `guard_arc_bias`=45° onto the
   top-outboard diagonal). Bottom sits low near the water; inboard faces the sheltered channel between hulls.
   **Mirrors with `side`.** NB the OUTBOARD side is guard-local −X/180° (verified through the assembly
   transform — the model's +Y points at the water and the hull mirror flips the sign; an early rev had the
   bias backwards, caught by rendering `main.scad`).
3. **ROUNDED edges** — lives in turbulent air, so no sharp corners: `guard_round` rounds aft/top edges,
   `guard_front_round` softens the frontal/intake edges, spokes are **tapered** (`guard_spoke_root` 8 →
   `guard_bar` 3, ~2.7:1) via a hull of rounded cylinders.
4. **SHROUD** (`guard_shroud`) — an aft cowl wall wrapping the tips: catches things swept in from the **side**,
   not just head-on. It's a vertical wall off the flat grille ⇒ **prints supportless**; a filleted inner FOOT
   (`guard_shroud_foot`) spreads the root stress across layers + adds bed contact. Its height **TAPERS** from
   `guard_shroud_h` (28) at the arc MIDDLE to `guard_shroud_h_min` (11) at the ends — most mass/protection
   where the spokes best support it, least where they don't (a single tilted-plane cut → smooth cosine taper).
   The spoke tips **weld into the shroud's inner face** (never poke through the outer), and the shroud arc
   extends `guard_shroud_ext` past each end spoke so the full spoke backs it (no half-contact/dangling end).

**Numbers (defaults):** OD 221, arc 135°, hub r24 **clipped to the pad footprint on the inner (+X) + down (−Y)
sides** (`guard_hub` — round on top/outboard where the spokes flare, flat on inner/down where it meets the pad)
+ 2 relief holes, 1 ring + 5 tapered spokes, shroud r107.5–109.7 × 28→11 mm tapered × 2.2 wall. → **41 g** PETG,
single manifold shell, **supportless** (0.21 cm² off-bed overhang; PrusaSlicer 0 cm³ support at 50°), 153×153×28 mm.

**Hub matches the pad (2026-08-13, Patrick):** the round hub used to overhang the square pad and its lower edge
protruded ~11 mm below the pad toward the sloped buttress (measured ~1 mm clearance — too tight). The hub is now
clipped to the pad's flat face (`guard_pad_inner`=`pylon_width`/2, `guard_pad_bottom`=−(`pad_h`/2−`pylon_fillet`)),
so it **sandwiches flush on the pad** (reads as one part) and its bottom no longer overhangs the buttress —
**verified 0 mm³ guard∩pylon interference** (flush face only). The 4 mount holes are the **same 24 mm square as the
pad** (both from `bp_axis` in common.scad; verified they coincide at the identical 4 points), bore 11.5, M3 clr 3.4.

**Export / render** (from `boat_enclosure/`):
```
openscad -o stl/airboat_propguard_arc_starboard.stl -D 'side="starboard"' -D '$fn=220' propguard.scad
openscad -o stl/airboat_propguard_arc_port.stl      -D 'side="port"'      -D '$fn=220' propguard.scad
openscad -D 'guard_part="onpylon"' propguard.scad    # fit: guard in front of the real BasePlate+Motor+prop
openscad -D 'preview_upright=true' -D 'show_foam=false' main.scad   # both guards on the boat (size check)
```
**PRINT: add a ~5 mm brim** — a 153 mm PETG span with the shroud mass out at the rim; the brim is cheap
warp insurance (AM-review must-do; not a model change).

**Review:** an additive-manufacturing engineer (subagent) verified supportless/1-shell/weight and drove the
elegance pass (smaller hub, exaggerated spoke taper, frontal-edge rounding, shroud foot). A 4-lens adversarial
review (DFM/structure/function/geometry) covered the earlier basket + flat revs.

**Open items — confirm before/after printing:**
1. **OUTBOARD direction** — set `side` to match your boat; *name a feature* (the side toward open water, away
   from the centreline), don't trust a bare left/right — a mirror is invisible to a probe.
2. **Reed coverage is COARSE** — outer cell ~40 (radial) × ~63 mm (tangential): a **branch/clump fender, not
   a fine reed screen**. Adding `guard_rings`/`guard_spokes` closes it (rings add cheap central mass, spokes
   add clutter) — a thrust-vs-protection call. Current is deliberately open per the "few spokes / elegant" steer.
3. **Side gap** — the shroud lip stops at z=28 but the disc plane is `guard_standoff`=34 back, so an object in
   the disc plane clears the lip by ~6 mm; raise `guard_shroud_h`→34 if in-plane side strikes matter (rim mass↑).
4. **Flex-into-prop** — the disc cantilevers off the 4 M3 at r17; `guard_t`=5 alone sets stiffness toward the
   prop (the in-plane grid sits in the neutral plane). It sits 34 mm forward of the disc; raise `guard_t` if a
   push test brings it near the prop.
5. **Mast resonance** — 47 g at the mast tip lowers the mast's 1st bending freq. Patrick is NOT balancing the
   prop, so mass was kept low (arc + short/thin shroud); the shroud is the biggest remaining lever if a rev
   sweep shows a resonance dwell (its mass sits at the worst radius).

### 2-PIECE SANDWICH — mounting rethink (2026-08-13, Patrick) — SUPERSEDES the single-piece mount above

The motor isn't flat: from the pylon pad to the prop is ~29 mm (X-bracket + motor body), so a guard bolted at
the pad can't reach the disc. New scheme — **pylon pad | X-BRACKET | BARREL (spacer) | GUARD | motor**, all
clamped by the **SAME 4 motor screws** (no glue, Patrick's call — easier + a mechanical joint):

- **`guard_barrel()` (piece 1, spacer):** a rounded-square base **LOFTED (BOSL2 `skin()`) up into the round tube**
  over `guard_loft_h`=12 mm -- a smooth aero pedestal, not a cylinder stepped onto a plate (still supportless: the
  corner taper stays under 45°). 4 M3 clearance on the 24 mm square. `guard_barrel_len`=26 mm bridges the motor.
  **Motor barrel = 28 mm → `guard_motor_bore` = 28.5** (0.5 to spin free) in the SNUG base ring where the bolts sit;
  the bore opens wide (`guard_barrel_bore`=42) above so the 4 clamp screws (and the motor) pass through. OD 48. **22 g.**
- **`guard_full()` (piece 2, the guard):** baseplate (OD = barrel OD = 48, flush stack) + the same tapered
  spokes + tapered shroud, now **`guard_shroud_h`=20** (barrel 26 + shroud 20 = **46 mm reach** = Patrick's
  measured cover-the-prop distance). 4 M3 holes on the 24 mm square (the sandwich screws pass through). **36 g.**
- **Assembly:** stack pad → X-bracket → barrel → guard, run **4× M3 ~44 mm** from the pad nut down through the
  barrel's open bore into/through the guard, tighten. Both pieces **single-shell + supportless** (barrel stands
  on its flange, guard face-down). The **bore↔screw wall is ~1.0 mm** (28.5 bore vs r17 screws) in both the
  flange and the guard plate — thin, but clamped in compression in the sandwich, so acceptable.
- Render: `-D guard_part="barrel"` / `"full"` (guard) / `"assembly"` (both + motor + prop ghosts) / `"onpylon"`.
- **STILL OPEN:** confirm the OUTBOARD side (set `side`, name a feature); confirm the real guard-face-to-prop
  distance sets `guard_shroud_h` right; the reed-coverage / resonance notes above still apply.
