// =====================================================================
//  Chest-mounted field-stimulator enclosure  (v0.9)
//  Bare Teensy 4.1 | single KeePower 26650 cell in holder | 1x BNC
//  | 6 playback buttons, 3 across x 2 down | LED + on/off on top
//  | XT60 charge port
//
//  INTERIOR (stacked, all long axes = X):
//     - battery holder horizontal along the BOTTOM (cell axis = X)
//     - bare Teensy 4.1 horizontal, directly ABOVE the battery
//     - power/LED hang off the TOP face; the on/off switch is deep
//       (power_body_depth) and owns its corner down to mid-height
//     - the button bodies (door) ride in FRONT of the Teensy, not above
//       it -- what boxes their two rows in is the switch above and the
//       battery holder below, both of which they do meet in y
//  The ENTIRE FRONT PANEL is a hinged, latched door.
//     HINGE : hand-rolled knuckle hinge on the LEFT edge, VERTICAL axis.
//             Outer half on the HOUSING, inner half on the DOOR: per-
//             segment barrels + leaf profiles extruded DIRECTLY at their
//             final shape (no corrective cuts), teardrop pin bores.  User
//             threads a length of 1.75 mm filament as the pin.  No
//             print-in-place, no screws.
//     LATCH : the battery-case inspo closure, verbatim: the housing's
//             front band steps in (the inspo's proud inner block), the
//             door carries a thin skirt that wraps it flush with the
//             outer walls (0.1 clearance/side), and little prismoid
//             bumps on the skirt inner face click into 5 % oversized,
//             0.1 deeper dents in the band.  Two locks on the long
//             right edge plus one top and one bottom.  The skirt runs
//             FULL DEPTH around the whole perimeter -- including across
//             the knuckle span: the pin axis sits at mid-overlap depth
//             (Ay = ov_d/2) and stands farther off the wall, the
//             hinge-side band is cut a touch looser, the housing leaf's
//             front face is a smooth bevel about the pin axis, and the
//             door leaf rides below the pin plane, freeing the sector
//             the skirt sweeps.
//  Battery retention: none printed -- the holder is GLUED to the floor/backplate.
//
//  Requires BOSL2 (../BOSL2).  Print PLA, no supports.
//  PARTS (part=): shell | lid(=door) | assembly(preview)
//     shell : BACK face on the bed
//     lid   : outer face down
// =====================================================================

include <../BOSL2/std.scad>

/* [What to render] */
part = "assembly";   // [assembly, shell, lid]
print_ready = true;
door_open   = 0;     // assembly preview only: degrees the door is swung open
show_ghosts = false;  // assembly preview: draw battery + Teensy phantoms

$fn  = 128;
eps  = 0.01;

/* [Enclosure envelope] */
inner_w  = 84;     // X interior  (holder is 81 long -> ~1.5 mm each side)
inner_h  = 100;    // Z interior  (battery + Teensy stacked + top control band)
inner_d  = 36;     // Y interior depth (holder needs >= 27 -- see echoes)
wall     = 2.5;
corner_r = 5;

/* [Front door] */
lid_t     = 3;     // door outline matches the housing exactly, like the inspo lid

/* [Panel cut-outs] -- measured bores */
hole_bnc     = 9.5;   // BNC panel bore (confirmed)
hole_power   = 12.2;  // on/off switch bore (confirmed)
hole_led     = 8;     // LED bore

/* [Playback buttons] -- 6 momentary buttons, 3 across x 2 down, on the door:
     top    CAL | APT | GYM   calibration, Apteronotus, Gymnotus
     bottom LOC | VOL | L+V   all Electrophorus (eel) -- see [Eel group]
   Full sequence = L+V, deconstruction = LOC, VOL.
   The rows are boxed in tightly -- but NOT by the Teensy, which sits behind
   them in y (see the btn_hits_* checks), only by the on/off switch column
   above and the battery holder below.  That leaves ~25 mm of center travel
   for both rows; the echo reports the window and what each row has left. */
btn_d       = 12;     // panel bore, same as the old trigger (confirmed)
btn_body_d  = 17.5;     // button body diameter (fit checks)
btn_cols    = 3;
btn_row_z   = 10;     // Z of the TOP row; the switch column caps this
btn_row_pitch = 22;   // Z between the two rows
btn_pitch   = 22;     // X spacing between columns
btn_names   = [ ["A", "B", "C"],
                ["C", "D", "E"] ];
