// =====================================================================
//  AIRBOAT ENCLOSURE -- PROPELLER GUARD  (restyled to BELONG with the pylon)
//  Part of the airboat catamaran drive system.  Parameters + derived live in
//  common.scad (so main.scad can draw the guard on each hull); this file holds the
//  geometry, the echo fit-check, and the standalone render.
//
//  VISUAL-COHESION REV (Patrick, 2026-08-15)
//    The pylon was sculpted into a smooth BOSL2 skin() loft with softly rounded
//    edges.  The old guard -- a flat pancake hub, thin wire spokes, a thin arc and a
//    little lip -- looked SLAPPED ON next to it.  This rev restyles the guard to share
//    the pylon's surface language so it reads as ONE designed family:
//      * a HUB that is a pad-echo rounded RECTANGLE (same outline + soft corners as the
//        motor pad) -- it grows OUT of the pad instead of sitting on it as a disc ;
//      * broad SCULPTED VANES (fins) whose roots nearly kiss into a bloom near the hub
//        and split toward the rim, replacing the thin wire spokes ;
//      * ONE flowing ROLLED RIM (the old thin ring + the separate foot-fillet shroud
//        merged into a single rolled bead) ;
//      * every edge eased to ~2.5 (the pylon's rmax) EXCEPT the bed-contact / intake
//        edges, which stay crisp -- exactly the pylon's rule (round everything but the
//        face on the bed).  Select the family with guard_style (bloom | web | legacy).
//
//  WHAT IT IS  (unchanged function -- all HARD constraints preserved)
//    A bolt-on guard for the 8x4.5 (203 mm) pusher prop that keeps reeds / grass /
//    branches off the disc.  In motor mode the guard doubles as the motor WASHER:
//    stack  pylon pad | GUARD | motor  -- it bolts the A2212 cross and its central
//    bore is the boss recess; the four motor pads bear on the FLAT aft hub face.
//    It is a PARTIAL arc (top + outboard only; the bottom is near the water, the
//    inboard side faces the sheltered channel between hulls).  The motor breathes
//    OPEN aft (drone-outrunner cooling) -- this is a FRONTAL debris screen, NOT a
//    cage at the disc plane.
//
//  PRINTS FLAT, SUPPORTLESS -- PETG on a Prusa MK3.  The frontal (intake) face lies on
//    the bed at Z=0; the rolled edges are on the AFT face (UP on the bed) so they
//    self-support; bed-contact edges stay crisp (a rounded bed edge would LIFT into an
//    overhang).  The rim rises as a near-vertical wall (supportless).  BRIM the thin
//    arc extremities (PETG first-layer lift).
//  MIRRORS with motor_offset_dir (motor mode) so the outboard bias lands on the right
//    side of each hull.  CONFIRM which way is outboard on your boat (name a feature).
//  Requires BOSL2 (../BOSL2) via common.scad.
// =====================================================================
include <common.scad>
use <pylon.scad>       // for the "onpylon" fit check (draws the real pylon + STL hardware ghosts)

$fn = 140;

/* [What to render] */
guard_part = "full";   // [full, onpylon] full = the printable guard ; onpylon = bolted to the real pylon in front of the BasePlate + Motor + prop ghosts (fit check)
show_prop  = true;     // onpylon: draw the translucent prop-disc ghost (turn off for clean cohesion shots)
show_motor = true;     // onpylon: draw the Motor.stl ghost
mono       = false;    // onpylon: draw BOTH parts in one colour -> judge the assembled FORM (the "one part" read) w/o the print-colour seam
mono_col   = "BurlyWood";

// =====================================================================
//  GEOMETRY  (flat in X-Y, built +Z = aft ; frontal/intake face at Z=0 -> pad/bed)
//  guard-local X = width (short A2212 axis) ; Y = up-mast (long A2212 axis) ; +Z = aft.
// =====================================================================
guard_vane_angles = [ for (i=[0:guard_vanes-1]) guard_a0 + (guard_a1-guard_a0)*i/(guard_vanes-1) ];

