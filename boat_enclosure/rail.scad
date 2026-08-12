// =====================================================================
//  AIRBOAT ENCLOSURE -- MOUNTING RAIL  (segmented, dovetail-chained, M4 heat-set)
//  Part of the airboat catamaran mounting system.  See common.scad for the box
//  frame mapping, all box parameters, and the shared BOSL2 includes.
//
//  WHAT IT IS
//    A constant-section rail that drops FLUSH into a straight slot cut in the XPS
//    deck board and lets you bolt each enclosure down and slide it fore/aft on a
//    40 mm grid to trim the float's balance.  A row of M4 brass heat-set inserts
//    runs the length at rail_pitch (40 mm).  The box sits on the board; an M4
//    socket-head cap screw drops through each box corner-lug from ABOVE and threads
//    into a rail insert.  Two rails (62 mm apart -- the box's X=+/-31 bolt spacing)
//    carry one box line; the boat needs 4 rails (2 per skid, 2 boxes per skid).
//
//  CONSTANT CROSS-SECTION  (so the slot is a simple, constant channel)
//    The whole bar is a plain rail_w x rail_h prism -- SAME width and height
//    everywhere -- because it is embedded in a slot routed/cut in foam, and a
//    variable-width or variable-depth slot is very hard to cut.  The dovetail end
//    joints are inset features (a tang / a socket): they do NOT change the outer
//    envelope, so the slot stays constant.  Cut the slot rail_w (+ slot_clear for a
//    slip fit) wide and rail_h deep -> the rail top sits flush with the board, so
//    the box seats at deck level (NO change to CG / prop clearance) and the box
//    floor caps the slot, holding the rail down.  Glue (epoxy/PU) backs it up.
//
//  WHY 40 mm / 200 mm
//    Each box has 4 hold-down bolts at X=+/-31, Z=+/-100 (common.scad corner lugs):
//    200 mm fore/aft between a box's two bolts on one rail.  200 mm = 5 x 40 mm, so
//    a box lands on ANY hole pair, and end_margin = 20 (half a pitch) keeps the
//    40 mm grid continuous straight across a dovetail joint.  Slide either box to
//    any hole to shift the load and balance the hull.
//
//  SEGMENTED + DOVETAILED
//    A 50 cm rail won't fit the bed.  Each printable SEGMENT is seg_holes long
//    (default 4 -> 160 mm) with a BOSL2 dovetail(): a MALE tang on the +X end, a
//    matching FEMALE socket on the -X end.  Identical segments chain end-to-end
//    (drop the next segment straight DOWN onto the previous tang -- the flare locks
//    fore/aft pull-apart and lateral wander; assembly is vertical only, which suits
//    an open-topped slot).  3 segments ~= 480 mm ~= the 50 cm run.  dovetail_on=false
//    leaves plain butt ends if you'd rather cut the joint in the slicer.
//
//  HOLD-DOWN (supersedes the old corner_mount through-foam bolt)
//    The box KEEPS its corner lugs, but instead of a bolt UP through 60 mm of foam
//    into a captive nut, an M4 cap screw drops DOWN through the lug into the rail
//    insert.  For a first test THIS NEEDS NO BOX CHANGE: the lug's top hex pocket
//    (7.2 AF x 3.6) accepts a DIN912 M4 socket-head cap (7.0 dia, ~0.4 mm proud);
//    a hex head would jam in the hex, a button head won't fit -- socket-cap only.
//    Tidy follow-up: re-cut that pocket as a round 7.5 x >=4.2 counterbore (flush).
//
//  PRINTS BASE-DOWN, SUPPORTLESS.  Long + narrow -> add a brim.  PETG or PLA.
//  Requires BOSL2 (../BOSL2) -- std+threading via common.scad, joiners here.
// =====================================================================
include <common.scad>
include <../BOSL2/joiners.scad>   // dovetail() -- std.scad omits joiners

$fn = 64;

/* [What to render] */
rail   = "segment";  // [segment, pair, strip, seated] segment=one printable segment; pair=two chained (joint proof); strip=rail_n on a plate; seated=one segment dropped in a foam-slot stub (preview)
rail_n = 3;          // strip / full-rail count: copies for one plate (a full ~480 mm rail = 3)

/* [Grid -- matches the box hold-down bolt pattern] */
seg_holes  = 4;      // M4 insert holes per segment (4 -> 160 mm; 3 segments ~= 480 mm ~= the 50 cm run)
rail_pitch = 40;     // insert spacing (mm).  Box bolt span 200 mm (Z=+/-100) = 5 pitches -> lands on any hole pair
end_margin = 20;     // first/last hole this far from the butt plane; = pitch/2 keeps the grid continuous across a joint
                     // (M4 screw + insert diameters come from common.scad: insert_d, insert_od)

