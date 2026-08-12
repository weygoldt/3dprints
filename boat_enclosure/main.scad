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
    // plate + motor mounted turned 45deg so the plate's outer "+" holes land on the pylon's X bores.
    // The plate lies in the pad plane (normal = fore-aft X), so the 45deg CLOCK is about X (rotate([45,0,0])
    // applied AFTER the base orientation) -- NOT about Z, which would tilt it out of the pad plane.
    color([0.72,0.73,0.75,0.9])   // BasePlate flat on the pad aft face (X=pad_aft)
      translate([pad_aft, pylon_rise, pylon_width/2]) rotate([45,0,0]) rotate([0,0,-90]) import("BasePlate.stl");
    color([0.12,0.12,0.13,0.9])   // motor: mounting face on the plate, can aft (+X), clocked about its own axis (X)
      translate([pad_aft+2+1.6, pylon_rise, pylon_width/2]) rotate([45,0,0]) rotate([0,0,90]) import("Motor.stl");
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

// pylon placed against the stern block aft face, mast up (assembly view).
// 180deg about (1,0,-1) maps pylon-local (fore-aft X, up Y, width Z) to the
// stern pose; the pylon is width-symmetric so this rotation is exact.
module pylon_at_stern() {
  translate([pylon_width/2, mm_pad_yc + foot_h/2, mm_block_aft_z])
    rotate(a=180, v=[1,0,-1]) {
      difference() { pylon(); pylon_cut(); }
      ghost_hardware();
      // prop guard bolted in the pad sandwich (drawn canonical; hull_assembly's mirror sets outboard per hull)
      if (prop_guard) translate([pad_aft, pylon_rise, pylon_width/2]) rotate([0,90,0]) color("DarkSeaGreen") guard_full();
    }
}

// =====================================================================
//  SCENE
// =====================================================================
// one hull for the named side: applies that hull's mirror AND its own gland role,
// so the two boxes show their CORRECT, DIFFERENT bore sets (rc = 3, stim = 2).
module hull_assembly(hull) {
  apply_side_of(hull) {
    color("SteelBlue") body(role_of_side(hull));
    // lid swings about the outboard hinge axis (Ax,Ay), which runs along Z (the length)
    translate([Ax, Ay, 0]) rotate([0, 0, -lid_open]) translate([-Ax, -Ay, 0])
      color("Gainsboro") lid();
    pylon_at_stern();
    if (show_ghosts) { ghost_components(); ghost_prop_and_motor(); ghost_screws(); }
  }
}

module assembly_scene() {
  // the two hulls in their PHYSICAL positions (port at -X, starboard at +X), each with its own
  // electronics role -> the preview is the real boat: one RC box + one stim box (mapping = rc_side).
  // Independent of the global `side` (that only picks which single part body.scad/lid.scad export).
  translate([-beam_target/2, 0, 0]) hull_assembly("port");
  if (show_both_hulls)
    translate([ beam_target/2, 0, 0]) hull_assembly("starboard");
  // the shared foam catamaran body (drawn once, shifted fore-aft by deck_center_z)
  if (show_foam) translate([0, 0, deck_center_z]) foam_body();
}

// model "up" is -Y; upright view rotates it so height is world +Z (Z-up camera)
if (preview_upright) rotate([-90,0,0]) assembly_scene();
else assembly_scene();
