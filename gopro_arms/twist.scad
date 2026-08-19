// =====================================================================
//  GoPro 90 deg TWIST adapter  --  a short arm whose two hinge axes stand
//  at right angles, so a chain can change its plane of articulation.
//
//  Built from arm_simple.scad's numbers.  The donor STL in inspiration/ is
//  a SHAPE reference and nothing else -- it is not imported and not one of
//  its dimensions is inherited.  It could not be: its 3-prong middle prong
//  is 3.300 against our 3.100 central gap, and its 2-prong fingers span
//  +/-(1.650 .. 4.800) where our slots reach only 4.55, so neither of its
//  ends would enter ours.  What DID come off it is the one thing worth
//  taking, measured by ray-casting:
//
//      the two hinge axes are EXACTLY 90 deg apart  (dot product 0)
//      they are 34.994 apart, and their common normal runs along the arm
//      lateral offset 0.000 -- skew but square: no dogleg, no rise
//      knuckle radius 7.5, which is our own tab_r
//
//  So the part is OUR joint at both ends, tw_L apart, with the far end's
//  hinge axis turned 90 deg.  That is the whole design.
//
//  ------------------------------------------------------------------
//  FRAME.  This part is MODELLED IN ITS PRINT ORIENTATION, and it prints
//  FLAT ON ITS UNDERSIDE, like the arms.
//
//    +X   the arm's own axis.  Pivot A (3-prong, both screw pockets, both
//         bosses) at x = 0; pivot B (2-prong fork) at x = tw_L.
//    +Y   pivot A's hinge axis -- HORIZONTAL, exactly as on every arm here.
//    +Z   pivot B's hinge axis -- VERTICAL, and also the build direction.
//    z = 0 is the bed, and the whole underside sits on it.
//
//  X, Y and Z mutually perpendicular IS what a twist adapter is: both hinge
//  axes square to each other and both square to the arm between them.
//
//  ------------------------------------------------------------------
//  WHY IT LIES DOWN, AND WHAT THAT COSTS
//
//  There is no orientation that is right on every count, and the two that
//  matter pull in opposite directions.  The choice is forced by one fact:
//
//      LAYERS ALONG THE ARM  <=>  the build direction is ACROSS the arm
//                            <=>  one hinge axis stands VERTICAL.
//
//  You cannot have layer lines running the length of the part AND both hinge
//  axes horizontal.  So:
//
//    STANDING ON END (both axes horizontal).  Every slot is a vertical slice
//      through its knuckle -- open top and bottom, no ceiling, nothing for
//      auto-support to grab, both slots measure 0.00 mm^2.  It was built and
//      measured that way first.  What it costs is everything else: the layers
//      run ACROSS the arm, so every bending load is carried by layer adhesion
//      at a single 15 mm section, and the part stands 50 mm tall on a 3.44 mm
//      first-layer line.  Both failures are the same failure -- it breaks or
//      it falls over -- and both are the ones that actually happen.
//
//    LYING DOWN (this file).  Layers run the length of the arm, so bending is
//      carried in-plane, where PETG is roughly twice as strong; and the whole
//      underside is flat on the plate, 477.6 mm^2 of it measured, so the tower
//      problem does not exist.  Pivot A's axis stays horizontal and its end is
//      therefore EXACTLY arm_simple's 3-prong end, slot floors and all.  This
//      is also the reason the arms lie flat, and README.md has said so under
//      "Reinforcement" all along: bending stress runs along X, in-plane for
//      every layer, never across them.
//
//      The bill is pivot B.  Its axis is vertical, so its slot is a
//      horizontal gap and the upper finger hangs over it: 229.5 mm^2 of
//      ceiling INSIDE a 3.10 mm slot, which is the one thing this project
//      otherwise refuses.  It is taken with eyes open, and it is the mildest
//      form of it there is -- the support is a 3.10 mm wafer lying flat on
//      the lower finger, with solid material directly beneath it and the
//      whole circumference open, not a column growing up a blind slot.  DIG
//      IT OUT BEFORE THE JOINT GOES TOGETHER; a knuckle that will not close
//      is what a forgotten one feels like.  Your slicer will not warn you --
//      it is quiet because it has already planned to fill that slot.
//
//  ------------------------------------------------------------------
//  WHAT LYING DOWN SETTLES, AND IT IS MOST OF THE PART
//
//    * PIVOT A IS UNCHANGED.  Not "similar to" arm_simple's 3-prong end --
//      it is that end, built by the same modules in the same frame: the same
//      centred pivot at tab_r, the same FLAT slot floors, the same round
//      pivot bore, the same two pockets in the same two bosses.  Nothing
//      about it needed re-deriving, which is the point of not importing.
//    * NO GABLE.  Standing up, pivot A's slot floors faced DOWN and had to be
//      ridged to keep a ceiling out of them.  Lying down they face along -X
//      and are plain vertical planes, so the ridge is not merely unnecessary,
//      it would be a notch cut for nothing.  pocket(..., flat = true), as on
//      the simple arm.
//    * NO TEARDROPS.  A teardrop only earns its keep pointing UP.  Pivot A's
//      bore now runs across the part like an arm's, so it is arm_simple's
//      plain ROUND bore -- which buys back 1.10 mm of crown and costs the
//      same 23.5 mm^2 of ceiling inside a 5.30 hole that file already pays.
//      Pivot B's bore is VERTICAL: a vertical hole has no roof at all.
//    * THE BODY DOES NOT TWIST.  Both ends' constraints are expressible in
//      one frame -- pivot A wants 15.9 across Y, pivot B wants 8.9 up Z -- so
//      the section changes size without ever rotating.  There is no helix to
//      pay overhang for, because there is no helix.
//
//  ------------------------------------------------------------------
//  THE ONE CONSEQUENCE WORTH STATING OUT LOUD
//
//  The part has a FLAT BOTTOM, is 15.0 tall at pivot A (that knuckle is 15.0
//  in diameter) and 8.9 tall at pivot B (that stack is 8.9 across), so the
//  two joints' centrelines sit 3.05 mm apart in Z.  That is not a dogleg
//  bolted on: it is what a flat-bottomed part with two different end heights
//  looks like, and the AXES are still exactly perpendicular and exactly tw_L
//  apart, which is what the twist actually is.  The donor has 3.4 mm of the
//  same thing for the same reason.
//
//  The alternative is to centre the fork on pivot A's height instead, which
//  costs another ~155 mm^2 of ceiling -- the LOWER finger's whole disc, less
//  the bore, hanging 3.05 mm off the bed -- plus whatever the body's underside
//  owes once it is cut away beneath it, and it gives up the flat bottom.
//  tw_fork_z is the one line that changes it; see it in full below.
//
//  ------------------------------------------------------------------
//  SUPPORT.  Five places, measured, and only the first is in a joint:
//    * the UPPER FORK FINGER, 229.5 mm^2 over pivot B's 3.10 mm slot.  See
//      above.  This is the one to dig out.
//    * PIVOT A's KNUCKLE UNDERSIDE, 94.2 mm^2 -- the circle is tangent to the
//      bed and leaves at 90 deg, as the simple arm's knuckles do.  It is
//      barely half what that arm pays per knuckle, and the reason is the
//      orientation again: only the OUTBOARD half of the stack is exposed,
//      because the inboard half sits inside the body's own prism.  Both
//      halves of each BOSS are exposed, though -- they stand proud in Y.
//    * the BOSS RIMS, r1.25, 17.6 mm^2, on the edge of that same underside.
//    * the two SCREW POCKETS, 56.5 mm^2 -- a flat hex roof and a round
//      counterbore roof, exactly as arm_simple.scad describes them.
//    * PIVOT A's BORE, 23.5 mm^2, round instead of teardropped.
//  Everything else is upward-facing or vertical by construction: the body's
//  top rounding, its 45 deg bottom chamfer, the fork's outer walls, and the
//  vertical bore.
//
//  ------------------------------------------------------------------
//  WHAT FITS IT.  The same M5x16 socket cap + M5 nut the simple arm takes,
//  in the same two pockets at the same depths -- pivot A's end IS that end.
//  Checked against this part's own two faces rather than assumed: the head
//  seats 0.30 below its face, the nut 0.30 below its own, and the tip stops
//  0.40 inside the nut pocket with 3.9 of the nut's 4.0 engaged.
//  Pivot B takes a plain M5 through-bolt or a GoPro thumbscrew; it has no
//  pockets, because a 2-prong end cannot have them -- a boss on the outside
//  of a finger fouls the mating part's outer prong.
// =====================================================================

