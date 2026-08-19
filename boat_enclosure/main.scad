// =====================================================================
//  AIRBOAT ENCLOSURE -- ASSEMBLY / PREVIEW
//  Opening this file renders the assembled preview (both hulls, ghosts,
//  hardware phantoms).  The individual printable parts live in their own
//  files: body.scad, lid.scad, pylon.scad.  All shared parameters, the
//  fit-check echoes, and shared helpers are in common.scad.
//
//  FILE LAYOUT:
//    common.scad  -- params, DERIVED, ECHO fit-check, shared helpers, BOSL2
//    body.scad    -- body()  (floor down)      : openscad -o body.stl  -D '$fn=128' body.scad
//    lid.scad     -- lid()   (outer face down) : openscad -o lid.stl   -D '$fn=128' lid.scad
//    pylon.scad   -- pylon() (laid flat)       : openscad -o pylon.stl -D '$fn=128' pylon.scad
//    main.scad    -- this assembly preview     : openscad main.scad
// =====================================================================
include <common.scad>
use <body.scad>
use <lid.scad>
use <pylon.scad>
use <propguard.scad>
use <float.scad>
include <rail.scad>        // the REAL recessed mounting rail (dovetail-chained, 40 mm insert grid)
include <connector.scad>   // the centre-box connector bracket
rail = "none";             // AFTER the include: suppress rail.scad's own standalone render
conn_show = "none";        // AFTER the include: suppress connector.scad's own standalone render

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

module ghost_prop_and_motor() {
  // prop disc at TRUE diameter, aft of the stern, at hub height (clearance check).
  // Placed at the real motor width offset (hull-local X = pylon_width/2 - motor_zc) so the
  // top-down HONESTLY shows the outboard prop separation.  Schematic motor drawn if show_hardware off.
  motor_x_hull = (mount_to=="motor") ? (pylon_width/2 - motor_zc) : 0;
  translate([motor_x_hull, D - pylon_rise, -H/2 - prop_z_offset]) {
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
    if (mount_to == "motor") {
      // INTEGRATED: motor bolts straight to the guard-washer at the OFFSET motor axis (NO plate).  rotate([0,0,90])
      // maps motor-local X (long axis) -> pylon Y (up-mast), Z (short) -> pylon Z (width); mount face at X=pad_aft+guard_t.
      color([0.12,0.12,0.13,0.9])
        translate([pad_aft+guard_t, pylon_rise, motor_zc]) rotate([0,0,90]) import("Motor.stl");
    } else {
      // legacy: plate + motor mounted turned 45deg so the plate's outer "+" holes land on the pylon's X bores.
      // The plate lies in the pad plane (normal = fore-aft X), so the 45deg CLOCK is about X (rotate([45,0,0])
      // applied AFTER the base orientation) -- NOT about Z, which would tilt it out of the pad plane.
      color([0.72,0.73,0.75,0.9])   // BasePlate flat on the pad aft face (X=pad_aft)
        translate([pad_aft, pylon_rise, pylon_width/2]) rotate([45,0,0]) rotate([0,0,-90]) import("BasePlate.stl");
      color([0.12,0.12,0.13,0.9])   // motor: mounting face on the plate, can aft (+X), clocked about its own axis (X)
        translate([pad_aft+2+1.6, pylon_rise, pylon_width/2]) rotate([45,0,0]) rotate([0,0,90]) import("Motor.stl");
    }
  }
}

// hold-down screws: up through the foam, with a fender washer / head UNDER the soft foam.
// (screw_mount) old floor bosses -- blind, from the underside.  (corner_mount) the new external
// corner lugs -- the bolt rises into a nut CAPTURED in the lug top (Task 3), both ends (Task 2).
module ghost_screws() {
  if (screw_mount) for (p = screw_positions) color([0.7,0.7,0.75,0.9]) {
    translate([p[0], D - screw_hole_depth, p[1]]) rotate([-90,0,0])
      cylinder(h=screw_hole_depth + float_thickness, d=screw_size);      // shaft: boss -> under the board
    translate([p[0], D + float_thickness, p[1]]) rotate([-90,0,0])
      cylinder(h=2.5, d=max(16, 3.5*screw_size));                        // fender washer + head under the foam
  }
  if (corner_mount) both_ends() for (sx=[-1,1]) {
    color([0.7,0.7,0.75,0.9]) translate([sx*hd_x, hd_top_y + hd_nut_depth, hd_z]) rotate([-90,0,0])
      cylinder(h=(D + float_thickness) - (hd_top_y + hd_nut_depth), d=4);   // M4 bolt: top nut -> under the foam
    color([0.7,0.7,0.75,0.9]) translate([sx*hd_x, D + float_thickness, hd_z]) rotate([-90,0,0])
      cylinder(h=2.5, d=16);                                                // fender washer + head under the foam
    color([0.45,0.45,0.5,0.95]) translate([sx*hd_x, hd_top_y, hd_z]) rotate([-90,0,0])
      cylinder(h=hd_nut_depth, r=hd_nut_af/sqrt(3), $fn=6);                 // M4 nut captured in the lug top
  }
}

