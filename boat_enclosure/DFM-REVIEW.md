# DFM / printability review — airboat enclosure on Prusa MK3S (PLA, supportless)

**Date:** 2026-08-04 · reviewer: additive-engineering pass (real slicing + mesh analysis + intersection-
volume probes). Covers the **current through-board screw-mount design** (`main.scad`). The body/lid/pylon
findings carry over from the PR#5 review; the float-mount section is new (the bonded cradle and the
lanyard ears it replaced, and the two PVC rod sockets, are all **removed**).

## Verdict: **YES — producible on an MK3S in PLA with no supports.** All three parts slice manifold
(1 shell) and generate **zero support material**. Two must-do print-setting calls, a few optional polish
items.

| part | verdict | supportless slice | est. time | the one thing to do |
|------|---------|-------------------|-----------|---------------------|
| **body**  | GO (with tweaks) | clean, 0 support; overhang-risk ~540 mm² (localized) | **~8h47m** | brim tabs at the thin hinge leaf |
| **lid**   | GO (brim it)     | clean, 0 support, **0 overhang-perimeter** | **4h09m** | add a brim (warp) |
| **pylon** | GO               | clean, 0 support, 193 mm overhang-perimeter | **3h15m** | none (ignore auto-support) |

Removing the lanyard ears + the horizontal PVC rod sockets **dropped** the body's mesh overhang-risk from
~1300 → ~540 mm² and its print time ~9h36 → **~8h47m** — the screw mount is a net printability win.

## Float mount — through-board screw bosses (new; supportless by design)
Four M4 blind bosses on the floor **interior** (`screw_positions=[±27,±79]`), each a solid `boss_od=12`
cylinder rising into the chamber; the screw bore is drilled from the **bed face upward**.
- **Prints the easy direction.** Floor-DOWN, each boss stands vertically on the bed (fully supported by
  the layer below) and the blind bore opens at the bed face and runs **straight up** → self-supporting,
  **no teardrop** needed (unlike the old horizontal rod sockets). Sliced supportless: **0 support material**
  for both `screw_method="insert"` and `"thread"`.
- The only new downward face is each **bore ceiling** — a ⌀5.6 flat disc ~9 mm above the bed. That is a
  **5.6 mm bridge**, well inside FDM capability (bridges to ~10 mm are routine); it prints as a clean cap.
  No support, no sag of consequence. (It counts in the mesh "near-flat ceiling" area but is a bridge, not
  a support-need — same interpretation guard as the top/bottom-shell bridge-infill.)
- **Watertight, probe-verified.** Every screw bore ∩ the sealed chamber = **0 mm³** for insert/thread/
  selftap on both `side` settings; positive controls (over-deep bore, boss-under-component) fire, so the
  0 is real. Sealed PLA cap above every bore = **4.5 mm** (thread, default) / 5.5 mm (insert) — a fully over-driven
  real screw still stops on solid PLA.
- **Heat-set insert wall.** `boss_od=12` around a ⌀5.6 insert hole = **3.2 mm** radial wall — meets the
  CNC-Kitchen ≥2×-insert-OD rule, so a hot brass insert seats without splitting the boss.

## How this was checked
- Sliced every part with **PrusaSlicer** using an **authentic MK3S PLA profile** (0.4 nozzle, 0.2 mm layer
  / 0.35 first, 20 % infill, 3 perimeters, overhang-detection on, **supports off**; bed 250×210×210). Ground
  truth = does the *supportless* slice emit support material, overhang perimeters, or trip the stability flag.
- **Mesh overhang** analysis in each part's true print orientation (world +Z = build up), excluding the
  bed-contact first layer, clustering downward faces by surface-angle-above-horizontal (<45° = risk).
- **Watertightness / fit** via intersection-VOLUME probes (`probe.scad`) with positive controls.

Interpretation guard: "Bridge infill" spanning a whole footprint is *normal* solid-shell-over-infill
bridging, **not** an overhang problem — the real signals are *Overhang perimeter*, *Support material*, and
the slicer's *print-stability* flag. Judged on those, no part needs support.

## Must-do (2)