btn_label_dz = 14;     // each label sits this far above its own button
panel_depth = 15;     // how far a button body reaches inward (for fit checks)

/* [Eel group] -- the bottom row is all eel playback and the top row is not,
   so the bottom row gets an engraved tie: end ticks reach up at the three
   buttons it claims, joined by a rule that the group's name breaks.  It hangs
   below the row because the band between the rows is spoken for by labels. */
eel_group    = false;
eel_row      = 1;     // index into btn_names
eel_name     = "EEL";
eel_name_sz  = 3.2;
eel_tie_z    = -24;   // Z of the tie's rule
eel_tick_gap = 1.5;   // tick tops stop this far under the row's bores
eel_rule_t   = 0.9;   // engraved stroke width
eel_pad      = 3;     // how far the tie overhangs the outer bores
eel_name_clr = 1.2;   // clear space the name knocks out of the rule

/* [Top controls] -- on/off switch and LED on the TOP face, one per side */
power_top = [ 22, 0];  // [x, y-offset from the top-face center]
led_top   = [-22, 0];
power_body_d     = 14; // switch body envelope below the panel (fit checks)
power_body_depth = 32; // MEASURED: the switch hangs this far into the housing.
                       // It owns the whole +x top corner down to
                       // power_body_z0, which is what caps the button row

/* [BNC output] -- ONE port, on the wall OPPOSITE the on/off switch, whose
   body owns that top corner (see power_body_depth); one channel is all the
   stimulator needs.  (bnc_face="left" is -x, the hinge/XT60/LED side.) */
bnc_face    = "left";  // [left, right, both, bottom, top]
bnc_z       = 38;
bnc_x       = 0;
bnc_y       = -4;
bnc_keepout = 14;

/* [Panel engraving] -- one label above each playback button */
engrave    = true;
engrave_d  = 0.6;
label_size = 3.5;
labels = [ for (r = [0:len(btn_names)-1], c = [0:btn_cols-1])
             [btn_names[r][c], btn_x(c), btn_z(r) + btn_label_dz, 0] ];

/* [Front panel masthead] -- engraved title block, centered above the labels.
   One row per line: [text, size, z].  `size` is OpenSCAD's text ASCENT, not
   an em, and text() centers each line on its INK box -- so z IS the ink
   center and a line stands text_ink_h*size tall (see that constant).
   The tight direction is Z, not width: the door's top edge and the button
   labels close in from both ends, and the echo reports what is left. */
masthead = true;
masthead_lines = [
  //   text                          size    z
  [   "TeensyStim",                   7,    44.5 ],
  [   "EOD Playback System",    2.9,  36.5 ],
  [   "by ThunderLab",                2.7,  31.5 ],
];

/* [Lanyard eyes] -- the rubber-band standoffs: 4 of them, on the BACK face's
   side edges (the chest side), VERTICAL 5 mm bores.  The shell prints back
   down, so the ear's two round features both lie as horizontal cylinders on
   the bed and neither may be left circular: they carry the hinge's profile
   instead -- hinge_arm_ang hat on the boss, teardrop bore. */
lanyard   = true;
lug_hole  = 4.5;
lug_web   = 3;
lug_out   = 5;
lug_t     = 8;
lug_inset = 12;

/* [Knuckle hinge] -- hand-rolled, LEFT edge, vertical axis, 1.75 mm filament pin */
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
hinge_fillet = 2;      // housing leaf-to-wall fillet radius: an exact arc
                       // tangent to both the wall and the leaf underside,
                       // so the leaf grows smoothly out of the wall and
                       // leaf_reach is the computed tangent point --
                       // nothing empirical
hinge_arm_ang = 35;    // housing leaf underside angle from vertical == its
                       // print overhang (the leaf profile is built at
                       // exactly this angle).  Smaller = shallower but
                       // longer leaf; 35 is comfortable supportless PLA
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
grip          = true;  // inspo-style thumb grip wedge on the door's right rim

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
                           // keeps the flange seat well clear of the 35-deg
                           // leaf (~3.9 mm margin with the exact-fillet leaf
                           // reach -- could come back to ~6.5 if a more
                           // central port is ever wanted).  Budget runs to
                           // ~12 before the flange hits the back edge (the
                           // BNC keeps its own bnc_y -- the lanyard lug
                           // blocks moving it back)
