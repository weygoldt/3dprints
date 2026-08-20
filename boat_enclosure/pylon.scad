// =====================================================================
//  AIRBOAT ENCLOSURE -- PYLON  (LOWERED + NOSE-DOWN rev, 2026-08-19)
//  Separate bolt-on part.  See common.scad for the frame mapping, all parameters, the fit-check echoes
//  and shared helpers.
//
//  WHY THIS REV (Patrick's handoff: rigid + STOP THE NOSE-DIVE)
//    (1) LOWERED -- the hub drops from 111.5 to pylon_rise (56.5) above the deck: prop bottom ~2 cm above
//        the waterline (the prop sweeps AFT of the transom over open water, so the deck is no longer the
//        clearance floor).  A short mast is far stiffer (bending ~1/L^3) AND halves the bow-down thrust couple.
//    (2) NOSE-DOWN motor pad -- the motor pad, its bores and the guard are tilted about the WIDTH axis at the
//        hub so the prop THRUST points forward-and-DOWN by motor_tilt.  A down-forward thrust at the stern
//        pushes the stern down / bow up and aims the thrust line at the CoM -> nulls the residual dive.  The
//        tilt is about the extrude (Z) axis, so it stays a pure 2D-plane feature (motor_tilted() in common).
//    (3) STRUCTURE re-added (handoff #1): a DEEP AFT BUTTRESS base (resists reverse thrust) + a FORWARD GUSSET
//        bearing on the block top (resists the forward-thrust tipping in compression, off-loading the 4 bolts).
//
//  PRINT: SIDE-print.  The 2D silhouette (X = fore-aft, Y = up-mast) is extruded along Z = width; the part lies
//  on its Z=0 face with the mast flat on the bed and the layers running ALONG the mast.  Teardrop bores (apex
//  +Z = build-up) keep it supportless.  Motor CENTRED (motor_zc = pylon_width/2) -> SYMMETRIC: ONE part both
//  hulls (only the guard's arc + the motor-cross rotation lean L/R).
//
//  FROZEN: the HOUSING connector (mating face X=0 + register tongue + 4x M4 pattern) and the MOTOR mount
//  (A2212 cross 19x16 + boss recess + the flat washer/guard face) are unchanged -- same block, same motor.
//
//  Frame: X = fore-aft (0 = forward MATING face, +X = aft/motor) ; Y = up-mast ; Z = width (motor centred).
// =====================================================================
include <common.scad>

// teardrop bore: axis +X (fore-aft), APEX toward +Z (= the side-print build-up) so the horizontal hole
// self-supports.  Drop-in for `rotate([0,90,0]) cylinder(h,d)`; ctr=true centres it along X.
module td_bore(h, d, ctr=false)
  translate([ctr ? -h/2 : 0, 0, 0])
    rotate([90,0,0]) rotate([0,90,0]) linear_extrude(h) teardrop2d(d=d, ang=45);

// (head_aft -- the oversized vertical head aft face for the tilt-trim -- is derived in common.scad.)

// ---- 2D structural silhouette (X = fore-aft +aft, Y = up-mast) ------------------------------------------
//   main body : forward face flat at X=0 (block mating plane, extended up as the mast front) ; aft face a nearly
//               full-depth slab (base_aft at the foot -> head_aft at the head, ~1 mm of taper) = the DEEP, STIFF
//               BUTTRESS base that resists reverse thrust (a short mast wants section, not a dramatic taper).
//   fwd gusset: crisp forward brace, flat underside on the block top (fg_y0) reaching to the stern wall
//               (-fg_reach), apex at the hub height (0,fg_y1) -> compression path that off-loads the bolts.
//   tongue    : crisp register key into the block slot.
module pylon_2d() {
  union() {
    offset(r=pylon_fillet) offset(delta=-pylon_fillet)
      polygon([[0,0], [base_aft,0], [head_aft,pad_y0], [head_aft,mast_top_y], [0,mast_top_y]]);
    if (fwd_gusset) polygon([[eps,fg_y1], [eps,fg_y0], [-fg_reach,fg_y0]]);          // forward gusset (crisp)
    translate([-reg_depth, (foot_h-reg_h)/2]) square([reg_depth+eps, reg_h]);         // register tongue (crisp)
  }
}
module pylon() color("Tan") linear_extrude(pylon_width) pylon_2d();

