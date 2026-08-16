// =====================================================================
//  PVC PIPE FAIRING CAP  --  12 mm tube, press fit, parabolic nose.
//
//  A blunt-cut pipe end is the worst shape there is in water: the flow has
//  nowhere to go, it separates off the rim and drags a low-pressure wake
//  behind it.  This part plugs into the end of the tube and replaces that rim
//  with a nose that the water can follow.
//
//  ------------------------------------------------------------------
//  WHY A PARABOLA, AND WHICH ONE
//  The parabolic-series nose cone is the standard family:
//
//      r(x)/R = (2u - K u^2)/(2 - K),   u = x/L measured back from the TIP
//
//  K = 0 is a plain cone, K = 1 the "full parabola".  K = 1 is the one worth
//  having here, because its slope at the BASE is exactly zero:
//
//      dr/dz|base = R(2 - 2K)/(L(2 - K)) = 0   when K = 1
//
//  which means the nose leaves the 12 mm tube TANGENT -- same diameter, same
//  slope, no step and no corner for the flow to trip over.  With K = 1 the
//  formula collapses to something you can check by eye:
//
//      r(z) = R (1 - (z/L)^2)        z measured UP from the base
//
//  ------------------------------------------------------------------
//  AND WHY IT IS ROUNDED
//  A K = 1 parabola ends in a mathematical POINT with a finite slope (2R/L),
//  which is a spike one extrusion wide -- it prints as a stringy nub and snaps
//  off the first time the boat touches a rock.  So the last of it is replaced
//  by a sphere of radius tip_r that is TANGENT to the parabola: solved for, not
//  eyeballed, so there is no slope break where the two meet.  The tangency
//  condition with the sphere centred on the axis is
//
//      rho = r0 * sqrt(1 + m^2)       m = |dr/dz| at the join
//      zc  = z0 - r0 * m
//
//  and tip_u is bisected until rho comes out at tip_r.  Rounding the point off
//  necessarily SHORTENS the nose: nose_l is the parabola's nominal length, and
//  the part ends up ~1.3 mm shorter than that.  verify_cap.py prints the real
//  one.  Hydrodynamically the rounding is free -- a blunt nose radius costs
//  nothing at this Reynolds number, it is separation at the TAIL that costs.
//
//  nose_l = 18 is a 1.5:1 fineness ratio, a good all-rounder.  If this cap
//  goes on the DOWNSTREAM end, lengthen it: a trailing fairing wants 2.5-3:1
//  because the pressure recovery there is what actually sheds the wake.  The
//  leading end never needs more than about 1.5:1.
//
//  ------------------------------------------------------------------
//  THE PRESS FIT
//  The tube measures ~9.9 mm ID, and "~" is the problem: a plain cylinder
//  sized for 9.9 either will not start in a 9.75 bore or rattles in a 10.05
//  one.  So the plug does not touch the bore along its length at all.  It
//  carries rib_n annular RIBS whose crests stand proud of the bore and whose
//  body sits clear of it, exactly like a hose barb:
//
//      crest  plug_crest_d      interferes, deforms locally, grips
//      body   crest - 2*rib_h   clears the bore, contributes nothing
//
//  Only the crests touch, so insertion force stays low while the interference
//  per unit of contact stays high, and a bore anywhere in a ~0.4 mm band is
//  gripped by the same part.  Each rib is a sawtooth, not a bead: a long
//  shallow ramp on the way IN (16 deg from vertical -- printable, and it is
//  the only reason the plug enters by hand) and a square annular step on the
//  way OUT (90 deg -- maximum bite, and it faces UP in the print so it costs
//  nothing).  The asymmetry is the whole trick and it only works in this
//  orientation.
//
//  ------------------------------------------------------------------
//  WHAT LIMITS THE INTERFERENCE IS THE TUBE, NOT THE PLUG
//  The first cut of this shipped a 10.10 crest -- 0.20 mm into a 9.90 bore --
//  on the reasoning that the rib crest would just crush.  That reasoning looks
//  only at the plug, and the plug is the strong half.
//
//  A 12.0 OD tube with a 9.9 bore has a wall of 1.05 mm.  That is a thin-walled
//  tube, and it takes the interference as hoop strain: eps = (delta/2)/r_mean
//  with r_mean 5.475, so
//
//      crest 10.00   +0.100 diametral   0.91 % strain   ~27 MPa    55 % of yield
//      crest 10.10   +0.200 diametral   1.83 % strain   ~55 MPa   110 % of yield
//      crest 10.20   +0.300 diametral   2.74 % strain   ~82 MPa   164 % of yield
//
//  taking rigid uPVC at ~3 GPa and a ~50 MPa tensile yield.  That is a bound,
//  not a prediction -- it assumes the tube absorbs ALL of it and the PETG rib
//  crushes none, which is pessimistic.  But it is the right bound to design to,
//  because the ratio survives any plausible modulus, and 0.20 mm sits AT yield.
//  Past yield a thin PVC wall does not spring back; it creeps, and a fairing
//  that has permanently belled its own tube cannot be re-seated.
//
//  So the ceiling is +0.10 mm diametral and the gauge does not offer more.
//  verify_cap.py [4] computes this from the shipped numbers and fails above
//  60 % of yield, so the ceiling cannot be raised by editing one line and
//  forgetting why it was there.
//
//  ------------------------------------------------------------------
//  PRINT IT NOW -- WHY THE SHIPPED SIZE IS LINE-TO-LINE AND NOT A PRESS
//  plug_crest_d ships at 9.90: exactly the nominal bore, zero nominal
//  interference.  That is not timidity, it is the asymmetry of the two ways
//  this can be wrong once glue is on the table.
//
//      too LOOSE  -> a drop of adhesive in the rib grooves and it is fixed
//      too TIGHT  -> it will not seat, and the tube is what yields
//
//  One failure is a ten-second recovery and the other wastes the print and
//  possibly the tube, so the shipped number errs at the recoverable end.
//
//  And it is very unlikely to actually BE loose.  FDM lays outer diameters
//  fat -- perimeter overlap and squish typically put a nominal 9.90 crest out
//  at 9.95-10.05 in the hand -- so line-to-line on paper is a light press in
//  practice, which is precisely the fit wanted.  Nominal is the one place it
//  is safe to aim, because the printer's error only ever pushes it toward
//  grip, and the ceiling (below) is still 0.10 mm away when it does.
//
//  THE RIB GROOVES ARE GLUE RESERVOIRS, which is the other reason this
//  geometry suits a bonded joint better than a plain cylinder would.  A true
//  interference fit on a smooth plug wipes the adhesive off on the way in and
//  leaves a starved joint; the annular gaps between these ribs run 3.3 mm from
//  crest to crest and 0.35 mm deep, and carry a bead all the way in.  Run
//  cyanoacrylate or a PVC solvent cement round the second rib and press.
//
//  If it does end up loose and you would rather not glue, `capgauge` is still
//  there -- five stubs at five crest diameters, labelled, printed the same way
//  up -- and the tightest one that seats by hand is the number to type in.  It
//  is a refinement, not a prerequisite.
//
//  AND WHILE THE CALIPERS ARE OUT, MEASURE A STUB'S COLLAR.  Every stub carries
//  the same 12.00 mm collar as the cap, printed at the same time on the same
//  machine.  Whatever it reads over 12.00 is this printer's offset on outer
//  diameters, and it applies to the crests too -- a stub labelled 9.9 whose
//  collar measures 12.15 is really pressing about 10.05.  That is the number
//  the tube feels, and it is the one to check the table above against.  The
//  labels are nominal; the collar tells you what nominal is worth here.
//
//  ------------------------------------------------------------------
//  THE SEAT, AND THE ONE OVERHANG IN THE PART
//  Insertion depth has to be set by a hard stop or the joint is wherever it
//  happened to stop, and a fairing whose base is 1 mm proud of the tube has a
//  groove around it that undoes the point of the exercise.  So the collar
//  butts the tube's end face on a flat annulus seat_w wide.
//
//  That seat is a horizontal down-facing ring ~12.8 mm up in the air -- a 90
//  deg overhang, and the ONLY one in the part.  It cannot be designed away:
//  any chamfer that removes it leaves the collar rim standing proud by the
//  full wall thickness, which is the groove again.  What CAN be done is make
//  it narrow, so it is one perimeter wide and the slicer just walks it out:
//  seat_w = 0.6, with a 40 deg chamfer carrying the rest of the step.  The
//  underside comes out rough, which is fine -- it is buried in the joint and
//  the roughness is friction.  verify_cap.py measures this area and fails if
//  ANY other facet in the part is steeper than 45 deg.
//
//  ------------------------------------------------------------------
//  FRAME / PRINT
//    +Z  pipe axis AND build direction.  Plug's free end on the bed, nose up.
//
//  That orientation is not a preference, it is what makes the part work:
//  everything on the nose faces up and out (dr/dz <= 0 all the way), so a
//  shape that is nothing BUT overhang printed any other way needs no support
//  at all printed this way, and the rib sawteeth land the right way round.
//
//  PETG, 0.2 mm layers, NO SUPPORT, 4 perimeters, ~25% infill.
//  USE A BRIM.  The part is ~31 mm tall on an 8.3 mm footprint -- it prints
//  fine and knocks over easily.
//  Print at least two at once (`capset` is four), or set a 15 s minimum layer
//  time: the last few mm of the tip are a handful of seconds per layer and
//  will slump into a blob if nothing else on the plate is buying them time.
// =====================================================================

