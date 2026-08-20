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
//        |   |                   |        # = 3-prong connector, facing UP
//        |   | [H|#|#|N]   [N|#|#|H]      H = head counterbore, opens OUTBOARD
//        +---|-------------------|-----> X  62 mm  (rail to rail)
//            |                   |        N = M5 nut pocket, opens INBOARD
//            o-------------------o            into the 23.3 mm gap
//
//  ORIENTATION -- the one thing to check before printing
//  The bolt grid is 40 mm in Y and 62 mm in X, so the SHORT edges of the
//  plate are the two that run along Y, at X = +/- plate_x/2, and the LONG
//  edges run along X.  Both connectors are YAWED a quarter turn, which puts
//  their hinge axis along X and swings the arms out over the LONG edges --
//  fore-aft on the boat, where the 40 mm axis is one rail's own insert pitch.
//  Turning that back (arms swinging athwartships, over the short edges) is one
//  number: boss_yaw = 0.  Where the two connectors sit is `boss_pos`.
//
//  Two things came free with the quarter turn.  The arms now swing in PARALLEL
//  planes 44 mm apart instead of toward each other, so neither loses its last
//  turn inboard to its neighbour: fitcheck --plate used to read a real
//  arm_simple biting from 160 deg on (514 mm^3 at 180), and now reads the
//  whole 0..180 clear.  That limit was the reason the wide plate carries only
//  one connector.  And the stack that used to run across the 40 mm axis now
//  runs along the 62 mm one, where there is room to spread the connectors out.
//
//  WHICH POCKET FACES WHERE -- and why boss_yaw is a LIST
//  Yawed, each connector's 21.7 mm prong stack lies along X, so the two of
//  them face each other and the two screw pockets are no longer out in open
//  air.  That matters asymmetrically: the nut pocket only ever has a nut
//  pushed into it, but the head counterbore is where a hex key goes, or where
//  a GoPro thumbscrew's 20 mm knob has to turn.  So the counterbores open
//  OUTBOARD, toward their own short edge and open sky, and only the nut
//  pockets face the gap.
//
//  That takes a MIRROR, not a rotation: +90 and -90 give the same hinge axis
//  but swap which prong is which, so boss_yaw is one angle PER CONNECTOR,
//  [90, -90].  Give both the same yaw and one of them turns its counterbore
//  inward; `heads_outboard` is an assert on exactly that, and it fires.
//
//  boss_pos then moves out from +/-18 to +/-22, which is as far as the
//  connectors go before their own pads drag the plate past the bolt pads and
//  it stops being 74 mm long.  It buys the gap: 15.3 mm at 18, 23.3 at 22.
//  The gap is open at the top and at both ends, so a nut goes in from
//  whichever side is convenient rather than having to be threaded down a
//  slot.
//
//  TWO VARIANTS
//    plate      62 x 40 bolt grid, TWO connectors, both yawed a quarter turn
//               so the hinge axis lies along the 62 mm (athwartships) axis
//               -> the arms swing FORE-AFT, out over the long edges.
//    plate155   155 x 40 bolt grid, ONE connector dead centre, turned a
//               quarter turn (wide_yaw = 90) so its hinge axis lies along
//               the long span -> the arm swings FORE-AFT, out over the long
//               edges.  171 x 56 x 8 mm.
//  They are the same module with different arguments.  Everything below --
//  bolt, counterbore, pedestal, disc, both screw pockets, the chamfer --
//  is shared, so the joint is the joint on both.
//
//  Note what the second one is NOT: 155 is not a multiple of the 40 mm
//  rail_pitch and it is not the 62 mm rail gap, so the wide plate does NOT
//  land on boat_enclosure/rail.scad's grid.  It is a 40 x 155 pattern for
//  something else, taken at face value.  If it was meant to straddle the
//  rails, 160 (4 x 40) is the nearest span that lands on them.
//
//  WHY THE SKELETON IS STIFF ENOUGH, AND WHY 5 mm IS
//  Two changes pay for each other here.  The BUTTON head (ISO 7380) bears
//  on the plate FACE, so nothing is recessed and plate_t stops being "deep
//  enough to swallow a socket cap" -- that alone was what set it at 8.  And
//  the slab becomes a SKELETON: one big H.  An upright down each bolt
//  COLUMN, tying that column's two bolts together, and a crossbar along the
//  row the connectors sit on, tying the uprights together and carrying both
//  connectors.  Every corner in it is a right angle.
//  41.8 -> 19.0 cm^3, 55% less, and 3 mm shorter.
//
//  The reason that is not reckless: this plate is not a free beam.  It is
//  BOLTED FLAT to a rail, sandwiched between four bolt heads and the deck,
//  so it works as a spreader.  Push down and the deck takes it; pull up and
//  the bolts take it.  The only real compliance left is the connector tipping
//  under the arm's moment -- fore and aft, about the X axis, now that the
//  arms swing that way -- and what resists that is material reaching out in
//  Y.  The uprights have 52 mm of it, and the connector pad runs out to
//  x = 36.35 while the upright starts at 25, so the two are continuous over
//  11 mm and the moment never has to twist the crossbar to get there.  A
//  GoPro on a 100 mm arm is only ~0.12 Nm.
//
//  What the skeleton DOES give up is the slab's own out-of-plane stiffness
//  (I falls ~19x under the connector), which would matter if the plate ever
//  had to span unsupported.  It does not here.  If it ever has to, the cheap
//  fix is depth, not width: stand a rib proud along each strut.
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
//  nothing has to be held on the far end.  Which prong gets which is set
//  above; the head's is the one facing open air.
//
//  The nut is a PRESS fit here, which is the one number that differs from the
//  arms.  arm.scad opens its trap 0.20 over the 8.00 AF nut and lets the screw
//  hold it; that is fine on an arm, where the trap faces out into free air and
//  a nut that drops out drops into your hand.  On this plate the trap faces
//  into the gap between the connectors and the screw arrives from the far
//  side, so a loose nut is one you have to hold in a slot you cannot see past
//  the arm.  plate_nut_clr = 0.05 makes it 8.05 nominal, and PETG comes out a
//  touch under nominal, so it goes in with thumb pressure and stays.
//  The outermost 0.6 mm of the pocket is flared 0.35 wider and tapers back to
//  size, so the nut enters square instead of racking on the mouth -- a press
//  fit with no lead-in is just a nut you cannot start.
//
//  hd_d 8.80 x hd_depth 5.30,
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
//  BOM per plate: 4x M4 BUTTON-head screw (ISO 7380; length = plate_t +
//  insert depth, so ~12-14 mm into a rail.scad insert -- the head sits
//  proud, there is nothing to recess), plus per
//  connector one M5 DIN 934 nut, PRESSED into the inboard prong from the gap
//  between the connectors, and EITHER a GoPro thumbscrew or a plain M5 socket
//  cap screw, entering from OUTBOARD through the barrel-head counterbore.
//  Same two pockets and the same two fasteners as arm_simple.scad; only the
//  nut's fit and the side each one faces are this file's own.
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
// BUTTON head (ISO 7380), not a socket cap.  A button head bears on the plate
// FACE, so nothing has to be recessed and the plate no longer has to be thick
// enough to swallow a head -- which is what was setting plate_t at 8.  Set
// cbore_h > 0 to go back to a recessed socket cap.
bolt_head_d =  7.6;  // ISO 7380 BUTTON head M4 across; it sits proud, by ~2.2
cbore_d   =  7.5;    // (only used when cbore_h > 0) socket-cap counterbore
cbore_h   =  0;      // 0 = no recess, the head sits on the face

