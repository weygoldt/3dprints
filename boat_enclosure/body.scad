// =====================================================================
//  AIRBOAT ENCLOSURE -- BODY  (the shell; prints FLOOR down)
// Part of the airboat catamaran enclosure. See common.scad for the
// frame mapping, all parameters, the fit-check echoes, and shared helpers.
// =====================================================================
include <common.scad>

// --- knuckle hinge: HOUSING leaf (body side of the outboard -X hinge) ---
module housing_leaf_2d() {
  translate([Ax, Ay]) circle(d=knuckle_d);
  polygon(concat(
    [[Ax + kr*cos(shell_bevel), Ay + kr*sin(shell_bevel)],
     [-W/2, ov_d + 0.3],
     [-W/2 + 0.6, ov_d + 0.3],
     [-W/2 + 0.6, leaf_reach]],
    arc(n=16, r=hinge_fillet, cp=leaf_F, angle=[0, -hinge_arm_ang]),
    [leaf_P]));
}

module hinge_housing() {
  difference() {
    hinge_segments(0) housing_leaf_2d();
    pin_bore_cut(-1);     // body prints floor down -> print-up = -y
  }
}

// =====================================================================
//  LID OVERLAP + SNAP LOCKS  (ported verbatim; full top-face perimeter)
// =====================================================================
module front_step_cut() {
  intersection() {
    difference() {
      translate([-W/2-5, -eps, -H/2-5]) cube([W+10, ov_d+0.3+eps, H+10]);
      translate([0, -2*eps, 0]) hull() for (sz=[-1,1]) {
        translate([ W/2-corner_r, 0, sz*(H/2-corner_r)])
          rotate([-90,0,0]) cylinder(h=ov_d+0.3+4*eps, r=corner_r-step);
        translate([-W/2+corner_r + (step_left-step), 0, sz*(H/2-corner_r)])
          rotate([-90,0,0]) cylinder(h=ov_d+0.3+4*eps, r=corner_r-step);
      }
    }
    translate([-W/2-1, -1, -H/2-6]) cube([W+10, ov_d+2, H+12]);
  }
}

module lock_dents() {
  for (z = lock_zs) translate([W/2-step+eps, lock_y, z]) lock_wedge(LEFT, dent=true);
  if (n_locks >= 2) translate([0, lock_y,  H/2-step+eps])  lock_wedge(DOWN, dent=true);
  if (n_locks >= 3) translate([0, lock_y, -(H/2-step)-eps]) lock_wedge(UP, dent=true);
}

// =====================================================================
//  XT60 CHARGE PORT  (ported; outboard wall / floor / stern)
// =====================================================================
module xt60_cut() {
  if (xt60 && xt60_face != "none") {
    bw = xt60_body[0]; bh = xt60_body[1];
    if (xt60_face=="left" || xt60_face=="right") {
      sx = (xt60_face=="right") ? 1 : -1;
      translate([sx*(W/2-wall/2), D/2+xt60_y, xt60_pos]) rotate([0,sx*90,0]) {
        cube([bw, bh, wall+2*eps], center=true);
        for (s=[-1,1]) translate([s*xt60_screw_sep/2, 0, 0])
          cylinder(h=wall+2*eps, d=xt60_screw_d, center=true);
      }
    } else if (xt60_face=="bottom") {   // floor (Y=D)
      translate([xt60_pos, D-wall/2, 0]) rotate([90,0,0]) {
        cube([bw, bh, wall+2*eps], center=true);
        for (s=[-1,1]) translate([s*xt60_screw_sep/2, 0, 0])
          cylinder(h=wall+2*eps, d=xt60_screw_d, center=true);
      }
    } else if (xt60_face=="bow" || xt60_face=="stern") {  // end wall (+Z bow / -Z stern)
      zc = (xt60_face=="bow") ? H/2-wall/2 : -H/2+wall/2;
      translate([xt60_pos, D/2+xt60_y, zc]) {   // long axis (flange/screws) along X
        cube([bw, bh, wall+2*eps], center=true);
        for (s=[-1,1]) translate([s*xt60_screw_sep/2, 0, 0])
          cylinder(h=wall+2*eps, d=xt60_screw_d, center=true);
      }
    }
  }
}

