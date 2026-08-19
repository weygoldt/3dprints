// =====================================================================
//  GoPro quick-release buckle  --  our screw pockets, nothing else.
//
//  The donor is `inspiration/Quck Release v3 clip.STL`, imported as it is.
//  This file changes it in ONE way: it stops taking a GoPro hand screw and
//  starts taking the pairing arm_simple.scad is built around -- an M5 socket
//  cap (barrel) head one side, a press-fit M5 nut the other.  The body, the
//  latch, the rails and the 3-prong joint are the donor's and are not touched.
//
//  ------------------------------------------------------------------
//  THE DONOR, MEASURED (verify_buckle.py re-measures every one of these on
//  the EXPORT and fails if the donor mesh is ever swapped for another)
//
//    hinge axis        along X
//    pivot             y 15.240, z 12.700;  bore 5.461 through all three prongs
//    knuckle           R 7.3655, dead flat over the whole free arc (-80..+90
//                      about the pivot); outside that the gusset takes over
//                      and the radius climbs -- 7.3705 by -82, 7.4796 by -90,
//                      7.8387 by -100, which is a straight 10 deg draft.  The
//                      -85 this line used to claim is inside the climb, and
//                      verify_buckle.py [1] has always swept only to -80.
//    slots             x 11.506..14.681 and 17.856..21.031, both 3.175
//    middle prong      x 14.681..17.856, 3.175
//    outer prongs      NOT on the grid, and not equal to each other.  The
//                      high-x one is x 21.031..23.635, only 2.604 -- 0.571
//                      under a unit.  The low-x one runs the other way: past
//                      its 11.506 slot wall it never presents a plane at all,
//                      but blends into the boss and the body.  Only the slots
//                      and the middle prong are on the 1/8" grid; do not
//                      predict either outer face from it.
//    printed           on the y = 0 plane, which is 718 mm^2 of flat face --
//                      nearly four times the next largest.  +Y is UP.
//
//  Two things about that list are worth stopping on.
//
//  FIRST, the grid is IMPERIAL.  Both slots and the middle prong measure
//  3.175 == 1/8".  Our arms are built on a 3.00 mm grid
//  with a 3.10 slot, so this buckle's 3.175 middle prong is 0.075 WIDER than
//  the 3.10 central gap on our 2-prong end.  That is a real interference, not
//  mesh noise -- it reads 3.175 at every radius and every angle probed.  It is
//  the donor's tolerance, not ours, and nothing here loosens our arm to suit
//  it.  Ease the buckle's middle prong, or squeeze it: 0.075 total across a
//  PETG finger is a firm push, not a jam.
//
//  SECOND, THE DONOR ALREADY HAS THE NUT TRAP.  The low-x prong carries a
//  boss standing out to x 5.0164, with a hexagon cut into it 3.887 deep,
//  floor at x 8.903.  That hexagon measures 8.0010 across flats -- the same
//  nominal 8.00 as pkt_af, arrived at independently -- and it is FLATS UP in
//  the print orientation, the same choice arm_simple argues for.  So the nut
//  pocket is not something this file invents; it is something the donor got
//  right, and all that is missing is 0.413 mm of depth, because 3.887 is
//  shallower than a 4.00 mm DIN 934 nut and leaves it standing 0.113 proud.
//
//  We re-cut it anyway, at our own pkt_af and pkt_depth, for a reason that is
//  not cosmetic: a pocket the donor owns is a pocket that changes silently if
//  the donor mesh is ever re-exported. Cutting it here makes the depth OURS,
//  and makes it something verify_buckle.py can hold to a number.  Our hex is
//  0.0005 narrower than the donor's on the radius, so in practice the donor's
//  own walls still govern the fit and only the floor moves.
//
//  ------------------------------------------------------------------
//  WHERE EACH POCKET GOES, AND WHY IT IS NOT A CHOICE
//
//  The donor decided this, not us.  Its nut trap is in the LOW-X prong; the
//  hand screw's head bore against the plain HIGH-X face at x 23.635.  So the
//  head counterbore goes where the head already went, and the nut stays where
//  the nut already is.  Swapping them would mean filling a good 8.00 hex and
//  cutting a new one 18 mm away -- three changes to save none.
//
//    low-x prong    boss face x 5.0164, hex 8.00 AF, pkt_depth deep.
//                   Floor lands at 9.3164, which leaves 2.190 to the slot at
//                   11.506 -- 0.69 more than nut_wall asks for.  The 0.413 we
//                   sink it costs exactly that much wall, and it is spent out
//                   of a surplus, not out of the minimum.
//    high-x prong    plain face x 23.635, and only 2.604 mm of prong behind
//                   it.  A 5.00 mm cap head sunk head_seat below flush wants
//                   hd_depth + nut_wall = 6.80.  Hence the boss below.
//
//  ------------------------------------------------------------------
//  THE BOSS, AND THE ONE ENVELOPE RULE
//
//  Nothing may poke outside R7.5 about the pivot or the hinge jams part-way
//  through its travel.  The boss is a disc of the DONOR'S OWN knuckle radius,
//  7.3655, not our tab_r of 7.50: it is then provably not one micron outside
//  a silhouette the part already had, and it clears the R7.5 rule by 0.135
//  into the bargain.  Same trick as side_boss() in arm_simple.scad, with the
//  donor's circle standing in for tab_solid().
//
//  What it does NOT share with arm_simple's bosses is a footing.  There, the
//  knuckle is tangent to the bed and the boss stands on it.  Here the knuckle
//  floats: its lowest point is y 7.8745, and the buckle's own body runs under
//  the boss as a shelf that falls away from y 7.457 at the inboard end to
//  6.819 at the outboard one.  So the boss's underside starts 0.42 mm above
//  solid material where it begins and 1.06 mm above it where it ends -- two to
//  five layers of air at 0.2 mm, directly over a wide flat shelf.  That is a
//  short bridge, not a cliff, and it is the smallest of the four support jobs
//  this part already has.
//
//  ------------------------------------------------------------------
//  SUPPORT.  Same budget as arm_simple, for the same reasons: the hex roof is
//  flat (pkt_peak is false there and there is no peak here either), the head
//  counterbore's roof is a ceiling however you cut it, the donor's pivot bore
//  is round, and now the boss underside bridges 0.39..0.76 to the shelf.
//  DIG THE POCKETS OUT BEFORE THE NUT AND THE SCREW GO IN.
//
//  ------------------------------------------------------------------
//  WHAT FITS IT
//    M5x16 socket cap + M5 nut, driven with a 4 mm key instead of a thumb.
//
//    The head bears on its counterbore floor at x 22.531 and the nut spans
//    5.316..9.316, so a shank needs 17.215 to fill the nut and may not exceed
//    17.515 before it pokes out of the boss face.  NOTHING STANDARD LANDS IN
//    THAT 0.30 WINDOW, so it is a real either/or:
//      M5x16   2.785 of the nut's 4.00 engaged, nothing proud anywhere
//      M5x18   the whole nut, standing 0.485 proud of the boss face
//    Buy the 16.  2.785 mm is ~3.5 turns of steel on steel, and this joint
//    fails in the PETG round the pocket long before an M5 thread strips -- so
//    the extra engagement buys nothing, while 0.485 of screw sticking out of a
//    part whose whole job is to be clipped on and off costs snagging.
//    verify_buckle.py [8] re-derives all of this from the mesh.
// =====================================================================