// OpenSCAD's include is TEXTUAL and has no include-once, so this project keeps
// exactly ONE chain and each file extends it rather than opening a second path
// to arm.scad -- two paths would define every module twice.  The chain is now
//   main.scad / fitcheck.scad  ->  twist.scad  ->  buckle.scad
//                              ->  arm_simple.scad  ->  arm.scad
// and each file guards its own standalone preview on its own sentinel.
lib_b = true;
include <buckle.scad>

// ---------------------------------------------------------------- the twist
// PIVOT-TO-PIVOT, measured along the common normal of the two axes, which is
// the arm's own X.  35.0 is the donor's number and it survives the check that
// matters here -- not "does it look right" but "is there room to turn the
// corner":
//
//   the two slots reach pocket_r each way from their pivots, so they clear
//   each other only above 2*pocket_r = 22.10 -- that is the hard floor;
//   pivot A's section has to be held at the plain knuckle prism out to
//   pocket_r, exactly as the simple arm holds its own, and pivot B's has to
//   be down to the fork's 8.9 before it enters the mating knuckle's sweep at
//   tab_r + joint_clr.  Everything the body does happens in between, and at
//   35 that is 16.2 mm.  At 30 it is 11.2; at 25 the ramp gets steep enough
//   to be a step rather than a taper.
//
// Longer is free.
tw_L = 35.0;

