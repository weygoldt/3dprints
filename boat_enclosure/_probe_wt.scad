// WATERTIGHT breach probe: do any FASTENER bores reach the sealed cavity void?
// intersection(cavity void solid, union of screw + block-bolt bores) -> expect EMPTY.
// (cable/lid glands are INTENDED through-holes -> excluded.)  probe_pos=true adds a
// deliberately over-deep screw bore as a POSITIVE CONTROL (must become non-empty).
include <common.scad>
use <body.scad>
probe_pos = false;

// the TRUE void = the rprism cavity MINUS the solid bosses that rise into it
module cavity_solid() difference() {
  rprism(inner_w, inner_h, inner_d, corner_r - wall);
  if (screw_mount) for (p = screw_positions) screw_boss(p);
}

module fastener_bores() {
  if (screw_mount) for (p = screw_positions) screw_boss_cut(p);
  motor_mount_cut();
  if (probe_pos)   // positive control: an over-deep bore that DOES breach
    translate([screw_positions[0][0], D + eps, screw_positions[0][1]])
      rotate([90,0,0]) cylinder(h = boss_h + 5, d = insert_d);
}

intersection() { cavity_solid(); fastener_bores(); }
