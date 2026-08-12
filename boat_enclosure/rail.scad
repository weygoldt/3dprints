// =====================================================================
//  AIRBOAT ENCLOSURE -- MOUNTING RAIL  (segmented, dovetail-chained, M4 heat-set)
//  Part of the airboat catamaran mounting system.  See common.scad for the box
//  frame mapping, all box parameters, and the shared BOSL2 includes.
//
//  WHAT IT IS
//    A constant-section rail that drops FLUSH into a straight slot in the XPS deck
//    and is bonded in with EPOXY + FIBERGLASS (no through-hull bolts).  A row of M4
//    brass heat-set inserts runs the length at rail_pitch (40 mm); the box sits on
//    the deck and an M4 SOCKET-HEAD cap screw drops through each box corner-lug from
//    above into a rail insert, so you can slide each box fore/aft on the 40 mm grid
//    to trim the float.  Two rails 62 mm apart carry one box line; 4 rails per boat
//    (2 per skid, 2 boxes per skid: sensors fore, motors aft).
//
//  THREE RAIL TYPES (clean, visible ends -- no dangling tang / open socket)
//    A full rail = one START (flat left, joint right) + N MID (joint both ends) +
//    one END (joint left, flat right).  Pick with rail_type.  The flat ends read as
//    a finished blunt face; the joints live between segments where they're hidden.
//
//  CONSTANT OUTER SECTION (so the slot is a simple, constant channel)
//    Outer rail_w x rail_h is the SAME everywhere -> a constant slot, easy to cut.
//    Lightening (below) and the dovetail joints are INSET features that never grow
//    the envelope, so the slot stays constant and the flush top keeps the box at
//    deck level (no CG/prop shift).
//
//  LIGHTENING (faster print, less plastic, keeps the envelope -- default on)
//    A stadium SLOT is cut vertically through the bay between each pair of inserts,
//    leaving continuous side rails + a solid boss at every insert.  ~25% less
//    material/time, still stiff, prints supportless (vertical walls, solid bottom
//    frame for bed adhesion), and -- bonus for the glass job -- epoxy flows THROUGH
//    the slots and keys the rail to the deck.  lighten=false -> a solid bar.
//
//  DOVETAIL JOINT ORIENTATION (joint =)
//    "drop"     : vertical-slide dovetail (flare horizontal).  Locks fore/aft +
//                 lateral; free vertical -> assemble by dropping the next segment
//                 straight down.  Prints SUPPORTLESS.  RECOMMENDED: the epoxy+glass+
//                 slot+box already lock the vertical axis hard once installed, so the
//                 joint only has to align + hold during glue-up.
//    "vertical" : rotated 90deg (flare vertical) so the JOINT ITSELF locks the
//                 vertical axis you flagged.  BUT a vertical-locking joint needs a
//                 vertical undercut, which is an overhang when printed flat -> the
//                 tang needs a little support at each joint (2 per rail, glassed over).
//
//  PRINTS BASE-DOWN.  Long + narrow -> add a brim.  PETG or PLA.  Fastest slice:
//  2 perimeters, ~15-20% gyroid infill, 0.28-0.3 mm layers (bigger lever than geometry).
//  Requires BOSL2 (../BOSL2) -- std+threading via common.scad, joiners here.
// =====================================================================
include <common.scad>
include <../BOSL2/joiners.scad>   // dovetail() -- std.scad omits joiners

$fn = 64;

/* [What to render] */
rail   = "trio";     // [segment, trio, pair, strip, seated] trio=start+mid+end assembled; segment=one rail_type; pair=two mids; strip=rail_n of rail_type; seated=in a foam-slot stub
rail_type = "mid";   // [start, mid, end] segment/strip/seated render this type (start: flat|male ; mid: female|male ; end: female|flat)
rail_n = 3;          // strip count / full-rail segment count (start + (n-2) mid + end)

