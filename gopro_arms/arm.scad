// =====================================================================
//  GoPro extension arms  --  tight-fit prongs + streamlined strut
//  PETG, 0.4 nozzle / 0.2 mm layers, Prusa MK3S, SUPPORTLESS.
//
//  Replaces the loose `inspiration/*.stl` arms with two changes:
//    1. FIT.  The prong stack is rebuilt on the real GoPro 3 mm grid
//       (prong 3, slot 3, five slots = 15 mm) instead of the inspiration's
//       2.5 mm prongs in 4.0 mm slots, which left ~0.6-1.2 mm of rattle and
//       never clamped.  Slots are 3.10 and fingers 2.90: 0.10 per feature.
//    2. FLOW. The square 9.3 x 14.9 beam becomes a streamlined strut
//       section: flat trailing base, gentle taper, rounded leading edge.
//    3. NUT.  A captive M5 hex nut in the 3-prong end, so the thumbscrew
//       can actually be pulled up tight one-handed.
//
//  ------------------------------------------------------------------
//  FRAME  (model axes -> boat axes, arm hanging UNDER the hull)
//    +X  arm length.  Pivot A (3-prong) at x=0, pivot B (2-prong) at x=L.
//        In use X points DOWN; the camera hangs at the far end.
//    +Y  hinge axis = ATHWARTSHIP (port-starboard).  The joint therefore
//        articulates in the vertical fore-aft plane, i.e. it tilts the
//        camera up/down -- the adjustment that actually matters here.
//    +Z  FORE-AFT, and also the BUILD direction.
//          Z = 0        flat face  -> points AFT   (this face is the bed)
//          Z = beam_c   rounded nose -> points FORWARD (into the flow)
//
//  So: print flat face down, and mount the arm with the FLAT FACE AFT.
//  The section is symmetric about the XZ plane, so port/starboard does
//  not matter -- only which way the flat face looks.
//
//  ------------------------------------------------------------------
//  WHY IT PRINTS WITHOUT SUPPORT
//  Every surface is either the flat bed face, a wall within `oh_ang` of
//  vertical, or an upward-facing slope:
//    * the knuckle circle is CUT by the bed with its pivot at R/sqrt(2),
//      the lowest the pivot can sit while the cut face still leaves the
//      bed at exactly 45 deg.  The inspiration instead sat a full circle
//      tangent on the bed -- a knife edge -- which is why the old gcode
//      needed support material.  Cutting rather than padding also keeps
//      every knuckle inside the R7.5 joint envelope, so the hinge does
//      not jam part-way through its travel (see ARTICULATION below);
//    * the strut section widens from base to max thickness at ~17 deg
//      from vertical, then closes toward the nose;
//    * the chord ramps up as an upward-facing slope;
//    * the pivot bore is a 45 deg teardrop, so nothing droops into it
//      (PETG bridges worse than PLA).
//  The only sub-45 surfaces left are the slot roofs, which bridge 3.1 mm.
//
//  ------------------------------------------------------------------
//  ARTICULATION (measured, fitcheck.py, zero-interference range)
//    into a GoPro mount     -100 .. +90 deg
//    our end into a socket   -80 .. +100 deg
//    arm to arm              -90 .. +40 deg
//  The original arms were clear at EVERY angle, because their body was a
//  15 mm slab exactly matching the knuckle diameter -- two such slabs
//  sharing a pivot can never foul.  The nose fairing is 20 mm deep and so
//  gives that up.  This is the deliberate cost of the streamlining; 0 deg
//  (collinear) has wide clearance either side, which is what the arm is
//  actually used at.
// =====================================================================

include <../BOSL2/std.scad>

$fa = 1;
$fs = 0.4;

