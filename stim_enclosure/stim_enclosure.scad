// =====================================================================
//  Chest-mounted field-stimulator enclosure  (v0.8)
//  Bare Teensy 4.1 | single KeePower 26650 cell in holder | 2x BNC
//  | trigger | 3-way toggle | LED | on/off switch | XT60 charge port
//
//  INTERIOR (stacked, all long axes = X):
//     - battery holder horizontal along the BOTTOM (cell axis = X)
//     - bare Teensy 4.1 horizontal, directly ABOVE the battery
//     - top cavity holds the door controls (toggle / LED / power)
//  The ENTIRE FRONT PANEL is a hinged, latched door.
//     HINGE : BOSL2 knuckle_hinge() on the LEFT edge, VERTICAL axis.
//             Outer half on the HOUSING, inner half on the DOOR, teardrop
//             pin bores. User threads a length of 1.75 mm filament as the
//             pin. No print-in-place, no screws.
//     LATCH : snap closure mimicking the battery-case inspo: a prismoid
//             wedge bump on a thin door flange that wraps the RIGHT wall
//             and clicks into a slightly oversized prismoid socket dent,
//             plus an inspo-style thumb grip ridge to pop it open.
//  Battery retention: printed snap features that grab the holder's side flaps.
//
//  Requires BOSL2 (../BOSL2).  Print PETG, no supports.
//  PARTS (part=): shell | lid(=door) | plug(BNC blank) | assembly(preview)
//     shell : BACK face on the bed
//     lid   : outer face down
//     plug  : flange down
// =====================================================================

include <../BOSL2/std.scad>
include <../BOSL2/hinges.scad>

/* [What to render] */
part = "assembly";   // [assembly, shell, lid, plug]
print_ready = true;
door_open   = 0;     // assembly preview only: degrees the door is swung open
show_ghosts = true;  // assembly preview: draw battery + Teensy phantoms

$fn  = 128;
eps  = 0.01;

/* [Enclosure envelope] */
inner_w  = 84;     // X interior  (holder is 81 long -> ~1.5 mm each side)
inner_h  = 100;    // Z interior  (battery + Teensy stacked + top control band)
inner_d  = 36;     // Y interior depth -- set by the 35 mm flap span (see echoes)
wall     = 2.5;
corner_r = 5;

/* [Front door] */
lid_t     = 3;
fit_clr   = 0.4;   // door-to-shell gap all round

/* [Panel cut-outs] -- measured bores */
hole_bnc     = 9.5;   // BNC panel bore (confirmed)
hole_toggle  = 12.2;
hole_power   = 12.2; // on/off switch bore (confirmed)
hole_led     = 9;    // LED bore (confirmed)
toggle_key_w = 0;
toggle_key_d = 1.5;
led_bezel_d  = 0;
led_bezel_t  = 1.0;

// Door controls live in the TOP band, clear of the battery/Teensy depth.
toggle_pos = [-20,  30];   // FRONT [x, z]
power_pos  = [ 20,  30];
led_pos    = [  0,  12];
panel_depth = 15;          // how far a switch body reaches inward (for fit checks)

/* [BNC outputs] -- one per side wall */
bnc_face    = "both";  // [both, left, right, bottom, top]
bnc_z       = 38;
bnc_x       = 0;
bnc_y       = -4;
bnc_keepout = 14;

/* [Trigger button] -- on the TOP of the shell, 45 deg guard collar */
button_top    = [22, 0];
hole_button   = 12;
button_body_d = 14;
button_guard  = false;     // 45 deg finger-guard collar (removed -- plain hole)
guard_t       = 2;
guard_h       = 3;

/* [Panel engraving] */
engrave    = true;
engrave_d  = 0.6;
label_size = 3.5;
labels = [ ["CAL", -32, 40, 0], ["VOL", -32, 30, 0], ["LOC", -32, 20, 0],
           ["TRIG", 0, 22, 0],
           ["ON", 31, 36, 0], ["OFF", 31, 24, 0] ];

/* [Lanyard eyes] -- 4 corners, VERTICAL 5 mm bores */
lanyard   = true;
lug_hole  = 5;
lug_web   = 3;
lug_out   = 5;
lug_t     = 8;
lug_inset = 12;

