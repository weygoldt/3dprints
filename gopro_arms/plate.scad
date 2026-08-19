// =====================================================================
//  GoPro RAIL PLATE -- a flat base that bolts onto the boat's M4 rail
//  grid and stands a GoPro 3-prong connector at each end.
//
//  WHAT IT IS FOR
//  The airboat's decks carry mounting rails (boat_enclosure/rail.scad):
//  a row of M4 brass heat-set inserts at rail_pitch = 40 mm along each
//  rail, and the two rails of a line stand 62 mm apart.  Everything that
//  rides on the boat bolts DOWN THROUGH its own feet into those inserts.
//  This plate is the smallest thing that can do that and still present a
//  GoPro joint: a 4-bolt footprint on the 40 x 62 grid, and on top of it
//  the same 3-prong knuckle the arms carry, so anything in this folder --
//  arm, arm_simple, arm_double, twist, buckle -- clips straight on.
//
//        Y  40 mm  (along one rail; = rail_pitch)
//        ^
//        |   o-------------------o        o = M4 bolt into a rail insert
//        |   |   ###       ###   |        # = 3-prong connector, facing UP
//        +---|---###-------###---|-----> X  62 mm  (rail to rail)
//            |   ###       ###   |
//            o-------------------o
//
//  ORIENTATION -- the one thing to check before printing
//  The bolt grid is 40 mm in Y and 62 mm in X, so the SHORT edges of the
//  plate are the two that run along Y, at X = +/- plate_x/2.  The
//  connectors' hinge axis runs along Y, PARALLEL to those short edges,
//  which is what makes an arm swing out OVER a short edge -- prongs
//  facing the short edge, as asked for.  Turning that 90 deg (arms
//  swinging out over the LONG edges instead) is one number: boss_yaw = 90.
//  Where the two connectors sit is `boss_pos`, also just a list.
//
//  WHY THE PIVOT SITS A FULL RADIUS UP
//  arm.scad's own knuckles use tab_style = "trim": the pivot at
//  tab_r/sqrt(2), the R7.5 circle simply CUT by the bed.  That is right
//  for an arm, whose mating half is another arm sitting on the same
//  centreline.  It is WRONG here.  A mating arm's knuckle is a full R7.5
//  disc about the shared pivot, and it has to be able to swing all the
//  way down onto the plate -- so the pivot has to stand a full tab_r
//  above the plate top, exactly like a real GoPro adhesive base.  That
//  leaves the circle TANGENT to the plate, i.e. a 0 deg overhang at the
//  root, so the knuckle gets arm.scad's "pad" treatment: hulled onto a
//  thin bar of half-width tab_base_h_at(tab_r) = 3.107, which makes the
//  flanks leave the plate at exactly oh_ang.  That pad pokes ~0.6 mm
//  outside the R7.5 joint envelope -- harmless HERE, and provably so:
//  every point of it is FARTHER from the pivot than tab_r, and the
//  mating knuckle is a disc of radius tab_r about that same pivot, so it
//  can never reach the pad at any angle.  (On an arm the same pad is a
//  problem, because there the mating BODY sweeps past at that radius.)
//
//  AND WHY THE SLOTS ARE CUT SHORT
//  arm.scad's pocket() is a cylinder of pocket_r = 11.05 about the pivot.
//  Placed on a pivot a full tab_r up, its bottom would reach 3.55 mm
//  BELOW the plate top and saw two 3.1 mm slots most of the way through
//  the plate.  So the pocket is clipped to `slot_sink` below the plate
//  top: the mating knuckle only ever reaches tab_r from the pivot, and
//  tab_r from the pivot IS the plate top, so a shallow relief is all the
//  clearance that geometry can ever need.  What is left in the plate is
//  a ~0.4 x 3.1 x 16 mm groove under each slot, which also drains.
//
//  PRINT
//  Flat on the bed, plate down, connectors up.  PETG, 0.2 mm, 0.4 nozzle,
//  NO SUPPORT: the knuckle flanks leave the plate at oh_ang, the M5 bore
//  is a teardrop, the nut pocket has a 45 deg peak, and the bolt
//  counterbores open UPWARD (a counterbore that opens up has no ceiling).
//  4-5 perimeters; the load path is bolt -> plate -> knuckle root, all of
//  it in the walls.
//
//  BOM per plate: 4x M4 socket-head cap screw (length = plate_t - cbore_h
//  + insert depth, so ~12-14 mm into a rail.scad insert), plus one M5
//  GoPro thumbscrew and one M5 DIN 934 nut per connector.
// =====================================================================

