// =====================================================================
//  GoPro extension arms  --  SIMPLE variant.
//
//  A sibling to arm.scad, not a replacement.  arm.scad is purposefully
//  STREAMLINED: it hangs under a boat with water flowing past it, so it
//  pays for a Kamm-tail strut section with material, print time and hinge
//  travel.  This one buys all three back for a general-purpose arm.
//
//  It shares every millimetre of the GoPro interface with arm.scad -- same
//  3 mm grid, same 0.10 mm clearances, same trimmed knuckle, same teardrop
//  bore, same prong free length.  Only the BODY and the SCREW POCKETS differ.
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
//         second boss (measured off the mesh: 16016 -> 12754 mm^3);
//       * 12.8 mm tall instead of 20.0, so ~36 % fewer layers and a shorter
//         perimeter loop in each one -- which is where print time on a
//         nearly-solid part actually goes.
//     Deliberately NOT an ellipse: the edges are a 45 deg bottom chamfer
//     and a rounded top, i.e. smoothed rather than faired.  Streamlining is
//     what arm.scad is for.
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
//  2. SCREW POCKETS.  A PRESS-FIT nut pocket in BOTH outer prongs instead of
//     one, so the nut can go on whichever side you can reach and a plain
//     machine screw can replace the knurled GoPro thumbscrew.  The nut bears
//     on the pocket FLOOR, which is the inboard end, so screw tension pulls
//     it onto solid material rather than trying to lift it out.
//
//  ------------------------------------------------------------------
//  WHY THE POCKET IS SIZED TO THE NUT AND NOT THE HEAD
//
//  It was 8.80 across flats, sized to swallow an 8.50 barrel head flush.  In
//  the hand that is the wrong trade: the nut then has 0.80 mm of play and
//  rattles, and the streamlined arm already rattles at 0.20.
//
//  The two cannot be reconciled, which is worth writing down so nobody tries
//  again.  A barrel head needs 4.25 mm of clearance in EVERY radial
//  direction.  A nut that will not rattle needs the flats at 4.00.  No
//  single outline satisfies both, and stepping the pocket -- head counterbore
//  at the mouth, hex deeper -- does not rescue it either: the nut has to pass
//  through the counterbore to reach the hex, so the counterbore has to clear
//  the nut's 9.24 across-corners, and the depths add instead of overlapping.
//  That lands the stack past 30 mm for a 5 mm saving in screw head height.
//
//  So: pocket 8.00 across flats, a press fit on the nut, and the head sits
//  ON the face like a thumbscrew does.  Dropping the head depth as well
//  takes the pocket from 5.30 to 4.30 and the stack from 22.70 to 20.70.
//
//  ------------------------------------------------------------------
//  WHAT FITS IT
//    M5x20 socket cap  + M5 nut     the pairing this is built around.  Head
//                                   stands on the face, driven with a 4 mm
//                                   key -- far more torque than a thumbscrew,
//                                   which is the point.  The tip lands 0.7 mm
//                                   inside the far face, so nothing protrudes.
//    GoPro thumbscrew  + M5 nut     as arm.scad, now with a choice of side
//  A hex-head bolt press-fits the pocket too, but then BOTH ends are captive
//  and nothing can be turned -- use it only against a free nut outside.
//
//  ------------------------------------------------------------------
//  SUPPORT.  This is the one part of the project that wants it, and only in
//  one place: with pkt_peak = false the pocket roof is a flat ceiling
//  pkt_r wide, and the slicer will fill both pockets.  DIG THAT OUT BEFORE
//  THE NUT GOES IN.  Everything else is still supportless by construction --
//  the body's bottom edge is CHAMFERED at 45 deg rather than rounded (a
//  rounded bottom edge turns down through vertical and overhangs), the top
//  rounding is upward-facing, and the bore keeps its 45 deg teardrop.
//  Setting pkt_peak = true puts the self-bridging peak back and the whole
//  part returns to needing no support at all.
//
//  The bosses are the one place that stays sharp on purpose: the knuckle
//  silhouette already leans 45 deg where it meets the bed, so a chamfer
//  around the boss rim would tip that underside past the budget.  Rim
//  chamfer is only free on geometry that meets the bed vertically.
// =====================================================================

lib = true;          // suppress arm.scad's standalone preview
include <arm.scad>