// =====================================================================
//  THROUGH-BOARD SCREW MOUNT  (floor interior; blind, sealed, WATERTIGHT)
//  Each boss is a solid PLA cylinder unioned to the floor, rising boss_rise
//  INTO the chamber.  The screw bore is drilled from the BOTTOM (bed) face
//  (Y=D) UPWARD (toward -Y / the lid) and stops screw_cap short of the boss
//  top, so it NEVER reaches the chamber void -- the whole watertight guarantee.
//  Because the box prints floor-DOWN, the boss stands vertically on the bed
//  (fully supported) and the blind bore opens at the bed face and runs straight
//  up -> self-supporting, NO teardrop needed (unlike the old horizontal sockets).
//  The bosses are unioned AFTER the cavity is carved (see body()); otherwise the
//  cavity cut would erase them.  The bore is then cut through the merged
//  floor+boss, so the screw passes through the 2.5 mm floor and engages the boss.
// =====================================================================
module screw_boss(p) {   // solid boss: underside (Y=D) up into the chamber to Y=boss_top_y
  translate([p[0], D, p[1]]) rotate([90,0,0]) cylinder(h=boss_h, d=boss_od);
}

module screw_boss_cut(p) {   // blind bore UP from the underside; method sets insert / thread / pilot
  translate([p[0], D + eps, p[1]]) rotate([90,0,0]) {
    if (screw_method=="insert")      cylinder(h=insert_depth + eps, d=insert_d);
    else if (screw_method=="thread") tapped_hole(screw_size, screw_pitch, thread_len + eps, selftap_d, td=false);
    else                             cylinder(h=selftap_depth + eps, d=selftap_d);
  }
}

// =====================================================================
//  TASK 3 -- CABLE PORTS  (inboard +X wall; PLAIN through-holes, item 4)
//  No external boss: the cable gland's own threaded body + nut form the
//  shoulder and seal.  Just a clean hole through the 2.5 mm wall, sized for
//  the gland's panel-mount diameter.
// =====================================================================
module cable_port_cut(z, dia) {
  translate([W/2-wall-eps, port_y, z]) rotate([0,90,0])
    cylinder(h=2*wall+2*eps, d=dia);
}

// =====================================================================
//  TASK 1 -- MOTOR MOUNT BLOCK  (external, on the stern -Z wall)
//  A solid block protruding AFT from the stern wall, extending DOWN to the
//  FLOOR (Y=D) so it rests on the bed when printing (no overhang) and spreads
//  the motor load into the floor, not just the 2.5 mm wall.  The pylon foot
//  bolts to its aft face; 4 M4 blind holes (default: heat-set brass INSERT bore;
//  thread / selftap fallbacks) end mm_cavity_margin short of the cavity -- no
//  fastener enters the interior.  A full-width register SLOT takes the
//  shear/moment (bolts not in pure shear).
// =====================================================================
module motor_mount_boss() {
  difference() {
    translate([0, mm_pad_yc, -H/2 - mm_block_depth/2 + eps])
      cube([mm_pad_w, mm_pad_h, mm_block_depth], center=true);
    // full-width register slot in the aft face (pylon tongue seats here)
    translate([0, mm_pad_yc, mm_block_aft_z - eps])
      cube([pylon_width+0.4, reg_h+0.4, 2*reg_depth], center=true);
    // item 5 -- 45deg chamfer the block's exposed AFT-OUTER vertical edges so the
    // glued-on-looking pad reads as an integral transom.  Stays in the 3 mm strip
    // outboard of the 44 mm pylon mating footprint (X=+/-22) and clear of the +/-14
    // insert bores; the aft MATING face + the register slot interior stay dead flat.
    if (block_sculpt) for (sx=[-1,1])
      translate([sx*mm_pad_w/2, mm_pad_yc, mm_block_aft_z]) rotate([90,0,0])
        linear_extrude(mm_pad_h + 2*eps, center=true) rotate(45) square(edge_ch*sqrt(2), center=true);
  }
}

