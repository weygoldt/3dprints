// =====================================================================
//  AIRBOAT ENCLOSURE -- BLANKING CAPS  (snap-in plugs for unused bores)
//  Part of the airboat catamaran enclosure.  See common.scad for the frame
//  mapping, all parameters, the fit-check echoes, and shared helpers.
//
//  ONE PLUG PER HOLE *RANGE*, not per bore.  A family is [d_min, d_max, wall]:
//  the shank is cut for the SMALL end (so it physically enters every hole in the
//  range) and the bead + preload are guaranteed at the BIG end (so the loosest
//  hole still bites).  Two families cover the whole boat:
//     SMALL -> 12 .. 12.2 : the inboard cable-gland bores (port_gland_d = 12)
//                           AND the lid on/off switch bore (lid_switch_d = 12.2),
//                           which used to need two near-identical plugs 0.2 apart
//     BIG   -> cap_big_d  : gland bores opened out for thicker glands (16 default)
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
//  the flange edge to pull it back out.
//
//  TWO THINGS MAKE IT HOLD (both were wrong in the first revision, hence this one):
//
//  1. REAL PRELOAD.  cap_preload is the axial overlap the plug is driven PAST the
//     point where the retention cone first fills the hole -- so with the flange
//     bottomed on the wall the fingers are still sprung inward and the wall's inner
//     CORNER is wedged on the cone.  A cone in a round edge pulls the flange down
//     AND self-centres the shank, which is what pays back the extra slide clearance
//     the 12/12.2 merge costs in the bigger hole.  (Previously cap_preload was
//     measured from the ramp START, and the cone never actually reached the hole
//     radius at the wall's inner plane: the seated plug had ~0.12 mm of axial free
//     play and rattled.  That was the "loose" complaint.)
//     NB the clamp is a SUSTAINED load (~1.7% strain in the tight end of the range), so it will
//     creep and soften over months.  Retention does not: pulling the plug still has to deflect
//     the fingers the full cap_interf, which is a short-term load.  So an old plug may stop
//     feeling tight long before it stops holding.
//
//  2. A FINGER RELIEF GROOVE.  cap_relief is an annular groove sunk into the flange's
//     SEATING face around the tube, down to the pocket floor.  Without it the flange
//     ring is fused to the tube for its full thickness, so the fingers really root at
//     the flange TOP, not at cap_base -- the cantilever is a whole flange-thickness
//     shorter than the strain formula assumes, and the true strain was ~3.2%, not the
//     2.3% the echo printed.  The groove frees the finger down to cap_base, which
//     makes the printed part match cap_strain() below and buys back enough length to
//     run a firmer bead.  Flange thickness now LENGTHENS the fingers instead of
//     shortening them, so cap_flange_t is up (it is also a better pry lip).
//
//  PRINTS FLANGE-DOWN, SUPPORTLESS: flange face flat on the bed (clean), shank up.  The
//  only overhang is the bead's retention ramp, held <=45 deg from vertical (echo); the
//  flange-top + tip chamfers self-support, and the pocket, the relief groove and the
//  slots all open upward.
//
//  Requires BOSL2 (../BOSL2) via common.scad.  PETG preferred -- its higher
//  strain-to-yield gives the fingers margin at the default cap_interf.  The echo
//  prints the PLA-safe cap_interf if you want to run these in PLA.
// =====================================================================
include <common.scad>

/* [What to render] */
cap   = "both";  // [both, small, big, seated, none] -- a print row of caps, ONE cap seated in a wall stub (preview),
                 // or "none" to suppress the standalone render when a probe includes this file
cap_n = 1;       // copies of EACH family in the row (bump to fill the plate -- caps are tiny)

/* [Bore families] */
cap_big_d = 16;  // the ENLARGED gland bore (Patrick opened some out for thicker glands).  This is the CAP's
                 // hole size only -- common.scad still cuts every gland at port_gland_d, so if the housing
                 // should print these big from now on, that is a change to common.scad, not here.

/* [Snap plug -- shared geometry] (every family shares these; only the bore range differs) */
cap_clear       = 0.4;  // DIAMETRAL slide clearance at d_min: shank OD = d_min - this.  DELIBERATELY UNCHANGED, so
                        // the shank is still 11.6 in the 12 family -- exactly the old SIDE cap's -- and any bore
                        // that took the old plug takes this one.  The bores you actually BLANK are the ones you
                        // never test-fitted a gland into, so their printed size is unverified; a horizontal 12 in
                        // FDM can come out ~11.7.  Tightening here buys little now that the cone (below) locates
                        // the plug and self-centres it -- the shank no longer does.  Drop to 0.3 if you have
                        // measured your bores at true nominal and want a snugger slide.