// ---------------------------------------------------------------------
//  BLOOM family (default) -- pad-echo hub + sculpted vanes + rolled rim
// ---------------------------------------------------------------------
// HUB: a rounded RECTANGLE that overlays the motor pad (same width + height).  offset_sweep gives it a rolled AFT
// (top) edge + a tiny 45 deg intake (bed) chamfer -> supportless, and a FLAT solid interior (the bearing washer face).
module guard_hub_bloom()
  offset_sweep(rect([guard_hub_w, guard_hub_h], rounding=guard_hub_rr),
               height=guard_t, bottom=os_chamfer(width=guard_front_round), top=os_circle(r=guard_round));

// VANE: a broad rounded trapezoid (root -> tip taper), extruded with the SAME rolled aft edge / crisp intake.  The
// root overlaps into the hub (welds); the tip embeds into the rim.  Roots are wide so neighbours nearly kiss near the
// hub -> a solid "bloom" that opens into distinct fins toward the rim.
// SWEPT fin: a curved, tapering band from the collar out into the rim.  Its centreline curls guard_fin_converge of the way
// toward the arc centre (smoothstep-eased, like the loft) so the fins read as swept turbine blades, not straight spokes.
// The root overlaps the collar (solid weld) and the tip pushes into the rim wall (full weld, not a tangent kiss).
function guard_fin_path(a, conv) =
  let(ri = guard_vane_r0 - 4, ro = guard_r_tip + guard_rim_wall*0.6, N = 12,
      C  = [ for (i=[0:N]) let(t=i/N, r=ri+(ro-ri)*t, s=t*t*(3-2*t),
                               ang = a + conv*(guard_a_ctr - a)*s) [r*cos(ang), r*sin(ang)] ],
      Wd = [ for (i=[0:N]) let(t=i/N) (guard_vane_root*(1-t) + guard_vane_tip*t)/2 ],
      nrm = [ for (i=[0:N]) let(p0=C[max(0,i-1)], p1=C[min(N,i+1)], d=p1-p0, L=max(1e-6,norm(d))) [-d.y, d.x]/L ],
      L = [ for (i=[0:N]) C[i] + nrm[i]*Wd[i] ], R = [ for (i=[0:N]) C[i] - nrm[i]*Wd[i] ])
  concat(L, [ for (i=[N:-1:0]) R[i] ]);
module guard_vane_bloom(a, conv)
  offset_sweep(guard_fin_path(a, conv), height=guard_t, offset="delta",
               bottom=os_chamfer(width=guard_front_round), top=os_circle(r=guard_round));

// ROLLED BEAD cross-section (radial start r_in, radial width w, height h): rounded TOP corners, FLAT crisp bed.
// Reused for the concentric ribs (flush at guard_t) and the outer rim (stands proud, with a cosine height taper).
module guard_bead_cs(r_in, w, h) let(rr = min(guard_round, w/2-0.05, h/2-0.05))
  translate([r_in, 0]) union() {
    offset(r=rr) offset(delta=-rr) square([w, h]);   // round all 4 corners
    square([w, rr]);                                  // refill the bottom rr -> crisp bed corners
  }
// height-taper mask: keep z <= z0 + m*u (u = distance in the arc-centre direction) -> h_mid at the middle, h_end at the
// ends.  m=0 (h_mid==h_end) leaves a flat cut at h_mid (used for the flush ribs).
module guard_height_mask(h_mid, h_end, r_ref)
  let(ext = guard_full_ring ? 0 : guard_shroud_ext,
      ca  = cos(guard_arc/2 + ext),
      denom = r_ref*(1 - ca),
      m   = (denom < 0.001) ? 0 : (h_mid - h_end)/denom,
      z0  = h_mid - m*r_ref, tilt = atan(m), BIG = 3000)
  rotate([0,0,guard_a_ctr]) translate([0,0,z0]) rotate([0,-tilt,0]) translate([0,0,-BIG]) cube(2*BIG, center=true);
// a rolled arc bead: revolve the cross-section over the kept arc (+ a small ext so the end vanes seat fully), then
// clip the height with the taper mask (or, for a full ring, a plain cylinder).
module guard_bead(r_in, w, h_mid, h_end)
  intersection() {
    rotate([0,0,guard_a0 - (guard_full_ring?0:guard_shroud_ext)])
      rotate_extrude(angle = guard_full_ring ? 360 : guard_arc + 2*guard_shroud_ext, $fn=300)
        guard_bead_cs(r_in, w, h_mid);
    if (guard_full_ring) translate([0,0,-1]) cylinder(h=h_mid+2, r=r_in+w+1);
    else guard_height_mask(h_mid, h_end, r_in + w);
  }

