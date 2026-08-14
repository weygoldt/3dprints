// =====================================================================
//  GoPro extension arms  --  SIMPLE variant.
//
//  A sibling to arm.scad, not a replacement.  arm.scad is purposefully
//  STREAMLINED: it hangs under a boat with water flowing past it, so it
//  pays for a Kamm-tail strut section with material, print time and hinge
//  travel.  This one buys all three back for a general-purpose arm.
//
//  It shares every millimetre of the GoPro interface with arm.scad -- same
//  3 mm grid, same 0.10 mm clearances, same trimmed knuckle, same prong free
//  length.  The BODY, the SCREW POCKETS and the BORE differ, and all three
//  differences follow from one decision: this variant is printed with support,
//  so it stops paying for self-bridging geometry it no longer needs.
//
//  ------------------------------------------------------------------
//  WHAT CHANGES, AND WHY
//
//  1. BODY.  A constant-section slab exactly as tall as the knuckle
//     (sb_h == tab_top), instead of a 20 mm chord lofted up from it.
//     Three things fall out of that one decision:
//       * no chord ramp at all -- the top face is one flat plane from
//         knuckle to knuckle, so the loft only has to flare the WIDTH;
//       * 20 % less material on a 100 mm arm, even after paying for a
//         second boss (measured off the mesh: 16016 -> 12813 mm^3);
//       * 12.8 mm tall instead of 20.0, so ~36 % fewer layers and a shorter
//         perimeter loop in each one -- which is where print time on a
//         nearly-solid part actually goes.
//     All four edges are ROUNDED, r2.5, leaving a 3.9 mm flat top and bottom.
//     Deliberately still NOT an ellipse -- 66 % of the section height is a
//     dead-straight vertical flank, and the verifier fails under 40 %.
//     Smoothed, not faired; streamlining is what arm.scad is for.
//
//     Articulation is NOT one of the things that improves, which is worth
//     writing down because it looks like it should be.  Measured, both
//     variants clear exactly the same band (-100..+90 into a GoPro mount,
//     -110..+80 arm to arm).  What limits the swing is the full-height,
//     full-width block between the pivot and the end of the slots -- and
//     that block is identical in both, because the slots have to run out to
//     pocket_r either way.  The 20 mm chord never was the binding
//     constraint; it only starts ramping up once it is already past it.
//
//  2. SCREW POCKETS.  One in each outer prong, and they are NOT the same
//     pocket, because one shape cannot do both jobs.  The nut side is a
//     press-fit hex; the far side is a plain round counterbore that takes the
//     barrel head flush.  Both parts bear on their pocket FLOOR, the inboard
//     end, so screw tension pulls each onto solid material.
//
//  ------------------------------------------------------------------
//  WHY TWO DIFFERENT POCKETS
//
//  Both were 8.80 across flats, sized to swallow an 8.50 barrel head.  That
//  leaves the 8.00 nut 0.80 mm of play, and it rattles -- the streamlined arm
//  already rattles at 0.20.  Sizing them both to the nut instead fixes the
//  rattle and throws away the flush head: 8.50 will not enter 8.00 flats at
//  all, so the head stands fully proud.
//
//  Neither compromise is necessary once you stop insisting the two pockets
//  match.  A screw head needs a SEAT; only a nut needs ANTI-ROTATION.  So the
//  head gets a round bore, the nut gets a hex, and each is sized and sunk for
//  exactly what goes in it.  The cost is that the nut now lives on nut_side
//  permanently -- which, with a press fit, is what happens anyway.
//
//  For the record, so nobody re-derives it: a barrel head needs 4.25 mm of
//  clearance in EVERY radial direction and a nut that will not rattle needs
//  the flats at 4.00, so no single outline satisfies both.  Stepping ONE
//  pocket does not rescue it either -- the nut has to pass through the head
//  counterbore to reach the hex below, so that counterbore must clear the
//  nut's 9.24 across-corners, and the two depths add instead of overlapping,
//  which puts the stack past 30 mm to recess 5 mm of screw head.
//
//  ------------------------------------------------------------------
//  WHAT FITS IT
//    M5x16 socket cap  + M5 nut     the pairing this is built around.  Head
//                                   sits 0.30 below its face, nut 0.30 below
//                                   its own, and the tip stops 0.40 inside
//                                   the nut pocket with 3.9 of the nut's 4.0
//                                   mm engaged.  Nothing protrudes anywhere.
//                                   Driven with a 4 mm key, which is far more
//                                   torque than a thumbscrew and is half the
//                                   point of the whole arrangement.
//    GoPro thumbscrew  + M5 nut     as arm.scad; the head just sits proud
//
//  ------------------------------------------------------------------
//  SUPPORT.  This is the one part of the project that needs it, in two
//  places, and both are deliberate:
//    * the SCREW POCKETS.  pkt_peak = false leaves the hex a flat ceiling
//      pkt_r wide, and the head counterbore is a round bore whose roof is a
//      ceiling however you cut it.  ~56 mm^2.  DIG IT OUT BEFORE THE NUT AND
//      THE SCREW GO IN.
//    * the BODY'S BOTTOM EDGES.  A fillet is tangent to the bed face, so it
//      leaves through 90 deg of overhang -- which is exactly why this edge
//      was a 45 deg chamfer until the pockets forced support anyway.  ~263
//      mm^2 on a 100 mm arm, running the whole length of the underside, and
//      the footing narrows from 5.90 to 3.90 mm.  Brim it.
//    * the PIVOT BORES.  Round instead of teardropped, so their top ~87 deg
//      of arc is a ceiling: ~51 mm^2, and it is support INSIDE a 5.30 hole,
//      the fiddliest on the part.  A 5 mm drill clears it if it comes out
//      ragged; the screw seats on the bottom of the bore, so the top is
//      clearance either way.
//  Everything else is still supportless by construction: the top rounding is
//  upward-facing and the knuckle flanks leave the bed at exactly 45.
//
//  sb_rb = 0, pkt_peak = true and bore_round = false give the supportless
//  part back -- square bottom, a nut seating on a peak, a pointed bore.
//
//  The bosses stay sharp on purpose: the knuckle silhouette already leans
//  45 deg where it meets the bed, so a chamfer around the boss rim would tip
//  that underside past the budget.  A rim chamfer is only free on geometry
//  that meets the bed vertically.
// =====================================================================

