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
//  THE CONNECTOR IS A BLOCK WITH A ROUND TOP, NOT A CIRCLE ON A POINT
//  A GoPro knuckle is an R7.5 disc about the pivot, and the mating half
//  is another R7.5 disc about the SAME pivot.  Put that disc straight
//  down onto a plate and it is tangent -- the two touch along a line and
//  the connector necks to nothing at the root.  (rev 1 did exactly that,
//  with only arm.scad's 3.107 mm "pad" hulled underneath to keep the
//  flanks printable.  It looked like a barrel balanced on an edge, and
//  structurally it was one.)
//
//  So the knuckle stands on a PEDESTAL: a plain block, half-width
//  boss_hw, running from the plate top all the way up to the pivot, with
//  the disc sitting on top of it.  The silhouette is a rectangle with a
//  semicircular cap, which is what a real GoPro base looks like, and the
//  footprint is a solid 2*boss_hw x 21.7 mm welded to the plate.
//
//  boss_hw = tab_r is not a styling choice, it is the largest value the
//  joint allows and the only one that is also smooth.  A vertical line at
//  x = tab_r is TANGENT to the disc at pivot height, so:
//    * every point of the block is at least tab_r from the pivot
//      (sqrt(tab_r^2 + dz^2) >= tab_r), and the mating knuckle is a disc
//      of radius tab_r about that same pivot -- so the block is outside
//      the joint envelope at EVERY hinge angle.  Wider would foul.
//    * the disc meets the block tangentially, so the section only ever
//      narrows going up.  No overhang anywhere, and no pad needed.
//  Narrower than tab_r is legal but pointless: it re-opens the overhang
//  the pad existed to patch, which is what the -D boss_hw negative
//  control in verify_plate.py demonstrates.
//
//  boss_riser then lifts the whole disc clear of the plate.  It buys two
//  things: the slots stop inside the pedestal instead of cutting into the
//  plate, so the three prongs are tied together by a solid web at their
//  root; and an M5 thumbscrew KNOB (~20 mm across) turns beside the
//  connector without grounding out on the plate -- at riser 0 the knob
//  would foul, which is reported in the echo below.
//
//  THE TWO SCREW POCKETS
//  Same pairing arm_simple.scad uses, and the same fasteners: a captive
//  M5 nut in one outer prong, a barrel-head counterbore in the other, so
//  a plain M5 socket cap screw drops in flush from the head side and
//  nothing has to be held on the far end.  hd_d 8.80 x hd_depth 5.30,
//  with a 45 deg head_cs relief at the bore mouth so the screw's
//  under-head fillet has somewhere to go and the head bears on a flat
//  annulus rather than on the bore's edge.  Each prong is thickened only
//  as far as its own pocket needs -- boss_h for the nut, the deeper
//  boss_hd for the head -- which is why the stack is not symmetric.
//
//  The one departure: the counterbore is a TEARDROP, where arm_simple
//  uses a plain cylinder.  Identical seat, identical head, but the
//  pocket's ceiling comes to a 45 deg point instead of a round arch.
//  arm_simple prints with support and can afford an arch; this plate is
//  supportless everywhere else and one pocket is not a reason to start.
//  What that costs is height: the apex, not the bore radius, is what has
//  to stay under the crown, and the assert checks the apex.
//
//  AND WHY THE SLOTS ARE CUT SHORT
//  arm.scad's pocket() is a cylinder of pocket_r = 11.05 about the pivot,
//  which reaches 3.55 mm below the disc and would saw the slots straight
//  on down through the pedestal and into the plate.  It is clipped to
//  `slot_sink` below the disc's lowest point instead.  The reasoning is
//  exact rather than a fudge: the mating knuckle never passes tab_r from
//  the pivot, so tab_r from the pivot is the deepest a slot can ever need
//  to be, and everything below that is web holding the prongs together.
//
//  PRINT
//  Flat on the bed, plate down, connectors up.  PETG, 0.2 mm, 0.4 nozzle,
//  NO SUPPORT: the pedestal walls are vertical, the disc meets them
//  tangentially so the section only narrows going up, the M5 bore is a
//  teardrop, the nut pocket has a 45 deg peak, the head counterbore is a
//  teardrop too, and the bolt counterbores open UPWARD (a counterbore
//  that opens up has no ceiling).  The plate's top edge is chamfered and
//  its bottom edge deliberately is not -- a chamfer down there would lift
//  the first layer's perimeter off the bed where the part is widest.  4-5
//  perimeters; the load path is bolt -> plate -> pedestal, all of it in
//  the walls.
//
//  BOM per plate: 4x M4 socket-head cap screw (length = plate_t - cbore_h
//  + insert depth, so ~12-14 mm into a rail.scad insert), plus per
//  connector one M5 DIN 934 nut in the nut prong and EITHER a GoPro
//  thumbscrew (knob outboard of the head seat) or a plain M5 socket cap
//  screw, which drops flush into the barrel-head counterbore opposite the
//  nut and needs nothing held on the far side.  Same two pockets, same two
//  fasteners, as arm_simple.scad.
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
top_cham    = 1.0;   // 45 deg break on the TOP edge, all the way round.  Top
                     // only: the bottom stays square so the first layer keeps
                     // its full footprint on the bed.

