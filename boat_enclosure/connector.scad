// =====================================================================
//  AIRBOAT ENCLOSURE -- CENTRE-BOX CONNECTOR BRACKET   (v1 -- box-as-negative)
//
//  The boat now carries THREE boxes: the two stern DRIVE boxes (one per hull,
//  on their rails) plus a THIRD box floated on the centreline BETWEEN them,
//  ~3.5 cm above the deck, so the motor wiring runs in the gap underneath and the
//  mass moves aft+inboard (the 4-box layout was nose-heavy).
//
//  There is no rail on the centreline, so the centre box hangs off FOUR of these
//  brackets, one per corner.  Each bracket is, in FRONT VIEW, basically a
//  RECTANGLE with a NOTCH cut out of its bottom-OUTBOARD corner that fits over a
//  stern box's mounting lug (the "mickey-mouse ear").  The notch is not guessed:
//  it is the REAL box carved out of the blank (body() subtracted in place), so it
//  mates the lug + corner exactly (Patrick 2026-08-19).
//    * OUTER end : sits over the stern box's inboard lug.  A barrel/socket-head
//      cap screw drops through the bracket's COUNTERBORE, through the lug, into
//      the RAIL heat-set insert below -- one screw clamps bracket + box + rail.
//      NOTE: this screw spans the FULL bracket height, so box3_lift sets its
//      length -- at 35 the head seats at Y=12.5 and the deck is Y=43, so it
//      needs ~30.5 mm + the rail insert (~9) => M4 x ~40 (it was ~35 at lift 30).
//    * INNER end : its TOP is the centre-box FLOOR plane; an M4 HEAT-SET INSERT
//      is bored down there and the centre box's own lug screws DOWN into it.
//      This end is also the one the WIRING runs past (it faces the gap under the
//      centre box), so all four of its edges carry a round -- see conn_in_round.
//
//  MEASURED interface (Patrick, 2026-08-19):
//    inner-rail to inner-rail screw spacing = conn_rail_span = 155 mm
//    centre-box mount spacing (its lug pair) = 2*hd_x         =  62 mm
//    centre box floats box3_lift = 35 mm above the deck (the wire gap; was 30, raised 5 mm 2026-08-20).
//
//  Built in the ASSEMBLY frame (X athwartship, Y down = model up is -Y, Z fore-
//  aft) so the box negative lands correctly; main.scad just calls it per corner.
// =====================================================================
include <common.scad>
use <body.scad>

// ---- measured interface + centre-box lift ------------------------------
conn_rail_span = 155;          // MEASURED inner-rail-to-inner-rail screw spacing (mm)
box3_lift      = 35;           // centre box floor above the deck (the wire gap).  30 -> 35 (Patrick 2026-08-20):
                               // the ONLY height knob -- the bracket bottom is the deck (conn_ybot) and its top IS
                               // this plane, so +5 here = a 5 mm taller bracket AND the centre box rides 5 mm higher.
hull_dx        = conn_rail_span/2 + hd_x;   // stern-box centre so its inboard lug lands on the 155 mm inner rail

// ---- bracket geometry ---------------------------------------------------
conn_w        = mm_block_depth;// fore-aft width = the stern block depth (14): the bracket sits FLUSH with the
                               // block/pylon-mount faces on the housing, not proud (Patrick 2026-08-19)
conn_in       = 9;            // how far the inner edge reaches PAST the insert axis (toward the centreline)
conn_clr      = 0.3;           // notch slide-on clearance: the box negative is also subtracted shifted +/-conn_clr
                               // in X so the lug's inboard/outboard faces clear as the bracket drops on (Y seats
                               // on the lug top; Z is flush beside the block, so neither needs a gap)

// ---- outer fastener: barrel / socket-head cap screw, DOWN into the rail --
conn_barrel_d = 7.5;           // socket-head cap counterbore dia (DIN912 M4 head ~7.0 + slop)
conn_barrel_h = 4.5;           // counterbore depth (recesses the head)
conn_hex_d    = 9.5;           // bore over the lug hex-nut-pocket depth: > the M4 nut across-corners (~8.3) so no hex peg
conn_clear_d  = 5.5;           // M4 clearance shank through the bracket + lug -- generous so the ~1 mm hand-shaped
                               // hull-width slop is absorbed (the notch self-references to the lug, so the screw
                               // still lands on the rail insert; the head is captured in the 7.5 counterbore)