/* [Knuckle hinge] -- BOSL2, LEFT edge, vertical axis, 1.75 mm filament pin */
hinge_segs   = 5;      // total knuckles (odd -> housing gets the two ends)
hinge_span   = 80;     // Z span of the knuckle stack
hinge_gap    = 0.3;    // Z clearance between adjacent knuckles (rotation)
knuckle_d    = 6;      // hinge barrel outer diameter
hinge_offset = 4;      // pin axis standoff from the left wall face (>= knuckle_d/2)
hinge_arm_h  = 1;      // housing-side straight arm height (inspo look)
pin_d        = 1.75;   // filament pin nominal
pin_clr      = 0.5;    // added to pin bore

/* [Snap latch] -- inspo-style prismoid wedge + socket dent, RIGHT edge */
latch_z      = 0;      // Z center of the latch (keep clear of the BNC at z=38)
latch_len    = 34;     // Z length of the door flange (~lid_h/3, like the inspo)
flange_reach = 10;     // how far the flange wraps past the door plane (+Y)
flange_t     = 1.6;    // flange thickness in X (flex wall, like the inspo lid wall)
flange_clr   = 0.2;    // flange inner face to shell wall clearance
bump_len     = 26;     // wedge bump length along Z
bump_w       = 1.8;    // wedge bump width along Y (both faces are cam ramps)
bump_h       = 0.55;   // wedge bump proudness; catch depth = bump_h - flange_clr

/* [Battery holder] -- single-cell 26650, horizontal, cell axis = X.
   Sits with its FLAT SIDE against the BACK (chest) wall, bottom on the floor,
   GLUED in place. Perpendicular-to-backplate depth needs the cavity >= ~27 mm.  */
hold_len    = 81;    // X (incl. solder flags)
hold_depth  = 26.5;  // Y from the backplate toward the lid (cavity inner_d must exceed this)
hold_height = 28.5;  // Z, floor to top of the holder body

/* [Teensy 4.1 phantom] -- no mount; the packed interior holds it */
teensy_len = 61;     // X
teensy_wid = 17.8;   // Z
teensy_stk = 6;      // Y stack height (board + tallest parts)
teensy_gap = 2.5;    // Z gap above the battery

/* [XT60 charge port] -- female XT60E-F panel mount. MEASURE the real part. */
xt60          = true;
xt60_face     = "left";    // [bottom, left, right, back, none]  on the hinge side, clear of the latch
xt60_body     = [16, 8.5]; // body cutout W x H  (XT60E-F ~15.6 x 8.1, +clearance)
xt60_screw_d  = 3.2;       // M3 clearance
xt60_screw_sep= 25;        // XT60E-F current version (older version = 23.4)
xt60_pos      = 10;        // position along the face (X on bottom/back, Z on a side)
xt60_body_depth = 12;      // how far the connector body reaches inward (collision check)

/* [Wire routing] */
loom_slot = [10, 8];   // W x H slot near the hinge for the control loom

screw_pilot_d = 2.6;   // (kept for the plug)

// =====================================================================
//  DERIVED
// =====================================================================
W = inner_w + 2*wall;
H = inner_h + 2*wall;
D = inner_d + wall;          // SHELL depth only; the door sits PROUD in front (Y<0)

lid_w = inner_w + 2*wall - 2*fit_clr;
lid_h = inner_h + 2*wall - 2*fit_clr;
lid_r = corner_r;

floor_z       = -inner_h/2;
front_inner_y = 0;                         // front opening plane (door lands here)
back_inner_y  = inner_d;
body_front_y  = back_inner_y - hold_depth; // holder front face (toward the lid)
hold_yc       = (body_front_y + back_inner_y)/2;
battery_top_z = floor_z + hold_height;
teensy_bot_z  = battery_top_z + teensy_gap;
teensy_top_z  = teensy_bot_z + teensy_wid;

// hinge axis (vertical, just outside the front-left corner)
Ax = -(W/2) - hinge_offset;
Ay = 0;                                     // at the front-face plane
pin_bore = pin_d + pin_clr;

// latch derived values
flange_x = W/2 + flange_clr;                // flange inner face
bump_y   = flange_reach - 2.5;              // wedge center behind the door plane

lug_d  = lug_hole + 2*lug_web;
lug_ex = W/2 + lug_out;
lug_ez = H/2 - lug_inset;
lug_ey = D - lug_d/2;

cs_depth = 1.6;

