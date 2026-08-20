// MOTOR-CLOCK probe.  Which screen diagonal does each hull's LONG screw axis lie on, seen from
// Patrick's viewpoint: standing at the BOW looking AFT at the motors' mounting faces (the screw
// heads).  In that view  screen-right = -X  and  screen-up = -Y  (assembly frame has +X starboard,
// +Y down, +Z bow), so the PORT motor appears on the viewer's RIGHT.
//
// Renders ONE marker at ONE motor hole, carried through the same chain main.scad uses.  Read its
// centroid from the STL bounds; the driver turns four of them into the two axis directions.
//   -D hull="port"|"starboard"   -D hole=0..3     (0,1 = LONG pair r=9.5 ; 2,3 = SHORT pair r=8)
include <common.scad>
include <connector.scad>          // hull_dx
conn_show = "none";

hull = "port";
hole = 0;
what = "hole";      // "hole" = a motor screw hole | "wire" = the wire-slot exit direction | "hub" = pad centre
wire_r = 30;        // radius along the slot direction for the "wire" marker (well outside the hub)

// placement = "assembly" reproduces assembly_scene() (which MIRRORS the starboard hull).
// placement = "physical" is how the printed part actually goes on: the pylon foot is symmetric
// across its width (full-width tongue, symmetric 4-bolt pattern), so ONE part fits either hull in
// exactly ONE orientation (pad aft, mast up) -- a pure TRANSLATION, with no mirror available.
placement = "assembly";     // "assembly" | "physical"
dir_over  = 0;              // 0 = use mrot_of() per hull ; else force this motor_offset_dir

sgn = (hull == "starboard") ?  1 : -1;
rot = (dir_over != 0) ? mrot_of(dir_over)
    : (placement == "assembly") ? mrot_display((hull == "starboard") ? -1 : 1)   // preview clock
    :                             mrot_of((hull == "starboard") ? -1 : 1);       // part clock

module side_maybe(h) { if (placement == "assembly") apply_side_of(h) children(); else children(); }

module marker()
  translate([sgn*hull_dx, 0, 0]) side_maybe(hull)
    translate([0, 0, box_back_z])
      translate([pylon_width/2, mm_pad_yc + foot_h/2, mm_block_aft_z]) rotate(a=180, v=[1,0,-1])
        motor_tilted()
          if (what == "hole")
            translate([pad_aft - motor_seat_t,
                       pylon_rise + mholes(rot)[hole][0],
                       motor_zc   + mholes(rot)[hole][1]])
              cube(0.8, center = true);
          else if (what == "hub")
            translate([pad_aft, pylon_rise, motor_zc]) cube(0.8, center = true);
          else   // "wire": same construction main.scad uses for the lead ghost, at a bigger radius
            translate([pad_aft, pylon_rise, motor_zc]) rotate([0,90,0])
              rotate([0,0,wsa((dir_over != 0) ? dir_over : ((hull == "starboard") ? -1 : 1))])
                translate([wire_r, 0, 0]) cube(0.8, center = true);

marker();
