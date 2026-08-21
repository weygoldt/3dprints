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
//
//  ... and three against arm_double(), the 3-prong-BOTH-ENDS arm:
//    male_in_double_a  ideal GoPro 2-prong into its near end
//    male_in_double_b  ... and into its far one, swung separately
//    ctrl_double       the usual off-axis control
//  There is no arm-to-arm case for that part and cannot be: both of its ends
//  are female, so two of them will not couple -- which is the whole reason
//  it exists.
//
//  ... and three more against the 90 deg TWIST adapter:
//    male_in_twist    ideal GoPro 2-prong into its 3-prong end (pivot A)
//    twist_in_female  its 2-prong end into an ideal GoPro 3-prong (pivot B)
//    ctrl_twist       the same control, driven off-axis along pivot A's X
//  Each end is swung on ITS OWN axis, separately, because that is the whole
//  point of the part: the two ends articulate in planes at right angles, so a
//  sweep of one says nothing about the other.  Running them together would
//  also be wrong -- it would measure a pose, not a range.
//
//  ... and three against the QUICK-RELEASE BUCKLE, which break the pattern
//  twice over:
//    simple_in_buckle  a REAL simple arm's body swung on the buckle's hinge
//    buckle_grid       the same pair with the joint envelope left in
//    show_buckle       the two together, for looking at
//  The mating part is a real arm and not ref_2prong() because the question is
//  about the arm's 15.0 mm slab BODY, which the ideal reference does not have;
//  and the answer is a RANGE rather than zero-at-collinear, because the whole
//  point of raising that connector was to free a half turn.
// =====================================================================

lib_p = true;        // the chain: plate -> twist -> buckle -> arm_simple -> arm
include <plate.scad>
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

// ---- the RAIL PLATE's frame ----------------------------------------
// The plate carries its connectors at boss_pos, not at the origin, so the
// PLATE is slid until connector `i` sits on the origin -- and then TURNED
// until that connector is unyawed, because at_plate() swings about Y and the
// connectors are yawed a quarter turn.  Moving the part and not the probe
// keeps every pose in the same frame the arms are swept in; a rotation and a
// translation are rigid, so the interference volume is unchanged.
//
// What ang means changed with the yaw.  Unyawed, ang = 0 laid a mating part
// flat OUTBOARD over a short edge and ang = 180 laid it flat inboard, straight
// at the other connector -- so that end of the sweep was expected to bite, and
// the gate was the outboard quadrant only.  Yawed, the swing plane runs
// fore-aft and the other connector is 44 mm away ALONG THE HINGE AXIS, out of
// the plane entirely: ang = 0 and ang = 180 both lie flat over a long edge and
// neither has anything in it but the plate.  So the arm should now keep the
// whole half turn, and the sweep says whether it does.
module plate_at_origin(i = 0) {
    rotate([0, 0, -boss_yaws[i]])
        translate([-boss_pos[i][0], -boss_pos[i][1], 0]) rail_plate();
}

// The WIDE plate's one connector is turned a quarter turn, so its hinge axis
// runs along X and at_plate() -- which swings about Y -- cannot reach it.
// Rather than write a second swing helper, the PART is turned back: translate
// its connector onto the origin, then un-yaw it.  Interference volume is
// invariant under a rigid transform, and a rotation is not a mirror, so this
// re-frames the question without changing its answer.
module plate155_at_origin() {
    rotate([0, 0, -wide_yaw])
        translate([-wide_pos[0][0], -wide_pos[0][1], 0]) rail_plate155();
}

// Carry a mating part built about its own pivot height `pz_part` onto the
// PLATE's pivot -- a full tab_r above the plate top, not arm.scad's pivot_z --
// and swing it there.
module at_plate(a, pz_part) {
    at_pivot(0, a, p_pivot_z) translate([0, 0, p_pivot_z - pz_part]) children();
}

// The 90 deg twist adapter's two pivots do NOT share an axis, so ONE helper
// cannot place a mating part on both -- which is the part's whole point.
//
// PIVOT A needs no helper at all: its hinge axis runs along Y at s_pivot_z,
// which is exactly the simple arm's pivot, so at_ref_pivot() places a mating
// part on it unchanged.  That is not a coincidence, it is the design -- lying
// this part down makes its 3-prong end an arm's 3-prong end in every respect.
//
// PIVOT B is the one that needs its own: its axis is VERTICAL.  The reference
// is built about arm.scad's pivot_z with its axis along Y and its body on -X,
// so it is dropped onto the origin, rolled 180 deg about [0,1,1] -- which
// takes Y to Z (the axis it has to share) and -X to +X (so its body points
// away from ours at ang = 0) -- and then swung about Z.  A rotation, not a
// mirror: the reference has to stay the handedness a real GoPro part is.
//
// It lands at fork_c up its own axis, not at s_pivot_z, because that is where
// this part's fork actually sits -- see twist.scad on the 3.05 mm step.
module at_twist_B(a) {
    translate([tw_L, 0, fork_c])
        rotate([0, 0, a])                          // swing about Z, the axis
            rotate(180, [0, 1, 1])                 // Y axis -> Z, body -> +X
                translate([0, 0, -pivot_z]) children();
}

