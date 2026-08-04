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
//  PARTS (part=):  assembly(preview) | body | lid | pylon
//     body  : FLOOR on the bed
//     lid   : outer face down
//     pylon : laid flat (layers along its length -- bending load along layers)
// =====================================================================

include <../BOSL2/std.scad>
include <../BOSL2/threading.scad>   // metric tapped holes (Task 5); std.scad omits it

/* [What to render] */
part = "assembly";   // [assembly, body, lid, pylon]
side = "port";       // [port, starboard]
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
inner_h  = 165;    // code Z = box LENGTH  (fore-aft)     -- floor 90 x 165
inner_d  = 35;     // code Y = box HEIGHT  (floor->lid)   -- LiPo 26.5 + routing
wall     = 2.5;
corner_r = 5;

// readable aliases (new code + echoes use these; the ported modules keep the
// original names so they need no edits)
box_width  = inner_w;    // athwartship
box_len    = inner_h;    // fore-aft
box_height = inner_d;    // floor -> lid

/* [Lid] */
lid_t     = 3;     // top-lid outline matches the body exactly (inspo lid == base)

// Item 3 -- a gland hole through the LID for the LOCAL motor's 3 phase leads
// (the motor sits on this hull's stern pylon; its leads drop into the box
// through this sealed hole and are zip-tied to the pylon).  Placed over the
// stern end, clear of the hinge (outboard), the perimeter skirt, and the snap
// locks.  Replaces the pylon cable-groove as the routing solution (item 3).
lid_gland   = true;
lid_gland_d = 12;     // gland panel-mount hole -- MEASURED (matches the port glands)
lid_gland_x = 0;      // athwartship (X): 0 = centreline
lid_gland_z = -60;    // fore-aft (Z): near the stern/pylon end, clear of locks & skirt

/* [Side & boat] -- one body, two hulls */
beam_target = 240;  // hull centreline-to-centreline spacing (mm).  MUST exceed
                    // prop_diameter or the two stern props collide (echo-checked).

/* [Knuckle hinge] -- hand-rolled, OUTBOARD long edge (-X), axis along the
   length (code Z), 1.75 mm filament pin.  Ported verbatim from the stim
   enclosure; only the span/segment count grow for the longer edge. */
hinge_segs   = 7;      // total knuckles (odd -> housing gets the two ends)
hinge_span   = 120;    // Z (length) span of the knuckle stack, centered
hinge_gap    = 0.3;    // Z clearance between adjacent knuckles (rotation)
knuckle_d    = 6;      // hinge barrel outer diameter
hinge_offset = 7;      // pin axis standoff from the outboard wall face (>=knuckle_d/2)
hinge_fillet = 2;      // housing leaf-to-wall fillet radius (exact tangent arc)
hinge_arm_ang = 35;    // housing leaf underside overhang from vertical (<=~45 for PLA)
pin_d        = 1.75;   // filament pin nominal
pin_clr      = 0.3;    // added to pin bore

/* [Lid overlap + snap locks] -- the inspo closure, ported verbatim: lid
   skirt over a stepped body band, bump-in-dent interlocks, full perimeter. */
ov_d          = 3.0;   // overlap depth behind the lid plane
skirt_t       = 1.1;   // lid skirt thickness
lid_clearance = 0.1;   // per-side skirt-to-band clearance (inspo)
lid_clearance_left = 0.25;  // hinge-side (outboard) skirt clearance, looser for the swing
lock_zs       = [55, 0, -55];  // Z centers of the INBOARD-edge locks (long free edge)
n_locks       = 3;     // 1 = inboard edge (lock_zs), 2 = + bow end, 3 = + stern end
bump_l        = 16;    // lock bump length along the wall
bump_w        = 1.0;   // bump profile width
bump_h        = 0.25;  // bump proudness (dent = 5% wider, 0.1 deeper)
grip          = true;  // thumb-grip wedge on the lid's inboard rim

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
screw_mount     = true;
screw_method    = "insert";  // [insert(M4 heat-set brass), thread(BOSL2 modeled), selftap(pilot in PLA)]
screw_size      = 4;         // M4 nominal (tension + shear hold-down; assembled/disassembled in the field)
// 4 bosses as a symmetric rectangle inset from the corners, tucked in the gaps
// between the RC components (see rc_parts) and merging into the bow/stern end
// walls for stiffness.  [X athwartship, Z fore-aft], box model frame.
screw_positions = [[-27, 79], [27, 79], [-27, -79], [27, -79]];
boss_od         = 12;        // boss outer diameter (>= 2x the insert OD, CNC-Kitchen rule -> ~3.2 mm wall,
                             // so a hot brass insert does not split the boss)
boss_rise       = 12;        // how far the boss rises off the floor INTO the chamber
boss_cap_min    = 3;         // min sealed PLA cap above the bore top (watertight bar; >=2.5)
// -- (insert) M4 brass heat-set: plain bore, insert melts in from the bed face --
insert_d        = 5.6;       // heat-set hole for M4 brass (MEASURE your inserts; ~5.6-5.7)
insert_depth    = 9;         // bore depth up from the floor underside (insert ~8 + melt lead)
// -- (thread / selftap) fallbacks, mirroring the use_threads pattern --
screw_pitch     = 0.7;       // M4 coarse (BOSL2 modeled internal thread)
thread_len      = 8;         // modeled-thread engagement depth up from the underside
selftap_d       = 3.4;       // thread-forming pilot for M4 in PLA (~0.85 x major)
selftap_depth   = 9;         // pilot depth up from the underside

