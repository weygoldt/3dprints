// =====================================================================
//  Airboat catamaran electronics enclosure  (v0.1)
//  A low-profile, watertight float box.  ONE body serves both hulls via
//  side = "port" | "starboard" (mirror about the boat centreline).  The
//  top face is a hinged, snap-latched lid whose hinge sits on the OUTBOARD
//  long edge, so both lids open away from the centreline.  Components lie
//  FLAT in a single layer on the floor (no stacking); internal height is
//  set by the tallest single item (3S LiPo, 26.5 mm) plus wire routing.
//
//  Reuses the field-stimulator enclosure's proven mechanisms VERBATIM --
//  the hand-rolled knuckle hinge (1.75 mm filament pin), the inspo overlap
//  skirt + bump/dent snap locks, and the echo fit-check harness -- by keeping
//  that project's CODE FRAME and only remapping which physical axis each
//  stands for:
//
//  FRAME MAPPING (airboat box <- stim enclosure code frame):
//    code X (inner_w, W)  = box WIDTH   (athwartship, ~90)
//                           -X wall = OUTBOARD  -> lid hinge, XT60
//                           +X wall = INBOARD   -> cable ports (glands)
//    code Z (inner_h, H)  = box LENGTH  (fore-aft, ~165)
//                           +Z = BOW, -Z = STERN (motor pylon on the stern wall)
//    code Y (inner_d, D)  = box HEIGHT  (floor->lid, ~35)
//                           Y=0 = LID/TOP (open, the lid covers it)
//                           Y=D = FLOOR (solid; sits on the styrofoam float)
//  Prints FLOOR DOWN (code Y=D face on the bed); print-up = model -y.
//  side="starboard" wraps the whole part in mirror([1,0,0]): left/right
//  (inboard/outboard) reflect while bow/stern and floor/lid stay put, so
//  the hinge stays outboard and the sockets stay inboard on BOTH printed
//  parts.  A mirror about X leaves every +/-y overhang untouched, so both
//  hulls print supportless equally well.
//
//  NEW for the airboat: motor mount + a SEPARATE bolt-on pylon (printed flat),
//  stern + bow cable ports, and a WATERTIGHT THROUGH-BOARD SCREW MOUNT -- the
//  box is rigidly screwed DOWN onto its XPS float by screws that pass UP through
//  the foam from below and thread into blind, sealed bosses on the floor
//  underside (no hole ever breaches the sealed chamber).  DROPPED from the stim
//  donor (they belong to the chest device and would foul the top lid): playback
//  buttons, masthead, eel tie, top-face power switch / LED, BNC.  ALSO DROPPED:
//  the PVC rod sockets and the lanyard/zip-tie ears -- the box is now screwed
//  rigidly to the float, so neither is needed.  KEPT: the XT60 charge port.
//
//  Requires BOSL2 (../BOSL2).  Print PLA, no supports.
//  FILE LAYOUT -- open a file to render that part (no -D part= any more):
//     common.scad  shared params, DERIVED, the ECHO fit-check, shared helpers
//     body.scad    the shell       -> FLOOR on the bed
//     lid.scad     the top panel   -> outer face down
//     pylon.scad   the motor pylon -> laid flat (layers along its length)
//     main.scad    the assembly preview (both hulls, ghosts, hardware phantoms)
// =====================================================================

include <../BOSL2/std.scad>
include <../BOSL2/threading.scad>   // metric tapped holes (Task 5); std.scad omits it

/* [What to render] */
side = "port";       // [port, starboard]  -- which physical hull to render (mirror about the boat centreline)
rc_side = "port";    // [port, starboard]  -- which hull carries the RC/BOAT electronics; the OTHER hull is the
                     // stimulator.  The cable-gland SET now FOLLOWS the hull (Task 3): a `side` render gets that
                     // hull's correct bores, and the assembly draws both hulls with their own sets.  Set this to
                     // match your physical boat.  (You can still force the role directly with -D box_role="rc"|"stim".)
print_ready = true;
lid_open   = 0;      // assembly preview only: degrees the lid is swung open
show_ghosts = true;  // assembly preview: draw components + float + prop discs
show_both_hulls = true; // assembly preview: draw the mirror hull too
preview_upright = false; // assembly preview: rotate so box HEIGHT is vertical (Z-up)
show_hardware = true; // assembly preview: import the real BasePlate.stl + Motor.stl phantoms

$fn  = 64;           // dev speed; bump to 128 for final STL export (-D '$fn=128')
eps  = 0.01;

/* [Enclosure envelope] -- FLAT float box (see FRAME MAPPING above).  The
   existing inner_w/inner_h/inner_d names are KEPT (the brief says do not
   rename); the aliases below give the airboat semantics for new code. */
inner_w  = 90;     // code X = box WIDTH   (athwartship)  -- floor 90 wide
inner_h  = 180;    // code Z = box LENGTH  (fore-aft)     -- floor 90 x 165
inner_d  = 40;     // code Y = box HEIGHT  (floor->lid)   -- LiPo 26.5 + routing
wall     = 3.0;    // was 2.5 -- bumped so the snap-lock rim band isn't a flimsy weak point.  W/H/D are
                   // DERIVED (inner + 2*wall), so this grows the OUTER box ~1 mm and leaves the electronics
                   // cavity (inner_*) untouched; pairs with skirt_t 1.4 -> both joint leaves ~1.5 mm.
corner_r = 7;      // fuller, more designed vertical corners (was 5).  Feeds rprism/cavity/front_step_cut/
                   // lid_r; purely vertical edges so no overhang. corner_r-wall=4.5 stays > 0 for the cavity.

// readable aliases (new code + echoes use these; the ported modules keep the
// original names so they need no edits)
box_width  = inner_w;    // athwartship
box_len    = inner_h;    // fore-aft
box_height = inner_d;    // floor -> lid

/* [Lid] */
lid_t     = 3;     // top-lid outline matches the body exactly (inspo lid == base)

// A bore through the LID for the ON/OFF SWITCH (master power) -- a big chunky FLIP switch.  The local
// motor's phase leads used to route through here, but they now exit via the inboard SIDE glands near the
// pylon (see box_role / Task 3), which frees this lid hole for the switch.  Placed over the stern end,
// clear of the hinge (outboard), the perimeter skirt, and the snap locks.  The switch's INNER BODY
// (switch_ftp) must sit clear of ALL lid stiffening ribs -> lid_ribs_mod KILLS every rib within the
// footprint + switch_clear margin (a full rectangular keep-out, not just a disc around the bore).
lid_switch   = true;
lid_switch_d = 12.2;  // switch panel-mount BORE -- MEASURED (this flip switch needs 12.2)
lid_switch_x = 0;     // athwartship (X): 0 = centreline
lid_switch_z = -60;   // fore-aft (Z): near the stern/pylon end, clear of locks & skirt
switch_ftp   = [30, 15]; // switch INNER-body footprint on the lid [X athwartship, Z fore-aft] -- MEASURED 30x15
                         // (30 across the width here).  If your switch is rotated 90deg, swap to [15, 30].
switch_clear = 3;     // margin kept rib-free around the switch footprint (each side) -- the keep-out is ftp + 2*this

/* [Side & boat] -- one body, two hulls */
beam_target = 234;  // hull centreline-to-centreline spacing (mm).  Set so the OUTERMOST point -- the lid
                    // hinge at +/-(beam/2 + 58) -- lands on the 350 mm (35 cm) deck edge (+/-175): the boat
                    // is exactly 35 cm wide and nothing overshoots.  100 mm skids then tuck +/-8 mm inside
                    // the edge; clear gap between hulls ~13.5 cm; 203 mm prop clears 31 mm (234-203).
                    // MUST exceed prop_diameter or the two stern props collide (echo-checked).

/* [Knuckle hinge] -- hand-rolled, OUTBOARD long edge (-X), axis along the
   length (code Z), 1.75 mm filament pin.  Ported verbatim from the stim
   enclosure; only the span/segment count grow for the longer edge. */
hinge_segs   = 9;      // total knuckles (odd -> housing gets the two ends)
hinge_span   = 160;    // Z (length) span of the knuckle stack, centered
hinge_gap    = 0.3;    // Z clearance between adjacent knuckles (rotation)
knuckle_d    = 6;      // hinge barrel outer diameter
hinge_offset = 7;      // pin axis standoff from the outboard wall face (>=knuckle_d/2)
hinge_fillet = 2;      // housing leaf-to-wall fillet radius (exact tangent arc)
hinge_arm_ang = 35;    // housing leaf underside overhang from vertical (<=~45 for PLA)
door_web_merge = 3;    // how far the DOOR leaf PLATE roots INTO the lid (past the -X edge).  The plate is
                       // flush with the lid top and edge_ch-chamfered on its deck edges (see lid.scad
                       // door_leaf), so this reach is invisible -- it just gives the barrel a solid root.
                       // Kept modest so the leaf doesn't run inboard into the rib ring.
pin_d        = 1.75;   // filament pin nominal
pin_clr      = 0.3;    // added to pin bore

/* [Lid overlap + snap locks] -- the inspo closure, ported verbatim: lid
   skirt over a stepped body band, bump-in-dent interlocks, full perimeter. */
ov_d          = 3.0;   // overlap depth behind the lid plane
skirt_t       = 1.4;   // lid skirt thickness (was 1.1 -- beefed the lid leaf of the joint alongside wall 3.0;
                       // step follows (=skirt_t+clearance) so the bump<->dent clearance stays 0.1, snap unchanged).
lid_clearance = 0.1;   // per-side skirt-to-band clearance (inspo)
lid_clearance_left = 0.25;  // hinge-side (outboard) skirt clearance, looser for the swing
lock_zs       = [55, 27.5, 0, -27.5, -55];  // Z centers of the INBOARD-edge locks (long free edge), EVEN
                       // 27.5 mm pitch.  Was [55,15,0,-15,-55]: the middle three (16 mm-long dents on 15 mm
                       // centres) OVERLAPPED into one ragged blob -- looked unclean AND seated sloppily (two
                       // bumps sharing one merged dent).  Even pitch > dent length (16.8) gives 5 DISCRETE
                       // dents with a ~10 mm clean gap each -> a crisper snap and a tidy rim.  The side glands
                       // sit at Y=port_y (24), the locks at the rim (Y~lock_y=2), so a lock and a gland may
                       // share a Z without ever touching (see the inboard-dent-gap echo).
