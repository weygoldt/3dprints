include <../BOSL2/std.scad>
include <../BOSL2/screws.scad>
include <main_vars.scad>

// Main outer shell (no holes)
module main_body() {
  difference() {
    translate([0, 0, edge_r])
      cylinder(h=plate_thick - edge_r, d=main_d);
    translate([0, +( (main_d + 2) / 2 + 5), (plate_thick * 1.3) / 2])
      cube([main_d + 2, main_d + 2, plate_thick * 1.3], center=true);
    translate([0, -( (main_d + 2) / 2 + 5), (plate_thick * 1.3) / 2])
      cube([main_d + 2, main_d + 2, plate_thick * 1.3], center=true);
  }
}

// Rounded or plain exterior -------------------------------------
module rounded_shell() {
  minkowski() {
    main_body();
    sphere(r=edge_r);
  }
}

// Screw holes for M4 screws ------------------------
module screw_holes(x, y) {
  translate([x, y, main_h / 2]) {
    screw_hole("M4,30", thread=false);
  }
  translate([x, y, 3])
    nut_trap_inline(4, "M4");
}

color("lightblue", 1)
  difference() {
    rounded_shell();
    screw_holes(x=20, y=0);
    screw_holes(x=-20, y=0);
  }
