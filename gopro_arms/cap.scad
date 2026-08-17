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

include <../BOSL2/std.scad>
include <../BOSL2/threading.scad>

// ---------------------------------------------------------------- the pipe
pipe_od      = 12.00;   // tube OUTSIDE diameter -- the fairing's base diameter
pipe_id      =  9.90;   // tube INSIDE diameter, as measured
plug_crest_d =  9.95;   // Rib crest diameter.  +0.05 over the bore: nominally a
                        // whisker of interference, and with the printer's usual
                        // positive bias a light press.  Still only 27% of the
                        // tube's yield -- see "WHAT LIMITS THE INTERFERENCE".

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

// ------------------------------------------- two-part bungee cap (see below)
cord_d     =  4.00;   // through bore for the bungee
cord_flare =  0.80;   // radial trumpet where the cord leaves for the tube
body_d     = 14.00;   // the assembled body's greatest diameter
flare_h    =  6.00;   // length of the 12 -> 14 cone.  9.5 deg half-angle.
land_h     = 11.00;   // straight 14.0 band; the socket lives inside it
thr_d      = 11.50;   // thread nominal (major) diameter
thr_pitch  =  2.00;   // coarse on purpose -- see the note
thr_slop   =  0.10;   // BOSL2 $slop; internal threads gain 4*$slop
sock_thr_l =  5.00;   // threaded depth of the socket
bay_d      = 12.00;   // knot bay, bored WIDER than the thread, BELOW it
bay_l      =  6.00;   // and out of the dome's reach, so the knot is never
                      // squeezed by the part screwing down over it
spig_thr_l =  4.50;   // male thread on the dome (< sock_thr_l so the rim seats)
spig_w     =  1.00;   // dome spigot wall, at the thread core
dome_l     = 20.00;   // dome's nominal parabola length
dome_w     =  1.40;   // dome wall, radial
rim_w      =  0.60;   // flat seat at the dome's rim, same trick as the plug's

// --------------------------------------------------------------- faceting
cap_fn    = 160;        // rotate_extrude segments.  160/4 = 40, so there is a
                        // vertex exactly on the +Y axis: the verifier's probe
                        // reads the true radius, not a chord.
nose_seg  = 48;         // parabola samples
arc_seg   = 16;         // tip arc samples
cav_seg   = 40;         // dome cavity samples

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
// Parameterised on (R, L) because there are now TWO of these domes: the plain
// cap fairs the 12 mm tube directly, and the screw-on dome of the bungee cap
// fairs the 14 mm body it sits on.  One implementation, solved twice.
// u runs from 1 at the base to 0 at the tip.
function pk_r(u, R)      = R*(2*u - para_k*u*u)/(2 - para_k);
function pk_slope(u,R,L) = R*(2 - 2*para_k*u)/(L*(2 - para_k));
function pk_rho(u, R, L) = pk_r(u,R)*sqrt(1 + pow(pk_slope(u,R,L), 2));

// rho is monotonic in u (0 at the point, R at the base for K = 1), so a plain
// bisection lands it.  48 halvings of [0,1] is ~3.6e-15 -- exact for our
// purposes, and it costs nothing at render time.
function solve_u(t, R, L, lo, hi, n) =
    n <= 0 ? (lo + hi)/2
           : (pk_rho((lo + hi)/2, R, L) < t
                ? solve_u(t, R, L, (lo + hi)/2, hi, n - 1)
                : solve_u(t, R, L, lo, (lo + hi)/2, n - 1));

// Everything the tip blend needs, solved once and carried as a vector:
//   [0] u at the join   [1] z of the join   [2] r of the join   [3] |dr/dz|
//   [4] sphere radius   [5] sphere centre   [6] join angle      [7] nose height
function nose_solve(R, L, t) =
    let (u   = solve_u(t, R, L, 0, 1, 48),
         z0  = L*(1 - u),
         r0  = pk_r(u, R),
         m   = pk_slope(u, R, L),
         rho = r0*sqrt(1 + m*m),
         zc  = z0 - r0*m)
        [u, z0, r0, m, rho, zc, atan2(z0 - zc, r0), zc + rho];

