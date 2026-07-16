// =====================================================================
//  Chest-mounted field-stimulator enclosure  (v0.9)
//  Bare Teensy 4.1 | single KeePower 26650 cell in holder | 2x BNC
//  | 4 playback buttons (CAL/LOC/VOL/L+V) | LED + on/off on top
//  | XT60 charge port
//
//  INTERIOR (stacked, all long axes = X):
//     - battery holder horizontal along the BOTTOM (cell axis = X)
//     - bare Teensy 4.1 horizontal, directly ABOVE the battery
//     - top cavity holds the button bodies (door) + power/LED (top)
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
//             0.1 deeper dents in the band.  Two locks on the long
//             right edge plus one top and one bottom.  The skirt runs
//             FULL DEPTH around the whole perimeter, hinge side and
//             corners included: the pin axis sits at mid-overlap depth
//             (Ay = ov_d/2) and stands farther off the wall, and the
//             hinge-side band is cut a touch looser, so the closing
//             arc clears without any relief carving; only the knuckle
//             span itself is windowed out.
//  Battery retention: printed snap features that grab the holder's side flaps.
//
//  Requires BOSL2 (../BOSL2).  Print PLA, no supports.
//  PARTS (part=): shell | lid(=door) | plug(BNC blank) | assembly(preview)
//     shell : BACK face on the bed
//     lid   : outer face down
//     plug  : flange down
// =====================================================================

include <../BOSL2/std.scad>
include <../BOSL2/hinges.scad>

/* [What to render] */
part = "shell";   // [assembly, shell, lid, plug]
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
hole_power   = 12.2;  // on/off switch bore (confirmed)
hole_led     = 9;     // LED bore (confirmed)

/* [Playback buttons] -- 4 momentary buttons in ONE ROW on the door:
   CAL | LOC | VOL | L+V.  Full sequence = L+V, deconstruction = LOC, VOL.
   Bodies live in the top interior band, clear of the Teensy/battery. */
btn_d       = 12;     // panel bore, same as the old trigger (confirmed)
btn_body_d  = 14;     // button body diameter (fit checks)
btn_row_z   = 20;     // Z of the button row (above the Teensy band)
btn_pitch   = 20;     // X spacing between buttons
btn_names   = ["CAL", "LOC", "VOL", "L+V"];
panel_depth = 15;     // how far a button body reaches inward (for fit checks)

/* [Top controls] -- on/off switch and LED on the TOP face, one per side */
power_top = [ 22, 0];  // [x, y-offset from the top-face center]
led_top   = [-22, 0];

/* [BNC outputs] -- one per side wall */
bnc_face    = "both";  // [both, left, right, bottom, top]
bnc_z       = 38;
bnc_x       = 0;
bnc_y       = -4;
bnc_keepout = 14;

/* [Panel engraving] -- one label above each playback button */
engrave    = true;
engrave_d  = 0.6;
label_size = 3.5;
labels = [ for (i = [0:3]) [btn_names[i], (i-1.5)*btn_pitch, btn_row_z+9.5, 0] ];

/* [Lanyard eyes] -- 4 corners, VERTICAL 5 mm bores */
lanyard   = true;
lug_hole  = 5;
lug_web   = 3;
lug_out   = 5;
lug_t     = 8;
lug_inset = 12;

/* [Knuckle hinge] -- BOSL2, LEFT edge, vertical axis, 1.75 mm filament pin */
hinge_segs   = 5;      // total knuckles (odd -> housing gets the two ends)
hinge_span   = 56;     // Z span of the knuckle stack (ends 2.5 mm shy of the
                       // left BNC nut zone at z = bnc_z - 7.5)
hinge_gap    = 0.3;    // Z clearance between adjacent knuckles (rotation)
knuckle_d    = 6;      // hinge barrel outer diameter
hinge_offset = 7;      // pin axis standoff from the left wall face
                       // (>= knuckle_d/2).  Deliberately large: together
                       // with the mid-depth pin (Ay = ov_d/2) it lets the
                       // full-depth door skirt swing past the hinge-side
                       // band -- see the swing-gap echo
