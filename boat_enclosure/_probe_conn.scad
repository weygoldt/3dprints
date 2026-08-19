// PROBE (scratch): does the 2D-slice notch actually clear the REAL 3D box?
// Intersect the bracket with the real stern box -> should be EMPTY (clearance gap).
// A positive control (no notch) proves the probe can see a collision.
include <common.scad>
use <body.scad>
include <connector.scad>
conn_show = "none";

probe = "real";  // "real" = bracket ∩ box (want EMPTY) ; "control" = blank ∩ box (want NON-empty)

if (probe == "real")
  intersection() {
    connector_solid(-1, conn_z_fore);
    stern_placed(-1) body("rc");
  }
else
  intersection() {
    // blank with NO notch -- positive control, must collide
    scr = -conn_rail_span/2; ins = -hd_x;
    xo = scr - conn_boss; xi = ins + conn_in; xlo=min(xo,xi); xhi=max(xo,xi);
    translate([xlo, conn_ytop, conn_z_fore - conn_w/2]) cube([xhi-xlo, conn_ybot-conn_ytop, conn_w]);
    stern_placed(-1) body("rc");
  }
