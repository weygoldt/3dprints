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
//                           +X wall = INBOARD   -> PVC rod sockets, cable ports
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
//  two blind teardrop PVC rod sockets, stern + bow cable ports, and a SEPARATE
//  bonded float-mount CRADLE (the box drops into a foam-bonded collar + a 4 mm
//  bungee clamps over the top).  DROPPED from the stim donor (they belong to the
//  chest device and would foul the top lid): playback buttons, masthead, eel
//  tie, top-face power switch / LED, BNC.  ALSO DROPPED: the lanyard/zip-tie
//  ears -- superseded by the bonded cradle (no hardware through the foam).
//  KEPT: the XT60 charge port.
//
//  Requires BOSL2 (../BOSL2).  Print PLA, no supports.
//  PARTS (part=):  assembly(preview) | body | lid | pylon | cradle
//     body   : FLOOR on the bed
//     lid    : outer face down
//     pylon  : laid flat (layers along its length -- bending load along layers)
//     cradle : bonding-face DOWN on the bed (foam-bond plane on the bed, walls up)
// =====================================================================

include <../BOSL2/std.scad>
include <../BOSL2/threading.scad>   // metric tapped holes (Task 5); std.scad omits it

/* [What to render] */
part = "assembly";   // [assembly, body, lid, pylon, cradle]
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
lid_gland_d = 12.5;   // PG7 gland panel-mount hole (matches the port glands)
lid_gland_x = 0;      // athwartship (X): 0 = centreline
lid_gland_z = -60;    // fore-aft (Z): near the stern/pylon end, clear of locks & skirt

/* [Side & boat] -- one body, two hulls */
beam_target = 240;  // hull centreline-to-centreline spacing (mm).  Sets rod
                    // length; MUST exceed prop_diameter or the two stern
                    // props collide (echo-checked).

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

/* [Float-mount cradle] -- REPLACES the lanyard ears.  A SEPARATE printed collar
   bonded to the XPS foam float: the box DROPS IN (walls key to the box floor
   footprint -> take all slide + yaw) and a 4 mm elastic bungee runs athwartship
   OVER the top (takes only the lift/pitch preload; elastic holds tension as the
   foam compresses, and hooks on/off in a second for a field mount/unmount).
   NO fastener touches the sealed box -- pure capture + bungee.  Bonds to XPS
   with PU / epoxy / low-temp hot-melt (NOT solvent cement).  Mirrors with
   `side` exactly like the box (the holes/hooks swap sides).  Prints
   bonding-face DOWN (the foam-bond plane on the bed, walls up) -> one flat face,
   supportless.  Keyed to the box floor: outer 95 (W) x 170 (H), corner_r 5, with
   the stern motor block (50 wide) protruding 14 aft. */
cradle          = true;   // build the cradle (assembly preview + part="cradle")
cradle_clear    = 0.4;    // gap box-outer -> wall-inner (drop-in fit + print slop)
cradle_wall_t   = 3;      // capture-wall thickness
cradle_wall_h   = 6;      // capture-wall height (<=~7 clears the low inboard cable ports;
                          // clears the high hinge leaf/XT60 on the other faces with margin)
cradle_flange_w = 8;      // outward glue-foot flange width (bonds flat to the foam)
cradle_flange_t = 3;      // glue-foot flange thickness (rises from the foam plane)
cradle_stern_relief = 54; // width (X) of the stern-wall gap for the motor block (>= mm_pad_w + slop)
cradle_recess   = 0;      // v2 hook: box sinks this far into a foam pocket (mm); 0 = top-bonded (v1)
// INSTALLED cable-gland hardware protrudes INBOARD from the inboard wall at each port
// (the box's OUTSIDE hex/dome, where the cable exits).  The cradle's inboard wall +
// anchor tabs share that space, so these drive the port-relief + anchor-Z clearances.
// (A bare-hole clearance check misses this -- an adversarial review caught it.)
cradle_gland_od = 18;     // gland hex/body OD that protrudes inboard (PG7 ~15-18 A/F; MEASURE yours)
cradle_gland_len= 22;     // how far the gland+cable reaches inboard (assembly ghost + probe)