// DOMED collar: a rounded central BOSS around the hub (the guard's half of the mast's blossom).  Flat (= guard_t) inside
// guard_collar_flat (clears the motor can), domes to +guard_collar_crown mid-band, back to guard_t at the collar rim where
// the fins take over.  Frontal face flat on the bed; the aft dome is convex -> self-supporting (no overhang).  Revolved
// over the arc.  guard_collar_crown=0 falls back to a flat collar (guard_bead).
function guard_collar_z(r) =
  let(r0 = guard_collar_flat, r1 = guard_collar_r,
      t = (r <= r0) ? 0 : (r >= r1) ? 0 : (r - r0)/(r1 - r0))
  guard_t + guard_collar_crown * (0.5 - 0.5*cos(360*t));
module guard_collar_boss() let(ri = guard_hub_ext - 3, ro = guard_collar_r, NS = 44)
  rotate([0,0,guard_a0 - (guard_full_ring?0:guard_shroud_ext)])
    rotate_extrude(angle = guard_full_ring ? 360 : guard_arc + 2*guard_shroud_ext, $fn=300)
      polygon(concat([[ri,0],[ro,0]], [ for (i=[0:NS]) let(r = ro - (ro-ri)*i/NS) [r, guard_collar_z(r)] ]));

module guard_bloom() difference() {
  union() {
    guard_hub_bloom();                                                       // pad-echo hub (rolled aft, crisp bed)
    if (guard_has_collar)                                                    // SOLID inner bloom (grows from the pad -> pylon mass)
      if (guard_collar_crown > 0.01) guard_collar_boss();                    //   domed BOSS (one-part sculpt) ...
      else guard_bead(guard_hub_ext - 3, guard_collar_r - (guard_hub_ext - 3), guard_t, guard_t);  // ... or flat
    // fins fan out of the collar; the INNER fins swirl toward the arc centre while the two END fins stay radial to
    // CAP the rim ends (a sin() taper of the convergence) -> a gathered swept look with no dangling rim tips.
    for (i = [0:guard_vanes-1]) guard_vane_bloom(
        guard_a0 + (guard_a1-guard_a0)*i/(guard_vanes-1),
        guard_fin_converge * sin(180*i/max(1,guard_vanes-1)));
    for (r = guard_ring_radii) guard_bead(r - guard_rib_w/2, guard_rib_w, guard_t, guard_t);  // flush concentric rib(s), outer band
    if (guard_rim) guard_bead(guard_r_tip, guard_rim_wall,                   // ONE rolled rim (proud aft, tapered ends)
                              guard_t + guard_rim_proud, guard_t + guard_rim_proud_min);
  }
  translate([0,0,-1]) cylinder(h=guard_t + guard_rim_proud + 2, d=guard_bore_d);     // central boss recess
  for (p = guard_mount_xy) translate([p[0],p[1],-1]) cylinder(h=guard_t+2, d=guard_bolt_d); // 4x M3 (straight, vertical)
}

// ---------------------------------------------------------------------
//  WEB family -- the same pad-echo hub feeding a SOLID rolled arc shell,
//  lightened by organic annular-cell cut-outs (lightening as DESIGN).
//  Heavier / most solid -- closest to the pylon's mass.
// ---------------------------------------------------------------------
module guard_shell()   // a filled rolled arc plate from the hub reach out to the rim inner
  guard_bead(guard_hub_ext - 3, (guard_r_tip) - (guard_hub_ext - 3), guard_t, guard_t);
// an annular CELL (a rounded-corner sector patch) used as a lightening cut-out
module guard_cell(a_lo, a_hi, r_lo, r_hi, m) let(am = m / ((r_lo+r_hi)/2) * 57.2958)   // angular margin ~ m in mm
  rotate([0,0,-90])   // build in +Y then the arc frame; simplest: use a masked ring
  intersection() {
    rotate([0,0,90]) translate([0,0,-1]) linear_extrude(guard_t+2)
      offset(r=3) offset(delta=-3)
        difference() { circle(r=r_hi - m); circle(r=r_lo + m); }
    rotate([0,0,90]) translate([0,0,-1]) linear_extrude(guard_t+2)
      polygon([[0,0],
               [ (r_hi+5)*cos(a_lo+am), (r_hi+5)*sin(a_lo+am) ],
               [ (r_hi+5)*cos((a_lo+a_hi)/2), (r_hi+5)*sin((a_lo+a_hi)/2) ],
               [ (r_hi+5)*cos(a_hi-am), (r_hi+5)*sin(a_hi-am) ]]);
  }
