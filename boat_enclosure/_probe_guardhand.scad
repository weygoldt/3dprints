// WHICH HAND GOES ON WHICH HULL -- measured, not reasoned.
//
// A mirror is invisible to a probe and a bare "left/right" has been wrong here before, so this file does not
// argue about sides.  It drops two MARKER spheres through the exact transform chain main.scad uses and lets
// the exported mesh say where they land in BOAT coordinates:
//
//   probe_what = "hub"   a marker at the guard's hub (the motor axis)
//   probe_what = "exit"  a marker at the wire channel's OUTBOARD mouth, on the plate edge
//
// Read the marker's world X (athwartships).  The hull centre is at +/-hull_dx, the boat centreline at X=0.
// If |X_exit| < |X_hub| the leads run toward the centreline (INBOARD); if greater, they run OUTBOARD.
//
//   for d in 1 -1; do for h in 1 -1; do for w in hub exit; do
//     openscad -o out.stl --export-format binstl --render=force \
//              -D motor_offset_dir=$d -D probe_hull=$h -D probe_what=\"$w\" _probe_guardhand.scad
//   done; done; done
//
// CONTROL: probe_what="hub" must land within a millimetre of the hull centre for every combination -- if it
// does not, the chain is wrong and the exit numbers mean nothing.
include <common.scad>
include <connector.scad>          // hull_dx
use <propguard.scad>
conn_show = "none";

probe_hull = -1;      // -1 = the hull main.scad calls "port", +1 = "starboard"
probe_what = "exit";  // hub | exit
probe_r    = 21;      // radius along the channel axis for the "exit" marker (the plate edge is at 22)

module marker() sphere(r = 1.5, $fn = 24);

module placed(sgn)
  translate([sgn*hull_dx, 0, 0]) apply_side_of(sgn < 0 ? "port" : "starboard")
    translate([0, 0, box_back_z])
      translate([pylon_width/2, mm_pad_yc + foot_h/2, mm_block_aft_z]) rotate(a=180, v=[1,0,-1])
        motor_tilted() translate([pad_aft, pylon_rise, motor_zc]) rotate([0,90,0])
          children();

// probe_what = "view": the PART as Patrick specified it -- looking straight at the face that screws to the
// pylon, with up-mast UP.  rotate([0,180,0]) turns the bed face (z=0) toward the top view while keeping +Y
// up, so guard-local +X falls on the LEFT of the image, which is what "looking at it from the pylon" means.
// Render it as a plain TOP view:
//   openscad -o hand.png --render=force --projection=o --viewall --autocenter \
//            -D motor_offset_dir=1 -D probe_what='"view"' _probe_guardhand.scad
if (probe_what == "view") rotate([0,180,0]) guard_full();
else placed(probe_hull) {
  if (probe_what == "hub") translate([0, 0, guard_t/2]) marker();
  else translate([probe_r*cos(wire_slot_ang), probe_r*sin(wire_slot_ang) + wire_slot_off, guard_t/2]) marker();
}

echo(str("hand motor_offset_dir=", motor_offset_dir, "  hull=", probe_hull < 0 ? "port" : "starboard",
         "  marker=", probe_what, "  wire_slot_ang=", wire_slot_ang, "  hull_dx=", hull_dx));
