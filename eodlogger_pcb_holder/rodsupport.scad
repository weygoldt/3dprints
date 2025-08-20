include <../BOSL2/std.scad>
include <../BOSL2/threading.scad>
include <main_vars.scad>

// Helper for port holes
module rounded_cutout(diam, height, rot, pos) {
  translate(pos) {
    rotate(rot) {
      union() {
        cylinder(h=height, d=diam, center=true);
        translate([diam / 2, 0, 0]) {
          cube([diam, diam, height], center=true);
        }
      }
    }
  }
}

// Through-ports for connectors ----------------------------------
module port_holes() {
  // Large port
  rounded_cutout(port_large_d, main_h * 1.3, [0, 0, 90], [0, port_large_y, main_h / 2]);

  // Small ports
  for (sx = [-1, 1])
    if (sx < 0) {
      rot = 225;
      rounded_cutout(port_small_d, main_h * 1.3, [0, 0, rot], [sx * port_small_x, port_small_y, main_h / 2]);
    } else {
      rot = -45;
      rounded_cutout(port_small_d, main_h * 1.3, [0, 0, rot], [sx * port_small_x, port_small_y, main_h / 2]);
    }

  // Dip in center to route wires
  translate([0, -2, main_h * 2 / 3]) {
    cylinder(h=main_h / 2, d=port_large_d, center=false);
  }
}

// Main outer shell (no holes)
module main_body()
  difference() {
    translate([0, 0, edge_r])
      cylinder(h=main_h - edge_r, d=main_d);
  }

// Rounded or plain exterior -------------------------------------
module rounded_shell() {
  minkowski() {
    difference() {
      main_body();
      port_holes();
    }
    sphere(r=edge_r);
  }
}

// Screw holes for M4 screws ------------------------
module screw_holes(x, y) {
  translate([x, y, main_h / 2]) {
    threaded_rod(d=4, l=main_h * 1.3, pitch=0.7, internal=true);
  }
}

color("lightblue", 1)
  difference() {
    rounded_shell();
    screw_holes(x=20, y=0);
    screw_holes(x=-20, y=0);
  }
