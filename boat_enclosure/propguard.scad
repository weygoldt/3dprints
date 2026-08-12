// =====================================================================
//  AIRBOAT ENCLOSURE -- PROPELLER GUARD  (FLAT frontal ARC grille; bolt-on)
//  Part of the airboat catamaran drive system.  See common.scad for the box
//  frame mapping, the pylon/pad geometry, the prop parameters, and the shared
//  BOSL2 includes.  This part is an ACCESSORY (like rail.scad): it keeps its own
//  parameters + echo fit-check here and pulls only the mount + prop geometry
//  (prop_radius, the pad bolt pattern, pad_aft, prop_disc_z) from common.
//
//  WHAT IT IS  (Patrick's calls, 2026-08-13)
//    A totally FLAT (2D) grille that bolts to the SAME 4 holes the motor bracket
//    uses and sits ~a prop-plane in FRONT of the 8 in (203 mm) pusher prop.  The
//    airboat drives FORWARD ~99% of the time, so vegetation (reeds / grass /
//    branches) comes at the prop from the FRONT -- a flat grille on the intake
//    side intercepts it before it reaches the disc.  It is a PARTIAL RING, not a
//    full disc: on the boat the prop's exposed faces are the TOP and the OUTBOARD
//    side (the bottom sits low near the water/spray; the inboard side faces the
//    sheltered channel between the two hulls), so the grille covers only the
//    top + outboard arc (guard_arc) and the rest is removed.  That cuts mass (=>
//    less mast-tip resonance load), cuts intake blockage (=> more thrust), and
//    still prints flat in one piece.
//
//  THE STACK  (the guard is sandwiched at the pad, like the motor bracket)
//    pylon pad | PROP-GUARD grille (guard_t) | BasePlate (motor bracket) | motor
//    -> the 4 M3 mount screws just get ~guard_t longer; nut still on the pad's
//    forward face.  The grille's central hub is a FULL disc (all 4 bolts) that
//    copies the pad's 4x M3 square (bp_pitch, +/-bp_axis) + the 11.5 mm central
//    boss clearance; only the outer grid is cut to the arc.  The motor + prop live
//    AFT of the grille; the grille's aft face sits guard_standoff mm ahead of the
//    prop disc (that gap is also the flex-into-the-prop safety margin).
//
//  PRINTS FLAT -- PETG on a Prusa MK3 (user spec).  One flat extrude: the whole
//    plate lies on the bed, layers in-plane, SUPPORTLESS, maximum bed adhesion.
//    Removing the bottom of the ring shrinks the footprint below the prop OD, so
//    the arc fits the 250x210 bed comfortably in one piece (room for a brim).
//  MIRRORS with `side` (port/starboard) so the outboard bias lands on the correct
//    side of each hull -- CONFIRM which way is outboard on your boat (name a
//    feature; don't trust a bare left/right).
//  Requires BOSL2 (../BOSL2) via common.scad.
// =====================================================================
include <common.scad>
use <pylon.scad>       // for the "onpylon" fit check (draws the real pylon + STL hardware ghosts)

$fn = 160;  // smooth rings

/* [What to render] */
guard_part = "full";   // [full, onpylon] full = the flat arc grille (the printable part) ; onpylon = grille bolted to the real pylon in front of the BasePlate + Motor + prop ghosts (fit check)
side       = "starboard"; // [starboard, port] mirror so the OUTBOARD bias lands correctly on this hull (port mirrors X)

/* [Arc coverage] -- a PARTIAL ring: cover the top + outboard, drop the bottom + inboard */
guard_arc      = 210;  // kept angular sweep of the grille, degrees.  360 = full ring ; 240 removes 1/3 ; 210 ~ 42% off ; 120 removes 2/3
guard_arc_bias = 25;   // lean the kept arc this many degrees from TOP toward the OUTBOARD side (0 = symmetric about top)
guard_over     = 1;    // rim OUTER radius = prop_radius + this (mm).  1 -> just covers the tips
guard_t        = 6;    // flat plate thickness (Z).  This ALONE sets the stiffness in the one mode that matters -- flexing
                       // back into the prop under a head-on branch (the in-plane rings/spokes sit in the neutral plane
                       // and barely help).  6 mm vs a ~guard_standoff gap; raise it if a push test flexes it near the disc.

/* [Mount hub] -- FULL disc, copies the pad's 4x M3 square + central boss clearance; sits in the sandwich */
guard_hub_r   = 30;    // hub outer radius -- >= the BasePlate corner reach (39.5 sq -> r 27.9) so it fully backs the plate in the clamp
guard_bore_d  = bp_bore + 1.5;  // 11.5 central clearance for the motor boss poking forward (matches the pad)
guard_bolt_d  = bp_screw_d;     // 3.4 M3 clearance, MATCHES the pad (a vibration mount wants tight holes, not slop)