lib = true;          // suppress arm.scad's standalone preview
include <arm.scad>

// ------------------------------------------------------- screw / pockets
// TWO DIFFERENT POCKETS, because one shape cannot do both jobs.
//
// An M5 nut is 8.00 across flats.  An M5 barrel head (DIN 912 socket cap) is
// 8.50 ACROSS -- wider than the nut is.  The head needs 4.25 mm of clearance
// in EVERY radial direction; a nut that is not going to rattle needs the
// flats at 4.00.  No single outline satisfies both, and stepping one pocket
// does not rescue it either: the nut has to PASS THROUGH the head counterbore
// to reach the hex below, so that counterbore must clear the nut's 9.24
// across-corners, and the two depths add instead of overlapping -- which puts
// the stack past 30 mm to recess 5 mm of screw head.
//
// So stop trying.  The pockets do not have to match:
//
//   nut_side   HEX 8.00 across flats, nut_depth deep -- a PRESS FIT.  The nut
//              goes in once and stays.  Nothing to spin, nothing to rattle.
//   far side   ROUND hd_d across, hd_depth deep -- the barrel head drops in
//              FLUSH.  A screw head needs no anti-rotation, only a seat, so
//              a plain bore is the right shape and a hex would be pretence.
//
// What this gives up is the nut going on either side; it now lives on
// nut_side permanently.  With a press fit that is what happens anyway.
//
// Both parts bear on their pocket FLOOR, the inboard end, so screw tension
// pulls each onto solid material instead of trying to lift it out.
nut_side  = -1;      // which outer prong takes the press-fit nut

pkt_af    = 8.00;    // nut pocket, across flats
// Modelled at NOMINAL on purpose.  FDM lays pockets down a touch undersize,
// and that is where the interference comes from -- asking for it in the model
// as well would stack two tolerances the same way.  Tune it on `sgauge`
// before committing a plate: raise it if the nut will not start square,
// lower it if it drops in under its own weight.

// A flat roof instead of the 45 deg peak.  The peak existed so the pocket
// could bridge itself; printed with support it is just wasted depth, and the
// flat roof is what a nut actually wants to seat against.
pkt_peak  = false;