// This file is the OUTERMOST link of the project's single include chain:
//   plate -> twist -> buckle -> arm_simple -> arm  (+ BOSL2, at the far end)
// OpenSCAD's include is textual and has no include-once, so there must be
// exactly ONE path to arm.scad; anything that wants this file's modules
// includes THIS file and sets lib_p, rather than opening a second path.
lib_t = true;
include <twist.scad>

// ---------------------------------------------------------------- params

/* [Bolt pattern -- boat_enclosure/rail.scad] */
// 40 mm is rail.scad's rail_pitch (one rail's insert spacing); 62 mm is the
// gap between the two rails of a line (the box lugs sit at X = +/- 31).
grid_x    = 62.0;    // rail-to-rail  -> the plate's LONG axis
grid_y    = 40.0;    // along a rail  -> the plate's SHORT axis
bolt_d    =  4.5;    // M4 clearance through the plate
cbore_d   =  7.5;    // M4 socket-head counterbore (DIN 912 head is 7.0)
cbore_h   =  4.4;    // counterbore depth; head is 4.0 tall -> 0.4 below flush

/* [Plate] */
plate_t     = 8.0;   // >= cbore_h + a seat the head can actually pull against
edge_margin = 8.0;   // hole centre to plate edge -> cbore leaves 4.25 of wall
plate_square = false; // true -> square plate, side = max(long, short).  The
                      // bolt grid is 40 x 62, so the default is a RECTANGLE
                      // sized off that grid; nothing else changes.
corner_r    = 4.0;   // rounded plate corners (vertical edges only)

/* [Connectors] */
// Position of each 3-prong knuckle on the plate top, [x, y].  Two, one
// toward each short edge.  boss_yaw rotates a connector about Z: 0 puts the
// hinge axis along Y (arms swing over the SHORT edges), 90 puts it along X.
boss_pos    = [[-18, 0], [18, 0]];
boss_yaw    = 0;
boss_skirt  = 1.5;   // 45 deg fillet skirt where the knuckle meets the plate
slot_sink   = 0.4;   // how far the slot floor drops below the plate top
slot_relief = 1.0;   // slot cut is clipped to tab_r + this in X (see header)
plate_nut   = true;  // captive M5 nut in one outer prong, as on the arms

// ---------------------------------------------------------------- derived
plate_x = plate_square ? max(grid_x, grid_y) + 2*edge_margin : grid_x + 2*edge_margin;
plate_y = plate_square ? max(grid_x, grid_y) + 2*edge_margin : grid_y + 2*edge_margin;

p_pivot_z = plate_t + tab_r;          // knuckle circle TANGENT to the plate top
p_tab_top = p_pivot_z + tab_r;        // top of the knuckle
p_pad_h   = tab_base_h_at(tab_r);     // 3.107 -- pad half-width for oh_ang flanks

// Y span of one connector stack, nut boss included (boss_h/nut_side/nut_depth/
// nut_wall/nut_af/nut_r all come from arm.scad, so the trap here is the same
// trap the arms use and takes the same nut).
p_y_lo = (plate_nut && nut_side < 0) ? -w3_half - boss_h : -w3_half;
p_y_hi = (plate_nut && nut_side > 0) ?  w3_half + boss_h :  w3_half;