// ------------------------------------------------------------- pivot B
// The fork.  Its hinge axis is VERTICAL, so its two fingers are horizontal
// discs and its stack height is the 8.90 a 2-prong end always is.
//
// It sits with its LOWER FINGER ON THE BED.  That is the whole reason the
// underside of this part is flat, and it is worth being explicit about what
// it buys and what it costs, because the alternative is one line away:
//
//   on the bed (tw_fork_z = 0)     the lower finger prints straight onto the
//                                  plate and the body's underside is one
//                                  plane end to end.  The two joints' centres
//                                  end up 3.05 mm apart in Z.
//   centred on pivot A (= 3.05)    the centres line up, the lower finger
//                                  hangs 3.05 off the bed and needs its own
//                                  ~155 mm^2 of support -- its whole disc,
//                                  less the bore -- plus whatever the body's
//                                  underside owes once it is cut away beneath
//                                  it.  And it MUST be cut away, not filled
//                                  in: that volume is where the MATING part's
//                                  lower outer prong swings.
tw_fork_z = 0;
fork_h    = 2*w2_half;                 // 8.900  the 2-prong stack, upright
fork_c    = tw_fork_z + w2_half;       // 4.450  stack centre == pivot B's datum

// ------------------------------------------------------------- the body
// A slab with a FLAT BOTTOM, as tall as pivot A's knuckle where it meets it
// and as tall as the fork where it meets that.  Both are that end's own
// bounding prism, which is arm_simple's rule and it is what stops either
// knuckle standing proud of the body it grows out of.
tw_h0    = s_tab_top;          // 15.000  at pivot A -- the knuckle's diameter
tw_h1    = fork_h;             //  8.900  at pivot B -- the fork's stack
tw_w0    = w3_half;            //  7.950  half-width at pivot A: the 3-prong stack
tw_w1    = tab_r;              //  7.500  half-width at pivot B: the fingers' radius
tw_rt    = 2.50;               // top edge rounding
// The bottom edge is a 45 deg CHAMFER, not arm_simple's r2.50 fillet, and the
// reason is this part's orientation rather than a change of taste.  A fillet
// is tangent to the bed, so it leaves through 90 deg of overhang and has to be
// supported for the whole length of the part; arm_simple accepts that because
// its pockets force support anyway and it has bed contact to spare.  Here the
// flat underside IS the argument for lying the part down at all, so it is not
// spent on a cosmetic round: a 45 deg chamfer sits ON the budget, needs
// nothing, and keeps the footing wide.  arm.scad made the same call for the
// same reason before support was on the table.
tw_cb    = 2.00;               // bottom edge chamfer, 45 deg
tw_stn   = 24;                 // loft stations across the transition

// The transition band.  It starts where pivot A's slots end -- the section is
// held at the plain knuckle prism until then, exactly as the simple arm holds
// its own -- and finishes before the body enters the mating knuckle's sweep at
// pivot B, because from there in it must already be down to the fork's height.
function tw_xA()  = pocket_r;                        // 11.05
function tw_xB(L) = L - (tab_r + joint_clr);         // 27.25 at L = 35

function tw_t(x, L) = sstep(tw_xA(), tw_xB(L), x);
function tw_hw(x, L) = tw_w0 + (tw_w1 - tw_w0)*tw_t(x, L);
function tw_ht(x, L) = tw_h0 + (tw_h1 - tw_h0)*tw_t(x, L);
// 0 at BOTH ends -> the section is the plain rectangle matching that end's own
// prism exactly; 1 through the middle -> chamfered and rounded.  Same shape as
// arm_simple's sb_s, and taken back to 0 at the fork for the same reason it is
// at a knuckle: the fork's two discs are square-edged and 15.0 across, so a
// body still carrying its chamfer there would sit 2.0 mm inside them at the
// bed and leave a notch along the join -- and give up that bed contact.
function tw_s(x, L) = sstep(pocket_r, pocket_r + 8, x)
                    * (1 - sstep(L - 8, L, x));