show_wire = true;   // draw the bright motor-lead ghost (down the wire slot toward the boat centre)

// one SET of two parallel fore-aft mounting RAILS under the stern box (the REAL rail.scad part, not a stub): each rail is
// n_seg segments (start+..+end) laid along Z, TOP flush with the deck (Y=D), inserts opening UP toward the box lugs.  The
// native rail pose (length +X, up +Z) is reframed to (length world-Z, up world -Y).  Two segments centred on box_back_z put
// the 40 mm insert grid on phase 20, so the box lugs at Z=box_back_z+/-100 land exactly on real insert holes.
module box_rails() {
  n = 2;   // 2 x 160 = 320 mm covers the 200 mm lug span + margin (contained in the skid)
  for (sx=[-1,1], i=[0:n-1])
    color([0.32,0.32,0.36])
      translate([sx*rail_x, D + rail_h, box_back_z - (n-1)*seg_len/2 + i*seg_len])
        rotate([0,-90,0]) rotate([90,0,0]) rail_segment(i==0 ? "start" : (i==n-1 ? "end" : "mid"));
}

// ONE drive: pylon (motor cross rotated by `rot`) + guard (rot + wire slot) + prop-disc + wire ghost, at a box's stern.
module drive(rot) {
  translate([pylon_width/2, mm_pad_yc + foot_h/2, mm_block_aft_z]) rotate(a=180, v=[1,0,-1]) {
    color("Tan") pylon_part(rot);
    // guard, prop disc and motor phantom all TILT with the pad (motor_tilted) so the preview shows the true
    // nose-down thrust line; the pylon part already has the tilt baked in.
    motor_tilted() ghost_hardware();
    if (prop_guard) motor_tilted() translate([pad_aft, pylon_rise, mount_to=="motor" ? motor_zc : pylon_width/2]) rotate([0,90,0]) {
      color("DarkSeaGreen") guard_full(rot, wire_slot_ang, false);
      if (show_wire && mount_to=="motor" && wire_slot) color([1,0.35,0])
        rotate([0,0,wire_slot_ang]) translate([6, 0, guard_t/2]) rotate([0,90,0]) cylinder(h=48, d=3.5);
    }
    if (show_ghosts) motor_tilted() color([0.85,0.2,0.2,0.28])
      translate([pad_aft+guard_t+guard_standoff, pylon_rise, motor_zc]) rotate([0,90,0]) cylinder(h=1.5, r=prop_radius, center=true);
  }
}

// one box: body + hinged lid; with_drive adds the pylon/guard/prop at its stern.
module boat_box(role, with_drive=false, rot=0) {
  color("SteelBlue") body(role);
  translate([Ax, Ay, 0]) rotate([0, 0, -lid_open]) translate([-Ax, -Ay, 0]) color("Gainsboro") lid();
  if (with_drive) drive(rot);
  if (show_ghosts) ghost_components();   // ghost_screws (through-foam hold-down) removed -- boxes now screw to the rails
}

// =====================================================================
//  SCENE -- 3 boxes: the two STERN DRIVE boxes (one per hull, on their rails) plus a CENTRE box floated box3_lift above
//  the deck BETWEEN them, hung off FOUR connector brackets (connector.scad).  The 4-box layout was nose-heavy, so the
//  front boxes are gone and the third box moves aft+inboard.  The stern boxes sit at +/-hull_dx so their inboard lug lands
//  on Patrick's MEASURED 155 mm inner rail; the port + starboard drives are the REAL mirrored-motor parts, not a fake.
// =====================================================================
module stern_drive_hull(sgn, rot) {
  hull = sgn < 0 ? "port" : "starboard";
  translate([sgn*hull_dx, 0, 0]) apply_side_of(hull) {
    box_rails();
    translate([0, 0, box_back_z]) boat_box(role_of_side(hull), true, rot);
  }
}

// the CENTRE box: floated box3_lift above the deck, on the centreline, at the same fore-aft station as the stern boxes.
module centre_box() {
  translate([0, -box3_lift, box_back_z]) color("LightSteelBlue") boat_box("rc", false);
}

// the four connector brackets: one per corner (both hulls x both end-block lug stations).
module centre_connectors() {
  for (sgn = [-1, 1], zs = [conn_z_fore, conn_z_aft])
    color("Goldenrod") connector_solid(sgn, zs);
}

module assembly_scene() {
  stern_drive_hull(-1, mrot_of( 1));                       // port hull: motor clocked so the wire gap faces the slot
  if (show_both_hulls) stern_drive_hull(1, mrot_of(-1));   // starboard hull: same, mirrored
  centre_box();
  centre_connectors();
  if (show_foam) translate([0, 0, deck_center_z]) foam_body();
}

// model "up" is -Y.  UPRIGHT: rotate to Z-up and lift so the hull BOTTOM (foam underside) sits on the XY plane (Z=0).
if (preview_upright) translate([0, 0, D + float_thickness]) rotate([-90,0,0]) assembly_scene();
else assembly_scene();