/* [Connectors] */
// Position of each 3-prong knuckle on the plate top, [x, y].  Two, one
// toward each short edge.  boss_yaw rotates a connector about Z: 0 puts the
// hinge axis along Y (arms swing over the SHORT edges), 90 puts it along X.
boss_pos    = [[-18, 0], [18, 0]];
boss_yaw    = 0;
boss_hw     = 7.50;  // pedestal half-width in X.  MUST be <= tab_r -- at tab_r
                     // the wall is tangent to the disc (smooth, and the whole
                     // block is outside the joint envelope); wider fouls, and
                     // narrower re-opens an overhang under the disc.
boss_riser  = 5.0;   // pedestal height ABOVE the plate before the disc starts.
                     // Ties the prong roots together with a solid web and gets
                     // an M5 thumbscrew knob off the plate.
boss_skirt  = 1.5;   // 45 deg fillet skirt where the pedestal meets the plate
slot_sink   = 0.4;   // slot floor, measured BELOW the disc's lowest point
slot_relief = 1.0;   // slot cut is clipped to tab_r + this in X (see header)
plate_nut   = true;  // captive M5 nut in one outer prong, as on the arms
plate_head  = true;  // ... and a barrel-head counterbore in the OTHER one, so
                     // an M5 socket cap screw drops in flush from that side --
                     // arm_simple.scad's pairing, same screw, same numbers
knob_d      = 20.0;  // M5 GoPro thumbscrew KNOB diameter -- reporting only,
                     // it sets no geometry.  MEASURE yours; the echo below
                     // says whether it clears the plate at this riser.

// ---------------------------------------------------------------- derived
plate_x = plate_square ? max(grid_x, grid_y) + 2*edge_margin : grid_x + 2*edge_margin;
plate_y = plate_square ? max(grid_x, grid_y) + 2*edge_margin : grid_y + 2*edge_margin;

p_disc_z  = plate_t + boss_riser;     // lowest point of the knuckle disc
p_pivot_z = p_disc_z + tab_r;         // hinge axis, one radius above that
p_tab_top = p_pivot_z + tab_r;        // top of the knuckle
p_slot_z  = p_disc_z - slot_sink;     // slot floor -- still inside the pedestal
p_knob_c  = p_pivot_z - knob_d/2 - plate_t;   // thumbscrew knob over the plate

// Which outer prong carries what.  arm.scad's nut_side is the nut; the barrel
// head goes opposite it, which is arm_simple.scad's pairing exactly.
p_nut_side  = nut_side;          // -1 -> the -Y prong
p_head_side = -nut_side;         // ... so +Y takes the head

// Y span of one connector stack, both bosses included.  boss_h/nut_depth/
// nut_wall/nut_af/nut_r come from arm.scad and hd_d/hd_depth/boss_hd/head_cs
// from arm_simple.scad, so both pockets here are the ones already in service
// on the arms and take the same M5 nut and the same M5 cap screw.
p_y_lo = (plate_nut  && p_nut_side  < 0) ? -w3_half - boss_h
       : (plate_head && p_head_side < 0) ? -w3_half - boss_hd : -w3_half;
