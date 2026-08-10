// =====================================================================
//  AIRBOAT ENCLOSURE -- BLANKING CAPS  (snap-in plugs for unused bores)
//  Part of the airboat catamaran enclosure.  See common.scad for the frame
//  mapping, all parameters, the fit-check echoes, and shared helpers.
//
//  Two identical snap plugs, one per bore FAMILY, sized to the SAME holes the
//  body/lid already cut (pulled from common.scad, so they can never drift):
//     SIDE cap -> the inboard cable-gland bores  (port_gland_d = 12   through wall  = 3)
//     LID  cap -> the on/off switch bore         (lid_switch_d = 12.2 through lid_t = 3)
//  Fit one whenever you DON'T install a gland / the switch in a bore -- it blanks
//  the hole for a finished look and splash/debris resistance.
//
//  MECHANISM -- a flanged, hollow, slotted push-plug (the classic panel snap plug):
//    * a FLANGE disc caps the hole mouth and seats flat on the OUTER wall face;
//    * a hollow TUBE shank passes through the 3 mm wall with slide clearance;
//    * the tube is split into cap_slots cantilever FINGERS by radial slots so it
//      breathes inward on the way in;
//    * an external snap BEAD near the tip springs out behind the wall's INNER face,
//      and its retention ramp holds the plug seated -- a light, hand-reversible click.
//  Insert from OUTSIDE (the fingers spring into the chamber -- open space sits behind
//  both bores: port_y=24 on the side wall, the rib keep-out under the lid switch).  Pry
//  the flange edge to pull it back out.  Only the bead protrusion (cap_interf) has to
//  deflect, so the finger travel -- and the bending strain -- stays tiny (echo below).
//
//  PRINTS FLANGE-DOWN, SUPPORTLESS: flange face flat on the bed (clean), shank up.  The
//  only overhang is the bead's retention ramp, held <=45 deg from vertical (echo); the
//  flange-top + tip chamfers self-support and the hollow pocket opens upward.
//
//  Requires BOSL2 (../BOSL2) via common.scad.  Print PLA or -- better for the snap --
//  PETG: its higher strain-to-yield gives the fingers more margin.  On PLA keep
//  cap_interf modest (default 0.25) so a finger survives repeated mount/unmount.
// =====================================================================
include <common.scad>

/* [What to render] */
cap   = "both";  // [both, lid, side, seated] -- a print row of caps, or ONE cap shown seated in a wall stub (preview)
cap_n = 1;       // copies of EACH family in the row (bump to fill the plate -- caps are tiny)

/* [Snap plug -- shared geometry] (both families share these; only the bore size differs) */
cap_clear       = 0.4;  // DIAMETRAL slide clearance: shank OD = hole - this (radial 0.2/side -> the shank slides freely)
cap_interf      = 0.25; // RADIAL bead protrusion past the hole edge = the retention lip AND the finger travel on insert.
                        // 0.25 = a light, reversible click (a blank, not load-bearing).  Drop to ~0.2 on PLA if a finger
                        // ever cracks; raise to ~0.35 for a firmer hold in tougher PETG.  Drives the strain echo below.
cap_flange_over = 2.5;  // flange overhang past the hole radius (covers the mouth + leaves a lip to pry under)
cap_flange_t    = 1.5;  // flange thickness (how proud the button sits on the wall face)
cap_flange_ch   = 0.6;  // 45 deg chamfer on the flange TOP outer edge (finished look; self-supports flange-down)
cap_base        = 0.9;  // solid closed base under the pocket -- blanks the hole AND sets the finger ROOT height (low = long fingers)
cap_tube_wall   = 1.2;  // finger wall thickness at the ROOT
cap_tube_taper  = 0.4;  // inner wall opens this much toward the tip -> fingers thin to (wall - taper) at the tip for compliance
cap_slots       = 4;    // radial relief slots -> that many cantilever fingers
cap_slot_w      = 1.2;  // slot width
cap_preload     = 0.1;  // how far the bead retention face sits INSIDE the wall's inner plane -> springs the flange snug down
cap_bead_ax     = 0.5;  // bead RETENTION ramp axial rise (tube OD -> apex): vs ~0.45 radial flare -> ~<=45 deg overhang, printable
cap_lead_ax     = 1.0;  // bead LEAD-IN ramp axial rise (apex -> tube OD): shallow = easy push-in, fully self-supporting
cap_tip         = 0.8;  // tube length above the lead-in ramp (finger tip)
cap_tip_ch      = 0.6;  // tip outer chamfer (entry lead)