/* [Plate] */
plate_t     = 5.0;   // no head to swallow any more, so this is structure only
edge_margin = 8.0;   // (solid style only) hole centre to plate edge
plate_square = false; // true -> square plate, side = max(long, short).  The
                      // bolt grid is 40 x 62, so the default is a RECTANGLE
                      // sized off that grid; nothing else changes.
corner_r    = 4.0;   // rounded plate corners (vertical edges only)

/* [Frame -- the X-shaped skeleton] */
// A solid slab spends most of its material where nothing is happening.  The
// load path is short and known: each connector pushes into the two bolts
// nearest it, and the connectors lean on each other.  So the plate is built as
// exactly that skeleton -- a pad at every bolt, a pad under every connector, a
// strut from each bolt to its NEAREST connector, and a spine tying consecutive
// connectors.  On the 62 x 40 plate that draws an X with a bar through it.
plate_frame = true;  // false -> the old solid rectangular slab
pad_r       = 6.0;   // bolt pad radius; d12 around a d7.6 button head
rib_hw      = 6.0;   // strut half-width where it lands on a connector
node_margin = 1.5;   // connector pad, out beyond the pedestal's own skirt
node_r      = 4.0;   // corner radius of that pad
top_cham    = 1.0;   // 45 deg break on the TOP edge, all the way round.  Top
                     // only: the bottom stays square so the first layer keeps
                     // its full footprint on the bed.

