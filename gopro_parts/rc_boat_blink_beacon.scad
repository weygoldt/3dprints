/*
  RC boat blink beacon v3 -- TWO PARTS
  -----------------------------------
  Requires BOSL2. Install it as an OpenSCAD library so these resolve:
    include <BOSL2/std.scad>
    include <BOSL2/threading.scad>

  Two printable parts:
    1. opaque body -- driver compartment, GoPro two-prong mount, and the male
       thread the dome screws straight onto
    2. translucent diffuser dome  (UNCHANGED since v1 -- already printed)

  Select a part with `part` before exporting an STL.
  Units: millimetres.  Material: PETG.

  ---------------------------------------------------------------------------
  WHY THE CARRIER IS GONE
  ---------------------------------------------------------------------------
  v1 and v2 had a third part: an LED carrier that snapped into the body and
  carried the thread.  v2 finally made that snap work -- 0.40 mm of engagement
  on six cantilever tongues instead of v1's 0.144 mm against a rigid ring --
  and it was still the wrong part to have.

  It was a shallow cup printed open-end-down, so its rim underside was a flat
  25.2 mm roof, and no chamfer fixes that: closing the bore at 45 deg needs
  12.6 mm of height and the rim had 3.2.  Sliced with support that roof cost
  1.96 cm^3 -- against a part that was only 2.71 cm^3.  Support very nearly as
  large as the part it held up, to mount an LED board that can simply be glued
  to the driver.

  So the dome now threads DIRECTLY onto the body, the LED star is glued to the
  driver, and the whole 25 mm roof problem stops existing rather than being
  managed.  Everything the dome touches is unchanged, so the printed dome
  still fits:
    * boss diameter 30.0 and its 1.8 mm of stand-off  -- the dome's skirt bore
    * thread 28.0 x 2.0, 6 mm long                    -- the dome's thread
    * body diameter 33.0                              -- flush with the dome
  Those are asserted below and the build re-renders the dome every run and
  compares it against the mesh that is actually on the printer.

  ---------------------------------------------------------------------------
  PRINT ORIENTATION
  ---------------------------------------------------------------------------
  BODY:  thread DOWN on the bed, GoPro fork UP.  USE A BRIM -- the bed contact
         is the thread's end face, a 28/24 annulus of about 163 mm^2 under a
         part 37 mm tall, which is tippy without one.  Everything above it
         then builds the right way up: the thread's flanks are self-supporting
         printed this way, the collar and body walls are vertical, and the
         floor comes out as a bridge anchored right around its rim.
         It DOES want support, for the two PCB rails: printed this way up the
         floor is the last thing laid down, so the rails -- which stand on it
         -- start in mid-air.  That is a deliberate trade.  Rails cost two thin
         walls; the pocket that would replace them costs a solid floor to sink
         it into, which is more material than the support saves.
  DOME:  flat top face down, as before.  Needs nothing.
*/

include <../BOSL2/std.scad>
include <../BOSL2/threading.scad>

part = "body"; // [assembly,body,dome]

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
pcb_z_clearance = 0.50;
general_fit = 0.25;            // radial fit -- DOME SEES THIS
wire_hole_clearance = 0.35;

// Beacon proportions --------------------------------------------------------
// Back to v1's 9.5 with the carrier gone: the compartment only has to hold the
// driver and the star glued on top of it, and the collar above carries the
// thread.  v2 needed 11.0 purely to give the snap tongues their travel.
body_diameter = 33.0;
body_wall = 2.0;
body_floor = 2.2;
body_height = 9.5;
pcb_compartment_wall = 1.2;
pcb_rail_length = pcb_length + 1.0;
// Exactly the driver's own thickness, so the rails guide it for its full
// height and then stop -- the star is glued on top of the driver and would
// foul anything that carried on past it.
rail_height = pcb_total_thickness;

// The light collar: the boss the dome's skirt rides on, and the thread -----
// FROZEN.  The dome is already printed; these are every dimension it touches.
collar_boss_diameter = 30.0;
collar_proud = 1.8;            // stand-off before the thread starts
thread_diameter = 28.0;
thread_pitch = 2.0;
thread_length = 6.0;
thread_slop = 0.20;
thread_collar_wall = 2.0;
// What the light actually leaves through, and what the driver plus its glued
// star has to be posted in through on assembly.
collar_bore = thread_diameter - 2 * thread_collar_wall;   // 24.0

dome_wall = 1.6;
dome_top_thickness = 2.0;
dome_thread_start = collar_proud;
dome_skirt_height = dome_thread_start + thread_length + 0.5;
dome_height_above_skirt = 12.0;
dome_total_height = dome_skirt_height + dome_height_above_skirt;
dome_outer_diameter = 33.0;