// =====================================================================
//  ECHO FIT-CHECK REPORT  (this is how correctness is verified)
// =====================================================================
echo(str("OUTER  W x H x D = ", W, " x ", H, " x ", D, " mm",
         "   (+lugs: ", W + 2*(lug_out + lug_hole/2 + lug_web), " mm wide)"));
echo(str("INNER  w x h x d = ", inner_w, " x ", inner_h, " x ", inner_d, " mm"));
echo("--- battery holder (flat side on the back/chest wall) -------------");
echo(str("  holder X gap each side = ", (inner_w - hold_len)/2, " mm"));
echo(str("  holder depth (Y) = ", hold_depth, " ; cavity depth = ", inner_d,
         "  (need >= 27)", inner_d < 27 ? "  WARNING: too shallow" : "  OK"));
echo(str("  holder body Y span = [", body_front_y, ", ", back_inner_y,
         "]  front clr to lid plane = ", body_front_y - front_inner_y, " mm"));
echo(str("  holder height (Z) = ", hold_height, " ; top z = ", battery_top_z, "  (glued in)"));
if (battery_top_z > inner_h/2) echo("  WARNING: battery taller than the cavity");
echo("--- Teensy (phantom, no mount) -----------------------------------");
echo(str("  Teensy z span = [", teensy_bot_z, ", ", teensy_top_z, "]  (top wall ", inner_h/2, ")"));
echo(str("  Teensy X span = [", -teensy_len/2, ", ", teensy_len/2, "]  (inner +/-", inner_w/2, ")"));
if (teensy_top_z > inner_h/2) echo("  WARNING: Teensy runs past the top wall");
echo("--- door controls vs interior depth (need ", panel_depth, " mm) -------");
for (c = [["toggle", toggle_pos], ["power", power_pos], ["led", led_pos]]) {
  over_batt   = c[1][1] - (c[1][1] < battery_top_z ? 0 : 999) < battery_top_z; // crude
  clash = c[1][1] - 6 < teensy_top_z;   // control lower edge dips into Teensy band?
  echo(str("  ", c[0], " at ", c[1],
           clash ? "  << WARNING: body may reach the Teensy band" : "  (clear top band)"));
}
echo("--- BNC ----------------------------------------------------------");
echo(str("  BNC at z = ", bnc_z, "  (battery top ", battery_top_z, ", top wall ", inner_h/2, ")"));
if (bnc_z - bnc_keepout/2 < battery_top_z) echo("  note: BNC body dips toward the battery band");
echo("--- XT60 ---------------------------------------------------------");
if (xt60 && xt60_face!="none") {
  echo(str("  XT60 on ", xt60_face, " face; body reaches ", xt60_body_depth, " mm inward"));
  if (xt60_face=="bottom") {
    if (floor_z + xt60_body_depth > floor_z && battery_top_z > floor_z)
      echo("  WARNING: bottom XT60 collides with the battery holder (holder fills the floor)");
  } else if (xt60_face=="left" || xt60_face=="right") {
    inner_reach = W/2 - wall - xt60_body_depth;   // X the body reaches to (from the wall)
    echo(str("  side XT60 at z=", xt60_pos, "; body inner edge x=|", inner_reach,
             "|  (Teensy X half-span ", teensy_len/2, ")"));
    if (xt60_pos - xt60_body[1]/2 < battery_top_z)
      echo("  WARNING: side XT60 dips into the battery band -- raise xt60_pos");
    if (inner_reach < teensy_len/2 &&
        (xt60_pos - xt60_body[1]/2) < teensy_top_z && (xt60_pos + xt60_body[1]/2) > teensy_bot_z)
      echo("  WARNING: side XT60 body may hit the Teensy -- move xt60_pos above ", teensy_top_z);
    if (abs(xt60_pos - bnc_z) < (xt60_body[1]/2 + hole_bnc/2 + 3))
      echo("  note: side XT60 is close to the BNC at that z");
  } else if (xt60_face=="back") {
    echo("  note: back face is the chest side -- awkward for plugging a charger");
  }
}
echo("--- knuckle hinge (BOSL2, left edge) ------------------------------");
echo(str("  pin axis (x,y) = (", Ax, ", ", Ay, ") ; barrel d=", knuckle_d,
         " ; pin bore=", pin_bore, " (teardrop)"));