/* [Connectors] */
// Position of each 3-prong knuckle on the plate top, [x, y].  Two, one
// toward each short edge.  boss_yaw rotates a connector about Z: 0 puts the
// hinge axis along Y (arms swing over the SHORT edges), 90 puts it along X
// (arms swing over the LONG edges -- fore-aft on the boat).
//
// boss_yaw takes ONE angle for all of them, or ONE PER CONNECTOR.  The default
// is per-connector and the two are NOT the same number: +90 and -90 give the
// same hinge axis, but they are mirrors of each other, and that mirror is the
// whole point -- it turns each connector's head counterbore OUTBOARD, toward
// its own short edge, and leaves only the nut pocket facing the gap between
// them.  See "WHICH POCKET FACES WHERE" in the header.
//
// 22 (was 18) is as far out as the connectors go without making the plate any
// bigger: their pads then just reach the bolt pads.  Yawed, the 21.7 mm prong
// stack lies along X, so at 18 the two stacks left a 15.3 mm slot between them
// and at 22 they leave 23.3 -- room to get a nut and a finger in.
boss_pos    = [[-22, 0], [22, 0]];
boss_yaw    = [90, -90];
boss_hw     = 7.50;  // pedestal half-width in X.  MUST be <= tab_r -- at tab_r
                     // the wall is tangent to the disc (smooth, and the whole
                     // block is outside the joint envelope); wider fouls, and
                     // narrower re-opens an overhang under the disc.
boss_riser  = 5.0;   // pedestal height ABOVE the plate before the disc starts.
                     // Ties the prong roots together with a solid web and gets
                     // an M5 thumbscrew knob off the plate.
boss_rim_r  = 1.25;  // quarter-round on the OUTSIDE FACE of each outer prong.
                     // arm_simple.scad's own boss_rim_r, and there for looks.
rim_stn     = 16;    // stations round that quarter
boss_skirt  = 1.5;   // 45 deg fillet skirt where the pedestal meets the plate
slot_sink   = 0.4;   // slot floor, measured BELOW the disc's lowest point
slot_relief = 1.0;   // slot cut is clipped to tab_r + this in X (see header)
plate_nut   = true;  // captive M5 nut in one outer prong, as on the arms
// PRESS fit, which is not what the arms use.  arm.scad opens its trap
// nut_af_clr = 0.20 over the 8.00 AF nut: a slip fit that drops in and is then
// held by the screw.  On the arms the trap faces out into free air, so a nut
// that rattles is a non-event.  Here the trap faces INTO the gap between the
// two connectors and the screw comes at it from the far side, so a loose nut
// falls out of a pocket you cannot reach past the arm to hold.  0.05 puts the
// pocket at 8.05 nominal, and a PETG pocket comes out a touch narrower than
// nominal, so the nut goes in with thumb pressure and stays where it is put.
// Drop to 0 for a harder press; go back to 0.20 for the arms' slip fit.
plate_nut_clr      = 0.05;  // over nut_af (8.00), vs arm.scad's 0.20
// A press fit needs somewhere to START, or the nut sits on the mouth and
// racks.  The outermost plate_nut_lead of the pocket is flared by
// plate_nut_lead_clr at the face and tapers to nominal, so the nut enters
// square and only meets the interference once it is already aligned.
plate_nut_lead     = 0.60;  // funnel length, measured in from the face
plate_nut_lead_clr = 0.35;  // extra across-flats AT the face
// Each connector's head counterbore must face AWAY from the plate centre.
// That is the whole reason boss_yaw is a per-connector list: give both
// connectors the SAME yaw and one of them ends up with its counterbore -- and
// so the hex key, or the thumbscrew's 20 mm knob -- pointing into the gap at
// its neighbour, and only the nut pocket has any business in there.
heads_outboard = true;
plate_head  = true;  // ... and a barrel-head counterbore in the OTHER one, so
                     // an M5 socket cap screw drops in flush from that side --
                     // arm_simple.scad's pairing, same screw, same numbers
knob_d      = 20.0;  // M5 GoPro thumbscrew KNOB diameter -- reporting only,
                     // it sets no geometry.  MEASURE yours; the echo below
                     // says whether it clears the plate at this riser.

/* [The WIDE variant -- part "plate155"] */
// Same 40 mm short-edge spacing, a 155 mm span on the long edge, and ONE
// connector in the middle turned a quarter turn.  See the header.
grid_x_wide = 155.0;   // long-edge bolt spacing for the wide plate
wide_pos    = [[0, 0]];  // one connector, dead centre
wide_yaw    = 90;      // hinge axis along X -> the arm swings FORE-AFT

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

// boss_yaw takes a scalar or one angle per connector; everything downstream
// wants the list.  yaws_of() is used by rail_plate() too, so the gates, the
// frame and the geometry all read the SAME expansion.
function yaws_of(yaw, pos) = is_list(yaw) ? yaw : [for (p = pos) yaw];
boss_yaws = yaws_of(boss_yaw, boss_pos);