// ---------------------------------------------------------------- the pipe
pipe_od      = 12.00;   // tube OUTSIDE diameter -- the fairing's base diameter
pipe_id      =  9.90;   // tube INSIDE diameter, as measured
plug_crest_d =  9.90;   // Rib crest diameter -- LINE-TO-LINE with the bore.
                        // Deliberately not an interference number: see
                        // "PRINT IT NOW" below.  The gauge can tighten it.

// ---------------------------------------------------------------- the plug
rib_n     = 3;          // ribs along the plug
rib_h     = 0.35;       // crest height above the plug body (radial)
rib_ramp  = 1.20;       // axial run of the lead ramp.  >= rib_h or it overhangs
rib_land  = 0.70;       // axial land at the crest -- the bit that actually grips
rib_pitch = 4.00;       // rib spacing
pilot_l   = 2.00;       // the TOP rib's land runs this long instead: it sits at
                        // the tube mouth and stops the cap sitting cocked
lead_l    = 1.20;       // lead-in taper at the free end
lead_drop = 0.55;       // radial: how far below the body the lead-in starts

// ---------------------------------------------------------------- the seat
seat_w    = 0.60;       // radial width of the flat ring that butts the tube end
seat_ang  = 40;         // deg from vertical of the chamfer under it (<= 45)
collar_h  = 1.50;       // straight 12 mm collar between the tube end and the nose

