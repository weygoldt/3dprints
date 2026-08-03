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
//  skirt + bump/dent snap locks, the teardrop lanyard ears, and the echo
//  fit-check harness -- by keeping that project's CODE FRAME and only
//  remapping which physical axis each stands for:
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
//  NEW for the airboat (Tasks 1-3): motor mount + a SEPARATE bolt-on pylon
//  (printed flat), two blind teardrop PVC rod sockets, stern + bow cable
//  ports.  DROPPED from the stim donor (they belong to the chest device and
//  would foul the top lid): playback buttons, masthead, eel tie, top-face
//  power switch / LED, BNC.  KEPT: the XT60 charge port and the lanyard/
//  zip-tie ears (the user lashes the box to the foam with zip ties).
//
//  Requires BOSL2 (../BOSL2).  Print PLA, no supports.
//  PARTS (part=):  assembly(preview) | body | lid | pylon
//     body  : FLOOR on the bed
//     lid   : outer face down
//     pylon : laid flat (layers along its length -- bending load along layers)
// =====================================================================

include <../BOSL2/std.scad>

/* [What to render] */
part = "assembly";   // [assembly, body, lid, pylon]
side = "port";       // [port, starboard]
print_ready = true;
lid_open   = 0;      // assembly preview only: degrees the lid is swung open
show_ghosts = true;  // assembly preview: draw components + float + prop discs
show_both_hulls = true; // assembly preview: draw the mirror hull too
preview_upright = false; // assembly preview: rotate so box HEIGHT is vertical (Z-up)

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

/* [Lanyard / zip-tie ears] -- KEPT from the stim donor: 4 teardrop-boss ears
   on the floor's side edges.  The user lashes the box to the styrofoam float
   with zip ties threaded through the foam and these ears. */
lanyard   = true;
lug_hole  = 4.5;
lug_web   = 3;
lug_out   = 5;
lug_t     = 8;
lug_inset = 22;     // Z inset from each end -> ears near the 4 floor corners

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

/* [Motor -- A2212-class 2212 outrunner] -- VERIFY the bolt pattern against
   the real motor with calipers before printing; cheap A2212s vary.  The four
   holes are short radial SLOTS (+/- motor_slot) so a slightly off pattern
   still bolts up. */
motor_bolt_x   = 16;    // one pair spacing  -> holes at (+/-8, 0)
motor_bolt_y   = 19;    // other pair spacing -> holes at (0, +/-9.5)
motor_screw_d  = 3.2;   // M3.2 clearance
motor_slot     = 1.0;   // radial slot half-length (0 = plain round holes)
motor_bore     = 10.5;  // central bore (>=10 to clear shaft boss + circlip)
motor_pad_t    = 5;     // motor pad thickness (>=5)
motor_body_d   = 28;    // motor body diameter (pad sizing)

/* [Motor mount + pylon] -- SEPARATE printed pylon bolts to an aft-protruding
   BLOCK on the stern wall.  Every fastener stays inside that block, AFT of
   the wall -- none enters the sealed cavity (echo-checked).  A register
   socket takes the shear/moment so the M4s are not in pure shear.  The pylon
   prints laid FLAT (layers along its length carry the bending load). */
mm_block_depth = 14;    // stern block aft protrusion (bolt thread lives here)
mm_pad_w       = 50;    // block width  (X)  -- extends DOWN to the floor (load spread, no overhang)
mm_bolt_x      = 32;    // M4 spread across the width  (envelope sqrt(32^2+26^2)=41 >= 40)
mm_bolt_y      = 26;    // M4 spread across the height
mm_bolt_depth  = 10;    // blind M4 thread depth into the block (< block_depth-2)
mm_bolt_pilot  = 3.4;   // BLIND-hole pilot in the block: thread-forming for M4 in PLA
                        // (set ~5.6 instead if using M4 heat-set inserts)
reg_depth      = 6;     // register tongue/slot depth (fore-aft) -- takes the shear/moment
reg_h          = 14;    // register tongue/slot height
pylon_width    = 44;    // pylon width (single supportless extrude): holds the 32 mm foot-bolt
                        // spread with >=3 mm wall to each edge, plus the motor body
