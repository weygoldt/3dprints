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
// BAYONET.  The carrier drops in and twists a quarter turn to lock under two
// ledges in the body.  This is what actually holds the beacon together, and it
// took a wrong turn to see why: the dome screws onto the CARRIER, so tightening
// it clamps the dome and carrier to each other and does nothing at all to the
// body -- the whole top assembly just lifts off.  v1 had a snap here and I
// deleted it as a convenience.  It was not; it was the only retention there
// was.
//
// A bayonet rather than another snap because it needs no elastic tuning: every
// fit in it is a loose clearance, and it either engages or visibly does not.
// The lock direction is CLOCKWISE seen from above, which is the direction the
// dome's right-hand thread drives the carrier when you tighten it -- so doing
// up the dome pushes the lobes harder into their stops instead of backing them
// out, and that is also what keeps the carrier from spinning and winding up the
// LED wires.
bay_seat_diameter = 27.0;      // the carrier's shank, below the flange
bay_lobe_angle = 60;           // arc each lobe covers
bay_lobe_height = 0.80;        // axial thickness of a lobe
bay_travel = 90;               // quarter turn from slot to stop
bay_fit = 0.20;                // diametral clearance, lobes and shank
bay_fit_angle = 1.0;           // angular clearance either side of a lobe
bay_lobe_z_fit = 0.15;         // axial slack in the groove

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
// The bayonet only retains anything if the ledge it hooks under is real: the
// lobes must be WIDER than the shank the body's counterbore is bored to, and
// there must be body left outboard of them to be a ledge at all.
assert(carrier_diameter > bay_seat_diameter + 1.0,
       "lobes barely stand proud of the shank -- nothing to hook under");
assert(bay_lobe_height + bay_lobe_z_fit < carrier_seat_depth,
       "groove is as deep as the seat, so there is no ledge above the lobes");
assert(body_diameter / 2 - (carrier_diameter + bay_fit) / 2 >= 1.2,
       "too little wall left outboard of the bayonet slots");
assert(bay_lobe_angle * 2 + bay_travel < 360,
       "lobes cannot travel a quarter turn without meeting each other");
assert(bay_seat_diameter > collar_bore,
       "shank is narrower than the collar bore it has to clear");

// The compartment only holds the driver now -- the star lives in the carrier.
assert(carrier_floor_z - body_floor >= pcb_total_thickness + 1.0,
       "compartment too short for the driver");

assert(gopro_pivot_clear >= 7.75 + 1.0,
       "web fouls the mating knuckle -- lengthen gopro_finger_drop");
assert(gopro_tip_diameter / 2 == 7.5, "knuckle must match arm.scad tab_r");

// ---- geometry -------------------------------------------------------------

// One pie-slice, from a0 to a1 degrees.  Both the carrier's lobes and the
// body's slots and grooves are cut from this, so a lobe and the pocket it has
// to enter cannot drift apart the way two hand-matched profiles would.
module arc_sector_2d(a0, a1, r) {
    polygon(concat([[0, 0]],
            [for (i = [0 : 64]) let (t = a0 + (a1 - a0) * i / 64)
                [r * cos(t), r * sin(t)]]));
}

module arc_sector(a0, a1, r, h) {
    linear_extrude(height = h) arc_sector_2d(a0, a1, r);
}

