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
//  DOVETAIL FIT (dt_fit) -- v3 tightens the joint.  Why v2 was wobbly:
//    The dovetail flank sits atan(1/slope) off the pull-apart axis, so a flank gap g
//    opens sqrt(slope^2+1)*g of AXIAL slack -- a 6.08x AMPLIFIER at slope=6.  v2 passed
//    $slop=0.15 straight to BOSL2, which is 0.91 mm of pull-apart play per joint
//    (measured with _probe_fit.scad, not estimated).  That is the wobble.
//    v3 drops it to 0.12 mm (dt_fit=0.02) while staying a positive clearance -- see the
//    dt_fit block below for why that value and not a true press fit.
//    Depth is a SEPARATE knob (dt_depth, always > 0) so the tang can never bottom out and
//    hold the flat butt faces apart -- that would break the continuous 40 mm hole grid.
//
//  BACKWARD COMPATIBLE WITH ALREADY-PRINTED v2 SEGMENTS.  The MALE tang is nominal in both
//    versions -- dt_fit only ever resizes the FEMALE socket -- so every tang mates with
//    every socket and only the tightness differs.  Verified by rendering: a v3 "start"
//    (tang, no socket) is volumetrically IDENTICAL to a v2 "start".  Practical consequence:
//      new segment onto an OLD tang -> tight (the improvement, free, no reprinting)
//      old segment onto a NEW tang  -> still 0.91 mm loose (that socket is already printed)
//    So mix freely; put the new segments wherever you want the joint to be stiff.
//
//  PRINTS BASE-DOWN.  Long + narrow -> add a brim.  PETG or PLA.  Fastest slice:
//  2 perimeters, ~15-20% gyroid infill, 0.28-0.3 mm layers (bigger lever than geometry).
//  Requires BOSL2 (../BOSL2) -- std+threading via common.scad, joiners here.
// =====================================================================
include <common.scad>
include <../BOSL2/joiners.scad>   // dovetail() -- std.scad omits joiners

$fn = 64;

/* [What to render] */
rail   = "trio";     // [segment, trio, pair, strip, seated, fittest, none] trio=start+mid+end assembled; segment=one rail_type; pair=two mids; strip=rail_n of rail_type; seated=in a foam-slot stub; fittest=dovetail fit coupons; none=render nothing (for include)
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
dt_w      = 9;       // "drop": horizontal flare width. rail_w - dt_w = 2x socket wall
dt_v      = 6;       // "vertical": vertical flare (must fit rail_h with walls: rail_h - dt_v = 2x wall)
dt_slope  = 6;       // BOSL2 woodworking slope

/* [Dovetail FIT] */
// dt_fit is the gap NORMAL to the dovetail flank (same meaning as BOSL2's $slop, but
// signed and decoupled from depth).  0 = nominal, zero-play.  NEGATIVE = INTERFERENCE.
// 0.02 is a deliberate "just get it built" value: 0.12 mm of axial play instead of v2's
// 0.91 mm (-87%), but still a POSITIVE clearance, so it drops together without a mallet
// and cannot jam a segment you cannot afford to reprint.  0.02 is below a typical FDM
// printer's own repeatability, so in the real part it lands somewhere between a light
// press and ~0.07 mm loose -- snug either way.
// Tighter if you want it: 0 = exactly nominal, negative = a true press fit (rail="fittest"
// prints a coupon ladder to find your printer's limit).  If a joint ever binds, three
// strokes of a file on the TANG fixes it -- never open up the socket.
dt_fit    = 0.02;    // flank gap.  Axial play = dt_fit * sqrt(slope^2+1)
dt_depth  = 0.20;    // extra socket DEPTH only.  Keeps the tang off the socket floor so the flat
                     // BUTT FACES always close -> the 40 mm hole grid stays continuous across a joint.
dt_lead   = 0.8;     // entry relief height at the socket mouth (z=0, where the tang enters)
dt_lead_w = 0.35;    // how much that relief widens the mouth, per side.  Starts the press square
                     // and swallows the elephant's foot both parts grow on the bed.

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