hinge_arm_h  = 1;      // housing-side straight arm height (inspo look)
hinge_round_bot = 0.5; // leaf-to-wall fillet (BOSL2 round_bot flare).  Its
                       // thin tail hugs the wall for ~4.4x this length past
                       // the leaf underside plane -- keep small so the leaf
                       // stays clear of the XT60 flange seat
hinge_arm_ang = 35;    // housing leaf angle == underside print overhang from
                       // vertical (BOSL2 keeps the underside parallel to the
                       // arm skeleton).  Smaller = shallower but longer leaf;
                       // 35 is comfortable supportless PLA, and below ~35 the
                       // knuckle barrels dominate print quality anyway.  The
                       // longer reach clears the XT60 flange because the port
                       // moved toward the backplate (xt60_y, see echoes)
pin_d        = 1.75;   // filament pin nominal
pin_clr      = 0.5;    // added to pin bore

/* [Lid overlap + snap locks] -- the inspo closure with its tolerances:
   door skirt over a stepped housing band, bump-in-dent interlocks */
ov_d          = 3.0;   // overlap depth: skirt/band engagement behind the door
                       // plane (bump lever = ov_d-1; keep >= 3 so the PLA
                       // skirt still cams over gently)
skirt_t       = 1.1;   // door skirt thickness (inspo: wall_thickness - lid_clearance)
lid_clearance = 0.1;   // per-side skirt-to-band clearance (inspo)
lid_clearance_left = 0.25;  // hinge-side skirt-to-band clearance.  Looser
                            // than the inspo 0.1 so the full-depth skirt's
                            // corner sagitta clears on the swing; invisible
                            // in use -- the knuckles, not the skirt fit,
                            // locate the door's hinge edge
lock_zs       = [24, -24];  // Z centers of the RIGHT-edge locks (the long free
                            // edge fits 2-3; two for now)
n_locks       = 3;     // 1 = right edge (lock_zs), 2 = + top, 3 = + bottom
bump_l        = 16;    // lock bump length along the wall (inspo: case_length/3)
bump_w        = 1.0;   // bump profile width (inspo)
bump_h        = 0.25;  // bump proudness (inspo 0.3, softened for PLA);
                       // dent = 5 % wider, 0.1 deeper
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
xt60_y        = 9;         // Y offset from mid-depth, toward the backplate; 9
                           // keeps the flange seat clear of the 35-deg leaf,
                           // which reaches farther now that the pin stands
                           // hinge_offset = 7 off the wall (see echoes).
                           // Budget runs to ~12 before the flange hits the
                           // back edge (the BNC keeps its own bnc_y -- the
                           // lanyard lug blocks moving it back)
xt60_flange_h = 14;        // flange height across the screw axis (fit check)
xt60_body_depth = 12;      // how far the connector body reaches inward (collision check)

/* [Wire routing] */
loom_slot = [10, 8];   // W x H slot near the hinge for the control loom

/* [BNC blank plug] -- snap-in: hollow slotted stem forms two sprung
   prongs; a barb ring (interrupted by the slot -> two catch nubs)
   clicks in behind the wall's inner face */
plug_flange_t = 2;     // flange disc thickness
plug_clr      = 0.3;   // stem-to-bore diametral clearance
plug_nub      = 0.35;  // barb radial proudness (snap = 2*nub - clr per diameter)
plug_nub_clr  = 0.15;  // axial slack behind the inner wall face
plug_slot     = 1.4;   // flex slot width through the stem tip
plug_bore     = 6.2;   // blind core diameter (thins the prongs so they flex)

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
Ay = ov_d/2;   // pin axis at MID-OVERLAP depth: with the axis centered in
               // the skirt's depth, the skirt face's worst swing radius
               // exceeds its seated distance only by the sagitta of ov_d/2
               // (not ov_d) -- this is what makes a full-depth hinge-side
               // skirt swing clear at a modest hinge_offset