// ---- INBOARD END ROUND (the free end, pointing away from the stern housing) --
// The wiring runs through the gap under the centre box, i.e. straight past THIS end,
// so it gets a full round-over instead of four sharp arrises (Patrick 2026-08-20).
// It is rounded on ALL FOUR edges of the end face, and it has to be: the part is
// fore-aft MIRROR-SYMMETRIC about its mid-width plane, and that symmetry is the only
// reason one printed piece serves both hulls.  Treating the bed-side width edge
// differently from the other one (a 45 deg chamfer there, say, to keep it strictly
// self-supporting) would break the symmetry and put two brackets back on the plate.
// So the bed-side edge carries the same round, and the print pays for it in one
// small overhang -- see the measured figure in AIRBOAT-NOTES / the commit.
conn_in_round = 3;             // round radius on the inboard end (0 = old sharp end)
conn_round_fn = 32;            // facets for the round ONLY.  The part is otherwise exported at
                               // $fn=128; a 3 mm fillet at 128 buries the mesh in facets for a
                               // sub-0.1 mm gain, and 32 already puts the chord error at ~0.02 mm.

// ---- inner fastener: M4 heat-set insert (centre box screws DOWN into it) --
conn_ins_d    = insert_d;      // 5.6 heat-set hole (common.scad; MEASURE yours)
conn_ins_deep = insert_depth;  // 9 mm insert depth from the top
conn_ins_cham = 0.6;           // lead-in chamfer at the insert mouth

// ---- derived ------------------------------------------------------------
conn_ytop = D - box3_lift;     // bracket TOP = centre-box floor plane (Y, model)
conn_ybot = D;                 // bracket BOTTOM = deck plane

// place the REAL stern box for this hull (IDENTICAL transform to main.scad's scene)
module stern_placed(sgn) {
  translate([sgn*hull_dx, 0, 0])
    apply_side_of(sgn < 0 ? "port" : "starboard")
      translate([0, 0, box_back_z])
        children();
}

// The box negative = the simple, no-fuss 3D subtract of the REAL box, PLUS its own FORE-AFT MIRROR about the
// station z_st.  Mirroring makes the lug notch symmetric front-to-back -> the whole bracket becomes fore-aft
// symmetric, so ONE printed piece serves BOTH hulls: flip it 180 deg about the vertical and the left bracket
// becomes the right one (Patrick 2026-08-19).  With clr>0 it is also subtracted shifted +/-clr in X for the fit.
module box_negative(sgn, clr, z_st) {
  b = role_of_side(sgn < 0 ? "port" : "starboard");
  module one() stern_placed(sgn) body(b);
  module sym() { one(); translate([0, 0, 2*z_st]) mirror([0, 0, 1]) one(); }   // box + its mirror about Z=z_st
  sym();
  if (clr > 0) for (dx = [clr, -clr]) translate([dx, 0, 0]) sym();
}

// A box with EVERY edge rounded to r -- the hull of eight spheres sitting on the inset corners.
// Used only to shape the inboard nose, where a rounded box is exactly what is wanted; the sharp
// edges it also produces at its outboard end are deliberately buried inside the main body below.
module rbox(org, size, r)
  hull() for (i = [r, size[0]-r], j = [r, size[1]-r], k = [r, size[2]-r])
    translate([org[0]+i, org[1]+j, org[2]+k]) sphere(r = r, $fn = conn_round_fn);

// The blank: SQUARE at the outboard end, ROUNDED at the inboard one.
//
// Built as a full-section main body that stops r short of the inboard end, plus a fully rounded
// nose 3r long that overlaps it.  The overlap is what makes this exact rather than approximate:
// the nose's OWN outboard rounding lives in [xin-3r, xin-2r], which the main body fills at full
// section, so the only rounding that survives into the surface is the last r at the inboard end.
// Shorten that overlap and a groove appears at the seam where the nose's far rounding pokes out.
module conn_blank(xlo, xhi, z_st, sgn, r) {
  y0 = conn_ytop;  yh = conn_ybot - conn_ytop;  z0 = z_st - conn_w/2;
  rr = min(r, (yh - eps)/2, (conn_w - eps)/2, (xhi - xlo)/3);   // never let the round eat the section
  if (rr <= 0) {
    translate([xlo, y0, z0]) cube([xhi - xlo, yh, conn_w]);
  } else {
    mlo = (sgn < 0) ? xlo            : xlo + rr;      // main body: full section, stops rr short
    mhi = (sgn < 0) ? xhi - rr       : xhi;           //           of the INBOARD end
    nlo = (sgn < 0) ? xhi - 3*rr     : xlo;           // nose: 3rr long, rounded all over, its far
    nhi = (sgn < 0) ? xhi            : xlo + 3*rr;    //       end buried in the main body
    union() {
      translate([mlo, y0, z0]) cube([mhi - mlo, yh, conn_w]);
      rbox([nlo, y0, z0], [nhi - nlo, yh, conn_w], rr);
    }
  }
}

