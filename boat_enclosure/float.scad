// =====================================================================
//  AIRBOAT -- FOAM CATAMARAN BODY  (XPS; NOT printed -- assembly/clearance)
//  The float the two enclosures ride on: a full-width DECK (top plate) with a
//  central water-access CUTOUT, and TWO SKIDS glued to its underside (the
//  catamaran floats).  Hand-cut XPS; modeled so the whole vehicle can be seen
//  and the raked bow planned.  See common.scad for the frame + all parameters.
//
//  Frame: X athwartship (centreline X=0), Y down (foam TOP at Y=D), Z +bow.
//  Foam is modeled CENTRED at Z=0; main.scad shifts it by deck_center_z.
// =====================================================================
include <common.scad>

// a rounded-rect slab: w (X) x l (Z), thickness t along +Y starting at y0
module foam_slab(w, l, t, y0, r) {
  translate([0, y0, 0]) hull() for (sx=[-1,1], sz=[-1,1])
    translate([sx*(w/2-r), 0, sz*(l/2-r)]) rotate([-90,0,0]) cylinder(h=t, r=r);
}

// central water-access cutout through the deck (rounded rect, centred)
module deck_cutout() {
  foam_slab(deck_cut_w, deck_cut_len, deck_t + 2*eps, foam_top_y - eps, deck_cut_r);
}

// the raked bow: one inclined cut across the whole front.  A big block hinged at
// the top-bow edge (Y=D, Z=bow_tip) and tilted bow_rake_ang from vertical, so the
// underside is swept back (-Z) toward a forward top point -> ski-tip / raked stem.
module bow_rake_cut() {
  if (bow_rake_ang > 0) {
    BIG = 3000;
    translate([0, foam_top_y, bow_tip_z]) rotate([-bow_rake_ang, 0, 0])
      translate([-BIG/2, 0, 0]) cube([BIG, BIG, BIG]);   // occupies +Y (down) & +Z (fwd) of the hinge
  }
}

module foam_body() {
  color([0.86, 0.86, 0.80]) difference() {
    union() {
      difference() {                                  // deck (top plate) with the water cutout
        foam_slab(deck_w, deck_len, deck_t, foam_top_y, deck_r);
        deck_cutout();
      }
      for (s = [-1, 1]) translate([s*skid_center, 0, 0])   // two skids glued underneath
        foam_slab(skid_w, skid_len, skid_t, foam_top_y + deck_t, skid_r);
    }
    bow_rake_cut();
  }
}

// standalone render: opening this file renders the foam body alone.
foam_body();
