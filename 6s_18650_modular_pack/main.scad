$fn = $preview ? 24 : 120;
include <BOSL2/std.scad>
include <BOSL2/screws.scad>

max_outer_diam = 57;
cell_d = 18.6;
cell_h = 65;
padding = 0.1;
plate_thick = 10;

// Effective spacing between cell centers
cell_spacing = cell_d + padding;
row_spacing = sqrt(3) * cell_spacing / 2;

module bat18650(x, y) {
  color("lightblue", 1)
    translate([x, y, cell_h / 2])
      cylinder(h=cell_h, d=cell_d, center=true);
}

module contact_bump(x, y, z) {
  translate([x, y, z])
    prismoid(size1=[6, 6], size2=[3, 6], h=2, center=true);
}

module cell_bundle() {
  // Define rows with number of cells per row, from bottom to top
  rows = [2, 3, 2];

  row_count = len(rows);
  middle_row_index = floor(row_count / 2); // index of center row (1)

  for (row_idx = [0:row_count - 1]) {
    num_cells = rows[row_idx];

    // y-coordinate: offset from center row
    y = (row_idx - middle_row_index) * row_spacing;

    // Center the row horizontally
    x_offset = -( (num_cells - 1) * cell_spacing) / 2;

    for (i = [0:num_cells - 1]) {
      x = i * cell_spacing + x_offset;
      bat18650(x, y);
    }
  }
}

module bump_bundle() {
  // Define rows with number of cells per row, from bottom to top
  rows = [2, 3, 2];

  row_count = len(rows);
  middle_row_index = floor(row_count / 2); // index of center row (1)

  for (row_idx = [0:row_count - 1]) {
    num_cells = rows[row_idx];

    // y-coordinate: offset from center row
    y = (row_idx - middle_row_index) * row_spacing;

    // Center the row horizontally
    x_offset = -( (num_cells - 1) * cell_spacing) / 2;

    for (i = [0:num_cells - 1]) {
      x = i * cell_spacing + x_offset;
      contact_bump(x, y, 0);
    }
  }
}

difference() {
  translate([0, 0, plate_thick / 2])
    cylinder(h=plate_thick, d=max_outer_diam, center=true);
  translate([0, 0, 4])
    cell_bundle();

  // holes for the fastening screws
  translate([0, 25, 0])
    screw_hole("M3,30");
  translate([0, -25, 0])
    screw_hole("M3,30");
  translate([22, -12.5, 0])
    screw_hole("M3,30");
  translate([-22, -12.5, 0])
    screw_hole("M3,30");
  translate([22, 12.5, 0])
    screw_hole("M3,30");

  // holes for the 12 AWG cables
  translate([-23, 10, 0])
    screw_hole("M4,30");
  translate([-20.5, 14.5, 0])
    screw_hole("M4,30");

  // supressions for nickel band to roll through
  // those also need to go through the top and bottom row
  translate([-10, 0, 3 + 0.5])
    cube([6, 6, 1], center=true);
  translate([+10, 0, 3 + 0.5])
    cube([6, 6, 1], center=true);
  translate([0, 16, 3 + 0.5])
    cube([6, 6, 1], center=true);
  translate([0, -16, 3 + 0.5])
    cube([6, 6, 1], center=true);
  translate([-14, 0, 3 + 0.5])
    cube([6, 35, 1], center=true);
}

translate([0, 0, 5])
  color("red", 0.5)
    bump_bundle();