n_locks       = 3;     // 1 = inboard edge (lock_zs), 2 = + bow end, 3 = + stern end
bump_l        = 16;    // lock bump length along the wall
bump_w        = 1.2;   // bump profile width = triangle base along the closing slide.  With bump_h=0.38 this
                       // is a ~32 deg lead-in ramp: firm but still hand-closeable (was 1.0 = ~27 deg for the
                       // old shallow 0.25 bump; widened in step so the deeper bump doesn't get too steep to seat).
bump_h        = 0.38;  // bump proudness / dent depth (dent = 5% wider, 0.1 deeper).  0.25 popped open too
                       // easily (a <0.25 mm lift unseated it); 0.38 is ~1.5x deeper for a firm, accident-proof
                       // snap while the dent stays clear of the sealed chamber: wall 3.0 - step 1.5 - dent 0.48
                       // = 1.02 mm PLA behind the dent (was a tight 0.82 at wall 2.5; the thicker wall now
                       // leaves real margin over the 0.8 bar -- room to deepen to ~0.5 later if it still pops).
                       // Guarded by the "wall behind the snap dents" echo below.
grip          = true;  // thumb-grip pry wedges on the lid's inboard (free) rim -- opposite the outboard hinge
grip_zs       = [-55, 0, 55];  // Task 4 (2026-08-09, Patrick): was a SINGLE nub at Z=0 (middle of the long free
                       // edge).  Add two more toward the fore/aft ENDS so the lid can be pried up EVENLY along its
                       // ~186 mm free edge, not just at the middle.  Aligned with the outermost snap locks (+/-55):
                       // proven on the FLAT rim (|Z|<=H/2-corner_r=86, clear of the rounded corners) and each 16 mm
                       // (bump_l) nub stays discrete.  All sit at the very edge (X=lid_w/2), just outboard of the locks.

/* [Through-board screw mount] -- REPLACES the lanyard ears AND the rod sockets.
   The box is rigidly screwed DOWN onto its XPS float: screws pass UP through the
   foam from below (wide fender washer / backing plate under the soft foam so the
   head cannot pull through) and thread into BLIND, SEALED bosses on the floor
   underside.  Each boss is a solid PLA cylinder unioned to the floor and rising
   INTO the chamber; the screw bore is drilled from the BOTTOM (bed) face UPWARD
   and stops a sealed cap short of the boss top -- so NO hole ever breaches the
   sealed electronics chamber (the single most important property; echo + probe
   checked).  Prints floor-DOWN: the bosses rise vertically off the bed, fully
   supported -> the blind bores are self-supporting (no teardrop needed).  Bosses
   sit in the free gaps between the floor components (echo-checked vs rc_parts).
   Mirrors with `side` (symmetric X pattern -> port/starboard land identically). */
screw_mount     = false;     // Task 3 (2026-08-09, Patrick): OFF -- these interior floor bosses stuck up INSIDE
                             // the housing.  REPLACED by corner_mount (external hold-down lugs beside the end
                             // blocks) in the [Hull hold-down] block below.  Code kept for reference/rollback.
screw_method    = "insert";  // [insert(M4 heat-set brass, DEFAULT), thread(BOSL2 modeled M4 ->
                             //  screw straight into the PLA), selftap(thread-forming pilot)]
// "insert" bores a plain 5.6 mm hole and you melt an M4 brass heat-set insert in from the bed
// (underside) face; the hold-down screw then threads into brass -- the strongest, most reusable
// hold, with no printed-thread wear across repeated field mount/unmount.  "thread" prints a real
// internal M4 thread (needs use_threads=true) so a screw threads straight into the PLA -- no
// inserts to install, but M4x0.7 printed threads on a 0.4 mm nozzle are coarse (see DFM-REVIEW)
// and wear if you mount/unmount a LOT.  "selftap" bores an undersized pilot; the screw cuts its own.
screw_size      = 4;         // M4 nominal (tension + shear hold-down; assembled/disassembled in the field)
// 4 bosses as a symmetric rectangle inset from the corners, tucked in the gaps
// between the RC components (see rc_parts) and merging into the bow/stern end
// walls for stiffness.  [X athwartship, Z fore-aft], box model frame.
screw_positions = [[-27, 79], [27, 79], [-27, -79], [27, -79]];
boss_od         = 12;        // boss outer diameter -- CNC-Kitchen rule: >= 2x the INSERT OD (insert_od,
                             // NOT the hole), so a hot brass insert seats without splitting the boss.
                             // 12 = exactly 2x a 6.0 mm M4 insert; bump to ~13 for inserts nearer 6.4.
boss_rise       = 12;        // how far the boss rises off the floor INTO the chamber
boss_cap_min    = 3;         // min sealed PLA cap above the bore top (watertight bar; >=2.5)
// -- (insert) M4 brass heat-set: plain round bore, insert melts in from the bed face --
insert_d        = 5.6;       // heat-set HOLE for M4 brass (MEASURE your inserts; ~5.6-5.7)
insert_od       = 6.0;       // heat-set brass OUTER knurl OD (MEASURE; ruthex M4 ~6.0, some ~6.4) --
                             // the melted insert expands the hole to this; the CNC-Kitchen 2x boss rule uses it
insert_depth    = 9;         // bore depth up from the floor underside (insert ~8 + melt lead)
// -- (thread) BOSL2 modeled internal M4 thread -- the screw threads straight into the PLA --
screw_pitch     = 0.7;       // M4 coarse
thread_len      = 10;        // modeled-thread engagement up from the underside (>=2x dia; deeper = more
                             // thread shear area, which helps the coarse printed thread in soft PLA)
// -- (selftap) thread-forming pilot: a plain undersized hole, the screw cuts its own (stronger) thread --
selftap_d       = 3.4;       // ~0.85 x major (M4)
selftap_depth   = 9;         // pilot depth up from the underside

/* [Hull hold-down] -- Task 3 (2026-08-09, Patrick): REPLACES the interior floor bosses.
   The box now bolts to the XPS float through 4 external corner LUGS -- one on the LEFT and
   one on the RIGHT of EACH end block (front + back of the box, because mount_both_ends puts a
   block at both ends).  Each lug fills the otherwise-empty wedge BESIDE the block (between the
   +/-mm_pad_w/2 block side and the +/-W/2 box edge), so it adds NO footprint -- the block
   already reaches this Z and the box already this X.  A vertical M4 clearance hole runs down
   through the lug to the foam; a hex NUT POCKET is recessed into the lug's TOP face (opens to
   the sky -> supportless floor-down).  Drop an M4 nut in the top, run the hold-down bolt UP
   from under the foam (fender washer / backing plate below the soft foam), and tightening seats
   the nut on the pocket floor and clamps the box down.  Everything is OUTSIDE the sealed wall:
   nothing sticks up inside the housing and no bore breaches the chamber (probe-checked).  Sitting
   right at the ends (Z ~ +/-100) also gives a much WIDER hold-down base than the old +/-79 bosses,
   which the old MOUNT NOTE flagged as too narrow vs the aft mast (less pitch, less bolt tension). */
corner_mount    = true;      // ON: the new external corner-lug hold-down (screw_mount floor bosses default OFF)
hd_post_h       = 16;        // lug height ABOVE the foam (Y) -- sets the (short) hold-down bolt length: foam + this
hd_w            = 18;        // lug width (X): overlaps the block side for a weld AND stays inboard of the box edge
hd_screw_d      = 4.5;       // M4 CLEARANCE through the lug (the bolt comes UP from under the foam)
hd_nut_af       = 7.2;       // M4 nut ACROSS-FLATS pocket (DIN934 M4 ~7.0 + slop) -- MEASURE your nuts
hd_nut_depth    = 3.6;       // hex pocket depth from the top face (M4 nut ~3.2 thick + a little capture)
hd_inset        = 7;         // bolt X offset OUTBOARD of the block side (mm_pad_w/2): sets hd_x = mm_pad_w/2 + this

/* [XT60 charge port] -- KEPT (each hull has a cell to charge).  On the BOW end
   wall (+Z): the outboard wall is fully occupied by the lid hinge (the 35 mm
   flange cannot clear the +/-60 knuckle stack), and the inboard wall carries
   the cable ports -- the bow end is the only clear face.
   Measured off the real part (hole 19x11.5, screw 2.4->2.8, sep 25, flange 35x16). */
xt60          = false;
xt60_face     = "bow";     // [bow(+Z end), stern(-Z end), left(outboard), bottom(floor), none]
xt60_body     = [19, 11.5];// connector through-hole [long(screw axis), short] -- MEASURED
xt60_screw_d  = 2.8;       // clearance for the 2.4 mm screw (side-wall holes print undersized)
xt60_screw_sep= 25;        // MEASURED
xt60_pos      = 0;         // position along the face (X on bow/stern; Z on a side wall)
xt60_y        = 0;         // Y offset of the flange center from mid-height
xt60_flange_h = 16;        // flange SHORT axis (Y)
xt60_flange_len = 35;      // flange LONG axis (screw line): X on bow/stern, Z on a side
xt60_body_depth = 12;      // how far the connector body reaches inward

// =====================================================================
//  TASK 5 -- PLA FASTENERS (heat-set inserts, default)
//  Both PLA-threaded families now default to M4 HEAT-SET BRASS INSERTS: bore a
//  plain insert_d hole and melt the brass insert in; the screw threads into
//  brass (strongest, reusable, no printed-thread wear).  BOSL2 tapped_hole() is
//  only reached when a family's method is switched back to "thread":
//    (a) the 4 stern-block pylon-attach holes -> M4  (only when mm_bolt_method="thread")
//    (b) the through-board screw-mount bosses  -> M4  (only when screw_method="thread")
//  In "thread" mode use_threads=true models real BOSL2 internal threads; set it
//  false to fall back to thread-FORMING pilot holes.  The stern-block holes print
//  with their axis HORIZONTAL, so BOTH the insert bore and the modeled thread are
//  TEARDROPPED (apex up) to self-support; the screw-mount bores print VERTICAL
//  (self-support automatic).  The pylon-foot holes and cable ports stay plain
//  (bolt+nut / gland).
// =====================================================================
use_threads = true;
thread_slop = 0.1;    // BOSL2 internal-thread clearance ($slop): adds ~4*slop to the bore