// A plain ROUND pivot bore instead of arm.scad's 45 deg teardrop, for the same
// reason: the teardrop exists so the bore can bridge its own roof, and this
// variant is supported anyway.  Two things fall out of it, one good and one
// worth knowing:
//   * the crown over the bore gains 1.10 mm -- the teardrop's apex cuts up to
//     z=9.05, a round bore stops at 7.95, so there is 4.85 mm of material
//     above it instead of 3.75;
//   * the bore's top ~87 deg of arc becomes a ceiling and the slicer will put
//     support INSIDE a 5.30 hole, which is the fiddliest support on the part.
//     Run a 5 mm drill through afterwards if it comes out ragged; the screw
//     seats on the BOTTOM of the bore, so the top is clearance either way.
// bore_round = false gives arm.scad's teardrop back, and with pkt_peak = true
// and sb_rb = 0 the whole part is supportless again.
bore_round = true;

head_d     = 8.50;   // DIN 912 socket cap ("barrel head"), M5: across
head_h     = 5.00;   // ... and tall
head_clr   = 0.30;
head_seat  = 0.30;   // so the head sits just below flush

pkt_r     = pkt_af/sqrt(3);                    // 4.619 circumradius
pkt_depth = nut_t + nut_seat;                  // 4.30
hd_d      = head_d + head_clr;                 // 8.80
hd_depth  = head_h + head_seat;                // 5.30

// Each side's boss is only as deep as its own pocket needs.
boss_nut  = max(0, pkt_depth + nut_wall - prong_out_t);   // 2.40
boss_hd   = max(0, hd_depth  + nut_wall - prong_out_t);   // 3.40
sw3_nut   = w3_half + boss_nut;                           // 10.35
sw3_hd    = w3_half + boss_hd;                            // 11.35
sw3_max   = max(sw3_nut, sw3_hd);                         // -> 21.7 stack

// Roof and floor of BOTH pockets have to stay inside the knuckle.
pkt_top   = pivot_z + pkt_af/2 + (pkt_peak ? pkt_r/2 : 0);
assert(max(pkt_top, pivot_z + hd_d/2) <= tab_top - 0.45,
       str("a pocket roof breaks out of the knuckle crown (nut ", pkt_top,
           ", head ", pivot_z + hd_d/2, " vs tab_top ", tab_top, ")"));
// A pocket centred on the pivot is ALWAYS thinner underneath than over: the
// trimmed knuckle puts the pivot at R/sqrt(2) = 5.303 above the bed but 7.500
// below the crown.  Floors here are 1.303 (nut) and 0.903 (head) against 3.500
// and 3.100 of crown.  Two things about that are worth not re-deriving:
//
//   * the hex's FLATS-UP orientation, picked so the roof could bridge, is also
//     the one that maximises this floor.  Do NOT rotate it 30 deg to put a
//     vertex down -- that drops the nut pocket's floor to 0.684.
//   * the only way to thicken both floors is to raise pivot_z, and pivot_z is
//     defined in arm.scad and shared with the STREAMLINED ARM and the CLAMP,
//     which are supportless and already in service.  Raising it means either
//     changing them too or threading a per-variant pivot through the one file
//     this variant has deliberately never touched.  The gain would also land
//     mostly on the pocket that carries no load.
//
// The load lands on the HEX pocket (press-fit hoop stress, nut torque) and that
// one has 1.303, more than the 1.203 the streamlined arm has shipped with; the
// thin one only holds a screw head bearing axially on its floor.  Print with 7
// bottom solid layers so both floors come out as solid skin.
assert(min(pivot_z - pkt_af/2, pivot_z - hd_d/2) >= 0.80,
       "a pocket floor leaves less than 0.80 mm of material to the bed");
// The nut pocket must still stop the nut turning: its corners have to stand
// outside the pocket's flats.
assert(pkt_af/2 < nut_af/sqrt(3) - 0.05,
       "nut pocket is so wide the M5 nut spins freely -- it is not a trap");
// ... and not be so tight that no nut will ever enter it.
assert(pkt_af >= nut_af - 0.25,
       "nut pocket is more than 0.25 under the nut: nothing will seat it");