// ---------------------------------------------------------------- gates
assert(plate_t - cbore_h >= 2.0,
       str("bolt seat only ", plate_t - cbore_h, " mm thick -- raise plate_t ",
           "or drop cbore_h (an M4 head will dish anything thinner)"));
assert(edge_margin >= cbore_d/2 + 2.5,
       str("edge_margin ", edge_margin, " leaves ", edge_margin - cbore_d/2,
           " mm of wall outside the counterbore"));
assert(slot_sink < plate_t - 1.0, "slot_sink is eating the plate");
// The knuckle must not reach a counterbore.  Its widest point is tab_r from
// the pivot, at pivot height; the counterbore's inner edge is cbore_d/2 in.
for (p = boss_pos)
    assert(abs(abs(p[0]) - grid_x/2) - tab_r - cbore_d/2 >= 1.0
        || abs(abs(p[1]) - grid_y/2) - tab_r - cbore_d/2 >= 1.0,
           str("connector at ", p, " runs into a bolt counterbore"));
// Nut pocket, if any, has to stay inside the knuckle: its 45 deg peak is the
// highest point (nut_profile2d puts flats top and bottom, then a peak on top).
assert(!plate_nut || p_pivot_z + nut_af/2 + nut_r/2 <= p_tab_top - 0.45,
       "nut pocket breaks out of the top of the knuckle");
assert(!plate_nut || p_pivot_z - nut_af/2 >= plate_t + 1.5,
       "nut pocket reaches down into the plate");

// ---------------------------------------------------------------- pieces

// Knuckle silhouette in XZ, sitting ON the plate top.  This is arm.scad's
// "pad" branch with the pivot a full tab_r up -- see the header for why the
// file's own "trim" style cannot be used here.
module gp_pad_profile2d() {
    hull() {
        translate([0, p_pivot_z]) circle(r = tab_r);
        translate([0, plate_t + 0.005]) square([2*p_pad_h, 0.01], center = true);
    }
}

// That silhouette as a solid spanning y0..y1 (same construction as tab_solid).
module gp_knuckle(y0, y1) {
    translate([0, y1, 0]) rotate([90, 0, 0])
        linear_extrude(height = y1 - y0) gp_pad_profile2d();
}

// A 45 deg skirt around the knuckle root.  Wider at the plate, dying out
// `boss_skirt` up, so it adds material where the bending moment is highest
// and never overhangs.  Every exposed point of it is farther from the pivot
// than tab_r (at z = plate_t it is sqrt((p_pad_h+s)^2 + tab_r^2) away), so
// like the pad it cannot touch a mating knuckle.
module gp_skirt(y0, y1) {
    if (boss_skirt > 0)
        hull() {
            translate([0, (y0 + y1)/2, plate_t + 0.005])
                cube([2*(p_pad_h + boss_skirt), (y1 - y0) + 2*boss_skirt, 0.01],
                     center = true);
            translate([0, (y0 + y1)/2, plate_t + boss_skirt])
                cube([2*p_pad_h, y1 - y0, 0.01], center = true);
        }
}

// One slot, clipped so it stops at the plate instead of sawing through it.
module gp_slot(yc) {
    intersection() {
        translate([0, yc, p_pivot_z])
            cyl(r = pocket_r, h = slot_w, rounding = root_fillet, orient = BACK);
        translate([-(tab_r + slot_relief), yc - (slot_w + 2)/2, plate_t - slot_sink])
            cube([2*(tab_r + slot_relief), slot_w + 2, 8*tab_r]);
    }
}

// Captive M5 nut in the outer prong -- arm.scad's pocket, moved onto this
// file's pivot.  Opens on the outboard face, flats top and bottom, 45 deg
// peak so the roof does not droop into the slot.
module gp_nut_pocket() {
    if (plate_nut)
        mirror([0, nut_side < 0 ? 0 : 1, 0])
            translate([0, -(w3_half + boss_h - nut_depth), p_pivot_z])
                rotate([90, 0, 0])
                    linear_extrude(height = nut_depth + 0.5) nut_profile2d();
}