// =====================================================================
//  TASK 1 -- MOTOR MOUNT + PYLON (highest priority)
// =====================================================================
/* [Prop & clearance] -- the ONE knob the user asked for: set prop_diameter
   and the required pylon height falls out.  Default 8x4.5 (203 mm): shorter,
   stiffer, ~450 g static thrust/motor.  1045 (254 mm) is a one-line change. */
prop_diameter        = 203;   // 8x4.5 = 203 (SETTLED), 1045 = 254
float_thickness      = 60;    // styrofoam float thickness
float_freeboard      = 42;    // float top above the waterline at ~2 kg all-up
prop_clearance_margin= 10;    // disc lowest point above the float top
prop_z_offset        = 65;    // how far AFT of the stern wall the prop disc sweeps

/* [Motor + BasePlate mount] -- item 2.  The real chain is
   motor -> BasePlate.stl -> pylon pad.  The motor bolts to an X-shaped plate,
   and THAT plate bolts to the pad, so the pad carries the plate's OUTER "+"
   pattern, NOT the motor's own 2212 pattern.  Measured off BasePlate.stl
   (39.49 sq x 2 mm), holes verified as exact cylinders:
     outer "+" (plate -> pylon): (+/-16,0) and (0,+/-16) = 32 mm across each
        axis, 3 mm (M3), countersunk on the plate for flat-heads  <-- OURS
     central bore: 10 mm  (motor bell/boss clearance)
     inner 2212 (motor -> plate): (+/-9.5,0),(0,+/-7.75), 2 mm    <-- the plate's job
   The motor's own pattern is the plate's problem; the pad only matches the "+"
   holes and clears the central boss.  Measure YOUR plate before printing. */
bp_size        = 39.5;  // BasePlate square (MEASURED) -- the pad backs this
// (2026-08-09, Patrick) The pad's 4 plate-mount holes form a SQUARE; bp_pitch is its SIDE -- the
// ADJACENT hole spacing you actually caliper on the X-bracket (top-left to top-right, NOT the
// diagonal).  The BasePlate.stl reference was a 32 mm "+" across each axis (= holes at +/-16, a
// 22.6 mm SIDE once ROTATED 45deg to an X) -- but the REAL bracket measures 24-24.5 mm on the side,
// so the pad now follows the physical part, not the STL.  bp_bolt (the across-axis / diagonal =
// bolt-circle dia) is DERIVED from bp_pitch below for the echo + central-bore talk.
bp_pitch       = 24.25; // MEASURED adjacent hole spacing (side of the 4-hole square) -- MEASURE YOURS.
                        // 24.25 = midpoint of the 24-24.5 range; the widened bp_screw_d below seats it
                        // anywhere in that band.
bp_bore        = 10;    // BasePlate central bore -- pad clears the motor boss poking through
bp_screw_d     = 3.8;   // M3 clearance through the pad (was 3.4): WIDENED so the pattern seats over the
                        // whole 24-24.5 measured band -- radial slop 0.4 covers +/-0.5 mm of spacing
                        // error, well past the +/-0.25 the 24.25 nominal needs.  These are pass-through
                        // clearance holes (flat-head from the plate, nut behind); the metal plate + nut
                        // locate the pattern, so looser holes cost nothing and absorb the hand-measure.
bp_edge        = 5;     // pad material beyond the bolt centres (keeps >=3 mm wall at the M3s)
motor_pad_t    = 5;     // pad thickness aft of the mast (>=5)
motor_body_d   = 28;    // motor can diameter (MEASURED off Motor.stl; pad + ghost sizing)
// Item 1 (2026-08-06): with pylon_fillet raised to 6 the pad-top round SWALLOWED the top motor "+"
// screw (at pylon_rise + bp_bolt/2) -- the head/plate landed on the curve.  Extend the pad UPWARD by
// pad_top_pad so a full FLAT seat sits above that screw before the round begins.  Only the top grows
// (the bottom still merges into the buttress), so the mast + motor axis stay put.
pad_top_pad    = 6;     // extra flat above the top "+" screw (>= pylon_fillet + ~1 keeps the screw off the round)

/* [Motor mount + pylon] -- SEPARATE printed pylon bolts to a protruding BLOCK on the
   stern wall.  Every fastener stays inside that block, AFT of the wall -- none enters
   the sealed cavity (echo-checked).  A register socket takes the shear/moment so the
   M4s are not in pure shear.  The pylon prints laid FLAT (layers along its length carry
   the bending load).  Task 2 (2026-08-09, Patrick): the SAME block is mirrored onto the
   BOW wall too (mount_both_ends), so ONE pylon can bolt to EITHER end -- motor facing
   AFT (pusher) or FORWARD (tractor).  Both blocks are identical; the assembly still shows
   the pylon at the stern.  This grows the printed LENGTH to H + 2*mm_block_depth, so the
   body now prints ROTATED (length along the long bed axis) -- see the body-fit echo. */
mount_both_ends = true; // Task 2: add a second, identical pylon mount on the BOW wall (mount the pylon either way)
mm_block_depth = 14;    // stern block aft protrusion (the insert / bolt thread lives here)
mm_bolt_method = "insert"; // [insert(M4 heat-set brass, DEFAULT), thread(BOSL2 modeled M4), selftap(pilot)]
                        // how the 4 pylon-attach bolts engage the block.  "insert": bore insert_d and
                        // melt an M4 brass insert into the block aft face -> the screw threads into
                        // brass (strongest, reusable).  "thread"/"selftap": into the PLA, as screw_method.
mm_pad_w       = 50;    // block width  (X)  -- extends DOWN to the floor (load spread, no overhang)
mm_bolt_x      = 28;    // M4 spread across the width (Z): pulled in so the foot bolt COUNTERBORES
                        // (Task 1 redesign) clear the 42 mm pylon edge by >=3 mm
// Item 3 (2026-08-06): was 26 -- at that spread the LOW foot bolt sat so near the foot base that its
// counterbore ran into the (now r6->r4) base-corner fillet ("screws on the rounded radius").  The
// forward gusset (item 2) now carries the forward-tipping MOMENT in compression, so the bolts no
// longer need a tall spread to resist it -- they just clamp.  20 RAISES the low foot bolt onto clean
// FLAT and keeps the block-edge walls healthy, with the same footprint.  Block holes track this param.
mm_bolt_y      = 20;    // M4 spread across the height  (moment now goes through the gusset, not the bolt spread)
mm_bolt_depth  = 10;    // blind hole depth into the block (< block_depth-2); fits the M4 insert (~8) + lead
mm_bolt_pilot  = 3.4;   // (selftap / thread-fallback only) thread-forming pilot for M4 in PLA
reg_depth      = 8;     // register tongue/slot depth (fore-aft) -- the primary shear/moment key (item 4:
                        // KEEP the square peg, deepen it 6->8 for more engagement; a dovetail's thin flare
                        // necks would be stress risers under this moment and would fight the flat side-print)
reg_h          = 10;    // register tongue/slot HEIGHT (was 14).  The CENTRED slot must not collide with the 4
                        // M4 attach-insert bores once item 3 pulls them inward: at reg_h 14 + mm_bolt_y 20 the
                        // upper insert bore ran TANGENT to the slot (0 mm PLA -> insert reflows into the slot).
                        // Trimming the slot to 10 (deeper engagement via reg_depth 8 more than pays for the
                        // lost height) leaves >=2 mm PLA bore<->slot (mm_bolt_slot_wall echo now guards this).
// -- Pylon: a SEPARATE flat-extruded part.  Patrick's v0.2 redesign makes the
// reinforcement a FULL-HEIGHT triangular buttress (thick fore-aft at the foam
// BASE, tapering to the mast tip -- the moment peaks at the base, so that is
// where the section must be deep) with FILLETED transitions, and trims the
// width to the motor-bolt floor.  Still ONE linear_extrude => supportless, with
// the layers running along the mast (the bending load stays within the layers).
pylon_width    = 44;    // (was 44) trimmed to the motor "+" pattern (+/-16) + >=3 mm walls
pylon_root_t   = 12;    // mast fore-aft thickness at the TIP (was 8).  Deepening the tip mainly stiffens the
                        // torsionally-soft tip (J ~ t^3, where the motor mass + gyro/imbalance couples act)
                        // and finishes the silhouette; a tip-mass cantilever's FUNDAMENTAL is governed by
                        // BASE compliance, so tip depth barely moves f_1. >=4.
pylon_gusset   = 18;    // fore-aft thickness added at the BASE (was 16; base_aft = root + gusset = 30).  The
                        // BASE is the efficient lever for the 1st-bending frequency (base I +~95% vs the old
                        // 8/16): a higher f_1 + lower root stress means the mast spends less of a swept-rpm
                        // run near resonance at lower amplitude -- it does NOT dodge the band (a run sweeps
                        // through it).  GROW THIS, not root_t, if you want a stiffer/higher-f mast for a big
                        // prop.  NB: BALANCING THE PROP is the dominant vibration lever -- geometry can't fix
                        // an unbalanced prop.
pylon_bolt_d   = 4.4;   // M4 CLEARANCE through the foot (the block holes take an M4 heat-set insert by
                        // default; thread/selftap fallbacks) -- the bolt threads into brass, not the foot
pylon_fillet   = 4;     // smooth-transition fillet radius at the mast/pad/base junctions (item 1/3: was 6,
                        // trimmed to 4 -- r6 rounded the mast tip/pad-top nicely but rolled the screw seats
                        // onto the curve; r4 still smooths the peak-moment base + finishes the silhouette while
                        // leaving flat under the pad-top screw (with pad_top_pad) and the low foot bolt).