/* [Grid] -- concentric ring arcs + radial spokes (a fan-guard pattern over the arc) */
guard_rings   = 2;     // intermediate concentric ring arcs between the hub and the outer rim (evenly spaced)
guard_spokes  = 7;     // radial spokes ACROSS the arc (includes one at each arc end, which caps + welds the ring arcs)
guard_bar     = 4;     // in-plane width of every ring + spoke.  Thinner -> more open (less intake/thrust loss, lighter),
                       // bigger reed gates.  A THRUST prop hates a blocked intake, so err open; close it (raise this /
                       // add rings) only if a field test shows reeds still reach the disc.
guard_outer_spokes = true; // add spokes in the OUTERMOST annulus only -> halves the big tangential rim cells without a full extra ring
guard_fillet  = 1.5;   // round the concave grid junctions + the arc ends -- kills sharp re-entrant stress risers on an
                       // impact guard and cleans the look (pylon.scad's offset idiom)

// =====================================================================
//  DERIVED
// =====================================================================
eps2 = 0.02;
r_out    = prop_radius + guard_over;          // rim outer radius
guard_od = 2*r_out;                           // grille outer diameter (full-ring equivalent)
bed_fit  = 250;                               // MK3 long bed axis; the arc drops below the prop OD so it clears easily
guard_standoff = (mm_block_aft_z - pad_aft) - prop_disc_z; // pad face -> prop disc plane; = the guard-aft-face-to-prop gap (flex margin)
mount_xy = [ for (sx=[-1,1], sy=[-1,1]) [sx*bp_axis, sy*bp_axis] ];  // 4 M3 -> land on the pad pattern
ring_radii = [ for (i=[1:guard_rings]) guard_hub_r + i*(r_out - guard_bar - guard_hub_r)/(guard_rings+1) ]; // intermediate ring centres
outer_ann_r = (guard_rings>0) ? ring_radii[guard_rings-1] : guard_hub_r; // inner edge of the outermost annulus
a_ctr = 90 - guard_arc_bias;                  // arc centre angle from +X (90 = top ; bias>0 leans toward outboard +X)
a0 = a_ctr - guard_arc/2;                     // arc start / end (deg)
a1 = a_ctr + guard_arc/2;
full_ring = guard_arc >= 359.9;
spoke_as = full_ring ? [ for (i=[0:guard_spokes-1]) a0 + (a1-a0)*i/guard_spokes ]           // even, no duplicate end
                     : [ for (i=[0:guard_spokes-1]) a0 + (a1-a0)*i/(guard_spokes-1) ];       // includes both ends (cap the arc)
// gate sizes (the reed/branch stop)
n_rim = (guard_spokes-1) * (guard_outer_spokes?2:1);         // rim-spoke intervals across the arc
rim_cell   = (guard_arc*PI/180)*r_out/max(n_rim,1) - guard_bar; // tangential gap between rim spokes
radial_cell= (r_out - guard_hub_r)/(guard_rings+1) - guard_bar; // radial gap between rings

module apply_guard_side() { if (side=="port") mirror([1,0,0]) children(); else children(); }

// =====================================================================
//  GEOMETRY  (flat in X-Y, extruded guard_t along +Z ; mount face at Z=0 -> pad)
// =====================================================================
module ring2d(r) difference() { circle(r=r); circle(r=r-guard_bar); }   // annulus, OUTER radius r
module spoke2d(len) translate([0,-guard_bar/2]) square([len, guard_bar]); // bar along +X, 0..len
// a pie wedge from angle s to e, radius rr (for clipping the rings to the arc)
module sector(s, e, rr) {
  n = max(2, ceil((e-s)/4));
  polygon(concat([[0,0]], [ for (i=[0:n]) let(a=s+(e-s)*i/n) rr*[cos(a), sin(a)] ]));
}

module grille2d() {
  circle(r=guard_hub_r);                        // FULL hub disc (all 4 bolts)
  // concentric ring arcs, clipped to the kept sector
  if (full_ring) { ring2d(r_out); for (r=ring_radii) ring2d(r); }
  else intersection() {
    union() { ring2d(r_out); for (r=ring_radii) ring2d(r); }
    sector(a0, a1, r_out+5);
  }
  // radial spokes (full width; the two end spokes at a0/a1 cap + weld the ring arcs)
  for (a=spoke_as) rotate([0,0,a]) spoke2d(r_out);
  // extra spokes in the OUTERMOST annulus only, interleaved -> shrink the rim cells
  if (guard_outer_spokes)
    for (i=[0:len(spoke_as)-2]) rotate([0,0,(spoke_as[i]+spoke_as[i+1])/2])
      translate([outer_ann_r,0]) spoke2d(r_out - outer_ann_r);
}

module grille_cut2d() {
  circle(d=guard_bore_d);                                   // central boss clearance
  for (p = mount_xy) translate(p) circle(d=guard_bolt_d);   // 4 M3 mount holes
}