module guard_web() difference() {
  union() {
    guard_hub_bloom();
    guard_shell();
    if (guard_rim) guard_bead(guard_r_tip, guard_rim_wall,
                              guard_t + guard_rim_proud, guard_t + guard_rim_proud_min);
  }
  // cut-outs: two radial bands (split by equal AREA, not equal dr, so cells look even) x a few angular cells; the OUTER
  // band is staggered half a cell so the radial ribs don't line up -> reads organic, not a grille.  guard_web_margin ribs kept.
  ri0 = guard_hub_ext + 6; ro0 = guard_r_tip - 6;
  rmid = sqrt((ri0*ri0 + ro0*ro0)/2);
  bands = [ [ri0, rmid], [rmid, ro0] ];
  ncol  = max(2, round(guard_web_holes/2));
  for (bi = [0:1], c = [0:ncol-1]) {
    off  = (bi==1) ? 0.5 : 0;
    a_lo = guard_a0 + (guard_a1-guard_a0)*(c+off)/ncol;
    a_hi = guard_a0 + (guard_a1-guard_a0)*(c+1+off)/ncol;
    if (a_hi <= guard_a1 + 0.01) guard_cell(a_lo, a_hi, bands[bi][0], bands[bi][1], guard_web_margin);
  }
  translate([0,0,-1]) cylinder(h=guard_t + guard_rim_proud + 2, d=guard_bore_d);
  for (p = guard_mount_xy) translate([p[0],p[1],-1]) cylinder(h=guard_t+2, d=guard_bolt_d);
}

// ---------------------------------------------------------------------
//  LEGACY family -- the old thin grille (kept for A/B + fallback)
// ---------------------------------------------------------------------
module guard_rr2d(w, h) let(r = min(guard_round, w/2-0.01, h/2-0.01))
  offset(r=r) offset(delta=-r) square([w, h]);
module guard_legacy_arc_bar(r_ctr, w, h)
  rotate([0,0,guard_a0]) rotate_extrude(angle = guard_full_ring ? 360 : guard_arc, $fn=240)
    translate([r_ctr - w/2, 0]) guard_rr2d(w, h);
module guard_legacy_spoke(a)
  rotate([0,0,a]) hull() {
    translate([guard_hub_r - 1, 0, 0])
      cyl(h=guard_t, r=guard_spoke_root/2, rounding2=min(guard_round, guard_spoke_root/2-0.01),
          rounding1=min(guard_front_round, guard_spoke_root/2-0.01), anchor=BOTTOM);
    translate([guard_r_tip - guard_bar/2 + 0.8, 0, 0])
      cyl(h=guard_t, r=guard_bar/2, rounding2=min(guard_round, guard_bar/2-0.01),
          rounding1=min(guard_front_round, guard_bar/2-0.01), anchor=BOTTOM);
  }
module guard_legacy_shroud_2d() let(rr = min(guard_round, guard_shroud_wall/2 - 0.05), f = guard_shroud_foot)
  offset(r=rr) offset(delta=-rr)
    polygon([[guard_r_tip - f, 0], [guard_r_out, 0], [guard_r_out, guard_shroud_h],
             [guard_r_tip, guard_shroud_h], [guard_r_tip, f]]);
module guard_legacy_shroud_wall_m()
  intersection() {
    rotate([0,0,guard_a0 - (guard_full_ring?0:guard_shroud_ext)])
      rotate_extrude(angle = guard_full_ring ? 360 : guard_arc + 2*guard_shroud_ext, $fn=280) guard_legacy_shroud_2d();
    if (guard_full_ring) translate([0,0,-1]) cylinder(h=guard_shroud_h+2, r=guard_r_out+1);
    else guard_height_mask(guard_shroud_h, guard_shroud_h_min, guard_r_tip);
  }