// per-bore family: [hole diameter, wall thickness it passes through] -- taken straight from common.scad
lid_bore  = [lid_switch_d, lid_t];   // 12.2 mm through the 3 mm lid
side_bore = [port_gland_d, wall];    // 12   mm through the 3 mm inboard wall

// =====================================================================
//  THE CAP  (built in PRINTED orientation: flange bottom on the bed at z=0, shank +z up)
//  One solid of revolution (rotate_extrude of the half cross-section) then split into
//  fingers by the slot cuts.  Cross-section points are [radius, height].
// =====================================================================
module bore_cap(hole_d, wall_t) {
  hr     = hole_d/2;
  tor    = hr - cap_clear/2;            // tube (shank) outer radius -- slide fit in the hole
  bor    = hr + cap_interf;             // bead outer radius -- protrudes past the hole edge (the retention lip)
  ir     = tor - cap_tube_wall;         // finger inner radius at the root
  ir_top = ir + cap_tube_taper;         // finger inner radius at the tip (tapered thinner)
  fr     = hr + cap_flange_over;        // flange radius
  ft     = cap_flange_t;

  y_ret  = ft + wall_t - cap_preload;   // bead retention face -- just inside the wall's inner plane (pulls the flange snug)
  y_apex = y_ret + cap_bead_ax;         // bead widest point (apex)
  y_btop = y_apex + cap_lead_ax;        // bead lead-in top -- back to the tube OD
  y_top  = y_btop + cap_tip;            // finger tip

  difference() {
    rotate_extrude($fn = max($fn, 96))
      polygon([
        [0, 0], [fr, 0],                                  // flange bottom (on the bed)
        [fr, ft - cap_flange_ch], [fr - cap_flange_ch, ft], // flange side + top chamfer
        [tor, ft],                                        // in across the flange top to the tube OD
        [tor, y_ret], [bor, y_apex], [tor, y_btop],       // tube OD up, bead retention ramp OUT, lead-in ramp back IN
        [tor, y_top - cap_tip_ch], [tor - cap_tip_ch, y_top], // tube to the tip + tip chamfer
        [ir_top, y_top],                                  // across the tip face to the inner wall
        [ir, cap_base], [0, cap_base]                     // tapered inner wall down to the pocket floor, in to the axis
      ]);
    // relief slots: cap_slots radial cuts from the base up past the tip -> discrete cantilever fingers.
    // Each spans axis->past-bead in radius and leaves the solid base (z < cap_base) intact.
    for (i = [0 : cap_slots - 1])
      rotate([0, 0, i*360/cap_slots])
        translate([(bor + 1)/2, 0, cap_base + (y_top - cap_base)/2 + eps])
          cube([bor + 1, cap_slot_w, y_top - cap_base + 2*eps], center = true);
  }
}

// translucent wall stub with the bore, for the seated preview (NOT printed)
module wall_stub(hole_d, wall_t)
  color([0.7, 0.7, 0.75], 0.35) difference() {
    translate([0, 0, cap_flange_t]) linear_extrude(wall_t) square(hole_d + 16, center = true);
    translate([0, 0, cap_flange_t - eps]) cylinder(h = wall_t + 2*eps, d = hole_d);
  }

// =====================================================================
//  ECHO FIT-CHECK  (house style: report the number and the bar it must clear)
// =====================================================================
function cap_strain(bore) =            // constant-section cantilever snap-fit strain: 1.5 * h * Y / L^2
  let (wall_t = bore[1],
       L = (cap_flange_t + wall_t - cap_preload + cap_bead_ax) - cap_base,  // finger root(base) -> bead apex
       h = cap_tube_wall - cap_tube_taper/2,                                 // mean finger thickness
       Y = cap_interf)                                                       // deflection = bead protrusion
  1.5 * h * Y / (L*L);

echo("=== BLANKING CAPS (snap-in plugs for unused bores) ===");
echo(str("  SIDE cap: hole ", side_bore[0], " (gland bore) through wall ", side_bore[1],
         "  ; LID cap: hole ", lid_bore[0], " (switch bore) through lid ", lid_bore[1]));