// The nut pocket, at this file's own PRESS clearance rather than arm.scad's
// slip clearance -- so gp_nut_profile2d() is a local copy of nut_profile2d()
// with the across-flats passed in instead of read off a global.
p_nut_af  = nut_af + plate_nut_clr;            // 8.05 across flats
p_nut_r   = p_nut_af/sqrt(3);                  // hex circumradius, 4.648
// linear_extrude's `scale` is linear in the extrusion parameter, and the cut
// runs plate_nut_lead + 0.5 (the 0.5 is overshoot into free air past the face,
// so the mouth is cut clean).  Solve the end scale that makes the section at
// the FACE exactly plate_nut_lead_clr oversize; past the face it keeps opening,
// but that is outside the part and removes nothing.
p_nut_lead_h = plate_nut_lead + 0.5;
p_nut_mouth  = 1 + plate_nut_lead_clr/p_nut_af;             // scale at the face
p_nut_lead_s = 1 + (p_nut_mouth - 1)*p_nut_lead_h/plate_nut_lead;

// Head pocket geometry, on its own side's face.
p_hd_face  = p_head_side * (w3_half + boss_hd);        // outboard face
p_hd_floor = p_hd_face - p_head_side * hd_depth;       // where the head seats
// A teardrop's apex stands r/cos(ang) above the axis, not r.
p_hd_top   = p_pivot_z + (hd_d/2)/cos(oh_ang);

// ---------------------------------------------------------- footprints
// What a connector actually OCCUPIES on the plate top, as a box in the plate's
// own frame.  In its local frame the raised footprint is a rectangle -- the
// pedestal, half-width boss_hw, running the length of the prong stack -- and
// `grow` is what stands out beyond it (the 45 deg skirt, and for the frame's
// pad, node_margin on top of that).  Yaw turns it, so this is the corners
// rotated and re-bounded; that is exact at 0 and +/-90 and conservative in
// between, which is the right way round for a clearance gate.
function _rz(v, a) = [v[0]*cos(a) - v[1]*sin(a), v[0]*sin(a) + v[1]*cos(a)];
function conn_box(yaw, grow) =
    let(hx = boss_hw + grow,
        c  = [for (sx = [-hx, hx], sy = [p_y_lo - grow, p_y_hi + grow])
                  _rz([sx, sy], yaw)])
    [[min([for (q = c) q[0]]), min([for (q = c) q[1]])],
     [max([for (q = c) q[0]]), max([for (q = c) q[1]])]];

// Distance from a point to that box once it is parked at `p` -- 0 if inside.
function box_gap(pt, p, b) =
    let(qx = max(p[0] + b[0][0], min(pt[0], p[0] + b[1][0])),
        qy = max(p[1] + b[0][1], min(pt[1], p[1] + b[1][1])))
    norm([pt[0] - qx, pt[1] - qy]);

// ---------------------------------------------------------------- gates
assert(plate_t - cbore_h >= 2.0,
       str("bolt seat only ", plate_t - cbore_h, " mm thick -- raise plate_t ",
           "or drop cbore_h (an M4 head will dish anything thinner)"));
assert(plate_frame || edge_margin >= max(cbore_d, bolt_head_d)/2 + 2.5,
       str("edge_margin ", edge_margin, " leaves ",
           edge_margin - max(cbore_d, bolt_head_d)/2,
           " mm of wall outside the screw head"));
// The bolt pad has to carry the head with wall left over.
assert(!plate_frame || pad_r >= bolt_head_d/2 + 1.5,
       str("pad_r ", pad_r, " leaves only ", pad_r - bolt_head_d/2,
           " mm of pad outside a d", bolt_head_d, " head"));
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
// Nut pocket, if any, has to stay inside the knuckle: its 45 deg peak is the
// highest point (the profile puts flats top and bottom, then a peak on top).
// Measured at the MOUTH scale, not the nominal one -- the lead-in funnel is
// the widest the cut ever gets while it is still inside material, and checking
// the nominal section would pass a funnel whose peak has already broken out.
assert(!plate_nut || p_pivot_z + (p_nut_af/2 + p_nut_r/2)*p_nut_mouth
                     <= p_tab_top - 0.45,
       str("nut pocket peak reaches ",
           p_pivot_z + (p_nut_af/2 + p_nut_r/2)*p_nut_mouth,
           " vs a crown at ", p_tab_top, " -- it breaks out of the knuckle"));
assert(!plate_nut || p_pivot_z - (p_nut_af/2)*p_nut_mouth >= p_slot_z,
       "nut pocket reaches below the slot floor, into the pedestal web");
