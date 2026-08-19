// SEAT-PRELOAD probe: measures the real clamp built by caps.scad -- no replica geometry.
//
//   The plug is left exactly where bore_cap() builds it (flange bottom at z=0, so the
//   flange's SEATING face is at z=cap_flange_t) and intersected with the wall as SOLID
//   material occupying z = cap_flange_t .. cap_flange_t+wall.  That is the plug pushed
//   fully HOME.  Whatever survives is bead standing inside wall material -- i.e. spring
//   the fingers are still holding:
//
//   EMPTY      -> the seated plug touches nothing.  It has axial free play and rattles;
//                 this is what the pre-2026-08 revision actually built (cap_preload was
//                 measured from the ramp START, so the cone never reached the hole).
//   NON-EMPTY  -> real preload, and the export measures it (the echo prints all three):
//                   Z top       == the wall's inner plane
//                   Z extent    == how far past first engagement the plug is driven
//                   X/Y extent  == the cone radius there, CLIPPED by the slot that
//                                  straddles the +X axis -> sqrt(R^2 - (slot_w/2)^2)
//
//   Run with -D probe_fam='"big"' -D probe_d=... (-D reaches through the include).
include <caps.scad>

// NOTE these assignments must come AFTER the include.  OpenSCAD resolves each scope's
// variables last-assignment-wins before any geometry is built, so putting them first
// would lose to caps.scad's own `cap = "both"` and the probe would also render the row.
cap       = "none";
probe_fam = "small";  // [small, big]
probe_d   = 0;        // the hole to seat into; 0 -> the family's LOOSEST hole (d_max), the worst case

probe_bore = (probe_fam == "big") ? bore_big : bore_small;
probe_hole = (probe_d > 0) ? probe_d : probe_bore[1];

// the wall as SOLID material (the complement of wall_stub's bore), seated against the flange
module wall_solid(hole_d, wall_t)
  difference() {
    translate([0, 0, cap_flange_t]) linear_extrude(wall_t) square(hole_d + 16, center = true);
    translate([0, 0, cap_flange_t - eps]) cylinder(h = wall_t + 2*eps, d = hole_d);
  }

probe_spring = cap_seat_spring(probe_bore, probe_hole);   // radial spring still held in the fingers
probe_R      = probe_hole/2 + probe_spring;               // cone radius at the wall's inner plane
probe_dz     = probe_spring * cap_bead_ax / (cap_bor(probe_bore) - cap_tor(probe_bore));
probe_bb     = sqrt(probe_R*probe_R - (cap_slot_w/2)*(cap_slot_w/2));  // slot clips the +X axis

echo(str("PROBE fam=", probe_fam, " hole=", probe_hole, " -> radial spring ", probe_spring,
         " (cone radius ", probe_R, ")"));
echo(str("  expect NON-EMPTY, X/Y half-extent ", probe_bb, " , Z ",
         cap_flange_t + probe_bore[2] - probe_dz, " .. ", cap_flange_t + probe_bore[2],
         " (extent ", probe_dz, ")"));

intersection() {
  bore_cap(probe_bore);
  wall_solid(probe_hole, probe_bore[2]);
}