xt60_flange_h = 14;        // flange height across the screw axis (fit check)
xt60_body_depth = 12;      // how far the connector body reaches inward (collision check)

/* [Wire routing] */
loom_slot = [10, 8];   // W x H slot near the hinge for the control loom

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
kr       = knuckle_d/2;

// knuckle stack: hinge_segs segments over hinge_span, hinge_gap apart
seg_h = (hinge_span - (hinge_segs-1)*hinge_gap)/hinge_segs;
function seg_z(i) = -hinge_span/2 + i*(seg_h + hinge_gap);

// housing leaf underside: the line at hinge_arm_ang from vertical, tangent
// to the barrel at leaf_P and heading for the wall; an exact arc fillet of
// radius hinge_fillet (tangent to both the line and the wall, centered at
// leaf_F) lands the leaf on the wall at leaf_reach -- the tangent point,
// computed, not fitted
leaf_P  = [Ax - kr*cos(hinge_arm_ang), Ay + kr*sin(hinge_arm_ang)];
leaf_T1 = leaf_P + ((-W/2 - hinge_fillet*(1 - cos(hinge_arm_ang)) - leaf_P.x)
                    / sin(hinge_arm_ang)) * [sin(hinge_arm_ang), cos(hinge_arm_ang)];
leaf_F  = leaf_T1 + hinge_fillet*[-cos(hinge_arm_ang), sin(hinge_arm_ang)];
leaf_reach = leaf_F.y;   // leaf-wall contact ends here (fillet-wall tangent)

// lid overlap derived values
step      = skirt_t + lid_clearance;        // band inset, right/top/bottom
step_left = skirt_t + lid_clearance_left;   // band inset, hinge side
lock_y    = ov_d - 1.0;                // bump/dent center, 1 mm shy of the skirt rim (inspo)
// hinge-side full overlap: the skirt is a plain UNBROKEN full-depth ring.
// It swings clear of the band because (a) the pin axis sits at mid-overlap
// depth (Ay), so the skirt face's worst radius is sqrt(dx^2 + (ov_d/2)^2)
// instead of sqrt(dx^2 + ov_d^2), and (b) the left band face gives
// lid_clearance_left.  swing_gap below is the guaranteed minimum
// skirt-to-band gap at any point of the swing (worst at the skirt tip
// corners on the straight left edge; the corner arcs are strictly better).
swing_gap = hinge_offset + skirt_t + lid_clearance_left
          - sqrt(pow(hinge_offset + skirt_t, 2) + pow(ov_d/2, 2));
// leaf swing bevel: the housing leaf's front face is a flat plane through
// the pin axis at shell_bevel (smooth, swing-concentric), landing exactly
// on the recess floor edge at the wall -- it frees the sector the closing
// skirt sweeps and reads as a continuation of the recess.  The door leaf
// needs no bevel at all: its plate tops out ON the pin plane (swing ray 0),
// a full shell_bevel below any housing material it passes.  Rays measured
// about (Ax, Ay) from the pin plane toward the wall.
skirt_max_ang  = atan((ov_d - Ay)/hinge_offset);        // skirt's highest seated ray
shell_bevel    = atan((ov_d + 0.3 - Ay)/hinge_offset);  // lands on the recess floor edge

lug_d  = lug_hole + 2*lug_web;
lug_ex = W/2 + lug_out;
lug_ez = H/2 - lug_inset;
lug_ey = D - lug_d/2;

// lanyard ear, all in the PRINT frame (back face on the bed -> print-up = -y):
lug_front_y = lug_ey - lug_d/2;                  // ear's front edge = its print top
lug_bed_w   = 2*((lug_d/2)/sin(hinge_arm_ang) - (D - lug_ey))*tan(hinge_arm_ang);
                                                 // boss's truncated hat = its bed flat
lug_apex_y  = lug_ey - (lug_hole/2)/sin(45);     // teardrop bore's apex
lug_apex_web = lug_apex_y - lug_front_y;         // PLA left between apex and ear top
lug_z0 = lug_ez - lug_t/2;
lug_z1 = lug_ez + lug_t/2;