// tilted-pad trim: remove everything AFT of the pad plane (through the hub, tilted by motor_tilt about the
// width axis) so the motor + guard bear on a genuine FLAT face perpendicular to the (forward+down) thrust.
module pad_trim() motor_tilted() translate([pad_aft, -600, -600]) cube([600, 1200, 1200]);

// bores.  Motor cross + boss are cut in the TILTED frame (perpendicular to the pad); foot bolts run straight
// +X through the frozen foot into the block.  All teardrops (apex +Z) -> supportless in the side-print.
module pylon_cut(rot = mount_rot) {
  seat_x = pad_aft - motor_seat_t;
  // M3 screw CLEARANCE + boss: TILTED (perpendicular to the pad, so the screw threads square into the tilted motor).
  motor_tilted() {
    for (h = mholes(rot))
      translate([seat_x, pylon_rise + h[0], motor_zc + h[1]]) td_bore(motor_seat_t + 3, motor_screw_d);  // seat -> into the motor
    if (motor_boss_reach > 0)                                                 // central relief only if a long boss pokes past the guard
      translate([pad_aft - (motor_boss_reach + 1), pylon_rise, motor_zc]) td_bore(motor_boss_reach + 3, motor_boss_d);
  }
  // HEAD COUNTERBORE + DRIVER ACCESS: one bore per screw, COAXIAL WITH THAT SCREW -- so it lives inside
  // motor_tilted() with the M3 clearance it continues, and the two are one straight hole from daylight to the motor.
  //   WHY (Patrick, 2026-08-20 -- "a barrel head will not go in there and pass through the screw hole"): this bore
  //   used to run STRAIGHT fore-aft while the screw is TILTED, so the two met at a motor_tilt KINK right at the seat.
  //   A screw is rigid: it can only travel along its own axis, and that axis walked out of the straight tunnel within
  //   ~5 mm and then bored into solid mast.  _probe_screw.scad measures 571 mm^3 of PLA standing in the 4 screws'
  //   insertion paths -- all four were blocked, and the seat face was not square to the head either.  The old comment
  //   here justified the straight bore by "a tilted tunnel exits too low for the bottom holes": true, they now descend
  //   as they run forward and clip the forward gusset's angled front tip -- which Patrick pre-authorised removing, is
  //   the least-loaded knife edge of the gusset, and is measured by the driver_bear_clear echo guard in common.scad.
  //   Access on the boat is unchanged in kind (the mouths still open above the block); the motor goes on at the BENCH
  //   with the front fully open anyway.  Uniform seat depth -> ALL 4 SCREWS ARE STILL THE SAME LENGTH.
  motor_tilted() for (h = mholes(rot))
    translate([-driver_reach, pylon_rise + h[0], motor_zc + h[1]])
      td_bore(driver_reach + seat_x, motor_head_d);      // daylight -> the head seat (floor square to the screw)
  // 4x M4 FOOT bolts: clearance along +X through the foot to the ACTUAL (buttress) aft face + a socket-head
  // COUNTERBORE recessed from that face (bolt inserted from aft, threads into the block insert; frozen, not tilted).
  // The re-added deep buttress pushed the aft face back to ~base_aft, so the bore MUST reach it -- a pad_aft-length
  // bore would dead-end ~5 mm inside the buttress and the pylon could not be bolted on (review blocker, 2026-08-19).
  for (sy = [-1,1], sz = [-1,1])
    let (by    = foot_h/2 + sy*mm_bolt_y/2,
         bz    = pylon_width/2 + sz*mm_bolt_x/2,
         x_aft = base_aft + (head_aft - base_aft)*(by/pad_y0)) {   // buttress aft face X at this bolt height
      translate([-eps, by, bz])                td_bore(x_aft + 2,        pylon_bolt_d);   // clearance -> through the aft face
      translate([x_aft - foot_cbore_h, by, bz]) td_bore(foot_cbore_h + 2, foot_cbore_d);   // socket-head counterbore from aft
    }
}

// the finished part: solid, trimmed to the tilted pad, bored.  Used by the standalone render AND main.scad's drive().
module pylon_part(rot = mount_rot) difference() { pylon(); pad_trim(); pylon_cut(rot); }

// standalone render: opening this file renders the PYLON in its SIDE-print pose (mast flat on the bed).
oriented("pylon") pylon_part();