cap_interf      = 0.35; // RADIAL bead protrusion past d_min/2 = the retention lip AND the finger travel on insert.
                        // 0.35 gives 0.35 of bite in a d_min hole and 0.25 -- the old value -- in the d_max hole,
                        // so merging the families costs no retention at the loose end.  Drives the strain echo.
cap_flange_over = 2.5;  // flange overhang past the BIGGEST hole radius (covers the mouth + leaves a lip to pry under)
cap_flange_t    = 2.8;  // flange thickness.  With the relief groove this is finger LENGTH: raising it lowers strain
                        // (and gives a better pry lip).  Costs how proud the button sits on the wall face.
                        // 2.8, not 2.4, to buy back the length cap_root_fil spends.
cap_flange_ch   = 0.6;  // 45 deg chamfer on the flange TOP outer edge (finished look; self-supports flange-down)
cap_base        = 1.0;  // solid closed base under the pocket -- blanks the hole, carries the flange, AND is the
                        // finger ROOT height (low = long fingers).  1.0 = 5 layers at 0.2.
cap_relief      = 1.2;  // annular groove around the tube, sunk into the flange SEATING face down to cap_base.
                        // This is what makes the finger root cap_base instead of cap_flange_t -- see note 2 above.
                        // Keep (cap_relief - cap_root_fil) >= 2 extrusion widths, or the slicer fills the groove
                        // and the fingers stiffen back up -- that is the failure the echo below guards.
cap_root_fil    = 0.4;  // FILLET blending the groove floor into the finger root.  That corner is the finger's
                        // peak-stress point AND, printed flange-down, a layer interface loaded in interlayer
                        // TENSION -- the classic FDM snap-fit crack site.  A sharp notch there runs Kt ~3; this
                        // rounds it to ~1.7 for the price of cap_root_fil of free length (paid back in flange_t).
cap_tube_wall   = 1.2;  // finger wall thickness at the ROOT (3 perimeters at a 0.4 nozzle)
cap_tube_taper  = 0.4;  // inner wall opens this much toward the tip -> fingers thin to (wall - taper) at the tip
cap_slots       = 4;    // radial relief slots -> that many cantilever fingers
cap_slot_w      = 1.2;  // slot width
cap_fil_n       = 6;    // segments in the root fillet arc (cosmetic; 6 is smooth at this size)
cap_preload     = 0.15; // axial overlap PAST first cone engagement in the d_max hole -> the fingers stay sprung when
                        // the flange is home, wedging the cone in the hole's inner corner (note 1 above).  0.15 also
                        // absorbs +/-0.15 of wall-thickness error before the clamp goes slack.
cap_bead_ax     = 0.6;  // bead RETENTION ramp axial rise (tube OD -> apex): vs (interf + clear/2) radial flare, this
                        // sets the overhang angle -- raise it in step with cap_interf or the bead needs support
cap_lead_ax     = 1.0;  // bead LEAD-IN ramp axial rise (apex -> tube OD): shallow = easy push-in, fully self-supporting
cap_tip         = 0.8;  // tube length above the lead-in ramp (finger tip)
cap_tip_ch      = 0.6;  // tip outer chamfer (entry lead)

// per-bore FAMILY: [smallest hole, largest hole, wall thickness it passes through].
// Taken straight from common.scad so they can never drift.  d_min == d_max is a single-size family.
cap_wall  = max(wall, lid_t);                                       // the merged plug is cut for the THICKER face
bore_small = [min(port_gland_d, lid_switch_d),                      // 12   -- gland bore
              max(port_gland_d, lid_switch_d), cap_wall];           // 12.2 -- lid switch bore
bore_big   = [cap_big_d, cap_big_d, wall];                          // 16   -- enlarged gland bores
cap_families = [["SMALL", bore_small, "gland bores + the lid switch bore"],
                ["BIG  ", bore_big,   "gland bores opened out for thick glands"]];