// The head pocket has one job and it is worth asserting it does it.
assert(hd_d >= head_d + 0.10,
       "head counterbore is not wider than the head -- it will not seat");

// -------------------------------------------------------------- the body
// A constant slab, exactly as tall as the knuckle, so there is no chord
// ramp to build and the top face is one plane end to end.
sb_h     = tab_top;          // 12.803  body height == knuckle height
sb_t     = 2*w2_half;        //  8.900  body width == the 2-prong stack, so
                             //         the beam runs straight into that end
sb_rt    = 2.50;             // top edge rounding radius
// Bottom edges are ROUNDED too, not chamfered.  That is a deliberate spend:
// a fillet is tangent to the bed face, so it starts at 90 deg of overhang and
// needs support for the whole length of the arm -- which is exactly why this
// was a 45 deg chamfer until the pockets made support necessary anyway.
// The cost, measured: the bed footing narrows from 5.90 to 3.90 mm, and the
// supported area goes from the 56 mm^2 of pocket ceiling to roughly 300.
// Set sb_rb = 0 and the bottom goes square; there is no chamfer option left,
// because a chamfer and a fillet cannot both be the bottom edge.
sb_rb    = 2.50;             // bottom edge rounding radius
sb_flare = 14;               // 3-prong stack 15.9 -> sb_t
sb_neck  = 10;               // sb_t -> 2-prong stack 8.9 (nil when sb_t == 8.9)
sb_blend = 10;               // sharp knuckle section -> chamfered/rounded section
sb_stn   = 20;               // loft stations per transition

// Station half-width along the arm.  Additive ramps, same shape as arm.scad.
function sb_hw(x, L) =
      w3_half
    + (sb_t/2 - w3_half) * sstep(pocket_r, pocket_r + sb_flare, x)
    + (w2_half - sb_t/2) * sstep(L - pocket_r - sb_neck, L - pocket_r, x);

// 0 at both knuckles -> the section is a plain rectangle matching the
// knuckle prism exactly.  1 through the middle -> chamfered and rounded.
function sb_s(x, L) =
      sstep(pocket_r, pocket_r + sb_blend, x)
    * (1 - sstep(L - pocket_r - sb_blend, L - pocket_r, x));

function sb_tA()   = pocket_r + max(sb_flare, sb_blend);
function sb_tB(L)  = L - pocket_r - max(sb_neck, sb_blend);

function sb_station_xs(L) =
    let (tA = sb_tA(), tB = sb_tB(L))
    concat(
        [0],
        [for (i = [0:sb_stn]) pocket_r + i/sb_stn * (tA - pocket_r)],
        [for (i = [0:sb_stn]) tB       + i/sb_stn * ((L - pocket_r) - tB)],
        [L]
    );

// One 0.01 mm station slab at x.  rotate([90,0,90]) maps the 2D (y, z)
// profile onto the model's YZ plane and extrudes along +X, as in arm.scad.
module sb_slab(x, L) {
    hw = sb_hw(x, L);
    s  = sb_s(x, L);
    translate([x, 0, 0]) rotate([90, 0, 90])
        linear_extrude(height = 0.01)
            rect([2*hw, sb_h],
                 rounding = [sb_rt*s, sb_rt*s, sb_rb*s, sb_rb*s],
                 anchor   = FRONT);
}

module sb_loft(L) {
    xs = sb_station_xs(L);
    for (i = [0 : len(xs) - 2])
        hull() { sb_slab(xs[i], L); sb_slab(xs[i+1], L); }
}

// ------------------------------------------------------------- the boss
// Local thickening of BOTH outer prongs, one per pocket.  Same silhouette
// as the knuckle, so each stands on the bed like everything else and dies
// out at R7.5 instead of leaving a step in the joint envelope.
// One boss, `h` thick, standing off the stack face on `side`.
module side_boss(side, h) {
    if (h > 0)
        tab_solid(side < 0 ? -(w3_half + h) : w3_half,
                  side < 0 ? -w3_half       : w3_half + h);
}

// The two are different thicknesses: each is only as deep as its own pocket.
module sboss() {
    side_boss( nut_side, boss_nut);
    side_boss(-nut_side, boss_hd);
}