// arm_simple.scad carries every pocket number this file uses -- pkt_af,
// pkt_depth, hd_d, hd_depth, head_cs, head_da, nut_wall, nut_af.  Including
// it rather than copying them means they cannot drift apart.  It sets `lib`
// for arm.scad itself; `lib_s` suppresses its own standalone preview.
lib_s = true;
include <arm_simple.scad>

clip_stl = "inspiration/Quck Release v3 clip.STL";

// ---------------------------------------------------- the donor, measured
// All of these are read off the mesh, not off a drawing.  verify_buckle.py
// re-derives each one from the exported part, so a donor swap fails the gate
// instead of quietly shifting our pockets.
clip_pivot_y = 15.240;    // pivot, in the STL's own frame
clip_pivot_z = 12.700;
clip_bore_d  =  5.461;    // the donor's pivot bore -- WIDER than our bore_d
clip_knuckle_r = 7.3655;  // measured 7.3649..7.3660 over the free arc
clip_face_nut  =  5.0164; // low-x prong: outer face of the boss the donor has
clip_slot_nut  = 11.506;  // ... and the slot wall behind it
clip_face_hd   = 23.635;  // high-x prong: the plain outer face
clip_slot_hd   = 21.031;  // ... and the slot wall behind it
// Centre of the prong stack, i.e. where a mating 2-prong end has to sit.  The
// middle prong runs 14.681..17.856 and the two slots are centred on 13.0935
// and 19.4435, so both give 16.2685 -- the stack is symmetric about it even
// though the two OUTER prongs are not.  Nothing in the part is positioned off
// this; fitcheck.scad needs it to place a mating arm on the hinge.
clip_mid_c   = 16.2685;