// =====================================================================
//  DERIVED GEOMETRY  (one source of truth: bore_cap() and every echo call these)
// =====================================================================
function cap_tor(bore) = bore[0]/2 - cap_clear/2;   // tube (shank) outer radius -- slide fit in the SMALLEST hole
function cap_bor(bore) = bore[0]/2 + cap_interf;    // bead outer radius -- the retention lip
// axial rise from the ramp start to where the cone first fills the BIGGEST hole in the range
function cap_engage(bore) = cap_bead_ax * (bore[1]/2 - cap_tor(bore)) / (cap_bor(bore) - cap_tor(bore));
function cap_yret(bore)   = cap_flange_t + bore[2] - cap_engage(bore) - cap_preload;  // bead retention ramp START
// FREE finger: the fillet TANGENT (not the groove floor) is the real root -> bead apex
function cap_len(bore)    = cap_yret(bore) + cap_bead_ax - cap_base - cap_root_fil;
// Constant-section cantilever snap-fit strain, 1.5 * h * Y / L^2, with h = the MEAN finger thickness and
// Y = cap_interf (the travel into the d_min hole).  Using the mean is deliberate: the finger tapers, and the
// exact tapered-beam solution is eps_root = Y*h_root/(2*L^2*J) with J = int(1-u)^2/(1-cu)^3 du.  At the
// defaults that is 2.52% -- this mean-thickness stand-in reports 2.57%, i.e. conservative by ~2%.  Do NOT
// "fix" it by substituting the ROOT thickness into this constant-section form: that assumes the whole finger
// is root-thick, inflates the load a given deflection needs, and overstates the root strain by ~22%.
function cap_strain(bore) = let (L = cap_len(bore))
  1.5 * (cap_tube_wall - cap_tube_taper/2) * cap_interf / (L*L);
// How far the bead APEX sits proud of the wall's inner plane.  Must be > 0 or no part of the bead ever
// emerges behind the wall and the plug has NO retention at all -- the seat-spring figure below would still
// read healthy, because it is a linear extrapolation of the ramp with no idea where the ramp ends.
function cap_apex_clear(bore) = cap_bead_ax - cap_engage(bore) - cap_preload;
// Radial spring still held in a hole of diameter d once the flange is bottomed (>0 == it clamps).
// Clamped at the apex: the cone cannot be wider than bor no matter how far the ramp is extrapolated.
function cap_seat_spring(bore, d) =
  min(cap_bor(bore),
      cap_tor(bore) + (cap_bor(bore) - cap_tor(bore)) * (cap_engage(bore) + cap_preload) / cap_bead_ax) - d/2;

function cap_r1(x) = round(10*x)/10;
function cap_r2(x) = round(100*x)/100;
// echo helper: "0.2" for a single-size family, "0.2 @12 / 0.3 @12.2" across a range
function cap_span(bore, a, b) = (bore[0] == bore[1]) ? str(cap_r2(a))
  : str(cap_r2(a), " @", bore[0], " / ", cap_r2(b), " @", bore[1]);

// =====================================================================
//  THE CAP  (built in PRINTED orientation: flange bottom on the bed at z=0, shank +z up)
//  One solid of revolution (rotate_extrude of the half cross-section) then split into
//  fingers by the slot cuts.  Cross-section points are [radius, height].
// =====================================================================
module bore_cap(bore) {
  tor    = cap_tor(bore);
  bor    = cap_bor(bore);
  ir     = tor - cap_tube_wall;         // finger inner radius at the root
  ir_top = ir + cap_tube_taper;         // finger inner radius at the tip (tapered thinner)
  fr     = bore[1]/2 + cap_flange_over; // flange radius -- sized off the BIGGEST hole so it covers every mouth
  gor    = tor + cap_relief;            // relief-groove outer wall == flange ring inner radius
  ft     = cap_flange_t;

  y_ret  = cap_yret(bore);              // bead retention ramp START
  y_apex = y_ret + cap_bead_ax;         // bead widest point (apex)
  y_btop = y_apex + cap_lead_ax;        // bead lead-in top -- back to the tube OD
  y_top  = y_btop + cap_tip;            // finger tip
  // slots must clear the bead AND the groove wall, but must NOT notch the flange seating ring
  slot_or = max(bor, gor) + eps;

