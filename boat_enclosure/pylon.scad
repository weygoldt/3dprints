// =====================================================================
//  AIRBOAT ENCLOSURE -- PYLON  (WEDGE rev: straight taper, motor CENTRED, prints on the BACK face)
//  Separate bolt-on part.  See common.scad for the frame mapping, all parameters, the fit-check echoes
//  and shared helpers.
//
//  WEDGE REV (Patrick, 2026-08-16)
//    The smooth side-print loft (organic, one-sided outboard offset) read as sci-fi next to the rugged
//    square housing boxes.  Replace it with a SIMPLE STRAIGHT WEDGE that matches the boxes:
//      * STRAIGHT edges taper toward the top -- the width tapers pylon_width -> pad_w_top and the fore-aft
//        depth tapers pad_aft -> mast_top_t, both linearly (a clean engineered gusset/wedge, no curves).
//      * the MOTOR is CENTRED on the mast (motor_zc = pylon_width/2), so the pylon is SYMMETRIC -- one part
//        fits both hulls (only the guard's arc leans L/R).
//      * it PRINTS ON THE BACKWARDS (aft) FACE instead of on the side: the flat X=pad_aft face lies on the
//        bed and the build rises fore-aft (+X).  The mast length (Y) still lies IN the layers, so the
//        bending strength is comparable to the old side print (Patrick).  Every bore now runs along the
//        build axis -> no teardrops.
//    FROZEN: the HOUSING connector (mating face X=0 + register tongue + 4x M4 pattern) and the MOTOR mount
//    (A2212 cross + boss recess + the flat aft washer face) are unchanged -- it still screws to the same
//    block and the same motor.
//
//  Frame: X = fore-aft (0 = forward MATING face, +X = aft/motor) ; Y = up-mast ; Z = width (0..pylon_width,
//  motor centred at pylon_width/2).  oriented("pylon") lays the aft face on the bed for printing.
// =====================================================================
include <common.scad>

// STRAIGHT WEDGE solid: a full-width/full-depth FOOT (the connector base) that tapers -- in width AND fore-aft --
// up to the motor pad, with the AFT face kept FLAT (X=pad_aft) so it prints face-down and carries the motor.
// Edges get a small 45deg CHAMFER (pylon_edge_ch, = the box edge_ch) so it reads rugged/machined like the housings.
module pylon() color("Tan") let(cz = pylon_width/2, ch = pylon_edge_ch) {
  union() {
    // FOOT: prismatic box, mating face (X=0) .. flat aft face (X=pad_aft), up to flare_y -- houses the 4 M4 + tongue.
    // Chamfer the LONG (Y-running) edges; the mating (X=0) and aft (X=pad_aft) faces + their bed edge stay effectively flat.
    hull() {
      translate([pad_aft/2, eps/2,      cz]) cuboid([pad_aft, eps, pylon_width], chamfer=ch, edges="Y", except=RIGHT);
      translate([pad_aft/2, flare_y,    cz]) cuboid([pad_aft, eps, pylon_width], chamfer=ch, edges="Y", except=RIGHT);
    }
    // MAST WEDGE: straight taper flare_y -> mast_top_y.  Flat AFT face (X=pad_aft) shared top+base; the FORWARD face
    // recedes (0 -> pad_aft-mast_top_t) and the WIDTH narrows (pylon_width -> pad_w_top), both linear.  Chamfered long edges.
    hull() {
      translate([pad_aft/2,               flare_y,    cz]) cuboid([pad_aft,     eps, pylon_width], chamfer=ch, edges="Y", except=RIGHT);
      translate([pad_aft - mast_top_t/2,  mast_top_y, cz]) cuboid([mast_top_t,  eps, pad_w_top],   chamfer=ch, edges="Y", except=RIGHT);
    }
    // REGISTER TONGUE (forward, into the block slot) -- part of the frozen connector (crisp)
    translate([-reg_depth, (foot_h - reg_h)/2, 0]) cube([reg_depth + eps, reg_h, pylon_width]);
  }
}

// bores -- all run along +X (the build axis in the back print), so plain cylinders (no teardrop needed).
module xbore(x0, y, z, len, d) translate([x0, y, z]) rotate([0,90,0]) cylinder(h = len, d = d, $fn = 48);
module pylon_cut() {
  cz = pylon_width/2;
  // MOTOR CROSS on the flat aft face (X=pad_aft), CENTRED: a FRONT-access counterbore (motor_head_d, lets the
  // socket head + driver reach from the forward side so the screw stays short) + the screw clearance through the seat.
  seat_x = pad_aft - motor_seat_t;
  for (h = motor_holes) {
    hy = pylon_rise + h[0]; hz = motor_zc + h[1];
    xbore(-2,     hy, hz, seat_x + 2,       motor_head_d);   // front access + head counterbore
    xbore(seat_x, hy, hz, motor_seat_t + 2, motor_screw_d);  // screw clearance through the seat
  }
  if (motor_boss_reach > 0)                                   // central seat relief only if a long boss pokes past the guard
    xbore(pad_aft - (motor_boss_reach + 1), pylon_rise, motor_zc, motor_boss_reach + 3, motor_boss_d);
  // 4x M4 FOOT bolts: a plain clearance hole through the foot (a vertical channel in the back print).  The socket head
  // sits PROUD on the flat aft face (exposed at the base, behind the pylon -- no interference, and reads rugged) so
  // there is NO down-facing counterbore to bridge -> the print stays supportless.
  for (sy = [-1,1], sz = [-1,1])
    xbore(-eps, foot_h/2 + sy*mm_bolt_y/2, cz + sz*mm_bolt_x/2, pad_aft + 2*eps, pylon_bolt_d);
}

// standalone render: opening this file renders the PYLON in its PRINT pose (aft face on the bed).
oriented("pylon") difference() { pylon(); pylon_cut(); }