p_y_hi = (plate_nut  && p_nut_side  > 0) ?  w3_half + boss_h
       : (plate_head && p_head_side > 0) ?  w3_half + boss_hd :  w3_half;

// Head pocket geometry, on its own side's face.
p_hd_face  = p_head_side * (w3_half + boss_hd);        // outboard face
p_hd_floor = p_hd_face - p_head_side * hd_depth;       // where the head seats
// A teardrop's apex stands r/cos(ang) above the axis, not r.
p_hd_top   = p_pivot_z + (hd_d/2)/cos(oh_ang);

// ---------------------------------------------------------------- gates
assert(plate_t - cbore_h >= 2.0,
       str("bolt seat only ", plate_t - cbore_h, " mm thick -- raise plate_t ",
           "or drop cbore_h (an M4 head will dish anything thinner)"));
assert(edge_margin >= cbore_d/2 + 2.5,
       str("edge_margin ", edge_margin, " leaves ", edge_margin - cbore_d/2,
           " mm of wall outside the counterbore"));
// The pedestal wall is tangent to the disc at boss_hw == tab_r.  Anything
// wider reaches INSIDE the mating knuckle's R7.5 sweep and jams the hinge.
assert(boss_hw <= tab_r,
       str("boss_hw ", boss_hw, " > tab_r ", tab_r, " -- the pedestal would ",
           "reach inside the joint envelope and the hinge would not turn"));
// The slots stop in the pedestal, not in the plate.  If they reach the plate
// top the prongs have lost the web that ties their roots together.
assert(p_slot_z > plate_t + 0.5,
       str("slot floor at ", p_slot_z, " is down on the plate (top ", plate_t,
           ") -- raise boss_riser, the prong roots have nothing tying them"));
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
assert(!plate_nut || p_pivot_z - nut_af/2 >= p_slot_z,
       "nut pocket reaches below the slot floor, into the pedestal web");
// Same two questions for the head pocket.  Its roof is the TEARDROP APEX, not
// the bore radius -- checking the radius would pass a pocket whose point has
// already broken out through the crown.
assert(!plate_head || p_hd_top <= p_tab_top - 0.45,
       str("the head pocket's teardrop apex reaches ", p_hd_top,
           " vs a crown at ", p_tab_top, " -- it breaks out of the knuckle"));
assert(!plate_head || p_pivot_z - hd_d/2 >= p_slot_z,
       "head pocket reaches below the slot floor, into the pedestal web");
// Wall between the head seat and the slot behind it, less what the countersink
// eats out of that same wall.
assert(!plate_head
       || abs(p_hd_floor) - (u + slot_w/2) - head_cs >= 0.8,
       str("only ", abs(p_hd_floor) - (u + slot_w/2) - head_cs,
           " mm of wall left between the head countersink and the slot"));

// ---------------------------------------------------------------- pieces

// Connector silhouette in XZ: a pedestal from the plate top up to the pivot,
// with the R7.5 knuckle disc on top of it.  At boss_hw == tab_r the wall is
// TANGENT to the disc, so this is one smooth outline and not two shapes that
// happen to overlap -- see the header.
module gp_boss_profile2d() {
    union() {
        translate([0, p_pivot_z]) circle(r = tab_r);
        translate([-boss_hw, plate_t]) square([2*boss_hw, p_pivot_z - plate_t]);
    }
}

// That silhouette as a solid spanning y0..y1 (same construction as tab_solid).
module gp_knuckle(y0, y1) {
    translate([0, y1, 0]) rotate([90, 0, 0])
        linear_extrude(height = y1 - y0) gp_boss_profile2d();
}

