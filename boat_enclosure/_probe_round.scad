// PROBE: did the inboard end actually get rounded, and did rounding it cost anything it shouldn't?
//
// Run every mode twice -- once as-is, and once with -D conn_in_round=0.  The second run is the
// POSITIVE CONTROL: with the round switched off the part is the old sharp one, so a mode that
// cannot come back non-empty there is a mode that was never measuring anything.
//
//  mode="corners" -> 0.8 mm cubes on the 4 CORNERS + the 4 EDGES of the inboard end face.
//                    The inboard end is now a semicircular TONGUE (r=conn_w/2=7): at the end plane
//                    the only solid is the APEX LINE at mid-width, full height.  So the 4 corners
//                    AND the two side (fore/aft) edge cubes read EMPTY, while the top+bottom edge
//                    cubes sit ON that apex line and stay solid -> 2 x 0.512 = 0.9988 mm^3.
//                    conn_in_round=0 (sharp): all 8 fill -> 4.096 mm^3.  The 4 CORNERS empty vs full
//                    is the real discriminator (a square end fills them); 0.9988 vs 4.096 gates it.
//  mode="mirror"  -> the part MINUS its own fore-aft mirror about z_st.  Gate on VOLUME, not on
//                    openscad's "top level object is empty": the two solids' surfaces coincide, so
//                    the difference comes back as a zero-thickness shell of a few hundred facets
//                    and openscad reports NoError.  Measured ~1e-7 mm^3 (sub-cubic-micron float
//                    noise) both directions, and the SHARP part reads the same order -- that is
//                    the baseline, not a defect.  MUST be ~0 in both
//                    directions: that mirror symmetry is the whole reason ONE printed piece serves
//                    both hulls, and a round applied to one width face but not the other would
//                    quietly put a second bracket on the plate.  (This one is empty for the sharp
//                    part too -- it is a regression gate, not a discriminator.)
//  mode="rmirror" -> the reverse difference, so the gate is symmetric.
//  mode="face_in" -> a 0.5 mm wafer off the INBOARD end.  tongue: vol 56.78, full 35 tall but only
//                    Z 17.43..22.57 wide -- the semicircle's chord 0.5 back from the apex (2*sqrt(7^2
//                    -6.5^2)=5.20 predicted).  sharp: the full 35 x 14 = 245 mm^3, 12 facets.
//  mode="face_out"-> the same wafer off the OUTBOARD end.  Rounded and sharp must agree EXACTLY --
//                    they do: 61.8 mm^3, X -83.200..-82.700, Y 8..27, Z 16.5..23.5 both ways.
//                    Note that face is only solid over a 7 mm width band and Y 13..27; the notch
//                    takes the rest.  That is why the corner-cube form of this gate reads empty on
//                    a perfectly square end, and why this wafer replaced it.
//  mode="bed"     -> the first layer's footprint: the part sliced at the bed (z0 .. z0+0.2).
//                    The tongue is a horizontal half-cylinder in the print pose, so its upper half
//                    overhangs; this measures the first-layer cost.  area 1834.8 -> 1622.8 mm^2
//                    (-11.6%; sharp footprint reaches x=-22, tongue only to x=-27.4 at the bed edge).
//  mode="outboard"-> the same 0.8 mm cubes on the OUTBOARD end's two width edges.  Must stay
//                    NON-empty: that end has to remain square to sit flush beside the block face,
//                    so this is the "did I round the wrong end" gate.
//                    NOT at the corners: the notch eats this end top AND bottom -- the lug from
//                    Y=27 down, and the 80 mm^3 wedge the box negative takes out of Y 8..13 (see
//                    _probe_band.scad).  The face is solid only in Y 13..27, so the cubes sit at
//                    mid-band.  Probing the corners here reads EMPTY on a perfectly square end.
include <common.scad>
use <body.scad>
include <connector.scad>
conn_show = "none";

mode = "corners";
sgn  = -1;
s    = 0.8;                                  // test-cube side
z0   = conn_z_fore - conn_w/2;
xi   = sgn*hd_x - sgn*conn_in;               // the INBOARD end plane
xo   = sgn*(hull_dx - mm_pad_w/2) - sgn*conn_clr;   // the OUTBOARD end plane
dir  = (sgn < 0) ? 1 : -1;                   // +X points inboard on port

module part() connector_solid(sgn, conn_z_fore, conn_clr);

// a test cube whose INBOARD face lies on the end plane x, at (y,z)
module probe_at(x, y, z) translate([x - (dir > 0 ? s : 0), y, z]) cube([s, s, s]);

if (mode == "corners")
  intersection() {
    part();
    union() {
      for (y = [conn_ytop, conn_ybot - s], z = [z0, z0 + conn_w - s]) probe_at(xi, y, z);   // 4 corners
      probe_at(xi, conn_ytop,        z0 + conn_w/2 - s/2);                                  // top edge
      probe_at(xi, conn_ybot - s,    z0 + conn_w/2 - s/2);                                  // bottom edge
      probe_at(xi, (conn_ytop + conn_ybot - s)/2, z0);                                      // fore edge
      probe_at(xi, (conn_ytop + conn_ybot - s)/2, z0 + conn_w - s);                         // aft edge
    }
  }
else if (mode == "outboard")
  intersection() {
    part();
    union() for (z = [z0, z0 + conn_w - s]) translate([xo - (dir > 0 ? 0 : s), 20, z]) cube([s, s, s]);
  }
else if (mode == "mirror")
  difference() { part(); translate([0, 0, 2*conn_z_fore]) mirror([0, 0, 1]) part(); }
else if (mode == "rmirror")
  difference() { translate([0, 0, 2*conn_z_fore]) mirror([0, 0, 1]) part(); part(); }
else if (mode == "face_out")   // a 0.5 mm wafer off the OUTBOARD end: its bbox says where that face is solid
  intersection() { part(); translate([xo - (dir > 0 ? 0 : 0.5), -200, -400]) cube([0.5, 400, 800]); }
else if (mode == "face_in")    // the same wafer off the INBOARD end
  intersection() { part(); translate([xi - (dir > 0 ? 0.5 : 0), -200, -400]) cube([0.5, 400, 800]); }
else if (mode == "bed")
  intersection() { part(); translate([-200, -200, z0]) cube([400, 400, 0.2]); }
