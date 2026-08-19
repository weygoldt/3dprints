// =====================================================================
//  What buckle.scad ADDS to the donor, and what it TAKES OUT of it.
//
//  "Keep the part as it is" is a claim about two SETS, and measuring the
//  finished buckle cannot check either one -- a pocket in the wrong place
//  measures exactly as well as a pocket in the right place.  So render the
//  set differences and measure those instead.
//
//  THE RAISE MADE THIS A CHAIN OF TWO, and that is the point rather than a
//  complication.  Once the connector stands 1.500 mm higher, differencing the
//  finished part against the raw donor mixes two changes that have nothing to
//  do with each other: the pockets would read as "moved", the knuckle as
//  "added and removed", and no fence could tell a mis-cut pocket from the lift
//  it rode up on.  So each step is bounded on its own:
//
//    donor  --[ the RAISE ]-->  bk_donor_raised()  --[ OUR pockets ]-->  buckle()
//
//    added / removed         buckle() against the RAISED donor.  Must be the
//                            head boss and the two pockets, exactly the
//                            numbers this check has always held them to --
//                            the raise does not touch them, it carries them.
//    lift_added / _removed   the raised donor against the DONOR.  Must be one
//                            spacer's worth of material in the connector's own
//                            x window, plus the 1.500 mm the pivot bore bores
//                            off the top of where it used to be.
//    spacer                  bk_spacer() alone, for the identity below.
//    ctrl                    CONTROL: the donor differenced against itself,
//                            shifted 0.5 mm.  MUST come out non-empty.  If it
//                            reads zero the boolean-and-measure path is blind
//                            and none of the others prove anything, exactly as
//                            ctrl_male does in fitcheck.scad.
//
//  THE IDENTITY, which is what really pins the lift down:
//
//      lift_added - lift_removed  ==  volume(spacer)
//
//  Lift a solid whose section narrows monotonically upward by dy and fill the
//  gap with the section you cut at, and the material you have gained is the
//  fill and nothing else -- the shells the lift adds higher up telescope
//  exactly into the ones it vacates.  A lift that dragged the clip plate with
//  it, a spacer that did not match its own cut, a cut plane in the wrong place:
//  each breaks the identity, and none of them has to be guessed at in advance.
//
//    openscad -o d.stl --render -D 'test="added"' buckle_diff.scad
// =====================================================================

lib_b = true;          // buckle.scad brings arm_simple.scad, which brings arm.scad
include <buckle.scad>

test = "added";        // [added, removed, ctrl, added_stray, removed_stray,
                       //  lift_added, lift_removed, lift_added_stray,
                       //  lift_removed_stray, spacer]

// The fences are PLAIN NUMBERS, deliberately, and that includes the pivot
// height they are struck about: 16.740 = 15.240 + 1.500.  A bound that shared
// code with the thing it bounds would agree with its bugs.  The cost is that
// they go stale if the raise changes, so say so out loud rather than let a
// silent fence pass a part it was never sized for.
assert(bk_raise == 1.50,
       str("bk_raise is ", bk_raise, ", but every fence in buckle_diff.scad is ",
           "written out for 1.50 -- re-derive them, do not widen them"));

// ---- conservative BOUNDS on where a change is allowed to be -----------
// Deliberately larger than the features they contain.  They are not the
// design; they are a fence around it.
module bound(x0, x1, r) {
    translate([x0, 16.740, 12.700]) rotate([0, 90, 0])
        cylinder(r = r, h = x1 - x0, $fn = 240);
}
module allow_boss()   { bound(23.60,  27.87, 7.40); }   // boss 23.635..27.831, r 7.3655
module allow_nut()    { bound( 4.40,   9.36, 4.66); }   // nut pocket, r <= 4.6188
module allow_head()   { bound(21.98,  27.87, 4.45); }   // head bore + relief, r <= 4.40

// Where the RAISE is allowed to reach: the connector's own x window, from just
// under the cut plane upward, and no wider than the section that is cut there.
// The lifted piece measures x 5.0164..23.6346 and |z - 12.700| <= 8.2273, so
// every bound here stands off it -- if the cut plane ever dropped into the
// clip plate, the plate would run straight out of this box in z.
module allow_lift()   { translate([4.95, 10.95, 12.700 - 8.30])
                            cube([23.70 - 4.95, 40, 16.60]); }
// ... and what the raise TAKES, which is every HOLE in the connector riding up
// with it and boring 1.500 mm off the top of where it used to stop.  There are
// exactly two, and the second one is easy to forget because it is the donor's
// and not ours: the pivot bore, and the hexagon the donor already had in its
// nut boss.  Left out, the hex reads as 49.26 mm^3 of unexplained removal.
// Ø5.461 -> r 2.7305, fenced at 2.79; the hex is 8.0010 across flats -> 4.6193
// across corners, fenced at 4.67 over its own x 5.0164..8.903.
module allow_bore()   { translate([4.95, 16.740, 12.700]) rotate([0, 90, 0])
                            cylinder(r = 2.79, h = 23.70 - 4.95, $fn = 240); }
module allow_dhex()   { translate([4.95, 16.740, 12.700]) rotate([0, 90, 0])
                            cylinder(r = 4.67, h = 8.95 - 4.95, $fn = 240); }

module donor() { import(clip_stl, convexity = 12); }

module added()        { difference() { buckle();            bk_donor_raised(); } }
module removed()      { difference() { bk_donor_raised();   buckle();          } }
module lift_added()   { difference() { bk_donor_raised();   donor();           } }
module lift_removed() { difference() { donor();             bk_donor_raised(); } }

if (test == "added")             added();
else if (test == "removed")      removed();
else if (test == "lift_added")   lift_added();
else if (test == "lift_removed") lift_removed();
else if (test == "spacer")       bk_spacer();
// Everything changed that is NOT inside its own fence.  Must measure zero:
// a vertex test cannot be used here because differencing two meshes that share
// most of their surfaces leaves coplanar, ZERO-VOLUME shells scattered over
// the coincident faces.  Those carry no material, so volume sees through them
// and a bounding box does not.
else if (test == "added_stray")        difference() { added();   allow_boss(); }
else if (test == "removed_stray")      difference() { removed(); allow_nut(); allow_head(); }
else if (test == "lift_added_stray")   difference() { lift_added();   allow_lift(); }
else if (test == "lift_removed_stray") difference() { lift_removed(); allow_bore(); allow_dhex(); }
else if (test == "ctrl")
    difference() {
        translate([0.5, 0, 0]) donor();
        donor();
    }