/* [Cradle bungee anchors + hooks] -- one long side gets tie-HOLES (permanent
   anchor), the other gets HOOKS (quick-release).  The HOOK is a fore-aft RUNG
   held PROUD OUTBOARD of the wall by two stout gusseted bracket arms: the
   bungee's end-hook (or a loop) drops over the rung from the OUTBOARD/water side
   into the clear space around it -- it opens AWAY from the foam board (not down
   into it), and the up-and-inboard tension then seats it against the rung toward
   the wall.  The gussets make it stiff (not a flimsy staple); the rung is a
   short fore-aft BRIDGE between the two arms, so it still prints supportless.
   hooks_outboard=true (default) puts the HOOKS on the OUTBOARD long side (easy
   field reach; clears the lid hinge + swing -- probe-verified) and the tie-HOLES
   on the INBOARD side; flip it to swap.  n_bungee runs, a hook opposite an
   anchor at +/-Z. */
hooks_outboard  = true;   // true: hooks OUTBOARD (-X port frame), holes INBOARD (+X)
n_bungee        = 2;      // transverse bungee runs (2 or 3); 3 adds one amidships (Z=0)
bungee_z        = 18;     // |Z| of the paired anchor/hook lines.  MUST clear the INBOARD gland
                          // hardware (ports at +/-35, dia ~cradle_gland_od) and the rod bosses
                          // (+/-60): the clear windows are amidships |Z|<~21 (default) or the
                          // ends |Z|~76-80.  The echo flags fouling (gland/boss-aware).  The
                          // bungee is elastic + does anti-LIFT (position-insensitive); the walls
                          // take yaw/slide, so the amidships pair is fine.  Widen toward the ends
                          // if you want more anti-pitch (it lands near the corner -- see notes).
bungee_d        = 4;      // bungee cord diameter
anchor_hole_d   = 5.5;    // tie-hole through the anchor tab (> bungee_d, smooth entry)
anchor_tab_h    = 14;     // anchor-tab height from the foam plane (hole sits clear above the wall)
anchor_tab_w    = 10;     // anchor-tab size along Z (fore-aft)
anchor_tab_out  = 7;      // how far the anchor tab reaches out past the wall (X)
hook_h          = 14;     // rung height above the foam (kept below the hinge leaf -- probe-checked)
hook_w          = 14;     // hook total width along Z (fore-aft): two arms + the clear access gap
hook_reach      = 10;     // how far the rung stands PROUD outboard of the wall (clear space to hook on)
hook_arm_t      = 3.5;    // gusset-arm thickness, each of the two brackets (stout, not flimsy)
hook_rung_d     = 5;      // fore-aft rung diameter -- the bar the bungee end-hook / loop catches over

