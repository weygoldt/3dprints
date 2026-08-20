// MOTOR-SCREW INSERTION probe (Patrick 2026-08-20: "a barrel head will not go in there and
// be able to pass through the screw hole").
//
// The 4 M3 motor screws thread SQUARE into the tilted motor face, so their axis is the TILTED
// one.  A screw is rigid: to reach its seat it must sweep ALONG THAT AXIS from outside the part.
// Swept volume per screw = the head disc (head_od) from its SEATED underside forward to daylight,
// plus the shank (shank_d) along the whole axis.  Intersect with the solid pylon and measure the
// VOLUME left in the way (not the triangle count -- the head's seated face is coplanar with the
// counterbore floor, which yields degenerate zero-volume facets even on a perfect part).
//
//   sweep_tilt = motor_tilt  -> the real screw axis.  Want ~0 mm^3.
//   sweep_tilt = 0           -> positive control: what a straight fore-aft tunnel asks of the
//                               screw.  Must be LARGE (it fouls the tilted clearance bore).
//   sweep_tilt = motor_tilt-3 -> fine control: a 3 deg misalignment must show up as a small but
//                               NON-zero volume, proving the gate resolves near-misses too.
include <common.scad>
use <pylon.scad>

feature    = "motor";      // "motor" = the 4 M3 motor screws | "foot" = the 4 M4 foot bolts
sweep_tilt = motor_tilt;   // degrees; see above (motor feature only)
rot        = mount_rot;    // 45 (dir +1) / 135 (dir -1) -- run BOTH hulls
head_od    = 5.5;          // M3 socket/barrel head OD (DIN912; the bore is motor_head_d=8 for a washer)
shank_d    = 3.0;          // M3 shank
APPROACH   = 60;           // start well forward of the part (forward-most feature is x=-fg_reach)

// same pivot as motor_tilted(), but at an arbitrary angle so the probe can be de-tuned
module sweep_tilted(t)
  translate([pad_aft, pylon_rise, 0]) rotate([0,0,t]) translate([-pad_aft, -pylon_rise, 0]) children();

// the volume a screw sweeps on its way to the seat, along the axis at (y,z)
module screw_sweep(y, z) {
  seat_x = pad_aft - motor_seat_t;                       // seated head underside
  translate([-APPROACH, y, z]) rotate([0,90,0]) {
    cylinder(h = APPROACH + seat_x,  d = head_od);       // head, swept to its seat
    cylinder(h = APPROACH + pad_aft, d = shank_d);       // shank, swept through the pad
  }
}

// The 4 M4 FOOT bolts go in from AFT and must reach daylight through the buttress face.  That
// face moves with motor_tilt (head_aft), and a review once caught bores dead-ending inside it,
// so re-check it here: sweep each bolt (head + shank) from behind the part to its seated depth.
module foot_sweep() {
  for (sy = [-1,1], sz = [-1,1])
    let (by    = foot_h/2 + sy*mm_bolt_y/2,
         bz    = pylon_width/2 + sz*mm_bolt_x/2,
         x_aft = base_aft + (head_aft - base_aft)*(by/pad_y0))
      translate([0, by, bz]) rotate([0,90,0]) {
        cylinder(h = x_aft + APPROACH, d = 4.2);                       // shank, all the way through
        translate([0,0,x_aft - foot_cbore_h])                          // head, swept in from aft
          cylinder(h = foot_cbore_h + APPROACH, d = foot_cbore_d - 0.5);
      }
}

intersection() {
  pylon_part(rot);
  if (feature == "foot") foot_sweep();
  else sweep_tilted(sweep_tilt)
         for (h = mholes(rot)) screw_sweep(pylon_rise + h[0], motor_zc + h[1]);
}