foot_cbore_d   = 7.5;   // M4 socket-head counterbore in the foot aft face (recesses the head)
foot_cbore_h   = 5;     // counterbore depth
// Item 2 -- FORWARD SLOPE / GUSSET: the mast's FORWARD face is a FULL-HEIGHT taper (mirroring the
// aft buttress).  It runs from a flat bearing FOOT on the block top all the way up to just below
// the motor pad.  The foot (90deg to the mast) sits ON TOP OF THE STERN BLOCK and reaches forward
// to the housing's stern wall: when the motor thrusts, the pylon tips forward and this foot drives
// DOWN into the block top -- a direct compression path into the body that off-loads the 4 attach
// bolts (see mm_bolt_y).  Rev 2026-08-06 (Patrick): carry the slope the FULL height instead of
// topping out mid-mast in a point -- the old short bracket ended in a stress-concentrating apex at
// ~3/4 height; spreading the section change over the whole mast (like the aft taper) distributes
// the bending stress evenly.  Added to the SAME single flat linear_extrude (crisp, like the tongue),
// so it costs NOTHING in supports, and it stays aft of the lid (bears on the block top) -> lid clear.
fwd_gusset      = true;  // item 2: the forward slope / compression bracket
fwd_gusset_top_gap = 2;  // where the forward slope tops out BELOW the motor pad (was fwd_gusset_rise=24, a
                         // mid-mast apex).  Small -> the slope climbs nearly the whole mast, just shy of the pad.
fwd_gusset_gap  = 0.15;  // clearance under the bearing foot so it never fights foot-seating; small so the
                         // gusset engages after minimal deflection (it is a compression bracket for the
                         // dominant FORWARD thrust; aft/handling loads are carried by the deep tongue + bolts)

// =====================================================================
//  TASK 3 -- CABLE GLANDS (inboard +X wall) -- PLAIN through-holes, role-based.
//  The cable GLAND supplies its own shoulder/seal (threaded body seats in the
//  hole, nut inside), so there is NO printed boss (Patrick, item 4).  port_gland_d
//  is the gland's PANEL-MOUNT hole; port_ftp is the installed gland's OUTER
//  hex/dome footprint on the wall (this, NOT the hole, drives feature SPACING).
//  Both MEASURED by Patrick (2026-08-04): hole = 12, installed footprint ~= 19.
//
//  box_role picks the gland SET (the two hulls carry different electronics):
//    "rc"   (boat electronics): 2 motor glands AFT by the pylon (same-side +
//           opposite-side motor, one 3-wire bundle each) + 1 control gland well
//           FORWARD (stim control signal out), kept away from the motor phase wires.
//    "stim" (stimulator):       2 glands, both well FORWARD (max distance from the
//           external motor wiring that runs aft): signal-IN (from the RC receiver)
//           + electrode-OUT.
//  Every gland is the same 12 mm hole at Y=port_y on the inboard wall.
// =====================================================================
port_gland_d   = 12;    // gland panel-mount hole -- MEASURED (every gland is the same)
port_ftp       = 19;    // installed gland hex/dome OD on the wall (MEASURED) -- the spacing check uses THIS
port_y         = 24;    // Y of the gland centers (above the on-floor components)
rc_motor_zs    = [-72, -48]; // RC: 2 aft motor glands by the pylon (same-side + opposite-side, 3 wires each)
rc_ctrl_z      = 55;    // RC: control-signal gland, well forward (far from the motor wires for less EMI pickup)
stim_in_z      = 55;    // STIM: signal-in from the RC receiver (forward)
stim_out_z     = 30;    // STIM: stimulus electrode leads out (forward)
// role <-> hull, and the gland Z SET for a role (inboard +X wall; body cuts one plain hole per Z).
// The set FOLLOWS the hull: rc_side names which hull is RC, the other is stim.  body(role) takes the
// role so the assembly can draw each hull with its own set; the standalone render uses box_role (from side).
function gland_set(role) = (role == "stim") ? [stim_in_z, stim_out_z]
                                            : concat(rc_motor_zs, [rc_ctrl_z]);
function role_of_side(s)  = (s == rc_side) ? "rc" : "stim";
box_role = role_of_side(side);   // THIS render's electronics role, derived from the hull (override: -D box_role=...)
gland_zs = gland_set(box_role);  // the standalone-render / echo set

// =====================================================================
//  FINISHING PASS  (edges, splash gasket, lid ribs, interior structure)
//  A refinement layer over the verified design: it only ADDS material or
//  removes it OUTSIDE the sealed void / away from the mechanisms, so every
//  hard invariant (watertight, supportless, nesting, hinge/snap/register,
//  0-interference lid seat) is preserved.  Everything here is prop-independent.
// =====================================================================
edge_ch      = 1.5;   // shared 45deg chamfer on printed BED faces (lid top edge, block aft corners)
foot_chamfer = false; // body FOOT bottom-edge chamfer -- OFF (Patrick): the stern block's foot is square, so the
                      // chamfer left a mismatched gap where the body meets the block; a square foot also seats the
                      // whole bottom flush on the bed (easier first layer).  Flip true to restore the finished foot edge.
// -- perimeter foam-tape gasket land + retention groove on the body TOP rim (the splash seal) --
seal_gasket  = false; // OFF (Patrick): the inboard sealing lip is a full-perimeter cantilevered overhang at the
                      // top of the print -> the slicer wants support INSIDE the deep box (awkward to remove, mars
                      // the very sealing face).  It only bought SPLASH resistance anyway (a capsize floods the box
                      // through the glands/lid regardless), and the lid's overlap skirt + snap locks still shed the
                      // bulk of prop spray.  If spray intrusion shows up in testing, stick adhesive foam weatherstrip
                      // on the flat rim -- no printed lip needed.  Flip true to restore the printed land + groove.
seal_land_w  = 2.5;   // width of the added inboard lip -> flat sealing land = existing rim(1.3) + this = 3.8
seal_land_h  = 5;     // how far the lip rises DOWN into the chamber from the Y=0 rim
seal_groove_w= 2.0;   // foam-tape retention channel width (centred on the land, >=0.8 mm PLA to each edge)
seal_groove_d= 0.9;   // channel depth (was 0.6).  GASKET SPEC: lay ~1.5 mm adhesive closed-cell foam/PORON
                      // weatherstrip TAPE (NOT a 2-3 mm cord) in the channel -- it protrudes ~0.6 mm above
                      // the land, and the flat lid underside compresses it ~40 % while STILL bottoming on
                      // the ~0.9 mm flat land strips either side of the groove (so the 0-interference lid
                      // seat + every snap lock are preserved -- the land IS the crush stop).  4.1 mm of lip
                      // stays below the groove; >=0.8 mm PLA to the void laterally (probe-verified 0 breach).
// -- lid underside stiffening waffle (kill the panel bow that breaks the seal) --
lid_ribs     = true;
rib_t        = 1.6;   // rib thickness
rib_h        = 3;     // rib protrusion into the chamber (was 5 -- Patrick: too deep/overkill).  3 mm on the
                      // 3 mm panel still stiffens the long-axis bow, and clears the LiPo top (Y=13.5) with room.
rib_inset    = 7;     // perimeter rib inset from the skirt inner face (was 5).  7 keeps the perimeter rib
                      // ~2 mm clear of the body seal lip (was a razor 0.3 mm) so print tolerance + lip droop
                      // can't make them clash and hold the lid off its seat.
// EVEN bays (was [-28,0,28]/[-55,0,55], which left ragged ends): every internal rib now runs ring-to-ring
// (lid_ribs_mod terminates them on the perimeter ring -- no overshoot) and the spacing divides the field evenly.
rib_xs       = [-20, 0, 20];   // longitudinal ribs (run fore-aft, along Z) at these X
rib_zs       = [-42, 0, 42];   // transverse ribs (run athwartship, along X) at these Z -- clear of the switch bay (Z=-60)
// (switch_ftp / switch_clear -- the switch keep-out that kills ribs around the hole -- live in the [Lid] block above)
// -- lid deck shadow-gap panel line (looks) -- OFF: a recessed groove in the OUTER
// (bed) face fights a clean flat bottom (Patrick: prints poorly flat on the bed).
// The 45deg top-edge chamfer alone carries the finished-deck look. Flip true to restore.
lid_panel_line = false;
panel_inset  = 7;     // inset of the shadow-gap line from the lid outline
panel_w      = 1.5;   // line width
panel_d      = 0.9;   // line depth into the OUTER (bed) face  (leaves >=1.8 of the 3mm lid)
// -- interior floor<->wall coves (spread loads; stiffen the 2.5mm wall roots) --
floor_cove   = true;
cove_leg     = 3;     // 45deg cove leg along the internal floor/wall junction (supportless floor-down)
// -- stern motor-block sculpting (fillet/chamfer the block-to-shell junctions) --
block_sculpt = true;
block_fil_r  = 4;     // vertical block-side <-> stern-wall concave fillet radius (looks + load path)

// =====================================================================
//  FOAM CATAMARAN BODY  (the XPS float the enclosures ride on)
//  Hand-cut XPS, NOT printed -- modeled for ASSEMBLY / CLEARANCE / aesthetics
//  and to plan the raked-bow cut.  Two plate layers:
//    * a full-width DECK (top plate) with a central water-access CUTOUT, and
//    * TWO SKIDS glued to its underside -- the catamaran floats.
//  ONE enclosure rides on each skid (centred over it); the props sweep aft over
//  the stern; the BOW is raked back for lower water-entry drag + a finished look.
//  Frame = the enclosure model frame: X athwartship (boat centreline X=0),
//  Y down (+Y toward the water; foam TOP at Y=D = the enclosure floor),
//  Z fore-aft (+Z BOW, -Z STERN).  All dims MEASURE/confirm on the real foam.
// =====================================================================
show_foam       = true;   // assembly preview: draw the foam catamaran body
deck_w          = 350;    // deck athwartship width  (X, the beam)      ~35 cm
deck_len        = 550;    // deck fore-aft length    (Z)                ~55 cm
deck_t          = 25;     // deck (top plate) thickness (Y)   -- deck_t+skid_t = float_thickness
deck_r          = 15;     // deck plan corner radius (stern corners; the bow is raked)
deck_cut_w      = 120;    // central water-access cutout, athwartship (X)   ~12 cm
deck_cut_len    = 300;    // central water-access cutout, fore-aft   (Z)   ~30 cm
deck_cut_r      = 30;     // cutout corner radius
skid_w          = 100;    // each skid athwartship width (X)  ~10 cm -- matches the enclosure box (96 mm)
                          // so the skids sit UNDER the boxes and don't overshoot the deck (was 150 = overhang)