// Liberation Sans ink extents, MEASURED off rendered text at size 10: a line
// with a descender stands this * size tall, all-caps ~0.956 * size, and
// text(valign="center") centers that ink box.  Used only to echo the masthead
// stack -- OpenSCAD cannot measure text (textmetrics is experimental and off
// by default), so the widths are checked by rendering, not asserted here.
text_ink_h  = 1.294;
text_caps_h = 0.956;
mast_top    = masthead ? masthead_lines[0][2] + text_ink_h*masthead_lines[0][1]/2 : -H;
mast_bot    = masthead ? masthead_lines[len(masthead_lines)-1][2]
                         - text_ink_h*masthead_lines[len(masthead_lines)-1][1]/2 : H;
label_top   = labels[0][2] + text_caps_h*label_size/2;     // labels are all-caps

// on/off switch body: a column hanging off the top panel into the +x corner
power_body_z0 = inner_h/2 - power_body_depth;    // its lowest point

// button grid: column 0 is -x, row 0 is the TOP row
btn_rows = len(btn_names);
function btn_x(c) = (c - (btn_cols-1)/2) * btn_pitch;
function btn_z(r) = btn_row_z - r*btn_row_pitch;
// what boxes the grid in.  NOT the Teensy: it sits behind the buttons in y
// (its front face is hold_yc - teensy_stk/2, the bodies only reach
// panel_depth), so its z band is irrelevant -- the two that bite are the
// switch column above (only over the columns it overlaps in x) and the
// battery holder below, which the bodies DO reach in y.
btn_z_hi = power_body_z0 - btn_body_d/2;         // ceiling, switch columns only
btn_z_lo = battery_top_z + btn_body_d/2;         // floor, every column
function btn_over_power(c) =
  abs(btn_x(c) - power_top[0]) < (btn_body_d + power_body_d)/2;
function btn_hits_power(r, c) = btn_over_power(c) && btn_z(r) > btn_z_hi
                                && panel_depth > D/2 + power_top[1] - power_body_d/2;
function btn_hits_batt(r, c)  = btn_z(r) < btn_z_lo && panel_depth > body_front_y;
function btn_hits_teensy(r, c) = btn_z(r) - btn_body_d/2 < teensy_top_z
                                 && btn_z(r) + btn_body_d/2 > teensy_bot_z
                                 && panel_depth > hold_yc - teensy_stk/2;

// eel group tie: the rule's ticks are computed to stop just under the row's
// bores, and it spans that row's outer bores plus eel_pad -- both follow the
// grid, so moving a row or the pitch carries the tie with it
eel_tick_h = (btn_z(eel_row) - btn_d/2 - eel_tick_gap) - eel_tie_z;
eel_tie_w  = 2*(btn_x(btn_cols-1) + btn_d/2 + eel_pad);

// BNC nut zone: the flat wall the d15 nut needs, around the bore
bnc_nut_y1 = D/2 + bnc_y + bnc_keepout/2;        // its front edge (toward the door)
bnc_nut_z0 = bnc_z - bnc_keepout/2;
bnc_nut_z1 = bnc_z + bnc_keepout/2;
bnc_wall_x = bnc_face=="right" ? 1 : bnc_face=="left" ? -1 : 0;   // 0 = not a side wall

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
echo(str("--- playback buttons: ", btn_cols, " across x ", btn_rows,
         " down (bodies ", btn_body_d, " reaching ", panel_depth, " mm in) ----"));
for (r = [0:btn_rows-1], c = [0:btn_cols-1])
  echo(str("  ", btn_names[r][c], " at [", btn_x(c), ", ", btn_z(r), "]",
           btn_hits_power(r,c)  ? "  << WARNING: body hits the on/off switch body" :
           btn_hits_batt(r,c)   ? "  << WARNING: body hits the battery holder" :
           btn_hits_teensy(r,c) ? "  << WARNING: body hits the Teensy" :
           btn_over_power(c)    ? "  (clear, under the switch column)" : "  (clear)"));
if (btn_pitch < btn_body_d + 2)
  echo("  WARNING: button bodies closer than 2 mm in x -- widen btn_pitch");
if (btn_row_pitch < btn_body_d + 2)
  echo("  WARNING: button bodies closer than 2 mm in z -- widen btn_row_pitch");
if (btn_z(0) + btn_body_d/2 > bnc_z - bnc_keepout/2)
  echo("  note: outer button bodies reach the side-wall BNC body band");
echo(str("  grid span x = [", btn_x(0) - btn_d/2, ", ", btn_x(btn_cols-1) + btn_d/2,
         "]  (cavity +/-", inner_w/2, ") ; z = [", btn_z(btn_rows-1), ", ", btn_z(0), "]"));