/* [Grid -- matches the box hold-down bolt pattern] */
seg_holes  = 4;      // M4 insert holes per segment (4 -> 160 mm; 3 segments ~= 480 mm ~= the 50 cm run)
rail_pitch = 40;     // insert spacing (mm).  Box bolt span 200 mm (Z=+/-100) = 5 pitches -> lands on any hole pair
end_margin = 20;     // first/last hole this far from the butt plane; = pitch/2 keeps the grid continuous across a joint

/* [Cross-section -- CONSTANT outer envelope (embeds in a straight slot)] */
rail_w   = 14;       // constant width = slot width.  >=12 for the M4 insert boss; extra -> dovetail-socket + slot walls
rail_h   = 10;       // constant height = slot depth for a flush top.  >= ~8 mm insert + a little (user spec: 1 cm)
edge_r   = 1.0;      // round on the vertical edges (finish + eases dropping into the slot; supportless)

/* [Lightening -- stadium slots between inserts (keeps the outer envelope)] */
lighten   = true;    // true: cut a slot through each bay between inserts (~25% lighter, epoxy keys through); false: solid bar
slot_wall = 3.0;     // side-rail thickness left either side of a lightening slot (slot width = rail_w - 2*this)
slot_keep = 16;      // solid length kept centred on each insert (slot length = pitch - this)

/* [Heat-set inserts -- M4, from common.scad] */
insert_bore    = insert_d;  // 5.6 mm heat-set hole for M4 brass (common.scad; MEASURE yours)
insert_through = true;      // true: bore through (bolt tip exits into the foam, forgiving of screw length); false: blind
insert_deep    = 9;         // blind-bore depth from the top when insert_through=false
insert_cham    = 0.6;       // lead-in chamfer at the bore mouth (eases the heat-set start)

/* [Dovetail joint] */
joint     = "drop";  // [drop, vertical] drop = supportless vertical-slide (recommended); vertical = rotated 90deg, locks vertical (needs light joint support)
dt_proj   = 8;       // how far the male tang projects past the butt plane (inset within the slot)
dt_chamfer = 0.5;    // corner chamfer -> printed parts mate without corner interference
dt_slop   = 0.15;    // $slop clearance added to the FEMALE socket (tune to your printer)
dt_w      = 9;       // "drop": horizontal flare width. rail_w - dt_w = 2x socket wall
dt_v      = 6;       // "vertical": vertical flare (must fit rail_h with walls: rail_h - dt_v = 2x wall)
dt_slope  = 6;       // BOSL2 woodworking slope

/* [Slot -- the XPS channel (for the 'seated' preview / your reference)] */
slot_clear = 0.3;    // cut the slot rail_w + this wide for a slip fit; 0 = press fit.  Depth = rail_h (flush)

// ---- derived ----
eps = 0.01;
seg_len   = seg_holes * rail_pitch;                                   // butt-plane to butt-plane
hole_xs   = [ for (i=[0:seg_holes-1]) -seg_len/2 + end_margin + i*rail_pitch ];
bore_h    = insert_through ? rail_h + 2*eps : insert_deep + eps;
bore_z    = insert_through ? -eps : rail_h - insert_deep;
sock_wall = (joint=="vertical") ? (rail_h - dt_v)/2 : (rail_w - dt_w)/2; // PLA around the female socket at its widest
boss_wall = (rail_w - insert_bore)/2;
slot_w    = rail_w - 2*slot_wall;
slot_len  = rail_pitch - slot_keep;
printed_len_mid = seg_len + dt_proj;                                  // a mid segment (male tang adds to X)

// per-end joint feature: "flat" | "male" | "female"
function ends_of(t) = (t=="start") ? ["flat","male"]
                    : (t=="end")   ? ["female","flat"]
                    :                ["female","male"];   // mid