pin_bore = pin_d + pin_clr;

// lid overlap derived values
step      = skirt_t + lid_clearance;        // band inset, right/top/bottom
step_left = skirt_t + lid_clearance_left;   // band inset, hinge side
lock_y    = ov_d - 1.0;                // bump/dent center, 1 mm shy of the skirt rim (inspo)
// hinge-side full overlap: the skirt is a plain full-depth ring all the way
// around.  It swings clear of the band because (a) the pin axis sits at
// mid-overlap depth (Ay), so the skirt face's worst radius is
// sqrt(dx^2 + (ov_d/2)^2) instead of sqrt(dx^2 + ov_d^2), and (b) the left
// band face gives lid_clearance_left.  swing_gap below is the guaranteed
// minimum skirt-to-band gap at any point of the swing (worst at the skirt
// tip corners on the straight left edge; the corner arcs are strictly
// better).  Only the knuckle span itself is windowed out of the skirt.
hinge_win_z = hinge_span/2 + 1;   // skirt window half-height over the knuckles
swing_gap = hinge_offset + skirt_t + lid_clearance_left
          - sqrt(pow(hinge_offset + skirt_t, 2) + pow(ov_d/2, 2));

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
echo("--- playback buttons (door) vs interior (need ", panel_depth, " mm) ----");
for (i = [0:3]) {
  bx = (i-1.5)*btn_pitch;
  clash = btn_row_z - btn_body_d/2 < teensy_top_z;   // body lower edge in Teensy band?
  echo(str("  ", btn_names[i], " at [", bx, ", ", btn_row_z, "]",
           clash ? "  << WARNING: body may reach the Teensy band" : "  (clear top band)"));
}
if (btn_pitch < btn_body_d + 2)
  echo("  WARNING: button bodies closer than 2 mm -- widen btn_pitch");
if (btn_row_z + btn_body_d/2 > bnc_z - bnc_keepout/2)
  echo("  note: outer button bodies reach the side-wall BNC body band");
echo(str("  row span x = [", -1.5*btn_pitch - btn_d/2, ", ", 1.5*btn_pitch + btn_d/2,
         "]  (cavity +/-", inner_w/2, ")"));
echo("--- top controls (power switch + LED) ------------------------------");
echo(str("  power at x=", power_top[0], " (old trigger spot), LED at x=", led_top[0],
         " ; bodies reach down to z~", inner_h/2 - panel_depth));
if (abs(bnc_z - inner_h/2) < panel_depth + bnc_keepout/2)
  echo("  note: top-control bodies share the corner zone with the BNC bodies -- checked OK for the trigger before");
echo("--- BNC ----------------------------------------------------------");
echo(str("  BNC at z = ", bnc_z, "  (battery top ", battery_top_z, ", top wall ", inner_h/2, ")"));
if (bnc_z - bnc_keepout/2 < battery_top_z) echo("  note: BNC body dips toward the battery band");
echo(str("  blank plug: snap interference ", 2*plug_nub - plug_clr,
         " on the bore ; prong strain ~ ",
         round(1000*1.5*((hole_bnc-plug_clr-plug_bore)/2)*(plug_nub-plug_clr/2)
               / pow(plug_flange_t + wall + plug_nub_clr - 0.8, 2))/10,
         " %  (PLA ok < ~3-4 one-shot)"));
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
    echo(str("  side XT60 y-center = ", D/2 + xt60_y, " ; flange front edge y = ",
             D/2 + xt60_y - xt60_flange_h/2, "  (hinge leaf ends y = ", leaf_reach, ")"));
    // 0.5 margin: leaf_reach's flare term is itself ~0.3 conservative
    if (xt60_face=="left" && D/2 + xt60_y - xt60_flange_h/2 < leaf_reach + 0.5)
      echo("  WARNING: XT60 flange lands on the hinge leaf -- raise xt60_y");
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
leaf_reach = Ay + hinge_arm_h + hinge_offset/tan(hinge_arm_ang)
           + knuckle_d/(2*sin(hinge_arm_ang))
           + 1.7*hinge_round_bot/tan(hinge_arm_ang/2);
           // Ay: the whole housing half mounts at the mid-depth pin plane.
           // Last term: fillet flare tail along the wall, slightly
           // conservative fit to STL measurements: 4.0x cut at 45 deg arm
           // angle, 5.1x at 35