// A lead-in that runs the whole depth is a taper, not a press fit: there would
// be no parallel length left for the flats to grip.
assert(!plate_nut || (plate_nut_lead > 0 && plate_nut_lead <= nut_depth - 2.0),
       str("plate_nut_lead ", plate_nut_lead, " leaves only ",
           nut_depth - plate_nut_lead, " mm of parallel pocket out of ",
           nut_depth, " -- the nut would seat on a taper, not on the flats"));
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

// The silhouette pulled IN by d -- the section the rim sweep runs through.
//
// The prongs keep their SOLID fillets: each outer prong is thickened over its
// whole length so its pocket has material, and the thickening runs right down
// to the plate.  arm_simple.scad instead puts a dedicated circular boss at the
// pivot, which is lighter and leaves the prong freer to flex -- but that boss's
// underside is a face hanging off a vertical wall, and on a flat supportless
// print there is nothing to hold it up.  arm_simple gets away with it because
// it prints on support.  This does not, so solid it is, and the rounding is
// applied where it costs nothing: the OUTSIDE FACE of each outer prong.
//
// arm_simple rounds its rims by offsetting the profile inward the same way, and
// pays for it there too: its knuckle is tangent to the bed, so shrinking the
// outline lifts the last boss_rim_r off the bed.  Here the outline is extended
// DOWNWARD past the plate before offsetting, so the offset eats that tail
// instead of the bottom.  The rim then stays sitting on the plate at full
// height and the shrink happens only in X and upward -- directions where a
// surface that narrows going out is not an overhang.
module gp_rim_profile2d(d) {
    offset(delta = -d)
        union() {
            gp_boss_profile2d();
            translate([-boss_hw, plate_t - d - 1])
                square([2*boss_hw, d + 1.01]);
        }
}

// One rounded outside face: a quarter turn swept off the end face at `y_end`,
// going inboard in direction `dir`.
module gp_rim(y_end, dir, rr) {
    for (i = [0 : rim_stn - 1]) hull() for (j = [i, i + 1]) {
        a = j/rim_stn * 90;
        translate([0, y_end - dir*rr*(1 - sin(a)), 0]) rotate([90, 0, 0])
            linear_extrude(height = 0.01) gp_rim_profile2d(rr*(1 - cos(a)));
    }
}

