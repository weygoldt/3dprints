# DFM / printability review — airboat enclosure on Prusa MK3S (PLA, supportless)

**Date:** 2026-08-04 · reviewer: independent additive-engineering pass (real slicing + mesh
analysis + adversarial multi-agent verification). Covers the merged design (`main.scad`, PR #5).

## Verdict: **YES — producible on an MK3S in PLA with no supports.** All three parts slice
manifold and generate **zero support material**. Two must-do print-setting calls, a few optional
polish items, one doc correction.

| part | verdict | supportless slice | est. time | the one thing to do |
|------|---------|-------------------|-----------|---------------------|
| **body**  | GO (with tweaks) | clean, 0 support, 906 mm overhang-perimeter (localized) | **9h36m** | print `use_threads=false` |
| **lid**   | GO (brim it)     | clean, 0 support, **0 overhang-perimeter** | **4h09m** | add a brim (warp) |
| **pylon** | GO               | clean, 0 support, 193 mm overhang-perimeter | **3h15m** | none (ignore auto-support) |
| **cradle**| GO (brim it, ≤8) | clean, 0 support, 56 mm overhang-perimeter (bail bridges) | **2h23m** | add a brim (*Low bed adhesion*) |

Per hull (all four parts): **~19.5 h machine time, ~235 g PLA** (~190 cm³). Two hulls ≈ 39 h, ~470 g.

**Cradle (added after this review — the float-mount that replaces the lanyard ears):** a thin bonded
collar the box drops into + a 4 mm over-top bungee. Slices **supportless** (0 support material); the
only overhang perimeter is the bungee-bail top bars, which **bridge** between two bed-supported legs
(56 mm total — trivial). Like the lid it is a thin part on a large footprint, so the stability detector
flags **Low bed adhesion → brim it** (~5 mm). Box-capture, lid-swing, and cavity-breach were probe-
verified at 0 mm³. See `AIRBOAT-NOTES.md` › "Float-mount cradle".

## How this was checked
- Sliced every part with **PrusaSlicer 2.9.6** using an **authentic MK3S PLA profile** (0.4 nozzle,
  0.2 mm layer / 0.35 first, 20 % infill, 3 perimeters, overhang-detection on, **supports off**; bed
  patched to the real 250×210×210 from the Prusa vendor profile). Ground truth = does the *supportless*
  slice emit support material, overhang perimeters, or trip the stability detector.
- **Mesh overhang** analysis in each part's true print orientation (world +Z = build up), excluding the
  bed-contact first layer, clustering downward faces by surface-angle-above-horizontal (<45° = risk).
- Every substantive finding was **independently re-derived by a second agent** trying to refute it.

Interpretation guard: "Bridge infill" spanning a whole footprint is *normal* solid-shell-over-infill
bridging, **not** an overhang problem — the real signals are *Overhang perimeter*, *Support material*,
and the slicer's *print-stability* flag. Judged on those, no part needs support.

## Must-do (2)

### 1. Print with `use_threads=false` for the first print — **the single most important call**
The modeled BOSL2 internal threads sit **at or below MK3S PLA radial resolution**:
- **M4×0.7** (stern block, horizontal, teardrop crest): modeled crest ≈ 0.379 mm ≈ **one 0.45 mm
  extrusion wide** — the flank has ~one bead to define it. Prints, but marginal.
- **M3×0.5** (rod grub, vertical): 0.271 mm radial crest, ~2.5 layers/pitch → a **jagged/noisy helix**.
  This hole only exists so a *steel M3 set-screw bites the PVC rod* — a printed thread there is worse than
  a pilot the screw cuts itself.

`use_threads=false` (already a one-flag toggle) drops both to **thread-forming pilots** (M4→3.4 mm blind,
M3→2.5 mm): the bolt / set-screw forms its own thread in PLA — stronger and more repeatable than a printed
thread at this scale, and it removes the `$slop` fit gamble (too tight won't start, too loose strips).
If the M4 clamp later proves marginal, upgrade to **M4 heat-set brass inserts** (pilot ≈ 5.6 mm) — *not*
printed threads. Revisit `use_threads=true` only after a thread-fit test coupon. *(Verified: both families
CONFIRMED under-resolved by an independent pass.)*

### 2. Brim the lid — it's the real warp risk
The lid is a **170 mm-long, 3 mm-thin broad flat panel** — a textbook corner/edge-curl candidate in PLA.
Add a **~5 mm outer brim** (and print on clean PEI at a real **60 °C bed** — see caveat). The body warps
far less (its 39 mm perimeter walls stiffen the floor into a box), but a couple of **brim tabs at the thin
hinge leaf** are cheap insurance on a 9h36 print.
*(The four lanyard ears mentioned in the first draft here are now **removed** — the bonded float-mount
cradle replaces them; see the cradle row above and `AIRBOAT-NOTES.md`.)*

**Nesting decision (couples to the brim):** body + lid nest on one bed at **242 mm across X** (bare) with
~4 mm/side slack — *geometrically real, but only skirtless/brimless*. A modest **3–4 mm outer-only brim
still fits** (sliced maxX 248–249 < 250, inner brims merge in the 5 mm gap). Your call:
- **(a) Nest bare** on one ~13h45 plate — accept some lid corner-lift risk, or
- **(b) Print body & lid separately, each with a full brim** — safest given the lid is the warp driver.
Recommended: **(b)** for the first article, then **(a)** once you trust the bed.

## Optional polish (your call — all currently *fine*, none blocks printing)
- **Teardrop the 3 cable/gland ports** (⌀12.5, inboard wall). They're plain round horizontal bores through
  the 2.5 mm wall; the top arc droops slightly out-of-round. The gland body + nut seat and seal regardless,
  so it's cosmetic — but a `teardrop2d(apex up)` (one line, matching the rod sockets) gives a clean circle.
- **Register-slot roof** (stern block): the pylon-tongue slot has a flat **42.4 mm-wide unsupported ceiling**
  that bridges ~44 mm (biggest single flat overhang on the body). PLA sags ~0.2–0.5 mm there; with only
  0.4 mm total vertical clearance over the 14 mm tongue, the top *could* get tight. It's loaded on the floor
  + side walls, so a snug top is harmless — **file if the tongue binds**, or gable/chamfer/teardrop the slot
  top edge to kill the bridge. Minor. *(CONFIRMED: bridges the 42 mm width, anchored on side walls.)*
- **Pylon foot counterbores** (⌀7.5) and **XT60 window top** (⌀19): minor crown droop, both hidden by the
  bolt head / the XT60 flange. No action.

## Doc correction to fold into AIRBOAT-NOTES.md
- **Pylon print time: ~2 h → 3h15m** (the notes underestimate by ~62 %; measured 3h14m56s supportless).
  Across 2 pylons/catamaran that's ~2.5 h of schedule error. (Body 9h36 and lid 4h09 match the notes.)

## Confirmed-fine (the notes' claims that hold up)
- **Body prints supportless** — 0 support material at every layer; the stern block reaches the bed (no
  float), the hinge-leaf underside is ≥45° (self-supporting, fillet touches exactly 45°), lanyard-ear
  teardrops and lid-overlap step undersides are all ≥45°, rod-socket bores are teardropped and blind.
- **Lid is genuinely trivial** to print outer-face-down (0 overhang perimeter). Only warp, not overhang.
- **Pylon prints supportless** — it's a single prismatic extrude (all walls vertical); the ⌀11.5 central
  bore is correctly teardropped. PrusaSlicer's *auto-support* fills the whole pylon **non-physically**
  (support grows as the threshold rises — backwards); that's a slicer artifact on a tapered/holed prism,
  **not** a real overhang. Slice it supports-OFF and ignore auto-support for this part.
- **Rod-socket boss undersides** droop cosmetically (solid bosses, mid-air bottom tangent) — the *bore* is
  teardropped and unaffected. Rough undersides, no functional impact.

## Caveat on the profile
The MK3S profile was extracted from a prior real slice; its `bed_temperature`/`first_layer_bed_temperature`
read **0** (an extraction artifact) and nozzle temp 200 °C. This affects only *warp realism* (qualitative);
the **overhang, support, bridge, and time results are temperature-independent** and stand. For real prints,
set the bed to **60 °C** (PLA on PEI).