echo(str("  barrel inner edge x = ", Ax + knuckle_d/2, "  (left wall ", -W/2,
         ", door edge ", -lid_w/2, ")"));
if (hinge_offset < knuckle_d/2) echo("  ERROR: hinge_offset must be >= knuckle_d/2");
echo(str("  housing leaf reach along left wall y = ",
         hinge_arm_h + hinge_offset + knuckle_d/(2*sin(45)),
         " mm  (XT60 body window starts y~11)"));
echo("--- snap latch (right edge) ---------------------------------------");
echo(str("  catch depth (bump_h - flange_clr) = ", bump_h - flange_clr,
         " mm ; flange cam strain ~ ",
         round(1000*1.5*flange_t*(bump_h - flange_clr)/(bump_y*bump_y))/10,
         " %  (PETG ok < ~1.5)  (tune on calibration print)"));
if (latch_z + latch_len/2 > bnc_z - bnc_keepout/2)
  echo("  WARNING: latch flange runs into the right-wall BNC keepout");
echo("------------------------------------------------------------------");

// =====================================================================
//  HELPERS
// =====================================================================
module rprism(w, h, d, r) {
  hull() for (sx=[-1,1], sz=[-1,1]) translate([sx*(w/2-r), 0, sz*(h/2-r)])
    rotate([-90,0,0]) cylinder(h=d, r=r);
}
module post(x, z, h, d) { translate([x, D-wall, z]) rotate([90,0,0]) cylinder(h=h, d=d); }
module face_text(t, x, z, size, rot=0) {
  translate([x, -lid_t+engrave_d, z]) rotate([90,0,0])
    linear_extrude(engrave_d+eps) rotate(-rot)
      text(t, size=size, halign="center", valign="center", font="Liberation Sans:style=Bold");
}

// =====================================================================
//  LANYARD
// =====================================================================
module lanyard_ear(sx, sz) {
  translate([0,0,sz*lug_ez - lug_t/2]) linear_extrude(lug_t) hull() {
    translate([sx*(W/2-3), lug_ey]) square([6, lug_d], center=true);
    translate([sx*lug_ex,  lug_ey]) circle(d=lug_hole+2*lug_web);
  }
}
module lanyard_bore(sx, sz) {
  translate([sx*lug_ex, lug_ey, sz*lug_ez - lug_t/2 - eps]) cylinder(h=lug_t+2*eps, d=lug_hole);
}

// =====================================================================
//  BNC + PLUG
// =====================================================================
module bnc_side(sx) {
  translate([sx*(W/2-wall) - eps*sx, D/2+bnc_y, bnc_z]) rotate([0, sx*90, 0])
    cylinder(h=wall+2*eps, d=hole_bnc);
}
module bnc_cut() {
  if (bnc_face=="both") { bnc_side(-1); bnc_side(1); }
  else if (bnc_face=="left")   bnc_side(-1);
  else if (bnc_face=="right")  bnc_side(1);
  else if (bnc_face=="bottom") translate([bnc_x, D/2+bnc_y, -H/2-eps]) cylinder(h=wall+2*eps, d=hole_bnc);
  else if (bnc_face=="top")    translate([bnc_x, D/2+bnc_y, H/2-wall-eps]) cylinder(h=wall+2*eps, d=hole_bnc);
}
module blank_plug() {
  cylinder(h=2, d=hole_bnc+6);
  translate([0,0,2-eps]) cylinder(h=wall+1.5, d=hole_bnc-0.3);
}

// =====================================================================
//  XT60 CHARGE PORT  (parametric, any face)
// =====================================================================
module xt60_cut() {
  if (xt60 && xt60_face!="none") {
    bw = xt60_body[0]; bh = xt60_body[1];
    if (xt60_face=="bottom") {
      translate([xt60_pos, D/2+bnc_y, -H/2-eps]) {
        cube([bw, bh, wall+2*eps], center=true);
        for (s=[-1,1]) translate([s*xt60_screw_sep/2, 0, 0])
          cylinder(h=wall+2*eps, d=xt60_screw_d, center=true);
      }
    } else if (xt60_face=="left" || xt60_face=="right") {
      sx = (xt60_face=="right") ? 1 : -1;
      translate([sx*(W/2-wall/2), D/2+bnc_y, xt60_pos]) rotate([0,sx*90,0]) {
        cube([bw, bh, wall+2*eps], center=true);
        for (s=[-1,1]) translate([s*xt60_screw_sep/2, 0, 0])
          cylinder(h=wall+2*eps, d=xt60_screw_d, center=true);
      }
    } else if (xt60_face=="back") {
      translate([xt60_pos, D-wall/2, 0]) rotate([90,0,0]) {
        cube([bw, bh, wall+2*eps], center=true);
        for (s=[-1,1]) translate([s*xt60_screw_sep/2, 0, 0])
          cylinder(h=wall+2*eps, d=xt60_screw_d, center=true);
      }
    }
  }
}