### 1. Printed M4 threads are coarse on the MK3S — know the durability ladder
Two families of modeled M4 thread print (with `use_threads=true`, the default): the **stern-block**
pylon-attach holes, and — by Patrick's call — the **through-board screw-mount bores** (`screw_method
="thread"`, now the **default** so a screw threads straight in, no heat-set inserts). At MK3S PLA radial
resolution the M4×0.7 crest ≈ 0.38 mm (~one 0.45 mm bead): it prints and threads a screw, but the crest is
thin and can **strip under repeated field mount/unmount**. Pick per how often you'll cycle the mount — all
one flag, all **probe-verified watertight**:
- **`screw_method="thread"` (default)** — easiest, no inserts; `thread_len`=10 (~2.5×dia) adds shear area.
  Fine if you don't unbolt the box often.
- **`screw_method="selftap"`** (or `"thread"` + `use_threads=false`) — a plain ⌀3.4 pilot; the screw forms
  its own thread in **solid** PLA: **stronger** than a printed thread, no `$slop` gamble. Best all-round.
- **`screw_method="insert"`** — M4 heat-set brass (⌀5.6 bore): strongest, best for many cycles, needs a
  soldering iron to install.
For the **stern-block** M4 (horizontal, teardrop crest) the same coarseness applies; `use_threads=false`
falls it back to a thread-forming pilot.

### 2. Brim the lid — it's the real warp risk
The lid is a **170 mm-long, 3 mm-thin broad flat panel** — a textbook corner/edge-curl candidate in PLA.
Add a **~5 mm outer brim** (print on clean PEI at a real **60 °C bed** — see caveat). The body warps far
less (its 39 mm perimeter walls stiffen the floor into a box), but a couple of **brim tabs at the thin hinge
leaf** are cheap insurance on an ~8h47 print.

**Nesting (couples to the brim):** body + lid nest on one bed at **217 mm across X** (bare) — comfortable now
the ears + rod bosses are gone (was 242). A full outer brim on both still fits < 250. Your call:
- **(a) Nest bare** on one plate, or
- **(b) Print body & lid separately, each with a full brim** — safest given the lid is the warp driver.
Recommended: **(b)** for the first article, then **(a)** once you trust the bed.

## Optional polish (your call — all currently *fine*, none blocks printing)
- **Teardrop the cable/gland ports** (⌀12, inboard wall). Plain round horizontal bores through the 2.5 mm
  wall; the top arc droops slightly out-of-round. The gland body + nut seat and seal regardless, so it's
  cosmetic — a `teardrop2d(apex up)` gives a clean circle.
- **Register-slot roof** (stern block): the pylon-tongue slot has a flat ~42 mm-wide unsupported ceiling
  that bridges the width (biggest single flat overhang on the body). Loaded on the floor + side walls, so a
  snug top is harmless — **file if the tongue binds**, or gable/chamfer the slot top to kill the bridge. Minor.
- **Screw-bore mouth chamfer** (optional): a ~0.5 mm lead-in at the bed-face mouth would help start a heat-set
  insert square. Left off to keep the box bottom face flat against the foam/washer; add if inserts go in cocked.
- **Pylon foot counterbores** (⌀7.5) and **XT60 window top** (⌀19): minor crown droop, both hidden by the
  bolt head / the XT60 flange. No action.

## Confirmed-fine (claims that hold up)
- **Body prints supportless** — 0 support material at every layer; the stern block reaches the bed (no
  float), the hinge-leaf underside is ≥45° (self-supporting), the lid-overlap step undersides are ≥45°, and
  the **screw bores are vertical blind holes** (open at the bed, run straight up).
- **Lid is genuinely trivial** to print outer-face-down (0 overhang perimeter). Only warp, not overhang.
- **Pylon prints supportless** — a single prismatic extrude (all walls vertical); the ⌀11.5 central bore is
  teardropped. PrusaSlicer's *auto-support* fills the whole pylon **non-physically** (support grows as the
  threshold rises — backwards); that's a slicer artifact on a tapered/holed prism, not a real overhang. Slice
  supports-OFF and ignore auto-support for this part.
- **Mirror is exact** — body port and starboard are byte-identical in volume/overhang; both hulls print equally.

## Caveat on the profile
The MK3S profile's `bed_temperature` reads **0** (an extraction artifact) and nozzle 200 °C. This affects only
*warp realism* (qualitative); the **overhang, support, bridge, and time results are temperature-independent**
and stand. For real prints, set the bed to **60 °C** (PLA on PEI).