/* [XT60 charge port] -- KEPT (each hull has a cell to charge).  On the BOW end
   wall (+Z): the outboard wall is fully occupied by the lid hinge (the 35 mm
   flange cannot clear the +/-60 knuckle stack), and the inboard wall carries
   the cable ports -- the bow end is the only clear face.
   Measured off the real part (hole 19x11.5, screw 2.4->2.8, sep 25, flange 35x16). */
xt60          = true;
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
//  TASK 5 -- METRIC THREADS (BOSL2)
//  Tapped holes so bolts/set-screws thread straight into the PLA.  Two families
//  use the tapped_hole() helper:
//    (a) the 4 stern-block pylon-attach holes -> M4  (see mm_bolt_* below)
//    (b) the through-board screw-mount bosses  -> M4  (ONLY when screw_method
//        ="thread"; the default "insert" and the "selftap" fallback bore plain)
//  use_threads=true models real BOSL2 internal threads.  If they print poorly
//  at this scale on the MK3S, set use_threads=false to fall back to the
//  thread-FORMING pilot holes (a bolt cuts its own thread in the PLA).  The
//  stern-block holes print with their axis HORIZONTAL, so they use BOSL2's
//  teardrop thread crest (self-supporting); the screw-mount bores print with a
//  VERTICAL axis (self-support is automatic).  The pylon-foot holes and cable
//  ports stay plain (bolt+nut / gland).
// =====================================================================
use_threads = true;
thread_slop = 0.1;    // BOSL2 internal-thread clearance ($slop): adds ~4*slop to the bore

// =====================================================================
//  TASK 1 -- MOTOR MOUNT + PYLON (highest priority)
// =====================================================================
/* [Prop & clearance] -- the ONE knob the user asked for: set prop_diameter
   and the required pylon height falls out.  Default 8x4.5 (203 mm): shorter,
   stiffer, ~450 g static thrust/motor.  1045 (254 mm) is a one-line change. */
prop_diameter        = 203;   // 8x4.5 = 203, 1045 = 254
float_thickness      = 60;    // styrofoam float thickness
float_freeboard      = 42;    // float top above the waterline at ~2 kg all-up
prop_clearance_margin= 20;    // disc lowest point above the float top
prop_z_offset        = 30;    // how far AFT of the stern wall the prop disc sweeps

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
bp_bolt        = 32;    // outer "+" hole spacing across each axis (holes at +/-16) -- MEASURED
bp_bore        = 10;    // BasePlate central bore -- pad clears the motor boss poking through
bp_screw_d     = 3.4;   // M3 clearance through the pad (flat-head from the plate, nut behind)
bp_edge        = 5;     // pad material beyond the bolt centres (keeps >=3 mm wall at the M3s)
motor_pad_t    = 5;     // pad thickness aft of the mast (>=5)
motor_body_d   = 28;    // motor can diameter (MEASURED off Motor.stl; pad + ghost sizing)

/* [Motor mount + pylon] -- SEPARATE printed pylon bolts to an aft-protruding
   BLOCK on the stern wall.  Every fastener stays inside that block, AFT of
   the wall -- none enters the sealed cavity (echo-checked).  A register
   socket takes the shear/moment so the M4s are not in pure shear.  The pylon
   prints laid FLAT (layers along its length carry the bending load). */
mm_block_depth = 14;    // stern block aft protrusion (bolt thread lives here)
mm_pad_w       = 50;    // block width  (X)  -- extends DOWN to the floor (load spread, no overhang)
mm_bolt_x      = 28;    // M4 spread across the width (Z): pulled in so the foot bolt COUNTERBORES
                        // (Task 1 redesign) clear the 42 mm pylon edge by >=3 mm
mm_bolt_y      = 26;    // M4 spread across the height
mm_bolt_depth  = 10;    // blind M4 thread depth into the block (< block_depth-2)
mm_bolt_pilot  = 3.4;   // BLIND-hole pilot in the block: thread-forming for M4 in PLA
                        // (set ~5.6 instead if using M4 heat-set inserts)
reg_depth      = 6;     // register tongue/slot depth (fore-aft) -- takes the shear/moment
reg_h          = 14;    // register tongue/slot height
// -- Pylon: a SEPARATE flat-extruded part.  Patrick's v0.2 redesign makes the
// reinforcement a FULL-HEIGHT triangular buttress (thick fore-aft at the foam
// BASE, tapering to the mast tip -- the moment peaks at the base, so that is
// where the section must be deep) with FILLETED transitions, and trims the
// width to the motor-bolt floor.  Still ONE linear_extrude => supportless, with
// the layers running along the mast (the bending load stays within the layers).
pylon_width    = 42;    // (was 44) trimmed to the motor "+" pattern (+/-16) + >=3 mm walls
pylon_root_t   = 8;     // mast fore-aft thickness at the TIP (>=4)
pylon_gusset   = 16;    // extra fore-aft thickness added at the BASE (base_aft = root + gusset)
pylon_bolt_d   = 4.4;   // M4 CLEARANCE through the foot (the block holes use mm_bolt_pilot/threads)
pylon_fillet   = 4;     // smooth-transition fillet radius at the mast/pad/base junctions
foot_cbore_d   = 7.5;   // M4 socket-head counterbore in the foot aft face (recesses the head)
foot_cbore_h   = 5;     // counterbore depth

