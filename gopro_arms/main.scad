// =====================================================================
//  GoPro extension arms -- renderer / part picker.
//
//  Render one part:
//    openscad -o out.stl --render -D 'part="arm100"' main.scad
//
//  Two families of arm, identical at the GoPro joint, different in the body:
//
//    STREAMLINED (arm.scad) -- Kamm-tail strut, 20 mm chord.  For the boat,
//    where water flows past the arm and a bluff section sheds a wake that
//    shakes the camera.  Costs material, print time and hinge travel.
//
//    SIMPLE (arm_simple.scad) -- slab body exactly as tall as the knuckle,
//    smoothed edges, screw pocket in BOTH outer prongs.  For everything else.
//    Lighter, faster to print, wider articulation, takes a plain M5 cap screw
//    flush into either face.
//
//  Parts:
//    gauge          fit coupon -- BOTH ends, no beam.  PRINT THIS FIRST.
//    arm50 / arm75 / arm100 / arm140   pivot-to-pivot length in mm
//    set            all four streamlined arms laid out for one plate
//    section        a slice of the strut profile, for eyeballing the shape
//    sgauge         fit coupon for the simple variant (checks BOTH pockets)
//    simple50 / simple75 / simple100 / simple140
//    sset           all four simple arms on one plate
//    ssection       a slice of the simple slab section
//    clamp          2-prong pipe clamp -- holds a 12 mm pipe, squeezed shut
//                   by the arm's own thumbscrew (no clamp screw of its own)
//
//  Print: PETG, 0.2 mm layers, 0.4 nozzle, NO SUPPORT, flat face on the bed.
//  Bump perimeters to 4-5; both bodies are under 10 mm thick, so perimeters
//  do most of the structural work and the part ends up nearly solid.
// =====================================================================

// arm_simple.scad sets `lib` itself and includes arm.scad, so this file
// only has to suppress arm_simple's own standalone preview.
lib_s = true;
include <arm_simple.scad>
use <clamp.scad>

part = "arm100";   // [gauge, arm50, arm75, arm100, arm140, set, section, sgauge, simple50, simple75, simple100, simple140, sset, ssection, clamp]

arm_lengths = [50, 75, 100, 140];

if      (part == "gauge")     gauge();
else if (part == "arm50")     arm(50);
else if (part == "arm75")     arm(75);
else if (part == "arm100")    arm(100);
else if (part == "arm140")    arm(140);
else if (part == "set")       arm_set();
else if (part == "section")   section_demo();
else if (part == "sgauge")    gauge_simple();
else if (part == "simple50")  arm_simple(50);
else if (part == "simple75")  arm_simple(75);
else if (part == "simple100") arm_simple(100);
else if (part == "simple140") arm_simple(140);
else if (part == "sset")      simple_set();
else if (part == "ssection")  section_simple_demo();
else if (part == "clamp")     pipe_clamp();

// All four arms, side by side, flat faces all on the bed.
module arm_set() {
    pitch = 2*w3_half + 6;
    for (i = [0 : len(arm_lengths) - 1])
        translate([0, i*pitch, 0]) arm(arm_lengths[i]);
}

// Same, for the simple variant.  Pitch off the wider bossed stack.
module simple_set() {
    pitch = 2*sw3_max + 6;
    for (i = [0 : len(arm_lengths) - 1])
        translate([0, i*pitch, 0]) arm_simple(arm_lengths[i]);
}

// 10 mm of the mid-beam strut section, to look at the profile alone.
module section_demo() {
    intersection() {
        arm(100);
        translate([50, 0, 0]) cube([10, 60, 60], center = true);
    }
}

module section_simple_demo() {
    intersection() {
        arm_simple(100);
        translate([50, 0, 0]) cube([10, 60, 60], center = true);
    }
}
