// PROP-GUARD vs FOAM DECK probe.
//
// The guard rides on the tilted motor pad, so changing motor_tilt SWINGS it: a shallower tilt rotates the
// guard's low arc FORWARD, back toward the fibreglassed aft deck it nicked once before.  Re-run this
// whenever motor_tilt, the spoke ladder, or the hull geometry changes.
//
// WHY THIS PROBE WAS REWRITTEN (2026-08-22).  Two independent faults, both of which made it green:
//
//  1. IT COULD NOT SEE THE TWO HANDS.  It drew both hulls in one render by calling guard_full() twice --
//     but the guard's ARC (guard_a0/guard_a1/guard_spoke_a) is derived from the GLOBAL motor_offset_dir,
//     which one render has only one of.  So it tested dirP and a MIRRORED dirP, never the dirN part that
//     build.sh actually exports.  That is exactly how the pre-SPAR guard shipped with its deck trim on the
//     wrong end of the arc for the second hull: the part drove its low tip 24.55 mm into the foam, and
//     this file said EMPTY.  A probe that cannot distinguish the thing that broke is not a gate.
//     FIX: the hull is a PARAMETER and the hand is the global -- so you run it FOUR times, one per
//     (hand, hull) combination, and every one must come back EMPTY.
//
//  2. ITS CONTROL WAS A PARAMETER THAT GOT DELETED.  The control was `-D guard_arc_lo_trim=0`, and the
//     SPAR rev removed guard_arc_lo_trim entirely.  OpenSCAD accepts a -D for an unknown variable in
//     silence -- no warning, no error -- so the control became a no-op that rendered the DEFAULT geometry
//     and came back EMPTY, i.e. it "passed" by proving nothing at all.
//     FIX: the control is probe_roll, a rotation this file owns.  It cannot be deleted by a rev of the
//     part, and it fails loudly if the transform chain ever stops landing the guard on the boat.
//
// HOW TO RUN -- all four must be EMPTY:
//     for d in 1 -1; do for h in 1 -1; do
//       openscad -o /dev/null --export-format binstl --render=force \
//                -D motor_offset_dir=$d -D probe_hull=$h _probe_guarddeck.scad
//     done; done
// then the CONTROL -- all four must be NON-EMPTY, or the probe is not measuring the boat:
//     ... -D probe_roll=28 ...
//
include <common.scad>
include <connector.scad>          // hull_dx
use <propguard.scad>
use <float.scad>
conn_show = "none";

probe_hull = -1;    // -1 = port hull, +1 = starboard hull.  The HAND is the global motor_offset_dir.
probe_roll = 0;     // CONTROL: roll the guard this many degrees further toward the deck about the prop
                    // axis.  0 = the real part.  28 must come back NON-EMPTY on every combination.
                    // The sign follows motor_offset_dir because the arc's LOW end is a1 on one hand and
                    // a0 on the other -- rolling the wrong way would lift the guard and fake a pass.

// The guard, carried through the SAME chain main.scad uses:
//   hull offset -> side mirror -> box station -> drive() mount -> motor tilt -> pad face.
module guard_placed(sgn)
  translate([sgn*hull_dx, 0, 0]) apply_side_of(sgn < 0 ? "port" : "starboard")
    translate([0, 0, box_back_z])
      translate([pylon_width/2, mm_pad_yc + foot_h/2, mm_block_aft_z]) rotate(a=180, v=[1,0,-1])
        motor_tilted() translate([pad_aft, pylon_rise, motor_zc]) rotate([0,90,0])
          rotate([0, 0, motor_offset_dir*probe_roll])          // the control, in the guard's own frame
            guard_full(mount_rot, wire_slot_ang, false);

echo(str("=== GUARD vs DECK: hand motor_offset_dir=", motor_offset_dir, " on hull ",
         probe_hull < 0 ? "PORT" : "STARBOARD", " ; probe_roll=", probe_roll,
         probe_roll == 0 ? "  (want EMPTY)" : "  (CONTROL -- want NON-EMPTY)"));
echo(str("    spokes at ", guard_spoke_a, " deg ; arc ", guard_a0, "..", guard_a1));

intersection() {
  guard_placed(probe_hull);
  translate([0, 0, deck_center_z]) foam_body();
}