module guard_legacy_hub()
  cyl(h=guard_t, r=guard_hub_r, rounding2=guard_round, rounding1=guard_front_round, anchor=BOTTOM);
module guard_legacy_hub_lightening()
  for (ha = [45,135,225,315]) rotate([0,0,ha]) translate([guard_hub_r-7, 0, -1]) cylinder(h=guard_t+2, d=5);
module guard_legacy() {
  spoke_as = [ for (i=[0:guard_spokes-1]) guard_a0 + (guard_a1-guard_a0)*i/(guard_spokes-1) ];
  difference() {
    union() {
      guard_legacy_hub();
      for (r = guard_ring_radii) guard_legacy_arc_bar(r, guard_bar, guard_t);
      for (a = spoke_as) guard_legacy_spoke(a);
      if (guard_shroud) guard_legacy_shroud_wall_m();
    }
    translate([0,0,-1]) cylinder(h=guard_t+2, d=guard_bore_d);
    for (p = guard_mount_xy) translate([p[0],p[1],-1]) cylinder(h=guard_t+2, d=guard_bolt_d);
    if (guard_hub_light) guard_legacy_hub_lightening();
  }
}

// dispatch
module guard_full()
  if (guard_style == "web")         guard_web();
  else if (guard_style == "legacy") guard_legacy();
  else                              guard_bloom();

// =====================================================================
//  ECHO FIT-CHECK
// =====================================================================
echo("=== AIRBOAT PROP GUARD (visual-cohesion rev -- matches the pylon) ===");
echo(str("  style = ", guard_style, " ; prop ", prop_diameter, " (r ", prop_radius, ") ; rim inner r ", guard_r_tip,
         " (tip gap ", guard_tip_gap, ") ; OD ", guard_od, " ; ",
         guard_od <= (guard_full_ring ? 210 : 250) ? "fits the MK3 bed one-piece (250x210; the partial arc footprint is well under)"
                                                    : "<< too big for the bed one-piece (a FULL ring needs OD<=210)"));
echo(str("  ARC: keep ", guard_arc, " deg (", round(100*guard_arc/360), "% of the ring), ", guard_arc_bias,
         " deg off TOP toward OUTBOARD -> spans ", round(guard_a0), "..", round(guard_a1),
         " deg (0=INBOARD, 90=top, 180=OUTBOARD) -> covers TOP + OUTBOARD"));  // frame per common.scad guard_a_ctr; VERIFY by eye
if (guard_style == "bloom")
  echo(str("  BLOOM: pad-echo hub ", round(10*guard_hub_w)/10, "(X,width) x ", round(10*guard_hub_h)/10,
           "(Y,up-mast), corner r", guard_hub_rr, " -> overlays the motor pad ; ",
           guard_has_collar ? str("SOLID collar to r", guard_collar_r, " then ") : "",
           guard_vanes, " sculpted fins (root ", guard_vane_root, " -> tip ", guard_vane_tip, ") ; ",
           guard_ribs, " rolled rib(s) ; ALL edges r", guard_round, " EXCEPT the crisp bed/intake face"));
else if (guard_style == "web")
  echo(str("  WEB: pad-echo hub + a SOLID rolled arc shell lightened by ~", guard_web_holes,
           " organic cells (margin ", guard_web_margin, ") ; edges r", guard_round));
else
  echo(str("  LEGACY grille: hub disc r ", guard_hub_r, " + ", guard_rings, " ring + ", guard_spokes,
           " spokes ; bar ", guard_bar, " x ", guard_t, " ; edges r", guard_round));
echo(str("  RIM: ", guard_rim ? str("one rolled bead r ", guard_r_tip, "..", round(10*guard_r_out)/10,
         " (wall ", guard_rim_wall, "), stands ", guard_rim_proud, "->", guard_rim_proud_min,
         " mm proud AFT (rolled lip vs SIDE debris; does NOT reach the disc)") : "off"));
