/*
  RC boat blink beacon v1
  -----------------------
  Requires BOSL2. Install it as an OpenSCAD library so these resolve:
    include <BOSL2/std.scad>
    include <BOSL2/threading.scad>

  Three printable parts:
    1. opaque body with integrated GoPro-compatible two-prong mount
    2. opaque LED carrier for a 20 mm star board
    3. translucent diffuser dome

  Select a part with `part` before exporting an STL.
  Units: millimetres.
*/

include <../BOSL2/std.scad>
include <../BOSL2/threading.scad>

part = "body"; // [assembly,body,carrier,dome]

$fn = 128;
eps = 0.05;

// Actual components ---------------------------------------------------------
pcb_length = 18.0;
pcb_width = 10.0;
pcb_total_thickness = 4.5;

// The compartment is deliberately longer than the bare PCB to accommodate
// solder joints and the bend radius of wires leaving both ends.
pcb_compartment_length = 21.5;
pcb_compartment_width = 11.5;

led_star_diameter = 20.0;
led_star_thickness = 2.0;
led_emitter_diameter = 8.5;
led_emitter_height = 4.5;

wire_diameter = 1.3;

// FDM fit tuning ------------------------------------------------------------
pcb_xy_clearance = 0.45;       // clearance on each side
pcb_z_clearance = 0.50;
general_fit = 0.25;            // radial fit for removable parts
wire_hole_clearance = 0.35;

// Beacon proportions --------------------------------------------------------
body_diameter = 33.0;
body_wall = 2.0;
body_floor = 2.2;
body_height = 9.5;
pcb_compartment_wall = 1.2;
pcb_rail_length = pcb_length + 1.0;

carrier_diameter = 30.0;
carrier_thickness = 3.2;
carrier_seat_depth = 1.4;
star_pocket_depth = 2.15;

// Eight low-force radial snaps retain the removable carrier.  The bumps only
// interfere with the plain socket by snap_interference; matching dimples give
// them somewhere to settle once fully seated.
snap_count = 8;
snap_bump_diameter = 1.4;
snap_interference = 0.15;
snap_bump_embed = snap_bump_diameter / 2 - general_fit - snap_interference;
snap_dimple_diameter = 1.65;

// Coarse, printable dome thread.  BOSL2 enlarges the internal thread by
// 4 * thread_slop; tune this value after the first fit test.
thread_diameter = 28.0;
thread_pitch = 2.0;
thread_length = 6.0;
thread_slop = 0.20;
thread_collar_wall = 2.0;

dome_wall = 1.6;
dome_top_thickness = 2.0;
dome_thread_start = carrier_thickness - carrier_seat_depth;
dome_skirt_height = dome_thread_start + thread_length + 0.5;
dome_height_above_skirt = 12.0;
dome_total_height = dome_skirt_height + dome_height_above_skirt;
dome_outer_diameter = 33.0;

// GoPro-compatible two-prong interface -------------------------------------
gopro_finger_thickness = 3.0;
gopro_center_gap = 3.5;
gopro_tip_diameter = 15.0;
gopro_hole_diameter = 5.5;
gopro_hole_teardrop_angle = 45;
gopro_finger_drop = 17.0;
gopro_neck_width = 18.0;
gopro_web_thickness = 3.0;

pcb_cavity = [
    pcb_compartment_length,
    pcb_compartment_width,
    pcb_total_thickness + pcb_z_clearance
];

module rounded_box(size, radius) {
    hull()
        for (x = [radius, size[0] - radius])
            for (y = [radius, size[1] - radius])
                translate([x, y, 0]) cylinder(r = radius, h = size[2]);
}

// Lightweight body core: a sealed floor, thin cylindrical exterior, and two
// free-standing PCB guide rails.  Their open ends leave the surrounding hollow
// annulus available for solder joints, wire bends, and excess wire.
module lightweight_body_shell() {
    rail_height = body_height - carrier_seat_depth - body_floor;

    union() {
        // Subtracting only above body_floor leaves a continuous sealed floor.
        difference() {
            cylinder(d = body_diameter, h = body_height);
            translate([0, 0, body_floor])
                cylinder(d = body_diameter - 2 * body_wall,
                         h = body_height - body_floor + eps);
        }

