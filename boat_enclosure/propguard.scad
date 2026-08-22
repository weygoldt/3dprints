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

// ---------------------------------------------------------------------
//  RUGGED family (DEFAULT) -- rev "SPAR", 2026-08-22.
//
//  THE CONSTRUCTION IS THE POINT.  The whole body is ONE closed 2D region -- base plate U spokes U mid ring U rim --
//  morphologically CLOSED at guard_fillet, extruded ONCE by offset_sweep with ONE top chamfer.  Everything after that
//  is a DIFFERENCE.  Nothing is ever unioned with anything already chamfered.
//
//  WHY, not just what.  The previous body unioned a chamfered cuboid hub, 5 chamfered cuboid bars and 2 chamfered
//  rings.  Wherever two of those met, their chamfers met, and the union left a sharp zero-radius re-entrant V.
//  Measured on the shipped part: 40 such sites, floor at z = 3.00 in a 5.00 plate (40% through), 126.9 mm^3 of missing
//  material, all of it at the spoke ROOT -- the station where a rim strike's bending moment peaks.  That is what
//  Patrick reported as "gaps ... this is the load bearing part for the spokes".  You cannot fillet that away
//  afterwards; you have to stop creating it.  With one extrusion there is no second chamfer to collide with, so the
//  defect is not fixed, it is UNCONSTRUCTABLE.
//
//  Three fillets, in three planes, each doing a different job:
//    IN-PLANE   the morphological CLOSE (dilate then erode by guard_fillet) puts a true tangent arc in every concave
//               corner of the unified outline -- spoke/plate, spoke/ring, spoke/rim.  guard_fillet was declared
//               "(reserved)" for two revisions and never used; it is the whole mechanism now.
//    Z, ROOT    a revolved CONE tool holds the plate flat at guard_t inside guard_can_r (the motor-can keep-out) and
//               ramps each spoke up to guard_web_d at 45 deg.  The spoke does not start at full depth on a flat plate
//               -- it grows out of it.
//    Z, WALL    the pocket tool's own base chamfer leaves a 45 deg fillet of leg guard_root_fz standing against every
//               spoke wall where it rises off the plate.
//
//  Spokes get their section from DEPTH (5 -> 7 mm) and give width back toward the tip (9 -> 3.5), so the root section
//  modulus roughly doubles while the part gets LIGHTER.  Prints FLAT and supportless: the plate's bed face is the
//  intake face, every wall is vertical or leans outward, and the single chamfer is on top.
// ---------------------------------------------------------------------
// 2D primitives, all returned as DATA so the booleans happen in region space (BOSL2 regions.scad) rather than as
// CSG on solids -- that is what makes one closed outline possible at all.
function guard_rot2(a,p)             = [p.x*cos(a) - p.y*sin(a), p.x*sin(a) + p.y*cos(a)];
function guard_arcp(r,a0,a1,n)       = [ for (i=[0:n]) let(a = a0 + (a1-a0)*i/n) r*[cos(a), sin(a)] ];
function guard_band(r_in,w,a0,a1,n)  = concat(guard_arcp(r_in, a0, a1, n), reverse(guard_arcp(r_in+w, a0, a1, n)));
function guard_spoke2d(a,ri,ro,w0,w1)= [ for (p = [[ri,-w0/2],[ro,-w1/2],[ro,w1/2],[ri,w0/2]]) guard_rot2(a,p) ];
function guard_platep()              = [ [-guard_hub_w/2, guard_hub_yc - guard_hub_h/2],
                                         [ guard_hub_w/2, guard_hub_yc - guard_hub_h/2],
                                         [ guard_hub_w/2, guard_hub_yc + guard_hub_h/2],
                                         [-guard_hub_w/2, guard_hub_yc + guard_hub_h/2] ];
function guard_close(R,r)            = offset(offset(R, r=r,  closed=true), r=-r, closed=true);