/* [Cross-section -- CONSTANT everywhere (embeds in a straight slot)] */
rail_w   = 14;       // constant width (X-perp) = slot width.  >=12 for the M4 insert boss; extra -> dovetail-socket walls
rail_h   = 10;       // constant height = slot depth for a flush top.  >= ~8 mm insert + a little (user spec: 1 cm)
edge_r   = 1.0;      // round on the vertical edges (finish + eases dropping into the slot; supportless)

/* [Heat-set inserts -- M4, from common.scad] */
insert_bore    = insert_d;  // 5.6 mm heat-set hole for M4 brass (common.scad; MEASURE yours)
insert_through = true;      // true: bore through (bolt tip exits into the foam below, forgiving of screw length)
                            // false: blind bore insert_deep from the top (leaves a floor -> a hard screw stop)
insert_deep    = 9;         // blind-bore depth from the top when insert_through=false (insert ~8 + lead)
insert_cham    = 0.6;       // lead-in chamfer at the bore mouth (eases the heat-set start)

/* [Dovetail joint -- BOSL2] */
dovetail_on = true;  // BOSL2 male+female dovetail on the segment ends; false -> plain butt ends
dt_w      = 9;       // dovetail flare width (the wide, locking end).  rail_w - dt_w = socket wall (2 x ~2.5 mm)
dt_proj   = 8;       // how far the male tang projects past the butt plane (adds to the printed length, inset in the slot)
dt_slope  = 6;       // BOSL2 standard woodworking slope (6); shallower = more aggressive lock
dt_chamfer = 0.6;    // corner chamfer -> printed parts mate without corner interference
dt_slop   = 0.15;    // $slop clearance added to the FEMALE socket (tune to your printer; 0.1-0.2 typical)

/* [Slot -- the XPS channel the rail drops into (for the 'seated' preview / your reference)] */
slot_clear = 0.3;    // cut the slot rail_w + this wide for a slip fit; 0 = friction/glue press fit.  Depth = rail_h (flush)

// ---- derived ----
eps = 0.01;
seg_len   = seg_holes * rail_pitch;                                   // butt-plane to butt-plane
hole_xs   = [ for (i=[0:seg_holes-1]) -seg_len/2 + end_margin + i*rail_pitch ];
bore_h    = insert_through ? rail_h + 2*eps : insert_deep + eps;
bore_z    = insert_through ? -eps : rail_h - insert_deep;             // bore start Z (through from below, or blind from top)
sock_wall = (rail_w - dt_w)/2;                                        // PLA each side of the female socket at its widest
boss_wall = (rail_w - insert_bore)/2;                                 // PLA around each insert (constant bar -> same everywhere)
printed_len = seg_len + (dovetail_on ? dt_proj : 0);                  // male tang adds to the X extent
full_len  = rail_n * seg_len;                                         // assembled rail (butts meet)
full_holes= rail_n * seg_holes;

// =====================================================================
//  ONE SEGMENT  (built in PRINT pose: flat bottom on the bed at z=0, length along X)
//   male dovetail on +X (RIGHT), female socket on -X (LEFT) -> identical segments chain
// =====================================================================
module rail_segment() {
  diff() {
    // constant-section bar (same W x H everywhere -> a constant slot)
    cuboid([seg_len, rail_w, rail_h], anchor=BOTTOM, rounding=edge_r, edges="Z") {
      if (dovetail_on) {
        attach(RIGHT) dovetail("male", slide=rail_h, width=dt_w, height=dt_proj,
                               slope=dt_slope, chamfer=dt_chamfer);
        tag("remove")
          attach(LEFT) dovetail("female", slide=rail_h, width=dt_w, height=dt_proj,
                                slope=dt_slope, chamfer=dt_chamfer, $slop=dt_slop);
      }
    }
    // insert bores from the top + a lead-in chamfer at each mouth
    for (x = hole_xs) {
      tag("remove") translate([x, 0, bore_z]) cylinder(h=bore_h, d=insert_bore);
      tag("remove") translate([x, 0, rail_h - insert_cham]) cylinder(h=insert_cham + eps, d1=insert_bore, d2=insert_bore + 2*insert_cham);
    }
  }
}

// translucent foam-slot stub for the 'seated' preview (NOT printed)
module slot_stub() {
  bw = rail_w + slot_clear;
  color([0.85, 0.82, 0.70, 0.35]) difference() {
    translate([0, 0, rail_h/2]) cube([seg_len + 40, bw + 40, rail_h], center=true);           // board, top flush at z=rail_h
    translate([0, 0, rail_h/2 + eps]) cube([seg_len + 60, bw, rail_h + 2*eps], center=true);   // the slot
  }
}

