// =====================================================================
//  AIRBOAT ENCLOSURE -- PYLON  (separate bolt-on part; prints laid flat)
// Part of the airboat catamaran enclosure. See common.scad for the
// frame mapping, all parameters, the fit-check echoes, and shared helpers.
// =====================================================================
include <common.scad>

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
      translate([0, pad_y0]) square([pad_aft, pad_y1 - pad_y0]);                   // motor pad (item 1: top extended)
    }
    translate([-reg_depth, (foot_h-reg_h)/2]) square([reg_depth+eps, reg_h]);       // register tongue (crisp)
    // item 2 -- forward gusset (crisp, like the tongue, so the thin tip keeps its full reach to the
    // stern wall and the bearing face stays flat).  Right edge at X=+eps sits INSIDE the mast front
    // (x>=0) for a solid weld; bottom face at fg_y0 bears on the block top; apex at (eps,fg_y1).
    if (fwd_gusset)
      polygon([[eps, fg_y1], [eps, fg_y0], [-fg_reach, fg_y0]]);
  }
}

module pylon() color("Tan") linear_extrude(pylon_width) pylon_2d();

// teardrop clearance bore: axis +X (fore-aft, horizontal on the bed), APEX toward
// +Z = the pylon's print-up (Z=0 face is on the bed) so the horizontal hole
// self-supports instead of drooping.  Drop-in for `rotate([0,90,0]) cylinder(h,d)`;
// ctr=true centers it along X (like cylinder(center=true)).
module td_bore(h, d, ctr=false)
  translate([ctr ? -h/2 : 0, 0, 0])
    rotate([90,0,0]) rotate([0,90,0]) linear_extrude(h) teardrop2d(d=d, ang=45);

module pylon_cut() {
  cz = pylon_width/2;
  // --- MOTOR MOUNT on the pad face (aft plane X=pad_aft) -- item 2, switches on mount_to ---
  if (mount_to == "motor") {
    // Bolt STRAIGHT to the A2212 cross (LONG axis up-mast Y, SHORT across width Z), shifted OUTBOARD by
    // motor_offset_z.  Each screw threads into the motor's blind hole; a thin motor_seat_t carries the clamp
    // and a wider FRONT-access counterbore lets the socket head + hex driver reach in from the mast FRONT,
    // so the screw stays short (M3 x ~16).  Every bore runs along X (horizontal on the bed) -> TEARDROP.
    seat_x = pad_aft - motor_seat_t;                                   // head-seat shoulder (faces forward)
    for (h = motor_holes) {
      hy = pylon_rise + h[0];  hz = motor_zc + h[1];
      translate([-2, hy, hz])   td_bore(seat_x + 2, motor_head_d);     // front access + head counterbore -- TEARDROP
      translate([seat_x, hy, hz]) td_bore(motor_seat_t + 2, motor_screw_d); // screw clearance through the seat -- TEARDROP
    }
    if (motor_boss_reach > 0)   // central seat relief ONLY if a long boss pokes past the guard-washer (else seat stays flat)
      translate([pad_aft - (motor_boss_reach + 1), pylon_rise, motor_zc])
        td_bore(motor_boss_reach + 3, motor_boss_d);
  } else {
    // legacy: mount the metal X-plate on the pad SQUARE (holes at +/-bp_axis = the plate's outer "+" turned 45deg),
    // every hole through the whole pad -> open both sides (flat-head from the plate, nut on the forward face).
    bp_hole_l = 2*(pad_aft + 2);
    for (sy=[-1,1], sz=[-1,1])
      translate([0, pylon_rise + sy*bp_axis, cz + sz*bp_axis])
        td_bore(bp_hole_l, bp_screw_d, ctr=true);                      // 4x M3 plate-mount (X pattern) -- TEARDROP
  }
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
    translate([-eps, by, bz])
      td_bore(x_aft + 2, pylon_bolt_d);                              // clearance: mating face -> aft -- TEARDROP
    translate([x_aft - foot_cbore_h, by, bz])
      td_bore(foot_cbore_h + 2, foot_cbore_d);                       // head counterbore from the aft surface -- TEARDROP
  }
  // (item 3) the pylon cable-groove is GONE: the local motor's leads route
  // through the LID gland and zip-tie to the mast, so the mast face stays solid.
}

// standalone render: opening this file renders the PYLON (modeled flat).
oriented("pylon") difference() { pylon(); pylon_cut(); }
