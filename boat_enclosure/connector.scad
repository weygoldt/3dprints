// =====================================================================
//  AIRBOAT ENCLOSURE -- CENTRE-BOX CONNECTOR BRACKET   (v1 -- box-as-negative)
//
//  The boat now carries THREE boxes: the two stern DRIVE boxes (one per hull,
//  on their rails) plus a THIRD box floated on the centreline BETWEEN them,
//  ~3 cm above the deck, so the motor wiring runs in the gap underneath and the
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
//    * INNER end : its TOP is the centre-box FLOOR plane; an M4 HEAT-SET INSERT
//      is bored down there and the centre box's own lug screws DOWN into it.
//
//  MEASURED interface (Patrick, 2026-08-19):
//    inner-rail to inner-rail screw spacing = conn_rail_span = 155 mm
//    centre-box mount spacing (its lug pair) = 2*hd_x         =  62 mm
//    centre box floats box3_lift = 30 mm above the deck (the wire gap).
//
//  Built in the ASSEMBLY frame (X athwartship, Y down = model up is -Y, Z fore-
//  aft) so the box negative lands correctly; main.scad just calls it per corner.
// =====================================================================
include <common.scad>
use <body.scad>

// ---- measured interface + centre-box lift ------------------------------
conn_rail_span = 155;          // MEASURED inner-rail-to-inner-rail screw spacing (mm)
box3_lift      = 30;           // centre box floor above the deck (the 3 cm wire gap)
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
conn_clear_d  = 5.5;           // M4 clearance shank through the bracket + lug -- generous so the ~1 mm hand-shaped
                               // hull-width slop is absorbed (the notch self-references to the lug, so the screw
                               // still lands on the rail insert; the head is captured in the 7.5 counterbore)

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

// ONE bracket at hull sgn (-1 port / +1 starboard), fore-aft station z_st.  clr = slide-on fit gap.
//
// The notch is a clean LUG-SHAPED POCKET (a prism sized to the lug's outer box), NOT the raw box subtracted:
// the raw box dragged its own INTERNAL voids in -- the lug's hex-nut pocket became a hex PEG and the block's
// slots/bores became thin WEBS, both nasty overhangs (Patrick 2026-08-19).  Instead the blank simply STOPS clr
// inboard of the block face (no block overlap -> no block negative needed) and a rectangular pocket clears the
// lug.  The lug's rounded aft corners just get a touch more clearance; the flat inboard + top faces (which
// locate + seat the bracket) fit exactly, and the barrel-screw boss stays fully CLOSED.
module connector_solid(sgn, z_st, clr = 0) {
  scr    = sgn*conn_rail_span/2;                    // outer screw axis (on the inner rail / box inboard lug)
  ins    = sgn*hd_x;                                // inner insert axis (under the centre-box lug)
  blk_in = sgn*(hull_dx - mm_pad_w/2);              // stern block INBOARD face (world X)
  xo     = blk_in - sgn*clr;                        // outboard edge: clr inboard of the block face (no overlap)
  xi     = ins - sgn*conn_in;                       // inboard edge (a boss past the insert, toward the centreline)
  xlo = min(xo, xi);  xhi = max(xo, xi);
  lug_lo = min(scr - hd_w/2, scr + hd_w/2) - clr;   // lug pocket X span (+clr each side for the drop-on fit)
  lug_hi = max(scr - hd_w/2, scr + hd_w/2) + clr;
  difference() {
    // rectangular blank (front view), block face -> centre-box, deck -> centre-box floor
    translate([xlo, conn_ytop, z_st - conn_w/2]) cube([xhi - xlo, conn_ybot - conn_ytop, conn_w]);
    // LUG POCKET: a prism from the lug top (Y=hd_top_y, where the bracket SEATS) down past the deck, through
    // the full width -> the lug drops in from below; no top gap (it rests on the lug), clr on the side faces.
    translate([lug_lo, hd_top_y, z_st - conn_w/2 - eps]) cube([lug_hi - lug_lo, (D - hd_top_y) + 1, conn_w + 2*eps]);
    // OUTER barrel-head cap: counterbore from the top + M4 clearance all the way down through the lug
    translate([scr, conn_ytop - eps, z_st]) rotate([-90,0,0]) cylinder(h = (conn_ybot - conn_ytop) + float_thickness, d = conn_clear_d);
    translate([scr, conn_ytop - eps, z_st]) rotate([-90,0,0]) cylinder(h = conn_barrel_h + eps, d = conn_barrel_d);
    // INNER M4 heat-set insert bored DOWN from the centre-box floor plane, mouth chamfer
    translate([ins, conn_ytop - eps, z_st]) rotate([-90,0,0]) cylinder(h = conn_ins_deep + eps, d = conn_ins_d);
    translate([ins, conn_ytop - eps, z_st]) rotate([-90,0,0]) cylinder(h = conn_ins_cham + eps, d1 = conn_ins_d, d2 = conn_ins_d + 2*conn_ins_cham);
  }
}

// PRINT pose: one bracket laid with a flat side (the prismatic Z-face) on the bed (Z=0), centred at the origin.
// The notch is a through-profile feature (no overhang); the two bores print horizontal (fine for a clearance
// hole and a heat-set insert).  main.scad / STL export renders this; the assembly uses connector_solid.
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

// the four fore-aft lug stations the brackets sit at (box lugs are at box_back_z +/- 100)
conn_z_fore = box_back_z + 100;   // fore end block  (+20)
conn_z_aft  = box_back_z - 100;   // aft  end block  (-180)

// standalone render (main.scad sets conn_show="none" after include to suppress this):
//   "solo"  -- one PORT bracket at the fore lug station with the box it notches onto ghosted (inspection)
//   "print" -- the PRINT-pose bracket alone, for STL export.  conn_side = -1 left / +1 right.
//     export:  openscad -o connector_left.stl  --export-format=binstl -D 'conn_show="print"' -D 'conn_side=-1' -D '$fn=96' connector.scad
conn_show = "solo";
conn_side = -1;
if (conn_show == "print")     color("Goldenrod") connector_print(conn_side);
else if (conn_show != "none") { color("Goldenrod") connector_solid(-1, conn_z_fore); %stern_placed(-1) body("rc"); }