// =====================================================================
//  BATTERY  -- holder is GLUED to the floor/backplate (no printed retention).
//  Sits flat side against the backplate; cavity depth (36) > holder depth (26.5).
// =====================================================================

// =====================================================================
//  KNUCKLE HINGE  (BOSL2, left edge, vertical axis, filament pin)
//  Mounted exactly like the inspo battery case: each half hangs off the
//  wall next to the joint edge via position()+orient().  The housing gets
//  the outer half (both end knuckles), the door the inner half.  Both
//  halves put the pin axis at (Ax, 0) so they interleave coaxially.
// =====================================================================
module hinge_housing() {
  // proxy strip coincident with the left wall; the hinge hangs off its
  // front-left edge with the leaf hugging the wall exterior (+Y)
  translate([-W/2 + wall/2, D/2, 0])
    cuboid([wall, D, hinge_span + 4])
      position(FRONT+LEFT) orient(anchor=LEFT, spin=180)
        knuckle_hinge(length=hinge_span, segs=hinge_segs, offset=hinge_offset,
                      arm_height=hinge_arm_h, knuckle_diam=knuckle_d,
                      gap=hinge_gap, pin_diam=pin_bore, teardrop=true,
                      round_bot=1.0);
}
module hinge_door() {
  // proxy strip coincident with the door's left edge band; the inner hinge
  // half hangs off its back-left edge, leaf clipped flush with the door front
  translate([-lid_w/2 + 1.5, -lid_t/2, 0])
    cuboid([3, lid_t, hinge_span + 4])
      position(BACK+LEFT) orient(anchor=LEFT, spin=0)
        knuckle_hinge(length=hinge_span, segs=hinge_segs,
                      offset=hinge_offset + fit_clr, arm_height=0,
                      knuckle_diam=knuckle_d, gap=hinge_gap, pin_diam=pin_bore,
                      teardrop=true, inner=true, clip=lid_t, clear_top=true);
}

// =====================================================================
//  SNAP LATCH  (right edge)
//  Straight from the inspo: a prismoid wedge bump on a thin flexing wall
//  seats into a 5 % oversized, slightly deeper prismoid dent.  Both wedge
//  faces are shallow ramps, so the door cams shut and pops open again.
// =====================================================================
module latch_wedge(s=1, h=bump_h) {   // wedge pointing LEFT (-X)
  prismoid(size1=[bump_len*s, bump_w*s], size2=[bump_len*0.75*s, 0],
           h=h, orient=LEFT);
}
// socket dent in the right wall exterior (cut from the shell)
module latch_socket() {
  translate([W/2 + 0.01, bump_y, latch_z]) latch_wedge(s=1.05, h=bump_h+0.11);
}
// door side: root block, flexing flange along the wall, wedge bump, grip
module latch_door() {
  // root block bridging the door edge to the flange, proud like the door
  translate([lid_w/2 - 2, -lid_t, latch_z - latch_len/2])
    cube([(flange_x + flange_t) - (lid_w/2 - 2), lid_t, latch_len]);
  // flexing flange wrapping the right wall (the inspo's thin lid wall)
  translate([flange_x, 0, latch_z - latch_len/2])
    cube([flange_t, flange_reach, latch_len]);
  // wedge bump on the flange inner face
  translate([flange_x + eps, bump_y, latch_z]) latch_wedge();
  // thumb grip ridge on the flange outer face (inspo-style pry tab)
  translate([flange_x + flange_t - eps, bump_y, latch_z])
    prismoid(size1=[bump_len, 2], size2=[bump_len*0.75, 1], shift=[0, -0.5],
             h=1.5, orient=RIGHT);
}