// =====================================================================
//  ECHO FIT-CHECK  (house style: the number and the bar it must clear)
// =====================================================================
echo("=== AIRBOAT MOUNTING RAIL ===");
echo(str("  grid: ", seg_holes, " M4 holes/segment @ ", rail_pitch, " mm pitch ; segment ", seg_len,
         " mm ; ", rail_n, " chained = ", full_len, " mm, ", full_holes, " holes (target ~500)"));
echo(str("  box match: bolts at X=+/-31 (=> two rails 62 mm apart), Z=+/-100 (200 mm = ", 200/rail_pitch,
         " pitches) ", (200 % rail_pitch == 0) ? "OK -- box lands on a hole pair" : " << 200 not a multiple of pitch!"));
echo(str("  grid continuity: end_margin ", end_margin, " vs pitch/2 ", rail_pitch/2, " ",
         end_margin == rail_pitch/2 ? "OK -- 40 mm continues across the joint" : " << set end_margin = pitch/2"));
// two boxes per rail (2 front / 2 back layout): each box = a 200 mm bolt pair + a ~214 mm footprint
// (body 186 + both end blocks).  MEASURE/confirm; drives whether both boxes fit + how much slide is left.
box_fp = 214;
two_box_play = full_len - 2*box_fp;
echo(str("  two boxes/rail: ", full_holes, " holes hold two 200 mm bolt pairs; two ~", box_fp,
         " mm boxes leave ~", round(two_box_play), " mm combined fore/aft play for balancing ",
         two_box_play >= 0 ? "OK" : str(" << ", full_len, " mm rail is short for two ", box_fp,
                                        " mm boxes -- add a segment (rail_n) or shorten the boxes")));
echo(str("  section (CONSTANT): ", rail_w, "(W) x ", rail_h, "(H) everywhere -> slot ", rail_w + slot_clear,
         " wide x ", rail_h, " deep (flush top).  insert boss wall ", boss_wall, " mm vs >= (2*insert_od-insert_bore)/2 ",
         (2*insert_od-insert_bore)/2, " ", rail_w >= 2*insert_od ? "OK" : " << widen rail_w for insert grip"));
echo(str("  insert: bore d", insert_bore, (insert_through?" THROUGH":str(" blind ",insert_deep," deep")),
         " ; seat rail_h ", rail_h, " vs ~8 mm insert ", rail_h >= 8 ? "OK" : " << raise rail_h"));
if (dovetail_on)
  echo(str("  dovetail: flare ", dt_w, " / proj ", dt_proj, " / slope ", dt_slope, " / $slop ", dt_slop,
           " ; socket wall ", sock_wall, " mm ", sock_wall >= 2 ? "OK" : " << thin: lower dt_w or raise rail_w"));
echo(str("  printed extent: ", printed_len, "(X) x ", rail_w, "(Y) x ", rail_h, "(Z) on a 250x210 bed ",
         (printed_len <= 250 && rail_w <= 210) ? "fits (length along the 250 axis)" :
         " << too long: lower seg_holes"));
vol_solid = seg_len * rail_w * rail_h - seg_holes*PI/4*insert_bore*insert_bore*rail_h;
echo(str("  material ~", round(vol_solid/1000), " cm^3/segment (~", round(vol_solid*1.24/1000),
         " g PLA @100%); constant section is required for the slot, so it can't be webbed/lightened."));
echo(str("  BOM per rail: ", full_holes, "x M4 heat-set insert + iron.  Hold-down: M4 SOCKET-HEAD cap screw,"));
echo(str("     length >= ", 12 + 8, " mm (~12 mm through the lug + >=8 mm into the insert; M4x20-22).  ",
         "Hex head jams in the lug pocket, button head won't fit -- cap head only."));
echo("  ASSEMBLY: bolt the box onto its two rails FIRST (box = the placement jig), THEN bed the box+rail");
echo("     unit into the slots and glue -- the 4.5 mm lug clearance can't absorb per-rail placement error otherwise.");
echo(str("  slot: cut ", rail_w + slot_clear, " wide x ", rail_h, " deep; rail top flush -> box at deck level (no CG/prop shift)."));
echo("------------------------------------------------------------");

// =====================================================================
//  STANDALONE RENDER
// =====================================================================
if (rail == "pair") {
  // two segments chained along X (second dropped onto the first's +X tang): joint + grid proof
  rail_segment();
  translate([seg_len, 0, 0]) rail_segment();
} else if (rail == "strip") {
  for (i = [0:rail_n-1]) translate([0, i*(rail_w + 6), 0]) rail_segment();
} else if (rail == "seated") {
  rail_segment();
  slot_stub();
} else {
  rail_segment();
}
