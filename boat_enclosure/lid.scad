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
// a rounded slab, Y in [-t,0], with a 45deg chamfer on the OUTER (Y=-t, bed) edge.
// Printed outer-face-DOWN, the chamfer flares from an inset bed line up to full
// width -> self-supporting (brim recommended: it shrinks bed contact on the panel).
module chamfered_slab(w, h, t, r, ch) {
  union() {
    translate([0, -t+ch, 0]) rprism(w, h, t-ch, r);               // straight part above the chamfer
    hull() {                                                       // 45deg chamfer frustum on the bottom edge
      translate([0, -t,    0]) rprism(w-2*ch, h-2*ch, eps, max(0.5, r-ch));
      translate([0, -t+ch, 0]) rprism(w, h, eps, r);
    }
  }
}

module lid_body() {
  ch = (edge_ch > 0) ? edge_ch : 0;
  translate([0,-lid_t,0])
    if (ch > 0) translate([0,lid_t,0]) chamfered_slab(lid_w, lid_h, lid_t, lid_r, ch);
    else rprism(lid_w, lid_h, lid_t, lid_r);
}

// item 8 -- UNDERSIDE stiffening WAFFLE: kills the 185x3 mm panel bow that breaks
// the skirt seal.  Ribs stand +Y INTO the chamber when closed; printed outer-face-
// DOWN they build UP off the panel -> supportless.  The field is bounded by a
// perimeter ring and EVERY internal rib runs ring-to-ring (terminates on the ring,
// so no bar overshoots into a ragged free end); a clean disc is kept clear around
// the on/off switch hole.  Shallower than the first cut (rib_h) -- it only needs to
// stiffen the panel, not reach deep into the cavity.
module lid_ribs_mod() {
  prx = W/2 - skirt_t - rib_inset;    // perimeter ring centre (X), inboard of the lip
  prz = H/2 - skirt_t - rib_inset;    //                          (Z)
  difference() {
    union() {
      for (x = rib_xs) translate([x - rib_t/2, 0, -prz]) cube([rib_t, rib_h, 2*prz]); // longitudinal (Z), ring-to-ring
      for (z = rib_zs) translate([-prx, 0, z - rib_t/2]) cube([2*prx, rib_h, rib_t]); // transverse  (X), ring-to-ring
      difference() {                                                                   // perimeter ring
        rprism(2*prx + rib_t, 2*prz + rib_t, rib_h, corner_r - wall);
        translate([0,-eps,0]) rprism(2*prx - rib_t, 2*prz - rib_t, rib_h + 2*eps, corner_r - wall);
      }
    }
    if (lid_switch)                                                                    // clean disc around the switch hole
      translate([lid_switch_x, -eps, lid_switch_z]) cylinder(h = rib_h + 2*eps, r = lid_switch_d/2 + switch_clear);
  }
}

// item 10 -- shallow shadow-gap panel line recessed into the OUTER (bed) face:
// reads as a hatch cover, not a blank slab.  A shallow bridged pocket (prints
// outer-face-down); paired with the ribs so thinning the visible deck costs ~0 stiffness.
module panel_line_cut() {
  if (lid_panel_line) {
    pw = lid_w - 2*panel_inset;
    ph = lid_h - 2*panel_inset;
    pr = max(1, lid_r - panel_inset);
    translate([0, -lid_t - eps, 0]) difference() {
      rprism(pw + panel_w, ph + panel_w, panel_d + eps, pr);
      translate([0,-eps,0]) rprism(pw - panel_w, ph - panel_w, panel_d + 3*eps, pr);
    }
  }
}

module lid_switch_cut() {   // through-hole for the on/off switch (motors now exit via the side glands)
  if (lid_switch)
    translate([lid_switch_x, -lid_t-eps, lid_switch_z]) rotate([-90,0,0])
      cylinder(h=lid_t+2*eps, d=lid_switch_d);
}

module lid() {
  difference() {
    union() {
      lid_body();
      if (lid_ribs) lid_ribs_mod();
    }
    lid_switch_cut();    // switch hole pierces the panel (ribs are notched clear)
    panel_line_cut();    // deck shadow-gap line
  }
  hinge_door();
  door_skirt();
}

// standalone render: opening this file renders the LID (outer face down).
oriented("lid") apply_side() lid();