// ------------------------------------------------------- the raised hinge
// THE ONE CHANGE THIS FILE MAKES TO THE DONOR'S SHAPE.  An arm bolted to the
// buckle could not lie down: measured, it swung -90..+70 -- 160 deg, and the
// 20 it was short of a half turn were all on the clip-body side.
//
// What stops it is not the joint.  The mating knuckle is R7.5 and the donor's
// own connector is R7.3655, so the KNUCKLE clears the whole way round.  It is
// the arm's BODY: arm_simple's is a 15.0 mm slab, so it sweeps a half-height
// of 7.5 mm radially outward from the pivot at every angle, and swinging it
// down lays that slab across the clip.  The pivot sits only 15.240 above the
// plane the part prints on, with the clip's own plate under it and beside it.
//
// So the fix is HEIGHT, not shape.  Lift the whole connector and the swept
// slab lifts with it, while every other thing on the part stays exactly where
// the donor put it.  fitcheck.py --buckle is what chose the number, by
// swinging a real arm rather than an ideal knuckle:
//
//   raise  0.00   -90 .. +70    160 deg   as the donor stands
//   raise  1.22   +90 still fouls, by 0.0554 mm^3 -- the last of it
//   raise  1.23   -90 .. +90    180 deg   the half turn, on the boundary
//   raise  1.50   -90 .. +90    180 deg   THIS
//   raise  1.70   -100 .. +90   190 deg
//   raise  4.00   -100 .. +100  200 deg
//
// 1.50 is the 1.23 where the half turn first comes free plus `joint_clr`, the
// 0.25 mm of clearance every hinge in this project already carries.  The half
// turn is what the part is for, and it is met with 0.27 mm of lift in hand at
// the pose that binds, rather than by a reading that sits on zero.
//
// AND IT STOPS THERE ON PURPOSE, because the table does not level off -- 1.70
// would buy another 10 deg and 4.00 another 10 after that.  The connector is a
// cantilever carrying the arm and whatever is on the end of it, its neck is
// the whole load path, and every millimetre of lift is another millimetre of
// lever on that neck, bought for swing nobody asked for.  180 deg was the ask.
//
// clip_pivot_y stays what the DONOR measured, because that is what the mesh
// surgery cuts against.  bk_pivot_y is where the hinge ends up, and every
// feature this file adds or cuts hangs off THAT -- both pockets and the boss.
// Set bk_raise = 0 and the two are the same number and the part is the
// donor's again, which is how the byte-identical baseline was taken.
bk_raise   = 1.50;
bk_pivot_y = clip_pivot_y + bk_raise;

