// =====================================================================
//  GoPro 2-prong PIPE CLAMP  --  holds a 12 mm pipe, clamped by the arm.
//
//  A classic split collar whose two flanges ARE the GoPro fingers.  There is
//  no clamp screw of its own: you slip the collar over the pipe, push the
//  fingers into a 3-prong end, and the GoPro thumbscrew squeezes the flanges
//  together, which closes the collar onto the pipe.
//
//  ------------------------------------------------------------------
//  THE ONE THING THAT MAKES OR BREAKS THIS
//  The 3-prong's MIDDLE PRONG is a hard stop sitting in the flange gap.  The
//  flanges can only travel until they touch it, so with standard 2.90 fingers
//  in 3.10 slots you get 0.20 mm of squeeze -- and the lever from the pivot
//  down to the split turns that into ~0.10 mm at the bore.  That is not a
//  clamp, it is a rattle.
//
//  So the fingers here are deliberately UNDERSIZE (fing_t, default 2.40) and
//  sit OUTBOARD in the slots (fing_out, default 4.35).  That leaves the flange
//  gap wider than the middle prong by design, and every bit of that difference
//  is usable travel:
//
//      travel per side = fing_out - fing_t - (mating middle prong)/2
//                      = 4.35 - 2.40 - 1.50 = 0.45 mm   (real GoPro)
//      bore closure    = 2 * travel * 2a/(D + a)
//
//  where a is the bore radius and D the pivot-to-collar distance: the collar
//  rotates about its far side, so the split closes by rather less than the
//  flanges do.  With the defaults that is ~0.47 mm of bore closure against a
//  0.30 mm slip fit, so the pipe is gripped well before the flanges bottom
//  out.  If the pipe is oversize the flanges simply never reach the middle
//  prong and the screw load goes straight into the grip; if it is undersize
//  they bottom out and the joint still clamps.  Both failure directions are
//  graceful, which is the point.
//
//  ------------------------------------------------------------------
//  FRAME (same convention as arm.scad)
//    +X  from the pivot out to the collar.  Split faces the pivot.
//    +Y  hinge axis.  The GoPro screw squeezes ALONG Y -- which is why the
//        collar has to lie in the XY plane and the pipe has to run along Z.
//    +Z  build direction AND the pipe axis, so the bore is a plain vertical
//        hole: no overhang, no support, round where it matters.
//
//  PIPE SIZE: pipe_d is the pipe's OUTSIDE diameter, assumed 12.0 mm.  If your
//  "12 mm" pipe is a nominal-bore size its OD will be more like 16-18 mm --
//  measure it and change the one line.
// =====================================================================

lib = true;          // suppress arm.scad's standalone preview
include <arm.scad>

// ---------------------------------------------------------------- pipe
pipe_d     = 12.00;   // pipe OUTSIDE diameter
pipe_clr   = 0.30;    // slip fit before clamping; the closure has to beat this
clamp_wall = 3.00;    // collar wall
clamp_h    = 16.00;   // collar height = grip length along the pipe
lead_ch    = 0.80;    // 45 deg lead-in at both ends of the bore

// ------------------------------------------------------------- flanges
// Undersize on purpose -- see the note above.  fing_out is the OUTER face,
// i.e. how close the flange sits to the slot's outer wall (4.50 on a real
// GoPro 3-prong, 4.55 on ours), so it also sets the insertion clearance.
fing_t     = 2.40;
fing_out   = 4.35;
neck_clr   = 0.50;    // collar's clearance past the R7.5 knuckle circle

// ---------------------------------------------------------------- derived
cl_bore_r = (pipe_d + pipe_clr)/2;          // 6.15
coll_r    = cl_bore_r + clamp_wall;         // 9.15
coll_x    = tab_r + coll_r + neck_clr;      // 17.15  pivot -> collar centre
split_g   = 2*(fing_out - fing_t);          // 3.90  flange gap == collar split

// Travel before the flanges touch a mating middle prong, and what that is
// worth at the bore once the collar's own lever is taken into account.
function clamp_travel(mid = 3.00) = 2*(fing_out - fing_t - mid/2);
function clamp_closure(mid = 3.00) =
    clamp_travel(mid) * (2*cl_bore_r)/(coll_x + cl_bore_r);

// ---------------------------------------------------------------- pieces

// Silhouette in XZ: the knuckle disc at the pivot, blended into a plain
// full-height neck running out to the collar.  Reuses the arm's knuckle
// profile, so it is cut flat by the bed at exactly oh_ang like everything else.
module neck_profile2d() {
    union() {
        tab_profile2d();
        square([coll_x, tab_top]);
    }
}

module neck_solid() {
    translate([0, fing_out, 0]) rotate([90, 0, 0])
        linear_extrude(height = 2*fing_out) neck_profile2d();
}

// Vertical pipe bore with 45 deg lead-ins at both ends.
module pipe_bore() {
    union() {
        translate([0, 0, -1]) cylinder(r = cl_bore_r, h = clamp_h + 2, $fn = 160);
        translate([0, 0, -0.01])
            cylinder(r1 = cl_bore_r + lead_ch, r2 = cl_bore_r, h = lead_ch, $fn = 160);
        translate([0, 0, clamp_h - lead_ch + 0.01])
            cylinder(r1 = cl_bore_r, r2 = cl_bore_r + lead_ch, h = lead_ch, $fn = 160);
    }
}

// ---------------------------------------------------------------- the part
module pipe_clamp() {
    difference() {
        union() {
            neck_solid();
            translate([coll_x, 0, 0]) cylinder(r = coll_r, h = clamp_h, $fn = 160);
        }
        translate([coll_x, 0, 0]) pipe_bore();
        // ONE cut makes both the flange gap and the collar split, so they are
        // continuous by construction and cannot drift apart.  It runs from
        // behind the fingers right up to the bore.
        translate([-2*tab_r - 5, -split_g/2, -1])
            cube([2*tab_r + 5 + coll_x - cl_bore_r, split_g, clamp_h + 2]);
        bore(0, 6*fing_out);        // M5 teardrop, from arm.scad
    }
}

// ---------------------------------------------------------------- preview
// Render the part when this file is opened on its own.  main.scad and
// fitcheck.scad pull it in with `use`, which imports modules but does NOT
// execute top-level geometry, so this does not double up there.
pipe_clamp();