nose_s  = nose_solve(base_r, nose_l, tip_r);
tip_u   = nose_s[0];
tip_z0  = nose_s[1];
tip_r0  = nose_s[2];
tip_m   = nose_s[3];
tip_rho = nose_s[4];
tip_zc  = nose_s[5];
tip_phi = nose_s[6];
nose_h  = nose_s[7];                 // the ACTUAL nose length
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

// Meridian of a nose of base radius R and nominal length L, sitting on z = z0.
// `s` is its nose_solve() vector.  Starts at j = 1, so the caller's own base
// point is not repeated.
function nose_pts_of(R, L, s, z0) = concat(
    [ for (j = [1 : nose_seg])
        let (z = s[1]*j/nose_seg) [pk_r((L - z)/L, R), z0 + z] ],
    [ for (j = [1 : arc_seg - 1])
        let (a = s[6] + (90 - s[6])*j/arc_seg)
            [s[4]*cos(a), z0 + s[5] + s[4]*sin(a)] ],
    [[0, z0 + s[7]]]                    // forced onto the axis, not cos(90)
);

function nose_pts(z0) = nose_pts_of(base_r, nose_l, nose_s, z0);

// ---------------------------------------------------------------- the part
module pipe_cap() {
    // A BAND, not a floor.  The old assert demanded interference and would
    // have rejected the line-to-line fit this now ships; the real requirement
    // is that the crest lands near the bore from either side -- far under and
    // it rattles even glued, far over and the tube yields before the rib does.
    assert(plug_crest_d > pipe_id - 0.10,
           "plug_crest_d is so far under the bore that even glue has a gap to span");
    assert(plug_crest_d < pipe_id + 0.11,
           str("plug_crest_d presses the tube past its elastic limit -- the ",
               "1.05 mm wall yields before the rib crushes.  See the ",
               "hoop-strain table in the header."));
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

// =====================================================================
//  TWO-PART BUNGEE CAP  --  an anchor you can knot to, and a dome over it.
//
//  A 4 mm bungee has to pass through the tube end and be knotted so it cannot
//  pull back, and the end still has to be hydrodynamic.  Those two jobs fight:
//  the knot wants a big open pocket, the fairing wants a smooth point.  So they
//  are two parts.
//
//    borecap   presses into the tube exactly like `cap` does -- same plug, same
//              ribs, same gauge sizes it -- but instead of a nose it carries a
//              4 mm cord bore and, above it, a threaded socket.
//    domecap   screws onto that socket and is the parabola.
//
//  ------------------------------------------------------------------
//  WHY 14 mm, AND WHY THAT IS BETTER THAN 12
//  A dome that screws over an 11.5 mm thread needs wall outside the thread, so
//  it cannot also be 12.0 -- hence the 14.0 allowance.  Rather than step 12 ->
//  14 at the tube (a forward-facing step, the one thing worth avoiding), the
//  anchor cap CONES from 12.0 at the tube up to 14.0 over flare_h: a 9.5 deg
//  half-angle, gentle enough to stay attached.
//
//  The assembly is then 12 -> 14 -> parabola to a point, which is a proper body
//  of revolution rather than a cylinder with a hat on it.  It is very likely
//  BETTER in the water than the flush 12 mm version, not a concession.
//
//  ------------------------------------------------------------------
//  WHY A THREAD RATHER THAN A SNAP
//  A snap here wanted an annular bead, and an annular bead on a 12 mm ring has
//  to stretch its whole circumference to pass: 0.3 mm of bead is 6% hoop
//  strain, well past PETG.  Getting under that needs slots, and slots on the
//  one surface that is supposed to be smooth.  A thread has no strain budget at
//  all, it is serviceable -- the knot can be retied -- and BOSL2 already has
//  the geometry.
//
//  thr_pitch is 2.00, which is coarse for an 11.5 thread and deliberately so:
//  fewer, fatter threads survive FDM's rounding, and the flanks of a 60 deg
//  profile stand 30 deg off the axis, inside the 45 deg overhang budget, so
//  both the male and the female print standing up with no support.
//
//  ------------------------------------------------------------------
//  WHERE THE KNOT ACTUALLY LIVES, WHICH IS THE WHOLE DESIGN
//  Not in the dome.  The dome's spigot descends into the socket as it is done
//  up, so anything inside the socket's top gets swept by it; a knot parked
//  there would be crushed or would jam the thread.
//
//  So the socket is deeper than the thread, and the bottom bay_l of it is a
//  plain counterbore at bay_d -- bored WIDER than the thread's own major
//  diameter, and below where the spigot ever reaches.  The knot is pushed down
//  into that bay and the dome screws down over the top of it, touching nothing.
//
//  The one number to check against a real knot is the ENTRY: the thread's minor
//  diameter, ~thr_d - 2*0.541*thr_pitch, is the narrowest thing the knot has to
//  be pushed past on its way in.  verify_cap.py [3] measures the assembled
//  chamber off both meshes and prints that choke, the bay, and the largest
//  sphere that actually fits -- check your knot against those, not against a
//  number in this comment.
//
//  ------------------------------------------------------------------
//  PRINT.  Both stand up the same way as `cap`: plug (or spigot) on the bed,
//  no support, brim.  The dome's footprint is only the spigot's end ring, so
//  the brim is not optional there.  The rim seats on the anchor cap's shoulder
//  and that -- not the thread bottoming out -- is the stop, which is why
//  spig_thr_l is shorter than sock_thr_l.  Hand tight, then glue.
// =====================================================================

thr_depth  = 0.5412*thr_pitch;            // cos(30)*5/8, BOSL2's own profile
thr_minor  = thr_d - 2*thr_depth;         // the knot's entry choke
bay_cone_h = ((bay_d - thr_minor)/2)/tan(seat_ang);   // funnel, bay -> thread
body_r     = body_d/2;
bore_flare_z = seat_z(plug_crest_d) + collar_h;   // where the 12->14 cone starts
sock_floor   = bore_flare_z + flare_h;            // socket floor: OD is 14 here
bore_top     = sock_floor + land_h;               // the anchor cap's rim face
sock_l       = land_h;

// The dome's own parabola, solved on the 14 mm base.
dome_s = nose_solve(body_r, dome_l, tip_r);
dome_h = dome_s[7];

// ---------------------------------------------------- the anchor cap
module bore_cap() {
    assert(bay_d < body_d - 1.6, "bay_d leaves under 0.8 mm of wall at 14.0");
    assert(bay_l + sock_thr_l <= sock_l + 0.001,
           "the thread plus the bay do not fit in the socket");
    assert(spig_thr_l < sock_thr_l,
           str("the dome's thread is longer than the socket's, so it would ",
               "bottom out on the thread instead of seating its rim -- ",
               "the joint would never close"));
    difference() {
        // Same plug as every other cap here, then a cone out to 14 and a band.
        rotate_extrude($fn = cap_fn)
            polygon(concat(plug_pts(plug_crest_d),
                           [[body_r, bore_flare_z + flare_h],
                            [body_r, bore_top],
                            [0,      bore_top]]));

        // knot bay -- wider than the thread, below everything the dome reaches
        // The +0.02 OVERLAPS the funnel above.  Landing the bay's top rim
        // exactly on the funnel's bottom rim -- same z, same 12.0 diameter --
        // is a zero-overlap touch, and it exported 239 edges shared by FOUR
        // triangles in a ring at z=24.819.  OpenSCAD called that "manifold,
        // Status NoError" on the way out.  Cut solids must interpenetrate.
        translate([0, 0, sock_floor - 0.01])
            cylinder(d = bay_d, h = bay_l - bay_cone_h + 0.03, $fn = cap_fn);
        // funnel from the bay up to the thread's minor diameter.  Two jobs: it
        // guides the knot DOWN into the bay, and without it the step from
        // bay_d to thr_minor is a 1.33 mm annular ceiling inside the socket --
        // 45 mm^2 of unsupported area, the largest overhang in the part.
        translate([0, 0, sock_floor + bay_l - bay_cone_h])
            cylinder(d1 = bay_d, d2 = thr_minor, h = bay_cone_h, $fn = cap_fn);
        // The thread mask cuts its OWN bore -- do not pre-drill to thr_d first.
        // Boring to the major diameter removes exactly the material the inward
        // crests are made of, and what is left is a smooth 11.5 hole with a
        // shallow helical scratch in it: measured 0.205 mm deep instead of the
        // 1.08 it should be, and it looked like a thread in the render.
        translate([0, 0, bore_top - sock_thr_l/2])
            threaded_rod(d = thr_d, l = sock_thr_l + 0.02, pitch = thr_pitch,
                         internal = true, bevel = false, blunt_start = true,
                         $slop = thr_slop, $fn = 72);
        // cord bore, and a trumpet at the tube end so a working cord cannot
        // saw itself on a square edge
        translate([0, 0, -1])
            cylinder(d = cord_d, h = sock_floor + 2, $fn = 96);
        translate([0, 0, -0.01])
            cylinder(d1 = cord_d + 2*cord_flare, d2 = cord_d,
                     h = 2*cord_flare, $fn = 96);
    }
}

// ------------------------------------------------------- the dome cap
// z = 0 is the RIM, the face that lands on the anchor cap's shoulder.  The
// spigot hangs below it and the parabola stands above, so the two parts share
// one datum and the joint cannot drift.
function dome_outer_pts() =
    let (cr = thr_minor/2,                       // spigot core radius
         ch = (body_r - rim_w - cr)/tan(seat_ang))
    concat(
        [[0, -spig_thr_l],
         [cr - 0.4, -spig_thr_l],                // lead-in, 32 deg
         [cr, -spig_thr_l + 0.65],
         [cr, -ch],
         [body_r - rim_w, 0],                    // chamfer up to the rim
         [body_r, 0]],                           // THE RIM SEAT
        nose_pts_of(body_r, dome_l, dome_s, 0)
    );

function dome_cav_pts() =
    let (ir = thr_minor/2 - spig_w,
         ch = (body_r - rim_w - thr_minor/2)/tan(seat_ang),
         zc = dome_l*sqrt(1 - dome_w/body_r))    // where the cavity closes (K=1)
    concat(
        [[0, -spig_thr_l - 1], [ir, -spig_thr_l - 1], [ir, -ch]],
        [[body_r - dome_w, 0]],
        [ for (j = [1 : cav_seg - 1])
            let (z = zc*j/cav_seg)
                [max(0, pk_r((dome_l - z)/dome_l, body_r) - dome_w), z] ],
        [[0, zc]]
    );

module dome_cap() {
    assert(para_k == 1, "the cavity's closing height is solved for K = 1 only");
    difference() {
        union() {
            rotate_extrude($fn = cap_fn) polygon(dome_outer_pts());
            // The thread is added, not cut: the spigot above is a plain core.
            translate([0, 0, -spig_thr_l/2])
                threaded_rod(d = thr_d, l = spig_thr_l, pitch = thr_pitch,
                             bevel1 = true, blunt_start = true, $fn = 72);
        }
        rotate_extrude($fn = cap_fn) polygon(dome_cav_pts());
    }
}

// Both parts as they end up, for looking at.  NOT a print plate.
module cap_stack() {
    bore_cap();
    translate([0, 0, bore_top]) dome_cap();
}

// ---------------------------------------------------------------- preview
// Renders when this file is opened alone.  main.scad pulls it in with `use`,
// which imports modules but does not execute top-level geometry.
pipe_cap();