// The QUICK-RELEASE BUCKLE's hinge is nothing like an arm's: it runs along X
// at (bk_pivot_y, clip_pivot_z) and the part stands on its y = 0 face.  So the
// ARM is carried into the buckle's frame rather than a reference into ours.
//
//   translate  the arm's 2-prong pivot onto the origin, its axis along Y
//   rotate Z   -90 deg -- that axis turns onto X, and the body onto +Y
//   rotate X   the swing itself, about the buckle's own hinge axis
//
// A rotation and never a mirror: the arm has to stay the handedness it prints
// as.  ang = 0 stands the arm straight UP, out of the clip and in the middle
// of the donor's free arc, so it is this pairing's "collinear"; positive ang
// swings it toward +Z, which is the way the clip body runs.
module at_buckle(a) {
    translate([clip_mid_c, bk_pivot_y, clip_pivot_z])
        rotate([a, 0, 0])
            rotate([0, 0, -90])
                translate([-armL, 0, -s_pivot_z])
                    children();
}

// The arm MINUS its 2-prong knuckle -- everything within R7.5 of that end's
// hinge axis.  Two reasons, and neither is to make the number look better.
//
//   * The donor's prong grid is IMPERIAL.  Its slots sit on +/-3.175 where our
//     fingers sit on +/-3.00, so 0.0375 mm of each finger overlaps the middle
//     prong AT EVERY ANGLE -- the 0.075 mm "firm push" buckle.scad already
//     documents.  It does not vary with the hinge, and left in it would report
//     the joint as fouling through the whole of its travel.  `buckle_grid`
//     measures that overlap instead of taking it on trust.
//   * Nothing else is inside R7.5 to remove.  The donor's body comes no closer
//     to the hinge axis than 7.63 mm, so within the envelope the only material
//     either part has is the interleaving prongs.  What is left is the two
//     BODIES, and the body is what the complaint is about: an ideal
//     ref_2prong() has no 15.0 mm slab and would measure the wrong part.
// The grid shows up TWICE, and cutting the knuckle away only catches one of
// them.  Our central gap is 3.10 where the donor's middle prong is 3.175, so
// 0.0375 mm of the arm's BODY stands proud into that prong on each side --
// beyond R7.5, so the envelope cut leaves it, and it scrapes the prong through
// the entire sweep (0.00004 mm^3 at the extended pose rising to 0.66 at 80 deg
// on the part as it stands).  That is the donor's tolerance being measured a
// second time, not articulation.  So the probe also opens its own gap to the
// donor's 1/8" -- the easing buckle.scad already prescribes, done on the ARM
// because the buckle is the part under test and has to arrive untouched.
//
// Only over the slot's own reach, `2*pocket_r`: past that the buckle is a
// plate spanning every x, our body is solid across its full 8.9 mm, and a
// collision there is the real thing rather than a 0.0375 mm sliver.
// The eased gap is the donor's 3.175 plus `slot_extra`, which is the rule
// every slot in this project already follows -- a slot accepts a finger of its
// own unit plus 0.10.  Sizing it dead on 3.175 instead leaves the two walls
// COINCIDENT, and coincident faces are what strew a boolean with zero-volume
// shells and thousandths of a mm^3 of numerical dust; measured, that dust was
// 0.0015 mm^3 at 80 deg, small but never zero, and this gate reads zero.
module simple_body(L) {
    ease = (3.175 + slot_extra - slot_w)/2;      // 0.0875 off each wall
    difference() {
        arm_simple(L);
        translate([L, -4*tab_r, s_pivot_z]) rotate([-90, 0, 0])
            cylinder(r = tab_r, h = 8*tab_r, $fn = 240);
        for (s = [-1, 1])
            translate([L, s*(slot_w + ease)/2, s_pivot_z])
                cube([2*pocket_r, ease, 8*tab_r], center = true);
    }
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
// ---- the 90 deg twist adapter --------------------------------------
else if (test == "male_in_twist")
    intersection() {
        twist_adapter();
        at_ref_pivot(0, ang, s_pivot_z) ref_2prong();
    }
else if (test == "twist_in_female")
    intersection() { twist_adapter(); at_twist_B(ang) ref_3prong(); }
// CONTROL: 1.0 mm off-axis along pivot A's own hinge axis Y, which is the
// direction that closes the slot clearance -- the same control the arms use.
else if (test == "ctrl_twist")
    intersection() {
        twist_adapter();
        translate([0, 1.0, 0]) at_ref_pivot(0, ang, s_pivot_z) ref_2prong();
    }
else if (test == "show_twist")
    {
        twist_adapter();
        at_ref_pivot(0, ang, s_pivot_z) ref_2prong();
        at_twist_B(ang) ref_3prong();
    }
// ---- 3-prong at BOTH ends -------------------------------------------
// Both of arm_double's ends are FEMALE, so both take the reference MALE -- and
// they are swung SEPARATELY, for the same reason the twist adapter's are: one
// sweep would measure a pose.  Here it would also measure the wrong thing, in
// that the two ends articulate in the SAME plane but against different halves
// of the body, and the body is not symmetric about its own middle until the
// flare at each end has finished.
//
// End B's reference is mirrored in X so its body points away from the arm at
// ang = 0, exactly as ours_in_female does.  Both references are symmetric
// across their own hinge axis, so that mirror is a rotation in effect and the
// reference stays the handedness a real GoPro part is.
else if (test == "male_in_double_a")
    intersection() { arm_double(armL); at_ref_pivot(0, ang, s_pivot_z) ref_2prong(); }
else if (test == "male_in_double_b")
    intersection() {
        arm_double(armL);
        at_ref_pivot(armL, ang, s_pivot_z) mirror([1, 0, 0]) ref_2prong();
    }
// CONTROL: 1.0 mm off-axis along the hinge, the direction that closes the slot
// clearance -- the same control the arms use, and it must read non-zero.
else if (test == "ctrl_double")
    intersection() {
        arm_double(armL);
        translate([0, 1.0, 0]) at_ref_pivot(0, ang, s_pivot_z) ref_2prong();
    }
else if (test == "show_double")
    {
        arm_double(armL);
        at_ref_pivot(0, ang, s_pivot_z) ref_2prong();
        at_ref_pivot(armL, ang, s_pivot_z) mirror([1, 0, 0]) ref_2prong();
    }
// ---- the quick-release buckle ---------------------------------------
else if (test == "simple_in_buckle")
    intersection() { buckle(); at_buckle(ang) simple_body(armL); }
// The same pairing with the joint envelope left IN, which is the number that
// justifies taking it out: at ang = 0 the bodies are nowhere near each other,
// so everything this reports is the donor's 1/8" prong grid against our 3.00.
else if (test == "buckle_grid")
    intersection() { buckle(); at_buckle(ang) arm_simple(armL); }
else if (test == "show_buckle")
    { buckle(); at_buckle(ang) arm_simple(armL); }
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
// ---- the RAIL PLATE ------------------------------------------------
// Different question from every sweep above.  The arms are checked for zero
// interference at the poses they are USED in; the plate is checked over a
// FULL HALF TURN, 0 to 180 deg, because that half turn is the whole reason
// its pivot stands a full tab_r above the plate instead of arm.scad's
// tab_r/sqrt(2).  ang = 0 lays the mating part flat toward -X, 90 stands it
// up, 180 lays it flat toward +X.  Anything less than the full 180 means the
// plate itself is in the way, which is exactly the failure to catch.
else if (test == "male_in_plate")
    intersection() { plate_at_origin(); at_plate(ang, pivot_z) ref_2prong(); }
// A REAL simple arm, not the reference: what limits this hinge at the ends of
// the sweep is the arm's 15.0 mm slab BODY lying down onto the plate, and the
// reference has no body worth the name.  Its 2-prong end is at x = armL, so
// it is slid back to the origin first.
else if (test == "simple_in_plate")
    intersection() {
        plate_at_origin();
        at_plate(ang, s_pivot_z) translate([-armL, 0, 0]) arm_simple(armL);
    }
// CONTROL: 1.0 mm off-axis along Y, the hinge axis -- the direction that
// closes the slot clearance.  Same control the arms use.  If this reads zero
// the probe is blind and the two sweeps above mean nothing.
else if (test == "ctrl_plate")
    intersection() {
        plate_at_origin();
        translate([0, 1.0, 0]) at_plate(ang, pivot_z) ref_2prong();
    }
// ---- the WIDE plate: one centred connector, swinging fore-aft ------
// Same three questions, and one difference that is the point of the variant:
// there is no SECOND connector for the arm to meet, so nothing but the plate
// itself is in the way and the real arm should keep the full half turn the
// ideal male gets.
else if (test == "male_in_plate155")
    intersection() { plate155_at_origin(); at_plate(ang, pivot_z) ref_2prong(); }
else if (test == "simple_in_plate155")
    intersection() {
        plate155_at_origin();
        at_plate(ang, s_pivot_z) translate([-armL, 0, 0]) arm_simple(armL);
    }
else if (test == "ctrl_plate155")
    intersection() {
        plate155_at_origin();
        translate([0, 1.0, 0]) at_plate(ang, pivot_z) ref_2prong();
    }
else if (test == "show_plate155")
    { plate155_at_origin();
      at_plate(ang, s_pivot_z) translate([-armL, 0, 0]) arm_simple(armL); }
else if (test == "show_plate")
    { plate_at_origin(); at_plate(ang, s_pivot_z) translate([-armL, 0, 0]) arm_simple(armL); }
else if (test == "show_male")
    { arm(armL); at_pivot(0, ang) ref_2prong(); }
else if (test == "show_female")
    { arm(armL); at_pivot(armL, ang) mirror([1,0,0]) ref_3prong(); }