// =====================================================================
//  TASK 3 -- CABLE PORTS (inboard +X wall) -- PLAIN through-holes.
//  The cable GLAND supplies its own shoulder/seal (threaded body seats in the
//  hole, nut inside), so there is NO printed boss (Patrick, item 4).  port_*_d
//  is the gland's PANEL-MOUNT hole; port_ftp is the installed gland's OUTER
//  hex/dome footprint on the wall (this, NOT the hole, drives feature SPACING).
//  Both MEASURED by Patrick (2026-08-04): hole = 12, installed footprint ~= 19.
// =====================================================================
port_stern_d   = 12;    // stern port gland hole: 3 motor phase leads (RC box -> far motor) -- MEASURED
port_bow_d     = 12;    // bow   port gland hole: opto->Teensy signal -- MEASURED
port_ftp       = 19;    // installed gland hex/dome OD on the wall (MEASURED) -- the spacing check uses THIS
port_stern_z   = -35;   // stern port position along the length
port_bow_z     = 35;    // bow port position along the length
port_y         = 24;    // Y of the port centers (near the floor)

// Item 6 -- a THIRD inboard port for the stimulator's own wires, on the STIM
// hull ONLY.  stim_port is INDEPENDENT of side (set it true on whichever hull
// you print as the stim box), so either physical hull can be the stim hull.
stim_port      = false; // set true when printing the stim hull
port_stim_d    = 12;    // stim port gland hole (stimulator electrode/output leads) -- MEASURED
port_stim_z    = 0;     // amidships: clear of the two ports at +/-35

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
screw_len_est = float_thickness + wall + screw_hole_depth;  // through foam + floor + engagement
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
pad_h      = bp_bolt + 2*bp_edge;                          // pad backs the BasePlate: >=3 mm wall at the M3 "+" holes
pad_aft    = pylon_root_t + motor_pad_t;                   // pylon pad aft (motor) face, fore-aft
pad_bolt_wall_y = pad_h/2 - bp_bolt/2 - bp_screw_d/2;      // pad edge wall at the outer "+" bolts (Y)
pad_bolt_wall_z = pylon_width/2 - bp_bolt/2 - bp_screw_d/2;// pad edge wall at the outer "+" bolts (Z/width)
base_aft   = pylon_root_t + pylon_gusset;                  // buttress fore-aft thickness at the foam BASE
foot_cbore_wall = pylon_width/2 - mm_bolt_x/2 - foot_cbore_d/2; // pylon edge wall at the foot-bolt counterbores
// overall stack height (waterline to prop top), for the hand-back report
stack_height = float_freeboard + box_outer_height + hub_above_box_top + prop_radius;

// =====================================================================
//  ECHO FIT-CHECK REPORT  (how correctness is verified -- house style)
// =====================================================================
echo(str("=== AIRBOAT ENCLOSURE  side=", side, "  part=", part, " ==="));
echo(str("OUTER  W(width) x H(length) x D(height) = ", W, " x ", H, " x ", D, " mm"));
echo(str("INNER  ", inner_w, " x ", inner_h, " x ", inner_d,
         " mm   (floor ", inner_w, " x ", inner_h, ", height ", inner_d, ")"));
echo(str("  floor area = ", inner_w*inner_h, " mm^2"));
// true printed extents: X = full width incl. bosses/hinge/ears; length = box + stern block
body_len_ext = H + mm_block_depth;   // bow wall -> stern block aft face
echo(str("  body prints FLOOR down: bed ", round(body_x_ext), "(X) x ", body_len_ext,
         "(Y=length incl. stern block) x ~", D+ov_d, "(Z) ; fits 250x210x210 ",
         (body_x_ext<=250 && body_len_ext<=210 && D+ov_d<=210)?"OK":"  << CHECK"));
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
echo(str("  pad mounts BasePlate (", bp_size, " sq): 4x M3 at the OUTER \"+\" (",
         bp_bolt, " across each axis, holes +/-", bp_bolt/2,
         ") ; central boss clearance ", bp_bore+1.5));
echo(str("  pad face ", pad_h, "(Y) x ", pylon_width, "(Z) >= plate ", bp_size,
         " ", (pad_h>=bp_size && pylon_width>=bp_size)?"OK":"  << WARNING: pad smaller than plate"));
echo(str("  pad \"+\" bolt edge wall = ", round(10*min(pad_bolt_wall_y,pad_bolt_wall_z))/10,
         " mm (need >= 3) ", min(pad_bolt_wall_y,pad_bolt_wall_z) >= 3 ? "OK" : "  << WARNING: grow pad_h/pylon_width"));