// Where each lobe sits when the carrier is dropped in, before the twist.
function bay_entry(i) = i * 360 / 2;

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

        // The bayonet socket, in three pieces:
        //   the bore the carrier's shank turns in, full depth;
        //   two entry slots, also full depth, that the lobes drop through;
        //   two grooves at the BOTTOM only, that the lobes twist along.
        // What is left between a groove and the body's top face is the ledge,
        // and that ledge is the entire reason the beacon stays together.
        translate([0, 0, carrier_floor_z - eps])
            cylinder(d = bay_seat_diameter + bay_fit,
                     h = carrier_seat_depth + 2 * eps);

        for (i = [0 : 1]) {
            e = bay_entry(i);
            // Entry slot: straight down, one lobe wide plus clearance.
            translate([0, 0, carrier_floor_z - eps])
                arc_sector(e - bay_lobe_angle / 2 - bay_fit_angle,
                           e + bay_lobe_angle / 2 + bay_fit_angle,
                           (carrier_diameter + bay_fit) / 2,
                           carrier_seat_depth + 2 * eps);

            // Groove: runs CLOCKWISE from the slot by a quarter turn, and stops
            // there.  The stop is what the dome tightens the lobe against.
            translate([0, 0, carrier_floor_z - eps])
                arc_sector(e - bay_lobe_angle / 2 - bay_travel - bay_fit_angle,
                           e + bay_lobe_angle / 2 + bay_fit_angle,
                           (carrier_diameter + bay_fit) / 2,
                           bay_lobe_height + bay_lobe_z_fit + eps);
        }

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
            // Flange: the full-diameter part, from the top of the shank up.
            // Its underside IS a datum -- it lands on the body's face -- so it
            // starts exactly at carrier_seat_depth, and the shank below carries
            // the eps overlap instead.  Growing the flange DOWN by eps buries
            // 0.05 mm of full-diameter disc in the body's top face, which the
            // interference probe reports as 4.12 mm^3 of foul.
            translate([0, 0, carrier_seat_depth])
                cylinder(d = carrier_diameter, h = carrier_proud);

            // The lobe band, extruded from ONE 2D profile rather than unioned
            // together as solids.  Unioning the sectors onto the shank in 3D
            // exported two non-manifold edges where a lobe's radial face
            // crossed the shank's wall -- a 2D union has no such seam to get
            // wrong, and it is one extrusion instead of three.
            // The band's round part is deliberately 0.2 UNDER the shank above
            // it.  Made equal, the two solids share an identical cylindrical
            // face across their overlap and the union exports 136 non-manifold
            // edges; offset, there is no coincident surface anywhere and it
            // comes out clean.  The 0.1 mm step it leaves is inside the body's
            // bore and does nothing.
            linear_extrude(height = bay_lobe_height)
                union() {
                    circle(d = bay_seat_diameter - 0.2);
                    for (i = [0 : 1])
                        arc_sector_2d(bay_entry(i) - bay_lobe_angle / 2,
                                      bay_entry(i) + bay_lobe_angle / 2,
                                      carrier_diameter / 2);
                }

            // Shank: narrower, so the body has somewhere to put a ledge.
            translate([0, 0, bay_lobe_height - eps])
                cylinder(d = bay_seat_diameter,
                         h = carrier_seat_depth - bay_lobe_height + 2 * eps);

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

// The carrier where it actually lives: dropped in and twisted CLOCKWISE to the
// stop.  Everything below is measured against this, not against the angle it
// goes in at.
module carrier_locked(lift = 0) {
    translate([0, 0, carrier_floor_z + lift])
        rotate([0, 0, -bay_travel])
            carrier();
}

module assembly(exploded = 0) {
    color("dimgray") body();
    color("black") carrier_locked(exploded);
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

// ---- probes ---------------------------------------------------------------
// Two booleans that between them answer the question the whole revision exists
// for: is the carrier actually held down, or does it just rest there?
//
// probe_seated  the locked carrier against the body.  Must be EMPTY -- it has
//               to be able to reach the locked position at all.
// probe_lift    the same carrier lifted 1 mm.  Must NOT be empty: the volume it
//               reports is lobe driven into ledge, which is exactly the
//               material that has to fail before the beacon comes apart.  On
//               the version I shipped before this one it renders as nothing.
module probe_seated() {
    intersection() { body(); carrier_locked(); }
}

module probe_lift() {
    intersection() { body(); carrier_locked(lift = 1.0); }
}

// And the third case, which has to stay clear or it could never be assembled:
// the carrier at the ENTRY angle, lifted.  Nothing should be in its way.
module probe_entry() {
    intersection() {
        body();
        translate([0, 0, carrier_floor_z + 1.0]) carrier();
    }
}

if (part == "body")
    body();
else if (part == "carrier")
    carrier();
else if (part == "dome")
    dome();
else if (part == "probe_seated")
    probe_seated();
else if (part == "probe_lift")
    probe_lift();
else if (part == "probe_entry")
    probe_entry();
else
    assembly(exploded = 0);