// The whole 3-prong connector, built at the origin on top of a plate top at
// z = plate_t.  Slots on +/- u, M5 teardrop bore on the pivot.
module gp_connector() {
    difference() {
        union() {
            gp_knuckle(-w3_half, w3_half);
            if (plate_nut && boss_h > 0)
                gp_knuckle(nut_side < 0 ? -w3_half - boss_h : w3_half,
                           nut_side < 0 ? -w3_half          : w3_half + boss_h);
            gp_skirt(p_y_lo, p_y_hi);
        }
        bore(0, 6*w3_half, p_pivot_z);
        gp_slot( u);
        gp_slot(-u);
        gp_nut_pocket();
    }
}

// M4 clearance + socket-head counterbore.  The counterbore opens UPWARD, so
// its seat is the top of solid material and there is nothing to bridge.
module gp_bolt_hole() {
    translate([0, 0, -1]) cylinder(d = bolt_d, h = plate_t + 2);
    translate([0, 0, plate_t - cbore_h]) cylinder(d = cbore_d, h = cbore_h + 1);
}

// ---------------------------------------------------------------- the part
module rail_plate() {
    difference() {
        union() {
            cuboid([plate_x, plate_y, plate_t],
                   rounding = corner_r, edges = "Z", anchor = BOTTOM);
            for (p = boss_pos)
                translate([p[0], p[1], 0]) rotate([0, 0, boss_yaw]) gp_connector();
        }
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx*grid_x/2, sy*grid_y/2, 0]) gp_bolt_hole();
        // The slots have to be cut AFTER the plate too: a connector's own
        // difference() only sees its own solid, and the groove under each
        // slot lives in the plate.
        for (p = boss_pos)
            translate([p[0], p[1], 0]) rotate([0, 0, boss_yaw]) {
                gp_slot( u);
                gp_slot(-u);
            }
    }
}

// ---------------------------------------------------------------- echo
echo(str("RAIL PLATE  ", plate_x, " x ", plate_y, " x ", plate_t,
         " mm, ", len(boss_pos), " connector(s), top of knuckle at ", p_tab_top));
echo(str("  bolt grid ", grid_x, " x ", grid_y, " (rail.scad: 62 mm rail gap, ",
         "40 mm rail_pitch) ; M4 clr ", bolt_d, ", cbore ", cbore_d, "x", cbore_h,
         " -> ", plate_t - cbore_h, " mm seat, ", edge_margin - cbore_d/2,
         " mm wall to the edge"));
echo(str("  connector: pivot ", tab_r, " above the plate (circle TANGENT), pad ",
         p_pad_h, " half-width -> flanks at ", oh_ang, " deg ; stack y ",
         p_y_lo, "..", p_y_hi, " (", p_y_hi - p_y_lo, " mm), M5 bore d", bore_d));
echo(str("  slots: 2 x ", slot_w, " on +/-", u, ", floor ", slot_sink,
         " below the plate top ; prongs ",
         w3_half - (u + slot_w/2), " / ", 2*(u - slot_w/2), " / ",
         w3_half - (u + slot_w/2), " thick (outer / centre / outer)"));
echo(str("  hinge axis along ", boss_yaw == 0 ? "Y (arms swing over the SHORT edges)"
                                              : "X (arms swing over the LONG edges)"));
echo(str("  nut trap: ", plate_nut ? str("M5 ", nut_af, " AF, ", nut_depth,
         " deep in the ", nut_side < 0 ? "-Y" : "+Y", " prong, ", nut_wall,
         " mm to the slot") : "none -- bring your own nut"));

// ---------------------------------------------------------------- preview
if (is_undef(lib_p)) rail_plate();