// =====================================================================
//  SHELL
// =====================================================================
module shell() {
  // hollow shell + ALL through-holes in ONE difference (external features only)
  difference() {
    union() {
      rprism(W, H, D, corner_r);
      if (button_guard)
        translate([button_top[0], D/2+button_top[1], H/2-eps])
          cylinder(h=guard_h+eps, d1=hole_button+2*guard_t+2*guard_h, d2=hole_button+2*guard_t);
      if (lanyard) for (sx=[-1,1], sz=[-1,1]) lanyard_ear(sx, sz);
      hinge_housing();         // knuckle hinge, outer half (external, left)
    }
    translate([0,-eps,0]) rprism(inner_w, inner_h, inner_d+eps, corner_r-wall);  // cavity (front open)
    bnc_cut();
    translate([button_top[0], D/2+button_top[1], H/2-wall-eps])
      cylinder(h=wall+guard_h+2*eps, d=hole_button);
    if (lanyard) for (sx=[-1,1], sz=[-1,1]) lanyard_bore(sx, sz);
    translate([-inner_w/2+loom_slot[0]/2, loom_slot[1]/2+2, 0])   // loom slot (near front opening)
      cube([loom_slot[0], loom_slot[1], 2*wall+eps], center=true);
    xt60_cut();
    latch_socket();            // latch dent in the right wall exterior
  }
  // (battery holder is glued in — no printed retention features)
}

// =====================================================================
//  DOOR (front panel)
// =====================================================================
module lid_body() {
  // door panel sits PROUD in front of the opening: Y in [-lid_t, 0]
  difference() {
    translate([0,-lid_t,0]) rprism(lid_w, lid_h, lid_t, lid_r);
    // control bores run through the whole panel thickness (Y from -lid_t-eps to +eps)
    translate([toggle_pos[0], -lid_t-eps, toggle_pos[1]]) rotate([-90,0,0]) {
      cylinder(h=lid_t+2*eps, d=hole_toggle);
      if (toggle_key_w>0) translate([-toggle_key_w/2, hole_toggle/2-eps, 0])
        cube([toggle_key_w, toggle_key_d+eps, lid_t+2*eps]);
    }
    translate([led_pos[0], -lid_t-eps, led_pos[1]]) rotate([-90,0,0]) {
      cylinder(h=lid_t+2*eps, d=hole_led);
      if (led_bezel_d>0) translate([0,0,eps]) cylinder(h=led_bezel_t+eps, d=led_bezel_d);
    }
    translate([power_pos[0], -lid_t-eps, power_pos[1]]) rotate([-90,0,0]) cylinder(h=lid_t+2*eps, d=hole_power);
    if (engrave) for (l=labels) face_text(l[0], l[1], l[2], label_size, len(l)>3 ? l[3] : 0);
  }
}
module lid() {
  lid_body();
  hinge_door();   // knuckle hinge, inner half (external, left)
  latch_door();   // snap flange + wedge bump + grip (external, right)
}

// =====================================================================
//  PHANTOMS (assembly preview only)
// =====================================================================
module ghost_battery() {
  // holder+cell envelope, flat side glued to the backplate
  color([0.4,0.7,0.4,0.35]) translate([-hold_len/2, body_front_y, floor_z])
    cube([hold_len, hold_depth, hold_height]);
}
module ghost_teensy() {
  color([0.2,0.4,0.8,0.45]) translate([-teensy_len/2, hold_yc-teensy_stk/2, teensy_bot_z])
    cube([teensy_len, teensy_stk, teensy_wid]);
}

// =====================================================================
//  ORIENTATION / OUTPUT
// =====================================================================
module oriented(p) {
  if (!print_ready) children();
  else if (p=="shell") translate([0,0,D]) rotate([-90,0,0]) children();
  else if (p=="lid")   translate([0,0,lid_t]) rotate([90,0,0]) children();
  else children();
}

if (part=="assembly") {
  color("SteelBlue") shell();
  // door swings about the vertical hinge axis at (Ax, Ay)
  translate([Ax, Ay, 0]) rotate([0,0,-door_open]) translate([-Ax,-Ay,0])
    color("Gainsboro") lid();
  if (show_ghosts) { ghost_battery(); ghost_teensy(); }
}
else if (part=="shell") oriented("shell") shell();
else if (part=="lid")   oriented("lid")   lid();
else if (part=="plug")  blank_plug();