// ---------------------------------------------------------- how it is done
// The connector is DONOR MESH.  There is no parameter to turn, so raising it
// is mesh surgery, and the donor's own shape is what makes it a clean one:
//
//   above y 15.240 (the pivot)   the knuckle, a disc of R 7.3655
//   below it                     a gusset flaring out at exactly 10 deg from
//                                7.4796 at the pivot's own height
//   below y ~9.7                 the plate, and nothing else in this x window
//
// Measured by ray-casting the donor, not read off a drawing: the outermost
// material in x 4.7..24.1 runs 7.4796 at y 15.240, 7.6983 at 14.0, 7.8746 at
// 13.0, 8.2273 at 11.0 -- a straight 0.1763 = tan(10 deg) per mm -- and above
// the pivot it is the knuckle circle to four places (7.1523 at y 17, 6.3329
// at 19, 0 at 22.606 = 15.240 + 7.3655).
//
// Two things follow, and they are the whole method.  The section NARROWS
// monotonically upward through all of that, and in this x window there is
// nothing but the connector above y 9.7.  So:
//
//   cut at bk_cut_y, lift everything above it by bk_raise, and fill the gap
//   with THAT SECTION extruded.
//
// The fill is `projection(cut = true)` of the donor at bk_cut_y, which is the
// section itself rather than a guess at it -- no need to know how many prongs
// there are, where the slots stop, or whether the gusset is solid across.  And
// because the section narrows upward, the extrusion is exactly flush at both
// ends: the profile runs the donor's gusset up to bk_cut_y, a straight band
// bk_raise tall, then the donor's gusset again.  EVERY horizontal section of
// the finished part is a section the donor already had.  Nothing gains a
// silhouette, and the print keeps its overhang budget -- a 0 deg wall where
// there was a 10 deg one is the safe direction.
bk_cut_y   = 11.00;   // in the gusset: clear of the plate at 9.669 and of the
                      // bore, which starts at 15.240 - 5.461/2 = 12.510
bk_lift_x0 =  4.70;   // the connector's own x window.  Its faces are 5.0164
bk_lift_x1 = 24.10;   // (the donor's nut boss) and 23.635 (the high-x prong);
                      // measured, the lifted piece comes out 5.0164..23.6346
                      // and |z - 12.700| <= 8.2273, i.e. no plate came with it.

// ------------------------------------------------------------- the boss
// Only as thick as the head pocket needs, exactly as boss_hd is in
// arm_simple.scad -- there against prong_out_t, here against whatever prong
// the donor left us.
bk_prong_hd = clip_face_hd - clip_slot_hd;                    // 2.604
bk_boss_hd  = max(0, hd_depth + nut_wall - bk_prong_hd);      // 4.196
bk_face_hd  = clip_face_hd + bk_boss_hd;                      // 27.831

// ------------------------------------------------------------- asserts
// The same structural minima arm_simple.scad states, restated against the
// donor's geometry rather than ours.  They are minima, not the design intent;
// the intent is measured off the mesh in verify_buckle.py.
assert(bk_face_hd - hd_depth - clip_slot_hd >= nut_wall - 1e-6,
       str("the head counterbore floor leaves ",
           bk_face_hd - hd_depth - clip_slot_hd, " to the slot (want ",
           nut_wall, ")"));
assert(clip_slot_nut - (clip_face_nut + pkt_depth) >= nut_wall,
       str("the nut pocket floor leaves ",
           clip_slot_nut - (clip_face_nut + pkt_depth),
           " to the slot (want ", nut_wall, ")"));
// The countersink is cut INTO the wall the head bears on, so it has to stop
// short of the slot behind it -- head_cs off a nut_wall floor, as there.
assert(nut_wall - head_cs >= 1.00,
       str("the countersink leaves only ", nut_wall - head_cs,
           " mm of floor wall behind the head (want >= 1.00)"));