if (motor_pad_t < 5) echo("  WARNING: motor pad < 5 mm");
if (pylon_root_t < 4) echo("  WARNING: pylon root wall < 4 mm");
echo(str("  stern block ", mm_pad_w, " x ", mm_pad_h, " x ", mm_block_depth,
         " aft ; M4 x4 depth ", mm_bolt_depth, " ; bolt envelope ",
         round(mm_bolt_envelope), " mm ", mm_bolt_envelope >= 36 ? "OK (buttress + tongue carry the moment; bolts clamp)" : "  << WARNING: bolt spread small"));
echo(str("  motor-mount bolt cavity margin = ", mm_cavity_margin, " mm (need >= 3) ",
         mm_cavity_margin >= 3 ? "OK" : "  << WARNING: fastener enters the sealed cavity"));
echo(str("  pylon: ONE extrude, ", pylon_width, " wide -> flat supportless; FULL-HEIGHT buttress ",
         base_aft, "->", pylon_root_t, " fore-aft (base->tip); prints ~", round(pylon_rise),
         " long x ", pad_h, " x ", pylon_width, " mm"));
echo(str("  pylon foot-bolt counterbore edge wall = ", round(10*foot_cbore_wall)/10,
         " mm (need >= 3) ", foot_cbore_wall >= 3 ? "OK" : "  << WARNING: narrow mm_bolt_x or foot_cbore_d"));
echo(str("  OVERALL STACK (waterline -> prop top) = ", round(stack_height), " mm"));

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
  echo(str("  boss top at Y=", boss_top_y, " (rises ", boss_rise, " into the ", inner_d,
           " chamber) ; positions [X,Z] = ", screw_positions));
  echo(str("  min boss-to-component plan gap = ", round(10*screw_comp_gap)/10, " mm ",
           screw_comp_gap >= 2 ? "OK (bosses sit in the free gaps)"
                               : "  << WARNING: a boss fouls an RC component -- move it"));
  echo(str("  screw length ~", screw_len_est, " mm (foam ", float_thickness,
           " + floor ", wall, " + engage ", screw_hole_depth,
           ") ; use a fender washer / backing plate under the soft foam"));
} else echo("  screw mount OFF");

echo("--- beam / stern-prop collision across the hulls ---------------");
if (beam_target <= prop_diameter)
  echo(str("  WARNING: beam_target ", beam_target, " <= prop_diameter ", prop_diameter,
           " -- the two stern props collide.  Widen beam_target."));
else
  echo(str("  beam_target = ", beam_target, " ; stern-prop clearance across the beam = ",
           beam_target - prop_diameter, " mm OK"));

echo("--- Task 3: cable ports (inboard +X wall) -- PLAIN gland holes -");
echo(str("  stern port ", port_stern_d, " mm at Z=", port_stern_z,
         " (3 motor phases) ; bow port ", port_bow_d, " mm at Z=", port_bow_z, " (signal)",
         stim_port ? str(" ; STIM port ", port_stim_d, " mm at Z=", port_stim_z) : " ; stim port OFF"));
echo(str("  ports at Y=", port_y, " -- plain through-holes (gland provides the shoulder/seal, no boss)"));
// smallest Z gap between installed gland FOOTPRINTS (port_ftp, NOT the 12 hole) on the inboard wall
port_zs = concat([port_stern_z, port_bow_z], stim_port ? [port_stim_z] : []);
min_port_gap = min([ for (i=[0:len(port_zs)-1], j=[i+1:len(port_zs)-1])
                     abs(port_zs[i]-port_zs[j]) - port_ftp ]);
echo(str("  min inboard gland-footprint (", port_ftp, " mm) Z gap = ", round(10*min_port_gap)/10,
         " mm ", min_port_gap >= 3 ? "OK" : "  << WARNING: glands crowd in Z"));

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
if (step >= wall - 1.0) echo("  WARNING: step band leaves < 1 mm of wall behind the dents");

echo("--- lid gland (item 3: local motor leads route through the lid) -");
if (lid_gland) {
  g_edge = min(H/2 - abs(lid_gland_z), W/2 - abs(lid_gland_x)) - lid_gland_d/2;    // to nearest lid edge/skirt
  g_lock = (n_locks>=3) ? abs(lid_gland_z + (H/2 - step)) - lid_gland_d/2 - bump_l/2 : 1e9; // to stern-end lock
  echo(str("  gland ", lid_gland_d, " at (X=", lid_gland_x, ", Z=", lid_gland_z,
           ") ; clear of lid edge/skirt by ", round(10*g_edge)/10, " mm ",
           g_edge >= skirt_t+2 ? "OK" : "  << WARNING: too close to the skirt"));
  echo(str("  clear of the stern-end snap lock by ", round(10*g_lock)/10, " mm ",
           g_lock >= 2 ? "OK" : "  << WARNING: gland sits over a snap lock"));
} else echo("  lid gland OFF");

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
//  KNUCKLE HINGE  (ported verbatim; now the outboard long edge)
// =====================================================================
module hinge_segments(from)
  for (i = [from : 2 : hinge_segs-1])
    translate([0, 0, seg_z(i)]) linear_extrude(seg_h) children();

module pin_bore_cut(apex)
  translate([Ax, Ay, -hinge_span/2 - 1]) linear_extrude(hinge_span + 2)
    rotate(apex > 0 ? 0 : 180) teardrop2d(d=pin_bore, ang=45);

