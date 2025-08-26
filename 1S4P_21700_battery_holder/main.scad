$fn = $preview ? 64 : 120;
include <../BOSL2/std.scad>
include <../BOSL2/screws.scad>

// Some common battery configurations possible in this holder:
// -----------------------------------------------------------
// Protected KEEPOWER 26650 cell height: 68.5 mm
// Unprotected standard 26650 cell height: 65 mm
// Two Baby C / LR14 / Baby 1.5V cells in series: 100 mm
// -----------------------------------------------------------

// Adjust this parameter to change the cell height
cell_height = 74.5; // height of the cell
cell_width = 21.1; // diameter of the cell

contact_spring_clearance = 4.5; // clearance for contact spring in z direction
contact_spring_width = 8.1; // width of the contact spring 
contact_spring_len = 12; // length of the contact spring
contact_spring_slot = 1; // depth of the contact spring slot
contact_spring_opening_offset = contact_spring_len / 2; // offset for the contact spring opening from the xycenter of one battery
contact_spring_slot_hole_distance = 4; // distance between the opening and the slot hole for the retainer

cell_d = cell_width;
cell_h = cell_height + 2 * contact_spring_clearance;
max_outer_diam = 54;
padding = 1;
bottom_top_thick = 2;

// Effective spacing between cell centers
cell_spacing = cell_d + padding;
row_spacing = sqrt(3) * cell_spacing / 2;

module body() {
  height = cell_h + bottom_top_thick * 2;
  translate([0, 0, height / 2]) {
    cylinder(h=height, d=max_outer_diam, center=true);
  }
}

module bat18650(x, y) {
  color("lightblue", 1)
    translate([x, y, cell_h / 2])
      cylinder(h=cell_h, d=cell_d, center=true);
}

module cell_bundle(
  rows = [2, 1],
  cell_spacing = 21,
  row_spacing = 21,
  cell_d = 18,
  cell_h = 65,
  add_openings = true,
  opening_width = 25, // ~0.66 of cell diameter
  opening_depth = 18, // default ~ one diameter outwards
  clearance = 0.2 // small extra for fit
) {
  row_count = len(rows);

  // --- compute nominal row y positions (about a "center row") ---
  middle_row_index = (row_count - 1) / 2;
  row_y = [for (r = [0:row_count - 1]) (r - middle_row_index) * row_spacing];

  // --- collect all cell centers (pre-centering) ---
  _pos_nested = [
    for (row_idx = [0:row_count - 1]) let (
      n = rows[row_idx],
      y = row_y[row_idx],
      x0 = -( (n - 1) * cell_spacing) / 2
    ) [for (i = [0:n - 1]) [i * cell_spacing + x0, y]],
  ];
  pts = [for (row = _pos_nested) for (p = row) p]; // flatten

  // --- mean-centering (balance point) ---
  n = len(pts);
  cx = sum([for (p = pts) p[0]]) / n;
  cy = sum([for (p = pts) p[1]]) / n;
  pts_shifted = [for (p = pts) [p[0] - cx, p[1] - cy]];

  // --- helper: opening block for one cell at (sx,sy) ---
  module radial_opening(sx, sy) {
    // unit vector from origin to cell center (default +X if at origin)
    len = sqrt(sx * sx + sy * sy);
    ux = (len == 0) ? 1 : sx / len;
    uy = (len == 0) ? 0 : sy / len;

    // angle for rotation about Z so +X aligns with radial direction
    theta = atan2(sy, sx); // degrees

    // geometry
    r = cell_d / 2 + clearance; // tangent radius
    w_open = opening_width; // width of the opening block
    d_open = opening_depth; // outward extent
    h_open = cell_h; // same height as cell

    // Place a centered cube, oriented along +X, then rotate & position:
    // Inner face tangent to the cylinder; block extends outward by d_open.
    translate([sx, sy, 0]) {
      rotate([0, 0, theta]) {
        translate([r, 0, h_open / 2]) {
          //difference() {
          cube([d_open, w_open, h_open], center=true);
          // Nubsies to retain the battery in the opening
          // translate([-d_open / 4, -d_open / 2, 0]) {
          //  sphere(r=1.5);
          // }
          // }
          translate([-10, 0, 0]) cube([1, contact_spring_width, 100], center=true);
          translate([-18.5, 0, 0]) cube([8, contact_spring_width, 100], center=true);
          //translate([-20, 0, (cell_h + bottom_top_thick * 2) / 2 - 1 / 2]) cube([26, contact_spring_width * 1.4, 1.1], center=true);
          //translate([-20, 0, -( (cell_h + bottom_top_thick * 2) / 2 - 1 / 2)]) cube([26, contact_spring_width * 1.4, 1.1], center=true);
        }
      }
    }
  }

  // --- place cells and optional openings ---
  for (p = pts_shifted) {
    // if cell count is seven, only place six cells and skip the center one
    if (p[0] != 0 || p[1] != 0) {
      // your existing cell geometry
      bat18650(p[0], p[1]);
      // optional drop-in opening (negative)
      if (add_openings)
        radial_opening(p[0], p[1]);
    }
  }
}

difference() {
  body();
  translate([0, 0, bottom_top_thick]) {
    translate([0, 0, cell_h / 2 + 0.5]) {
      cylinder(h=cell_h + 10, d=cell_width * 0.8, center=true);
    }
    cell_bundle(rows=[2, 2], cell_spacing=cell_spacing, row_spacing=cell_spacing, cell_d=cell_d, cell_h=cell_h, add_openings=true, opening_width=cell_width * 0.99, opening_depth=22, clearance=0.2);
  }

  tol = 0.1;
  cable_channel_height = cell_h + 2 * bottom_top_thick + 2 * tol;
  translate([0, -(max_outer_diam / 2) * 0.8, cable_channel_height / 2 - tol])
    cylinder(h=cable_channel_height, d=5, center=true);
}
