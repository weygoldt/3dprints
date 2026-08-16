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

// V-KEEL skid cross-section (X-Y at a station): full width w at the top, then the bottom keel_frac tapers IN to a keel
// of width kw -> a boat-hull section (flat top, V bottom with a small keel flat).
module skid_section(w, kw) let(yt = foam_top_y + deck_t, yv = yt + skid_t*(1 - keel_frac), yb = yt + skid_t)
  polygon([[-w/2,yt], [w/2,yt], [w/2,yv], [kw/2,yb], [-kw/2,yb], [-w/2,yv]]);
// one skid = a boat hull: full V-section for most of the length, PLAN-tapering to a narrow prow, and ROUNDED at the
// top-front so the bow sweeps up and rounds over toward the deck (Patrick 2026-08-16).
module skid() let(yt = foam_top_y + deck_t) hull() {
  translate([0,0,-skid_len/2])                 linear_extrude(eps) skid_section(skid_w, keel_w);          // stern (full)
  translate([0,0, skid_len/2 - bow_taper_len]) linear_extrude(eps) skid_section(skid_w, keel_w);          // start of the bow taper
  translate([0,0, skid_len/2 - bow_round])     linear_extrude(eps) skid_section(keel_w*1.8, keel_w*0.6);  // bow keel (narrow, low)
  // ROUNDED bow crown: a cylinder (axis athwartship) tucked below the deck at the bow -> the top-front rounds over
  translate([0, yt + bow_round, skid_len/2 - bow_round]) rotate([0,90,0]) cylinder(h = keel_w*1.8, r = bow_round, center = true);
}

module foam_body() {
  color([0.86, 0.86, 0.80]) difference() {
    union() {
      difference() {                                  // deck (top plate); central water cutout only if enabled
        foam_slab(deck_w, deck_len, deck_t, foam_top_y, deck_r);
        if (deck_cutout_on) deck_cutout();
      }
      for (s = [-1, 1]) translate([s*skid_center, 0, 0]) skid();   // two V-keel skids glued underneath
    }
    bow_rake_cut();
  }
}

// standalone render: opening this file renders the foam body alone.
foam_body();