        // Two long rails locate the PCB laterally without enclosing its ends.
        for (y = [-(pcb_cavity[1] / 2 + pcb_compartment_wall),
                   pcb_cavity[1] / 2])
            translate([-pcb_rail_length / 2,
                       y,
                       body_floor - eps])
                rounded_box([
                    pcb_rail_length,
                    pcb_compartment_wall,
                    rail_height + 2 * eps
                ], pcb_compartment_wall / 2);
    }
}

// A GoPro-style pair of fingers. Screw axis runs along Y.
module gopro_two_prong() {
    total_y = 2 * gopro_finger_thickness + gopro_center_gap;
    tip_z = -gopro_finger_drop + gopro_tip_diameter / 2;

    // Short web joining the fingers to the beacon body.
    translate([-gopro_neck_width / 2, -total_y / 2, -gopro_web_thickness])
        cube([gopro_neck_width, total_y, gopro_web_thickness + eps]);

    // After rotate([90,0,0]), linear_extrude grows in negative Y.  Start at
    // each finger's positive-Y face so the pair remains centered on Y=0.
    for (y = [-gopro_center_gap / 2,
              total_y / 2])
        translate([0, y, 0])
            rotate([90, 0, 0])
                linear_extrude(height = gopro_finger_thickness)
                    difference() {
                        hull() {
                            translate([-gopro_neck_width / 2, -gopro_web_thickness])
                                square([gopro_neck_width, gopro_web_thickness]);
                            translate([0, tip_z])
                                circle(d = gopro_tip_diameter);
                        }
                        // The body is intended to print upside down with the
                        // GoPro fingers pointing upward.  Pointing this BOSL2
                        // teardrop toward model -Z therefore puts its pointed
                        // self-supporting roof upward in the print orientation.
                        translate([0, tip_z])
                            rotate(180)
                                teardrop2d(
                                    d = gopro_hole_diameter,
                                    ang = gopro_hole_teardrop_angle
                                );
                    }
}

module body() {
    socket_diameter = carrier_diameter + 2 * general_fit;
    snap_z = body_height - carrier_seat_depth / 2;
    snap_center_r = carrier_diameter / 2 - snap_bump_embed;

    difference() {
        union() {
            lightweight_body_shell();
            gopro_two_prong();
        }

        // Driver cavity: open from the top for assembly.
        translate([-pcb_cavity[0] / 2,
                   -pcb_cavity[1] / 2,
                   body_floor])
            rounded_box([
                pcb_cavity[0],
                pcb_cavity[1],
                body_height - body_floor + eps
            ], 1.0);

        // Recess locating the removable LED carrier.
        translate([0, 0, body_height - carrier_seat_depth])
            cylinder(d = socket_diameter,
                     h = carrier_seat_depth + 2 * eps);

        // Matching snap dimples.  Their centers match the carrier bumps but
        // the slightly larger diameter keeps the seated connection crisp
        // without making it excessively difficult to remove.
        for (a = [0 : 360 / snap_count : 359])
            rotate([0, 0, a + 45])
                translate([snap_center_r, 0, snap_z])
                    sphere(d = snap_dimple_diameter, $fn = 24);

        // One rounded slot lets all three external wires pass through the
        // bottom together.  It overlaps the enlarged PCB cavity and exits
        // beside the GoPro fork, so there is no hidden connecting tunnel.
        cable_slot_width = wire_diameter + 1.7;
        cable_slot_length = 3 * wire_diameter + 3.0;
        // Pull the slot inward so its complete 3 mm width overlaps the PCB
        // pocket by roughly 1.75 mm, rather than meeting it at a thin tangent.
        slot_x = pcb_cavity[0] / 2 - cable_slot_width * 0.08;
        hull()
            for (y = [-(cable_slot_length - cable_slot_width) / 2,
                       (cable_slot_length - cable_slot_width) / 2])
                translate([slot_x, y, -gopro_web_thickness - eps])
                    cylinder(d = cable_slot_width,
                             h = body_floor + gopro_web_thickness + 2 * eps);
    }
}