// ---------------------------------------------------------------- joint
// Measured off the user's current GoPro mounts: 3 mm prong, 3 mm gap.
// TIGHT ON PURPOSE.  The arms these replace ran 4.00 slots on 3.00 fingers and
// could not be clamped up -- the prongs bottomed out on each other before the
// faces ever gripped.  0.10 per feature is a slip fit that still leaves the
// thumbscrew something to squeeze.  Print `gauge` first and tune from there.
u           = 3.00;   // GoPro nominal prong / slot unit
slot_extra  = 0.10;   // slot   = u + slot_extra   -> 3.10 modelled
fing_under  = 0.10;   // finger = u - fing_under   -> 2.90 modelled
tab_r       = 7.50;   // knuckle radius            (measured 7.503)
bore_d      = 5.30;   // M5 GoPro thumbscrew clearance (measured 5.296)
prong_out_t = 3.40;   // OUTER prong thickness, 3-prong end -- reinforcement
joint_clr   = 0.25;   // radial clearance of the slot pocket
root_fillet = 0.80;   // fillet where the slot floor meets the prong faces
oh_ang      = 45;     // max overhang measured from vertical

// ---------------------------------------------------------------- strut
beam_t      = 10.0;   // max section thickness  (Y, athwartship = frontal)
beam_c      = 20.0;   // section chord          (Z, fore-aft)   -> fineness 2.0
base_w      =  5.0;   // flat trailing base width at Z=0 (Kamm truncation)
sec_fmax    = 0.70;   // z/chord of max thickness  == 30% chord behind the nose
sec_tail_p  = 1.70;   // tail taper exponent
nose_flat   = 0.40;   // tiny flat at the nose tip so the top layer is printable

// ---------------------------------------------------------- nut trap
// Captive M5 nut in one outer prong of the 3-prong end, so the GoPro
// thumbscrew can be done up one-handed instead of needing a spanner.
// The prong is only prong_out_t thick, which is less than a nut, so the
// prong is locally thickened by boss_h -- the boss reuses the knuckle
// silhouette, so it stands on the bed like everything else and fades out
// to nothing at the edge of the R7.5 circle instead of leaving a step.
nut_trap    = true;
nut_af      = 8.00;   // M5 DIN 934 across flats
nut_af_clr  = 0.20;   // snug; PETG pockets come out a touch narrow
nut_t       = 4.00;   // DIN 934 thickness  (DIN 985 nyloc = 5.0)
nut_seat    = 0.30;   // so the nut sits just below flush
nut_wall    = 1.50;   // material between pocket floor and the slot
nut_side    = -1;     // which outer prong carries it (-1 = -Y)

// ------------------------------------------------------------ blending
flare_len   = 14;     // 3-prong end: width flare  15.9 -> beam_t
neck_len    = 10;     // 2-prong end: width neck   beam_t -> 8.9
chord_len   = 12;     // chord ramp tab_top -> beam_c
n_station   = 22;     // loft stations per transition

// ---------------------------------------------------------------- derived
slot_w   = u + slot_extra;                 // 3.10  -- accepts a 3.00 finger
fing_w   = u - fing_under;                 // 2.90  -- enters a 3.00 slot
w3_half  = u + slot_w/2 + prong_out_t;     // 7.95  -> 15.9 mm 3-prong stack
w2_half  = u + fing_w/2;                   // 4.45  ->  8.9 mm 2-prong stack

nut_depth = nut_t + nut_seat;                              // 4.30
boss_h    = nut_trap                                        // local thickening
              ? max(0, nut_depth + nut_wall - prong_out_t)  // 2.40
              : 0;
nut_r     = (nut_af + nut_af_clr)/sqrt(3);   // hex circumradius, 4.76

// ---- knuckle style ---------------------------------------------------
// "pad"  pivot sits one full radius up, so the knuckle circle is tangent to
//        the bed and a flat pad is hulled under it to give the flanks a 45 deg
//        start.  Deepest knuckle, but the pad necessarily pokes ~0.6 mm
//        outside the R7.5 joint envelope, which a mating body sweeps into.
// "trim" pivot sits at R/sqrt(2), so the circle is simply CUT by the bed and
//        still leaves the bed at exactly 45 deg.  Nothing lies outside R7.5,
//        so the joint keeps its articulation; the knuckle is 2.2 mm shallower.
tab_style = "trim";   // [pad, trim]

pivot_z = (tab_style == "pad") ? tab_r : tab_r/sqrt(2);   // pivot above the bed
tab_top = pivot_z + tab_r;                                // knuckle Z extent