skid_len        = 550;    // each skid fore-aft length  (Z)  -- default shares the deck bow/stern
skid_t          = 35;     // each skid thickness (Y)         -- deck_t+skid_t = float_thickness (60)
skid_r          = 20;     // skid plan corner radius (stern; the bow is raked)
deck_center_z   = 40;     // deck centre fore-aft vs the enclosures (+ = more FOREdeck, props aft)
// Raked bow: a single inclined cut across the whole foam front -- the underside
// sweeps UP toward a forward top point (ski-tip / raked stem): finer water entry,
// less spray, and it reads as a purpose-built boat.  Angle from vertical.
bow_rake_ang    = 30;     // bow rake from vertical (deg); 0 = square bow.  Patrick to tune

// =====================================================================
//  DERIVED
// =====================================================================
W = inner_w + 2*wall;
H = inner_h + 2*wall;
D = inner_d + wall;          // BODY height only; the lid sits PROUD above (Y<0)

lid_w = W;                   // lid outline == body outline
lid_h = H;
lid_r = corner_r;

front_inner_y = 0;                         // lid plane (Y=0, top)
back_inner_y  = inner_d;                    // floor inner surface

// hinge axis (parallel to the length Z, just outside the outboard -X corner)
Ax = -(W/2) - hinge_offset;
Ay = ov_d/2;   // pin axis at MID-OVERLAP depth (see the swing-gap echo)
pin_bore = pin_d + pin_clr;
kr       = knuckle_d/2;

// knuckle stack: hinge_segs segments over hinge_span, hinge_gap apart
seg_h = (hinge_span - (hinge_segs-1)*hinge_gap)/hinge_segs;
function seg_z(i) = -hinge_span/2 + i*(seg_h + hinge_gap);

// housing leaf underside geometry (exact fillet tangent) -- ported verbatim
leaf_P  = [Ax - kr*cos(hinge_arm_ang), Ay + kr*sin(hinge_arm_ang)];
leaf_T1 = leaf_P + ((-W/2 - hinge_fillet*(1 - cos(hinge_arm_ang)) - leaf_P.x)
                    / sin(hinge_arm_ang)) * [sin(hinge_arm_ang), cos(hinge_arm_ang)];
leaf_F  = leaf_T1 + hinge_fillet*[-cos(hinge_arm_ang), sin(hinge_arm_ang)];
leaf_reach = leaf_F.y;

// lid overlap derived values -- ported verbatim
step      = skirt_t + lid_clearance;
step_left = skirt_t + lid_clearance_left;
lock_y    = ov_d - 1.0;
swing_gap = hinge_offset + skirt_t + lid_clearance_left
          - sqrt(pow(hinge_offset + skirt_t, 2) + pow(ov_d/2, 2));
skirt_max_ang  = atan((ov_d - Ay)/hinge_offset);
shell_bevel    = atan((ov_d + 0.3 - Ay)/hinge_offset);

// --- Task 1 derived: prop clearance & pylon height ---
prop_radius = prop_diameter/2;
box_outer_height = D;                       // floor to body top, above the float
hub_height_above_water = prop_radius + float_freeboard + prop_clearance_margin;
hub_above_box_top = hub_height_above_water - (float_freeboard + box_outer_height);
pylon_rise = hub_height_above_water - float_freeboard;   // hub above the box floor/mount
disc_low_above_float = hub_height_above_water - prop_radius - float_freeboard; // >0 clears

// RC component footprints on the floor (the layout the bosses must avoid, and the
// assembly-preview phantoms).  Defined here so the screw-mount clearance check below
// can reference it.  [name, footprint[X,Z], height, center[X,Z]] -- box model frame.
rc_parts = [
  ["LiPo 3S",   [34, 75],  26.5, [ -25,  30]],
  ["ESC1",      [25, 45],  15,   [  20,  45]],
  ["ESC2",      [25, 45],  15,   [  20,  -5]],
  ["FS-iA6B",   [27, 47],  12,   [ -25, -35]],
  ["opto",      [30, 40],  10,   [  22, -50]],
];

// --- Through-board screw-mount derived (box model frame; floor underside = Y=D) ---
// The bore is drilled from the bottom (bed) face Y=D UPWARD (toward -Y / the lid).
// It must stop a sealed cap short of the boss top so it never reaches the chamber.
screw_hole_depth = (screw_method=="insert") ? insert_depth
                 : (screw_method=="thread") ? thread_len
                 :                            selftap_depth;      // up from the underside
screw_bore_d     = (screw_method=="insert") ? insert_d
                 : (screw_method=="thread") ? screw_size + 4*thread_slop   // ~thread minor+slop
                 :                            selftap_d;          // nominal bore (echo / wall check)
boss_h        = boss_rise + wall;                 // total boss height: underside (Y=D) -> boss top
boss_top_y    = D - boss_h;                       // = inner_d - boss_rise (chamber-facing top)
screw_cap     = boss_h - screw_hole_depth;        // SEALED PLA between the bore top and the chamber
boss_wall_min = (boss_od - screw_bore_d)/2;       // radial PLA wall around the bore
// MAX screw length from the washer face: through the foam + the bore.  The bore (screw_hole_depth)
// is measured from the floor UNDERSIDE, so it ALREADY spans the 2.5 mm floor -- do NOT add `wall`
// again.  Shorter is safer: the cap is blind, so a too-long screw drives toward it instead of clamping.
screw_len_est = float_thickness + screw_hole_depth;
// plan-view gap from a boss (center [px,pz], radius boss_od/2) to a component rectangle
function comp_gap(px, pz, cx, cz, sx, sz) =
  let (dx = max(abs(px-cx) - sx/2, 0), dz = max(abs(pz-cz) - sz/2, 0))
  sqrt(dx*dx + dz*dz) - boss_od/2;
screw_comp_gap = screw_mount
  ? min([ for (p = screw_positions) for (c = rc_parts)
          comp_gap(p[0], p[1], c[3][0], c[3][1], c[1][0], c[1][1]) ]) : 1e9;

// --- Task 1 derived: motor-mount block + fastener cavity margin ---
mm_block_aft_z = -H/2 - mm_block_depth;                    // stern block aft face
mm_bolt_end_z  = mm_block_aft_z + mm_bolt_depth;           // deepest bolt point (blind)
mm_cavity_margin = (-inner_h/2) - mm_bolt_end_z;           // solid aft of the cavity (>=3)
mm_bolt_envelope = sqrt(pow(mm_bolt_x,2) + pow(mm_bolt_y,2)); // corner-to-corner spread
mm_pad_top = ov_d + 1;                                     // block top Y (clears the lid overlap)
mm_pad_h   = D - mm_pad_top;                               // block spans down to the FLOOR (Y=D)
mm_pad_yc  = (mm_pad_top + D)/2;                           // block/foot/bolt center in Y
foot_h     = mm_pad_h;                                     // pylon foot height matches the block
// --- Task 3 derived: hull hold-down lug (external, beside each end block; both_ends mirrors to the bow) ---
hd_x         = mm_pad_w/2 + hd_inset;          // bolt X: outboard of the block side (mm_pad_w/2), inboard of the box edge (W/2)
hd_z         = -H/2 - mm_block_depth/2;        // bolt Z: centered on the STERN end-block depth (both_ends mirrors to bow)
hd_top_y     = D - hd_post_h;                  // lug top face Y (sky side; the hex nut pocket opens here, toward -Y)
hd_screw_len = float_thickness + hd_post_h;    // hold-down bolt length est: foam + lug (nut seats near the lug top)
hd_edge_wall = W/2 - (hd_x + hd_w/2);          // PLA from the lug OUTBOARD edge to the box side edge (>=0 -> within the footprint)
hd_block_weld= mm_pad_w/2 - (hd_x - hd_w/2);   // X overlap of the lug INTO the block side (>0 -> welds solidly to the block)
hd_nut_wall  = hd_w/2 - hd_nut_af/2;           // PLA wall from the nut-pocket flat out to the lug side (X)
// stern-block fastener bore (ROUND for insert/selftap; the modeled thread carries its own teardrop crest):
// insert_d for heat-set, thread minor+slop for modeled (as the floor screw_bore_d), pilot for selftap.
// wall = least PLA from the round bore edge to the block edges (X width, Y top/floor); ends vs cavity above.
mm_bolt_bore_d   = (mm_bolt_method=="insert") ? insert_d
                 : (mm_bolt_method=="thread") ? screw_size + 4*thread_slop
                 :                              mm_bolt_pilot;
mm_bolt_wall_min = min(mm_pad_w/2 - mm_bolt_x/2 - mm_bolt_bore_d/2,          // to the block width edge (X)
                       (D - (mm_pad_yc + mm_bolt_y/2)) - mm_bolt_bore_d/2,   // up to the floor edge (Y=D)
                       (mm_pad_yc - mm_bolt_y/2 - mm_pad_top) - mm_bolt_bore_d/2); // down to the block top edge