// Spoke inner radius.  It must sit INSIDE guard_can_r, so every spoke root is buried in the flat bearing region of the
// plate and the cone tool ramps it up from there.  (Tying it to guard_hub_ext - 3, as the old bar did, now puts it at
// r=19 -- and the 90 deg spoke would then START at y=19, which is 2.07 mm ABOVE the plate's top edge at 16.93: the
// vertical spoke would not touch the plate at all.  The bug the old hub size was hiding.)
guard_spoke_ri  = guard_can_r - 3;                      // 13.5 -- buried in the flat plate, inside the can keep-out
guard_spoke_ro  = guard_r_tip + guard_rim_wall*0.6;     // spoke outer (buried in the rim)
guard_rmid      = (guard_hub_ext + guard_r_tip)/2;      // mid ring radius
guard_arcn      = 150;                                  // arc segments per band
guard_R_spokes  = [ for (a = guard_spoke_a) [guard_spoke2d(a, guard_spoke_ri, guard_spoke_ro, guard_spoke_w, guard_spoke_tip)] ];
guard_R_rim     = [ guard_band(guard_r_tip, guard_rim_wall, guard_a0 - guard_shroud_ext, guard_a1 + guard_shroud_ext, guard_arcn) ];
guard_R_mid     = [ guard_band(guard_rmid - guard_rib_w/2, guard_rib_w, guard_a0 - guard_shroud_ext, guard_a1 + guard_shroud_ext, guard_arcn) ];
guard_R_plate   = [ guard_platep() ];
// THE outline: everything at once, then closed.  Order matters only for readability -- union() is a region op.
guard_R_all     = guard_close(union(concat(guard_R_spokes, [guard_R_mid], [guard_R_rim], [guard_R_plate])), guard_fillet);
// the pocket footprint: everywhere EXCEPT the (closed) spokes -- so the plate is taken back down to guard_t and the
// pocket's base chamfer leaves the wall fillet standing against each spoke.
guard_R_pocket  = difference([ [[-guard_hub_w/2-6, guard_hub_yc-guard_hub_h/2-6], [guard_hub_w/2+6, guard_hub_yc-guard_hub_h/2-6],
                                [ guard_hub_w/2+6, guard_hub_yc+guard_hub_h/2+6], [-guard_hub_w/2-6, guard_hub_yc+guard_hub_h/2+6]],
                               guard_close(union(guard_R_spokes), guard_fillet) ]);

// (1) motor-can keep-out AND the 45 deg root ramp, in one revolved tool: flat at guard_t inside guard_can_r, full
//     guard_web_d beyond the ramp.  Everything above is removed, so the plate stays a flat bearing washer where the
//     motor sits and the spokes rise out of it.
module guard_cone_tool()
  let(ramp = guard_web_d - guard_t)
  rotate_extrude($fn = 180)
    polygon([[0, guard_t], [guard_can_r, guard_t], [guard_can_r + ramp, guard_web_d],
             [guard_can_r + ramp, guard_web_d + 40], [0, guard_web_d + 40]]);
// (2) take the plate back down to guard_t everywhere off the spokes, with a chamfered base -> the wall fillet.
module guard_pocket_tool()
  translate([0, 0, guard_t])
    offset_sweep(guard_R_pocket, height = guard_web_d + 40, steps = 8, check_valid = false,
                 bottom = os_chamfer(width = guard_root_fz, height = guard_root_fz));
// (3) NOT DONE, DELIBERATELY: a break on the base plate's own top-edge perimeter.
//     The old hub carried a 2 mm chamfer right round its top rim; this plate's perimeter is a bare 90 deg arris,
//     because the plate's top is a CUT plane (the pocket floor) rather than the sweep's top, so the one top chamfer
//     never reaches it.  Breaking a cut plane means cutting a wedge along it, and both constructions tried did real
//     damage:
//       a 400 mm outside-plane tool swallowed the mid ring and the rim   -> -8962 mm^3, 2790 mm^2 of flat roof;
//       a thin band hugging the plate, spokes protected by difference()  -> 40.5 mm^2 of flat roof at exactly
//         z = guard_t and 157 non-manifold edges, all of it just outside the plate corners where the morphological
//         close bridges the plate into the 54/162 deg spoke roots -- material the band cut from underneath.
//     The arris is against nothing: that face is the motor's bearing face, the perimeter is clear of every bolt, and
//     no wire crosses it.  A cosmetic edge is not worth shipping a non-manifold mesh for.  If it is ever wanted, the
//     honest construction is to build the plate's chamfer INTO guard_R_all as a second, lower sweep -- not to cut it.

// rugged BODY only (no boss / mount holes / slot) -- so the assembly can MIRROR the body per hull while cutting the
// (rotated) mount holes + the wire slot SEPARATELY (see guard_full).
module guard_rugged_body() difference() {
  offset_sweep(guard_R_all, height = guard_web_d, steps = 8, check_valid = false,
               top = os_chamfer(width = guard_edge_ch));
  guard_cone_tool();
  guard_pocket_tool();
}