// ------------------------------------------------------- screw / pockets
// THE ONE TRADE IN THIS PART, and it is forced by arithmetic, not taste.
//
// An M5 nut is 8.00 across flats.  An M5 barrel head (DIN 912 socket cap) is
// 8.50 ACROSS -- wider than the nut is.  A single pocket cannot do both jobs:
// the head needs 4.25 mm of clearance in EVERY radial direction, and a nut
// that is not going to rattle needs the flats at 4.00.  There is no shape
// that satisfies both.
//
//   pkt_af = 8.00   PRESS FIT on the nut.  The barrel head no longer recesses
//                   -- it sits on the face, the way a thumbscrew does.
//   pkt_af = 8.80   the barrel head sits flush, but the nut has 0.80 mm of
//                   play and rattles.  (The streamlined arm rattles at 0.20.)
//
// Sized for the nut, because a mount that shakes loose is worse than a screw
// head standing proud.  Flip the one number to swap the trade back.
pkt_af    = 8.00;
// Modelled at NOMINAL on purpose.  FDM lays pockets down a touch undersize,
// and that is where the interference comes from -- asking for it in the model
// as well would stack two tolerances the same way.  Tune it on `sgauge`
// before committing a plate: raise it if the nut will not start square,
// lower it if it drops in under its own weight.

// A flat roof instead of the 45 deg peak.  The peak existed so the pocket
// could bridge itself; printed with support it is just wasted depth, and the
// flat roof is what a nut actually wants to seat against.
pkt_peak  = false;

// The head, kept as a parameter so the geometry can answer for itself
// whether it recesses rather than leaving it to a comment.
head_d     = 8.50;   // DIN 912 socket cap, M5: across
head_h     = 5.00;   // ... and tall
head_clr   = 0.30;
head_seat  = 0.30;

pkt_r     = pkt_af/sqrt(3);                        // 4.619 circumradius
pkt_seats_head = pkt_af >= head_d + head_clr;      // false at 8.00
// No point carrying head depth in a pocket the head cannot enter.
pkt_depth = pkt_seats_head ? max(nut_t + nut_seat, head_h + head_seat)
                           : nut_t + nut_seat;     // 4.30
sboss_h   = max(0, pkt_depth + nut_wall - prong_out_t);       // 2.40 per side

sw3_half  = w3_half + sboss_h;                                // 10.35 -> 20.7 stack

// Roof and floor both have to stay inside the knuckle.
pkt_top   = pivot_z + pkt_af/2 + (pkt_peak ? pkt_r/2 : 0);
assert(pkt_top <= tab_top - 0.45,
       str("pocket roof breaks out of the knuckle crown (top ", pkt_top,
           " vs tab_top ", tab_top, ") -- the pocket is too big for an R",
           tab_r, " knuckle"));
assert(pivot_z - pkt_af/2 >= 0.80,
       "pocket bottom flat leaves less than 0.80 mm of material to the bed");
// Whatever it is sized for, it must still stop the nut turning: the nut's
// corners have to stand outside the pocket's flats.
assert(pkt_af/2 < nut_af/sqrt(3) - 0.05,
       "pocket is so wide the M5 nut spins freely in it -- it is not a nut trap");
// ... and not be so tight that no nut will ever enter it.
assert(pkt_af >= nut_af - 0.25,
       "pocket is more than 0.25 under the nut: an interference nothing seats");

// -------------------------------------------------------------- the body
// A constant slab, exactly as tall as the knuckle, so there is no chord
// ramp to build and the top face is one plane end to end.
sb_h     = tab_top;          // 12.803  body height == knuckle height
sb_t     = 2*w2_half;        //  8.900  body width == the 2-prong stack, so
                             //         the beam runs straight into that end
sb_cham  = 1.50;             // 45 deg bottom chamfer (printable; a fillet is not)
sb_rt    = 2.50;             // top edge rounding radius
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
                 rounding = [sb_rt*s, sb_rt*s, 0, 0],
                 chamfer  = [0, 0, sb_cham*s, sb_cham*s],
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
module sboss() {
    if (sboss_h > 0) {
        tab_solid(-sw3_half, -w3_half);
        tab_solid( w3_half,   sw3_half);
    }
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

// The pocket itself, opening on one outboard face.  side = -1 or +1.
module spkt(side) {
    mirror([0, side < 0 ? 0 : 1, 0])
        translate([0, -(sw3_half - pkt_depth), pivot_z])
            rotate([90, 0, 0])
                linear_extrude(height = pkt_depth + 0.5) spkt_profile2d();
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
        bore(0, 6*sw3_half);
        bore(L, 6*sw3_half);
        pocket(0,  u);        // 3-prong: slots centred on +/- 3.00
        pocket(0, -u);
        pocket(L,  0);        // 2-prong: central gap, same width as a slot
        spkt(-1);
        spkt(+1);
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
        bore(0,  6*sw3_half);
        bore(Lg, 6*sw3_half);
        pocket(0,  u);
        pocket(0, -u);
        pocket(Lg, 0);
        spkt(-1);
        spkt(+1);
    }
}

// ---------------------------------------------------------------- preview
// Render a simple arm when this file is opened on its own.  Guarded on a
// sentinel of its own because this file already sets `lib` for arm.scad;
// main.scad and fitcheck.scad set `lib_s` instead of `lib`.
if (is_undef(lib_s)) arm_simple(100);
