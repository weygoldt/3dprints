// GUARD-BORE alignment probe.  The guard doubles as the motor washer, so all 4 M3 screws pass
// THROUGH it: stack = pylon pad | guard-washer | motor.  Its bore pattern comes from gmxy(mount_rot)
// and the pad's from mholes(mount_rot); if those ever drift apart the screws foul the guard.  This
// re-checks it after the 2026-08-20 clock change (motor_clock 45 -> 135 for the port hull).
//
// Both bodies are built in the UN-tilted pad frame -- the motor tilt is a common transform for the
// guard and the screws, so it cancels in an intersection test.
//
//   offset_deg = 0  -> the real screws vs the guard.  Want EMPTY (they pass clean through).
//   offset_deg = 15 -> control: swing the screw pattern 15 deg off the bores.  Must be NON-EMPTY,
//                      otherwise the probe cannot see a misalignment at all.
include <common.scad>
use <propguard.scad>

offset_deg = 0;
rot        = mount_rot;
flip_z     = 0;   // 1 = negate the test pattern's WIDTH component (i.e. try the mirrored position)

intersection() {
  translate([pad_aft, pylon_rise, motor_zc]) rotate([0,90,0]) guard_full(rot, wire_slot_ang, false);
  for (h = mholes(rot + offset_deg))
    translate([pad_aft - 1, pylon_rise + h[0], motor_zc + (flip_z ? -h[1] : h[1])])
      rotate([0,90,0]) cylinder(h = guard_t + 4, d = 3.0);
}