// PLA web between the M4 attach bore and the CENTRED register slot (the wall mm_bolt_wall_min omits).
// The bolts straddle the slot in Y, so the inner bore edge must clear the slot half-height; use the
// melt-EXPANDED insert OD (insert_od) for insert mode so a hot insert has PLA to reflow into, not the slot.
mm_bolt_slot_bore_r = (mm_bolt_method=="insert") ? insert_od/2 : mm_bolt_bore_d/2;
mm_bolt_slot_wall   = mm_bolt_y/2 - (reg_h+0.4)/2 - mm_bolt_slot_bore_r;
// The 4 plate bolts form an axis-aligned SQUARE on the pad (side = bp_pitch), which is the plate's
// outer bolt circle ROTATED 45deg to an "X" (mount the BasePlate turned 45deg).  bp_axis is the half
// side -- each bolt's reach along the pad AXES (Y,Z) -- so the pad only has to be 2*bp_axis+edge tall
// (shorter than a "+" pad on the same circle), which raises pad_y0 and lets the sloped mast climb
// higher.  The (rigid metal) plate overhangs the smaller pad, bolted at 4 points, free air at the tip.
bp_axis    = bp_pitch/2;                                   // half the square side: bolts at +/-bp_axis on each pad axis (Y,Z)
bp_bolt    = bp_pitch*sqrt(2);                             // across-axis / diagonal = bolt-circle dia (echo + central-bore talk)
pad_h      = 2*bp_axis + 2*bp_edge;                        // pad backs the 4 X bolts + edge (>=3 mm wall at the M3s)
pad_aft    = pylon_root_t + motor_pad_t;                   // pylon pad aft (motor) face, fore-aft
pad_bolt_wall_y = pad_h/2 - bp_axis - bp_screw_d/2;        // pad edge wall at the X bolts (Y)
pad_bolt_wall_z = pylon_width/2 - bp_axis - bp_screw_d/2;  // pad edge wall at the X bolts (Z/width)
base_aft   = pylon_root_t + pylon_gusset;                  // buttress fore-aft thickness at the foam BASE
foot_cbore_wall = pylon_width/2 - mm_bolt_x/2 - foot_cbore_d/2; // pylon edge wall at the foot-bolt counterbores
// -- Item 1: pad top extends ABOVE the top "+" screw so the fillet round lands clear of the plate --
pad_y0     = pylon_rise - pad_h/2;                         // pad bottom (merges into the buttress top)
pad_y1     = pylon_rise + pad_h/2 + pad_top_pad;           // pad top (extended: flat seat above the fillet)
pad_top_flat = pad_y1 - (pylon_rise + bp_axis) - pylon_fillet; // FLAT above the top X screws before the round
// -- Item 3: low foot bolt now clears the base-corner fillet (counterbore bottom above the round) --
foot_lowbolt_y   = foot_h/2 - mm_bolt_y/2;                 // local Y of the low foot bolt (up from the base)
foot_bolt_base_clear = foot_lowbolt_y - foot_cbore_d/2 - pylon_fillet; // its cbore bottom above the base round
// -- Item 2: forward slope extents (pylon-local: X=fore-aft +aft, Y=up mast; bears on the block top) --
fg_reach   = mm_block_depth - fwd_gusset_gap;              // forward reach = to the stern wall, a hair shy so the foot seats first
fg_y0      = foot_h + fwd_gusset_gap;                      // bearing foot (a hair above the block top)
fg_y1      = pad_y0 - fwd_gusset_top_gap;                  // apex tops out just below the motor pad -> FULL-HEIGHT taper
fg_rise    = fg_y1 - fg_y0;                                // how far up the mast the forward slope climbs (echo/report)
// overall stack height (waterline to prop top), for the hand-back report
stack_height = float_freeboard + box_outer_height + hub_above_box_top + prop_radius;

// --- Foam catamaran derived (enclosure model frame; foam top at Y=D) ---
skid_center   = beam_target/2;                  // each skid/enclosure centre off the centreline (X)
foam_top_y    = D;                              // foam top = enclosure floor
foam_bot_y    = D + deck_t + skid_t;            // foam underside (skid bottom)
foam_h        = deck_t + skid_t;                // total foam thickness
bow_tip_z     = max(deck_len, skid_len)/2;      // forward-most foam edge (foam-local Z)
bow_rake_setback = foam_h * tan(bow_rake_ang);  // how far the bow underside is cut back
// enclosure fore-aft extents on the deck (enclosures modelled at Z=0; deck shifted deck_center_z)
foredeck_len  = (deck_center_z + deck_len/2) - (H/2);              // clear deck ahead of the bow wall
aftdeck_len   = mm_block_aft_z - (deck_center_z - deck_len/2);     // stern block aft face -> deck transom
prop_disc_z   = -H/2 - prop_z_offset;                             // prop disc plane (enclosure frame Z)
prop_to_transom = prop_disc_z - (deck_center_z - deck_len/2);      // + = disc forward of the transom
skid_overhang = (skid_center + skid_w/2) - deck_w/2;              // + = skid sticks out past the deck edge
cut_to_skid   = (skid_center - skid_w/2) - deck_cut_w/2;          // + = clear gap between cutout and skid
foam_ok = deck_t + skid_t == float_thickness;

// =====================================================================
//  ECHO FIT-CHECK REPORT  (how correctness is verified -- house style)
// =====================================================================
echo(str("=== AIRBOAT ENCLOSURE  side=", side, " ==="));
echo(str("OUTER  W(width) x H(length) x D(height) = ", W, " x ", H, " x ", D, " mm"));
echo(str("INNER  ", inner_w, " x ", inner_h, " x ", inner_d,
         " mm   (floor ", inner_w, " x ", inner_h, ", height ", inner_d, ")"));
echo(str("  floor area = ", inner_w*inner_h, " mm^2"));
// true printed extents: X = full width incl. hinge/ears; length = box + end block(s) (both_ends adds the bow block)
body_len_ext = H + (mount_both_ends ? 2 : 1)*mm_block_depth;  // block->block (both_ends) or bow wall->stern block
echo(str("  body prints FLOOR down: extents ", round(body_x_ext), "(width) x ", body_len_ext,
         "(length incl. ", mount_both_ends ? "BOTH end blocks" : "stern block", ") x ~", D+ov_d,
         "(height) ; on a 250x210 bed ",
         (max(body_x_ext,body_len_ext)<=250 && min(body_x_ext,body_len_ext)<=210 && D+ov_d<=210)
           ? str("fits", body_len_ext>210 ? " (auto-ROTATE: length along the 250 axis)" : "")
           : "  << CHECK: exceeds 250x210"));
// honest nesting footprint: full X extents incl. inboard boss, outboard hinge/ears, grip
body_x_ext = W/2 - (Ax - kr);                        // inboard wall -> outboard hinge barrel (screw bosses are internal)
lid_x_ext  = (lid_w/2 + 1.5) - (Ax - kr);             // grip -> outboard barrel
nest_x     = body_x_ext + lid_x_ext + 5;              // side by side, 5 mm gap
echo(str("  bed nesting (measured extents): body ", round(body_x_ext),
         " + lid ", round(lid_x_ext), " + gap 5 = ", round(nest_x),
         " mm across X vs 245 budget ", (nest_x <= 245)?"OK":"  << CHECK: exceeds 245"));

echo("--- Task 1: motor mount + pylon --------------------------------");
echo(str("  prop_diameter = ", prop_diameter, " -> radius ", prop_radius));
echo(str("  hub above water = ", hub_height_above_water,
         " (= r ", prop_radius, " + freeboard ", float_freeboard,
         " + margin ", prop_clearance_margin, ")"));
echo(str("  hub above box top = ", hub_above_box_top,
         " ; pylon rise above floor = ", pylon_rise));
echo(str("  prop disc lowest point clears the float top by ", disc_low_above_float,
         " mm ", disc_low_above_float >= 0 ? "OK" : "  << WARNING: prop dips below the float"));
echo(str("  pad mounts BasePlate (", bp_size, " sq): 4x M3 in a SQUARE, side (adjacent-hole pitch) = ",
         bp_pitch, " mm (MEASURED bracket; bolts at +/-", round(10*bp_axis)/10, " on each pad axis) -- ",
         "= the plate's r", round(10*bp_bolt/2)/10, " circle turned 45deg to an X ; central boss clearance ", bp_bore+1.5));
echo(str("  M3 clearance ", bp_screw_d, " mm -> radial slop ", round(10*(bp_screw_d-3)/2)/10,
         " seats a bracket pitch of ", bp_pitch, " +/-", round(10*(bp_screw_d-3)/2*sqrt(2))/10,
         " mm (covers the 24-24.5 measured band ", (bp_pitch-(bp_screw_d-3)/2*sqrt(2) <= 24 && bp_pitch+(bp_screw_d-3)/2*sqrt(2) >= 24.5) ? "OK)" : " << CHECK)"));
echo(str("  pad face ", round(pad_y1-pad_y0), "(Y, incl. +", pad_top_pad, " top pad) x ", pylon_width,
         "(Z): the X bolts span only +/-", round(10*bp_axis)/10, " so the pad holds them + edge -- the ",
         bp_size, " plate OVERHANGS (rigid, free air at the mast tip) ",
         (pad_h/2 >= bp_axis + bp_edge) ? "OK -- shorter pad, slopes climb higher" : "  << WARNING: pad too small for the X bolts"));
echo(str("  pad X-bolt edge wall = ", round(10*min(pad_bolt_wall_y,pad_bolt_wall_z))/10,
         " mm (need >= 3) ", min(pad_bolt_wall_y,pad_bolt_wall_z) >= 3 ? "OK" : "  << WARNING: grow pad_h/pylon_width"));
echo(str("  (item 1) FLAT above the top X screws before the fillet = ", round(10*pad_top_flat)/10,
         " mm ", pad_top_flat >= 2 ? "OK -- top screws seat on flat" : "  << WARNING: raise pad_top_pad or drop pylon_fillet"));
if (motor_pad_t < 5) echo("  WARNING: motor pad < 5 mm");
if (pylon_root_t < 4) echo("  WARNING: pylon root wall < 4 mm");
echo(str("  stern block ", mm_pad_w, " x ", mm_pad_h, " x ", mm_block_depth,
         " aft ; M4 x4 depth ", mm_bolt_depth, " (reg tongue ", reg_depth, " deep x ", reg_h, " tall) ; bolt envelope ",
         round(mm_bolt_envelope), " mm ", mm_bolt_envelope >= 33 ? "OK (fwd gusset + deep tongue carry the moment; bolts clamp)" : "  << WARNING: bolt spread small"));