// centers are boxed between the switch column above and the battery below --
// the Teensy is behind them in y and does NOT enter into it
echo(str("  center window = [", btn_z_lo, ", ", btn_z_hi, "] (battery floor, switch ceiling)",
         " ; rows at ", [for (r=[0:btn_rows-1]) btn_z(r)],
         " -> switch clr ", btn_z_hi - btn_z(0), ", battery clr ", btn_z(btn_rows-1) - btn_z_lo));
if (btn_z_hi - (btn_rows-1)*btn_row_pitch < btn_z_lo)
  echo("  WARNING: rows cannot fit between the battery and the switch -- tighten btn_row_pitch");
if (eel_group) {
  echo(str("  eel tie: rule z=", eel_tie_z, " w=", eel_tie_w, ", ticks ",
           round(100*eel_tick_h)/100, " up to ", eel_tie_z + eel_tick_h,
           " (", eel_tick_gap, " under the ", btn_names[eel_row][0], " row's bores)"));
  if (eel_tick_h <= 0)
    echo("  WARNING: eel tie sits above the row it claims -- lower eel_tie_z");
  if (eel_tie_z - eel_name_sz/2 < -H/2 + 3)
    echo("  WARNING: eel tie runs off the bottom of the door");
}
echo("--- top controls (power switch + LED) ------------------------------");
echo(str("  power at x=", power_top[0], " (old trigger spot), LED at x=", led_top[0]));
echo(str("  on/off body: ", power_body_depth, " mm measured -> reaches down to z = ",
         power_body_z0, " ; LED body reaches z ~ ", inner_h/2 - panel_depth));
if (power_body_z0 < teensy_top_z && abs(power_top[0]) < teensy_len/2 + power_body_d/2)
  echo("  WARNING: on/off switch body reaches the Teensy band");
if (abs(bnc_z - inner_h/2) < panel_depth + bnc_keepout/2)
  echo("  note: top-control bodies share the corner zone with the BNC bodies -- checked OK for the trigger before");
echo("--- BNC ----------------------------------------------------------");
echo(str("  bnc_face = ", bnc_face, "  (", bnc_face=="both" ? 2 : 1,
         " port) at z = ", bnc_z, "  (battery top ", battery_top_z,
         ", top wall ", inner_h/2, ")"));
if (bnc_z - bnc_keepout/2 < battery_top_z) echo("  note: BNC body dips toward the battery band");
// the switch column owns its top corner all the way down to power_body_z0
if ((bnc_face=="both" || bnc_wall_x*power_top[0] > 0) && power_body_z0 < bnc_nut_z1)
  echo("  WARNING: a BNC shares its top corner with the on/off switch body");
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
    // 0.5 mm assembly margin on an exact leaf reach
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
echo("--- knuckle hinge (hand-rolled, left edge) ------------------------");
echo(str("  pin axis (x,y) = (", Ax, ", ", Ay, ") ; barrel d=", knuckle_d,
         " ; pin bore=", pin_bore, " (teardrop)"));
echo(str("  barrel inner edge x = ", Ax + knuckle_d/2, "  (left wall ", -W/2,
         ", door edge ", -lid_w/2, ")"));
if (hinge_offset < knuckle_d/2) echo("  ERROR: hinge_offset must be >= knuckle_d/2");
echo(str("  housing leaf reach along left wall y = ", leaf_reach,
         " mm (exact fillet tangent) ; knuckle stack z = +/-", hinge_span/2));
echo(str("  housing leaf underside overhang = ", hinge_arm_ang,
         " deg from vertical by construction",
         " (shell prints back face down; keep <= ~45)"));
if (hinge_arm_ang > 45)
  echo("  WARNING: hinge leaf underside too steep to print -- lower hinge_arm_ang");
if (hinge_span/2 > bnc_z - 7.5 - 1)   // d15 BNC nut needs flat wall
  echo("  WARNING: hinge leaf runs into the left BNC nut zone -- shorten hinge_span");
if (leaf_reach > D/2 + xt60_y - 10.5/2 - 1)   // XT60 plug housing envelope
  echo("  WARNING: hinge leaf reaches the XT60 plug envelope -- steepen hinge_arm_ang");