// WIRE ROUTING SLOT: a wire_slot_w-wide gap from the hub centre out toward the INBOARD+DOWN corner (ang), so the motor
// leads pass through the base-plate and route down toward the boat centre.  In the 45deg gap between two screws.
// WAISTED FUNNEL (rev SPAR, 2026-08-22).  The previous canal was a constant-width obround whose two lip easings were
// applied with the WRONG SIGN: BOSL2's offset_sweep moves a POSITIVE radius INWARD, and the slot is a SUBTRACTED solid,
// so both "easings" SHRANK the cut.  Measured: 7.000 nominal collapsed to 4.620 clear at the motor face and 4.892 at
// the bed.  The aft lip became a 45 deg knife that closed the channel -- and it was the ONLY overhang in the whole part
// (29.12 mm^2, 25 support blocks), so the one thing needing support put it INSIDE the wire channel.  The bed lip became
// a zero-degree cusp feathering to 0.017 mm.  50.65 mm of edge sharper than 100 deg lay directly on the wire path.
// Now: NEGATIVE radii, so both mouths FLARE.  The channel is waisted -- narrow through the M3 bolt ring where the PLA
// web is the constraint, opening to a funnel outboard where the lead turns.  Aft lip = a tangent roll (no edge at all);
// bed lip = a 26.57 deg break, shallow enough that the widening hole still self-supports.  Both exit prongs filleted.
// The slot runs through the guard_t plate only, and the plate's bed face is clamped flat against the pylon pad.
// Half-width along the canal: a WAIST through the M3 bolt ring (where the PLA web to the nearest bore is the binding
// constraint) opening to a funnel MOUTH outboard (where the lead actually turns and rubs).  x is measured along the
// channel axis from the motor axis.
// The ramp finishes at x = 21, INSIDE the plate (whose edge is at 22 on the +X side), so the full wire_slot_w2
// mouth actually exists in the part.  It used to finish at 26 -- 4 mm outside the plate -- so the funnel was
// truncated and the widest the channel ever got was 8.83 mm against a nominal 10.
function wire_chan_hw(x) = (x <= 12) ? wire_slot_w/2
                         : (x >= 20.5) ? wire_slot_w2/2
                         : wire_slot_w/2 + (wire_slot_w2 - wire_slot_w)/2 * (x - 12)/8.5;
// The eased tool is the same profile shrunk, so sweeping it with NEGATIVE radii flares the mouth without moving the
// waist.  It must not flare inside the bolt ring or it eats the web, so it fades from a point at x=9 to full by x=15.
function wire_ease_fade(x) = (x <= 9) ? 1.0 : (x >= 15) ? 0.0 : (15 - x)/6;
// ONLY the breakpoints.  wire_chan_hw is piecewise LINEAR, so knots at 16/20/24 inside the ramp added no shape --
// but the prong fillet's tangent arc landed exactly on the x=16 vertex line and the difference-of-offsets there
// produced knife-thin slivers: 13 non-manifold edges, two of them zero-length, all clustered at x=15.87..22.
// Fewer vertices, no coincidence, same channel.
wire_chan_x = [-4, 0, 6, 12, 20.5, 30, 44];
// off is passed in, not read from the global: the path is built in the ROTATED channel frame, so the offset has to be
// counter-rotated or it lands on the wrong side of the (un-mirrored) base plate on the second hull.
function wire_chan_path(shrink, off) =
  let (hw = [ for (x = wire_chan_x) max(0.15, wire_chan_hw(x) - shrink*wire_ease_fade(x)) ])
  concat([ for (i = [0:len(wire_chan_x)-1])    [wire_chan_x[i], off + hw[i]] ],
         [ for (i = [len(wire_chan_x)-1:-1:0]) [wire_chan_x[i], off - hw[i]] ]);

