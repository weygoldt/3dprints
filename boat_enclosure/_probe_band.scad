// PROBE: what occupies the NEW 5 mm band (Y 8..13) that box3_lift 30 -> 35 added?
// Answer (measured 2026-08-20, $fn=96, BEFORE the inboard end was rounded -- it now reads
// 3816.2, the difference being the round's bite out of this band): the band is 3867.0 mm^3 -- a full-span slab
// (61.2 x 5 x 14) minus the two bores minus an 80.0 mm^3 wedge the box negative eats at the
// TOP-OUTBOARD corner (X -83.2..-67.2).  So the notch does follow the box up into the new band;
// it is not a plain slab.  "ctrl" is the positive control: the negative IS non-empty one band down.
//  mode="add"   -> the bracket material inside the band            (measured 3867.0 mm^3)
//  mode="neg"   -> the whole box negative clipped to the band       (non-empty: the box IS up here)
//  mode="ctrl"  -> the same, one band lower (Y 13..18): positive control, must be NON-empty
//  mode="carve" -> the band's BLANK minus what survives: the 80.0 mm^3 the notch actually eats
include <common.scad>
use <body.scad>
include <connector.scad>
conn_show = "none";
mode = "add";
module band(y0, y1) translate([-200, y0, conn_z_fore - conn_w]) cube([400, y1 - y0, 2*conn_w]);
if (mode == "add")       intersection() { connector_solid(-1, conn_z_fore, conn_clr); band(8, 13); }
else if (mode == "neg")  intersection() { box_negative(-1, conn_clr, conn_z_fore);    band(8, 13); }
else if (mode == "ctrl") intersection() { box_negative(-1, conn_clr, conn_z_fore);    band(13, 18); }
// mode="carve": the part of the NEW band's rectangular BLANK that the box negative eats.
//   Tells us WHERE (bbox) the material the band loses to the notch actually sits: X -83.2..-67.2.
module blank_band() {
  ins = -hd_x; blk_in = -(hull_dx - mm_pad_w/2);
  xo = blk_in + conn_clr; xi = ins + conn_in;
  xlo = min(xo, xi); xhi = max(xo, xi);
  intersection() {
    translate([xlo, conn_ytop, conn_z_fore - conn_w/2]) cube([xhi - xlo, conn_ybot - conn_ytop, conn_w]);
    band(8, 13);
  }
}
if (mode == "carve") intersection() { box_negative(-1, conn_clr, conn_z_fore); blank_band(); }