echo("--- front panel masthead (engraved) -------------------------------");
if (masthead) {
  for (m = masthead_lines)
    echo(str("  \"", m[0], "\"  size ", m[1], " at z=", m[2], " -> ink z [",
             round(100*(m[2] - text_ink_h*m[1]/2))/100, ", ",
             round(100*(m[2] + text_ink_h*m[1]/2))/100, "]"));
  echo(str("  stack z = [", round(100*mast_bot)/100, ", ", round(100*mast_top)/100,
           "] ; clear of the door's top edge by ", round(100*(H/2 - mast_top))/100,
           " , of the button labels by ", round(100*(mast_bot - label_top))/100));
  if (mast_top > H/2 - 1)
    echo("  WARNING: masthead runs off the top of the door");
  if (mast_bot < label_top + 1)
    echo("  WARNING: masthead crowds the button labels -- shrink it or lower btn_row_z");
  // engraved into the face that prints ON the bed -- strokes must beat the nozzle
  if (min([for (m=masthead_lines) m[1]]) < 2.5)
    echo("  WARNING: a masthead line is small enough that 0.4 mm strokes will fill in");
}
echo("--- lanyard ears (rubber-band standoffs) -------------------------");
echo(str("  eye boss: teardrop hat ", hinge_arm_ang,
         " deg from vertical (as the hinge leaf), truncated ON the back face",
         " -> ", round(100*lug_bed_w)/100, " mm flat on the bed, no tangent circle"));
echo(str("  eye bore: teardrop, apex print-up at y = ", lug_apex_y,
         " ; web above it = ", round(100*lug_apex_web)/100,
         " mm (the ", lug_web, " mm side web is untouched)"));
if (lug_apex_web < 1.2)
  echo("  WARNING: lanyard eye's teardrop apex leaves < 1.2 mm of web -- raise lug_web");
// the ears sit at the BNC's z; only their y span keeps them out of its nut zone
echo(str("  ear y span = [", lug_front_y, ", ", D, "] ; z = +/-[", lug_z0, ", ", lug_z1, "]"));
if (lug_z0 < bnc_nut_z1 && lug_z1 > bnc_nut_z0) {
  if (lug_front_y < bnc_nut_y1)
    echo(str("  WARNING: lanyard ear obstructs the BNC nut zone -- keep its front edge behind y = ",
             bnc_nut_y1));
  else
    echo(str("  ear shares the BNC's z band, clears its nut zone in y by ",
             round(100*(lug_front_y - bnc_nut_y1))/100, " mm"));
}
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
echo(str("  hinge-side skirt: FULL unbroken ring, ", ov_d,
         " deep incl. the knuckle span ; left clearance ", lid_clearance_left,
         " ; guaranteed min swing gap = ", round(1000*swing_gap)/1000, " mm"));
if (swing_gap < 0.1)
  echo("  WARNING: hinge-side skirt scrapes on the swing -- raise hinge_offset or lid_clearance_left");
echo(str("  leaf swing bevel: shell ", round(10*shell_bevel)/10,
         " deg over skirt ray ", round(10*skirt_max_ang)/10, " deg (gap ",
         round(100*sqrt(pow(hinge_offset,2)+pow(ov_d-Ay,2))*sin(shell_bevel-skirt_max_ang))/100,
         ") ; door leaf tops out on the pin plane (min gap ",
         round(100*kr*sin(shell_bevel))/100, ")"));
if (sqrt(pow(hinge_offset,2)+pow(ov_d-Ay,2))*sin(shell_bevel-skirt_max_ang) < 0.15)
  echo("  WARNING: shell leaf bevel too close to the swinging skirt");
echo("------------------------------------------------------------------");