module guard_wire_slot(ang = wire_slot_ang) {
  off     = wire_slot_off;   // in THIS (channel) frame -- see wire_slot_off in common.scad for why it must be
  R_chan  = [ wire_chan_path(0, off) ];
  R_ease  = [ wire_chan_path(wire_slot_waist_ease, off) ];
  rotate([0,0,ang]) {
    translate([0,0,-eps]) linear_extrude(guard_t + 2*eps) polygon(R_chan[0]);   // the clear channel itself
    // BOTH lips flared OUTWARD (negative radii).  Aft = a tangent roll: no edge at all on the face the motor bears on
    // and the lead crosses.  Bed = a 26.57 deg break: shallower than 45, so the widening hole still self-supports.
    translate([0,0,-eps])
      offset_sweep(R_ease, height = guard_t + 2*eps, steps = 12, check_valid = false,
                   top    = os_circle(r = -wire_slot_ease),
                   bottom = os_chamfer(width = -wire_slot_bed_w, height = wire_slot_bed_h));
  }
  // BOTH exit prongs.  The slivers a morphological OPEN removes from (plate MINUS channel) ARE the prong tips; clip
  // them with a band centred on the CHANNEL AXIS so it contains the two prongs and nothing else.  (The old clip was a
  // circle on a hub CORNER: it reached one prong, missed the other, and bored through a spoke root.)  The whole cut is
  // rotated by ang, so the plate rectangle is counter-rotated here -- the face is 44 x 39.80 and NOT hub-centred, so
  // this is emphatically not a no-op at ang = 180.
  if (wire_slot_corner_r > 0) {
    R_plate_c = [ [ for (p = guard_platep()) guard_rot2(-ang, p) ] ];
    R_pc      = difference([R_plate_c, [wire_chan_path(0, off)]]);
    rotate([0,0,ang]) translate([0,0,-eps]) linear_extrude(guard_t + 2*eps)
      // The sliver is TANGENT to the channel wall at each end, i.e. knife-thin exactly there, and a knife-thin
      // subtrahend meets the wall in a pinch: CGAL emitted 2-13 non-manifold edges right at the tangency depending
      // on where the channel's knots fell.  A 2 um fattening gives the sliver width at the tangent point without
      // moving the fillet anywhere a caliper could find it.
      offset(delta = 0.002)
      intersection() {
        difference() {
          region(R_pc);
          // MORPHOLOGICAL OPEN = erode THEN dilate.  OpenSCAD applies the INNER offset first, so the erode must be
          // written second.  Getting this backwards gives a CLOSING, and a closing always CONTAINS its input, so the
          // difference is empty BY CONSTRUCTION and the whole prong cut silently does nothing -- it removed 0.0002
          // mm^3 instead of ~18 mm^3, and shipped both prongs sharp while the comment claimed both were filleted.
          offset(r = wire_slot_corner_r) offset(r = -wire_slot_corner_r) region(R_pc);
        }
        translate([16, off]) square([44, 2*(wire_slot_w2/2 + wire_slot_corner_r + 3)], center = true);
      }
  }
}

// the central boss + the (rotated) mount holes + the wire slot -- cut AFTER any body mirror so they stay in the real frame.
module guard_cuts(rot = mount_rot, slot_ang = wire_slot_ang) {
  // BOSS RECESS.  Its BED rim is broken outward (that only costs pad bearing area, which is abundant); its AFT rim is
  // left deliberately CRISP.  Rounding the aft rim was built and measured: an r=1.0 round pushes the flat bearing
  // land's inner edge 5.75 -> 6.75 and cuts the short-axis bolt's fully-seated washer OD from 4.40 to 2.50 mm -- a
  // dimension already measured as marginal.  Not worth spending on a hazard that only exists IF the A2212's leads
  // exit its mount face, which is still unconfirmed.  Reverted, on purpose, with the number.
  // The bed break is CAPPED so it can never reach the two SHORT-axis M3 bores.  It was a flat -0.6, which reaches
  // r = 5.75 + 0.6 = 6.35 at z=0 against those bores' inner edge at 8.0 - 1.7 = 6.30: they OVERLAPPED by 0.05 mm over
  // a 0.73 mm chord, so the recess and both bolt holes sliced as ONE merged void for the first two layers and the
  // 0.55 mm PLA wall between them became 0.006 mm at the bed.  Derived from the bolt geometry, not typed in, so a
  // change to the motor cross or the boss recess cannot silently re-open it.
  // ONE sweep for the whole height.  It used to be a swept lower part capped by a separate cylinder, which left a
  // 0.00135 mm faceting ledge right round the bore (96-gon against $fn=128) -- and when both were put on the same
  // polygon they simply overlapped, giving 61 non-manifold edges at r=5.75, z=4.98.  A single sweep has no junction
  // to get wrong.
  translate([0,0,-eps])
    offset_sweep([ for (i=[0:guard_bore_fn-1]) (guard_bore_d/2)*[cos(360*i/guard_bore_fn), sin(360*i/guard_bore_fn)] ],
                 height = guard_web_d + 2*eps, steps = 10, check_valid = false,
                 bottom = os_chamfer(width = -guard_bore_bed_break, height = 2*guard_bore_bed_break));
  for (p = gmxy(rot)) translate([p[0],p[1],-1]) cylinder(h = guard_t + 2, d = guard_bolt_d);      // 4x M3 (rotated pattern)
  if (wire_slot && mount_to == "motor") guard_wire_slot(slot_ang);
}
// body dispatch: rugged is split; the other styles carry their own cuts (they are not the wire-routed default).
module guard_body_only()
  if (guard_style == "web")         guard_web();
  else if (guard_style == "legacy") guard_legacy();
  else if (guard_style == "bloom")  guard_bloom();
  else                              guard_rugged_body();

