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
//     LATCH : the battery-case inspo closure, verbatim: the housing's
//             front band steps in (the inspo's proud inner block), the
//             door carries a thin skirt that wraps it flush with the
//             outer walls (0.1 clearance/side), and little prismoid
//             bumps on the skirt inner face click into 5 % oversized,
//             0.1 deeper dents in the band.  Locks on the right, top
//             and bottom edges; plain butt joint on the hinge side.
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
lid_t     = 3;     // door outline matches the housing exactly, like the inspo lid

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

/* [Lid overlap + snap locks] -- the inspo closure with its tolerances:
   door skirt over a stepped housing band, bump-in-dent interlocks */
ov_d          = 2.5;   // overlap depth: skirt/band engagement behind the door plane
skirt_t       = 1.1;   // door skirt thickness (inspo: wall_thickness - lid_clearance)
lid_clearance = 0.1;   // per-side skirt-to-band clearance (inspo)
n_locks       = 3;     // 1 = right edge, 2 = + top, 3 = + bottom
bump_l        = 16;    // lock bump length along the wall (inspo: case_length/3)
bump_w        = 1.0;   // bump profile width (inspo)
bump_h        = 0.3;   // bump proudness (inspo); dent = 5 % wider, 0.1 deeper
grip          = true;  // inspo-style thumb grip ridge on the right skirt face

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

lid_w = W;                   // door outline == housing outline (inspo: lid == base)
lid_h = H;
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

// lid overlap derived values
step      = skirt_t + lid_clearance;   // housing band inset from the outer walls
skirt_end = -W/2 + corner_r + 2;       // top/bottom skirt legs stop here (hinge side)
lock_y    = ov_d - 1.0;                // bump/dent center, 1 mm shy of the skirt rim (inspo)

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
echo("--- lid overlap + snap locks --------------------------------------");
echo(str("  skirt ", skirt_t, " thick x ", ov_d, " deep over a ", step,
         " step band ; clearance ", lid_clearance, "/side (inspo)"));
echo(str("  ", n_locks, " lock(s): bump ", bump_l, " x ", bump_w, " x ", bump_h,
         " proud ; cam-over ", bump_h - lid_clearance,
         " ; dent 5 % oversize, ", bump_h + 0.1, " deep (inspo)"));
if (step >= wall - 1.0)
  echo("  WARNING: step band leaves < 1 mm of wall behind the dents");
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
                      offset=hinge_offset, arm_height=0,
                      knuckle_diam=knuckle_d, gap=hinge_gap, pin_diam=pin_bore,
                      teardrop=true, inner=true, clip=lid_t, clear_top=true);
}

// =====================================================================
//  LID OVERLAP + SNAP LOCKS  (right/top/bottom edges)
//  The inspo mechanism, tolerances included: the housing's front band
//  steps in by `step` (the inspo's block standing proud of its outer
//  shell); the door skirt wraps it flush with the outer walls at 0.1
//  clearance per side.  Prismoid bumps on the skirt inner face, 1 mm
//  shy of the rim, click into 5 % oversized / 0.1 deeper dents cut in
//  the band; the skirt bows locally to cam over, like the inspo lid
//  wall.  No step or skirt on the hinge side (the swing arc would
//  bind); the door lands butt-flush there and the hinge aligns it.
// =====================================================================
// rounded prism of the stepped front cross-section: right/top/bottom
// inset by `inset`, left side bled out past the outline (open side)
module stepped_profile(inset, l) {
  r = corner_r - inset;
  hull() for (sz=[-1,1]) {
    translate([ W/2-inset-r, 0, sz*(H/2-inset-r)]) rotate([-90,0,0]) cylinder(h=l, r=r);
    translate([-W/2-8,       0, sz*(H/2-inset-r)]) rotate([-90,0,0]) cylinder(h=l, r=r);
  }
}
// cut: recess the housing's outer band behind the door plane so the
// skirt sits flush (0.3 axial slack so the panel, not the skirt tip,
// seats on the band rim -- like the inspo lid resting on the case rim)
module front_step_cut() {
  intersection() {
    difference() {
      translate([-W/2-5, -eps, -H/2-5]) cube([W+10, ov_d+0.3+eps, H+10]);
      translate([0, -2*eps, 0]) stepped_profile(step, ov_d+0.3+4*eps);
    }
    translate([skirt_end-0.5, -1, -H/2-6]) cube([W+10, ov_d+2, H+12]);
  }
}
module lock_wedge(o, dent=false) {   // inspo bump; dent -> 5 % oversize, 0.1 deeper
  s = dent ? 1.05 : 1;
  prismoid(size1=[bump_l*s, bump_w*s], size2=[bump_l*0.75*s, 0],
           h=bump_h + (dent ? 0.1 : 0), orient=o);
}
// dents in the stepped band faces (cut from the shell), one per lock
module lock_dents() {
  translate([W/2-step+eps, lock_y, 0]) lock_wedge(LEFT, dent=true);
  if (n_locks >= 2) translate([0, lock_y,  H/2-step+eps])  lock_wedge(DOWN, dent=true);
  if (n_locks >= 3) translate([0, lock_y, -(H/2-step)-eps]) lock_wedge(UP, dent=true);
}
// door skirt: C-shaped ring (open on the hinge side) wrapping the band,
// lock bumps on its inner faces, inspo grip ridge on the right face
module door_skirt() {
  intersection() {
    union() {
      difference() {
        rprism(W, H, ov_d, corner_r);                                  // outer = housing outline
        translate([0, -eps, 0]) stepped_profile(skirt_t, ov_d+3*eps);  // inner = band + clearance
      }
      translate([W/2-skirt_t+eps, lock_y, 0]) lock_wedge(LEFT);
      if (n_locks >= 2) translate([0, lock_y,  H/2-skirt_t+eps])  lock_wedge(DOWN);
      if (n_locks >= 3) translate([0, lock_y, -(H/2-skirt_t)-eps]) lock_wedge(UP);
    }
    translate([skirt_end, -1, -H/2-1]) cube([W+10, ov_d+2, H+2]);      // open the hinge side
  }
  if (grip)
    translate([W/2-eps, ov_d/2-0.05, 0])
      prismoid(size1=[bump_l, 2], size2=[bump_l*0.75, 1], shift=[0, -0.5],
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
    front_step_cut();          // stepped band the door skirt wraps
    lock_dents();              // lock dents in the band faces
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
  door_skirt();   // overlap skirt + lock bumps + grip (right/top/bottom)
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