// =====================================================================
//  DOVETAIL male/female in the selected orientation (attach to a cuboid face)
// =====================================================================
module male_dt() {
  if (joint=="vertical") dovetail("male", slide=rail_w, width=dt_v, height=dt_proj, slope=dt_slope, chamfer=dt_chamfer, spin=90);
  else                   dovetail("male", slide=rail_h, width=dt_w, height=dt_proj, slope=dt_slope, chamfer=dt_chamfer);
}
module female_dt() {
  if (joint=="vertical") dovetail("female", slide=rail_w, width=dt_v, height=dt_proj, slope=dt_slope, chamfer=dt_chamfer, spin=90, $slop=dt_slop);
  else                   dovetail("female", slide=rail_h, width=dt_w, height=dt_proj, slope=dt_slope, chamfer=dt_chamfer, $slop=dt_slop);
}

// =====================================================================
//  ONE SEGMENT of a given type  (PRINT pose: flat bottom on the bed, length along X)
// =====================================================================
module rail_segment(type="mid") {
  e = ends_of(type);  // [left_feature, right_feature]
  diff() {
    cuboid([seg_len, rail_w, rail_h], anchor=BOTTOM, rounding=edge_r, edges="Z") {
      if (e[1]=="male") attach(RIGHT) male_dt();
      if (e[0]=="male") attach(LEFT)  male_dt();
      if (e[1]=="female") tag("remove") attach(RIGHT) female_dt();
      if (e[0]=="female") tag("remove") attach(LEFT)  female_dt();
    }
    // insert bores + lead-in chamfers
    for (x = hole_xs) {
      tag("remove") translate([x, 0, bore_z]) cylinder(h=bore_h, d=insert_bore);
      tag("remove") translate([x, 0, rail_h - insert_cham]) cylinder(h=insert_cham + eps, d1=insert_bore, d2=insert_bore + 2*insert_cham);
    }
    // lightening slots (stadium, through Z) in each bay between inserts
    if (lighten)
      for (i = [0:len(hole_xs)-2]) {
        cx = (hole_xs[i] + hole_xs[i+1]) / 2;
        tag("remove") translate([cx, 0, -eps]) linear_extrude(rail_h + 2*eps)
          hull() for (s=[-1,1]) translate([s*(slot_len/2 - slot_w/2), 0]) circle(d=slot_w);
      }
  }
}

// translucent foam-slot stub for the 'seated' preview (NOT printed)
module slot_stub() {
  bw = rail_w + slot_clear;
  color([0.85, 0.82, 0.70, 0.35]) difference() {
    translate([0, 0, rail_h/2]) cube([seg_len + 50, bw + 40, rail_h], center=true);
    translate([0, 0, rail_h/2 + eps]) cube([seg_len + 70, bw, rail_h + 2*eps], center=true);
  }
}

// =====================================================================
//  ECHO FIT-CHECK  (house style: the number and the bar it must clear)
// =====================================================================
full_len = rail_n * seg_len;  full_holes = rail_n * seg_holes;
echo("=== AIRBOAT MOUNTING RAIL ===");
echo(str("  grid: ", seg_holes, " M4 holes/segment @ ", rail_pitch, " mm pitch ; segment ", seg_len,
         " mm ; ", rail_n, " (start+", rail_n-2, "xmid+end) = ", full_len, " mm, ", full_holes, " holes (target ~500)"));
echo(str("  box match: bolts at X=+/-31 (=> two rails 62 mm apart), Z=+/-100 (200 mm = ", 200/rail_pitch,
         " pitches) ", (200 % rail_pitch == 0) ? "OK -- box lands on a hole pair" : " << 200 not a multiple of pitch!"));
echo(str("  grid continuity: end_margin ", end_margin, " vs pitch/2 ", rail_pitch/2, " ",
         end_margin == rail_pitch/2 ? "OK -- 40 mm continues across a joint" : " << set end_margin = pitch/2"));
