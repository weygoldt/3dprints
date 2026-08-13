// =====================================================================
//  AIRBOAT ENCLOSURE -- PROPELLER GUARD  (flat frontal ARC grille + aft SHROUD)
//  Part of the airboat catamaran drive system.  Parameters + derived live in
//  common.scad (so main.scad can draw the guard on each hull); this file holds the
//  geometry, the echo fit-check, and the standalone render.
//
//  WHAT IT IS  (Patrick's calls, 2026-08-13)
//    A bolt-on guard for the 8x4.5 (203 mm) pusher prop that keeps reeds / grass /
//    branches off the disc.  It mounts to the SAME 4 holes the motor bracket uses --
//    sandwiched  pad | GUARD | BasePlate | motor  on the pad's 4x M3 square + 11.5
//    boss bore (the M3 screws just get guard_t longer; nut still on the pad face).
//    Two working faces:
//      * a FLAT frontal grille (intake side) -- the boat runs forward ~99% of the
//        time, so it intercepts what comes head-on; and
//      * an aft SHROUD wall wrapping the tips -- catches things swept in from the
//        SIDE, not just the front.
//    It is a PARTIAL arc: on the boat only the TOP + OUTBOARD faces are exposed (the
//    bottom is low near the water, the inboard side faces the sheltered channel
//    between hulls), so guard_arc covers just that sweep.  ALL edges are ROUNDED --
//    this lives in very turbulent air and fewer sharp corners = less turbulence.
//
//  PRINTS FLAT, SUPPORTLESS -- PETG on a Prusa MK3.  The frontal grille lies on the
//    bed; the shroud rises as a VERTICAL wall off it (walls parallel to the build
//    axis need no support); rounded edges use rounded PROFILES / selective edge
//    rounding (BOSL2 cyl/cuboid, native rotate_extrude) so nothing overhangs.
//  MIRRORS with `side` (common.scad) so the outboard bias lands on the right side of
//    each hull.  CONFIRM which way is outboard on your boat (name a feature).
//  Requires BOSL2 (../BOSL2) via common.scad.
// =====================================================================
include <common.scad>
use <pylon.scad>       // for the "onpylon" fit check (draws the real pylon + STL hardware ghosts)

$fn = 140;

/* [What to render] */
guard_part = "onpylon";   // [full, onpylon] full = the printable guard ; onpylon = bolted to the real pylon in front of the BasePlate + Motor + prop ghosts (fit check)

// =====================================================================
//  GEOMETRY  (flat in X-Y, extruded +Z = aft ; mount/frontal face at Z=0 -> pad/bed)
// =====================================================================
// a 2D rounded rectangle (all corners) for revolve profiles
module guard_rr2d(w, h) let(r = min(guard_round, w/2-0.01, h/2-0.01))
  offset(r=r) offset(delta=-r) square([w, h]);

// a rounded bar revolved over the kept arc: cross-section w(radial) x h(axial), centred at radius r_ctr, base on Z=0
module guard_arc_bar(r_ctr, w, h)
  rotate([0,0,guard_a0]) rotate_extrude(angle = guard_full_ring ? 360 : guard_arc, $fn=240)
    translate([r_ctr - w/2, 0]) guard_rr2d(w, h);

// a radial spoke, TAPERED root->tip (elegant): hull of a wide rounded cylinder at the hub and a thin one at the
// rim -> rounded sides + rounded TOP edge, flat bottom on the bed.  (Cylinders avoid the thin-face rounding limit.)
module guard_spoke(a)
  rotate([0,0,a]) hull() {
    translate([guard_hub_r - 1, 0, 0])   // wide root, welds into the hub
      cyl(h=guard_t, r=guard_spoke_root/2, rounding2=min(guard_round, guard_spoke_root/2-0.01),
          rounding1=min(guard_front_round, guard_spoke_root/2-0.01), anchor=BOTTOM);
    translate([guard_r_tip - guard_bar/2 + 0.8, 0, 0])   // tip ENDS at the shroud inner face (embeds 0.8, never pokes through the outer)
      cyl(h=guard_t, r=guard_bar/2, rounding2=min(guard_round, guard_bar/2-0.01),
          rounding1=min(guard_front_round, guard_bar/2-0.01), anchor=BOTTOM);
  }

// SHROUD: an arc wall with a filleted inner FOOT (reinforces the root + adds bed contact) and rounded lips.
// Built tall (h_max) then trimmed by a tilted-plane mask so the top height TAPERS from h_max at the arc middle
// (best-supported, most protection) to h_min at the ends -- a single tilted plane gives a smooth cosine taper.
module guard_shroud_2d() let(rr = min(guard_round, guard_shroud_wall/2 - 0.05), f = guard_shroud_foot)
  offset(r=rr) offset(delta=-rr)
    polygon([[guard_r_tip - f, 0], [guard_r_out, 0], [guard_r_out, guard_shroud_h],
             [guard_r_tip, guard_shroud_h], [guard_r_tip, f]]);