echo(str("  shank OD = hole - ", cap_clear, " (radial slide clearance ", cap_clear/2,
         ") ; bead protrudes ", cap_interf, " past the hole -> retention lip ", cap_interf, " mm"));
bead_oh = atan((cap_interf + cap_clear/2)/cap_bead_ax);   // steepest overhang: the bead retention ramp (wall-independent)
echo(str("  SUPPORTLESS check: bead retention ramp = ", round(10*bead_oh)/10, " deg from vertical ",
         bead_oh <= 45 ? "OK (<=45, prints flange-down with no support)"
                       : "  << WARNING: raise cap_bead_ax (ramp too horizontal)"));
echo(str("  finger bending strain on insert: SIDE ", round(1000*cap_strain(side_bore))/10, "% , LID ",
         round(1000*cap_strain(lid_bore))/10, "% ",
         max(cap_strain(side_bore), cap_strain(lid_bore)) <= 0.03
           ? "OK (<=3% -- fine for PETG; PLA good for a few cycles)"
           : "  << high: lengthen the fingers (lower cap_base) or reduce cap_interf"));
echo(str("  flange dia: SIDE ", side_bore[0] + 2*cap_flange_over, " , LID ", lid_bore[0] + 2*cap_flange_over,
         " ; cap height ~", round(10*(cap_flange_t + max(side_bore[1],lid_bore[1]) - cap_preload
                                      + cap_bead_ax + cap_lead_ax + cap_tip))/10, " mm"));
// LID flange must sit inside the switch rib keep-out (rib-free zone the lid already carves)
lid_keepout = min(switch_ftp[0] + 2*switch_clear, switch_ftp[1] + 2*switch_clear);
echo(str("  LID flange ", lid_bore[0] + 2*cap_flange_over, " vs switch rib keep-out ", lid_keepout, " ",
         lid_bore[0] + 2*cap_flange_over <= lid_keepout ? "OK (seats clear of the lid ribs)"
                                                        : "  << WARNING: shrink cap_flange_over"));
// SIDE flange vs the closest neighbour on the inboard wall (a fitted gland footprint, or another cap)
min_gland_pitch = min([ for (i=[0:len(gland_zs)-1], j=[i+1:len(gland_zs)-1]) abs(gland_zs[i]-gland_zs[j]) ]);
side_neighbour_gap = min_gland_pitch - (side_bore[0] + 2*cap_flange_over)/2 - port_ftp/2;
echo(str("  SIDE flange vs nearest gland (pitch ", min_gland_pitch, ", gland ftp ", port_ftp,
         "): clear gap ", round(10*side_neighbour_gap)/10, " mm ",
         side_neighbour_gap >= 2 ? "OK" : "  << tight: a cap crowds an adjacent gland"));
echo(str("  print FLANGE-DOWN, supportless ; PETG preferred for the snap (PLA OK at cap_interf<=", cap_interf, ")"));
echo(str("  splash: the ", cap_base, " mm closed base + seated flange block the bore; add a smear of silicone / a"));
echo("  foam washer under the flange if you want it watertight rather than just splash-resistant.");
echo("------------------------------------------------------------");

// =====================================================================
//  STANDALONE RENDER
//   cap="both"/"lid"/"side" -> a print row (flange-down, ready to slice)
//   cap="seated"            -> one LID cap shown pushed into a wall stub (assembly preview)
// =====================================================================
bores = (cap == "lid")  ? [ for (i=[0:cap_n-1]) lid_bore ]
      : (cap == "side")  ? [ for (i=[0:cap_n-1]) side_bore ]
      :                    concat([ for (i=[0:cap_n-1]) lid_bore ], [ for (i=[0:cap_n-1]) side_bore ]);
pitch = (max(lid_bore[0], side_bore[0]) + 2*cap_flange_over) + 4;   // flange dia + 4 mm gap

if (cap == "seated") {
  bore_cap(lid_bore[0], lid_bore[1]);
  wall_stub(lid_bore[0], lid_bore[1]);
} else {
  for (i = [0 : len(bores)-1])
    translate([i*pitch - (len(bores)-1)*pitch/2, 0, 0]) bore_cap(bores[i][0], bores[i][1]);
}