// ---- dovetail fit (derived) ----------------------------------------------
// WHY THIS IS HAND-ROLLED INSTEAD OF JUST PASSING $slop:
//   BOSL2's dovetail() couples the two clearances -- $slop grows the socket's WIDTH and
//   its DEPTH together.  A negative $slop would therefore make the socket SHALLOWER than
//   the tang projects, so the tang bottoms out on the socket floor and holds the flat butt
//   faces APART -- which is exactly what a rail carrying a continuous 40 mm hole grid must
//   never do.  So: call dovetail() with $slop=0 and set the female's width and height
//   ourselves, giving one signed knob for grip (dt_fit) and a separate always-positive one
//   for depth (dt_depth).
// THE GEOMETRY THAT MADE V2 WOBBLE:
//   The flank sits at atan(1/slope) off the pull-apart axis, so a flank gap g opens up
//   sqrt(slope^2+1)*g of AXIAL slack -- a 6.08x amplifier at slope=6.  v2's $slop=0.15 was
//   therefore 0.91 mm of pull-apart slop per joint (measured, not estimated).
dt_nom_w  = (joint=="vertical") ? dt_v   : dt_w;      // nominal flare width, active orientation
dt_slide  = (joint=="vertical") ? rail_w : rail_h;    // sliding axis length
dt_wfac   = sqrt(1/(dt_slope*dt_slope) + 1);          // horizontal width per unit flank gap (taper=0)
dt_amp    = sqrt(dt_slope*dt_slope + 1);              // flank gap -> axial play amplifier
dt_axial  = dt_fit * dt_amp;                          // signed axial play (+) / interference (-) per joint
// female width must add back what the extra depth steals from the throat (dt_depth/slope)
function fem_w_of(f) = dt_nom_w + 2*(f*dt_wfac + dt_depth/dt_slope);
fem_w     = fem_w_of(dt_fit);
fem_h     = dt_proj + dt_depth;

// per-end joint feature: "flat" | "male" | "female"
function ends_of(t) = (t=="start") ? ["flat","male"]
                    : (t=="end")   ? ["female","flat"]
                    :                ["female","male"];   // mid

// =====================================================================
//  DOVETAIL male/female in the selected orientation (attach to a cuboid face)
// =====================================================================
// The MALE tang is always nominal -- every fit change lives in the female socket.
// (That is what lets one printed male gauge test a whole ladder of female coupons.)
module male_dt() {
  dovetail("male", slide=dt_slide, width=dt_nom_w, height=dt_proj,
           slope=dt_slope, chamfer=dt_chamfer, spin=(joint=="vertical") ? 90 : 0);
}
// $slop=0: the fit is carried entirely by fem_w / fem_h, computed above.
// `fit` overrides dt_fit for one socket -- that is how the coupon ladder is built.
module female_dt(fit=undef) {
  dovetail("female", slide=dt_slide, width=fem_w_of(is_undef(fit) ? dt_fit : fit), height=fem_h,
           slope=dt_slope, chamfer=dt_chamfer, spin=(joint=="vertical") ? 90 : 0, $slop=0);
}

// ENTRY RELIEF ("drop" only).  Segments are joined by lowering the next one onto the
// standing tang, so the tang enters the socket through its BOTTOM rim (z=0) -- which is
// also the bed face, where elephant's foot squeezes the socket and fattens the tang.
// A short funnel there starts the press square and costs dt_lead of 10 mm of grip.
// The socket cross-section is a constant trapezoid (taper=0), so the funnel is just a
// hull between an outset trapezoid at z=0 and the nominal one at z=dt_lead.
// NOTE it is subtracted by a plain difference(), NOT by tag("remove"): BOSL2's tag system
// is implemented inside attachable(), so raw polygon()/hull() geometry ignores tags and
// would be UNIONED into the part instead of cut out of it.
module lead_relief(sx, L=undef, fit=undef) {  // sx = -1 at the LEFT butt plane, +1 at the RIGHT
  fw    = fem_w_of(is_undef(fit) ? dt_fit : fit);
  x0    = sx * (is_undef(L) ? seg_len : L)/2;  // butt plane
  xd    = x0 - sx * fem_h;               // deep end -- the socket cuts INWARD from the butt face
  hw_t  = fw/2 - fem_h/dt_slope;         // half-width at the throat (at the butt plane)
  hw_d  = fw/2;                          // half-width at the deep end (widest)
  module trap(g) polygon([[x0, -(hw_t+g)], [xd, -(hw_d+g)], [xd, hw_d+g], [x0, hw_t+g]]);
  hull() {
    translate([0,0,-eps])     linear_extrude(eps) trap(dt_lead_w);
    translate([0,0,dt_lead])  linear_extrude(eps) trap(0);
  }
}

// =====================================================================
//  ONE SEGMENT of a given type  (PRINT pose: flat bottom on the bed, length along X)
// =====================================================================
module rail_segment(type="mid") {
  e = ends_of(type);  // [left_feature, right_feature]
  difference() {
    rail_segment_body(type);
    // entry funnel at the socket mouth (drop-assembly only -- see lead_relief)
    if (joint=="drop" && dt_lead > 0) {
      if (e[0]=="female") lead_relief(-1);
      if (e[1]=="female") lead_relief(+1);
    }
  }
}

