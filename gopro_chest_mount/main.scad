include <../GoProScad/GoPro.scad>;

gopro_mount_f(
  base_height=10,
  base_width=24,
  leg_height=17,
  nut_diameter=11.5,
  nut_sides=6,
  nut_depth=3,
  center=true
);
cube([80, 80, 3], center=true);