pylon_root_t   = 8;     // mast fore-aft thickness at the top (>=4); root adds pylon_gusset
pylon_gusset   = 16;    // extra fore-aft thickness at the mast root (bending)
pylon_bolt_d   = 4.4;   // M4 CLEARANCE through the pylon foot (the block holes use mm_bolt_pilot)

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
//  TASK 3 -- CABLE PORTS (inboard wall, gland/barb shoulders)
// =====================================================================
port_stern_d   = 8;     // stern port: 3 motor phase leads bundled (user: one 8 mm)
port_bow_d     = 6;     // bow port: opto->Teensy signal (2 signal + 1 gnd, thin)
port_stern_z   = -35;   // stern port position along the length (clear of the stern socket)
port_bow_z     = 35;    // bow port position (clear of the bow socket)
port_y         = 24;    // Y of the port centers (below the rod axis, near the floor)
port_boss_t    = 3;     // external gland-shoulder boss thickness

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

// lanyard ears, in the print frame (floor down -> print-up = -y) -- ported
lug_d  = lug_hole + 2*lug_web;
lug_ex = W/2 + lug_out;
lug_ez = H/2 - lug_inset;
lug_ey = D - lug_d/2;
lug_front_y = lug_ey - lug_d/2;
lug_apex_y  = lug_ey - (lug_hole/2)/sin(45);
lug_apex_web = lug_apex_y - lug_front_y;

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
pad_h      = motor_body_d + 8;                             // motor pad height on the pylon
pad_aft    = pylon_root_t + motor_pad_t;                   // pylon pad aft (motor) face, fore-aft
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
echo(str("  motor bolt pattern (", motor_bolt_x, " x ", motor_bolt_y,
         "): holes at (+/-", motor_bolt_x/2, ", 0) and (0, +/-", motor_bolt_y/2,
         ") ; slot +/-", motor_slot, " ; central bore ", motor_bore));
if (motor_bore < 10) echo("  WARNING: central bore < 10 -- may bind on the shaft boss/circlip");
if (motor_pad_t < 5) echo("  WARNING: motor pad < 5 mm");
if (pylon_root_t < 4) echo("  WARNING: pylon root wall < 4 mm");
echo(str("  stern block ", mm_pad_w, " x ", mm_pad_h, " x ", mm_block_depth,
         " aft ; M4 x4 depth ", mm_bolt_depth, " ; envelope ",
         round(mm_bolt_envelope), " mm ", mm_bolt_envelope >= 40 ? "OK" : "  << WARNING: <40"));
echo(str("  motor-mount bolt cavity margin = ", mm_cavity_margin, " mm (need >= 3) ",
         mm_cavity_margin >= 3 ? "OK" : "  << WARNING: fastener enters the sealed cavity"));
echo(str("  pylon: ONE extrude, ", pylon_width, " wide -> flat supportless face on the bed; ",
         "prints ~", round(pylon_rise), " long x ", pad_h, " x ", pylon_width, " mm"));
foot_bolt_wall = pylon_width/2 - mm_bolt_x/2 - pylon_bolt_d/2;   // edge wall at the foot bolts
echo(str("  pylon foot bolt edge wall = ", round(10*foot_bolt_wall)/10, " mm (need >= 3) ",
         foot_bolt_wall >= 3 ? "OK" : "  << WARNING: widen pylon_width or narrow mm_bolt_x"));
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

echo("--- Task 3: cable ports (inboard +X wall, through) -------------");
echo(str("  stern port ", port_stern_d, " mm at Z=", port_stern_z,
         " (3 motor phases bundled) ; bow port ", port_bow_d, " mm at Z=", port_bow_z, " (signal)"));
echo(str("  ports at Y=", port_y, " ; gland-shoulder boss ", port_boss_t + wall, " mm proud (through-bored)"));
if (abs(port_stern_z - rod_z_stern) < (rod_boss_protrusion/2 + port_stern_d/2 + 4))
  echo("  note: stern port is close to the stern socket boss in Z -- check clearance in render");

echo("--- lid hinge (outboard -X edge, axis along the length) --------");
echo(str("  pin axis (x,y)=(", Ax, ", ", Ay, ") ; barrel d=", knuckle_d,
         " ; stack z=+/-", hinge_span/2, " over ", hinge_segs, " knuckles"));