  difference() {
    rotate_extrude($fn = max($fn, 96))
      polygon([
        [0, 0], [fr, 0],                                   // flange bottom (on the bed, the visible outer face)
        [fr, ft - cap_flange_ch], [fr - cap_flange_ch, ft], // flange side + top chamfer
        [gor, ft],                                         // in across the flange SEATING ring to the groove
        [gor, cap_base],                                   // down the groove outer wall to its floor
        // FILLET the groove floor into the finger root -- that corner is the peak-stress point and, printed
        // flange-down, a layer interface in interlayer tension.  Arc runs -90 -> -180 about the corner centre.
        for (i = [0 : cap_fil_n]) let (th = -90 - i*90/cap_fil_n)
          [tor + cap_root_fil*(1 + cos(th)), cap_base + cap_root_fil*(1 + sin(th))],
        [tor, y_ret], [bor, y_apex], [tor, y_btop],        // tube OD up, bead retention ramp OUT, lead-in ramp back IN
        [tor, y_top - cap_tip_ch], [tor - cap_tip_ch, y_top], // tube to the tip + tip chamfer
        [ir_top, y_top],                                   // across the tip face to the inner wall
        [ir, cap_base], [0, cap_base]                      // tapered inner wall down to the pocket floor, in to the axis
      ]);
    // relief slots: cap_slots radial cuts from the groove floor up past the tip -> discrete cantilever fingers.
    // Each leaves the solid base (z < cap_base) and the flange ring (r > slot_or) intact.
    for (i = [0 : cap_slots - 1])
      rotate([0, 0, i*360/cap_slots])
        translate([slot_or/2, 0, cap_base + (y_top - cap_base)/2 + eps])
          cube([slot_or, cap_slot_w, y_top - cap_base + 2*eps], center = true);
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
echo("=== BLANKING CAPS (snap-in plugs for unused bores) ===");
if (wall != lid_t)
  echo(str("  << WARNING: wall ", wall, " != lid_t ", lid_t, " -- the merged plug is cut for ", cap_wall,
           "; the thinner face gets ", cap_r2(abs(wall - lid_t)), " mm of axial slop.  Split the family."));

// -- per family: what it serves, and what the fit looks like at BOTH ends of its hole range --
for (f = cap_families) {
  echo(str("  ", f[0], " plug -- ", f[2], ": holes ", f[1][0],
           f[1][0] == f[1][1] ? "" : str("-", f[1][1]), " through ", f[1][2], " mm"));
  echo(str("      shank OD ", cap_r2(2*cap_tor(f[1])), " -> radial slide ",
           cap_span(f[1], f[1][0]/2 - cap_tor(f[1]), f[1][1]/2 - cap_tor(f[1])),
           " ; bead OD ", cap_r2(2*cap_bor(f[1])), " -> BITE ",
           cap_span(f[1], cap_bor(f[1]) - f[1][0]/2, cap_bor(f[1]) - f[1][1]/2), " ",
           cap_bor(f[1]) - f[1][1]/2 >= 0.2 ? "OK (>=0.2 at the loose end)"
                                            : "  << WARNING: the big hole barely bites -- raise cap_interf"));
  // the apex MUST clear the wall's inner plane, or nothing springs out behind the wall and there is no
  // retention at all -- check this BEFORE trusting the clamp figure, which cannot see the end of the ramp
  echo(str("      bead apex proud of the wall's inner face by ", cap_r2(cap_apex_clear(f[1])), " ",
           cap_apex_clear(f[1]) >= 0.05
             ? "OK (>0 == the bead emerges and can hold)"
             : "  << WARNING: apex sits INSIDE the wall -- NO retention.  Lower cap_preload or raise cap_bead_ax"));
  echo(str("      seated CLAMP (fingers still sprung with the flange home): ",
           cap_span(f[1], cap_seat_spring(f[1], f[1][0]), cap_seat_spring(f[1], f[1][1])), " ",
           cap_seat_spring(f[1], f[1][1]) > 0 ? "OK (>0 == it pulls the flange down, no rattle)"
                                              : "  << WARNING: zero preload -- the plug will have axial free play"));
  echo(str("      flange dia ", cap_r1(f[1][1] + 2*cap_flange_over), " x ", cap_flange_t, " proud ; cap height ",
           cap_r1(cap_yret(f[1]) + cap_bead_ax + cap_lead_ax + cap_tip), " ; free finger ",
           cap_r2(cap_len(f[1])), " ; strain ", cap_r1(100*cap_strain(f[1])), "%"));
}

// -- SUPPORTLESS: the bead retention ramp is the only overhang, and it is family-independent --
bead_oh = atan((cap_interf + cap_clear/2)/cap_bead_ax);
echo(str("  SUPPORTLESS check: bead retention ramp = ", cap_r1(bead_oh), " deg from vertical ",
         bead_oh <= 45 ? "OK (<=45, prints flange-down with no support)"
                       : "  << WARNING: raise cap_bead_ax (ramp too horizontal)"));
// -- the tip chamfer must not eat past the tapered inner wall or the half-section self-intersects --
tip_face = cap_tube_wall - cap_tube_taper - cap_tip_ch;
echo(str("  tip face width ", cap_r2(tip_face), " ",
         tip_face > 0 ? "OK (>0, the cross-section closes)"
                      : "  << WARNING: cap_tip_ch + cap_tube_taper >= cap_tube_wall -- section self-intersects"));
// -- the relief groove is what makes the strain figure above true; the fillet eats into its floor --
echo(str("  finger relief groove ", cap_relief, " wide x ", cap_r1(cap_flange_t - cap_base),
         " deep, narrowing to ", cap_r2(cap_relief - cap_root_fil), " at the floor (", cap_root_fil,
         " root fillet) ",
         // compare the ROUNDED value we just printed -- 1.2-0.4 is 0.79999.. in floating point
         cap_r2(cap_relief - cap_root_fil) >= 0.8
           ? "OK (>=0.8 = 2 extrusions; the fingers root at cap_base, not at the flange top)"
           : "  << WARNING: too narrow to print -- the flange will fuse to the tube and stiffen the fingers"));
cap_strain_max = max([for (f = cap_families) cap_strain(f[1])]);
echo(str("  finger bending strain on insert (worst family) ", cap_r1(100*cap_strain_max), "% ",
         cap_strain_max <= 0.03 ? "OK (<=3% -- fine for PETG)"
                                : "  << high: raise cap_flange_t / lower cap_base, or reduce cap_interf"));
// PLA yields near 2%: report the cap_interf that would get there rather than just warning
cap_interf_pla = cap_interf * 0.02 / cap_strain_max;
echo(str("  PETG at cap_interf ", cap_interf, " ; for PLA drop cap_interf to ~", cap_r2(cap_interf_pla),
         " (2% strain) -- the bite in the loose hole then falls to ",
         cap_r2(cap_interf_pla - (bore_small[1] - bore_small[0])/2)));

// -- SMALL flange must sit inside the switch rib keep-out (rib-free zone the lid already carves) --
lid_keepout  = min(switch_ftp[0] + 2*switch_clear, switch_ftp[1] + 2*switch_clear);
small_flange = bore_small[1] + 2*cap_flange_over;
echo(str("  SMALL flange ", small_flange, " vs switch rib keep-out ", lid_keepout, " ",
         small_flange <= lid_keepout ? "OK (seats clear of the lid ribs)"
                                     : "  << WARNING: shrink cap_flange_over"));
// -- side-wall crowding: a fitted gland next door, and (now that flanges are bigger) a second CAP next door --
min_gland_pitch = min([ for (i=[0:len(gland_zs)-1], j=[i+1:len(gland_zs)-1]) abs(gland_zs[i]-gland_zs[j]) ]);
for (f = cap_families) {
  fl = f[1][1] + 2*cap_flange_over;
  echo(str("  ", f[0], " flange ", cap_r1(fl), " on the inboard wall (gland pitch ", min_gland_pitch,
           ", gland ftp ", port_ftp, "): gap to a fitted gland ", cap_r1(min_gland_pitch - fl/2 - port_ftp/2),
           ", to another cap ", cap_r1(min_gland_pitch - fl), " ",
           min(min_gland_pitch - fl/2 - port_ftp/2, min_gland_pitch - fl) >= 2
             ? "OK (>=2)" : "  << tight: a cap crowds its neighbour -- shrink cap_flange_over"));
}
echo(str("  print FLANGE-DOWN, supportless ; insert from OUTSIDE, pry the flange lip to remove"));
echo(str("  splash: the ", cap_base, " mm closed base + the seated flange ring block the bore; the relief groove is"));
echo("  a blind annulus behind that ring, not a leak path.  Silicone / a foam washer if you want it watertight.");
echo("------------------------------------------------------------");

// =====================================================================
//  STANDALONE RENDER
//   cap="both"/"small"/"big" -> a print row (flange-down, ready to slice)
//   cap="seated"             -> one SMALL cap pushed into a stub of its LOOSEST hole
//                               (the worst case: if it clamps there it clamps everywhere)
// =====================================================================
bores = (cap == "small") ? [ for (i=[0:cap_n-1]) bore_small ]
      : (cap == "big")   ? [ for (i=[0:cap_n-1]) bore_big ]
      :                    concat([ for (i=[0:cap_n-1]) bore_small ], [ for (i=[0:cap_n-1]) bore_big ]);
pitch = (bore_big[1] + 2*cap_flange_over) + 4;   // biggest flange dia + 4 mm gap

if (cap == "seated") {
  bore_cap(bore_small);
  wall_stub(bore_small[1], bore_small[2]);
} else if (cap != "none") {
  for (i = [0 : len(bores)-1])
    translate([i*pitch - (len(bores)-1)*pitch/2, 0, 0]) bore_cap(bores[i]);
}
