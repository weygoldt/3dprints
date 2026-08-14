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
//     (sb_h == s_tab_top), instead of a 20 mm chord lofted up from it.
//     Three things fall out of that one decision:
//       * no chord ramp at all -- the top face is one flat plane from
//         knuckle to knuckle, so the loft only has to flare the WIDTH;
//       * 15 % less material on a 100 mm arm, even after paying for a
//         second boss AND for the raised pivot (measured off the mesh:
//         16016 -> 13537 mm^3; it was 12813 before the pivot went up);
//       * 13.5 mm tall instead of 20.0, so ~32 % fewer layers and a shorter
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
//     The raised pivot did not cost a band either, though it did shave the
//     far end of one: the body sits 0.7 mm deeper UNDER the pivot, which is
//     the direction that costs swing, and arm-to-arm on the bed side now
//     touches at about -112 instead of -120.  The crown side never noticed,
//     because pivot-to-top-face is tab_r at any pivot height.
//
//  2. SCREW POCKETS.  One in each outer prong, and they are NOT the same
//     pocket, because one shape cannot do both jobs.  The nut side is a
//     press-fit hex; the far side is a plain round counterbore that takes the
//     barrel head flush.  Both parts bear on their pocket FLOOR, the inboard
//     end, so screw tension pulls each onto solid material.  The head side is
//     also COUNTERSUNK where the bore breaks into it, so the screw's under-head
//     fillet has somewhere to go and the head seats on its annulus rather than
//     on the bore's edge.
//
//  3. THE PIVOT, raised 5.303 -> 6.000 for this variant alone, which is what
//     thickens both pocket floors (1.303/0.903 -> 2.000/1.600).  It is bought
//     with part height and with flank angle, and arm.scad is threaded rather
//     than changed, so the streamlined arm and the clamp stay exactly as they
//     were.  The whole argument is in the block above s_pivot_z.
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
//  SUPPORT.  This is the one part of the project that needs it, in FOUR
//  places, and all four are deliberate:
//    * the SCREW POCKETS.  pkt_peak = false leaves the hex a flat ceiling
//      pkt_r wide, and the head counterbore is a round bore whose roof is a
//      ceiling however you cut it.  ~56 mm^2.  DIG IT OUT BEFORE THE NUT AND
//      THE SCREW GO IN.
//    * the BODY'S BOTTOM EDGES.  A fillet is tangent to the bed face, so it
//      leaves through 90 deg of overhang -- which is exactly why this edge
//      was a 45 deg chamfer until the pockets forced support anyway.  ~263
//      mm^2 on a 100 mm arm, running the whole length of the underside, and
//      the footing narrows from 8.90 to 3.90 mm.  Brim it.
//    * the PIVOT BORES.  Round instead of teardropped, so their top ~87 deg
//      of arc is a ceiling: ~49 mm^2, and it is support INSIDE a 5.30 hole,
//      the fiddliest on the part.  A 5 mm drill clears it if it comes out
//      ragged; the screw seats on the bottom of the bore, so the top is
//      clearance either way.
//    * the KNUCKLE FLANKS, since the pivot went up: the cut circle leaves the
//      bed at 53.13 deg instead of 45, ~26 mm^2, and unlike the other three
//      it does not grow with length -- it is the same on a 50 as on a 140.
//      See the raised-pivot block below for why it cannot be bought back.
//  Everything else is still supportless by construction: the top rounding is
//  upward-facing, and the countersink is a 45 deg cone, which sits ON the
//  budget rather than over it.
//
//  sb_rb = 0, pkt_peak = true, bore_round = false and s_pivot_z = tab_r/sqrt(2)
//  give the supportless part back -- square bottom, a nut seating on a peak, a
//  pointed bore, 45 deg flanks.  The floor asserts have to come down with the
//  pivot, and that is the point of them: they will not let it go quietly.
//
//  The bosses stay sharp on purpose: the knuckle silhouette already leans past
//  45 deg where it meets the bed, so a chamfer around the boss rim would tip
//  that underside further still.  A rim chamfer is only free on geometry that
//  meets the bed vertically.
// =====================================================================

lib = true;          // suppress arm.scad's standalone preview
include <arm.scad>