// A 45 deg skirt around the pedestal root.  Wider at the plate, dying out
// `boss_skirt` up, so it adds material where the bending moment is highest
// and never overhangs.  It sits a whole riser below the disc, so it is far
// outside the joint envelope and cannot touch a mating knuckle.
module gp_skirt(y0, y1) {
    // The lower slab is sunk 1 mm INTO the plate rather than sitting on it.
    // Its top face is where it always was, so the 45 deg flare above the plate
    // is unchanged -- but its bottom face is now buried instead of coplanar
    // with the plate top, and a coplanar face is what the union leaves behind
    // as a zero-area downward sliver.  (The overhang scan found exactly one,
    // nz -1.0 at z = 8.00.  Sinking the slab is the fix; loosening the scan to
    // ignore small facets would have been the bug.)
    if (boss_skirt > 0)
        hull() {
            translate([0, (y0 + y1)/2, plate_t - 0.5])
                cube([2*(boss_hw + boss_skirt), (y1 - y0) + 2*boss_skirt, 1.01],
                     center = true);
            translate([0, (y0 + y1)/2, plate_t + boss_skirt])
                cube([2*boss_hw, y1 - y0, 0.01], center = true);
        }
}

// One slot, clipped so it stops inside the PEDESTAL -- slot_sink below the
// lowest point a mating knuckle can reach -- instead of carrying on down
// through the web and into the plate.
module gp_slot(yc) {
    intersection() {
        translate([0, yc, p_pivot_z])
            cyl(r = pocket_r, h = slot_w, rounding = root_fillet, orient = BACK);
        translate([-(tab_r + slot_relief), yc - (slot_w + 2)/2, p_slot_z])
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

// The barrel-head counterbore, opposite the nut, so an M5 socket cap screw
// drops in flush from that side and needs no tool on the far end.  Same head
// numbers as arm_simple.scad (hd_d 8.80 x hd_depth 5.30), same 45 deg relief
// at the bore mouth so the under-head fillet has somewhere to go and the head
// seats on a flat annulus rather than on the bore's edge.
//
// One thing IS different: the counterbore is a TEARDROP, not the plain
// cylinder arm_simple uses.  Same seat and same head -- the extra material
// above the bore is only air -- but the pocket's ceiling comes to a 45 deg
// point instead of a round arch.  arm_simple prints with support and can
// afford the arch; this plate is supportless everywhere else, and one pocket
// is not a reason to start.
module gp_head_pocket() {
    if (plate_head) {
        translate([0, (p_hd_floor + p_hd_face + p_head_side*0.5)/2, p_pivot_z])
            teardrop(h = hd_depth + 0.5, d = hd_d, ang = oh_ang);
        translate([0, p_hd_floor, p_pivot_z])
            rotate([p_head_side > 0 ? 90 : -90, 0, 0])
                cylinder(d1 = bore_d + 2*head_cs, d2 = bore_d, h = head_cs);
    }
}

// The whole 3-prong connector, built at the origin on top of a plate top at
// z = plate_t.  Slots on +/- u, M5 teardrop bore on the pivot, a captive nut
// in one outer prong and a barrel-head seat in the other.
module gp_connector() {
    difference() {
        union() {
            gp_knuckle(-w3_half, w3_half);
            // Each outer prong is thickened only as far as its own pocket
            // needs -- boss_h for the nut, the deeper boss_hd for the head.
            if (plate_nut && boss_h > 0)
                gp_knuckle(p_nut_side < 0 ? -w3_half - boss_h : w3_half,
                           p_nut_side < 0 ? -w3_half          : w3_half + boss_h);
            if (plate_head && boss_hd > 0)
                gp_knuckle(p_head_side < 0 ? -w3_half - boss_hd : w3_half,
                           p_head_side < 0 ? -w3_half           : w3_half + boss_hd);
            gp_skirt(p_y_lo, p_y_hi);
        }
        bore(0, 6*w3_half, p_pivot_z);
        gp_slot( u);
        gp_slot(-u);
        gp_nut_pocket();
        gp_head_pocket();
    }
}

// M4 clearance + socket-head counterbore.  The counterbore opens UPWARD, so
// its seat is the top of solid material and there is nothing to bridge.
module gp_bolt_hole() {
    translate([0, 0, -1]) cylinder(d = bolt_d, h = plate_t + 2);
    translate([0, 0, plate_t - cbore_h]) cylinder(d = cbore_d, h = cbore_h + 1);
}

// The slab: rounded corners on the vertical edges, and a 45 deg break on the
// TOP edge all the way round.  Built as a hull of the full section and a
// shrunk wafer at the top rather than with cuboid()'s own chamfer, because
// cuboid takes rounding OR chamfer for a given edge set, and the corners want
// rounding while the top edge wants a chamfer.
//
// The bottom edge is deliberately left square.  A chamfer there would lift the
// first layer's perimeter off the bed at the one place the part is widest.
module gp_plate_slab() {
    hull() {
        linear_extrude(height = plate_t - top_cham)
            rect([plate_x, plate_y], rounding = corner_r);
        translate([0, 0, plate_t - 0.001])
            linear_extrude(height = 0.001)
                rect([plate_x - 2*top_cham, plate_y - 2*top_cham],
                     rounding = max(0.01, corner_r - top_cham));
    }
}

// ---------------------------------------------------------------- the part
module rail_plate() {
    difference() {
        union() {
            gp_plate_slab();
            for (p = boss_pos)
                translate([p[0], p[1], 0]) rotate([0, 0, boss_yaw]) gp_connector();
        }
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx*grid_x/2, sy*grid_y/2, 0]) gp_bolt_hole();
        // No second pass to cut the slots out of the PLATE, unlike rev 1.
        // The slots now bottom out at p_slot_z, a whole riser above the plate
        // top, so the plate is untouched by them -- which is the point of the
        // pedestal: what is left below each slot is the web tying the three
        // prong roots together.  The assert on p_slot_z guards that.
    }
}