module housing_leaf_2d() {
  translate([Ax, Ay]) circle(d=knuckle_d);
  polygon(concat(
    [[Ax + kr*cos(shell_bevel), Ay + kr*sin(shell_bevel)],
     [-W/2, ov_d + 0.3],
     [-W/2 + 0.6, ov_d + 0.3],
     [-W/2 + 0.6, leaf_reach]],
    arc(n=16, r=hinge_fillet, cp=leaf_F, angle=[0, -hinge_arm_ang]),
    [leaf_P]));
}
module door_leaf_2d() {
  translate([Ax, Ay]) circle(d=knuckle_d);
  polygon([[Ax - kr, -lid_t], [-W/2 + 0.6, -lid_t],
           [-W/2 + 0.6, Ay], [Ax - kr, Ay]]);
}
module hinge_housing() {
  difference() {
    hinge_segments(0) housing_leaf_2d();
    pin_bore_cut(-1);     // body prints floor down -> print-up = -y
  }
}
module hinge_door() {
  difference() {
    hinge_segments(1) door_leaf_2d();
    pin_bore_cut(+1);     // lid prints outer face down -> print-up = +y
  }
}

// =====================================================================
//  LID OVERLAP + SNAP LOCKS  (ported verbatim; full top-face perimeter)
// =====================================================================
module front_step_cut() {
  intersection() {
    difference() {
      translate([-W/2-5, -eps, -H/2-5]) cube([W+10, ov_d+0.3+eps, H+10]);
      translate([0, -2*eps, 0]) hull() for (sz=[-1,1]) {
        translate([ W/2-corner_r, 0, sz*(H/2-corner_r)])
          rotate([-90,0,0]) cylinder(h=ov_d+0.3+4*eps, r=corner_r-step);
        translate([-W/2+corner_r + (step_left-step), 0, sz*(H/2-corner_r)])
          rotate([-90,0,0]) cylinder(h=ov_d+0.3+4*eps, r=corner_r-step);
      }
    }
    translate([-W/2-1, -1, -H/2-6]) cube([W+10, ov_d+2, H+12]);
  }
}
module lock_wedge(o, dent=false) {
  s = dent ? 1.05 : 1;
  prismoid(size1=[bump_l*s, bump_w*s], size2=[bump_l*0.75*s, 0],
           h=bump_h + (dent ? 0.1 : 0), orient=o);
}
module lock_dents() {
  for (z = lock_zs) translate([W/2-step+eps, lock_y, z]) lock_wedge(LEFT, dent=true);
  if (n_locks >= 2) translate([0, lock_y,  H/2-step+eps])  lock_wedge(DOWN, dent=true);
  if (n_locks >= 3) translate([0, lock_y, -(H/2-step)-eps]) lock_wedge(UP, dent=true);
}
module door_skirt() {
  difference() {
    rprism(W, H, ov_d, corner_r);
    translate([0, -eps, 0])
      rprism(W-2*skirt_t, H-2*skirt_t, ov_d+3*eps, corner_r-skirt_t);
  }
  for (z = lock_zs) translate([W/2-skirt_t+eps, lock_y, z]) lock_wedge(LEFT);
  if (n_locks >= 2) translate([0, lock_y,  H/2-skirt_t+eps])  lock_wedge(DOWN);
  if (n_locks >= 3) translate([0, lock_y, -(H/2-skirt_t)-eps]) lock_wedge(UP);
  if (grip)
    translate([lid_w/2, -lid_t, 0]) rotate([-90, 0, 0])
      prismoid(size1=[3, bump_l], size2=[0.8, bump_l*0.75],
               shift=[-1.1, 0], h=2);
}

// =====================================================================
//  XT60 CHARGE PORT  (ported; outboard wall / floor / stern)
// =====================================================================
module xt60_cut() {
  if (xt60 && xt60_face != "none") {
    bw = xt60_body[0]; bh = xt60_body[1];
    if (xt60_face=="left" || xt60_face=="right") {
      sx = (xt60_face=="right") ? 1 : -1;
      translate([sx*(W/2-wall/2), D/2+xt60_y, xt60_pos]) rotate([0,sx*90,0]) {
        cube([bw, bh, wall+2*eps], center=true);
        for (s=[-1,1]) translate([s*xt60_screw_sep/2, 0, 0])
          cylinder(h=wall+2*eps, d=xt60_screw_d, center=true);
      }
    } else if (xt60_face=="bottom") {   // floor (Y=D)
      translate([xt60_pos, D-wall/2, 0]) rotate([90,0,0]) {
        cube([bw, bh, wall+2*eps], center=true);
        for (s=[-1,1]) translate([s*xt60_screw_sep/2, 0, 0])
          cylinder(h=wall+2*eps, d=xt60_screw_d, center=true);
      }
    } else if (xt60_face=="bow" || xt60_face=="stern") {  // end wall (+Z bow / -Z stern)
      zc = (xt60_face=="bow") ? H/2-wall/2 : -H/2+wall/2;
      translate([xt60_pos, D/2+xt60_y, zc]) {   // long axis (flange/screws) along X
        cube([bw, bh, wall+2*eps], center=true);
        for (s=[-1,1]) translate([s*xt60_screw_sep/2, 0, 0])
          cylinder(h=wall+2*eps, d=xt60_screw_d, center=true);
      }
    }
  }
}

