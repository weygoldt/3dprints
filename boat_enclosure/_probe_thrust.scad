// THRUST-DIRECTION probe.  The tilt sign is a known trap: a flipped motor_tilt makes the bow-dive
// WORSE, and no amount of "it looks right" catches a mirror.  So measure it instead of eyeballing.
//
// Renders ONE small marker, carried through the EXACT chain main.scad uses to place the drive on
// the port hull, at either end of the thrust vector:
//   -D pt="hub"  -> the prop hub
//   -D pt="tip"  -> hub + thrust_len along the thrust direction (pylon-local -X, tilted)
// Read each marker's centre from its STL bounds and subtract.  In the ASSEMBLY frame Z is +BOW and
// Y is DOWN (float.scad), so a correct nose-down thrust must come out  dZ > 0  and  dY > 0.
include <common.scad>
include <connector.scad>          // hull_dx
conn_show = "none";

pt         = "hub";               // "hub" | "tip"
thrust_len = 50;

module marker()
  translate([-hull_dx, 0, 0]) apply_side_of("port")
    translate([0, 0, box_back_z])
      translate([pylon_width/2, mm_pad_yc + foot_h/2, mm_block_aft_z]) rotate(a=180, v=[1,0,-1])
        motor_tilted()
          translate([pad_aft - (pt == "tip" ? thrust_len : 0), pylon_rise, motor_zc])
            cube(1, center = true);

marker();