// pad half-length that makes the flanks leave the bed at exactly `oh_ang`
tab_base_h = tab_r * (1/cos(oh_ang) - tan(oh_ang));   // 3.107 at 45 deg

// ---------------------------------------------------------------- helpers
function cl(x, a, b)       = x < a ? a : (x > b ? b : x);
function sstep(e0, e1, x)  = let (t = cl((x - e0)/(e1 - e0), 0, 1)) t*t*(3 - 2*t);

// Normalised half-width of the strut section.  f = z/chord.
//   f = 0            flat trailing base  (AFT, on the bed)
//   f = sec_fmax     max thickness
//   f = 1            rounded leading edge (FORWARD)
function strut_norm(f) =
    f <= sec_fmax
      ? 1 - (1 - base_w/beam_t) * pow((sec_fmax - f)/sec_fmax, sec_tail_p)
      : max(sqrt(max(0, 1 - pow((f - sec_fmax)/(1 - sec_fmax), 2))),
            nose_flat/beam_t);

// Station geometry along the arm.  Additive ramps: end A, then end B.
function st_hw(x, L) =
      w3_half
    + (beam_t/2 - w3_half) * sstep(tab_r, tab_r + flare_len, x)
    + (w2_half - beam_t/2) * sstep(L - tab_r - neck_len, L - tab_r, x);

function st_ch(x, L) =
      tab_top
    + (beam_c - tab_top) * sstep(tab_r, tab_r + chord_len, x)
    + (tab_top - beam_c) * sstep(L - tab_r - chord_len, L - tab_r, x);

// 0 at both knuckles (plain rectangle, matching the knuckle prism exactly)
// -> 1 through the middle (full strut section).
function st_s(x, L) =
      sstep(tab_r, tab_r + chord_len, x)
    * (1 - sstep(L - tab_r - chord_len, L - tab_r, x));

// Closed 2D station polygon, in (y, z).  Right flank up, left flank down.
function st_pts(x, L, n = 40) =
    let (hw = st_hw(x, L), ch = st_ch(x, L), s = st_s(x, L))
    concat(
        [for (i = [0:n])    let (f = i/n) [  hw*(1 + (strut_norm(f) - 1)*s), ch*f ]],
        [for (i = [n:-1:0]) let (f = i/n) [ -hw*(1 + (strut_norm(f) - 1)*s), ch*f ]]
    );

// Transition knots.  Both end-A ramps are covered by one dense band, ditto B.
function _tA(L) = tab_r + max(chord_len, flare_len);
function _tB(L) = L - tab_r - max(chord_len, neck_len);

function station_xs(L) =
    let (tA = _tA(L), tB = _tB(L))
    concat(
        [0],
        [for (i = [0:n_station]) tab_r + i/n_station * (tA - tab_r)],
        [for (i = [0:n_station]) tB   + i/n_station * ((L - tab_r) - tB)],
        [L]
    );

// ---------------------------------------------------------------- pieces

// Knuckle silhouette in the XZ plane: the pivot circle hulled onto a flat
// base bar, which turns the un-printable underside of the circle into two
// 45 deg tangent flanks standing on the bed.
module tab_profile2d() {
    if (tab_style == "pad")
        hull() {
            translate([0, pivot_z]) circle(r = tab_r);
            translate([0, 0.005]) square([2*tab_base_h, 0.01], center = true);
        }
    else
        intersection() {                      // circle cut off by the bed
            translate([0, pivot_z]) circle(r = tab_r);
            translate([0, tab_top/2]) square([4*tab_r, tab_top], center = true);
        }
}

// Knuckle solid spanning y0..y1.
module tab_solid(y0, y1) {
    translate([0, y1, 0]) rotate([90, 0, 0])
        linear_extrude(height = y1 - y0) tab_profile2d();
}

// One station slab, 0.01 mm thick, at x.  rotate([90,0,90]) maps the 2D
// (y, z) profile onto the model's YZ plane and extrudes along +X.
module station_slab(x, L) {
    translate([x, 0, 0]) rotate([90, 0, 90])
        linear_extrude(height = 0.01) polygon(st_pts(x, L));
}