// ---------------------------------------------------------------- echo
echo(str("RAIL PLATE  ", plate_x, " x ", plate_y, " x ", plate_t,
         " mm, ", len(boss_pos), " connector(s), top of knuckle at ", p_tab_top));
echo(str("  bolt grid ", grid_x, " x ", grid_y, " (rail.scad: 62 mm rail gap, ",
         "40 mm rail_pitch) ; M4 clr ", bolt_d, ", cbore ", cbore_d, "x", cbore_h,
         " -> ", plate_t - cbore_h, " mm seat, ", edge_margin - cbore_d/2,
         " mm wall to the edge"));
echo(str("  connector: pedestal ", 2*boss_hw, " x ", p_y_hi - p_y_lo, " welded to ",
         "the plate, up ", p_pivot_z - plate_t, " to the pivot at ", p_pivot_z,
         " ; disc starts ", boss_riser, " above the plate, tangent to the wall ",
         boss_hw == tab_r ? "(smooth, no overhang)" : " << boss_hw != tab_r"));
echo(str("  slots: 2 x ", slot_w, " on +/-", u, ", floor ", p_slot_z, " = ",
         slot_sink, " under the disc and ", p_slot_z - plate_t,
         " ABOVE the plate -> that much web tying the prong roots ; prongs ",
         w3_half - (u + slot_w/2), " / ", 2*(u - slot_w/2), " / ",
         w3_half - (u + slot_w/2), " thick (outer / centre / outer)"));
echo(str("  M5 bore d", bore_d, " ; thumbscrew knob d", knob_d, " clears the ",
         "plate by ", p_knob_c, " mm ",
         p_knob_c >= 0 ? "OK" : " << raise boss_riser or the knob grounds out"));
echo(str("  hinge axis along ", boss_yaw == 0 ? "Y (arms swing over the SHORT edges)"
                                              : "X (arms swing over the LONG edges)"));
echo(str("  nut trap: ", plate_nut ? str("M5 ", nut_af, " AF, ", nut_depth,
         " deep in the ", p_nut_side < 0 ? "-Y" : "+Y", " prong, ", nut_wall,
         " mm to the slot") : "none -- bring your own nut"));
echo(str("  head seat: ", plate_head ? str("M5 barrel head d", hd_d, " x ",
         hd_depth, " deep in the ", p_head_side < 0 ? "-Y" : "+Y", " prong (",
         head_cs, " countersink at the bore mouth), teardrop apex ", p_hd_top,
         " vs crown ", p_tab_top) : "none -- the head stands proud"));
echo(str("  stack ", p_y_hi - p_y_lo, " mm wide (", -p_y_lo, " nut side + ",
         p_y_hi, " head side) ; plate top edge chamfered ", top_cham));

// ---------------------------------------------------------------- preview
if (is_undef(lib_p)) rail_plate();