// height-taper mask: keep z <= z0 + m*u, where u = distance in the arc-centre direction -> h peaks at the middle
module guard_height_mask()
  let(ext = guard_full_ring ? 0 : guard_shroud_ext,
      ca  = cos(guard_arc/2 + ext),
      m   = (guard_shroud_h - guard_shroud_h_min) / (guard_r_tip * (1 - ca)),
      z0  = guard_shroud_h - m*guard_r_tip,
      tilt = atan(m), BIG = 2000)
  rotate([0,0,guard_a_ctr]) translate([0,0,z0]) rotate([0,-tilt,0]) translate([0,0,-BIG]) cube(2*BIG, center=true);
module guard_shroud_wall_m()
  intersection() {
    rotate([0,0,guard_a0 - (guard_full_ring?0:guard_shroud_ext)])
      rotate_extrude(angle = guard_full_ring ? 360 : guard_arc + 2*guard_shroud_ext, $fn=280) guard_shroud_2d();
    if (guard_full_ring) translate([0,0,-1]) cylinder(h=guard_shroud_h+2, r=guard_r_out+1); else guard_height_mask();
  }

// MOUNT HUB -- a round RING: the big central motor bore (guard_motor_bore) is cut in guard_full, leaving an annulus
// that carries the 4 M3 bolts (24 mm square, same as the pad) around it.  With the new order (guard AFT of the
// X-bracket) the ring no longer protrudes forward into the sloped buttress, so it stays round (no pad-clip needed).
module guard_hub()
  cyl(h=guard_t, r=guard_hub_r, rounding2=guard_round, rounding1=guard_front_round, anchor=BOTTOM);
module guard_hub_lightening() { }

// PIECE 1 -- the BARREL: bolts to the X-bracket (4 M3 on the pad's 24 mm square), bores clear for the motor barrel,
// bridges guard_barrel_len so the guard's short shroud reaches the prop.  Prints as a tube on its flange, supportless.
module guard_barrel() {
  difference() {
    union() {
      // rounded-square base LOFTED (BOSL2 skin) up into the round tube -- smooth aero pedestal, not a step
      skin([ rect([guard_barrel_od, guard_barrel_od], rounding=8), circle(d=guard_barrel_od) ],
           slices=24, z=[0, guard_loft_h], caps=true);
      up(guard_loft_h) cylinder(h=guard_barrel_len - guard_loft_h, d=guard_barrel_od);               // tube above the loft
    }
    translate([0,0,-1]) cylinder(h=guard_flange_t+1, d=guard_motor_bore);                            // SNUG base bore -- the 4 bolts sit in this ring
    translate([0,0,guard_flange_t]) cylinder(h=guard_barrel_len, d=guard_barrel_bore);               // wide bore above -> the 4 clamp screws + motor pass through
    for (p = guard_mount_xy) translate([p[0],p[1],-1]) cylinder(h=guard_flange_t+2, d=guard_bolt_d); // 4x M3 clamp-screw clearance -> pad's 24 mm square
  }
}

// PIECE 2 -- the GUARD: baseplate + spokes + shroud.  Butts the barrel's aft rim and is held by the SAME 4 motor
// screws running through it (sandwich clamp -- no glue).  guard_bore_d clears the motor; the 4 holes land on the 24 mm square.
module guard_full() {
  spoke_as = guard_full_ring
    ? [ for (i=[0:guard_spokes-1]) guard_a0 + (guard_a1-guard_a0)*i/guard_spokes ]
    : [ for (i=[0:guard_spokes-1]) guard_a0 + (guard_a1-guard_a0)*i/(guard_spokes-1) ];
  difference() {
    union() {
      guard_hub();                                                                 // baseplate ring (OD = barrel OD -> flush stack)
      for (r = guard_ring_radii) guard_arc_bar(r, guard_bar, guard_t);              // intermediate frontal ring arcs
      for (a = spoke_as) guard_spoke(a);                                            // frontal spokes (end spokes cap the arc)
      if (guard_shroud) guard_shroud_wall_m();                                      // aft SHROUD wall (filleted foot + rounded lips)
    }
    translate([0,0,-1]) cylinder(h=guard_t+2, d=guard_bore_d);                      // motor-barrel bore (through)
    for (p = guard_mount_xy) translate([p[0],p[1],-1]) cylinder(h=guard_t+2, d=guard_bolt_d); // 4x M3 sandwich-clamp screws pass through
  }
}