echo(str("  motor-mount bolt cavity margin = ", mm_cavity_margin, " mm (need >= 3) ",
         mm_cavity_margin >= 3 ? "OK" : "  << WARNING: fastener enters the sealed cavity"));
echo(str("  stern-block fastener method = ", mm_bolt_method, " ; bore ",
         round(10*mm_bolt_bore_d)/10, " x depth ", mm_bolt_depth,
         " ; PLA wall around bore = ", round(10*mm_bolt_wall_min)/10, " mm ",
         mm_bolt_wall_min >= 2 ? "OK" : "  << WARNING: thin wall around the block fastener"));
echo(str("  bore <-> register-slot PLA web = ", round(10*mm_bolt_slot_wall)/10, " mm ",
         mm_bolt_slot_wall >= 1.5 ? "OK -- insert has PLA to grip; won't reflow into the slot"
                                  : "  << WARNING: bore fouls the register slot -- widen mm_bolt_y or shrink reg_h"));
echo(str("  pylon: ONE extrude, ", pylon_width, " wide -> flat supportless; FULL-HEIGHT buttress ",
         base_aft, "->", pylon_root_t, " fore-aft (base->tip); prints bed ", round(pad_y1),
         "(Y, mast->pad tip) x ", round(base_aft + fg_reach), "(X, gusset tip->base) x ", pylon_width, " build"));
echo(str("  pylon foot-bolt counterbore edge wall = ", round(10*foot_cbore_wall)/10,
         " mm (need >= 3) ", foot_cbore_wall >= 3 ? "OK" : "  << WARNING: narrow mm_bolt_x or foot_cbore_d"));
echo(str("  (item 3) low foot-bolt counterbore clears the base fillet by ", round(10*foot_bolt_base_clear)/10,
         " mm ", foot_bolt_base_clear >= 1 ? "OK -- foot bolts on flat" : "  << WARNING: raise the bolt group / shrink pylon_fillet"));
if (fwd_gusset)
  echo(str("  (item 2) FORWARD SLOPE: bears on the block top, reaches ", fg_reach,
           " mm fwd to the stern wall, climbs ", round(fg_rise), " mm up the mast (FULL-HEIGHT taper; apex Y=",
           round(fg_y1), " vs pad Y0=", round(pad_y0), ") ",
           fg_y1 <= pad_y0 + eps ? "OK -- tops out just below the motor pad" : "<< WARNING: slope overruns the pad"));
else echo("  (item 2) forward slope OFF");
echo(str("  OVERALL STACK (waterline -> prop top) = ", round(stack_height), " mm"));
// prop is a FREE constant: warn when a big prop makes the mast tall enough that the
// stern joint (fixed block/gussets/2.5 mm wall), not the mast, becomes the weak link.
if (pylon_rise > 160)
  echo(str("  NOTE: tall mast (pylon_rise ", round(pylon_rise), " mm -> large prop): the stern block + ",
           block_fil_r, " mm gussets + 2.5 mm wall become the structural weak link -- grow block_fil_r / ",
           "mm_block_depth (they do NOT scale with prop_diameter) or reduce prop_diameter."));

echo("--- through-board screw mount (watertight blind bosses) --------");
if (screw_mount) {
  echo(str("  ", len(screw_positions), " x M", screw_size, " bosses  OD ", boss_od,
           "  method=", screw_method, "  bore ", round(10*screw_bore_d)/10, " x ",
           screw_hole_depth, " deep from the floor underside"));
  echo(str("  SEALED cap above each bore = ", round(10*screw_cap)/10,
           " mm (need >= ", boss_cap_min, ") ",
           screw_cap >= boss_cap_min ? "OK -- NO leak path into the chamber"
                                     : "  << WARNING: bore breaches toward the sealed cavity"));
  echo(str("  boss wall around the bore = ", round(10*boss_wall_min)/10, " mm ",
           boss_wall_min >= 2 ? "OK" : "  << WARNING: thin boss wall around the bore"));
  if (screw_method=="insert")
    echo(str("  CNC-Kitchen check: boss OD ", boss_od, " vs 2x insert OD ", insert_od, " = ", 2*insert_od,
             " ", boss_od >= 2*insert_od ? "OK -- a hot insert won't split the boss"
                                         : "  << WARNING: bump boss_od or use a <=6 mm insert"));
  echo(str("  boss top at Y=", boss_top_y, " (rises ", boss_rise, " into the ", inner_d,
           " chamber) ; positions [X,Z] = ", screw_positions));
  echo(str("  min boss-to-component plan gap = ", round(10*screw_comp_gap)/10, " mm ",
           screw_comp_gap >= 2 ? "OK (bosses sit in the free gaps)"
                               : "  << WARNING: a boss fouls an RC component -- move it"));
  echo(str("  screw length <= ", screw_len_est, " mm (foam ", float_thickness,
           " + bore ", screw_hole_depth, "; the bore already includes the ", wall,
           " mm floor) -- shorter is safer (blind cap) ; fender washer / backing plate under the soft foam"));
  // stability caveat: the mast (stern block) overhangs AFT of the aftmost hold-down.
  echo(str("  MOUNT NOTE: the mast/stern block (~Z ", round(mm_block_aft_z),
           ") sits AFT of the aftmost hold-down (Z +/-", max([for(p=screw_positions) abs(p[1])]),
           "), so thrust PITCHES the box -> the aft bolts take TENSION through the soft foam (creep -> loosen",
           " -> rattle).  Backing plate BOTH faces + consider an aft hold-down: this joint, not the mast,",
           " sets 'stable' in the field."));
} else echo("  screw mount OFF (interior floor bosses) -- see the corner-lug hold-down below");

echo("--- Task 3: hull hold-down (external corner lugs beside the end blocks) --");
if (corner_mount) {
  n_hd = (mount_both_ends ? 4 : 2);
  echo(str("  ", n_hd, " x M4 lug", n_hd>1?"s":"", " at (X=+/-", hd_x, ", Z=+/-", round(-hd_z),
           ")", mount_both_ends ? " (both ends)" : " (stern only)",
           " ; ", hd_w, "(X) x ", mm_block_depth, "(Z) x ", hd_post_h, "(Y above foam)"));
  echo(str("  lug within the box footprint: outboard PLA to the box edge = ", round(10*hd_edge_wall)/10,
           " mm ", hd_edge_wall >= 0 ? "OK -- adds NO footprint (fills the empty wedge beside the block)"
                                     : "  << WARNING: lug overhangs the box edge -- reduce hd_inset/hd_w"));
  echo(str("  lug welds to the block side: X overlap = ", round(10*hd_block_weld)/10, " mm ",
           hd_block_weld >= 1 ? "OK" : "  << WARNING: lug detached from the block -- raise hd_w or lower hd_inset"));
  echo(str("  nut-pocket wall to the lug side = ", round(10*hd_nut_wall)/10, " mm ",
           hd_nut_wall >= 2 ? "OK (hex captured)" : "  << WARNING: thin wall around the nut pocket"));
  echo(str("  M4 hold-down bolt ~", hd_screw_len, " mm (foam ", float_thickness, " + lug ", hd_post_h,
           "): UP from under the foam into the top-captured nut ; fender washer / backing plate below the soft foam"));
  echo(str("  wide base: lugs at Z +/-", round(-hd_z), " straddle the mast/block (Z ", round(mm_block_aft_z),
           ") far better than the old +/-79 floor bosses -> less thrust-pitch, less bolt tension. ",
           "ALL external to the sealed wall: nothing intrudes into the chamber (probe-checked)."));
} else echo("  corner mount OFF");
// consolidated heat-set BOM/tooling note (both PLA-threaded families default to inserts)
n_floor_ins = (screw_mount && screw_method=="insert") ? len(screw_positions) : 0;
n_block_ins = (mm_bolt_method=="insert") ? (mount_both_ends ? 8 : 4) : 0;
if (n_floor_ins + n_block_ins > 0)
  echo(str("  HEAT-SET BOM: ", n_floor_ins + n_block_ins, "x M", screw_size, " brass inserts (",
           n_floor_ins, " floor from the bed face + ", n_block_ins, " end-block", n_block_ins==1?"":"s",
           " from the aft face", mount_both_ends?" -- 4 stern + 4 bow":"", ")",
           " + a soldering-iron insert tip ; pylon-attach M4 socket-head ~30 mm (foot + ~8 mm insert, trim to fit)"));
if (corner_mount)
  echo(str("  HOLD-DOWN BOM: ", mount_both_ends?4:2, "x M4 bolt ~", hd_screw_len,
           " mm + M4 nut + fender washer (per lug) ; bolt UP from under the foam into the top nut pocket"));

echo("--- beam / stern-prop collision across the hulls ---------------");
if (beam_target <= prop_diameter)
  echo(str("  WARNING: beam_target ", beam_target, " <= prop_diameter ", prop_diameter,
           " -- the two stern props collide.  Widen beam_target."));
else
  echo(str("  beam_target = ", beam_target, " ; stern-prop clearance across the beam = ",
           beam_target - prop_diameter, " mm OK"));