function tw_station_xs(L) =
    concat([0],
           [for (i = [0:tw_stn]) tw_xA() + i/tw_stn * (tw_xB(L) - tw_xA())],
           [L]);

// One 0.01 mm station slab at x.  The section is anchored on the BED, not
// centred: the flat underside is the invariant here, and the two ends'
// different heights hang off it.
module tw_slab(x, L) {
    ht = tw_ht(x, L);
    s  = tw_s(x, L);
    translate([x, 0, 0]) rotate([90, 0, 90])
        linear_extrude(height = 0.01)
            rect([2*tw_hw(x, L), ht],
                 rounding = [tw_rt*s, tw_rt*s, 0, 0],
                 chamfer  = [0, 0, tw_cb*s, tw_cb*s],
                 anchor   = FRONT);
}

module tw_body(L) {
    xs = tw_station_xs(L);
    for (i = [0 : len(xs) - 2])
        hull() { tw_slab(xs[i], L); tw_slab(xs[i+1], L); }
}

// ------------------------------------------------------------- the fork
// Two discs on a vertical axis.  A full R7.5 circle each: there is no bed
// tangency to trim for -- the lower one's underside IS the bed and the upper
// one's is the ceiling this orientation pays for.
module tw_fork() {
    for (z = [tw_fork_z, tw_fork_z + fork_h - fing_w])
        translate([0, 0, z]) cylinder(r = tab_r, h = fing_w, $fn = 160);
}

// Pivot B's cuts: the vertical bore, and the slot between the fingers.
//
// The slot is arm_simple's own pocket turned onto this axis -- slot_w between
// the finger faces, running out to pocket_r toward the body and clear of the
// part in every other direction, with root_fillet where the floor meets the
// finger faces.  Those fillet edges run along Y here, not Z, because the floor
// it is filleting is a vertical plane at x = -pocket_r and not a horizontal
// one: same edge, named in this part's frame.
module tw_fork_cuts() {
    translate([0, 0, tw_fork_z - 1])
        cylinder(d = bore_d, h = fork_h + 2, $fn = 96);
    translate([0, 0, fork_c])
        cuboid([2*pocket_r, 8*tab_r, slot_w],
               rounding = root_fillet, edges = "Y");
}

// ------------------------------------------------------------ the adapter
// L = pivot-to-pivot along the arm's axis.  Pivot A (3-prong) hinges about Y
// at x = 0; pivot B (2-prong) about Z at x = L.
//
// Pivot A is arm_simple's 3-prong end, called by arm_simple's own modules.
// Nothing here re-derives it.
module twist_adapter(L = tw_L) {
    assert(tw_xA() + 4.0 <= tw_xB(L),
           str("twist_adapter(L): L too short -- pivot A's slots reach ",
               pocket_r, " and pivot B's knuckle sweeps ", tab_r + joint_clr,
               ", so the body has nowhere to change section"));
    difference() {
        union() {
            tab_solid(-w3_half, w3_half, s_pivot_z);       // 3-prong knuckle
            sboss();                                       // both bosses
            tw_body(L);
            translate([L, 0, 0]) tw_fork();
        }
        sbore(0, 6*sw3_max);                               // round, as arm_simple
        pocket(0,  u, s_pivot_z, true);                    // FLAT floors, as arm_simple
        pocket(0, -u, s_pivot_z, true);
        spkt_nut( nut_side);
        spkt_head(-nut_side);
        translate([L, 0, 0]) tw_fork_cuts();
    }
}

// ---- what the part is standing on, asserted rather than assumed ----
// The fork has to clear the mating knuckle's sweep, or the joint jams before
// it closes.
assert(tw_L - pocket_r > tab_r + joint_clr,
       str("pivot B's slot floor at ", tw_L - pocket_r,
           " is inside the ", tab_r + joint_clr, " a mating knuckle sweeps"));
// The body must be down to the fork's height before it enters that sweep, or
// it fouls the mating part's outer prongs.
assert(tw_ht(tw_xB(tw_L), tw_L) <= fork_h + 0.01,
       str("the body is still ", tw_ht(tw_xB(tw_L), tw_L),
           " tall where the mating knuckle starts sweeping (want ", fork_h, ")"));
// And the fork must sit inside the body it grows out of, on the bed.
assert(tw_fork_z >= 0 && tw_fork_z + fork_h <= tw_h0,
       "the fork stands outside the body's own section");

// ---------------------------------------------------------------- preview
// Render the adapter when this file is opened on its own.  Guarded on its own
// sentinel because this file already sets `lib_b` for buckle.scad; main.scad
// and fitcheck.scad set `lib_t` instead.
if (is_undef(lib_t)) twist_adapter();