// ---------------------------------------------------------------- the nose
nose_l    = 18.00;      // parabola's NOMINAL length; the rounded tip eats ~1.3
tip_r     = 1.50;       // radius of the tangent sphere at the tip
para_k    = 1.00;       // parabolic series K.  1 = tangent to the tube. Keep it.

// --------------------------------------------------------------- the gauge
// Bracketed BELOW the tube's limit, not around the nominal bore: 10.00 is the
// top of the band because that is where the tube gives out (see press_stress
// below), and the spread runs down from there far enough to still find the fit
// if the printer lays outer diameters on fat.
gauge_d   = [9.60, 9.70, 9.80, 9.90, 10.00];
gauge_lbl = ["9.6", "9.7", "9.8", "9.9", "10.0"];
gauge_pitch = 15.00;
pad_w     = 11.00;      // handle paddle -- stays inside the 12 mm collar, so
pad_t     =  4.00;      // its corners are supported and it needs no support
pad_h     = 14.00;
pad_sink  =  0.60;      // how far the paddle is buried in the collar.  NOT
                        // cosmetic: landed exactly ON the collar's top face it
                        // is a coplanar union, and the mesh came back genus -8
                        // instead of -4 -- four of the five stubs kept the
                        // paddle's buried underside as a degenerate internal
                        // shell.  Overlapping the two solids gives the union
                        // something to actually cut.