// GoPro-compatible two-prong interface -------------------------------------
// On the SAME 3 mm grid as arm.scad: fingers 2.90 into 3.10 slots, 0.10 per
// feature.  v1 ran 3.00 fingers on a 3.50 centre gap, which put each finger
// 0.20 mm outboard of the arm's slot -- it went together, but it was fighting.
gopro_finger_thickness = 2.90;   // == arm.scad  u - fing_under
gopro_center_gap = 3.10;         // == arm.scad  slot_w
gopro_tip_diameter = 15.0;       // == 2 * arm.scad tab_r
gopro_hole_diameter = 5.5;       // clears M5 with room; teardrop, prints under
gopro_hole_teardrop_angle = 45;
// v1 had 17.0, which put the pivot only 6.5 mm below the web -- INSIDE the
// mating knuckle's R7.5 (R7.75 on a real GoPro).  The beacon bottomed out on
// the knuckle about a millimetre before the bores lined up, so the thumbscrew
// would not pass.  19.5 puts the pivot 9.0 mm down: 1.50 clear of our arms,
// 1.25 clear of a genuine GoPro, and enough for the joint to swing.
gopro_finger_drop = 19.5;
gopro_neck_width = 18.0;
gopro_web_thickness = 3.0;

gopro_pivot_z = -gopro_finger_drop + gopro_tip_diameter / 2;
gopro_pivot_clear = -gopro_web_thickness - gopro_pivot_z;

body_bore_r = body_diameter / 2 - body_wall;
collar_top = body_height + collar_proud + thread_length;

pcb_cavity = [
    pcb_compartment_length,
    pcb_compartment_width,
    pcb_total_thickness + pcb_z_clearance
];

// ---- invariants ----------------------------------------------------------
// The dome is on the printer.  These are every dimension it can reach; if one
// moves, the printed dome no longer fits and the assert says so instead of the
// mesh saying nothing.
assert(collar_boss_diameter == 30.0, "dome skirt bore rides on the boss");
assert(general_fit == 0.25, "dome skirt bore is boss + 2*general_fit");
assert(dome_thread_start == 1.8, "dome thread starts 1.8 above its bottom face");
assert(collar_proud == dome_thread_start,
       "the boss must stand exactly dome_thread_start above the body face");
assert(thread_diameter == 28.0 && thread_pitch == 2.0 && thread_length == 6.0,
       "male thread must match the printed dome");
assert(dome_total_height == 20.3, "dome height changed -- the printed one is 20.3");
assert(body_diameter == dome_outer_diameter, "dome should sit flush on the body");

// The stack has to fit under the collar, and the driver plus its glued-on star
// has to be able to go IN, which means through the collar bore.
assert(body_height - body_floor >= pcb_total_thickness + led_star_thickness,
       "compartment too short for the driver plus the star glued on it");
assert(collar_bore > sqrt(pow(pcb_length, 2) + pow(pcb_width, 2)) + 1.0,
       "driver will not pass through the collar bore on assembly");
assert(collar_bore > led_star_diameter + 1.0,
       "LED star will not pass through the collar bore on assembly");

// Rails guide the driver and must stop before the star that sits on it.
assert(body_floor + rail_height <= body_floor + pcb_total_thickness,
       "rails run past the driver and would foul the star glued on top");
assert(sqrt(pow(pcb_rail_length / 2, 2) +
            pow(pcb_cavity[1] / 2 + pcb_compartment_wall, 2)) < body_bore_r,
       "PCB rails run out through the bore wall");

// GoPro joint: the web must clear the mating knuckle or the screw cannot pass.
assert(gopro_pivot_clear >= 7.75 + 1.0,
       "web fouls the mating knuckle -- lengthen gopro_finger_drop");
assert(gopro_tip_diameter / 2 == 7.5, "knuckle must match arm.scad tab_r");

module rounded_box(size, radius) {
    hull()
        for (x = [radius, size[0] - radius])
            for (y = [radius, size[1] - radius])
                translate([x, y, 0]) cylinder(r = radius, h = size[2]);
}

// Body core: a sealed floor, a thin cylindrical exterior, and two PCB rails.
module lightweight_body_shell() {
    union() {
        // Subtracting only above body_floor leaves a continuous sealed floor.
        difference() {
            cylinder(d = body_diameter, h = body_height);
            translate([0, 0, body_floor])
                cylinder(d = body_diameter - 2 * body_wall,
                         h = body_height - body_floor + eps);
        }

        // Two rails locate the driver laterally without enclosing its ends,
        // so the surrounding annulus stays free for solder joints and wire.
        for (y = [-(pcb_cavity[1] / 2 + pcb_compartment_wall),
                   pcb_cavity[1] / 2])
            translate([-pcb_rail_length / 2, y, body_floor - eps])
                rounded_box([pcb_rail_length,
                             pcb_compartment_wall,
                             rail_height + eps], pcb_compartment_wall / 2);
    }
}

// The collar the dome screws onto: a plain boss for the dome's skirt bore to
// ride on, then the male thread.  Hollow all the way through -- it is the
// light path out, and the hole the electronics go in through.
module light_collar() {
    translate([0, 0, body_height - eps])
        cylinder(d = collar_boss_diameter, h = collar_proud + eps);