echo(str("  housing leaf reach = ", round(1000*leaf_reach)/1000, " mm ; underside overhang ",
         hinge_arm_ang, " deg ", hinge_arm_ang <= 45 ? "OK" : " WARNING"));
if (hinge_offset < knuckle_d/2) echo("  ERROR: hinge_offset must be >= knuckle_d/2");
if (hinge_span/2 > H/2 - lug_inset) echo("  note: hinge stack runs near the lanyard-ear ends");

echo("--- lid overlap + snap locks ----------------------------------");
echo(str("  skirt ", skirt_t, " x ", ov_d, " deep over a ", step, " band ; ",
         len(lock_zs) + (n_locks>=2?1:0) + (n_locks>=3?1:0), " locks"));
echo(str("  hinge-side swing gap = ", round(1000*swing_gap)/1000, " mm ",
         swing_gap >= 0.1 ? "OK" : "  << WARNING: skirt scrapes on the swing"));
if (step >= wall - 1.0) echo("  WARNING: step band leaves < 1 mm of wall behind the dents");

echo("--- lanyard / zip-tie ears ------------------------------------");
echo(str("  4 teardrop ears at Z=+/-", lug_ez, ", protruding +/-X ; bore ", lug_hole,
         " ; teardrop apex web = ", round(100*lug_apex_web)/100, " mm ",
         lug_apex_web >= 1.2 ? "OK" : "  << WARNING: raise lug_web"));

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
//  LANYARD / ZIP-TIE EARS  (ported verbatim)
// =====================================================================
module lanyard_ear(sx, sz) {
  translate([0,0,sz*lug_ez - lug_t/2]) linear_extrude(lug_t) hull() {
    translate([sx*(W/2-3), lug_ey]) square([6, lug_d], center=true);
    translate([sx*lug_ex,  lug_ey])
      teardrop2d(d=lug_d, ang=hinge_arm_ang, cap_h=D-lug_ey);
  }
}
module lanyard_bore(sx, sz) {
  translate([sx*lug_ex, lug_ey, sz*lug_ez - lug_t/2 - eps])
    linear_extrude(lug_t + 2*eps) rotate(180) teardrop2d(d=lug_hole, ang=45);
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
  // grub screw: M3 from the top (-y) down into the bore, near the boss root
  translate([W/2 + rod_boss_protrusion*0.4, -eps, z]) rotate([-90,0,0])
    cylinder(h=rod_axis_y + rod_bore, d=rod_grub_d);
}

// =====================================================================
//  TASK 3 -- CABLE PORTS  (inboard +X wall; through, gland shoulder)
// =====================================================================
module cable_port_boss(z, dia) {   // external gland-shoulder boss
  translate([W/2-eps, port_y, z]) rotate([0,90,0])
    cylinder(h=port_boss_t+wall, d=dia+6);
}
module cable_port_cut(z, dia) {
  // through the wall AND the full gland boss (tip at X = W/2 + port_boss_t + wall)
  translate([W/2-wall-eps, port_y, z]) rotate([0,90,0])
    cylinder(h=2*wall+port_boss_t+2*eps, d=dia);
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
  // 4 M4 blind THREAD-FORMING pilot holes into the aft face; end short of the cavity
  for (sx=[-1,1], sy=[-1,1])
    translate([sx*mm_bolt_x/2, mm_pad_yc + sy*mm_bolt_y/2, mm_block_aft_z - eps])
      cylinder(h=mm_bolt_depth + eps, d=mm_bolt_pilot);
}

