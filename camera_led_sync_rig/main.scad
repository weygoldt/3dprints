$fn = $preview ? 24 : 120;

include <BOSL2/std.scad>

tube_od = 50.1;
wall_thick = 3;
sleeve_height = 20;

gopro_macro_lens_d = 44.2;
gopro_lens_a = 33;
action5_lens_d = 36;
dji_mini_camera_ab = [17, 22];
led_d = 5.1;
epi_d = 13.5;

module pipe_sleeve() {
  difference() {

    cylinder(h=sleeve_height, d=tube_od + 2 * wall_thick, center=true);

    // Inner cylinder (to create the wall thickness)
    translate([0, 0, -wall_thick])
      cylinder(h=sleeve_height, d=tube_od, center=true);
  }
}

module gopro_macro_sleeve() {
  difference() {
    pipe_sleeve();
    cylinder(h=sleeve_height + 2 * wall_thick, d=gopro_macro_lens_d, center=true);
  }
}

module gopro_sleeve() {
  difference() {
    pipe_sleeve();
    cuboid([gopro_lens_a, gopro_lens_a, sleeve_height + 2 * wall_thick], rounding=5);
  }
}

module action5_sleeve() {
  difference() {
    pipe_sleeve();
    cylinder(h=sleeve_height + 2 * wall_thick, d=action5_lens_d, center=true);
  }
}

module led_sleeve() {
  difference() {
    pipe_sleeve();
    cylinder(h=sleeve_height + 2 * wall_thick, d=led_d, center=true);
  }
}

module epi_sleeve() {
  difference() {
    pipe_sleeve();
    cylinder(h=sleeve_height + 2 * wall_thick, d=epi_d, center=true);
  }
}

module dji_mini_camera_sleeve() {
  difference() {
    pipe_sleeve();
    cuboid([dji_mini_camera_ab[0], dji_mini_camera_ab[1], sleeve_height + 2 * wall_thick], rounding=5);
  }
}

//gopro_macro_sleeve();
//action5_sleeve();
//gopro_sleeve();
//led_sleeve();
//epi_sleeve();
dji_mini_camera_sleeve();