// Pocket outline: hex with flats TOP AND BOTTOM.  That orientation is still
// right even with support under the roof -- a vertex up would leave the nut
// resting on two points instead of a flat.
//   pkt_peak = true   adds the 45 deg roof peak, and the pocket bridges itself
//   pkt_peak = false  flat roof: a pkt_r wide ceiling that needs support
module spkt_profile2d() {
    union() {
        circle(r = pkt_r, $fn = 6);        // first vertex on +X -> flat on top
        if (pkt_peak)
            polygon([[-pkt_r/2, pkt_af/2], [pkt_r/2, pkt_af/2],
                     [0, pkt_af/2 + pkt_r/2]]);
    }
}

// The press-fit nut pocket, opening on the `side` face.
module spkt_nut(side) {
    mirror([0, side < 0 ? 0 : 1, 0])
        translate([0, -(sw3_nut - pkt_depth), pivot_z])
            rotate([90, 0, 0])
                linear_extrude(height = pkt_depth + 0.5) spkt_profile2d();
}

// The pivot bore.  Round here, teardrop in arm.scad -- that file's bore() is
// shared with the pipe clamp, which is still printed WITHOUT support, so the
// teardrop has to stay there.
module sbore(px, span) {
    if (bore_round)
        translate([px, 0, pivot_z]) cyl(d = bore_d, h = span, orient = BACK);
    else
        bore(px, span);
}

// The barrel-head counterbore, opening on the `side` face.  A plain round
// bore: a screw head needs a seat, not anti-rotation, and its roof is a
// ceiling either way -- which is fine, the pockets are printed supported.
module spkt_head(side) {
    translate([0, side*(sw3_hd - hd_depth), pivot_z])
        rotate([side > 0 ? -90 : 90, 0, 0])
            cylinder(d = hd_d, h = hd_depth + 0.5, $fn = 96);
}

// ---------------------------------------------------------------- the arm
// L = pivot-to-pivot distance, same convention as arm(L).
module arm_simple(L) {
    assert(sb_tA() <= sb_tB(L),
           "arm_simple(L): L too short -- the end transitions overlap");
    difference() {
        union() {
            tab_solid(-w3_half, w3_half);                      // 3-prong knuckle
            sboss();
            translate([L, 0, 0]) tab_solid(-w2_half, w2_half);  // 2-prong knuckle
            sb_loft(L);
        }
        sbore(0, 6*sw3_max);
        sbore(L, 6*sw3_max);
        pocket(0,  u);        // 3-prong: slots centred on +/- 3.00
        pocket(0, -u);
        pocket(L,  0);        // 2-prong: central gap, same width as a slot
        spkt_nut( nut_side);
        spkt_head(-nut_side);
    }
}

// ---------------------------------------------------------------- gauge
// Fit coupon for this variant: both ends, no beam, both pockets.  ~12 min.
// Print it before a plate of arms -- it checks the 0.10 mm joint clearances
// AND whether your nut and your cap head actually drop into the pockets.
module gauge_simple() {
    Lg = 2*tab_r + 6;
    difference() {
        union() {
            tab_solid(-w3_half, w3_half);
            sboss();
            translate([Lg, 0, 0]) tab_solid(-w2_half, w2_half);
            // The taper has to finish BEFORE the 2-prong knuckle, otherwise
            // the coupon presents fat fingers and measures the wrong thing.
            hull() {
                translate([0, 0, sb_h/2])
                    cube([0.01, 2*w3_half, sb_h], center = true);
                translate([Lg - tab_r, 0, sb_h/2])
                    cube([0.01, 2*w2_half, sb_h], center = true);
            }
            translate([Lg - tab_r, -w2_half, 0]) cube([tab_r, 2*w2_half, sb_h]);
        }
        sbore(0,  6*sw3_max);
        sbore(Lg, 6*sw3_max);
        pocket(0,  u);
        pocket(0, -u);
        pocket(Lg, 0);
        spkt_nut( nut_side);
        spkt_head(-nut_side);
    }
}

// ---------------------------------------------------------------- preview
// Render a simple arm when this file is opened on its own.  Guarded on a
// sentinel of its own because this file already sets `lib` for arm.scad;
// main.scad and fitcheck.scad set `lib_s` instead of `lib`.
if (is_undef(lib_s)) arm_simple(100);
