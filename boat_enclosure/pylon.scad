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

// a thin cross-section slab (chamfered long edges) at height Y: width w (Z, centred), fore-aft from the FLAT aft face
// (X=pad_aft) forward to fwd_x(Y) -- the forward face recedes linearly (pad_aft depth at the base -> mast_top_t at the top).
function fwd_x(Y) = max(0, (pad_aft - mast_top_t) * (Y - flare_y) / (mast_top_y - flare_y));  // forward-face X at height Y
module wslab(Y, w) let(fx = fwd_x(Y), d = pad_aft - fx)
  translate([(fx + pad_aft)/2, Y, pylon_width/2]) cuboid([d, eps, w], chamfer = pylon_edge_ch, edges = "Y", except = RIGHT);

// STRAIGHT WEDGE solid, printed on the FLAT aft face.  Three ruled sections:
//   FOOT   (0..flare_y)        full width/depth -- the connector base (4x M4 + tongue).
//   TAPER  (flare_y..pad_y0)   width narrows pylon_width -> pad_head_w (straight edges).
//   HEAD   (pad_y0..mast_top_y) CONSTANT width pad_head_w -- a rectangle whose aft face == the guard hub, so the guard
//                              base-plate aligns PERFECTLY with the pylon face.  (Fore-aft still recedes to mast_top_t.)
module pylon() color("Tan") {
  union() {
    hull() { wslab(eps/2,   pylon_width); wslab(flare_y,    pylon_width); }  // FOOT  (full, prismatic)
    hull() { wslab(flare_y, pylon_width); wslab(pad_y0,     pad_head_w); }   // TAPER (44 -> head width)
    hull() { wslab(pad_y0,  pad_head_w);  wslab(mast_top_y, pad_head_w); }   // HEAD  (constant width -- matches the guard hub)
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