module carrier() {
    difference() {
        union() {
            cylinder(d = carrier_diameter, h = carrier_thickness);

            // Shallow embedded bumps give about 0.15 mm radial interference
            // before clicking into the body's matching dimples.
            for (a = [0 : 360 / snap_count : 359])
                rotate([0, 0, a + 45])
                    translate([carrier_diameter / 2 - snap_bump_embed,
                               0,
                               carrier_seat_depth / 2])
                        sphere(d = snap_bump_diameter, $fn = 24);

            // Male BOSL2 thread onto which the diffuser dome screws.
            translate([0, 0, carrier_thickness - eps])
                threaded_rod(
                    d = thread_diameter,
                    l = thread_length + eps,
                    pitch = thread_pitch,
                    anchor = BOTTOM,
                    blunt_start = true,
                    bevel = false,
                    $slop = 0
                );
        }

        // Circular pocket accepts the maximum diameter of the star board.
        translate([0, 0, carrier_thickness - star_pocket_depth])
            cylinder(d = led_star_diameter + 0.40,
                     h = star_pocket_depth + eps);

        // Two internal driver-to-LED wire passages. Their angle around the
        // carrier can be changed to match the star's solder pads.
        for (a = [0, 180])
            rotate([0, 0, a])
                translate([led_star_diameter / 2 - 2.2, 0, -eps])
                    cylinder(d = wire_diameter + 2 * wire_hole_clearance,
                             h = carrier_thickness + 2 * eps);

        // Hollow the threaded collar so it surrounds rather than covers the
        // LED.  The carrier floor beneath the star remains opaque.
        translate([0, 0, carrier_thickness - eps])
            cylinder(d = thread_diameter - 2 * thread_collar_wall,
                     h = thread_length + 2 * eps);
    }
}

module dome() {
    difference() {
        // A flat-ended cylinder can be printed inverted on its top face.
        // The thread and hollow interior then build upward without support.
        cylinder(d = dome_outer_diameter, h = dome_total_height);

        // Clearance around the exposed carrier edge.  This lets the dome
        // skirt descend until its lower face seats directly on the body.
        translate([0, 0, -eps])
            cylinder(d = carrier_diameter + 2 * general_fit,
                     h = dome_thread_start + 2 * eps);

        // Matching female BOSL2 thread.  With thread_slop=0.20, BOSL2 adds
        // 0.80 mm diametral clearance to this internal thread.  Its vertical
        // offset aligns it with the male collar when the dome is body-flush.
        translate([0, 0, dome_thread_start - eps])
            threaded_rod(
                d = thread_diameter,
                l = thread_length + 2 * eps,
                pitch = thread_pitch,
                internal = true,
                anchor = BOTTOM,
                blunt_start = true,
                bevel = false,
                $slop = thread_slop
            );

        // Open the full optical cavity above the threaded section.  Its
        // diameter leaves 1.6 mm translucent side walls.  The thicker 2 mm
        // top reduces the direct upward hotspot and provides stronger
        // diffusion while the thinner sides preserve lateral brightness.
        translate([0, 0, dome_thread_start + thread_length - eps])
            cylinder(d = dome_outer_diameter - 2 * dome_wall,
                     h = dome_total_height - dome_top_thickness -
                         dome_thread_start - thread_length + eps);
    }
}

module assembly(exploded = 0) {
    color("dimgray") body();

    color("black")
        translate([0, 0,
                   body_height - carrier_seat_depth + exploded])
            carrier();

    color([0.88, 0.92, 0.85, 0.50])
        translate([0, 0,
                   body_height + 2 * exploded])
            dome();

    // Component preview only; not exported as a printable part.
    if (part == "assembly") {
        color("silver")
            translate([0, 0,
                       body_height - carrier_seat_depth +
                       carrier_thickness - led_star_thickness + exploded])
                cylinder(d = led_star_diameter,
                         h = led_star_thickness,
                         $fn = 6);

        color("gold")
            translate([0, 0,
                       body_height - carrier_seat_depth +
                       carrier_thickness + exploded])
                cylinder(d = led_emitter_diameter,
                         h = led_emitter_height);
    }
}

if (part == "body")
    body();
else if (part == "carrier")
    carrier();
else if (part == "dome")
    dome();
else
    assembly(exploded = 0);