echo(str("  housing leaf reach along left wall y = ", leaf_reach,
         " mm ; knuckle stack z = +/-", hinge_span/2));
echo(str("  housing leaf underside overhang = ", hinge_arm_ang,
         " deg from vertical, STL-verified == arm_angle",
         " (shell prints back face down; keep <= ~45)"));
if (hinge_arm_ang > 45)
  echo("  WARNING: hinge leaf underside too steep to print -- lower hinge_arm_ang");
if (hinge_span/2 > bnc_z - 7.5 - 1)   // d15 BNC nut needs flat wall
  echo("  WARNING: hinge leaf runs into the left BNC nut zone -- shorten hinge_span");
if (leaf_reach > D/2 + xt60_y - 10.5/2 - 1)   // XT60 plug housing envelope
  echo("  WARNING: hinge leaf reaches the XT60 plug envelope -- steepen hinge_arm_ang");
echo("--- lid overlap + snap locks --------------------------------------");
echo(str("  skirt ", skirt_t, " thick x ", ov_d, " deep over a ", step,
         " step band ; clearance ", lid_clearance, "/side (inspo)"));
echo(str("  ", len(lock_zs) + (n_locks>=2?1:0) + (n_locks>=3?1:0),
         " locks (right z=", lock_zs, (n_locks>=2?" + top":""), (n_locks>=3?" + bottom":""),
         "): bump ", bump_l, " x ", bump_w, " x ", bump_h,
         " proud ; cam-over ", bump_h - lid_clearance,
         " ; dent 5 % oversize, ", bump_h + 0.1, " deep (inspo)"));
if (step >= wall - 1.0)
  echo("  WARNING: step band leaves < 1 mm of wall behind the dents");
echo(str("  hinge-side skirt: full ", ov_d, " deep, windowed z +/-", hinge_win_z,
         " over the knuckles ; left clearance ", lid_clearance_left,
         " ; guaranteed min swing gap = ", round(1000*swing_gap)/1000, " mm"));
if (swing_gap < 0.1)
  echo("  WARNING: hinge-side skirt scrapes on the swing -- raise hinge_offset or lid_clearance_left");
if (hinge_win_z >= H/2 - corner_r)
  echo("  WARNING: knuckle window runs into the corner arcs (hinge_span too long)");
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
// Snap-in blanking plug: flange + slotted hollow stem.  The barb ring
// sits just behind the wall's inner face; the slot interrupts it into
// two catch nubs and lets the prongs squeeze together on insertion.
// Insertion ramp is shallow (~16 deg), removal cam steep (~40 deg):
// clicks in, holds, but a firm pull still gets it back out.
module blank_plug() {
  stem_d = hole_bnc - plug_clr;
  nub_z  = plug_flange_t + wall + plug_nub_clr;   // barb crest = inner face + slack
  difference() {
    union() {
      cylinder(h=plug_flange_t, d=hole_bnc+6);                    // flange disc
      cylinder(h=nub_z+eps, d=stem_d);                            // stem through the bore
      translate([0,0,nub_z-0.4])                                  // removal cam (catch)
        cylinder(h=0.4, d1=stem_d, d2=stem_d+2*plug_nub);
      translate([0,0,nub_z-eps])                                  // insertion ramp / tip
        cylinder(h=1.2, d1=stem_d+2*plug_nub, d2=stem_d-0.6);
    }
    translate([0,0,0.8]) cylinder(h=nub_z+2, d=plug_bore);        // blind core
    translate([-plug_slot/2, -hole_bnc/2-4, 0.8])                 // flex slot
      cube([plug_slot, hole_bnc+8, nub_z+2]);
  }
}