module rail_segment_body(type="mid") {
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
// ---- dovetail fit ----
echo(str("  FIT: dt_fit ", dt_fit, " mm flank gap -> axial ",
         dt_fit <= 0 ? str(abs(dt_axial), " mm INTERFERENCE (press fit)")
                     : str(dt_axial, " mm of PULL-APART PLAY"),
         "   [amplifier sqrt(slope^2+1) = ", dt_amp, "x]"));
echo(str("  FIT: v2 compat -- the tang is NOMINAL in both versions (dt_fit resizes only the socket),",
         " so new segments mate with already-printed ones. v2 play was ", 0.15*dt_amp, " mm ; now ",
         abs(dt_axial), " mm = ", round(100*(1 - abs(dt_axial)/(0.15*dt_amp))), "% less wobble."));
echo(str("  FIT: socket ", fem_w, " wide x ", fem_h, " deep vs tang ", dt_nom_w, " x ", dt_proj,
         " ; tip clearance ", dt_depth, " mm ",
         dt_depth > 0 ? "OK -- butt faces close, 40 mm grid stays continuous"
                      : " << dt_depth must be > 0 or the tang bottoms out and holds the joint open"));
echo(str("  FIT: entry funnel ", (joint=="drop" && dt_lead>0)
           ? str(dt_lead_w, " mm/side over ", dt_lead, " mm at z=0 (overhang ",
                 round(atan(dt_lead_w/dt_lead)), " deg from vertical ",
                 atan(dt_lead_w/dt_lead) <= 45 ? "OK supportless" : " << too steep",
                 ") ; full-grip slide ", dt_slide - dt_lead, " of ", dt_slide, " mm")
           : "OFF"));
// socket-wall bending under the press (cantilever, L=dt_proj, t=sock_wall, h=slide)
fit_I   = dt_slide * pow(sock_wall,3) / 12;
fit_F   = dt_fit >= 0 ? 0 : 3*3500*fit_I*abs(dt_fit*dt_wfac) / pow(dt_proj,3);
fit_sig = dt_fit >= 0 ? 0 : fit_F*dt_proj*(sock_wall/2)/fit_I;
if (dt_fit < 0)
  echo(str("  FIT: press load ~", round(fit_F), " N/wall, socket-wall bending ~", round(fit_sig*10)/10,
           " MPa vs ~50 MPa PLA yield ", fit_sig < 25 ? "OK" : " << easing off dt_fit",
           " (stress runs ALONG the layers -- not a layer-adhesion load)"));
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
//  FIT-TEST COUPON  (rail="fittest")  -- print this BEFORE the real rails
// =====================================================================
//  The male tang is always nominal, so ONE printed male gauge tests the whole ladder:
//  press it into each numbered female coupon and keep the tightest one that still seats
//  fully (butt faces touching) without splitting.  Put that value in dt_fit and re-export.
//  ~25 g, prints in well under an hour -- far cheaper than a mis-fitting 480 mm rail.
fit_ladder = [0.05, 0.00, -0.05, -0.10, -0.15];   // coupon 1..5, loosest -> tightest
coupon_len = 26;                                   // short stub, enough to grip
coupon_gap = 6;

module coupon_label(n, L) {
  translate([L/2 - 7, 0, rail_h]) linear_extrude(0.6)
    text(str(n), size=6, halign="center", valign="center");
}
module fit_coupon(fit, n) {                        // female stub at one fit value
  difference() {
    union() {
      diff()   // REQUIRED: tag("remove") is inert outside diff() and would UNION the socket
      cuboid([coupon_len, rail_w, rail_h], anchor=BOTTOM, rounding=edge_r, edges="Z")
        tag("remove") attach(LEFT) female_dt(fit=fit);
      coupon_label(n, coupon_len);
    }
    if (joint=="drop" && dt_lead > 0) lead_relief(-1, L=coupon_len, fit=fit);
  }
}
module fit_gauge() {                               // the single nominal male gauge
  cuboid([coupon_len, rail_w, rail_h], anchor=BOTTOM, rounding=edge_r, edges="Z")
    attach(RIGHT) male_dt();
}
module fit_test() {
  fit_gauge();
  for (i = [0:len(fit_ladder)-1])
    translate([0, (i+1)*(rail_w + coupon_gap), 0]) fit_coupon(fit_ladder[i], i+1);
}

if (rail == "fittest") {
  echo("  === FIT COUPON LADDER (press the ONE male gauge into each numbered stub) ===");
  for (i = [0:len(fit_ladder)-1])
    echo(str("     coupon ", i+1, " : dt_fit = ", fit_ladder[i], " -> axial ",
             fit_ladder[i] <= 0 ? str(abs(fit_ladder[i]*dt_amp), " mm interference")
                                : str(fit_ladder[i]*dt_amp, " mm play")));
  echo("     keep the TIGHTEST that still seats butt-to-butt; put it in dt_fit and re-export the rails.");
}

// =====================================================================
//  STANDALONE RENDER
// =====================================================================
if (rail == "none") {
  // nothing -- lets another file `include <rail.scad>` for its params/modules
} else if (rail == "fittest") {
  fit_test();
} else if (rail == "trio") {
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