// item 5 (cont.) -- concave gusset webs blending each block SIDE into the stern
// wall: spreads the motor moment onto the wall and fairs the junction (looks).
// Vertical (along Y) -> supportless; sits outboard of the block, on the flat wall.
module block_side_gussets() {
  g = block_fil_r;
  for (sx=[-1,1])
    translate([sx*mm_pad_w/2, mm_pad_yc, -H/2]) rotate([90,0,0])
      linear_extrude(mm_pad_h, center=true)
        polygon([[0,0], [sx*g, 0], [0, -g]]);   // right-triangle web onto the wall (X out, Z aft)
}

// item 4 -- interior floor<->wall COVE: a 45deg fillet along the internal floor
// perimeter that stiffens the 2.5 mm wall roots and spreads floor/wall loads.
// Added AFTER the cavity cut (fills the inside corner).  Floor-DOWN it is monotonic
// (cross-section shrinks going up toward the opening) -> supportless.  Kept clear of
// the RC components + the +/-79 boss (cove reaches inner_d..inner_d-cove_leg near the wall).
module floor_cove_mod() {
  difference() {
    translate([0, inner_d - cove_leg, 0]) rprism(inner_w, inner_h, cove_leg + eps, corner_r - wall);
    hull() {   // the remaining void: full opening up high, shrunk by cove_leg at the floor
      translate([0, inner_d - cove_leg - eps, 0]) rprism(inner_w + eps, inner_h + eps, eps, corner_r - wall);
      translate([0, inner_d, 0])
        rprism(inner_w - 2*cove_leg, inner_h - 2*cove_leg, eps, max(0.5, corner_r - wall - cove_leg));
    }
  }
}

// item 7a -- finished FOOT: a 45deg chamfer on the bottom (floor, Y=D bed face)
// outer perimeter edge.  Leaves the central floor field flat for the foam/washer
// and clear of the screw-bore mouths; self-supporting floor-down (brim per DFM).
module foot_chamfer_cut() {
  difference() {
    translate([0, D - edge_ch, 0]) rprism(W + 2, H + 2, edge_ch + eps, corner_r);
    hull() {
      translate([0, D - edge_ch, 0]) rprism(W, H, eps, corner_r);
      translate([0, D - eps, 0]) rprism(W - 2*edge_ch, H - 2*edge_ch, eps, max(0.5, corner_r - edge_ch));
    }
  }
}

module motor_mount_cut() {
  // 4 blind M4 holes into the block aft face; end mm_cavity_margin short of the
  // cavity (item 5).  Axis is model +Z (fore-aft) -> prints HORIZONTAL.  The plain
  // bores (insert / selftap pilot) are ROUND: a heat-set insert is a round brass
  // knurl and wants full-circumference PLA to reflow into (a teardrop would leave
  // an ungripped void above it so the insert seats high/cocked), and at <=5.6 mm a
  // horizontal round bore self-supports fine -- the brass reflows any minor top sag
  // flush (the DFM review makes the same call for the round gland ports).  Only the
  // MODELED thread keeps BOSL2's teardrop crest (td=true; spin=180 puts the apex UP
  // in the floor-down print) so its profile stays accurate without reflow.
  for (sx=[-1,1], sy=[-1,1])
    translate([sx*mm_bolt_x/2, mm_pad_yc + sy*mm_bolt_y/2, mm_block_aft_z - eps]) {
      if (mm_bolt_method=="insert")      cylinder(h=mm_bolt_depth + eps, d=insert_d);      // round heat-set bore
      else if (mm_bolt_method=="thread") tapped_hole(4, 0.7, mm_bolt_depth + eps, mm_bolt_pilot, td=true, spin=180);
      else                               cylinder(h=mm_bolt_depth + eps, d=mm_bolt_pilot); // round thread-forming pilot
    }
}