// FULL guard.  rot = motor 90deg turn (0/90) ; slot_ang = wire slot direction ; mir = mirror the BODY (starboard hull).
module guard_full(rot = mount_rot, slot_ang = wire_slot_ang, mir = false) difference() {
  if (mir) mirror([1,0,0]) guard_body_only(); else guard_body_only();
  guard_cuts(rot, slot_ang);
}

// =====================================================================
//  ECHO FIT-CHECK
// =====================================================================
echo("=== AIRBOAT PROP GUARD (visual-cohesion rev -- matches the pylon) ===");
echo(str("  style = ", guard_style, " ; prop ", prop_diameter, " (r ", prop_radius, ") ; rim inner r ", guard_r_tip,
         " (tip gap ", guard_tip_gap, ") ; OD ", guard_od, " ; ",
         guard_od <= (guard_full_ring ? 210 : 250) ? "fits the MK3 bed one-piece (250x210; the partial arc footprint is well under)"
                                                    : "<< too big for the bed one-piece (a FULL ring needs OD<=210)"));
echo(str("  ARC: ", guard_arc, " deg (", round(100*guard_arc/360), "% of the ring), spans ", guard_a0, "..", guard_a1,
         " deg (0=INBOARD, 90=top, 180=OUTBOARD) -- DERIVED from the spoke ladder, ends ON a spoke at both ends"));
if (guard_style == "rugged")
  echo(str("  SPAR: base plate ", round(1e4*guard_hub_w)/1e4, "(X,width) x ", round(1e4*guard_hub_h)/1e4,
           "(Y,in-plane) centred ", round(1e4*guard_hub_yc)/1e4, " up-mast == the pylon's REAL tilted pad face ; ",
           guard_vanes, " spokes at ", guard_spoke_a, " deg (pitch ", guard_spoke_pitch,
           ") ; section ", guard_spoke_w, "->", guard_spoke_tip, " wide x ", guard_web_d,
           " deep ; ONE closed region, closed at r", guard_fillet, ", ONE ", guard_edge_ch, " mm top chamfer"));
else if (guard_style == "bloom")
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
echo(str("  RIM: ", !guard_rim ? "off"
       : guard_style == "rugged"
         ? str("r ", guard_r_tip, "..", round(10*guard_r_out)/10, " (wall ", guard_rim_wall, "), crown ", guard_web_d,
               " = the same one plane as the spokes and the rib, so a spoke tip meets it FLUSH (no square internal corner)")
         : str("one rolled bead r ", guard_r_tip, "..", round(10*guard_r_out)/10, " (wall ", guard_rim_wall,
               "), stands ", guard_rim_proud, "->", guard_rim_proud_min, " mm proud AFT")));