// =====================================================================
//  HELPERS
// =====================================================================
module rprism(w, h, d, r) {
  hull() for (sx=[-1,1], sz=[-1,1]) translate([sx*(w/2-r), 0, sz*(h/2-r)])
    rotate([-90,0,0]) cylinder(h=d, r=r);
}
module post(x, z, h, d) { translate([x, D-wall, z]) rotate([90,0,0]) cylinder(h=h, d=d); }
// engrave 2D children into the door's front face, engrave_d deep.  The 2D
// plane maps straight onto the panel: x -> x, y -> z.
module face_cut() {
  translate([0, -lid_t+engrave_d, 0]) rotate([90,0,0])
    linear_extrude(engrave_d+eps) children();
}
module panel_text_2d(t, size) {
  text(t, size=size, halign="center", valign="center", font="Inter:style=Bold");
}
module face_text(t, x, z, size, rot=0) {
  face_cut() translate([x, z]) rotate(-rot) panel_text_2d(t, size);
}
// Eel group tie: end ticks reaching up at the row's outer bores, joined by a
// rule that the group's name breaks.  The name knocks its OWN gap, so no gap
// width has to be kept in sync with the string -- but the cutter needs both
// of these to come out clean, and each fixes a real artifact:
//   hull()   : offsetting the raw glyphs gives a LETTER-shaped gap, so wherever
//              a letter is thin at the rule's height (the stem of an L) the
//              rule drives into it and leaves a notch.
//   mirror() : the hull alone is only as square as the string's end letters --
//              "EEL" has no top-right arm, so its hull slants and tapers that
//              end of the rule to a wedge.  Hulling the string against its own
//              mirror makes the gap symmetric whatever the letters are.
module eel_tie_2d() {
  difference() {
    union() {
      translate([0, eel_tie_z]) square([eel_tie_w, eel_rule_t], center=true);
      for (s = [-1,1])
        translate([s*(eel_tie_w - eel_rule_t)/2, eel_tie_z + eel_tick_h/2])
          square([eel_rule_t, eel_tick_h], center=true);
    }
    translate([0, eel_tie_z]) offset(r=eel_name_clr) hull() {
      panel_text_2d(eel_name, eel_name_sz);
      mirror([1,0]) panel_text_2d(eel_name, eel_name_sz);
    }
  }
}

// =====================================================================
//  LANYARD  (rubber-band standoffs on the back face's side edges)
//  Modeled DIRECTLY at its final printed shape, like the hinge: the ear is one
//  linear_extrude of an x-y profile whose every +y face -- the shell prints
//  back down, so +y IS the print-underside -- is either the bed itself or a
//  hinge_arm_ang wall.  A plain circular boss would sit TANGENT to the back
//  face and so leave the bed horizontally; the teardrop's hat, truncated on
//  that same plane (cap_h = D - lug_ey), gives it a flat to start from and a
//  hinge_arm_ang climb off it.  The square root keeps the ear fused to the
//  side wall and cannot reach the hat, which is the profile's only material
//  outboard of it, so the hull is free to convexify.  The eye's own ceiling
//  is a teardrop like the pin bores.  Nothing reaches toward the front, which
//  is what keeps the BNC nut zone clear -- see the echo.
// =====================================================================
module lanyard_ear(sx, sz) {
  translate([0,0,sz*lug_ez - lug_t/2]) linear_extrude(lug_t) hull() {
    translate([sx*(W/2-3), lug_ey]) square([6, lug_d], center=true);
    translate([sx*lug_ex,  lug_ey])
      teardrop2d(d=lug_d, ang=hinge_arm_ang, cap_h=D-lug_ey);
  }
}
module lanyard_bore(sx, sz) {   // teardrop, apex print-up (-y), as the pin bores
  translate([sx*lug_ex, lug_ey, sz*lug_ez - lug_t/2 - eps])
    linear_extrude(lug_t + 2*eps) rotate(180) teardrop2d(d=lug_hole, ang=45);
}

// =====================================================================
//  BNC
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
//  KNUCKLE HINGE  (hand-rolled, left edge, vertical axis, filament pin)
//  Both halves are modeled DIRECTLY as their final printed shape: each
//  knuckle segment is one linear_extrude of a 2D profile in the x-y
//  plane (barrel disc + leaf polygon), and one teardrop pin-bore prism
//  is cut through the whole stack, apex toward print-up.  The housing
//  gets segments 0,2,4 (both ends + middle), the door segments 1,3;
//  adjacent segments interleave with hinge_gap of z clearance.
// =====================================================================
module hinge_segments(from)   // every second knuckle, starting at `from`
  for (i = [from : 2 : hinge_segs-1])
    translate([0, 0, seg_z(i)]) linear_extrude(seg_h) children();

module pin_bore_cut(apex)     // teardrop prism through the stack; apex
                              // (+/-1 in y) must point print-up
  translate([Ax, Ay, -hinge_span/2 - 1]) linear_extrude(hinge_span + 2)
    rotate(apex > 0 ? 0 : 180) teardrop2d(d=pin_bore, ang=45);