// =====================================================================
//  PYLON  (SEPARATE part; ONE linear_extrude -> a genuinely FLAT face on the
//  bed, supportless).  Profile is in X = fore-aft (+aft), Y = up the mast;
//  extruded along Z = width (0..pylon_width).  Printed AS MODELED (oriented()
//  is identity): the flat Z=0 face is on the bed, the mast length lies along
//  Y, and the layers (X-Y planes) run ALONG the mast -- the ~0.9 Nm root
//  bending stress runs within the layers, not across them.
// =====================================================================
module pylon_2d() {
  union() {
    square([pylon_root_t, foot_h]);                                  // foot plate (mating face X=0)
    translate([-reg_depth, (foot_h-reg_h)/2]) square([reg_depth+eps, reg_h]); // register tongue
    polygon([[0, foot_h-6], [pylon_root_t+pylon_gusset, foot_h-6],   // gusseted mast (tapered)
             [pylon_root_t, pylon_rise], [0, pylon_rise]]);
    translate([0, pylon_rise - pad_h/2]) square([pad_aft, pad_h]);   // motor pad (aft face X=pad_aft)
  }
}
module pylon() color("Tan") linear_extrude(pylon_width) pylon_2d();
module pylon_cut() {
  cz = pylon_width/2;
  // motor central bore + 2212 bolt slots in the pad aft face (axis along X = fore-aft)
  translate([pad_aft - motor_pad_t/2, pylon_rise, cz]) rotate([0,90,0]) {
    cylinder(h=pad_aft+4, d=motor_bore, center=true);
    for (p = [[motor_bolt_y/2,0],[-motor_bolt_y/2,0],[0,motor_bolt_x/2],[0,-motor_bolt_x/2]])
      hull() for (s=[-1,1])
        translate([p[0]+s*motor_slot*(p[0]==0?0:1), p[1]+s*motor_slot*(p[1]==0?0:1), 0])
          cylinder(h=pad_aft+4, d=motor_screw_d, center=true);
  }
  // 4 M4 CLEARANCE holes through the foot (along X), matching the block
  for (sy=[-1,1], sz=[-1,1])
    translate([-eps, foot_h/2 + sy*mm_bolt_y/2, cz + sz*mm_bolt_x/2]) rotate([0,90,0])
      cylinder(h=pylon_root_t+2*eps, d=pylon_bolt_d);
  // cable route: an OPEN half-groove DOWN the mast's FORWARD face (X=0, toward the
  // box / cable port) for the 3 motor leads.  The forward face is flat and untapered
  // the whole length, so the groove breaks the surface (not a sealed void like a
  // groove on the slanted aft face would be).
  translate([0, foot_h, cz]) rotate([-90,0,0])
    cylinder(h=pylon_rise - foot_h - pad_h/2, d=7);
}

// =====================================================================
//  BODY  (the shell -- one difference for all external through-features)
// =====================================================================
module body() {
  difference() {
    union() {
      rprism(W, H, D, corner_r);
      if (lanyard) for (sx=[-1,1], sz=[-1,1]) lanyard_ear(sx, sz);
      hinge_housing();                              // outboard lid hinge
      rod_boss(rod_z_bow); rod_boss(rod_z_stern);   // inboard rod-socket bosses
      cable_port_boss(port_stern_z, port_stern_d);
      cable_port_boss(port_bow_z, port_bow_d);
      motor_mount_boss();                           // stern motor pad
    }
    translate([0,-eps,0]) rprism(inner_w, inner_h, inner_d+eps, corner_r-wall); // cavity (top open)
    if (lanyard) for (sx=[-1,1], sz=[-1,1]) lanyard_bore(sx, sz);
    rod_socket_cut(rod_z_bow); rod_socket_cut(rod_z_stern);
    cable_port_cut(port_stern_z, port_stern_d);
    cable_port_cut(port_bow_z, port_bow_d);
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
module lid() {
  lid_body();
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
module ghost_float() {
  // extends aft under the prop so the disc is seen sweeping OVER the float
  aft = prop_z_offset + 25;
  color([0.95,0.95,0.85,0.3])
    translate([-W/2-8, D, -H/2-aft]) cube([W+16, float_thickness, H+aft+15]);
}
module ghost_prop_and_motor() {
  // motor + prop disc at TRUE diameter, aft of the stern, at hub height.
  // motor can is COAXIAL with the prop-disc normal (both along fore-aft Z).
  translate([0, D - pylon_rise, -H/2 - prop_z_offset]) {
    color([0.2,0.2,0.2,0.9]) translate([0,0,12])
      cylinder(h=22, d=motor_body_d, center=true);   // motor body, axis along Z (fore-aft)
    color([0.85,0.2,0.2,0.30])
      cylinder(h=1.5, d=prop_diameter, center=true); // prop disc (X-Y plane, normal = Z)
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
    rotate(a=180, v=[1,0,-1]) difference() { pylon(); pylon_cut(); }
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
  if (show_ghosts) { ghost_components(); ghost_float(); ghost_prop_and_motor(); }
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