// =====================================================================
//  THROUGH-BOARD SCREW MOUNT  (floor interior; blind, sealed, WATERTIGHT)
//  Each boss is a solid PLA cylinder unioned to the floor, rising boss_rise
//  INTO the chamber.  The screw bore is drilled from the BOTTOM (bed) face
//  (Y=D) UPWARD (toward -Y / the lid) and stops screw_cap short of the boss
//  top, so it NEVER reaches the chamber void -- the whole watertight guarantee.
//  Because the box prints floor-DOWN, the boss stands vertically on the bed
//  (fully supported) and the blind bore opens at the bed face and runs straight
//  up -> self-supporting, NO teardrop needed (unlike the old horizontal sockets).
//  The bosses are unioned AFTER the cavity is carved (see body()); otherwise the
//  cavity cut would erase them.  The bore is then cut through the merged
//  floor+boss, so the screw passes through the 2.5 mm floor and engages the boss.
// =====================================================================
module screw_boss(p) {   // solid boss: underside (Y=D) up into the chamber to Y=boss_top_y
  translate([p[0], D, p[1]]) rotate([90,0,0]) cylinder(h=boss_h, d=boss_od);
}
module screw_boss_cut(p) {   // blind bore UP from the underside; method sets insert / thread / pilot
  translate([p[0], D + eps, p[1]]) rotate([90,0,0]) {
    if (screw_method=="insert")      cylinder(h=insert_depth + eps, d=insert_d);
    else if (screw_method=="thread") tapped_hole(screw_size, screw_pitch, thread_len + eps, selftap_d, td=false);
    else                             cylinder(h=selftap_depth + eps, d=selftap_d);
  }
}

// =====================================================================
//  TASK 3 -- CABLE PORTS  (inboard +X wall; PLAIN through-holes, item 4)
//  No external boss: the cable gland's own threaded body + nut form the
//  shoulder and seal.  Just a clean hole through the 2.5 mm wall, sized for
//  the gland's panel-mount diameter.
// =====================================================================
module cable_port_cut(z, dia) {
  translate([W/2-wall-eps, port_y, z]) rotate([0,90,0])
    cylinder(h=2*wall+2*eps, d=dia);
}

// =====================================================================
//  TASK 1 -- MOTOR MOUNT BLOCK  (external, on the stern -Z wall)
//  A solid block protruding AFT from the stern wall, extending DOWN to the
//  FLOOR (Y=D) so it rests on the bed when printing (no overhang) and spreads
//  the motor load into the floor, not just the 2.5 mm wall.  The pylon foot
//  bolts to its aft face; 4 M4 blind PILOT holes thread into the block and end
//  mm_cavity_margin short of the cavity -- no fastener enters the interior.  A
//  full-width register SLOT takes the shear/moment (bolts not in pure shear).
// =====================================================================
module motor_mount_boss() {
  difference() {
    translate([0, mm_pad_yc, -H/2 - mm_block_depth/2 + eps])
      cube([mm_pad_w, mm_pad_h, mm_block_depth], center=true);
    // full-width register slot in the aft face (pylon tongue seats here)
    translate([0, mm_pad_yc, mm_block_aft_z - eps])
      cube([pylon_width+0.4, reg_h+0.4, 2*reg_depth], center=true);
  }
}
module motor_mount_cut() {
  // 4 TAPPED M4 blind holes into the aft face; end short of the cavity (item 5).
  // Axis is model +Z (fore-aft) -> prints HORIZONTAL, so teardrop the crest.
  // The body prints via rotate([-90,0,0]) (model -Y -> world +Z up); spin=180
  // moves BOSL2's default +Y teardrop to model -Y so its apex ends up UP.
  for (sx=[-1,1], sy=[-1,1])
    translate([sx*mm_bolt_x/2, mm_pad_yc + sy*mm_bolt_y/2, mm_block_aft_z - eps])
      tapped_hole(4, 0.7, mm_bolt_depth + eps, mm_bolt_pilot, td=true, spin=180);
}

