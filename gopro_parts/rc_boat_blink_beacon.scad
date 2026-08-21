/*
  RC boat blink beacon v4 -- three parts, none of them need support
  -----------------------------------------------------------------
  Requires BOSL2:
    include <BOSL2/std.scad>
    include <BOSL2/threading.scad>

  Three printable parts:
    1. opaque body -- driver compartment and the GoPro two-prong mount
    2. opaque LED carrier -- holds a 20 mm star, carries the male thread
    3. translucent diffuser dome  (UNCHANGED since v1 -- already printed)

  Select a part with `part` before exporting an STL.
  Units: millimetres.  Material: PETG.

  ---------------------------------------------------------------------------
  WHY THE CARRIER PRINTS FLAT NOW
  ---------------------------------------------------------------------------
  The carrier is back, and this time it costs nothing to print.

  v2's carrier needed almost as much support as it contained filament, and the
  reason was self-inflicted: it carried a SNAP.  Six cantilever tongues need
  length, length meant a 6.4 mm skirt, a skirt made it a cup, and a cup printed
  open-end-down has a flat 25.2 mm roof.  That roof was the support.  None of
  it came from what the carrier is FOR.

  Strip the snap and the carrier is what it always should have been: a flat
  disc.  The star pocket opens upward, the threaded collar rises off the top
  face, the underside sits on the bed, and nothing overhangs anything.  It is
  retained the way v1 already retained it -- the dome screws onto its thread
  and bottoms on the body's face, so the carrier is captured between the two.
  A snap was never load-bearing here; it was a convenience that cost more to
  print than the part it was on.

  The body lost its PCB rails at the same time.  They were free-standing walls
  standing on a floor that, printed this way up, does not exist yet -- the only
  islands in the whole beacon.  With them gone the body's floor is a plain
  bridge anchored right around its rim, and it needs no support either.

  ANTI-ROTATION: the carrier's seat is keyed with two flats rather than being
  round, so screwing the dome down cannot spin the carrier and wind up the LED
  wires.  A flat costs nothing to print -- it is just a different cross section
  on a part that is already flat on the bed -- and the carrier and the body's
  counterbore are cut from ONE profile module so they cannot drift apart.

  Frozen, because the dome is already printed:
    * carrier_diameter 30.0 and its 1.8 mm of stand-off -- the dome's skirt bore
    * thread 28.0 x 2.0, 6 mm long
    * body/dome diameter 33.0
  All asserted below, and the build re-renders the dome every run and compares
  it against the mesh that is actually on the printer.

  PRINT ORIENTATION -- all three parts, no support anywhere:
    BODY:    counterbore face DOWN on the bed, GoPro fork UP.  The floor comes
             out as a bridge anchored around its rim.
    CARRIER: flat on its underside, star pocket and thread UP.
    DOME:    flat top face down.
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

led_star_diameter = 20.0;
led_star_thickness = 2.0;
led_emitter_diameter = 8.5;
led_emitter_height = 4.5;

wire_diameter = 1.3;

// FDM fit tuning ------------------------------------------------------------
general_fit = 0.25;            // DOME SEES THIS -- its skirt bore
star_pocket_fit = 0.40;        // diametral, star into its pocket
wire_hole_clearance = 0.35;
// Diametral, carrier into the body's counterbore.  Deliberately loose: the
// dome is what actually holds the carrier, so a slack seat still works and a
// tight one might not go together at all.
carrier_seat_fit = 0.20;

// Body ----------------------------------------------------------------------
body_diameter = 33.0;
body_wall = 2.0;
body_floor = 2.2;
body_height = 10.0;
// No PCB rails and no pocket: they were the only support-requiring features in
// the part, and the driver is held with tape.

// Carrier -------------------------------------------------------------------
carrier_diameter = 30.0;       // DOME SEES THIS -- do not change
carrier_proud = 1.8;           // stand-off above the body face == dome datum
carrier_seat_depth = 1.8;      // how much of it sits in the body counterbore
carrier_thickness = carrier_seat_depth + carrier_proud;   // 3.60
star_pocket_depth = 2.15;
// Flat-to-flat across the keyed seat.  Two flats, so there are two ways in and
// neither of them lets the carrier turn.
carrier_key_across = 28.0;

// Thread and dome -- FROZEN.  The dome is already printed.
thread_diameter = 28.0;
thread_pitch = 2.0;
thread_length = 6.0;
thread_slop = 0.20;
thread_collar_wall = 2.0;
collar_bore = thread_diameter - 2 * thread_collar_wall;   // 24.0

dome_wall = 1.6;
dome_top_thickness = 2.0;
dome_thread_start = carrier_proud;
dome_skirt_height = dome_thread_start + thread_length + 0.5;
dome_height_above_skirt = 12.0;
dome_total_height = dome_skirt_height + dome_height_above_skirt;
dome_outer_diameter = 33.0;

// GoPro-compatible two-prong interface -------------------------------------
// On the SAME 3 mm grid as arm.scad: fingers 2.90 into 3.10 slots.
gopro_finger_thickness = 2.90;   // == arm.scad  u - fing_under
gopro_center_gap = 3.10;         // == arm.scad  slot_w
gopro_tip_diameter = 15.0;       // == 2 * arm.scad tab_r
gopro_hole_diameter = 5.5;
gopro_hole_teardrop_angle = 45;
// v1 had 17.0, which put the pivot only 6.5 mm below the web -- INSIDE the
// mating knuckle's R7.5 (R7.75 on a real GoPro), so the beacon bottomed out
// about a millimetre before the bores lined up and the thumbscrew would not
// pass.  19.5 puts the pivot 9.0 mm down.
gopro_finger_drop = 19.5;
gopro_neck_width = 18.0;
gopro_web_thickness = 3.0;

gopro_pivot_z = -gopro_finger_drop + gopro_tip_diameter / 2;
gopro_pivot_clear = -gopro_web_thickness - gopro_pivot_z;

body_bore_r = body_diameter / 2 - body_wall;              // 14.5
carrier_floor_z = body_height - carrier_seat_depth;       // 8.2
star_pocket_floor = carrier_thickness - star_pocket_depth; // 1.45

// ---- invariants ----------------------------------------------------------
assert(carrier_diameter == 30.0, "dome skirt bore rides on carrier_diameter");
assert(general_fit == 0.25, "dome skirt bore is carrier_diameter + 2*general_fit");
assert(dome_thread_start == 1.8, "dome thread starts 1.8 above its bottom face");
assert(carrier_proud == dome_thread_start,
       "the carrier must stand exactly dome_thread_start above the body face");
assert(thread_diameter == 28.0 && thread_pitch == 2.0 && thread_length == 6.0,
       "male thread must match the printed dome");
assert(dome_total_height == 20.3, "dome height changed -- the printed one is 20.3");
assert(body_diameter == dome_outer_diameter, "dome should sit flush on the body");

// The carrier is a DISC.  If anything ever grows below its underside it stops
// printing flat, which is the entire point of this revision.
assert(carrier_thickness == carrier_seat_depth + carrier_proud,
       "carrier is a plain disc: seat + proud, nothing else");
assert(star_pocket_floor >= 1.0,
       "too little opaque floor left under the star pocket");
assert(led_star_diameter + star_pocket_fit < collar_bore,
       "star cannot be dropped in through the threaded collar");
assert(carrier_key_across < carrier_diameter,
       "key flats must actually cut the circle or they key nothing");
assert(carrier_key_across > collar_bore + 1.0,
       "key flats cut into the collar bore");

// The compartment only holds the driver now -- the star lives in the carrier.
assert(carrier_floor_z - body_floor >= pcb_total_thickness + 1.0,
       "compartment too short for the driver");

assert(gopro_pivot_clear >= 7.75 + 1.0,
       "web fouls the mating knuckle -- lengthen gopro_finger_drop");
assert(gopro_tip_diameter / 2 == 7.5, "knuckle must match arm.scad tab_r");

// ---- geometry -------------------------------------------------------------

// The keyed seat, defined ONCE.  The carrier is extruded from it and the
// body's counterbore is cut with it one clearance larger, so the two cannot
// drift apart the way two hand-matched profiles would.
module keyed_profile(d, across) {
    intersection() {
        circle(d = d);
        square([d + 1, across], center = true);
    }
}

module body() {
    difference() {
        union() {
            // Shell: sealed floor, thin cylindrical exterior, nothing inside.
            difference() {
                cylinder(d = body_diameter, h = body_height);
                // Stops at the counterbore, NOT at the top: the plain bore is
                // wider than the key is across its flats, so running it the
                // full height quietly erases the key and leaves a round seat
                // that lets the carrier spin.
                translate([0, 0, body_floor])
                    cylinder(d = 2 * body_bore_r,
                             h = carrier_floor_z - body_floor + eps);
            }
            gopro_two_prong();
        }

        // Counterbore the carrier drops into, keyed so it cannot turn.
        translate([0, 0, carrier_floor_z])
            linear_extrude(height = carrier_seat_depth + eps)
                keyed_profile(carrier_diameter + carrier_seat_fit,
                              carrier_key_across + carrier_seat_fit);

        // One rounded slot lets all three external wires pass through the
        // bottom together.  It exits beside the GoPro fork, so there is no
        // hidden connecting tunnel.
        cable_slot_width = wire_diameter + 1.7;
        cable_slot_length = 3 * wire_diameter + 3.0;
        hull()
            for (y = [-(cable_slot_length - cable_slot_width) / 2,
                       (cable_slot_length - cable_slot_width) / 2])
                translate([body_bore_r - cable_slot_width, y,
                           -gopro_web_thickness - eps])
                    cylinder(d = cable_slot_width,
                             h = body_floor + gopro_web_thickness + 2 * eps);
    }
}

// A GoPro-style pair of fingers. Screw axis runs along Y.
module gopro_two_prong() {
    total_y = 2 * gopro_finger_thickness + gopro_center_gap;
    tip_z = gopro_pivot_z;

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
                            translate([0, tip_z]) circle(d = gopro_tip_diameter);
                        }
                        // The body prints with the fingers pointing UP, so this
                        // teardrop points at model -Z to put its self-supporting
                        // roof upward in the print orientation.
                        translate([0, tip_z])
                            rotate(180)
                                teardrop2d(d = gopro_hole_diameter,
                                           ang = gopro_hole_teardrop_angle);
                    }
}

// A flat disc.  Everything on it faces up.
module carrier() {
    difference() {
        union() {
            // One cylinder for the whole disc.  The key is CUT out of its
            // lower band further down rather than being a second solid unioned
            // on: a keyed extrusion stacked under a round one shares a curved
            // face over the entire overlap, and that union exports with ~140
            // non-manifold edges while still reporting "manifold".
            cylinder(d = carrier_diameter, h = carrier_thickness);

            // Male BOSL2 thread the dome screws onto.
            translate([0, 0, carrier_thickness - eps])
                threaded_rod(d = thread_diameter,
                             l = thread_length + eps,
                             pitch = thread_pitch,
                             anchor = BOTTOM,
                             blunt_start = true,
                             bevel = false,
                             $slop = 0);
        }

        // The key: two flats on the seat only.  The rim above them returns to
        // full diameter, so each flat is capped by a ~1 mm ledge -- short
        // enough to print unsupported, and it is what stops the carrier
        // turning when the dome is screwed down onto it.
        for (m = [0, 1])
            mirror([0, m, 0])
                translate([-carrier_diameter, carrier_key_across / 2, -eps])
                    cube([2 * carrier_diameter,
                          carrier_diameter,
                          carrier_seat_depth + eps]);

        // The star's pocket -- opens upward, so it costs nothing to print.
        translate([0, 0, star_pocket_floor])
            cylinder(d = led_star_diameter + star_pocket_fit,
                     h = star_pocket_depth + eps);

        // Two driver-to-LED wire passages through the opaque floor.  Their
        // angle can be turned to match the star's solder pads.
        for (a = [0, 180])
            rotate([0, 0, a])
                translate([led_star_diameter / 2 - 2.2, 0, -eps])
                    cylinder(d = wire_diameter + 2 * wire_hole_clearance,
                             h = star_pocket_floor + 2 * eps);

        // Hollow the threaded collar so it surrounds rather than covers the
        // LED.  The floor beneath the star stays opaque.
        translate([0, 0, carrier_thickness - eps])
            cylinder(d = collar_bore, h = thread_length + 2 * eps);
    }
}

module dome() {
    difference() {
        // A flat-ended cylinder printed inverted on its top face.  The thread
        // and hollow interior then build upward without support.
        cylinder(d = dome_outer_diameter, h = dome_total_height);

        // Clearance around the exposed carrier edge, so the dome skirt can
        // descend until its lower face seats on the body.
        translate([0, 0, -eps])
            cylinder(d = carrier_diameter + 2 * general_fit,
                     h = dome_thread_start + 2 * eps);

        // Matching female thread.  With thread_slop=0.20 BOSL2 adds 0.80 mm
        // diametral clearance here.
        translate([0, 0, dome_thread_start - eps])
            threaded_rod(d = thread_diameter,
                         l = thread_length + 2 * eps,
                         pitch = thread_pitch,
                         internal = true,
                         anchor = BOTTOM,
                         blunt_start = true,
                         bevel = false,
                         $slop = thread_slop);

        // The optical cavity: 1.6 mm translucent sides, a thicker 2 mm top to
        // knock down the upward hotspot.
        translate([0, 0, dome_thread_start + thread_length - eps])
            cylinder(d = dome_outer_diameter - 2 * dome_wall,
                     h = dome_total_height - dome_top_thickness -
                         dome_thread_start - thread_length + eps);
    }
}

module assembly(exploded = 0) {
    color("dimgray") body();
    color("black") translate([0, 0, carrier_floor_z + exploded]) carrier();
    color([0.88, 0.92, 0.85, 0.50])
        translate([0, 0, body_height + 2 * exploded]) dome();

    if (part == "assembly") {
        color("green")
            translate([-pcb_length / 2, -pcb_width / 2, body_floor + exploded])
                cube([pcb_length, pcb_width, pcb_total_thickness]);
        color("silver")
            translate([0, 0, carrier_floor_z + star_pocket_floor + exploded])
                cylinder(d = led_star_diameter, h = led_star_thickness, $fn = 6);
        color("gold")
            translate([0, 0, carrier_floor_z + star_pocket_floor
                             + led_star_thickness + exploded])
                cylinder(d = led_emitter_diameter, h = led_emitter_height);
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