label_d   =  0.50;      // debossed, so nothing on the handle sticks out
label_sz  =  3.20;

// --------------------------------------------------------------- faceting
cap_fn    = 160;        // rotate_extrude segments.  160/4 = 40, so there is a
                        // vertex exactly on the +Y axis: the verifier's probe
                        // reads the true radius, not a chord.
nose_seg  = 48;         // parabola samples
arc_seg   = 16;         // tip arc samples

// ---------------------------------------------------------------- derived
base_r   = pipe_od/2;
seat_r   = base_r - seat_w;

function rib_z0(i)   = lead_l + i*rib_pitch;
top_land_end         = rib_z0(rib_n - 1) + rib_ramp + pilot_l;

// The chamfer is driven by its ANGLE, not by a fixed height, so every gauge
// stub keeps it at seat_ang however big its crest is.  A fixed height would
// flatten it past 45 deg on the small stubs.
function seat_z(d)   = top_land_end + (seat_r - d/2)/tan(seat_ang);
function collar_z(d) = seat_z(d) + collar_h;

// ------------------------------------------------------- parabolic series
// u runs from 1 at the base to 0 at the tip.
function pk_r(u)     = base_r*(2*u - para_k*u*u)/(2 - para_k);
function pk_slope(u) = base_r*(2 - 2*para_k*u)/(nose_l*(2 - para_k));
function pk_rho(u)   = pk_r(u)*sqrt(1 + pk_slope(u)*pk_slope(u));

// rho is monotonic in u (0 at the point, base_r at the base for K = 1), so a
// plain bisection lands it.  48 halvings of [0,1] is ~3.6e-15 -- exact for our
// purposes, and it costs nothing at render time.
function solve_u(t, lo, hi, n) =
    n <= 0 ? (lo + hi)/2
           : (pk_rho((lo + hi)/2) < t ? solve_u(t, (lo + hi)/2, hi, n - 1)
                                      : solve_u(t, lo, (lo + hi)/2, n - 1));

tip_u   = solve_u(tip_r, 0, 1, 48);
tip_z0  = nose_l*(1 - tip_u);        // where the parabola hands over to the arc
tip_r0  = pk_r(tip_u);
tip_m   = pk_slope(tip_u);
tip_rho = tip_r0*sqrt(1 + tip_m*tip_m);
tip_zc  = tip_z0 - tip_r0*tip_m;     // sphere centre, on the axis
tip_phi = atan2(tip_z0 - tip_zc, tip_r0);
nose_h  = tip_zc + tip_rho;          // the ACTUAL nose length
total_h = collar_z(plug_crest_d) + nose_h;

// ---------------------------------------------------------------- meridian
// One closed profile for the whole part, revolved once.  Built as a single
// polygon rather than a stack of unioned solids so the surface is continuous
// by construction: there is no seam between the parabola and the arc to drift
// open, and no coplanar-face lottery where the collar meets the nose.
//
// Order: out along the bed, up the outside, over the tip, and the polygon
// closes back down the axis.  Interior stays on the left throughout.
function plug_pts(d) =
    let (cr = d/2, br = cr - rib_h, sz = seat_z(d))
    concat(
        [[0, 0], [br - lead_drop, 0]],
        [ for (i = [0 : rib_n - 1]) each
            (i < rib_n - 1
              ? [[br, rib_z0(i)],                                   // ramp foot
                 [cr, rib_z0(i) + rib_ramp],                        // crest
                 [cr, rib_z0(i) + rib_ramp + rib_land],             // land
                 [br, rib_z0(i) + rib_ramp + rib_land]]             // the bite
              : [[br, rib_z0(i)],
                 [cr, rib_z0(i) + rib_ramp],
                 [cr, rib_z0(i) + rib_ramp + pilot_l]]) ],          // pilot land
        [[seat_r, sz],                                              // chamfer
         [base_r, sz],                                              // THE SEAT
         [base_r, sz + collar_h]]                                   // collar
    );