// =====================================================================
//  PYLON  (SEPARATE part; ONE linear_extrude -> a genuinely FLAT face on the
//  bed, supportless).  Profile is in X = fore-aft (+aft), Y = up the mast;
//  extruded along Z = width (0..pylon_width).  Printed AS MODELED (oriented()
//  is identity): the flat Z=0 face is on the bed, the mast length lies along
//  Y, and the layers (X-Y planes) run ALONG the mast -- the bending stress
//  runs within the layers, not across them.
//
//  v0.2 (Patrick): the reinforcement is a FULL-HEIGHT triangular buttress --
//  forward face flat at X=0 (the block-mating plane), aft face tapering from
//  base_aft at the foam BASE (Y=0) down to pylon_root_t at the mast tip.  The
//  bending moment is MAXIMUM at the base, so the section is deepest there (the
//  old design put the thick part at the mast root with only a thin foot below
//  -- backwards).  Concave junctions are filleted (offset "closing") for a
//  smooth load path; the aft taper doubles as the streamlined trailing edge.
//  The register tongue is unioned AFTER the fillet so it stays crisp.
// =====================================================================
module pylon_2d() {
  union() {
    offset(r=pylon_fillet) offset(delta=-pylon_fillet) union() {
      polygon([[0,0], [base_aft,0], [pylon_root_t, pylon_rise], [0, pylon_rise]]); // full-height buttress
      translate([0, pylon_rise - pad_h/2]) square([pad_aft, pad_h]);               // motor pad
    }
    translate([-reg_depth, (foot_h-reg_h)/2]) square([reg_depth+eps, reg_h]);       // register tongue (crisp)
  }
}
module pylon() color("Tan") linear_extrude(pylon_width) pylon_2d();
module pylon_cut() {
  cz = pylon_width/2;
  // PAD mounts the X BasePlate (item 2): a central clearance for the motor boss
  // that pokes through the plate's 10 mm bore, plus 4 M3 CLEARANCE holes on the
  // plate's OUTER "+" pattern (32 mm across each axis).  Every hole runs along
  // X through the whole pad -> open both sides (flat-head from the plate side,
  // nut on the forward face).  The pad face is the aft plane X=pad_aft.
  bp_hole_l = 2*(pad_aft + 2);   // spans the full pad depth, both sides open
  // central boss clearance -- TEARDROP (apex toward +Z = pylon print-up) so the
  // 11.5 mm horizontal bore self-supports instead of drooping onto the boss.
  translate([0, pylon_rise, cz]) rotate([0,0,-90]) teardrop(h=bp_hole_l, d=bp_bore+1.5);
  for (p = [[bp_bolt/2,0],[-bp_bolt/2,0],[0,bp_bolt/2],[0,-bp_bolt/2]])
    translate([0, pylon_rise + p[0], cz + p[1]]) rotate([0,90,0])
      cylinder(h=bp_hole_l, d=bp_screw_d, center=true);           // 4x M3 plate-mount
  // 4 foot bolts (item 1 redesign): M4 CLEARANCE all the way through the thick
  // buttress into the block, plus a socket-head COUNTERBORE cut ~foot_cbore_h
  // in from the ACTUAL (tapered) aft surface, so the heads stay recessed and
  // drivable.  x_aft = the buttress fore-aft surface at each bolt's height.
  // NOTE: the lower bolts sit foot_cbore_d/2 above the base (by=(foot_h-mm_bolt_y)/2),
  // so their counterbore is TANGENT to the base face -- intended and non-functional
  // (the base face stays intact, the head bears on the flat cbore floor, and in the
  // flat print the base is a vertical wall).  Don't grow foot_cbore_d or shrink
  // mm_bolt_y without rechecking -- it would notch the base face.
  for (sy=[-1,1], sz=[-1,1]) {
    by = foot_h/2 + sy*mm_bolt_y/2;
    bz = cz + sz*mm_bolt_x/2;
    x_aft = base_aft + (pylon_root_t - base_aft) * (by/pylon_rise);
    translate([-eps, by, bz]) rotate([0,90,0])
      cylinder(h=x_aft + 2, d=pylon_bolt_d);                          // clearance: mating face -> aft
    translate([x_aft - foot_cbore_h, by, bz]) rotate([0,90,0])
      cylinder(h=foot_cbore_h + 2, d=foot_cbore_d);                   // head counterbore from the aft surface
  }
  // (item 3) the pylon cable-groove is GONE: the local motor's leads route
  // through the LID gland and zip-tie to the mast, so the mast face stays solid.
}

// =====================================================================
//  BODY  (the shell -- one difference for all external through-features)
// =====================================================================
module body() {
  difference() {
    union() {
      // shell hollowed FIRST, THEN the interior screw bosses are unioned on top
      // (added after the cavity cut so the cavity does not erase them).
      difference() {
        union() {
          rprism(W, H, D, corner_r);
          hinge_housing();                          // outboard lid hinge
          motor_mount_boss();                       // stern motor pad
        }
        translate([0,-eps,0]) rprism(inner_w, inner_h, inner_d+eps, corner_r-wall); // cavity (top open)
      }
      if (screw_mount) for (p=screw_positions) screw_boss(p);   // solid hold-down bosses on the floor
    }
    // through-features cut through the assembled solid: the screw bores pierce the
    // floor AND the boss together, leaving the sealed cap between bore top and chamber.
    if (screw_mount) for (p=screw_positions) screw_boss_cut(p);
    cable_port_cut(port_stern_z, port_stern_d);     // plain gland holes (item 4)
    cable_port_cut(port_bow_z, port_bow_d);
    if (stim_port) cable_port_cut(port_stim_z, port_stim_d); // 3rd port, stim hull only (item 6)
    motor_mount_cut();
    xt60_cut();
    front_step_cut();                               // stepped band the lid skirt wraps
    lock_dents();
  }
}

// =====================================================================
//  LID  (the top panel)
// =====================================================================
module lid_body() {
  translate([0,-lid_t,0]) rprism(lid_w, lid_h, lid_t, lid_r);
}
module lid_gland_cut() {   // item 3: through-hole for the local motor's phase leads
  if (lid_gland)
    translate([lid_gland_x, -lid_t-eps, lid_gland_z]) rotate([-90,0,0])
      cylinder(h=lid_t+2*eps, d=lid_gland_d);
}
module lid() {
  difference() { lid_body(); lid_gland_cut(); }   // gland pierces only the panel
  hinge_door();
  door_skirt();
}