if (mount_to == "motor") {
  guard_bolt_r = motor_bolt_long/2;
  hub_reach = (guard_style=="legacy") ? guard_hub_r : min(guard_hub_w, guard_hub_h)/2;
  echo(str("  mount = WASHER: 4x M3 clearance ", guard_bolt_d, " on the A2212 CROSS (", motor_bolt_long, "x",
           motor_bolt_short, ") + ", guard_bore_d, " central BOSS RECESS -- the 4 motor pads bear on the FLAT hub face ; ",
           "hub half-reach ", round(10*hub_reach)/10, " vs furthest bolt ", guard_bolt_r, " + edge ",
           hub_reach >= guard_bolt_r + guard_bolt_d ? "OK" : "<< grow the hub"));
  // FLAT BEARING LAND.  The old version of this echo measured only the OUTER rim -- but the binding constraint is the
  // CENTRAL BOSS BORE, which crowds the two SHORT-axis screws (they sit at r=8.0 against a bore of r=5.75).  It
  // therefore could not fail on the real limiter, and reported "OK" while the short-axis land was 2.25 mm wide.
  // Check BOTH sides of every bolt, inner and outer, and report the WORST.
  land_in_short  = motor_bolt_short/2 - guard_bolt_d/2 - guard_bore_d/2;   // short-axis bolt -> boss bore
  land_in_long   = motor_bolt_long/2  - guard_bolt_d/2 - guard_bore_d/2;   // long-axis bolt  -> boss bore
  land_out       = hub_reach - guard_bolt_r - guard_bolt_d/2;              // furthest bolt   -> plate edge
  land_worst     = min(land_in_short, land_in_long, land_out);
  echo(str("  bearing face FLAT around every bolt (worst of inner AND outer): short-axis->bore ",
           round(100*land_in_short)/100, ", long-axis->bore ", round(100*land_in_long)/100,
           ", furthest bolt->plate edge ", round(100*land_out)/100, " mm -> WORST ", round(100*land_worst)/100,
           land_worst >= 0.5 ? " mm, a washer seats" : " mm << TOO TIGHT: the pad has no flat to bear on"));
  echo(str("  max fully-seated washer OD: short-axis pair ", round(100*(guard_bolt_d + 2*land_in_short))/100,
           ", long-axis pair ", round(100*(guard_bolt_d + 2*land_in_long))/100,
           " mm -- the SHORT pair is the one to watch, it is what the boss recess crowds"));
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

// ---------------------------------------------------------------------
//  GATES (rev SPAR).  Four assertions that each FIRE on a control -- verified by render, not by eye.  They exist
//  because this file has already shipped two defects that every check passed: a base plate sized from a parameter
//  whose geometry had been deleted, and a deck trim applied to the wrong end of the arc on one of the two hands.
//  A comment cannot catch either.  Each gate below is stated so that it prints a NUMBER, not a boolean.
// ---------------------------------------------------------------------
if (guard_style == "rugged") {
  // GATE 1 -- a spoke DEAD VERTICAL, on BOTH hands.  Both ladders are computed here so ONE render proves the pair;
  // the shipped defect was precisely that the two hands were not symmetric and no single render could see it.
  // control: -D guard_vanes=4  ->  18 / 18  << FAIL.  NOTE the control is the COUNT, not the pitch: the ladder is
  // anchored as 90 + pitch*lean + i*pitch, so i = -lean lands on 90 for ANY pitch.  -D guard_spoke_pitch=40 does NOT
  // fire, and that is the construction working, not the gate sleeping.  What the gate still catches is an even/short
  // guard_vanes and any future rewrite of the ladder formula -- which is exactly how pad_head_w went stale.
  lad = [ for (lean = [1,-1]) [ for (i = [-(guard_vanes-1)/2 : (guard_vanes-1)/2]) 90 + guard_spoke_pitch*lean + i*guard_spoke_pitch ] ];
  v_err = [ for (L = lad) min([ for (a = L) abs(a - 90) ]) ];
  echo(str("  GATE1 vertical spoke: worst |angle-90| = ", v_err[0], " (dirP) / ", v_err[1], " (dirN) -> ",
           (max(v_err) < 1e-9 && guard_vanes % 2 == 1 && guard_vanes >= 3)
             ? "EXACT on both hulls OK" : "<< FAIL: no spoke is vertical (guard_vanes must be ODD and >=3)"));
  // GATE 2 -- the base plate really is the pylon's pad face.  pad_face_yb must land ON the buttress slope, i.e.
  // strictly between the foot (0) and the head (pad_y0); if it does not, the closed form has been solved against
  // geometry that no longer exists -- exactly how pad_head_w went stale.
  // control: -D motor_tilt=0  ->  yb = 48 > pad_y0 = 40  << FAIL
  echo(str("  GATE2 plate == pad face: ", guard_hub_w, " x ", round(1e4*guard_hub_h)/1e4, " at yc ",
           round(1e4*guard_hub_yc)/1e4, " ; buttress crossing yb = ", round(1e4*pad_face_yb)/1e4,
           (pad_face_yb > 0 && pad_face_yb <= pad_y0 && guard_hub_w == pylon_width)
             ? str(" (in 0..", pad_y0, ") OK") : str(" << FAIL: not on the buttress slope (0..", pad_y0, ")")));
  // GATE 3 -- the in-plane fillet must stay bigger than the top chamfer, or the chamfer eats the fillet it is
  // supposed to be carried around and the root crease comes back.
  // control: -D guard_fillet=1.2  ->  0  << FAIL
  echo(str("  GATE3 fillet vs chamfer: ", guard_fillet, " - ", guard_edge_ch, " = ", guard_fillet - guard_edge_ch,
           (guard_fillet - guard_edge_ch >= 0.5) ? " OK" : " << FAIL: chamfer >= fillet, the root crease returns"));
  // GATE 4 -- the PLA web around each M3 bore, against BOTH voids that crowd it: the wire channel AND the central
  // boss recess.  An earlier version of this gate measured only the channel, and measured it to the channel
  // polygon's inboard END CORNER at (-4, +3.5) -- which is at r = 5.32, i.e. INSIDE the 5.75 boss recess and
  // therefore not a wall that exists in the solid.  It printed "worst 1.02 OK" while the part's real worst wall was
  // 0.55.  A gate that scores a surface the geometry has already removed is worse than no gate.
  // control: -D wire_slot_w=9  ->  the channel term goes negative  << FAIL
  webs = [ for (p = gmxy(mount_rot))
             let (q  = [ p[0]*cos(wire_slot_ang) + p[1]*sin(wire_slot_ang),
                        -p[0]*sin(wire_slot_ang) + p[1]*cos(wire_slot_ang) ],
                  x0 = wire_chan_x[0], x1 = wire_chan_x[len(wire_chan_x)-1],
                  xc = max(x0, min(x1, q[0])),
                  gy = max(0, abs(q[1] - wsa_off(motor_offset_dir)) - wire_chan_hw(xc)),
                  gx = (q[0] < x0) ? x0 - q[0] : (q[0] > x1) ? q[0] - x1 : 0,
                  d_chan = norm([gx, gy]),                     // to the wire channel
                  d_boss = norm(p) - guard_bore_d/2)           // to the central boss recess
             min(d_chan, d_boss) - guard_bolt_d/2 ];
  echo(str("  GATE4 PLA web around each M3 bore (channel AND boss recess): ",
           [ for (w = webs) round(1000*w)/1000 ], " mm, worst ", round(1000*min(webs))/1000,
           (min(webs) >= 0.5) ? " OK" : " << FAIL"));
  // The floor is set by the MOTOR, not by anything this file chooses: the short-axis bolts sit at
  // motor_bolt_short/2 = 8.0, their bores take 1.7, and the boss recess takes guard_bore_d/2 = 5.75, leaving 0.55.
  // The only lever is guard_bore_d (= motor_boss_d + 1.5).  MEASURE the A2212's boss: every 1 mm off that clearance
  // is +0.5 mm of wall here.  The previous rev shipped 0.4569, so this is an improvement, not a new problem.
  echo(str("  GATE4 note: the 0.55 floor is motor_bolt_short/2 ", motor_bolt_short/2, " - bore ", guard_bolt_d/2,
           " - boss recess ", guard_bore_d/2, ". Lever = guard_bore_d (measure your boss). Previous rev: 0.4569."));
  // GATE 5 -- the boss recess's BED break must never reach the two short-axis M3 bores.  At 0.6 it overlapped them
  // by 0.05 mm and the recess plus both bolt holes sliced as ONE void for the first two layers.  It is 0 now, but
  // this is what stops it being raised back without the collision being noticed.
  // control: -D guard_bore_bed_break=0.6  ->  0.6 > 0.25  << FAIL
  echo(str("  GATE5 boss bed break ", guard_bore_bed_break, " vs ceiling ", round(1000*guard_bore_break_max)/1000,
           " (= short-axis bolt inner edge - recess - 0.3 wall) -> ",
           (guard_bore_bed_break <= guard_bore_break_max) ? "OK" : "<< FAIL: the break eats into the M3 bores at the bed"));
}
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