function nose_pts(z0) = concat(
    [ for (j = [1 : nose_seg])
        let (z = tip_z0*j/nose_seg) [pk_r((nose_l - z)/nose_l), z0 + z] ],
    [ for (j = [1 : arc_seg - 1])
        let (a = tip_phi + (90 - tip_phi)*j/arc_seg)
            [tip_rho*cos(a), z0 + tip_zc + tip_rho*sin(a)] ],
    [[0, z0 + nose_h]]                  // forced onto the axis, not cos(90)
);

// ---------------------------------------------------------------- the part
module pipe_cap() {
    // A BAND, not a floor.  The old assert demanded interference and would
    // have rejected the line-to-line fit this now ships; the real requirement
    // is that the crest lands near the bore from either side -- far under and
    // it rattles even glued, far over and the tube yields before the rib does.
    assert(plug_crest_d > pipe_id - 0.10,
           "plug_crest_d is so far under the bore that even glue has a gap to span");
    assert(plug_crest_d < pipe_id + 0.11,
           "plug_crest_d presses the tube past its elastic limit -- the 1.05 mm \
wall yields before the rib crushes.  See the hoop-strain table in the header.");
    assert(plug_crest_d/2 - 2*rib_h < pipe_id/2,
           "plug body is wider than the bore -- the ribs would never touch");
    assert(seat_r > plug_crest_d/2,
           "seat_w leaves no room for the chamfer under the seat");
    assert(rib_ramp >= rib_h, "rib ramp steeper than 45 deg");
    assert(tip_r < base_r, "tip_r that big is a hemisphere, not a nose");
    rotate_extrude($fn = cap_fn)
        polygon(concat(plug_pts(plug_crest_d),
                       nose_pts(collar_z(plug_crest_d))));
}

// Four on a plate.  Spread out, not packed: each layer near the tip is a few
// seconds of extrusion and needs the travel time to cool.
module cap_set(n = 4, pitch = 20) {
    for (i = [0 : n - 1])
        translate([(i % 2)*pitch, floor(i/2)*pitch, 0]) pipe_cap();
}

// ---------------------------------------------------------------- the gauge
// A gauge is only worth anything if it is the SAME part.  Each stub carries
// the identical plug -- same ribs, same ramps, same seat -- printed the same
// way up, because a sawtooth rib measures differently if you flip it.  Only
// the crest diameter changes, and the nose is swapped for something to pull on.
module cap_paddle(lbl) {
    difference() {
        hull() {
            translate([0, 0, -pad_sink + 0.01])
                cube([pad_w, pad_t, 0.02], center = true);
            translate([0, 0, pad_h - pad_w/2]) rotate([90, 0, 0])
                cylinder(r = pad_w/2, h = pad_t, center = true, $fn = 64);
        }
        // rotate([90,0,180]), NOT [90,0,0].  Both stand the glyphs up on the
        // +Y face; only this one has the text's own +X pointing to the RIGHT
        // of someone looking at that face, and the first render of the other
        // came out cleanly mirrored -- a 10.2 you can misread is worse on a
        // gauge than on anything else here.  Rz(180)·Rx(90) sends local +Z
        // (the extrusion) to +Y and local +X to -X, which is that viewer's
        // right; the cut then runs from label_d inside the face to just proud
        // of it.
        translate([0, pad_t/2 - label_d, pad_h*0.45]) rotate([90, 0, 180])
            linear_extrude(label_d + 0.02)
                text(lbl, size = label_sz, halign = "center",
                     valign = "center", $fn = 32);
    }
}

module cap_stub(d, lbl) {
    union() {
        rotate_extrude($fn = cap_fn)
            polygon(concat(plug_pts(d), [[0, collar_z(d)]]));
        translate([0, 0, collar_z(d)]) cap_paddle(lbl);
    }
}

module cap_gauge() {
    assert(len(gauge_d) == len(gauge_lbl), "gauge_d and gauge_lbl disagree");
    for (i = [0 : len(gauge_d) - 1])
        translate([(i - (len(gauge_d) - 1)/2)*gauge_pitch, 0, 0])
            cap_stub(gauge_d[i], gauge_lbl[i]);
}

// ---------------------------------------------------------------- preview
// Renders when this file is opened alone.  main.scad pulls it in with `use`,
// which imports modules but does not execute top-level geometry.
pipe_cap();