/* [XT60 charge port] -- KEPT (each hull has a cell to charge).  On the BOW end
   wall (+Z): the outboard wall is fully occupied by the lid hinge (the 35 mm
   flange cannot clear the +/-60 knuckle stack), and the inboard wall carries
   the rod sockets + cable ports -- the bow end is the only clear face.
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
//  Tapped holes so bolts/set-screws thread straight into the PLA:
//    (a) the 4 stern-block pylon-attach holes -> M4  (see mm_bolt_* below)
//    (b) the PVC rod-socket lock (grub) holes  -> M3  (see rod_grub_* below)
//  use_threads=true models real BOSL2 internal threads.  If they print poorly
//  at this scale on the MK3S, set use_threads=false to fall back to the
//  thread-FORMING pilot holes (mm_bolt_pilot / rod_grub_d -- a bolt or set
//  screw cuts its own thread in the PLA).  The block holes print with their
//  axis HORIZONTAL, so they use BOSL2's teardrop thread crest (self-
//  supporting); the rod grub holes print with a VERTICAL axis (self-support
//  is automatic).  The pylon-foot holes and cable ports stay plain (bolt+nut
//  / gland), so only these two families are threaded.
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
//  TASK 2 -- PVC ROD SOCKETS (inboard wall, blind, teardrop)
// =====================================================================
rod_dia        = 12;    // nominal PVC rod
rod_clearance  = 0.4;   // added to the bore
socket_depth   = 25;    // rod insertion depth (>=25)
socket_wall    = 3.0;   // solid PLA left at the blind bottom (>=3)
rod_z_bow      = 60;    // bow socket position along the length (+Z)
rod_z_stern    = -60;   // stern socket position along the length (-Z)
rod_axis_y     = 18;    // Y of the rod axis (from the lid plane Y=0; mid-height)
rod_grub_d     = 2.5;   // cross-drilled grub-screw pilot: thread-forming for an M3 set
                        // screw in PLA (NOT the 3.2 clearance -- it must bite the rod)

// =====================================================================
//  TASK 3 -- CABLE PORTS (inboard +X wall) -- PLAIN through-holes.
//  The cable GLAND supplies its own shoulder/seal (threaded body seats in the
//  hole, nut inside), so there is NO printed boss (Patrick, item 4).  Each
//  diameter below is the gland's PANEL-MOUNT hole, not the cable bundle:
//    PG7 = 12.5 (cable 3-6.5) | PG9 = 15.2 (4-8) | M12x1.5 = 12.  Confirm which
//    gland you use and set these.  Default PG7 (fits the 3 motor phase leads).
// =====================================================================
port_stern_d   = 12.5;  // stern port gland hole: 3 motor phase leads (RC box -> far motor)
port_bow_d     = 12.5;  // bow   port gland hole: opto->Teensy signal (thin; a smaller gland is fine)
port_stern_z   = -35;   // stern port position along the length (clear of the stern socket)
port_bow_z     = 35;    // bow port position (clear of the bow socket)
port_y         = 24;    // Y of the port centers (below the rod axis, near the floor)

// Item 6 -- a THIRD inboard port for the stimulator's own wires, on the STIM
// hull ONLY.  stim_port is INDEPENDENT of side (set it true on whichever hull
// you print as the stim box), so either physical hull can be the stim hull.
stim_port      = false; // set true when printing the stim hull
port_stim_d    = 12.5;  // stim port gland hole (stimulator electrode/output leads)
port_stim_z    = 0;     // amidships: clear of both rod sockets (+/-60) and the two ports (+/-35)

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

// --- Cradle derived (box model frame; the floor plane Y=D is the foam-bond face) ---
cr_foam_y = D + cradle_recess;               // foam-bond plane (v1 recess=0 -> Y=D=floor)
cr_in_x   = W/2 + cradle_clear;              // wall inner face, athwartship (box +/-47.5 + clr)
cr_in_z   = H/2 + cradle_clear;              // wall inner face, fore-aft
cr_out_x  = cr_in_x + cradle_wall_t;         // wall outer face, athwartship
cr_out_z  = cr_in_z + cradle_wall_t;         // wall outer face, fore-aft
cr_top_y  = cr_foam_y - cradle_wall_h;       // wall top Y (smaller Y = up toward the lid)
cr_flange_x = cr_out_x + cradle_flange_w;    // flange outer edge, athwartship
cr_flange_z = cr_out_z + cradle_flange_w;    // flange outer edge, fore-aft
// corner radii: pocket = box corner + clearance (clears the box corners); wall &
// flange outers keep a uniform wall thickness at the corners
cr_pocket_r = corner_r + cradle_clear;       // 5.4 -- inner pocket the box drops into
cr_outer_r  = cr_pocket_r + cradle_wall_t;   // 8.4 -- wall outer corner
cr_flange_r = cr_outer_r + cradle_flange_w;  // flange outer corner
// low-feature clearances (mm the wall top clears each low box feature)
port_bot_above_floor   = D - (port_y + max(port_stern_d,port_bow_d,stim_port?port_stim_d:0)/2);
xt60_flange_bot_above  = (xt60 && xt60_face=="bow") ? D - (D/2 + xt60_flange_h/2) : 1e9;
cradle_port_gap = port_bot_above_floor - cradle_wall_h;   // >0: inboard wall clears the ports
cradle_xt60_gap = xt60_flange_bot_above - cradle_wall_h;  // >0: bow wall clears the XT60 flange
// bungee anchor/hook X sides (port frame: hooks_outboard -> hooks on -X, holes on +X)
hook_sign   = hooks_outboard ? -1 :  1;      // wall the hooks grow from
anchor_sign = hooks_outboard ?  1 : -1;      // wall the holes grow from
bungee_zs   = (n_bungee>=3) ? [bungee_z, 0, -bungee_z] : [bungee_z, -bungee_z];
// inboard obstacle map (only matters on the ANCHOR/hole side, which shares the
// inboard space with the cable glands + rod bosses): each obstacle is [Z, half-width-in-Z].
cr_port_zs   = concat([port_stern_z, port_bow_z], stim_port ? [port_stim_z] : []);
// (rod_bore is a Task-2 derived defined later in the file; use its parts to avoid a fwd-ref)
cr_obstacles = concat([ for (pz = cr_port_zs)              [pz, cradle_gland_od/2] ],
                      [ for (rz = [rod_z_bow, rod_z_stern]) [rz, (rod_dia+rod_clearance+9)/2] ]);
// smallest Z-gap between any anchor tab (width anchor_tab_w) and an inboard obstacle
function anchor_gap(z) = min([ for (o = cr_obstacles) abs(z - o[0]) - anchor_tab_w/2 - o[1] ]);
cr_min_anchor_gap = min([ for (z = bungee_zs) anchor_gap(z) ]);
// inboard wall must clear the gland BODY (not just the hole): gland bottom Y vs wall top Y
cr_gland_bot_y = port_y + cradle_gland_od/2;              // gland body reaches here (toward the foam)
cr_relief_top_y = cr_gland_bot_y + 0.5;                   // scallop the wall top down to here at each port
// print-orientation extents (bonding-face down = same transform as body): X across
// the beam (hook tip -> anchor tab), Z fore-aft, height = wall/tab/hook stack
cr_hook_tip_x   = cr_out_x + hook_reach + hook_rung_d/2;      // rung reaches this far out
cr_anchor_tip_x = cr_out_x + anchor_tab_out;                 // anchor tab reaches this far out
cr_x_ext   = max(cr_flange_x, cr_hook_tip_x, cr_anchor_tip_x) * 2;  // symmetric worst case
cr_z_ext   = cr_flange_z * 2;                                // fore-aft (motor relief is an open gap)
cr_h_ext   = max(cradle_wall_h, anchor_tab_h, hook_h) + cradle_recess; // build height

// --- Task 1 derived: prop clearance & pylon height ---
prop_radius = prop_diameter/2;
box_outer_height = D;                       // floor to body top, above the float
hub_height_above_water = prop_radius + float_freeboard + prop_clearance_margin;
hub_above_box_top = hub_height_above_water - (float_freeboard + box_outer_height);
pylon_rise = hub_height_above_water - float_freeboard;   // hub above the box floor/mount
disc_low_above_float = hub_height_above_water - prop_radius - float_freeboard; // >0 clears

// --- Task 2 derived: rod boss protrusion & beam ---
rod_bore = rod_dia + rod_clearance;
rod_boss_protrusion = socket_depth + socket_wall - wall;   // inboard (+X) reach
rod_boss_tip_x = W/2 + rod_boss_protrusion;
rod_bore_inner_x = rod_boss_tip_x - socket_depth;          // deepest point of the bore
rod_bottom_margin = rod_bore_inner_x - (inner_w/2);        // solid to the cavity (>=socket_wall)
rod_gap = beam_target - W - 2*rod_boss_protrusion;
rod_length = rod_gap + 2*socket_depth;

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
body_x_ext = rod_boss_tip_x - (Ax - kr);              // inboard boss tip -> outboard barrel
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

echo("--- Task 2: PVC rod sockets (inboard +X wall, blind) -----------");
echo(str("  bore ", rod_bore, " (rod ", rod_dia, " + ", rod_clearance,
         ") ; depth ", socket_depth, " ; boss protrudes ", rod_boss_protrusion, " inboard"));
echo(str("  blind-bottom solid to cavity = ", rod_bottom_margin, " mm (need >= ", socket_wall, ") ",
         rod_bottom_margin >= socket_wall ? "OK" : "  << WARNING: socket breaks toward the cavity"));
echo(str("  sockets at Z = ", rod_z_bow, " (bow), ", rod_z_stern,
         " (stern) ; both at rod_axis_y = ", rod_axis_y, " (coaxial per hull)"));
echo(str("  beam_target = ", beam_target, " -> rod_length = ", rod_length,
         " (gap ", rod_gap, " + 2 x ", socket_depth, ")"));
if (beam_target <= prop_diameter)
  echo(str("  WARNING: beam_target ", beam_target, " <= prop_diameter ", prop_diameter,
           " -- the two stern props collide.  Widen beam_target."));
else
  echo(str("  stern-prop clearance across the beam = ", beam_target - prop_diameter, " mm OK"));

echo("--- Task 3: cable ports (inboard +X wall) -- PLAIN gland holes -");
echo(str("  stern port ", port_stern_d, " mm at Z=", port_stern_z,
         " (3 motor phases) ; bow port ", port_bow_d, " mm at Z=", port_bow_z, " (signal)",
         stim_port ? str(" ; STIM port ", port_stim_d, " mm at Z=", port_stim_z) : " ; stim port OFF"));
echo(str("  ports at Y=", port_y, " -- plain through-holes (gland provides the shoulder/seal, no boss)"));
// smallest Z gap between any two inboard features (ports + rod-socket bosses); flag if tight
port_zs = concat([[port_stern_z, port_stern_d/2], [port_bow_z, port_bow_d/2]],
                 stim_port ? [[port_stim_z, port_stim_d/2]] : [],
                 [[rod_z_bow, (rod_bore+9)/2], [rod_z_stern, (rod_bore+9)/2]]);
min_port_gap = min([ for (i=[0:len(port_zs)-1], j=[i+1:len(port_zs)-1])
                     abs(port_zs[i][0]-port_zs[j][0]) - port_zs[i][1] - port_zs[j][1] ]);
echo(str("  min inboard-feature Z gap (ports + socket bosses) = ", round(10*min_port_gap)/10,
         " mm ", min_port_gap >= 3 ? "OK" : "  << WARNING: features merge/crowd in Z"));

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

echo("--- float-mount cradle (SEPARATE, bonded to the foam) ----------");
if (cradle) {
  echo(str("  keys off the box floor ", W, " x ", H, " (corner_r ", corner_r,
           ") ; drop-in clearance ", cradle_clear, " ; wall ", cradle_wall_t,
           " x ", cradle_wall_h, " high ; glue-foot flange ", cradle_flange_w, " wide"));
  echo(str("  INBOARD wall clears the cable ports by ", round(10*cradle_port_gap)/10,
           " mm ", cradle_port_gap >= 1 ? "OK" : "  << WARNING: wall hits the ports, lower cradle_wall_h"));
  echo(str("  BOW wall clears the XT60 flange by ", round(10*cradle_xt60_gap)/10,
           " mm ", cradle_xt60_gap >= 1 ? "OK" : "  << WARNING: wall hits the XT60, lower cradle_wall_h"));
  echo(str("  OUTBOARD wall top at Y=", cr_top_y, " vs hinge-leaf reach Y=",
           round(1000*leaf_reach)/1000, " (wall stays ", round(10*(cr_top_y-leaf_reach))/10,
           " mm below the leaf) ", cr_top_y - leaf_reach >= 1 ? "OK" : "  << WARNING: wall fouls the hinge leaf"));
  echo(str("  STERN motor-block relief gap ", cradle_stern_relief, " (>= block ", mm_pad_w,
           ") ", cradle_stern_relief >= mm_pad_w + 2 ? "OK" : "  << WARNING: relief narrower than the motor block"));
  echo(str("  bungee: ", n_bungee, " transverse runs at Z=", bungee_zs,
           " ; cord ", bungee_d, " ; ", hooks_outboard ? "HOOKS OUTBOARD, HOLES INBOARD" : "HOOKS INBOARD, HOLES OUTBOARD"));
  echo(str("  anchor tie-hole ", anchor_hole_d, " (> cord ", bungee_d, ") ",
           anchor_hole_d > bungee_d ? "OK" : "  << WARNING: hole smaller than the cord"));
  // GLAND-AWARE (the bare-hole check missed installed hardware): the inboard anchor tabs
  // share the inboard space with the cable glands (Z=+/-35, dia cradle_gland_od) + rod bosses (+/-60)
  echo(str("  anchor-tab Z-gap to nearest inboard obstacle (gland dia ", cradle_gland_od,
           " / rod boss) = ", round(10*cr_min_anchor_gap)/10, " mm ",
           cr_min_anchor_gap >= 1.5 ? "OK" : "  << WARNING: anchor tab fouls a gland/boss -- move bungee_z (amidships |Z|<21 or ends ~77)"));
  echo(str("  inboard wall relieved at the ", len(cr_port_zs), " ports so the gland body (bottom Y=",
           cr_gland_bot_y, ") clears the wall (top Y=", cr_top_y, ")",
           cr_top_y < cr_gland_bot_y ? str(" -> scalloped to Y=", cr_relief_top_y) : " (no relief needed)"));
  // print orientation: bonding-face down (same transform as the body)
  echo(str("  prints bond-face DOWN: bed ", round(cr_x_ext), "(X) x ", round(cr_z_ext),
           "(Y=length) x ", round(cr_h_ext), "(Z=height) ; fits 250x210x210 ",
           (cr_x_ext<=250 && cr_z_ext<=210 && cr_h_ext<=210) ? "OK" : "  << CHECK"));
} else echo("  cradle OFF");

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
//  FLOAT-MOUNT CRADLE  (SEPARATE part; bonded to the foam, box drops in)
//  Built in the box model frame keyed to the floor footprint: the foam-bond
//  plane is Y=cr_foam_y (=D at recess 0) and the walls rise toward -Y (the lid).
//  A rounded-rect capture-wall RING (open pocket = box + clearance) + an outward
//  glue-foot FLANGE, with a central STERN relief for the motor block.  One long
//  side carries tie-HOLE anchor tabs, the other gusseted-rung bungee HOOKS.  Prints
//  bonding-face DOWN (same transform as the body: floor plane on the bed) -> one
//  flat bed face, supportless.  Mirrors with `side` via apply_side.
// =====================================================================
module cradle_frame() {
  difference() {
    union() {
      // capture walls: Y = cr_top_y (top) .. cr_foam_y (foam), out to cr_out
      translate([0, cr_top_y, 0]) rprism(2*cr_out_x, 2*cr_out_z, cradle_wall_h, cr_outer_r);
      // glue-foot flange: Y = cr_foam_y - flange_t .. cr_foam_y, out to cr_flange
      translate([0, cr_foam_y - cradle_flange_t, 0])
        rprism(2*cr_flange_x, 2*cr_flange_z, cradle_flange_t, cr_flange_r);
    }
    // open pocket the box drops through (open top and bottom)
    translate([0, cr_top_y - eps, 0])
      rprism(2*cr_in_x, 2*cr_in_z, cradle_wall_h + cradle_flange_t + 2*eps, cr_pocket_r);
    // STERN motor-block relief: clear the wall+flange central band at -Z
    translate([0, (cr_top_y + cr_foam_y)/2, -(cr_flange_z + cr_in_z)/2])
      cube([cradle_stern_relief, cradle_wall_h + 4, (cr_flange_z - cr_in_z) + 2], center=true);
    // PORT scallops: relieve the INBOARD (+X) wall top so the installed cable-gland BODY
    // clears (a bare-hole clearance is not enough -- the hex/dome reaches deeper).
    if (cr_top_y < cr_gland_bot_y)
      for (pz = cr_port_zs)
        translate([(cr_in_x + cr_out_x)/2, (cr_top_y - 1 + cr_relief_top_y)/2, pz])
          cube([cradle_wall_t + 2, cr_relief_top_y - cr_top_y + 1, cradle_gland_od + 4], center=true);
  }
}

// tie-hole anchor tab (permanent bungee end): a rounded post on the anchor-side
// wall with a FORE-AFT teardrop through-hole (prints horizontal -> apex up = -Y).
module cradle_anchor(sign, z) {
  x0 = sign*cr_in_x;                          // inner edge (merges into the wall)
  x1 = sign*cr_anchor_tip_x;                  // outer tip
  yt = cr_foam_y - anchor_tab_h;              // top
  hx = sign*(cr_out_x + anchor_tab_out*0.5);  // tie-hole X (mid the protrusion)
  hy = cr_foam_y - anchor_tab_h*0.6;          // tie-hole Y (upper-middle)
  translate([0,0,z]) difference() {
    linear_extrude(anchor_tab_w, center=true) hull() {
      translate([x0 + sign*0.6, cr_foam_y - 0.6]) circle(0.6);   // inner-bottom
      translate([x1 - sign*0.6, cr_foam_y - 0.6]) circle(0.6);   // outer-bottom
      translate([x0 + sign*3,   yt + 3]) circle(3);              // inner-top (round)
      translate([x1 - sign*3,   yt + 3]) circle(3);              // outer-top (round)
    }
    translate([hx, hy, -anchor_tab_w/2 - eps])
      linear_extrude(anchor_tab_w + 2*eps) rotate(180) teardrop2d(d=anchor_hole_d, ang=45);
  }
}

// quick-release bungee HOOK: a fore-aft RUNG held PROUD outboard of the wall by
// two stout gusseted bracket arms.  The bungee end-hook / loop drops over the
// rung from the OUTBOARD/water side (clear space around it -- it opens AWAY from
// the board, not down into it); the up-and-inboard tension seats it against the
// rung toward the wall.  The arm gussets are self-supporting solids (their
// down-outboard hypotenuse is <=45 deg); the rung is a short fore-aft BRIDGE
// between the two arm tops -> supportless.
module cradle_hook(sign, z) {
  s    = sign;
  yr   = cr_foam_y - hook_h;                  // rung height (up from the foam)
  rx   = s*(cr_out_x + hook_reach);           // rung outboard X (stands proud of the wall)
  xr   = s*(cr_out_x - 1);                    // arm root (1 mm into the wall -> solid merge)
  a_dz = hook_w/2 - hook_arm_t/2;             // arm centre offset (arms sit at the rung ends)
  // two gusset arms: solid triangles rising from the foam+wall out-and-up to the rung
  for (dz = [-a_dz, a_dz])
    translate([0, 0, z + dz]) linear_extrude(hook_arm_t, center=true)
      hull() {
        translate([xr, cr_foam_y - 0.6]) circle(0.6);            // inboard-bottom (wall+foam)
        translate([xr, yr]) circle(0.6);                         // inboard-top (up the back)
        translate([rx, yr]) circle(hook_rung_d/2 + 0.5);         // outboard-top (holds the rung)
      }
  // rung: fore-aft bar bridging the two arm tops -- the bungee catches over this
  translate([rx, yr, z]) cylinder(h=hook_w, d=hook_rung_d, center=true);
}

module cradle() color("DarkKhaki") union() {
  cradle_frame();
  for (z = bungee_zs) { cradle_anchor(anchor_sign, z); cradle_hook(hook_sign, z); }
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
//  TASK 2 -- PVC ROD SOCKETS  (inboard +X wall; blind, teardrop-relieved)
//  A reinforcing boss protrudes inboard from the +X wall; a blind bore runs
//  athwartship (along -X) from the boss tip, stopping socket_wall shy of the
//  cavity.  Its ceiling is an unsupported horizontal overhang, so the bore is
//  a teardrop (apex toward print-up = -y).  A cross-drilled grub-screw hole
//  from the top locks the rod.
// =====================================================================
module rod_boss(z) {   // solid reinforcing boss on the shell exterior
  hull() {
    translate([W/2-wall, rod_axis_y, z]) rotate([0,90,0])
      cylinder(h=eps, d=rod_bore+9);                       // rooted on the wall
    translate([rod_boss_tip_x, rod_axis_y, z]) rotate([0,90,0])
      cylinder(h=eps, d=rod_bore+6);                       // tapered tip
  }
}
module rod_socket_cut(z) {
  // blind teardrop bore along -X, apex toward -y (print-up).  teardrop2d apex
  // is +y; rotate(180) flips it to -y so, after the -90 Y-rotation places the
  // bore axis along X, the unsupported ceiling self-supports on the bed.
  translate([rod_boss_tip_x + eps, rod_axis_y, z]) rotate([0, -90, 0])
    linear_extrude(socket_depth + eps) rotate(180) teardrop2d(d=rod_bore, ang=45);
  // grub screw: TAPPED M3 from the top (-y) down into the bore, near the boss
  // root.  Axis prints VERTICAL (opens at the top face), so no teardrop needed.
  translate([W/2 + rod_boss_protrusion*0.4, -eps, z]) rotate([-90,0,0])
    tapped_hole(3, 0.5, rod_axis_y + rod_bore, rod_grub_d, td=false);
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
      rprism(W, H, D, corner_r);
      hinge_housing();                              // outboard lid hinge
      rod_boss(rod_z_bow); rod_boss(rod_z_stern);   // inboard rod-socket bosses
      motor_mount_boss();                           // stern motor pad
    }
    translate([0,-eps,0]) rprism(inner_w, inner_h, inner_d+eps, corner_r-wall); // cavity (top open)
    rod_socket_cut(rod_z_bow); rod_socket_cut(rod_z_stern);
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
rc_parts = [ //  name        footprint[X,Z]  height   center[X,Z]
  ["LiPo 3S",   [34, 75],  26.5, [ -25,  30]],
  ["ESC1",      [25, 45],  15,   [  20,  45]],
  ["ESC2",      [25, 45],  15,   [  20,  -5]],
  ["FS-iA6B",   [27, 47],  12,   [ -25, -35]],
  ["opto",      [30, 40],  10,   [  22, -50]],
];
module ghost_components() {
  for (p = rc_parts) color([0.3,0.6,0.9,0.35])
    translate([p[3][0]-p[1][0]/2, inner_d - p[2], p[3][1]-p[1][1]/2])
      cube([p[1][0], p[2], p[1][1]]);
}
// INSTALLED cable glands -- the hex/dome that protrudes INBOARD (+X) from each port.
// Modeled so the assembly preview + probes see the real hardware the cradle must clear.
module ghost_glands() {
  for (pz = cr_port_zs) color([0.15,0.15,0.15,0.6])
    translate([W/2 - wall, port_y, pz]) rotate([0,90,0])
      cylinder(h=cradle_gland_len, d=cradle_gland_od);
}
// the 4 mm bungee(s): tied at the inboard anchor tab, stretched athwartship OVER the
// top of the lid, and caught over the outboard hook rung.  Preview only -- shows the
// mount working (each transverse run at +/-bungee_z).
module ghost_bungee() {
  for (z = bungee_zs) {
    a  = [anchor_sign*(cr_out_x + anchor_tab_out*0.5), cr_foam_y - anchor_tab_h*0.55, z];
    hk = [hook_sign*(cr_out_x + hook_reach),           cr_foam_y - hook_h,           z];
    pk = [0, -lid_t - 4, z];   // arcs just over the closed lid
    color([0.1,0.1,0.1,0.9]) {
      hull() { translate(a)  sphere(bungee_d/2); translate(pk) sphere(bungee_d/2); }
      hull() { translate(pk) sphere(bungee_d/2); translate(hk) sphere(bungee_d/2); }
    }
  }
}
module ghost_float() {
  // extends aft under the prop so the disc is seen sweeping OVER the float; wide
  // enough that the cradle glue-foot flange sits fully on it (foam top at cr_foam_y)
  aft = prop_z_offset + 25;
  fx  = cradle ? cr_flange_x + 4 : W/2 + 8;
  color([0.95,0.95,0.85,0.3])
    translate([-fx, cr_foam_y, -H/2-aft]) cube([2*fx, float_thickness, H+aft+15]);
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
// the two 12 mm PVC connecting rods, spanning the beam through the inboard sockets
module ghost_rods() {
  sgn = (side=="port") ? 1 : -1;
  for (z = [rod_z_bow, rod_z_stern])
    color([0.55,0.55,0.6,0.75])
      translate([min(sgn*rod_bore_inner_x, sgn*(beam_target-rod_bore_inner_x)), rod_axis_y, z])
        rotate([0,90,0]) cylinder(h=beam_target - 2*rod_bore_inner_x, d=rod_dia);
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
  else if (p=="cradle") translate([0,0,cr_foam_y]) rotate([-90,0,0]) children(); // bond-face down
  else children();
}

// one hull, in model space (before side mirror / orientation)
module hull_assembly() {
  color("SteelBlue") body();
  // lid swings about the outboard hinge axis (Ax,Ay), which runs along Z (the length)
  translate([Ax, Ay, 0]) rotate([0, 0, -lid_open]) translate([-Ax, -Ay, 0])
    color("Gainsboro") lid();
  pylon_at_stern();
  if (cradle) cradle();   // the box drops into this foam-bonded collar
  if (show_ghosts) { ghost_components(); ghost_float(); ghost_prop_and_motor();
                     if (cradle) { ghost_glands(); if (lid_open == 0) ghost_bungee(); } }
}

module assembly_scene() {
  apply_side() hull_assembly();
  if (show_both_hulls) {
    translate([ (side=="port"? 1:-1) * beam_target, 0, 0])
      mirror([1,0,0]) apply_side() hull_assembly();
    if (show_ghosts) ghost_rods();   // the connecting rods span both hulls -- draw once
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
else if (part=="cradle") oriented("cradle") apply_side() cradle();