if (mount_to == "motor") {
  guard_bolt_r = motor_bolt_long/2;
  hub_reach = (guard_style=="legacy") ? guard_hub_r : min(guard_hub_w, guard_hub_h)/2;
  echo(str("  mount = WASHER: 4x M3 clearance ", guard_bolt_d, " on the A2212 CROSS (", motor_bolt_long, "x",
           motor_bolt_short, ") + ", guard_bore_d, " central BOSS RECESS -- the 4 motor pads bear on the FLAT hub face ; ",
           "hub half-reach ", round(10*hub_reach)/10, " vs furthest bolt ", guard_bolt_r, " + edge ",
           hub_reach >= guard_bolt_r + guard_bolt_d ? "OK" : "<< grow the hub"));
  echo(str("  bearing face FLAT under the bolt circle: rolled edge eats ", guard_round, " mm in from the hub rim; ",
           "nearest bolt is ", round(10*(hub_reach - guard_bolt_r))/10, " mm inside the rim -> ",
           (hub_reach - guard_bolt_r) >= guard_round + 0.5 ? "flat under every pad OK" : "<< pad may sit on the roll"));
  echo(str("  SANDWICH: pad | GUARD-washer (", guard_t, " mm) | motor -> screws thread into the A2212, motor breathes OPEN aft ; ",
           "M3 x ", motor_screw_len, " (seat ", motor_seat_t, " + guard ", guard_t, " + engage ", motor_engage, ")"));
} else {
  echo(str("  mount: 4x M3 clearance ", guard_bolt_d, " on a ", bp_pitch, " mm square (+/-", bp_axis, ") + ", guard_bore_d,
           " boss bore -- MATCHES the pad"));
}
echo(str("  sits ", round(10*guard_standoff)/10, " mm in front of the disc ; prints FLAT face-down, SUPPORTLESS ",
         "(intake face on the bed; rolled edges + rim rise AFT/up)"));
echo(str("  DFM: run a BRIM -- the hub anchors the centre but the thin arc extremities (r~", round(guard_r_out),
         ") are the PETG first-layer LIFT risk."));
echo(str("  NOTE tip mass/resonance: guard hangs at the mast tip -- BALANCE THE PROP (dominant 1P lever), validate a rev sweep."));
echo(str("  CONFIRM which way is OUTBOARD before printing (", mount_to=="motor" ? "set motor_offset_dir" : "set side",
         ") -- name a feature, don't trust a bare left/right."));
echo("------------------------------------------------------------");

// =====================================================================
//  STANDALONE RENDER
// =====================================================================
if (guard_part == "onpylon") {
  color(mono ? mono_col : "Tan") difference() { pylon(); pylon_cut(); }
  if (mount_to == "motor") {
    // INTEGRATED fit check: guard = washer at the OFFSET motor axis, motor bolted straight to it (NO plate).
    if (show_motor) color([0.12,0.12,0.13,0.9]) translate([pad_aft+guard_t, pylon_rise, motor_zc]) rotate([0,0,90]) import("Motor.stl");
    if (show_prop) color([0.85,0.2,0.2,0.30]) translate([pad_aft+guard_t+guard_standoff, pylon_rise, motor_zc]) rotate([0,90,0]) cylinder(h=1.5, r=prop_radius, center=true); // prop disc
    color(mono ? mono_col : "DarkSeaGreen") translate([pad_aft, pylon_rise, motor_zc]) rotate([0,90,0]) guard_full();
  } else {
    // legacy fit check: guard on the pad, BasePlate + Motor STL ghosts, prop disc.
    color([0.72,0.73,0.75,0.9]) translate([pad_aft+guard_t, pylon_rise, pylon_width/2]) rotate([45,0,0]) rotate([0,0,-90]) import("BasePlate.stl");
    color([0.12,0.12,0.13,0.9]) translate([pad_aft+guard_t+2+1.6, pylon_rise, pylon_width/2]) rotate([45,0,0]) rotate([0,0,90]) import("Motor.stl");
    color([0.85,0.2,0.2,0.30]) translate([pad_aft+guard_t+guard_standoff, pylon_rise, pylon_width/2]) rotate([0,90,0]) cylinder(h=1.5, r=prop_radius, center=true); // prop disc
    color("DarkSeaGreen") translate([pad_aft, pylon_rise, pylon_width/2]) rotate([0,90,0]) apply_side() guard_full();
  }
} else {
  // the printable guard.  motor mode: side-independent (L/R is motor_offset_dir, the arc lean).  plate mode: side mirrors.
  color("DarkSeaGreen") if (mount_to=="motor") guard_full(); else apply_side() guard_full();
}