// It also has to clear the fillet it exists for.  Cut to the DONOR'S bore,
// which is 5.461 rather than our 5.30, so the mouth opens wider than the arm's
// 6.30 and the ISO 4762 da of 5.70 clears by more, not less.
assert(clip_bore_d + 2*head_cs >= head_da + 0.20,
       str("the countersink opens the bore mouth to ", clip_bore_d + 2*head_cs,
           ", which does not clear a ", head_da, " under-head fillet"));
assert(hd_d >= head_d + 0.10,
       "head counterbore is not wider than the head -- it will not seat");
// A nut trap, not a hole the nut spins in.
assert(pkt_af/2 < nut_af/sqrt(3) - 0.05,
       "nut pocket is so wide the M5 nut spins freely -- it is not a trap");
// THE SPACER HAS TO LAND IN THE GUSSET, and both of these say why.
// Above the pivot the section is the knuckle circle, and extruding a circle
// turns it into a stadium -- the joint would stop being round.  Below
// clip_pivot_y - clip_bore_d/2 the section is solid, and above it there is a
// hole: extrude a section with the bore in it and the bore becomes a SLOT,
// bk_raise taller than it is wide.  0.50 keeps the cut clear of the mesh's own
// faceting at the bore's widest point.
assert(bk_cut_y <= clip_pivot_y - clip_bore_d/2 - 0.50,
       str("the spacer is cut at y ", bk_cut_y,
           ", which is inside the pivot bore starting at ",
           clip_pivot_y - clip_bore_d/2, " -- it would stretch the bore into a slot"));
// The other end of the same window: below y 9.669 the cut plane starts taking
// the CLIP PLATE with it, and the plate is what the connector is supposed to
// be rising out of.  Measured off the donor by ray-casting, not assumed --
// buckle_diff.scad's `lifted_stray` re-measures it on every build.
assert(bk_cut_y >= 10.20,
       str("the spacer is cut at y ", bk_cut_y,
           ", which is into the clip plate at 9.669 -- it would lift the plate too"));
// Nothing outside R7.5 about the pivot, or the hinge jams part-way through.
assert(clip_knuckle_r <= tab_r,
       str("the boss silhouette (", clip_knuckle_r, ") is outside the R", tab_r,
           " joint envelope"));
// Both pocket roofs have to stay inside that same circle, with wall left.
assert(clip_knuckle_r - pkt_r >= 1.50,
       str("the nut pocket's corner leaves ", clip_knuckle_r - pkt_r,
           " to the knuckle -- under 1.50"));
assert(clip_knuckle_r - hd_d/2 >= 1.50,
       str("the head counterbore leaves ", clip_knuckle_r - hd_d/2,
           " to the knuckle -- under 1.50"));

// --------------------------------------------------------- the raise
// The x window, unbounded in y and z: what "the connector" means here.
module bk_xwin() {
    translate([bk_lift_x0, -60, -60]) cube([bk_lift_x1 - bk_lift_x0, 120, 120]);
}
// ... and the same window from bk_cut_y up: what moves.
module bk_lift_box() {
    translate([bk_lift_x0, bk_cut_y, -60]) cube([bk_lift_x1 - bk_lift_x0, 120, 120]);
}

// The spacer: the donor's own section at bk_cut_y, bk_raise tall.
// `projection(cut = true)` works on the z = 0 plane, so the donor is dropped
// so that bk_cut_y sits at y = 0 and then rolled +90 deg about X, which puts
// that plane at z = 0; the extrusion is rolled back the same way.  Taking the
// section off the x window rather than the whole part is what keeps the plate
// and the rails out of it -- they have sections at this height too, just not
// in these 19.4 mm of x.
module bk_spacer() {
    translate([0, bk_cut_y, 0]) rotate([-90, 0, 0])
        linear_extrude(height = bk_raise)
            projection(cut = true)
                rotate([90, 0, 0]) translate([0, -bk_cut_y, 0])
                    intersection() { import(clip_stl, convexity = 12); bk_xwin(); }
}