// the printable flat grille (fillet the junctions, then bore the mount holes crisp)
module guard_full()
  linear_extrude(guard_t) difference() {
    offset(r=guard_fillet) offset(delta=-guard_fillet) grille2d();
    grille_cut2d();
  }

// =====================================================================
//  ECHO FIT-CHECK  (house style: the number and the bar it must clear)
// =====================================================================
echo("=== AIRBOAT PROP GUARD (flat frontal arc grille) ===");
echo(str("  prop ", prop_diameter, " (r ", prop_radius, ") ; rim r ", r_out, " (= prop_radius + ", guard_over,
         ") ; thickness ", guard_t, " ; side ", side));
echo(str("  ARC: keep ", guard_arc, " deg (", round(100*guard_arc/360), "% of the ring; ", round(100*(360-guard_arc)/360),
         "% removed), centred ", guard_arc_bias, " deg off TOP toward OUTBOARD -> spans ", round(a0), "..", round(a1), " deg (0=outboard, 90=top)"));
echo(str("  covers the TOP + OUTBOARD; drops the bottom (near water) + inboard (sheltered channel between hulls)"));
echo(str("  sits ", round(10*guard_standoff)/10, " mm in FRONT of the prop disc (guard aft face -> prop plane = the flex-into-prop margin)"));
echo(str("  mount: 4x M3 clearance ", guard_bolt_d, " on a ", bp_pitch, " mm square (+/-", bp_axis, ") + ", guard_bore_d,
         " boss bore -- MATCHES the pad ; FULL hub disc r ", guard_hub_r, " >= BasePlate corner 27.9 ", guard_hub_r >= 27.9 ? "OK" : "<< grow guard_hub_r"));
echo(str("  SANDWICH: pad | grille (", guard_t, " mm) | BasePlate | motor -> M3 mount screws ~", guard_t,
         " mm LONGER than motor-only ; nut still on the pad forward face"));
echo(str("  grid: full hub + ", guard_rings, " ring arc", guard_rings==1?"":"s", " + ", guard_spokes, " spokes",
         guard_outer_spokes ? str(" (+", guard_spokes-1, " outer)") : "", " ; bar ", guard_bar, " x ", guard_t));
echo(str("  gates (reed/branch stop): radial cell ~", round(radial_cell), " mm x tangential rim cell ~", round(rim_cell), " mm ",
         (rim_cell <= 55 && radial_cell <= 45) ? "OK -- stops clumps/branches, passes air (a branch/clump fender, not a fine reed screen)"
                                               : "<< large gates: add rings/spokes or narrow the arc if reeds slip through"));
echo(str("  bed: arc drops below the ", guard_od, " prop OD, so its footprint fits the ", bed_fit,
         "x210 MK3 in ONE flat piece with room for a brim -- SUPPORTLESS (flat plate, no overhang)"));
echo(str("  NOTE resonance/mass: the guard hangs at the mast tip -- a review flagged tip-mass lowering the mast's 1st",
         " bending freq. The arc + thin bars keep it light; BALANCE THE PROP (the dominant 1P lever) and validate with a rev sweep."));
echo(str("  NOTE coverage: guards the FORWARD face for forward travel; the tip-circle side gap + the aft/exhaust side stay",
         " open (a wrap cage was dropped -- only helps in reverse).  CONFIRM which way is OUTBOARD before printing (set side)."));
echo("------------------------------------------------------------");

// =====================================================================
//  STANDALONE RENDER
// =====================================================================
if (guard_part == "onpylon") {
  // fit check: the grille bolted to the real pylon pad, in FRONT of the BasePlate +
  // Motor STL ghosts + the prop disc.  The guard (guard_t) shifts the whole motor
  // stack AFT by guard_t, so the ghosts are offset by guard_t here (honest sandwich).
  // Guard mount face (Z=0) -> pad aft face (pylon X=pad_aft) ; guard +Z -> pylon +X (aft) ; +Y -> up the mast.
  color("Tan") difference() { pylon(); pylon_cut(); }
  color([0.72,0.73,0.75,0.9]) translate([pad_aft+guard_t, pylon_rise, pylon_width/2]) rotate([45,0,0]) rotate([0,0,-90]) import("BasePlate.stl");
  color([0.12,0.12,0.13,0.9]) translate([pad_aft+guard_t+2+1.6, pylon_rise, pylon_width/2]) rotate([45,0,0]) rotate([0,0,90]) import("Motor.stl");
  color([0.85,0.2,0.2,0.30]) translate([pad_aft+guard_t+guard_standoff, pylon_rise, pylon_width/2]) rotate([0,90,0]) cylinder(h=1.5, r=prop_radius, center=true); // prop disc
  color("DarkSeaGreen") translate([pad_aft, pylon_rise, pylon_width/2]) rotate([0,90,0]) apply_guard_side() guard_full();
} else {
  color("DarkSeaGreen") apply_guard_side() guard_full();   // the printable flat arc grille
}