// =====================================================================
//  SPLASH SEAL  (item 6) -- a real perimeter COMPRESSION gasket on the top rim.
//  The naive "groove in the existing rim" was refuted (only 1.3 mm of flat rim
//  survives inboard of the skirt step, and thinning it eats the lock band).
//  Instead we UNION an inboard LIP that creates NEW sealing land (rim 1.3 +
//  lip -> ~3.8 mm), flush to the Y=0 rim and dropping seal_land_h into the
//  chamber, then cut a flat-bottomed channel into that new land.  GASKET: lay
//  ~1.5 mm adhesive closed-cell foam / PORON weatherstrip TAPE (NOT a 2-3 mm cord)
//  in the seal_groove_d (0.9 mm) channel; it stands ~0.6 mm proud and the flat lid
//  underside compresses it ~40 % while STILL bottoming on the ~0.9 mm flat land
//  strips either side of the groove -- the land is the crush stop, so the
//  0-interference seat + every snap lock are preserved.  Full perimeter, so the
//  compressed tape also clamps the outboard/hinge edge (which the hinge only
//  locates, not clamps down).  Prints floor-down: the lip is a
//  vertical-walled shelf with a flat top + the groove opens UP -> supportless.
//  Watertight: the groove keeps >= (inner wall - seal_land_w) ~= 0.9 mm of PLA
//  to the void laterally and seal_land_h - seal_groove_d below -> probe-checked.
// =====================================================================
module seal_lip() {
  difference() {
    rprism(inner_w, inner_h, seal_land_h, corner_r - wall);                      // fills to the wall inner face
    translate([0,-eps,0]) rprism(inner_w - 2*seal_land_w, inner_h - 2*seal_land_w,
                                 seal_land_h + 2*eps, max(0.5, corner_r - wall - seal_land_w));
  }
}

module seal_groove() {
  midX = ((W/2 - step) + (inner_w/2 - seal_land_w)) / 2;   // centre of the new sealing land, X
  midZ = ((H/2 - step) + (inner_h/2 - seal_land_w)) / 2;   //                                  Z
  translate([0,-eps,0]) difference() {
    rprism(2*(midX + seal_groove_w/2), 2*(midZ + seal_groove_w/2), seal_groove_d + eps, corner_r - wall);
    translate([0,-eps,0])
      rprism(2*(midX - seal_groove_w/2), 2*(midZ - seal_groove_w/2), seal_groove_d + 3*eps, corner_r - wall);
  }
}

// =====================================================================
//  BODY  (the shell -- one difference for all external through-features)
// =====================================================================
module body(role = box_role) {
  difference() {
    union() {
      // shell hollowed FIRST, THEN the interior screw bosses are unioned on top
      // (added after the cavity cut so the cavity does not erase them).
      difference() {
        union() {
          rprism(W, H, D, corner_r);
          hinge_housing();                          // outboard lid hinge
          motor_mount_boss();                       // stern motor pad
          if (block_sculpt) block_side_gussets();   // stern block -> wall gussets (item 5)
        }
        translate([0,-eps,0]) rprism(inner_w, inner_h, inner_d+eps, corner_r-wall); // cavity (top open)
      }
      if (screw_mount) for (p=screw_positions) screw_boss(p);   // solid hold-down bosses on the floor
      if (seal_gasket) seal_lip();                  // inboard gasket land around the top rim (item 6)
      if (floor_cove)  floor_cove_mod();            // interior floor<->wall stiffening cove (item 4)
    }
    // through-features cut through the assembled solid: the screw bores pierce the
    // floor AND the boss together, leaving the sealed cap between bore top and chamber.
    if (screw_mount) for (p=screw_positions) screw_boss_cut(p);
    for (z = gland_set(role)) cable_port_cut(z, port_gland_d); // plain gland holes, THIS hull's role set (Task 3)
    motor_mount_cut();
    xt60_cut();
    front_step_cut();                               // stepped band the lid skirt wraps
    lock_dents();
    if (seal_gasket) seal_groove();                 // foam-cord channel in the new land (item 6)
    if (edge_ch > 0 && foot_chamfer) foot_chamfer_cut(); // finished foot chamfer (item 7a) -- OFF: matches the square block foot + seats flush
  }
}

// standalone render: opening this file renders the BODY (floor down).
oriented("body") apply_side() body();