box_fp = 214;  two_box_play = full_len - 2*box_fp;   // box footprint incl. both end blocks (CONFIRM/measure)
echo(str("  two boxes/rail: ", full_holes, " holes hold two 200 mm bolt pairs; two ~", box_fp, " mm boxes leave ~",
         round(two_box_play), " mm combined fore/aft play ", two_box_play >= 0 ? "OK" : " << add a segment (rail_n)"));
echo(str("  section (CONSTANT): ", rail_w, "(W) x ", rail_h, "(H) -> slot ", rail_w + slot_clear, " wide x ", rail_h,
         " deep (flush).  boss wall ", boss_wall, " mm vs >= ", (2*insert_od-insert_bore)/2, " ",
         rail_w >= 2*insert_od ? "OK" : " << widen rail_w"));
echo(str("  insert: bore d", insert_bore, (insert_through?" THROUGH":str(" blind ",insert_deep)),
         " ; seat rail_h ", rail_h, " vs ~8 mm insert ", rail_h >= 8 ? "OK" : " << raise rail_h"));
echo(str("  joint = ", joint, " : ",
         joint=="vertical"
           ? str("rotated 90deg, LOCKS vertical ; socket wall ", sock_wall, " mm ; << needs light support at each joint (vertical undercut)")
           : str("vertical-slide, SUPPORTLESS ; socket wall ", sock_wall, " mm ; vertical axis is locked by the epoxy/glass/slot once installed")));
if (lighten)
  echo(str("  lightening: ", len(hole_xs)-1, " slots/segment ", slot_len, " x ", slot_w,
           " (side rails ", slot_wall, ", solid ", slot_keep, " at each insert) -> epoxy keys through ",
           slot_w > 0 && slot_wall >= 2 ? "OK" : " << slot walls too thin"));
// material
vol_solid = seg_len*rail_w*rail_h;
vol_slots = lighten ? (len(hole_xs)-1) * ((slot_len-slot_w)*slot_w + PI/4*slot_w*slot_w) * rail_h : 0;
vol_bore  = seg_holes*PI/4*insert_bore*insert_bore*rail_h;
vol_net   = vol_solid - vol_slots - vol_bore;
echo(str("  material ~", round(vol_net/1000), " cm^3/segment (", lighten?str("~",round(100*vol_slots/vol_solid),"% shaved by slots"):"solid",
         ") ~", round(vol_net*1.24/1000), " g PLA @100% ; big lever = slicer infill/perimeters/layer height"));
echo(str("  printed extent (mid): ", printed_len_mid, "(X) x ", rail_w, "(Y) x ", rail_h, "(Z) on 250x210 ",
         (printed_len_mid <= 250 && rail_w <= 210) ? "fits" : " << lower seg_holes"));
echo(str("  BOM/rail: ", full_holes, "x M4 heat-set insert + iron ; hold-down M4 SOCKET-HEAD cap x20-22 mm (from above through the lug)"));
echo("  MOUNT: bond into the slot with epoxy + glass (no through-holes).  ASSEMBLE the box onto its two rails first");
echo("     (box = the placement jig), set into the slots, then glass over -- flush top keeps the box at deck level.");
echo("------------------------------------------------------------");

// =====================================================================
//  STANDALONE RENDER
// =====================================================================
if (rail == "trio") {
  // full clean rail: start + mid... + end, chained (assembly proof; both ends flat)
  types = concat(["start"], [for (i=[1:rail_n-2]) "mid"], ["end"]);
  for (i = [0:rail_n-1]) translate([i*seg_len, 0, 0]) rail_segment(types[i]);
} else if (rail == "pair") {
  rail_segment("mid"); translate([seg_len, 0, 0]) rail_segment("mid");
} else if (rail == "strip") {
  for (i = [0:rail_n-1]) translate([0, i*(rail_w + 6), 0]) rail_segment(rail_type);
} else if (rail == "seated") {
  rail_segment(rail_type); slot_stub();
} else {
  rail_segment(rail_type);
}
