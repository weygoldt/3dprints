// DOVETAIL-FIT probe: measures the real joint built by rail.scad -- no replica geometry.
//
//   A "start" segment (male tang on its RIGHT) and an "end" segment (female socket on its
//   LEFT) are butted exactly as rail="trio" chains them, then the end segment is pulled
//   away along +X by `dx`.  For dx>0 the flat butt faces are separated, so any remaining
//   intersection can only be tang against socket wall.
//
//   dx = 0    -> intersection NON-EMPTY means the socket is tighter than the tang: a PRESS
//                FIT, and the overlap is the interference.  EMPTY means a slip fit.
//   dx > 0    -> the smallest dx that intersects is the joint's PULL-APART PLAY.
//
//   Run with -D dx=... -D dt_fit=... (-D reaches through the include).
include <rail.scad>

// NOTE this assignment must come AFTER the include.  OpenSCAD resolves each scope's
// variables last-assignment-wins before any geometry is built, so putting it first would
// lose to rail.scad's own `rail = "trio"` and the probe would also render a whole rail.
rail = "none";
dx   = 0;

echo(str("PROBE dt_fit=", dt_fit, " dx=", dx,
         "  predicted axial = dt_fit*sqrt(slope^2+1) = ", dt_axial));

intersection() {
  rail_segment("start");
  translate([seg_len + dx, 0, 0]) rail_segment("end");
}