// =====================================================================
//  PHANTOMS  (assembly preview only)
// =====================================================================
// rc_parts (the component footprints) is defined up in the DERIVED section so the
// screw-mount clearance echo can use it; these phantoms draw the same list.
module ghost_components() {
  for (p = rc_parts) color([0.3,0.6,0.9,0.35])
    translate([p[3][0]-p[1][0]/2, inner_d - p[2], p[3][1]-p[1][1]/2])
      cube([p[1][0], p[2], p[1][1]]);
}
module ghost_float() {
  // extends aft under the prop so the disc is seen sweeping OVER the float
  aft = prop_z_offset + 25;
  color([0.95,0.95,0.85,0.3])
    translate([-W/2-8, D, -H/2-aft]) cube([W+16, float_thickness, H+aft+15]);
}
module ghost_prop_and_motor() {
  // prop disc at TRUE diameter, aft of the stern, at hub height (clearance check).
  // The motor is drawn schematically here ONLY when the real Motor.stl phantom
  // is off (show_hardware); the disc is always drawn.
  translate([0, D - pylon_rise, -H/2 - prop_z_offset]) {
    if (!show_hardware) color([0.2,0.2,0.2,0.9]) translate([0,0,12])
      cylinder(h=22, d=motor_body_d, center=true);   // schematic motor, axis along Z (fore-aft)
    color([0.85,0.2,0.2,0.30])
      cylinder(h=1.5, d=prop_diameter, center=true); // prop disc (X-Y plane, normal = Z)
  }
}
// real BasePlate + motor STL phantoms on the pad (item 2 fit check).  Modelled
// in pylon-LOCAL coords so pylon_at_stern's transform carries them into place.
// The plate's OUTER "+" holes (+/-16) must land on the pad's 4 M3 holes.
module ghost_hardware() {
  if (show_hardware) {
    color([0.72,0.73,0.75,0.9])   // BasePlate flat on the pad aft face (X=pad_aft)
      translate([pad_aft, pylon_rise, pylon_width/2]) rotate([0,0,-90]) import("BasePlate.stl");
    color([0.12,0.12,0.13,0.9])   // motor: mounting face on the plate, can aft (+X)
      translate([pad_aft+2+1.6, pylon_rise, pylon_width/2]) rotate([0,0,90]) import("Motor.stl");
  }
}
// the 4 through-board hold-down screws: up through the foam into the blind bosses,
// with a fender washer / head UNDER the soft foam (so the head cannot pull through)
module ghost_screws() {
  if (screw_mount) for (p = screw_positions) color([0.7,0.7,0.75,0.9]) {
    translate([p[0], D - screw_hole_depth, p[1]]) rotate([-90,0,0])
      cylinder(h=screw_hole_depth + float_thickness, d=screw_size);      // shaft: boss -> under the board
    translate([p[0], D + float_thickness, p[1]]) rotate([-90,0,0])
      cylinder(h=2.5, d=max(16, 3.5*screw_size));                        // fender washer + head under the foam
  }
}
// pylon placed against the stern block aft face, mast up (assembly view).
// 180deg about (1,0,-1) maps pylon-local (fore-aft X, up Y, width Z) to the
// stern pose; the pylon is width-symmetric so this rotation is exact.
module pylon_at_stern() {
  translate([pylon_width/2, mm_pad_yc + foot_h/2, mm_block_aft_z])
    rotate(a=180, v=[1,0,-1]) {
      difference() { pylon(); pylon_cut(); }
      ghost_hardware();
    }
}

// =====================================================================
//  ORIENTATION / OUTPUT
// =====================================================================
module apply_side() {
  if (side == "starboard") mirror([1,0,0]) children();
  else children();
}
module oriented(p) {
  if (!print_ready) children();
  else if (p=="body") translate([0,0,D]) rotate([-90,0,0]) children();   // floor down
  else if (p=="lid")  translate([0,0,lid_t]) rotate([90,0,0]) children(); // outer face down
  else if (p=="pylon") children();  // modeled flat already (Z=0 face on the bed)
  else children();
}

// one hull, in model space (before side mirror / orientation)
module hull_assembly() {
  color("SteelBlue") body();
  // lid swings about the outboard hinge axis (Ax,Ay), which runs along Z (the length)
  translate([Ax, Ay, 0]) rotate([0, 0, -lid_open]) translate([-Ax, -Ay, 0])
    color("Gainsboro") lid();
  pylon_at_stern();
  if (show_ghosts) { ghost_components(); ghost_float(); ghost_prop_and_motor(); ghost_screws(); }
}

module assembly_scene() {
  apply_side() hull_assembly();
  if (show_both_hulls) {
    translate([ (side=="port"? 1:-1) * beam_target, 0, 0])
      mirror([1,0,0]) apply_side() hull_assembly();
  }
}
if (part=="assembly") {
  // model "up" is -Y; upright view rotates it so height is world +Z (Z-up camera)
  if (preview_upright) rotate([-90,0,0]) assembly_scene();
  else assembly_scene();
}
else if (part=="body")  oriented("body") apply_side() body();
else if (part=="lid")   oriented("lid")  apply_side() lid();
else if (part=="pylon") oriented("pylon") difference() { pylon(); pylon_cut(); }