// --------------------------------------------------------- the raised pivot
// This variant sits its pivot HIGHER than arm.scad's, and everything below
// follows from that one number, so it goes first.
//
// A pocket centred on the pivot is always thinner underneath than over it:
// the floor is pivot_z - pocket_half, the crown is tab_r - pocket_half.  Only
// the floor moves with the pivot.  At arm.scad's trimmed pivot of 5.303 the
// floors were 1.303 (nut) and 0.903 (head) against 3.500 and 3.100 of crown;
// at 6.00 they are 2.000 and 1.600, and the crowns do not move at all.  It is
// a pure floor gain, bought at 1 mm of part height per 1 mm of pivot -- the
// arm is 13.50 tall now instead of 12.803.
//
// WHAT IT COSTS, because it is not free and the number is not small:
// under "trim" the knuckle flank leaves the bed at asin(pivot_z/tab_r) from
// vertical.  That is 45.0 deg at 5.303 and 53.1 deg at 6.00, and each
// knuckle's bed chord narrows from 10.61 to 9.00 mm.  Nothing can buy that
// back.  Padding the flank out to 45 deg needs material at (+/-6.00, 0),
// which is R8.49 from the pivot -- half a millimetre outside the R7.5 joint
// envelope that a real GoPro's R7.75 slot pocket sweeps.  The cut circle
// already IS every point inside R7.5 that reaches the bed, so the trim is
// optimal and 53.1 deg is forced.  This part is printed with support, so the
// flank is supported like everything else; the streamlined arm and the clamp
// are NOT, which is exactly why they keep the low pivot.
//
// 7.50 is the wall, not a target: there the circle is tangent to the bed,
// the chord is 0.00 and the flank is 90 deg -- the knife edge this whole
// project was built to replace.
s_pivot_z = 6.00;
s_tab_top = s_pivot_z + tab_r;          // 13.500  knuckle Z extent
assert(tab_style == "trim",
       str("the simple arm's raised pivot assumes the TRIMMED knuckle; the ",
           "pad style puts its own pivot at tab_r and its pad outside R7.5"));
assert(s_pivot_z >= pivot_z,
       "raising the pivot is the only reason this parameter exists");
assert(s_pivot_z <= tab_r - 1.00,
       str("pivot ", s_pivot_z, " is too close to tab_r: the knuckle stands ",
           "on a knife edge instead of a chord"));

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

// A 45 deg COUNTERSINK where the pivot bore breaks into the head counterbore.
// A socket cap screw is not a plain cylinder on a plain disc: ISO 4762 puts a
// fillet under the head, and allows it out to da = 5.70 across -- 0.40 wider
// than this 5.30 bore.  Without relief that fillet lands on the sharp inside
// corner of the counterbore, and the head bears on a 5.30 mm CIRCLE instead of
// on its own flat annulus: it stands a hair proud, it rocks, and every bit of
// the screw tension is carried on that edge.  FDM makes it worse -- an inside
// corner between a horizontal hole and its counterbore floor is exactly where
// a perimeter bulges inward.
//
// 0.50 mm at 45 deg opens the mouth to 6.30, clearing da by 0.30 all round,
// and leaves 1.00 mm of the 1.50 mm floor wall.  That costs no bearing area
// worth counting: the head seats from 4.25 out, and the annulus this eats is
// r 2.65..3.15, which is where the fillet was going to sit anyway.
//
// HEAD SIDE ONLY, on purpose.  A nut's bearing face is flat to its thread --
// there is no fillet to clear -- so the same cut on the nut side would be
// 0.50 mm off the wall behind the pocket that carries the press fit, bought
// for nothing.
head_cs    = 0.50;
head_da    = 5.70;   // ISO 4762 M5: widest the under-head fillet may be

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
pkt_top   = s_pivot_z + pkt_af/2 + (pkt_peak ? pkt_r/2 : 0);
assert(max(pkt_top, s_pivot_z + hd_d/2) <= s_tab_top - 0.45,
       str("a pocket roof breaks out of the knuckle crown (nut ", pkt_top,
           ", head ", s_pivot_z + hd_d/2, " vs s_tab_top ", s_tab_top, ")"));
// A pocket centred on the pivot is ALWAYS thinner underneath than over it:
// the floor is s_pivot_z - half, the crown is tab_r - half, and only the floor
// moves with the pivot.  At 6.00 the floors are 2.000 (nut) and 1.600 (head)
// against 3.500 and 3.100 of crown -- still lopsided, but no longer by 4x.
// Two things about that are worth not re-deriving:
//
//   * the hex's FLATS-UP orientation, picked so the roof could bridge, is also
//     the one that maximises this floor.  Do NOT rotate it 30 deg to put a
//     vertex down -- that would drop the nut pocket's floor to 1.381.
//   * the pivot is the ONLY lever.  Sinking the pockets deeper is a cut in Y
//     and does nothing for a floor measured in Z, and the pockets cannot be
//     lifted off the pivot they are counterbores for -- the screw runs through
//     the middle of both.
//
// The load lands on the HEX pocket (press-fit hoop stress, nut torque); the
// thin one only holds a screw head bearing axially on its floor.  Print with 7
// bottom solid layers so both floors come out as solid skin.
assert(min(s_pivot_z - pkt_af/2, s_pivot_z - hd_d/2) >= 1.50,
       "a pocket floor leaves less than 1.50 mm of material to the bed");