// =====================================================================
//  XT60 CHARGE PORT  (parametric, any face)
// =====================================================================
module xt60_cut() {
  if (xt60 && xt60_face!="none") {
    bw = xt60_body[0]; bh = xt60_body[1];
    if (xt60_face=="bottom") {
      translate([xt60_pos, D/2+xt60_y, -H/2-eps]) {
        cube([bw, bh, wall+2*eps], center=true);
        for (s=[-1,1]) translate([s*xt60_screw_sep/2, 0, 0])
          cylinder(h=wall+2*eps, d=xt60_screw_d, center=true);
      }
    } else if (xt60_face=="left" || xt60_face=="right") {
      sx = (xt60_face=="right") ? 1 : -1;
      translate([sx*(W/2-wall/2), D/2+xt60_y, xt60_pos]) rotate([0,sx*90,0]) {
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
//  halves put the pin axis at (Ax, Ay) so they interleave coaxially.
// =====================================================================
module hinge_housing() {
  // proxy strip inside the left wall, its FRONT edge inset ov_d/2 from the
  // wall front so the pin lands at (Ax, Ay) -- the mid-overlap-depth axis;
  // the leaf hugs the wall exterior (+Y)
  translate([-W/2 + wall/2, D/2, 0])
    cuboid([wall, D - ov_d, hinge_span + 4])
      position(FRONT+LEFT) orient(anchor=LEFT, spin=180)
        knuckle_hinge(length=hinge_span, segs=hinge_segs, offset=hinge_offset,
                      arm_height=hinge_arm_h, arm_angle=hinge_arm_ang,
                      knuckle_diam=knuckle_d, gap=hinge_gap, pin_diam=pin_bore,
                      teardrop=true, round_bot=hinge_round_bot, clear_top=true);
}
module hinge_door() {
  // proxy strip on the door's left edge, extended past the door back face
  // so its BACK edge carries the pin at (Ax, Ay = ov_d/2); the leaf clips
  // flush with the door front (clip spans pin plane to door face).  The
  // trim cut removes whatever the hinge adds behind the door plane inside
  // the door outline -- that material would sweep into the housing band;
  // the leaf keeps its full lid_t-thick bond to the door edge.
  difference() {
    translate([-lid_w/2 + 1.5, (ov_d/2 - lid_t)/2, 0])
      cuboid([3, lid_t + ov_d/2, hinge_span + 4])
        position(BACK+LEFT) orient(anchor=LEFT, spin=0)
          knuckle_hinge(length=hinge_span, segs=hinge_segs,
                        offset=hinge_offset, arm_height=0,
                        knuckle_diam=knuckle_d, gap=hinge_gap, pin_diam=pin_bore,
                        teardrop=true, inner=true, clip=lid_t + ov_d/2,
                        clear_top=true);
    translate([-W/2, 0, -H/2-1]) cube([W/2, ov_d + 2, H + 2]);
  }
}

// =====================================================================
//  LID OVERLAP + SNAP LOCKS  (full perimeter)
//  The inspo mechanism, tolerances included: the housing's front band
//  steps in by `step` (the inspo's block standing proud of its outer
//  shell); the door skirt wraps it flush with the outer walls at 0.1
//  clearance per side.  Prismoid bumps on the skirt inner face, 1 mm
//  shy of the rim, click into 5 % oversized / 0.1 deeper dents cut in
//  the band; the skirt bows locally to cam over, like the inspo lid
//  wall.  The skirt runs full depth around the whole perimeter, hinge
//  side included; the swing clears because the pin axis sits at
//  mid-overlap depth and the hinge-side band is lid_clearance_left
//  loose (see the derived section and the swing-gap echo).  Only the
//  knuckle span is windowed out of the skirt.
// =====================================================================
// cut: recess the housing's outer band behind the door plane so the
// skirt sits flush (0.3 axial slack so the panel, not the skirt tip,
// seats on the band rim -- like the inspo lid resting on the case
// rim).  Full perimeter.  The band corner arcs all keep radius
// corner_r-step, but the LEFT cylinder pair shifts right by
// (step_left-step), giving the left face and corners the looser
// hinge-side clearance while the top/bottom/right faces -- and the
// dent/bump tuning on them -- stay at the inspo 0.1.  The left bound
// of the cut keeps it from digging deeper than 1 mm into the hinge
// leaf's base over the knuckle span (cosmetic, hidden behind the leaf)
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
module lock_wedge(o, dent=false) {   // inspo bump; dent -> 5 % oversize, 0.1 deeper
  s = dent ? 1.05 : 1;
  prismoid(size1=[bump_l*s, bump_w*s], size2=[bump_l*0.75*s, 0],
           h=bump_h + (dent ? 0.1 : 0), orient=o);
}
// dents in the stepped band faces (cut from the shell), one per lock
module lock_dents() {
  for (z = lock_zs) translate([W/2-step+eps, lock_y, z]) lock_wedge(LEFT, dent=true);
  if (n_locks >= 2) translate([0, lock_y,  H/2-step+eps])  lock_wedge(DOWN, dent=true);
  if (n_locks >= 3) translate([0, lock_y, -(H/2-step)-eps]) lock_wedge(UP, dent=true);
}
// door skirt: a plain full-depth ring wrapping the band, lock bumps on
// its inner faces, inspo grip ridge on the right face; the only opening
// is the window over the knuckle span, where the hinge leaf and barrels
// live
module door_skirt() {
  difference() {
    union() {
      difference() {
        rprism(W, H, ov_d, corner_r);              // outer = housing outline
        translate([0, -eps, 0])                    // inner = band + clearance
          rprism(W-2*skirt_t, H-2*skirt_t, ov_d+3*eps, corner_r-skirt_t);
      }
      for (z = lock_zs) translate([W/2-skirt_t+eps, lock_y, z]) lock_wedge(LEFT);
      if (n_locks >= 2) translate([0, lock_y,  H/2-skirt_t+eps])  lock_wedge(DOWN);
      if (n_locks >= 3) translate([0, lock_y, -(H/2-skirt_t)-eps]) lock_wedge(UP);
      if (grip)
        translate([W/2-eps, ov_d/2-0.05, 0])
          prismoid(size1=[bump_l, 2], size2=[bump_l*0.75, 1], shift=[0, -0.5],
                   h=1.5, orient=RIGHT);
    }
    translate([-W/2-1, -1, -hinge_win_z])
      cube([1 + step_left, ov_d+2, 2*hinge_win_z]);
  }
}

// =====================================================================
//  SHELL
// =====================================================================
module shell() {
  // hollow shell + ALL through-holes in ONE difference (external features only)
  difference() {
    union() {
      rprism(W, H, D, corner_r);
      if (lanyard) for (sx=[-1,1], sz=[-1,1]) lanyard_ear(sx, sz);
      hinge_housing();         // knuckle hinge, outer half (external, left)
    }
    translate([0,-eps,0]) rprism(inner_w, inner_h, inner_d+eps, corner_r-wall);  // cavity (front open)
    bnc_cut();
    // top controls: on/off switch on one side, LED on the other
    translate([power_top[0], D/2+power_top[1], H/2-wall-eps])
      cylinder(h=wall+2*eps, d=hole_power);
    translate([led_top[0], D/2+led_top[1], H/2-wall-eps])
      cylinder(h=wall+2*eps, d=hole_led);
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
    // playback button bores, one row (Y from -lid_t-eps to +eps)
    for (i = [0:3])
      translate([(i-1.5)*btn_pitch, -lid_t-eps, btn_row_z]) rotate([-90,0,0])
        cylinder(h=lid_t+2*eps, d=btn_d);
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
