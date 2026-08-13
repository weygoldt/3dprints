// =====================================================================
//  GoPro extension arms -- renderer / part picker.
//
//  Render one part:
//    openscad -o out.stl --render -D 'part="arm100"' main.scad
//
//  Parts:
//    gauge          fit coupon -- BOTH ends, no beam.  PRINT THIS FIRST.
//    arm50 / arm75 / arm100 / arm140   pivot-to-pivot length in mm
//    set            all four arms laid out for one plate
//    section        a slice of the strut profile, for eyeballing the shape
//    clamp          2-prong pipe clamp -- holds a 12 mm pipe, squeezed shut
//                   by the arm's own thumbscrew (no clamp screw of its own)
//
//  Print: PETG, 0.2 mm layers, 0.4 nozzle, NO SUPPORT, flat face on the bed.
//  Bump perimeters to 4-5; the strut is only 10 mm thick, so perimeters do
//  most of the structural work and the part ends up nearly solid.
// =====================================================================

include <arm.scad>
use <clamp.scad>

part = "arm100";   // [gauge, arm50, arm75, arm100, arm140, set, section, clamp]

arm_lengths = [50, 75, 100, 140];

if      (part == "gauge")   gauge();
else if (part == "arm50")   arm(50);
else if (part == "arm75")   arm(75);
else if (part == "arm100")  arm(100);
else if (part == "arm140")  arm(140);
else if (part == "set")     arm_set();
else if (part == "section") section_demo();
else if (part == "clamp")   pipe_clamp();

// All four arms, side by side, flat faces all on the bed.
module arm_set() {
    pitch = 2*w3_half + 6;
    for (i = [0 : len(arm_lengths) - 1])
        translate([0, i*pitch, 0]) arm(arm_lengths[i]);
}

// 10 mm of the mid-beam strut section, to look at the profile alone.
module section_demo() {
    intersection() {
        arm(100);
        translate([50, 0, 0]) cube([10, 60, 60], center = true);
    }
}