// The loaded one is worth its own floor, held against what the pivot was
// RAISED to buy.  0.80 was what the low pivot could manage; passing at 0.80
// again would mean the height was paid for and then given back.
assert(s_pivot_z - pkt_af/2 >= 1.90,
       str("the press-fit pocket's floor is under 1.90 -- the raised pivot ",
           "has been spent on something else"));
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
// ... and the countersink has to clear the fillet it exists for, at the one
// plane where it matters: the counterbore floor, which is where the widest
// part of the fillet sits.
assert(bore_d + 2*head_cs >= head_da + 0.20,
       str("the countersink opens the bore mouth to ", bore_d + 2*head_cs,
           ", which does not clear a ", head_da, " under-head fillet"));
// It also has to stop short of the slot behind the pocket floor -- it is cut
// INTO the wall the head bears on.
assert(nut_wall - head_cs >= 1.00,
       str("the countersink leaves only ", nut_wall - head_cs,
           " mm of floor wall behind the head (want >= 1.00)"));

// -------------------------------------------------------------- the body
// A constant slab, exactly as tall as the knuckle, so there is no chord
// ramp to build and the top face is one plane end to end.
sb_h     = s_tab_top;        // 13.500  body height == knuckle height
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
                  side < 0 ? -w3_half       : w3_half + h,
                  s_pivot_z);
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
        translate([0, -(sw3_nut - pkt_depth), s_pivot_z])
            rotate([90, 0, 0])
                linear_extrude(height = pkt_depth + 0.5) spkt_profile2d();
}

// The pivot bore.  Round here, teardrop in arm.scad -- that file's bore() is
// shared with the pipe clamp, which is still printed WITHOUT support, so the
// teardrop has to stay there.
module sbore(px, span) {
    if (bore_round)
        translate([px, 0, s_pivot_z]) cyl(d = bore_d, h = span, orient = BACK);
    else
        bore(px, span, s_pivot_z);
}

// The barrel-head counterbore, opening on the `side` face.  A plain round
// bore: a screw head needs a seat, not anti-rotation, and its roof is a
// ceiling either way -- which is fine, the pockets are printed supported.
//
// Plus the countersink, cut the other way out of the same plane: 45 deg,
// head_cs deep, so the head's under-head fillet has somewhere to go and the
// head seats on its flat annulus instead of on the bore's edge.  It belongs
// to THIS pocket, not to sbore() -- the far side gets a nut, which has no
// fillet to clear.
module spkt_head(side) {
    translate([0, side*(sw3_hd - hd_depth), s_pivot_z]) {
        rotate([side > 0 ? -90 : 90, 0, 0])          // outboard: the counterbore
            cylinder(d = hd_d, h = hd_depth + 0.5, $fn = 96);
        rotate([side > 0 ? 90 : -90, 0, 0])          // inboard: the relief
            cylinder(d1 = bore_d + 2*head_cs, d2 = bore_d, h = head_cs,
                     $fn = 96);
    }
}

// ---------------------------------------------------------------- the arm
// L = pivot-to-pivot distance, same convention as arm(L).
module arm_simple(L) {
    assert(sb_tA() <= sb_tB(L),
           "arm_simple(L): L too short -- the end transitions overlap");
    difference() {
        union() {
            tab_solid(-w3_half, w3_half, s_pivot_z);           // 3-prong knuckle
            sboss();
            translate([L, 0, 0])
                tab_solid(-w2_half, w2_half, s_pivot_z);       // 2-prong knuckle
            sb_loft(L);
        }
        sbore(0, 6*sw3_max);
        sbore(L, 6*sw3_max);
        pocket(0,  u, s_pivot_z);   // 3-prong: slots centred on +/- 3.00
        pocket(0, -u, s_pivot_z);
        pocket(L,  0, s_pivot_z);   // 2-prong: central gap, same width as a slot
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
            tab_solid(-w3_half, w3_half, s_pivot_z);
            sboss();
            translate([Lg, 0, 0]) tab_solid(-w2_half, w2_half, s_pivot_z);
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
        pocket(0,  u, s_pivot_z);
        pocket(0, -u, s_pivot_z);
        pocket(Lg, 0, s_pivot_z);
        spkt_nut( nut_side);
        spkt_head(-nut_side);
    }
}

// ---------------------------------------------------------------- preview
// Render a simple arm when this file is opened on its own.  Guarded on a
// sentinel of its own because this file already sets `lib` for arm.scad;
// main.scad and fitcheck.scad set `lib_s` instead of `lib`.
if (is_undef(lib_s)) arm_simple(100);
