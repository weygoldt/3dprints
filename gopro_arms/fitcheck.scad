// =====================================================================
//  Fit / interference harness.
//
//  Mates the arm against a SYNTHETIC GoPro part built to the exact nominal
//  standard (3.00 prongs, 3.00 slots, 15.00 stack, R7.5 knuckle, 5.0 bore).
//  The reference is deliberately ideal: if our part fouls it, our part is
//  wrong -- we cannot blame a sloppy real-world mount.
//
//  The test is a boolean intersection whose VOLUME is then measured off the
//  exported mesh by fitcheck.py.  Interference volume must be exactly 0.
//
//    openscad -o i.stl --render -D 'ang=0' -D 'test="male_in_ours"' fitcheck.scad
//
//  tests:
//    male_in_ours    ideal GoPro 2-prong plugged into OUR 3-prong end
//    ours_in_female  OUR 2-prong end plugged into an ideal GoPro 3-prong
//    arm_in_arm      one of our arms into another
//    ctrl_male       control: the same male driven 1.0 mm off-axis in Y,
//                    which MUST report non-zero -- proves the probe can see
//                    a collision at all
//  ... and the same four against the SIMPLE variant, suffixed _simple.  The
//  joint is identical between the two variants, so any difference in the
//  measured range is the BODY getting in the way and nothing else.
// =====================================================================

lib_s = true;        // arm_simple.scad sets `lib` itself and includes arm.scad
include <arm_simple.scad>
use <clamp.scad>

test = "male_in_ours";
ang  = 0;      // 0 = arms collinear (fully extended)
armL = 100;
REF_U = 3.00;  // the standard, with zero clearance anywhere

// Ideal knuckle: a full R7.5 disc of thickness t, centred on y=yc.
module ref_tab(yc, t) {
    translate([0, yc, pivot_z]) rotate([-90, 0, 0])
        cylinder(r = tab_r, h = t, center = true, $fn = 160);
}

// Ideal GoPro 2-prong male: two 3.00 fingers on +/-3.00, body extending -X.
module ref_2prong() {
    difference() {
        union() {
            ref_tab(-REF_U, REF_U);
            ref_tab( REF_U, REF_U);
            translate([-tab_r - 10, 0, pivot_z]) cube([20, 15, 2*tab_r], center = true);
        }
        translate([0, -25, pivot_z]) rotate([-90, 0, 0]) cylinder(d = 5.0, h = 50, $fn = 96);
    }
}

// Ideal GoPro 3-prong female: prongs on 0 and +/-6.00, slots on +/-3.00.
module ref_3prong() {
    difference() {
        union() {
            ref_tab(-2*REF_U, REF_U);
            ref_tab(       0, REF_U);
            ref_tab( 2*REF_U, REF_U);
            translate([-tab_r - 10, 0, pivot_z]) cube([20, 5*REF_U, 2*tab_r], center = true);
        }
        translate([0, -25, pivot_z]) rotate([-90, 0, 0]) cylinder(d = 5.0, h = 50, $fn = 96);
    }
}

// Swing a mating part about the shared pivot.  ang=0 -> collinear.
// The child is assumed to be BUILT with its own pivot at height `pz`; this
// only rotates it, it does not move it onto the axis.
module at_pivot(px, a, pz = pivot_z) {
    translate([px, 0, pz]) rotate([0, a, 0]) translate([0, 0, -pz]) children();
}

// Same, for a reference part built about arm.scad's pivot that has to mate
// with the SIMPLE arm, whose pivot sits s_pivot_z - pivot_z higher.  Two
// parts on a hinge share ONE axis, so the reference is lifted onto it first.
// Its own base ends up off the bed, which is meaningless -- it is a mating
// solid, not something anyone prints.
module at_ref_pivot(px, a, pz) {
    at_pivot(px, a, pz) translate([0, 0, pz - pivot_z]) children();
}

if (test == "male_in_ours")
    intersection() { arm(armL); at_pivot(0, ang) ref_2prong(); }
else if (test == "ours_in_female")
    intersection() { arm(armL); at_pivot(armL, ang) mirror([1,0,0]) ref_3prong(); }
else if (test == "ctrl_male")
    intersection() { arm(armL); translate([0, 1.0, 0]) at_pivot(0, ang) ref_2prong(); }
// Chaining: another one of OUR arms, its 2-prong end into our 3-prong end.
else if (test == "arm_in_arm")
    intersection() {
        arm(armL);
        at_pivot(0, ang) translate([-armL, 0, 0]) arm(armL);
    }
// ---- the same four, against the simple variant ----------------------
else if (test == "male_in_simple")
    intersection() { arm_simple(armL); at_ref_pivot(0, ang, s_pivot_z) ref_2prong(); }
else if (test == "simple_in_female")
    intersection() {
        arm_simple(armL);
        at_ref_pivot(armL, ang, s_pivot_z) mirror([1,0,0]) ref_3prong();
    }
else if (test == "ctrl_simple")
    intersection() {
        arm_simple(armL);
        translate([0, 1.0, 0]) at_ref_pivot(0, ang, s_pivot_z) ref_2prong();
    }
else if (test == "simple_in_simple")
    intersection() {
        arm_simple(armL);
        // Both arms are built about s_pivot_z, so no lift -- just the swing.
        at_pivot(0, ang, s_pivot_z) translate([-armL, 0, 0]) arm_simple(armL);
    }
// Baseline: the SAME reference male swung against an unmodified inspiration
// arm, so the articulation range can be compared like for like.  Its pivot A
// sits at (161.646, -0.01, 7.600); move it onto ours at (0, 0, 7.5).
else if (test == "insp_male")
    intersection() {
        translate([-161.646, 0.01, pivot_z - 7.600])
            import("inspiration/7.5cm_Gopro_Arm.stl", convexity = 10);
        at_pivot(0, ang) ref_2prong();
    }
// The pipe clamp plugged into our own 3-prong end.  The clamp is built with
// its collar on +X, so mirror it to point away from the arm.
else if (test == "clamp_in_arm")
    intersection() {
        arm(armL);
        at_pivot(0, ang) mirror([1, 0, 0]) pipe_clamp();
    }
else if (test == "show_clamp")
    { arm(armL); at_pivot(0, ang) mirror([1, 0, 0]) pipe_clamp(); }
else if (test == "show_male")
    { arm(armL); at_pivot(0, ang) ref_2prong(); }
else if (test == "show_female")
    { arm(armL); at_pivot(armL, ang) mirror([1,0,0]) ref_3prong(); }