// housing leaf profile: the barrel plus an arm whose faces are all final --
//   front : the shell_bevel ray from the barrel surface to the recess
//           floor edge at the wall (the swing relief, built in);
//   under : the hinge_arm_ang tangent line (the print overhang);
//   wall  : embedded 0.6 into the wall up to leaf_reach, where the exact
//           hinge_fillet arc returns to the underside line.
// The arm wraps the barrel's print-underside, so beyond the teardrop bore
// nothing on the housing half overhangs past hinge_arm_ang.
module housing_leaf_2d() {
  translate([Ax, Ay]) circle(d=knuckle_d);
  polygon(concat(
    [[Ax + kr*cos(shell_bevel), Ay + kr*sin(shell_bevel)],  // barrel @ bevel ray
     [-W/2, ov_d + 0.3],                                    // recess floor edge
     [-W/2 + 0.6, ov_d + 0.3],
     [-W/2 + 0.6, leaf_reach]],
    arc(n=16, r=hinge_fillet, cp=leaf_F, angle=[0, -hinge_arm_ang]),
    [leaf_P]));                                             // tangent on the barrel
}
// door leaf profile: the barrel plus a plain plate from the barrel's far
// side into the skirt wall, spanning door front face to pin plane.  The
// plate top lies ON the pin plane (swing ray 0), so it needs no bevel,
// and it wraps the barrel's print-underside (door face on the bed).
module door_leaf_2d() {
  translate([Ax, Ay]) circle(d=knuckle_d);
  polygon([[Ax - kr, -lid_t], [-W/2 + 0.6, -lid_t],
           [-W/2 + 0.6, Ay], [Ax - kr, Ay]]);
}

module hinge_housing() {  // outer half (external, left)
  difference() {
    hinge_segments(0) housing_leaf_2d();
    pin_bore_cut(-1);     // shell prints back face down -> print-up = -y
  }
}
module hinge_door() {     // inner half (external, left)
  difference() {
    hinge_segments(1) door_leaf_2d();
    pin_bore_cut(+1);     // door prints front face down -> print-up = +y
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
//  wall.  The skirt runs full depth around the whole perimeter with no
//  window at all; the swing clears because the pin axis sits at
//  mid-overlap depth, the hinge-side band is lid_clearance_left loose,
//  and the hinge leaves' inner sides are beveled about the pin axis
//  (see the derived section and the swing-gap/bevel echoes).
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
// door skirt: a plain UNBROKEN full-depth ring wrapping the band, lock
// bumps on its inner faces, inspo-style thumb grip on the right rim.  It
// runs across the knuckle span too: the housing leaf's swing bevel frees
// the sector it sweeps (see the derived section).
module door_skirt() {
  difference() {
    rprism(W, H, ov_d, corner_r);                  // outer = housing outline
    translate([0, -eps, 0])                        // inner = band + clearance
      rprism(W-2*skirt_t, H-2*skirt_t, ov_d+3*eps, corner_r-skirt_t);
  }
  for (z = lock_zs) translate([W/2-skirt_t+eps, lock_y, z]) lock_wedge(LEFT);
  if (n_locks >= 2) translate([0, lock_y,  H/2-skirt_t+eps])  lock_wedge(DOWN);
  if (n_locks >= 3) translate([0, lock_y, -(H/2-skirt_t)-eps]) lock_wedge(UP);
  if (grip)   // thumb-grip wedge on the door's right rim: its base sits on
              // the front-face plane (the print bed) and it tapers away
              // upward, so it prints without support
    translate([lid_w/2, -lid_t, 0]) rotate([-90, 0, 0])
      prismoid(size1=[3, bump_l], size2=[0.8, bump_l*0.75],
               shift=[-1.1, 0], h=2);
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
    // playback button bores, 3 across x 2 down (Y from -lid_t-eps to +eps)
    for (r = [0:btn_rows-1], c = [0:btn_cols-1])
      translate([btn_x(c), -lid_t-eps, btn_z(r)]) rotate([-90,0,0])
        cylinder(h=lid_t+2*eps, d=btn_d);
    if (engrave) for (l=labels) face_text(l[0], l[1], l[2], label_size, len(l)>3 ? l[3] : 0);
    // masthead: centered on the panel, each line at its own size
    if (engrave && masthead) for (m=masthead_lines) face_text(m[0], 0, m[2], m[1]);
    // eel group: the tie's rule and ticks, plus the name that breaks it
    if (engrave && eel_group) {
      face_cut() eel_tie_2d();
      face_text(eel_name, 0, eel_tie_z, eel_name_sz);
    }
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
