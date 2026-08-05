// LID-SEAT probe: with the lid closed (lid_open=0, as modeled), the lid and body
// must not solid-overlap (skirt wraps the step with clearance; knuckles interleave
// with a gap).  intersection(body, lid) -> expect EMPTY (or a negligible sliver).
include <common.scad>
use <body.scad>
use <lid.scad>
intersection() { body(); lid(); }
