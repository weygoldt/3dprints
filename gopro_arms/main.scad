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
//    buckle         GoPro quick-release buckle, imported from the donor STL
//                   in inspiration/ and given the SIMPLE arm's screw pockets:
//                   an M5 cap head one side, a press-fit nut the other.  Its
//                   own print note is in buckle.scad and differs from the one
//                   below -- it needs SUPPORT, and it prints on its y=0 face.
//    cap            PVC pipe fairing cap -- presses into the end of a 12 mm
//                   tube and replaces the blunt rim with a rounded parabola,
//                   so the tube stops dragging a wake behind it.  Nothing to
//                   do with the GoPro joint; it lives here because it caps the
//                   pipes the clamp holds.  PRINT capgauge FIRST -- it sizes
//                   the press fit against the tube you actually have.
//    capset         four caps on one plate
//    capgauge       five plug stubs at stepped crest diameters, labelled
//    twist          90 deg twist adapter -- a short arm whose two hinge axes
//                   are at right angles, so a chain can change its plane of
//                   articulation.  It prints FLAT, like the arms, so its layer
//                   lines run the length of the part; that costs support in
//                   ONE joint -- pivot B's axis stands vertical, so its slot
//                   has a ceiling.  DIG THAT OUT before assembling.  The
//                   trade, and what standing it on end would have bought
//                   instead, is argued at the top of twist.scad.
//
//  Print: PETG, 0.2 mm layers, 0.4 nozzle, NO SUPPORT, flat face on the bed.
//  Bump perimeters to 4-5; both bodies are under 10 mm thick, so perimeters
//  do most of the structural work and the part ends up nearly solid.
// =====================================================================

// One include, four files: twist.scad sets `lib_b` and includes buckle.scad,
// which sets `lib_s` and includes arm_simple.scad, which sets `lib` and
// includes arm.scad.  OpenSCAD's include is textual and has no include-once,
// so the project keeps ONE chain rather than several paths to arm.scad -- two
// paths would define every module twice.  Each file guards its own standalone
// preview on its own sentinel, so this file only suppresses the outermost.
lib_t = true;
include <twist.scad>
use <clamp.scad>
// cap.scad shares nothing with the arm chain -- no GoPro joint, no BOSL2 --
// so it stays off the include chain entirely and comes in on its own.
use <cap.scad>

part = "arm100";   // [gauge, arm50, arm75, arm100, arm140, set, section, sgauge, simple50, simple75, simple100, simple140, sset, ssection, clamp, buckle, twist, cap, capset, capgauge]

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
else if (part == "buckle")    buckle();
else if (part == "twist")     twist_adapter();
else if (part == "cap")       pipe_cap();
else if (part == "capset")    cap_set();
else if (part == "capgauge")  cap_gauge();

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