// ONE bracket at hull sgn (-1 port / +1 starboard), fore-aft station z_st.  clr = slide-on fit gap.
// Simple 3D box subtract (mirrored fore-aft, so one piece fits either hull); the blank stops clr inboard of the
// block face so the block is never overlapped.  The lug's hex-nut POCKET would leave a hex peg in the notch --
// an overhang -- so the barrel bore is widened over the pocket depth (conn_hex_d) to clear it.
module connector_solid(sgn, z_st, clr = 0) {
  scr    = sgn*conn_rail_span/2;                    // outer screw axis (on the inner rail / box inboard lug)
  ins    = sgn*hd_x;                                // inner insert axis (under the centre-box lug)
  blk_in = sgn*(hull_dx - mm_pad_w/2);              // stern block INBOARD face (world X)
  xo     = blk_in - sgn*clr;                        // outboard edge: clr inboard of the block face (no overlap)
  xi     = ins - sgn*conn_in;                       // inboard edge (a boss past the insert, toward the centreline)
  xlo = min(xo, xi);  xhi = max(xo, xi);
  difference() {
    // blank (front view), block face -> centre-box, deck -> centre-box floor.  Square at the
    // OUTBOARD end (it has to sit flush beside the block face) and ROUNDED at the inboard end.
    conn_blank(xlo, xhi, z_st, sgn, conn_in_round);
    // NEGATIVE: the real box, mirrored fore-aft, dilated by clr in X for the slide-on fit
    box_negative(sgn, clr, z_st);
    // OUTER barrel-head cap: counterbore from the top + M4 clearance all the way down through the lug
    translate([scr, conn_ytop - eps, z_st]) rotate([-90,0,0]) cylinder(h = (conn_ybot - conn_ytop) + float_thickness, d = conn_clear_d);
    translate([scr, conn_ytop - eps, z_st]) rotate([-90,0,0]) cylinder(h = conn_barrel_h + eps, d = conn_barrel_d);
    // clear the lug's hex-nut-pocket PEG: widen the bore to > the hex over the pocket's depth (both fore + aft mirror)
    translate([scr, hd_top_y - eps, z_st]) rotate([-90,0,0]) cylinder(h = hd_nut_depth + eps, d = conn_hex_d);
    // INNER M4 heat-set insert bored DOWN from the centre-box floor plane, mouth chamfer
    translate([ins, conn_ytop - eps, z_st]) rotate([-90,0,0]) cylinder(h = conn_ins_deep + eps, d = conn_ins_d);
    translate([ins, conn_ytop - eps, z_st]) rotate([-90,0,0]) cylinder(h = conn_ins_cham + eps, d1 = conn_ins_d, d2 = conn_ins_d + 2*conn_ins_cham);
  }
}

// PRINT pose: one bracket laid with a flat side (the prismatic Z-face) on the bed (Z=0), centred at the origin.
// The bracket is FORE-AFT symmetric, so ONE printed piece serves BOTH hulls -- flip it 180 deg about the
// vertical and the port bracket becomes the starboard one (conn_side -1 and +1 export the identical part).
module connector_print(sgn) {
  ins = sgn*hd_x;   blk_in = sgn*(hull_dx - mm_pad_w/2);
  xo  = blk_in - sgn*conn_clr;   xi = ins - sgn*conn_in;
  translate([-(xo + xi)/2, -(conn_ytop + conn_ybot)/2, -(conn_z_fore - conn_w/2)])
    connector_solid(sgn, conn_z_fore, conn_clr);
}

echo("=== CENTRE-BOX CONNECTOR (v1, box-as-negative) ===");
echo(str("  reach ", conn_rail_span/2 - hd_x, " mm (screw at X=+/-", conn_rail_span/2, " -> insert at X=+/-", hd_x, ")"));
echo(str("  block Y ", conn_ytop, "..", conn_ybot, " (centre-box floor ", conn_ytop, " = ", box3_lift, " above deck) ; width ", conn_w));
echo(str("  outer barrel M4 cap CB ", conn_barrel_d, "x", conn_barrel_h, " / clr ", conn_clear_d,
         " ; inner M4 insert ", conn_ins_d, "x", conn_ins_deep, " ; notch clearance ", conn_clr));
echo(str("  INBOARD end (the wire side, away from the housing) rounded r=", conn_in_round,
         " on all 4 edges", conn_in_round > 0 ? "" : "  << OFF: sharp arrises where the wiring runs"));

// the four fore-aft lug stations the brackets sit at (box lugs are at box_back_z +/- 100)
conn_z_fore = box_back_z + 100;   // fore end block  (+20)
conn_z_aft  = box_back_z - 100;   // aft  end block  (-180)

// standalone render (main.scad sets conn_show="none" after include to suppress this):
//   "solo"  -- one bracket at the fore lug station with the box it notches onto ghosted (inspection)
//   "print" -- the PRINT-pose bracket alone, for STL export.  ONE part serves both hulls (fore-aft symmetric).
//     export:  openscad -o airboat_centrebox_connector.stl --export-format=binstl -D 'conn_show="print"' -D '$fn=128' connector.scad
conn_show = "solo";
conn_side = -1;
if (conn_show == "print")     color("Goldenrod") connector_print(conn_side);
else if (conn_show != "none") { color("Goldenrod") connector_solid(-1, conn_z_fore); %stern_placed(-1) body("rc"); }