// The donor with its connector standing bk_raise higher.  Three pieces that
// meet on two planes: the part below the cut where the donor left it, the part
// above it lifted, and the spacer between.  A union, so the coincident faces
// at bk_cut_y and bk_cut_y + bk_raise are seams and not slivers.
module bk_donor_raised() {
    difference() { import(clip_stl, convexity = 12); bk_lift_box(); }
    translate([0, bk_raise, 0])
        intersection() { import(clip_stl, convexity = 12); bk_lift_box(); }
    bk_spacer();
}

// --------------------------------------------------------------- pieces
// A disc on the donor's own knuckle circle, spanning x0..x1.  This is the
// buckle's tab_solid(): the one silhouette anything added here is allowed to
// have.  $fn = 180 puts the polygon's CIRCUMradius at clip_knuckle_r, so the
// measured maximum is the number above and not a hair over it.
// `rim` rolls the OUTER (high-x) edge off by a quarter-round.  The donor's own
// nut boss has exactly this feature -- measured R1.24 off that mesh, rms 6 um
// over 24 points, so a nominal 1.25 -- and boss_rim_r comes from
// arm_simple.scad, which now rounds its bosses the same way.  One number for
// all three bosses on the two parts; they cannot drift.
//
// Unlike the arms' rims this one costs nothing at all in bed contact: this
// boss never touches the bed, it bridges to the donor's shelf, and the round
// pulls its lowest point UP and away from that shelf rather than down onto it.
module bk_disc(x0, x1, rim = 0) {
    translate([(x0 + x1)/2, bk_pivot_y, clip_pivot_z])
        cyl(r = clip_knuckle_r, h = x1 - x0, rounding2 = rim,
            orient = RIGHT, $fn = 180);
}

// The press-fit nut pocket, opening on the donor's boss face and running
// inboard.  rotate([0,90,0]) maps the 2D profile's +X to the model's -Z and
// its +Y to +Y, so a plain $fn = 6 circle -- vertex on the profile's +X --
// lands a VERTEX on the model's Z axis and a FLAT on its Y axis.  Y is up
// here, so that is FLATS UP: the same orientation the donor cut, and the same
// one arm_simple argues for (a vertex up rests the nut on two points).
module bk_nut_pocket() {
    translate([clip_face_nut - 0.5, bk_pivot_y, clip_pivot_z])
        rotate([0, 90, 0])
            linear_extrude(height = pkt_depth + 0.5)
                circle(r = pkt_r, $fn = 6);
}

// The barrel-head counterbore, opening on the boss face, plus the 45 deg
// relief cut the other way out of the same plane so the screw's under-head
// fillet has somewhere to go.  Both are anchored on the FLOOR, which is where
// the head actually bears -- as in spkt_head().
//
// The relief is sized off clip_bore_d, not bore_d.  The donor's bore is the
// hole the fillet is trying to enter; opening a 5.30 cone into a 5.461 hole
// would cut nothing at all on the last 0.08 of radius and leave the sharp
// corner exactly where the fillet lands.
module bk_head_pocket() {
    translate([bk_face_hd - hd_depth, bk_pivot_y, clip_pivot_z]) {
        rotate([0,  90, 0])                       // outboard: the counterbore
            cylinder(d = hd_d, h = hd_depth + 0.5, $fn = 96);
        rotate([0, -90, 0])                       // inboard: the relief
            cylinder(d1 = clip_bore_d + 2*head_cs, d2 = clip_bore_d,
                     h = head_cs, $fn = 96);
    }
}

// ------------------------------------------------------------ the buckle
module buckle() {
    difference() {
        union() {
            bk_donor_raised();
            bk_disc(clip_face_hd, bk_face_hd, boss_rim_r);
        }
        bk_nut_pocket();
        bk_head_pocket();
    }
}

// ---------------------------------------------------------------- preview
// Guarded on its own sentinel, as arm_simple.scad is: main.scad sets `lib_b`.
if (is_undef(lib_b)) buckle();
