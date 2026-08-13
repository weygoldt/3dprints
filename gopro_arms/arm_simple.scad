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
//  2. SCREW POCKETS.  A pocket in BOTH outer prongs instead of one, so the
//     nut can go on either side and a plain machine screw can replace the
//     knurled GoPro thumbscrew.  Each pocket does double duty:
//       * it traps an M5 DIN 934 nut against rotation, and
//       * it swallows an M5 DIN 912 socket cap head, giving a flush mount.
//     Both parts bear on the pocket FLOOR, which is the inboard end, so the
//     screw tension pulls each of them onto solid material.
//
//  ------------------------------------------------------------------
//  ONE POCKET, TWO JOBS -- the geometry that decides the screw
//
//  An M5 nut is 8.00 across flats.  An M5 socket cap head is 8.50 ACROSS,
//  which is bigger.  So a pocket that swallows the head cannot also be a
//  zero-slop nut trap; the pocket is sized to the head and the nut gets
//  some rotational play in it.  How much is worth writing down:
//
//      pocket across flats  8.80   -> flat at r 4.400, corner at r 5.081
//      M5 nut               8.00   -> flat at r 4.000, corner at r 4.619
//
//  The nut's CORNERS (4.619) stand outside the pocket's flats (4.400), so
//  the nut wedges after about +/-12 deg.  That is all a nut trap has to do:
//  hold it still while the screw is driven.  The nut also floats ~0.4 mm
//  laterally, which is a feature -- the screw pulls it into line instead of
//  fighting a pocket that is too tight to move.
//
//  A BUTTON head (ISO 7380, 9.50 across) does NOT fit, and not by a little:
//  its pocket would need 9.80 across flats, whose 45 deg roof peak lands at
//  z=13.03 against a knuckle crown of 12.80 -- the pocket would break out of
//  the top of the knuckle.  The assert below enforces that.  Socket cap.
//
//  ------------------------------------------------------------------
//  WHAT FITS IT
//    M5x16 socket cap  + M5 nut     nothing protrudes at either face
//    M5x18 socket cap  + M5 nut     0.6 mm of thread proud of the far face
//    M5 hex-head bolt  + free nut   the bolt head is 8.0 AF, so the pocket
//                                   traps it too -- drive it from the nut end
//    GoPro thumbscrew  + M5 nut     as arm.scad, just with a choice of side
//
//  ------------------------------------------------------------------
//  STILL SUPPORTLESS.  Support material costs exactly the two things this
//  variant exists to save, so nothing here spends the supportless budget:
//  the pocket keeps its hex flats top-and-bottom under a 45 deg peak, the
//  body's bottom edge is CHAMFERED at 45 deg rather than rounded (a rounded
//  bottom edge turns down through vertical and overhangs), and the top
//  rounding is an upward-facing surface.
//
//  The bosses are the one place that stays sharp on purpose: the knuckle
//  silhouette already leans 45 deg where it meets the bed, so a chamfer
//  around the boss rim would tip that underside past the budget.  Rim
//  chamfer is only free on geometry that meets the bed vertically.
// =====================================================================

lib = true;          // suppress arm.scad's standalone preview
include <arm.scad>

// ------------------------------------------------------- screw / pockets
// The head the pocket is sized to swallow.  DIN 912 socket cap, M5.
head_d     = 8.50;   // head diameter across
head_h     = 5.00;   // head height
head_clr   = 0.30;   // diametral clearance on the head
head_seat  = 0.30;   // so the head sits just below flush, like the nut

// Pocket across flats: whichever of the nut and the head needs more room.
// nut_af/nut_af_clr/nut_t/nut_seat/nut_wall all come from arm.scad.
pkt_af    = max(nut_af + nut_af_clr, head_d + head_clr);      // 8.80
pkt_r     = pkt_af/sqrt(3);                                   // 5.081 circumradius
pkt_depth = max(nut_t + nut_seat, head_h + head_seat);        // 5.30
sboss_h   = max(0, pkt_depth + nut_wall - prong_out_t);       // 3.40 per side

sw3_half  = w3_half + sboss_h;                                // 11.35 -> 22.7 stack

// The 45 deg roof peak over the pocket's top flat has to stay under the
// crown of the knuckle, and the pocket floor has to stay off the bed.
pkt_apex  = pivot_z + pkt_af/2 + pkt_r/2;
assert(pkt_apex <= tab_top - 0.45,
       str("pocket roof peak breaks out of the knuckle crown (apex ", pkt_apex,
           " vs tab_top ", tab_top, ") -- the head is too big for an R", tab_r,
           " knuckle; a socket cap head fits, a button head does not"));
assert(pivot_z - pkt_af/2 >= 0.80,
       "pocket bottom flat leaves less than 0.80 mm of material to the bed");
// A pocket wide enough for the head must still stop the nut turning: the
// nut's corners have to stand outside the pocket's flats.
assert(pkt_af/2 < nut_af/sqrt(3) - 0.05,
       "pocket is so wide the M5 nut spins freely in it -- it is not a nut trap");

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

// Pocket outline: hex with flats TOP AND BOTTOM (a vertex up would put the
// roof at 60 deg from vertical), plus a 45 deg peak over the top flat so
// nothing droops into it while it bridges.
module spkt_profile2d() {
    union() {
        circle(r = pkt_r, $fn = 6);        // first vertex on +X -> flat on top
        polygon([[-pkt_r/2, pkt_af/2], [pkt_r/2, pkt_af/2], [0, pkt_af/2 + pkt_r/2]]);
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