// The connector body: ONE prism from p_y_lo to p_y_hi -- the stack and both
// pocket fillets share the same silhouette, so they were always one solid --
// with a quarter-round on each outside face.
module gp_body(y0, y1) {
    rr = min(boss_rim_r, (y1 - y0)/2);
    if (rr > 0) {
        gp_knuckle(y0 + rr, y1 - rr);
        gp_rim(y1,  1, rr);
        gp_rim(y0, -1, rr);
    } else {
        gp_knuckle(y0, y1);
    }
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

// arm.scad's nut_profile2d() with the across-flats passed in instead of read
// off the globals, so this file can cut the SAME shape at its own clearance.
// Flats top and bottom, 45 deg peak on top so the roof does not droop.
module gp_nut_profile2d(af) {
    r = af/sqrt(3);
    union() {
        rotate(0) circle(r = r, $fn = 6);              // vertex on +X
        polygon([[-r/2, af/2], [r/2, af/2], [0, af/2 + r/2]]);
    }
}

// Captive M5 nut in the outer prong -- arm.scad's pocket, moved onto this
// file's pivot and cut at a PRESS clearance instead of a slip one.  Two cuts,
// not one: the pocket proper, parallel from the floor out to the face, and a
// short funnel at the mouth so a nut that has to be pushed still starts square.
// The funnel is cut with 0.5 mm of overshoot past the face, which is the only
// reason it opens wider than plate_nut_lead_clr -- that extra is in free air.
module gp_nut_pocket() {
    if (plate_nut)
        mirror([0, nut_side < 0 ? 0 : 1, 0]) {
            translate([0, -(w3_half + boss_h - nut_depth), p_pivot_z])
                rotate([90, 0, 0])
                    linear_extrude(height = nut_depth) gp_nut_profile2d(p_nut_af);
            translate([0, -(w3_half + boss_h - plate_nut_lead), p_pivot_z])
                rotate([90, 0, 0])
                    linear_extrude(height = p_nut_lead_h, scale = p_nut_lead_s)
                        gp_nut_profile2d(p_nut_af);
        }
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
            // p_y_lo..p_y_hi already accounts for each prong's own pocket
            // fillet (boss_h for the nut, the deeper boss_hd for the head), and
            // the stack and both fillets share one silhouette -- so this is a
            // single rimmed prism rather than three abutting ones.
            gp_body(p_y_lo, p_y_hi);
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
    if (cbore_h > 0)
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
module gp_plate_slab(px, py) {
    hull() {
        linear_extrude(height = plate_t - top_cham)
            rect([px, py], rounding = corner_r);
        translate([0, 0, plate_t - 0.001])
            linear_extrude(height = 0.001)
                rect([px - 2*top_cham, py - 2*top_cham],
                     rounding = max(0.01, corner_r - top_cham));
    }
}

// ---------------------------------------------------------------- frame
// The atom the whole frame is built from: a rectangular bar of plate
// thickness with a 45 deg break on its top rim, all four sides.  Union two of
// them at right angles and the chamfer comes out running along the actual
// outer boundary of the pair: where one bar crosses the other, the crossing
// bar is full height and simply fills its neighbour's chamfer.  So the H comes
// out chamfered all the way round without a single special case.  (It has to
// be done this way round: the frame outline is CONCAVE, so the
// hull-a-shrunk-wafer trick the solid slab uses would fill the concavities
// back in.)
module gp_bar(w, l) {
    cuboid([w, l, plate_t], chamfer = top_cham, edges = TOP, anchor = BOTTOM);
}

// How far the crossbar has to reach either side of the centreline: far enough
// to cover every connector's pad, wherever it sits and however it is turned.
// Symmetric, because half an H is not an H.
function bar_half(pos, yaws) =
    max([for (i = [0 : len(pos) - 1])
            let(b = conn_box(yaws[i], boss_skirt + node_margin))
            max(abs(pos[i][1] + b[0][1]), abs(pos[i][1] + b[1][1]))]);

// The frame: one big H, and every corner in it is a right angle.
//
//        o---------------o        the UPRIGHTS run down each bolt COLUMN,
//        |               |        tying that column's two bolts together
//        |###[C]#####[C]#|   <--- the CROSSBAR runs along the row the
//        |               |        connectors sit on, tying the uprights
//        o---------------o        together and carrying both connectors
//
// The rule it replaces was "every bolt reaches for the connector NEAREST it",
// which drew four diagonal struts -- an X with a bar through it.  That rule
// made sense while the connectors sat inboard at +/-18 and had clear air
// between themselves and the bolts.  It stopped making sense when they moved
// out to +/-22: their pads now overlap the bolt columns outright, so a
// diagonal is a long way round to a place the crossbar already touches.
//
// The H is also the better load path for the way the arms now swing.  Yawed,
// an arm's moment on its connector is about the X axis -- it tips the
// connector fore and aft -- and what resists that is material reaching out in
// Y.  The crossbar has none to give (a moment about its own axis is TORSION on
// a 5 mm plate, which is the weakest thing a flat part does).  The uprights
// have 52 mm of it.  And the connector pad reaches x = 36.35 while the upright
// starts at 25, so the two are continuous over 11 mm: the moment goes straight
// from pad into upright without asking the crossbar to twist at all.
//
// The four inside corners are left sharp, as asked.  Normally a re-entrant
// corner in a loaded plate wants a fillet, because that is where a crack
// starts -- but this plate is a spreader bolted flat between four heads and a
// deck, and the biggest thing it ever sees is a camera on a 100 mm arm, about
// 0.12 Nm.  There is no stress there to concentrate.
module gp_frame(gx, gy, pos, yaws) {
    bar_hw = bar_half(pos, yaws);
    union() {
        for (sx = [-1, 1])
            translate([sx*gx/2, 0, 0]) gp_bar(2*pad_r, gy + 2*pad_r);
        gp_bar(gx + 2*pad_r, 2*bar_hw);
    }
}

// ---------------------------------------------------------------- the part
// Everything the two variants differ in is an argument; everything they share
// -- bolt, counterbore, pedestal, disc, both screw pockets, the chamfer -- is
// the file's own parameters and is therefore literally the same geometry.
// The defaults ARE the globals, so rail_plate() with no arguments is the part
// it always was, byte for byte.
module rail_plate(gx = grid_x, gy = grid_y, pos = boss_pos, yaw = boss_yaw,
                  frame = plate_frame) {
    px = plate_square ? max(gx, gy) + 2*edge_margin : gx + 2*edge_margin;
    py = plate_square ? max(gx, gy) + 2*edge_margin : gy + 2*edge_margin;
    yaws = yaws_of(yaw, pos);
    assert(len(yaws) == len(pos),
           str("boss_yaw has ", len(yaws), " entries for ", len(pos),
               " connector(s) -- give one angle, or one per connector"));
    // A connector must not sit on a bolt, and a driver has to reach every head.
    // Which way it reaches depends on the YAW: unyawed the 21.7 mm prong stack
    // lies along Y and only tab_r of it sticks out in X, yawed it is the other
    // way round.  The old gate tested tab_r on both axes, which is generous on
    // one and blind on the other, so it is the real footprint that is tested
    // here -- the pedestal and its skirt, turned by this connector's own yaw.
    hd = max(cbore_d, bolt_head_d);
    bolts = [for (sx = [-1, 1], sy = [-1, 1]) [sx*gx/2, sy*gy/2]];
    for (i = [0 : len(pos) - 1], b = bolts)
        assert(box_gap(b, pos[i], conn_box(yaws[i], boss_skirt)) >= hd/2 + 1.0,
               str("connector at ", pos[i], " yawed ", yaws[i], " leaves ",
                   box_gap(b, pos[i], conn_box(yaws[i], boss_skirt)) - hd/2,
                   " mm between its skirt and the d", hd, " head at ", b,
                   " -- that bolt cannot be driven"));
    // ... and each head counterbore has to face OUTBOARD.  p_head_side is the
    // head's side in the connector's own frame, so yawing that unit vector
    // says which way the counterbore opens on the plate; it points outboard
    // exactly when it agrees with the connector's own offset from centre.
    // One scalar yaw for both connectors is what this catches: it turns them
    // the same way, so one of the two ends up opening into the gap.
    if (heads_outboard && plate_head && len(pos) > 1)
        for (i = [0 : len(pos) - 1])
            assert(pos[i]*_rz([0, p_head_side], yaws[i]) > 0.001,
                   str("connector at ", pos[i], " yawed ", yaws[i],
                       " opens its head counterbore toward the plate centre",
                       " -- a driver and a thumbscrew knob need open air, so",
                       " that connector wants yaw ", -yaws[i], " instead"));
    difference() {
        union() {
            if (frame) gp_frame(gx, gy, pos, yaws);
            else       gp_plate_slab(px, py);
            for (i = [0 : len(pos) - 1])
                translate([pos[i][0], pos[i][1], 0]) rotate([0, 0, yaws[i]])
                    gp_connector();
        }
        for (sx = [-1, 1], sy = [-1, 1])
            translate([sx*gx/2, sy*gy/2, 0]) gp_bolt_hole();
        // No second pass to cut the slots out of the PLATE, unlike rev 1.
        // The slots now bottom out at p_slot_z, a whole riser above the plate
        // top, so the plate is untouched by them -- which is the point of the
        // pedestal: what is left below each slot is the web tying the three
        // prong roots together.  The assert on p_slot_z guards that.
    }
}

// The WIDE plate: 40 mm across the short edge as before, 155 mm along the
// long one, and a single connector in the middle at a quarter turn.
//
// The yaw is the whole point of the variant.  On the boat the 40 mm direction
// is FORE-AFT (it is one rail's own insert pitch) and the long span is
// athwartships, so the default plate -- hinge axis along the 40 mm axis --
// swings its arms athwartships, out over the short edges.  Turning the
// connector 90 deg puts the hinge axis along the long span instead, and the
// arm then swings FORE-AFT, over the long edges.  Same connector, same
// pockets, same everything; only the plane it articulates in changes.
//
// One connector and not two, so nothing limits the swing but the plate: the
// default plate loses its last 30 deg inboard to its OWN second connector,
// and with a single centred one there is no neighbour to meet.
// NOTE: this one keeps the SOLID slab for now (frame = false).  The skeleton
// rule -- each bolt reaches its nearest connector -- draws a perfectly good
// X-with-a-bar over a 62 mm span, but here it would be four 80 mm legs of
// 12 x 5 section carrying a camera moment at their meeting point, with nothing
// tying their far ends together.  That wants its own truss (a perimeter tie,
// or ribs standing proud), not the same rule stretched twice as far.  It still
// gets the thinner plate and the button head, so it is 40% lighter than rev 3.
module rail_plate155() {
    rail_plate(gx = grid_x_wide, gy = grid_y, pos = wide_pos, yaw = wide_yaw,
               frame = false);
}

// ---------------------------------------------------------------- echo
// Envelope: for the frame it is the bolt pads that USUALLY reach furthest, but
// not necessarily -- a connector moved out far enough drags its own pad past
// them and the plate grows.  So take the max of both, per axis, and the number
// matches the bbox of the exported mesh instead of a nominal that stopped being
// true the moment boss_pos moved.
function env_half(ax) = max(
    plate_frame ? (ax == 0 ? grid_x/2 + pad_r : grid_y/2 + pad_r)
                : (ax == 0 ? plate_x/2 : plate_y/2),
    max([for (i = [0 : len(boss_pos) - 1])
            let(b = conn_box(boss_yaws[i], boss_skirt + node_margin))
            max(abs(boss_pos[i][ax] + b[0][ax]),
                abs(boss_pos[i][ax] + b[1][ax]))]));
env_x = 2*env_half(0);
env_y = 2*env_half(1);

// Clear span between consecutive connectors' prong stacks -- the slot the nut
// has to be dropped into, now that both counterbores open the other way.
function conn_gap(i) =
    (boss_pos[i+1][0] + conn_box(boss_yaws[i+1], 0)[0][0])
  - (boss_pos[i][0]   + conn_box(boss_yaws[i],   0)[1][0]);
echo(str("RAIL PLATE  ", env_x, " x ", env_y, " x ", plate_t, " mm ",
         plate_frame ? "H-FRAME (two uprights + a crossbar)" : "solid slab",
         ", ", len(boss_pos), " connector(s), top of knuckle at ", p_tab_top));
echo(str("  bolt grid ", grid_x, " x ", grid_y, " (rail.scad: 62 mm rail gap, ",
         "40 mm rail_pitch) ; M4 clr ", bolt_d, " ; ",
         cbore_h > 0 ? str("socket cap recessed ", cbore_d, "x", cbore_h,
                           " -> ", plate_t - cbore_h, " mm seat")
                     : str("BUTTON head d", bolt_head_d,
                           " bearing on the face, no recess -> the full ",
                           plate_t, " mm carries it")));
if (plate_frame)
    echo(str("  frame: an H -- ", 2*pad_r, " mm uprights down the bolt columns",
             " at x +/-", grid_x/2, " (", pad_r - bolt_head_d/2,
             " mm of pad outside a d", bolt_head_d, " head), tied by a ",
             2*bar_half(boss_pos, boss_yaws), " mm crossbar on y = 0 that",
             " carries both connectors ; every corner a right angle"));
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
echo(str("  yaw ", boss_yaws, " -> hinge axis along ",
         boss_yaws[0] % 180 == 0 ? "Y (arms swing over the SHORT edges)"
                                 : "X (arms swing over the LONG edges, fore-aft)"));
if (len(boss_pos) > 1)
    echo(str("  the two stacks lie along X and leave ", conn_gap(0),
             " mm of clear slot between them, open top and both sides -- that ",
             "is where the nut goes in ; the counterbores open the OTHER way"));
// Which way each counterbore actually opens, as a coordinate rather than a
// claim: the head face's X, next to the nut face's X.  Head further out.
function face_x(i, side, out) =
    boss_pos[i][0] + out*_rz([0, side], boss_yaws[i])[0];
for (i = [0 : len(boss_pos) - 1])
    echo(str("  connector ", i, " at ", boss_pos[i], " yaw ", boss_yaws[i],
             ": head face at x ", face_x(i, p_head_side, w3_half + boss_hd),
             ", nut face at x ",  face_x(i, p_nut_side,  w3_half + boss_h),
             len(boss_pos) > 1 ? " -> head is OUTBOARD, nut faces the gap"
                               : " -> one connector, no in or out"));
echo(str("  nut trap: ", plate_nut ? str("M5 ", p_nut_af, " AF (", nut_af,
         " nut + ", plate_nut_clr, " -> PRESS fit; arm.scad slips it at ",
         nut_af_clr, "), ", nut_depth, " deep, ", nut_wall,
         " mm to the slot, mouth flared to ", p_nut_af*p_nut_mouth, " over the ",
         "first ", plate_nut_lead, " so it starts square")
         : "none -- bring your own nut"));
echo(str("  head seat: ", plate_head ? str("M5 barrel head d", hd_d, " x ",
         hd_depth, " deep in the ", p_head_side < 0 ? "-Y" : "+Y", " prong (",
         head_cs, " countersink at the bore mouth), teardrop apex ", p_hd_top,
         " vs crown ", p_tab_top) : "none -- the head stands proud"));
echo(str("  stack ", p_y_hi - p_y_lo, " mm wide (", -p_y_lo, " nut side + ",
         p_y_hi, " head side) ; plate top edge chamfered ", top_cham));
echo(str("  WIDE variant (part \"plate155\"): ", grid_x_wide + 2*edge_margin,
         " x ", grid_y + 2*edge_margin, " x ", plate_t, " mm, bolt grid ",
         grid_x_wide, " x ", grid_y, ", ", len(wide_pos),
         " connector at ", wide_pos[0], " yawed ", wide_yaw,
         " deg -> the arm swings FORE-AFT, over the long edges"));

// ---------------------------------------------------------------- preview
if (is_undef(lib_p)) rail_plate();
