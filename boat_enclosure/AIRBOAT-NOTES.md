# Airboat enclosure — build notes

`main.scad` reorients the chest-stimulator enclosure into the catamaran **airboat hull
box**. One body serves both hulls via `side = "port" | "starboard"`.

## What was decided (with Patrick)

| Question | Answer |
|---|---|
| Base vs brief | **Reorient** to the flat low-profile float box; reuse the stim enclosure's knuckle hinge, snap-lock skirt, lanyard ears, wall/echo idioms. |
| Prop size | **Parametric** `prop_diameter` (default 203 = 8×4.5); the pylon height derives from it automatically. 1045 (254) is a one-line change. |
| Stern cable port | **One 8 mm** gland (`port_stern_d`). |
| Float mount | **Keep the lanyard/zip-tie ears** — box lashes to the styrofoam with zip ties through the foam. No bottom bolt bosses. |

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

## Prop clearance (parametric)

```
hub_above_water = prop_radius + float_freeboard + prop_clearance_margin
                = 101.5 + 42 + 20 = 163.5 mm   (8×4.5)
disc lowest point clears the float top by prop_clearance_margin (20 mm)
pylon rise above the box floor = 121.5 mm ; hub ~84 mm above the box top
```

Change `prop_diameter` to 254 (1045) and the pylon grows to ~110 mm above the box top — one line.

## Open items to confirm before printing

1. **A2212 bolt pattern** — the default is the standard 16×19 mm cross (holes at ±8, ±9.5),
   M3.2 clearance, with ±1 mm radial **slots** so a slightly-off pattern still bolts up.
   *Measure the real motor with calipers and set `motor_bolt_x` / `motor_bolt_y`.*
2. **`beam_target`** (default 240 mm) sets the rod length (144 mm) and must exceed `prop_diameter`
   or the two stern props collide — echo-checked. Confirm the catamaran beam you want.
3. **Float dimensions** — `float_thickness` (60) and `float_freeboard` (42) at ~2 kg all-up are
   assumptions; they set the prop clearance. Confirm against the real float at load.
4. **Rod grub screws vs split clamp** — currently a cross-drilled M3 grub screw per socket.
