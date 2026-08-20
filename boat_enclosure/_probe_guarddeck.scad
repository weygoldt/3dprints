// PROP-GUARD vs FOAM DECK probe.
//
// The guard rides on the tilted motor pad, so changing motor_tilt SWINGS it: a SHALLOWER tilt
// rotates the guard's low arc FORWARD, back toward the fibreglassed aft deck it nicked once
// before (fixed 2026-08-19 by guard_arc_lo_trim=28).  Dropping 13 -> 10 deg re-opens that risk,
// so this must be re-run whenever motor_tilt changes.
//
//   default            -> guard (both hulls) INTERSECT foam.  Want EMPTY.
//   -D guard_arc_lo_trim=0 -> control: the low-arc trim removed, which is the
//                      geometry that DID nick the deck.  Must be NON-EMPTY -- it proves this long
//                      transform chain actually lands the guard on the boat, so that an empty
//                      "real" result means clearance and not a mis-placed probe.
include <common.scad>
include <connector.scad>          // hull_dx
use <propguard.scad>
use <float.scad>
conn_show = "none";

// The control is driven by OVERRIDING the global: -D guard_arc_lo_trim=0 (guard_full reads the
// global; it takes no trim argument).
// the guard, carried through the SAME chain main.scad uses: hull offset -> side mirror ->
// box station -> drive() mount -> motor tilt -> pad face.
module guard_placed(sgn, rot)
  translate([sgn*hull_dx, 0, 0]) apply_side_of(sgn < 0 ? "port" : "starboard")
    translate([0, 0, box_back_z])
      translate([pylon_width/2, mm_pad_yc + foot_h/2, mm_block_aft_z]) rotate(a=180, v=[1,0,-1])
        motor_tilted() translate([pad_aft, pylon_rise, motor_zc]) rotate([0,90,0])
          guard_full(rot, wire_slot_ang, false);

intersection() {
  union() {
    guard_placed(-1, mrot_of( 1));
    guard_placed( 1, mrot_of(-1));
  }
  translate([0, 0, deck_center_z]) foam_body();
}