echo("--- foam catamaran body (XPS: deck + 2 skids) -----------------");
if (show_foam) {
  echo(str("  deck ", deck_w, "(beam) x ", deck_len, "(length) x ", deck_t,
           " ; central water cutout ", deck_cut_w, " x ", deck_cut_len, " (r", deck_cut_r, ")"));
  echo(str("  skids 2x ", skid_w, " x ", skid_len, " x ", skid_t, " at X=+/-", skid_center,
           " (centred under the enclosures) ; foam thickness ", foam_h,
           foam_ok ? str(" == float_thickness ", float_thickness, " OK")
                   : str("  << CHECK: != float_thickness ", float_thickness)));
  echo(str("  skid vs deck edge: ", skid_overhang <= 0
           ? str("skid inset ", round(-skid_overhang), " mm within the deck OK")
           : str("skid OVERHANGS the deck by ", round(skid_overhang),
                 " mm  << widen deck_w to ", round(2*(skid_center+skid_w/2)),
                 " (skids flush) or use smaller props/beam")));
  echo(str("  cutout-to-skid gap = ", round(cut_to_skid), " mm ",
           cut_to_skid >= 0 ? "OK (water channel clear of the skids)"
                            : "  << the cutout overlaps the skids -- narrow deck_cut_w or spread the skids"));
  echo(str("  foredeck ahead of the bow wall = ", round(foredeck_len),
           " mm ; aft deck (transom aft of the stern block) = ", round(aftdeck_len), " mm"));
  echo(str("  prop disc ", prop_to_transom >= 0
           ? str(round(prop_to_transom), " mm FORWARD of the transom (sweeps over the aft deck)")
           : str(round(-prop_to_transom), " mm AFT of the transom (overhangs the stern)")));
  echo(str("  raked bow: ", bow_rake_ang, " deg from vertical -> underside cut back ",
           round(bow_rake_setback), " mm at the keel"));
} else echo("  foam body OFF");

echo("--- Task 3: cable glands (inboard +X wall) -- role-based -------");
echo(str("  rc_side=", rc_side, " -> port hull=", role_of_side("port"),
         ", starboard hull=", role_of_side("starboard"), " (the assembly draws both; each `side` render gets its own set)"));
echo(str("  this render: side=", side, " -> box_role=", box_role, " -> ", len(gland_zs), " glands, ", port_gland_d,
         " mm holes at Z=", gland_zs, " (Y=", port_y, ") : ",
         box_role=="stim" ? "signal-IN + electrode-OUT, both forward"
                          : "2 aft motor glands (same-side + opposite-side) + 1 forward control"));
echo("  plain through-holes (the gland's own body/nut is the shoulder/seal, no boss)");
// smallest Z gap between installed gland FOOTPRINTS (port_ftp, NOT the 12 hole) on the inboard wall
min_port_gap = min([ for (i=[0:len(gland_zs)-1], j=[i+1:len(gland_zs)-1])
                     abs(gland_zs[i]-gland_zs[j]) - port_ftp ]);
echo(str("  min inboard gland-footprint (", port_ftp, " mm) Z gap = ", round(10*min_port_gap)/10,
         " mm ", min_port_gap >= 3 ? "OK" : "  << WARNING: glands crowd in Z"));
// glands must land on the FLAT wall (clear of the rounded vertical corners)
gland_z_edge = max([for (z=gland_zs) abs(z)]) + port_ftp/2;
echo(str("  outermost gland footprint edge at |Z|=", round(gland_z_edge), " vs flat-wall limit ",
         round(H/2 - corner_r), " ", gland_z_edge <= H/2 - corner_r ? "OK -- on the flat wall"
                                                                     : "  << WARNING: a gland rides into the corner"));

echo("--- lid hinge (outboard -X edge, axis along the length) --------");
echo(str("  pin axis (x,y)=(", Ax, ", ", Ay, ") ; barrel d=", knuckle_d,
         " ; stack z=+/-", hinge_span/2, " over ", hinge_segs, " knuckles"));
echo(str("  housing leaf reach = ", round(1000*leaf_reach)/1000, " mm ; underside overhang ",
         hinge_arm_ang, " deg ", hinge_arm_ang <= 45 ? "OK" : " WARNING"));
if (hinge_offset < knuckle_d/2) echo("  ERROR: hinge_offset must be >= knuckle_d/2");

echo("--- lid overlap + snap locks ----------------------------------");
echo(str("  skirt ", skirt_t, " x ", ov_d, " deep over a ", step, " band ; ",
         len(lock_zs) + (n_locks>=2?1:0) + (n_locks>=3?1:0), " locks"));
echo(str("  hinge-side swing gap = ", round(1000*swing_gap)/1000, " mm ",
         swing_gap >= 0.1 ? "OK" : "  << WARNING: skirt scrapes on the swing"));
// snap strength vs watertightness: the dent cuts INTO the inboard chamber wall.  Deeper = snappier
// but thinner behind the dent -> guard the sealed-wall bar (0.8 mm PLA to the void).
dent_wall = wall - step - (bump_h + 0.1);   // PLA left behind the deepest (dent) cut, to the sealed chamber
echo(str("  bump ", bump_h, " mm proud into a ", bump_h+0.1, " mm dent -> wall behind the dents = ",
         round(100*dent_wall)/100, " mm ",
         dent_wall >= 0.8 ? "OK (>=0.8 watertight bar)"
                          : "  << WARNING: dent thins the sealed wall below 0.8 mm -- reduce bump_h"));
// tidy rim: adjacent INBOARD dents must not overlap (16.8 mm dent length) or they merge into a ragged blob.
lock_pitch = min([for (i=[1:len(lock_zs)-1]) abs(lock_zs[i]-lock_zs[i-1])]);
lock_gap   = lock_pitch - bump_l*1.05;
echo(str("  inboard dents: min pitch ", lock_pitch, " mm, clean gap ", round(10*lock_gap)/10, " mm ",
         lock_gap >= 3 ? "OK (discrete, tidy)"
                       : "  << WARNING: adjacent dents overlap/crowd -> looks unclean, spread lock_zs"));

echo("--- lid on/off switch (chunky flip switch; motors exit via side glands) -");
if (lid_switch) {
  kx = switch_ftp[0] + 2*switch_clear;   // rib keep-out extents (switch body footprint + margin)
  kz = switch_ftp[1] + 2*switch_clear;
  s_edge = min(H/2 - abs(lid_switch_z) - kz/2, W/2 - abs(lid_switch_x) - kx/2) - skirt_t;  // keep-out -> lid edge/skirt
  s_lock = (n_locks>=3) ? (H/2 - step) - (abs(lid_switch_z) + kz/2) - bump_l/2 : 1e9;       // keep-out -> stern lock
  echo(str("  ", lid_switch_d, " bore + ", switch_ftp[0], "x", switch_ftp[1], " rib-free keep-out at (X=",
           lid_switch_x, ", Z=", lid_switch_z, ")"));
  echo(str("  keep-out clears the lid edge/skirt by ", round(10*s_edge)/10, " mm ",
           s_edge >= 2 ? "OK" : "  << WARNING: switch footprint too close to the skirt"));
  echo(str("  keep-out clears the stern-end snap lock by ", round(10*s_lock)/10, " mm ",
           s_lock >= 1 ? "OK" : "  << WARNING: switch footprint fouls the stern lock"));
} else echo("  lid switch OFF");

echo("--- XT60 charge port -------------------------------------------");
if (xt60 && xt60_face != "none") {
  echo(str("  XT60 on ", xt60_face, " at ", xt60_face=="bow"||xt60_face=="stern"?"X=":"Z=",
           xt60_pos, " ; flange ", xt60_flange_len, " x ", xt60_flange_h,
           " ; body reaches ", xt60_body_depth, " mm in"));
  if (xt60_face=="bow")
    echo(str("  bow XT60 body reaches to Z=", inner_h/2 - xt60_body_depth,
             " -- keep components aft of that (LiPo ghost aft face ~Z67.5)"));
}
echo("---------------------------------------------------------------");

// =====================================================================
//  HELPERS  (ported)
// =====================================================================
module rprism(w, h, d, r) {
  hull() for (sx=[-1,1], sz=[-1,1]) translate([sx*(w/2-r), 0, sz*(h/2-r)])
    rotate([-90,0,0]) cylinder(h=d, r=r);
}

// Task 5 tapped-hole cutter -- drop-in for `cylinder(h=l, d=..)` (axis +Z, base
// at the origin).  use_threads -> a real BOSL2 internal metric thread; else a
// thread-FORMING pilot (bolt/set-screw cuts its own thread in the PLA).  Set
// td=true for holes whose axis prints HORIZONTAL (teardrop crest self-supports).
module tapped_hole(major, pitch, l, pilot, td=false, spin=0) {
  if (use_threads)
    translate([0,0,l/2])
      threaded_rod(d=major, pitch=pitch, l=l, internal=true, teardrop=td,
                   blunt_start=true, bevel1=true, spin=spin, $slop=thread_slop);
  else
    cylinder(h=l, d=pilot);   // thread-forming pilot: bolt/screw cuts its own thread
}

// =====================================================================
//  SHARED HINGE PRIMITIVES  (both leaves use these; the housing/door
//  leaf profiles + modules live with their part -- body.scad / lid.scad)
// =====================================================================
module hinge_segments(from)
  for (i = [from : 2 : hinge_segs-1])
    translate([0, 0, seg_z(i)]) linear_extrude(seg_h) children();

module pin_bore_cut(apex)
  translate([Ax, Ay, -hinge_span/2 - 1]) linear_extrude(hinge_span + 2)
    rotate(apex > 0 ? 0 : 180) teardrop2d(d=pin_bore, ang=45);

// =====================================================================
//  SHARED SNAP-LOCK PRIMITIVE  (lock_dents (body) + door_skirt (lid) both use it)
// =====================================================================
module lock_wedge(o, dent=false) {
  s = dent ? 1.05 : 1;
  prismoid(size1=[bump_l*s, bump_w*s], size2=[bump_l*0.75*s, 0],
           h=bump_h + (dent ? 0.1 : 0), orient=o);
}

// =====================================================================
//  ORIENTATION HELPERS  (every part's standalone render + the assembly use them)
// =====================================================================
module apply_side() {
  if (side == "starboard") mirror([1,0,0]) children();
  else children();
}

// same mirror, but for an EXPLICIT hull (not the global `side`) -- the assembly draws both hulls
module apply_side_of(s) {
  if (s == "starboard") mirror([1,0,0]) children();
  else children();
}

module oriented(p) {
  if (!print_ready) children();
  else if (p=="body") translate([0,0,D]) rotate([-90,0,0]) children();   // floor down
  else if (p=="lid")  translate([0,0,lid_t]) rotate([90,0,0]) children(); // outer face down
  else if (p=="pylon") children();  // modeled flat already (Z=0 face on the bed)
  else children();
}