module beam_loft(L) {
    xs = station_xs(L);
    for (i = [0 : len(xs) - 2])
        hull() { station_slab(xs[i], L); station_slab(xs[i+1], L); }
}

// Slot pocket: a cylinder about the pivot, so the mating knuckle can swing
// through its full circle.  Radius carries the fillet OUTSIDE the mating
// knuckle's envelope -- full slot width is held out to tab_r + joint_clr,
// and only beyond that does the fillet close in.
module pocket(px, yc) {
    translate([px, yc, pivot_z])
        cyl(r = tab_r + joint_clr + root_fillet, h = slot_w,
            rounding = root_fillet, orient = BACK);
}

// 45 deg teardrop bore: BOSL2 teardrop() lies along Y with its point up +Z.
module bore(px, span) {
    translate([px, 0, pivot_z])
        teardrop(h = span, d = bore_d, ang = oh_ang);
}

// Hex nut outline, flats TOP AND BOTTOM (a vertex up would put the roof at
// 60 deg from vertical), plus a 45 deg peak so nothing droops into the pocket
// where it bridges the top flat.
module nut_profile2d() {
    af = nut_af + nut_af_clr;
    union() {
        rotate(0) circle(r = nut_r, $fn = 6);          // vertex on +X -> flat on top
        polygon([[-nut_r/2, af/2], [nut_r/2, af/2], [0, af/2 + nut_r/2]]);
    }
}

// Local thickening of the nut-side outer prong.  Same silhouette as the
// knuckle, so it prints off the bed identically and dies out at R7.5.
module nut_boss() {
    if (nut_trap && boss_h > 0)
        tab_solid(nut_side < 0 ? -w3_half - boss_h : w3_half,
                  nut_side < 0 ? -w3_half         : w3_half + boss_h);
}

// The pocket itself, opening on the outboard face.
module nut_pocket() {
    if (nut_trap)
        mirror([0, nut_side < 0 ? 0 : 1, 0])
            translate([0, -(w3_half + boss_h - nut_depth), pivot_z])
                rotate([90, 0, 0])
                    linear_extrude(height = nut_depth + 0.5) nut_profile2d();
}

// ---------------------------------------------------------------- the arm
// L = pivot-to-pivot distance.
module arm(L) {
    assert(_tA(L) <= _tB(L),
           "arm(L): L too short -- the end transitions overlap");
    difference() {
        union() {
            tab_solid(-w3_half, w3_half);                    // 3-prong knuckle
            nut_boss();
            translate([L, 0, 0]) tab_solid(-w2_half, w2_half); // 2-prong knuckle
            beam_loft(L);
        }
        bore(0, 6*w3_half);
        bore(L, 6*w3_half);
        pocket(0,  u);        // 3-prong: slots centred on +/- 3.00
        pocket(0, -u);
        pocket(L,  0);        // 2-prong: central gap, same width as a slot
        nut_pocket();
    }
}

// ---------------------------------------------------------------- gauge
// Fit coupon: both ends, no beam.  Print this first (~10 min) and check it
// against a real GoPro mount before committing to a set of long arms.
module gauge() {
    Lg = 2*tab_r + 6;
    difference() {
        union() {
            tab_solid(-w3_half, w3_half);
            nut_boss();
            translate([Lg, 0, 0]) tab_solid(-w2_half, w2_half);
            // Taper must finish BEFORE the 2-prong knuckle, otherwise the
            // coupon presents fat fingers and measures the wrong thing.
            hull() {
                translate([0, 0, tab_top/2])
                    cube([0.01, 2*w3_half, tab_top], center = true);
                translate([Lg - tab_r, 0, tab_top/2])
                    cube([0.01, 2*w2_half, tab_top], center = true);
            }
            translate([Lg - tab_r, -w2_half, 0]) cube([tab_r, 2*w2_half, tab_top]);
        }
        bore(0,  6*w3_half);
        bore(Lg, 6*w3_half);
        pocket(0,  u);
        pocket(0, -u);
        pocket(Lg, 0);
        nut_pocket();
    }
}
