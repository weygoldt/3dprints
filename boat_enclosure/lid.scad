// =====================================================================
//  AIRBOAT ENCLOSURE -- LID  (the top panel; prints outer face down)
// Part of the airboat catamaran enclosure. See common.scad for the
// frame mapping, all parameters, the fit-check echoes, and shared helpers.
// =====================================================================
include <common.scad>

// --- knuckle hinge: DOOR leaf (lid side of the outboard -X hinge) ---
module door_leaf_2d() {
  translate([Ax, Ay]) circle(d=knuckle_d);
  polygon([[Ax - kr, -lid_t], [-W/2 + 0.6, -lid_t],
           [-W/2 + 0.6, Ay], [Ax - kr, Ay]]);
}

module hinge_door() {
  difference() {
    hinge_segments(1) door_leaf_2d();
    pin_bore_cut(+1);     // lid prints outer face down -> print-up = +y
  }
}

// --- lid overlap skirt + snap-lock bumps (full top-face perimeter) ---
module door_skirt() {
  difference() {
    rprism(W, H, ov_d, corner_r);
    translate([0, -eps, 0])
      rprism(W-2*skirt_t, H-2*skirt_t, ov_d+3*eps, corner_r-skirt_t);
  }
  for (z = lock_zs) translate([W/2-skirt_t+eps, lock_y, z]) lock_wedge(LEFT);
  if (n_locks >= 2) translate([0, lock_y,  H/2-skirt_t+eps])  lock_wedge(DOWN);
  if (n_locks >= 3) translate([0, lock_y, -(H/2-skirt_t)-eps]) lock_wedge(UP);
  if (grip)
    translate([lid_w/2, -lid_t, 0]) rotate([-90, 0, 0])
      prismoid(size1=[3, bump_l], size2=[0.8, bump_l*0.75],
               shift=[-1.1, 0], h=2);
}

// =====================================================================
//  LID  (the top panel)
// =====================================================================
module lid_body() {
  translate([0,-lid_t,0]) rprism(lid_w, lid_h, lid_t, lid_r);
}

module lid_gland_cut() {   // item 3: through-hole for the local motor's phase leads
  if (lid_gland)
    translate([lid_gland_x, -lid_t-eps, lid_gland_z]) rotate([-90,0,0])
      cylinder(h=lid_t+2*eps, d=lid_gland_d);
}

module lid() {
  difference() { lid_body(); lid_gland_cut(); }   // gland pierces only the panel
  hinge_door();
  door_skirt();
}

// standalone render: opening this file renders the LID (outer face down).
oriented("lid") apply_side() lid();