    translate([0, 0, body_height + collar_proud - eps])
        threaded_rod(d = thread_diameter,
                     l = thread_length + eps,
                     pitch = thread_pitch,
                     anchor = BOTTOM,
                     blunt_start = true,
                     bevel = false,
                     $slop = 0);
}

// A GoPro-style pair of fingers. Screw axis runs along Y.
module gopro_two_prong() {
    total_y = 2 * gopro_finger_thickness + gopro_center_gap;
    tip_z = gopro_pivot_z;

    // Short web joining the fingers to the beacon body.
    translate([-gopro_neck_width / 2, -total_y / 2, -gopro_web_thickness])
        cube([gopro_neck_width, total_y, gopro_web_thickness + eps]);

    // After rotate([90,0,0]), linear_extrude grows in negative Y.  Start at
    // each finger's positive-Y face so the pair remains centered on Y=0.
    for (y = [-gopro_center_gap / 2, total_y / 2])
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
                        // The body prints with the GoPro fingers pointing UP.
                        // Pointing this BOSL2 teardrop toward model -Z puts its
                        // self-supporting roof upward in the print orientation.
                        translate([0, tip_z])
                            rotate(180)
                                teardrop2d(d = gopro_hole_diameter,
                                           ang = gopro_hole_teardrop_angle);
                    }
}

module body() {
    difference() {
        union() {
            lightweight_body_shell();
            light_collar();
            gopro_two_prong();
        }

        // Driver compartment.
        translate([-pcb_cavity[0] / 2, -pcb_cavity[1] / 2, body_floor])
            rounded_box([pcb_cavity[0],
                         pcb_cavity[1],
                         body_height - body_floor + eps], 1.0);

        // The collar bore: light out, electronics in.  It starts at the body
        // face, NOT at the floor -- the compartment below is already hollow,
        // and a d=24 bore taken all the way down eats everything inside r=12,
        // which is the PCB rails (they reach r=11.77) and most of what makes
        // this a compartment at all.  It deleted them silently; the rails were
        // simply absent from the mesh.
        translate([0, 0, body_height - eps])
            cylinder(d = collar_bore, h = collar_top - body_height + 2 * eps);

        // One rounded slot lets all three external wires pass through the
        // bottom together.  It overlaps the compartment and exits beside the
        // GoPro fork, so there is no hidden connecting tunnel.
        cable_slot_width = wire_diameter + 1.7;
        cable_slot_length = 3 * wire_diameter + 3.0;
        slot_x = pcb_cavity[0] / 2 - cable_slot_width * 0.08;
        hull()
            for (y = [-(cable_slot_length - cable_slot_width) / 2,
                       (cable_slot_length - cable_slot_width) / 2])
                translate([slot_x, y, -gopro_web_thickness - eps])
                    cylinder(d = cable_slot_width,
                             h = body_floor + gopro_web_thickness + 2 * eps);
    }
}

module dome() {
    difference() {
        // A flat-ended cylinder can be printed inverted on its top face.
        // The thread and hollow interior then build upward without support.
        cylinder(d = dome_outer_diameter, h = dome_total_height);

        // Clearance around the boss.  This lets the dome skirt descend until
        // its lower face seats directly on the body.
        translate([0, 0, -eps])
            cylinder(d = collar_boss_diameter + 2 * general_fit,
                     h = dome_thread_start + 2 * eps);

        // Matching female BOSL2 thread.  With thread_slop=0.20, BOSL2 adds
        // 0.80 mm diametral clearance to this internal thread.  Its vertical
        // offset aligns it with the male collar when the dome is body-flush.
        translate([0, 0, dome_thread_start - eps])
            threaded_rod(d = thread_diameter,
                         l = thread_length + 2 * eps,
                         pitch = thread_pitch,
                         internal = true,
                         anchor = BOTTOM,
                         blunt_start = true,
                         bevel = false,
                         $slop = thread_slop);

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

    color([0.88, 0.92, 0.85, 0.50])
        translate([0, 0, body_height + 2 * exploded])
            dome();

    // Component preview only; not exported as a printable part.  The star is
    // GLUED to the driver -- that is what replaced the carrier.
    if (part == "assembly") {
        color("green")
            translate([-pcb_length / 2, -pcb_width / 2, body_floor + exploded])
                cube([pcb_length, pcb_width, pcb_total_thickness]);

        color("silver")
            translate([0, 0, body_floor + pcb_total_thickness + exploded])
                cylinder(d = led_star_diameter, h = led_star_thickness, $fn = 6);

        color("gold")
            translate([0, 0,
                       body_floor + pcb_total_thickness + led_star_thickness
                       + exploded])
                cylinder(d = led_emitter_diameter, h = led_emitter_height);
    }
}

if (part == "body")
    body();
else if (part == "dome")
    dome();
else
    assembly(exploded = 0);
