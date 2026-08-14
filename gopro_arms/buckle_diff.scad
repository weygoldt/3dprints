// =====================================================================
//  What buckle.scad ADDS to the donor, and what it TAKES OUT of it.
//
//  "Keep the part as it is" is a claim about two SETS, and measuring the
//  finished buckle cannot check either one -- a pocket in the wrong place
//  measures exactly as well as a pocket in the right place.  So render the
//  two set differences and measure those instead:
//
//    added     buckle() minus the donor.  Must be the head boss and nothing
//              else: confined to x 23.635..27.831 and inside R7.5 of the
//              pivot, which is the envelope rule stated as a measurement.
//    removed   the donor minus buckle().  Must be the two pocket cuts and
//              nothing else -- no stray trim of the joint, the latch or the
//              rails.
//    ctrl      CONTROL: the donor differenced against itself, shifted 0.5 mm.
//              MUST come out non-empty.  If it reads zero the boolean-and-
//              measure path is blind and the other two prove nothing, exactly
//              as ctrl_male does in fitcheck.scad.
//
//    openscad -o d.stl --render -D 'test="added"' buckle_diff.scad
// =====================================================================

lib_b = true;          // buckle.scad brings arm_simple.scad, which brings arm.scad
include <buckle.scad>

test = "added";        // [added, removed, ctrl, added_stray, removed_stray]

// ---- conservative BOUNDS on where a change is allowed to be -----------
// Deliberately written out here as plain numbers, larger than the features
// they contain, instead of being built from buckle.scad's own modules.  A
// bound that shared code with the thing it bounds would agree with its bugs.
// They are not the design; they are a fence around it.
module bound(x0, x1, r) {
    translate([x0, 15.240, 12.700]) rotate([0, 90, 0])
        cylinder(r = r, h = x1 - x0, $fn = 240);
}
module allow_boss()   { bound(23.60,  27.87, 7.40); }   // boss 23.635..27.831, r 7.3655
module allow_nut()    { bound( 4.40,   9.36, 4.66); }   // nut pocket, r <= 4.6188
module allow_head()   { bound(21.98,  27.87, 4.45); }   // head bore + relief, r <= 4.40

module added()   { difference() { buckle(); import(clip_stl, convexity = 12); } }
module removed() { difference() { import(clip_stl, convexity = 12); buckle(); } }

if (test == "added")             added();
else if (test == "removed")      removed();
// Everything we added that is NOT inside the boss fence.  Must measure zero:
// a vertex test cannot be used here because differencing two meshes that share
// most of their surfaces leaves coplanar, ZERO-VOLUME shells scattered over
// the coincident faces.  Those carry no material, so volume sees through them
// and a bounding box does not.
else if (test == "added_stray")   difference() { added();   allow_boss(); }
else if (test == "removed_stray") difference() { removed(); allow_nut(); allow_head(); }
else if (test == "ctrl")
    difference() {
        translate([0.5, 0, 0]) import(clip_stl, convexity = 12);
        import(clip_stl, convexity = 12);
    }