// =====================================================================
//  ECHO FIT-CHECK
// =====================================================================
echo("=== AIRBOAT PROP GUARD (flat arc grille + aft shroud) ===");
echo(str("  prop ", prop_diameter, " (r ", prop_radius, ") ; shroud inner r ", guard_r_tip, " (tip gap ", guard_tip_gap,
         ") ; OD ", guard_od, " ; side ", side));
echo(str("  ARC: keep ", guard_arc, " deg (", round(100*guard_arc/360), "% of the ring, ", round(100*(360-guard_arc)/360),
         "% removed), ", guard_arc_bias, " deg off TOP toward OUTBOARD -> spans ", round(guard_a0), "..", round(guard_a1),
         " deg (0=outboard, 90=top) -> covers TOP + OUTBOARD"));
echo(str("  frontal grille: full hub r ", guard_hub_r, " + ", guard_rings, " ring", guard_rings==1?"":"s", " + ",
         guard_spokes, " spokes ; bar ", guard_bar, " x ", guard_t, " ; all edges rounded r", guard_round));
echo(str("  SHROUD: ", guard_shroud ? str("on -- r ", guard_r_tip, "..", guard_r_out, " wall, rises ", guard_shroud_h,
         " mm AFT (spans the prop plane ", round(10*guard_standoff)/10, " mm back) -> guards the SIDE, prints as a vertical wall (SUPPORTLESS)")
         : "off"));
echo(str("  mount: 4x M3 clearance ", guard_bolt_d, " on the pad's ", bp_pitch, " mm square (+/-", bp_axis,
         ", bolt circle r ", round(10*bp_axis*sqrt(2))/10, ") AROUND a ", guard_motor_bore, " mm MOTOR BORE (barrel passes through)"));
echo(str("  bore<->bolt WALL = ", round(100*((bp_axis*sqrt(2) - guard_bolt_d/2) - guard_motor_bore/2))/100,
         " mm ", ((bp_axis*sqrt(2) - guard_bolt_d/2) - guard_motor_bore/2) >= 1.2 ? "OK"
         : "  << VERY THIN: the bore nearly meets the bolts (fixed 24 mm square) -- confirm barrel dia / accept (plate clamps on the metal bracket)"));
echo(str("  ORDER: pylon pad | X-BRACKET | GUARD (motor thru bore) | motor  -> guard sits aft of the bracket, nearer the prop"));
echo(str("  2-PIECE SANDWICH: BARREL spacer (len ", guard_barrel_len, ", OD ", guard_barrel_od,
         ") + GUARD, clamped by the SAME 4 motor screws (NO glue) ; shroud reaches ", guard_barrel_len + guard_shroud_h, " mm from the bracket"));
echo(str("  print: BARREL on its flange (tube vertical -> supportless) ; GUARD face-down (spokes flat, shroud vertical) -- both supportless"));
echo(str("  screws: 4x M3 ~", round(guard_barrel_len + guard_flange_t + guard_t + 8), " mm long -- pad | X-bracket | barrel flange | (down the ",
         guard_barrel_bore, " open bore) | guard ; wide tube bore clears the screws at r", round(10*bp_axis*sqrt(2))/10));
echo(str("  CONFIRM which way is OUTBOARD before printing (set side) -- don't trust a bare left/right."));
echo("------------------------------------------------------------");

// =====================================================================
//  STANDALONE RENDER  (guard-local: Z=0 = the X-bracket face, +Z = aft)
// =====================================================================
module guard_2piece_ghosts() {   // motor barrel + prop disc phantoms for the assembly views
  color([0.12,0.12,0.13,0.7]) cylinder(h=28, d=motor_body_d);                                  // motor barrel through the bores
  color([0.85,0.2,0.2,0.30]) translate([0,0,32]) cylinder(h=1.6, r=prop_radius, center=true);  // prop disc (the shroud must cover this)
}
if (guard_part == "barrel") {
  color([0.75,0.75,0.78]) guard_barrel();                                   // PIECE 1 alone (printable)
} else if (guard_part == "assembly") {
  color([0.75,0.75,0.78,0.92]) guard_barrel();                              // barrel
  color("DarkSeaGreen") translate([0,0,guard_barrel_len]) apply_side() guard_full();  // guard glued at the barrel aft
  guard_2piece_ghosts();
} else if (guard_part == "onpylon") {
  color("Tan") difference() { pylon(); pylon_cut(); }
  translate([pad_aft, pylon_rise, pylon_width/2]) rotate([0,90,0]) {         // guard-local Z -> pylon +X (aft)
    color([0.75,0.75,0.78,0.95]) guard_barrel();
    color("DarkSeaGreen") translate([0,0,guard_barrel_len]) apply_side() guard_full();
    guard_2piece_ghosts();
  }
} else {
  color("DarkSeaGreen") apply_side() guard_full();   // PIECE 2 (the guard) alone (printable; side mirrors via common's `side`)
}
