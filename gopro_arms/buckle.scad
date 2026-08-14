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
//    knuckle           R 7.3655, dead flat over the whole free arc (-85..+90
//                      about the pivot); the body takes over outside that
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

// --------------------------------------------------------------- pieces
// A disc on the donor's own knuckle circle, spanning x0..x1.  This is the
// buckle's tab_solid(): the one silhouette anything added here is allowed to
// have.  $fn = 180 puts the polygon's CIRCUMradius at clip_knuckle_r, so the
// measured maximum is the number above and not a hair over it.
module bk_disc(x0, x1) {
    translate([x0, clip_pivot_y, clip_pivot_z])
        rotate([0, 90, 0])
            cylinder(r = clip_knuckle_r, h = x1 - x0, $fn = 180);
}

// The press-fit nut pocket, opening on the donor's boss face and running
// inboard.  rotate([0,90,0]) maps the 2D profile's +X to the model's -Z and
// its +Y to +Y, so a plain $fn = 6 circle -- vertex on the profile's +X --
// lands a VERTEX on the model's Z axis and a FLAT on its Y axis.  Y is up
// here, so that is FLATS UP: the same orientation the donor cut, and the same
// one arm_simple argues for (a vertex up rests the nut on two points).
module bk_nut_pocket() {
    translate([clip_face_nut - 0.5, clip_pivot_y, clip_pivot_z])
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
    translate([bk_face_hd - hd_depth, clip_pivot_y, clip_pivot_z]) {
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
            import(clip_stl, convexity = 12);
            bk_disc(clip_face_hd, bk_face_hd);
        }
        bk_nut_pocket();
        bk_head_pocket();
    }
}

// ---------------------------------------------------------------- preview
// Guarded on its own sentinel, as arm_simple.scad is: main.scad sets `lib_b`.
if (is_undef(lib_b)) buckle();
