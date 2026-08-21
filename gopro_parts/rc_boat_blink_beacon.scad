/*
  RC boat blink beacon v2
  -----------------------
  Requires BOSL2. Install it as an OpenSCAD library so these resolve:
    include <BOSL2/std.scad>
    include <BOSL2/threading.scad>

  Three printable parts:
    1. opaque body with integrated GoPro-compatible two-prong mount
    2. opaque LED carrier for a 20 mm star board
    3. translucent diffuser dome

  Select a part with `part` before exporting an STL.
  Units: millimetres.  Material: PETG.

  ---------------------------------------------------------------------------
  WHAT CHANGED IN v2, AND WHY
  ---------------------------------------------------------------------------
  v1's carrier did not snap into the body -- it dropped in and sat there.  The
  retention was eight d=1.4 spheres half-buried in the carrier's rim, standing
  0.40 mm proud of a 30.0 disc that entered a 30.5 socket.  Subtract the 0.25
  clearance and the actual interference was 0.15 mm, and it had to be taken up
  by a solid disc pushing a closed ring open: there was no cantilever anywhere
  in the joint, so 0.15 mm of "interference" meant 1 % hoop strain in a 30 mm
  ring.  Nothing that stiff yields politely -- it either refuses to enter or,
  as here, the bumps print away to a rounding error and the parts just stack.

  v2 puts a real cantilever in the joint.  The carrier grows a SLOTTED SKIRT
  below its rim: a 1.4 mm ring with six 0.9 mm tongues freed by axial cuts, each
  rooted at the rim and carrying an outward barb near its free end.  The body's
  bore gets one continuous internal groove for those barbs to fall into.  The
  tongues bend; the ring does not have to stretch.  Engagement went 0.15 -> 0.40
  mm, and the barb now has to spring 0.40 mm to get past the bore -- which is
  the number that decides whether it clicks.

  Three things were deliberately NOT touched, because the diffuser dome is
  already on the printer:
    * carrier_diameter (30.0) and general_fit (0.25) -- the dome's skirt bore
    * the male thread, its pitch, length and diameter
    * carrier_proud (1.8) -- how far the carrier stands above the body's top
      face, which is where the dome's internal thread starts
  Everything the dome can see is asserted below.  The dome STL is unchanged.

  ---------------------------------------------------------------------------
  PRINT ORIENTATION -- unchanged from v1, and the snap is designed around it
  ---------------------------------------------------------------------------
  BODY:    top face (the carrier socket) DOWN on the bed, GoPro fork UP.  So
           the socket, the seat ledge and the snap groove are all printed in
           the first four layers, where detail is best.  The groove's roof is a
           0.40 mm step -- it needs no support at any flank angle.
  CARRIER: skirt DOWN on the bed, thread UP.  The skirt is a continuous ring,
           so it lands on a 1.4 mm annulus rather than six separate towers, and
           the rim above it bridges a plain 25.2 mm circle.  The tongue cuts are
           vertical gaps and the barbs' lead ramps sit 0.6 mm off the bed.
  DOME:    flat top face down, as before.

  This is why the flexing member is on the CARRIER and not on the body: body-
  side fingers would need slots cut through the outer wall (a splash path), and
  the carrier cannot carry anything that hangs below a flat disc -- but it can
  carry a ring, which is what a skirt is.
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
general_fit = 0.25;            // radial fit for removable parts -- DOME SEES THIS
wire_hole_clearance = 0.35;

// Beacon proportions --------------------------------------------------------
// body_height went 9.5 -> 11.0 to buy the carrier skirt its travel.  The
// compartment did not shrink for it: the skirt is a ring, so the PCB now lives
// INSIDE it and the usable headroom actually went up (5.9 -> 7.4).
body_diameter = 33.0;
body_wall = 2.25;              // was 2.00 -- widens the carrier's seat ledge
body_floor = 2.2;
body_height = 11.0;            // was 9.5
pcb_compartment_wall = 1.2;
pcb_rail_length = pcb_length + 1.0;

carrier_diameter = 30.0;       // DOME SEES THIS -- do not change
carrier_rim_height = 3.2;      // the OD30 section: rim seat + the proud part
carrier_proud = 1.8;           // how far the carrier stands above the body face
star_pocket_depth = 2.15;

// Snap: a slotted skirt under the carrier rim, a groove in the body bore -----
// Sized for PETG (E ~ 2.0 GPa, permissible strain ~3 %).  The tongue is a
// straight cantilever, so peak strain is  3*t*y / (2*L^2)  -- with t = 0.90,
// y = 0.40 and L = 5.24 (root at the rim, load at the barb crest) that is
// 1.97 %, a third under the material and still a firm click.
skirt_height = 6.40;           // == tongue free length
skirt_wall = 1.40;             // the ring between tongues: stiff, prints the rim
tongue_wall = 0.90;            // the tongues themselves: 2 perimeters at 0.45
tongue_count = 6;
tongue_width = 3.50;           // narrow on purpose -- force goes as the width
tongue_cut = 1.50;             // axial gap either side of a tongue
snap_clr = 0.25;               // skirt OD to body bore, radial
snap_engage = 0.40;            // how deep the barb sits in the groove
snap_barb_z = 0.60;            // barb starts this far above the skirt's free end
snap_lead_ang = 30;            // insertion ramp, from horizontal -- easy in
snap_hold_ang = 45;            // retention flank, from horizontal -- hard out
snap_play = 0.15;              // groove taller than barb, so the SEAT is the stop
// The groove is cut DEEPER than the barb is tall.  Line-to-line, the crest and
// the groove floor are the same surface: it seats, but it binds, and the
// interference probe cannot tell that apart from a real overlap.  The extra
// depth costs no retention -- what the barb has to spring over on the way out
// is how far it stands past the BORE, which is snap_engage either way.
snap_groove_clr = 0.10;
skirt_lead = 0.60;             // 45 deg entry chamfer on the skirt's free end

carrier_thickness = skirt_height + carrier_rim_height;   // 9.60
carrier_seat_depth = carrier_thickness - carrier_proud;  // 7.80
carrier_seat_bore = carrier_rim_height - carrier_proud;  // 1.40 -- counterbore

body_bore_r = body_diameter / 2 - body_wall;   // 14.25
skirt_or = body_bore_r - snap_clr;             // 14.00
skirt_ir = skirt_or - skirt_wall;              // 12.60
tongue_ir = skirt_or - tongue_wall;            // 13.10
barb_or = body_bore_r + snap_engage;           // 14.65
barb_proud = barb_or - skirt_or;               // 0.65 -- 0.40 of it interferes
barb_lead_dz = barb_proud * tan(snap_lead_ang);
barb_hold_dz = barb_proud * tan(snap_hold_ang);
barb_land = barb_lead_dz;                      // flat crest between the flanks
barb_top_z = snap_barb_z + barb_lead_dz + barb_land + barb_hold_dz;
barb_mid_z = snap_barb_z + barb_lead_dz + barb_land / 2;
// Cut centrelines sit half a cut outboard of the tongue edge, so the tongue
// comes out exactly tongue_width wide at the skirt OD.
tongue_cut_off = asin((tongue_width + tongue_cut) / (2 * skirt_or));

carrier_floor_z = body_height - carrier_seat_depth;   // skirt's free end, in body Z
snap_groove_z0 = carrier_floor_z + snap_barb_z - snap_play;

carrier_bore_ceiling = carrier_floor_z + skirt_height; // ceiling over the PCB
rail_height = pcb_total_thickness + 1.0;

// Thread and dome -- FROZEN.  The dome is already printed.
thread_diameter = 28.0;
thread_pitch = 2.0;
thread_length = 6.0;
thread_slop = 0.20;
thread_collar_wall = 2.0;

dome_wall = 1.6;
dome_top_thickness = 2.0;
dome_thread_start = carrier_proud;
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

pcb_cavity = [
    pcb_compartment_length,
    pcb_compartment_width,
    pcb_total_thickness + pcb_z_clearance
];

// ---- invariants ----------------------------------------------------------
// The dome is on the printer.  These are every dimension it can reach; if one
// of them moves, the printed dome no longer fits and the assert says so
// instead of the mesh saying nothing.
assert(carrier_diameter == 30.0, "dome skirt bore rides on carrier_diameter");
assert(general_fit == 0.25, "dome skirt bore is carrier_diameter + 2*general_fit");
assert(dome_thread_start == 1.8, "dome thread starts 1.8 above its own bottom face");
assert(carrier_proud == dome_thread_start,
       "the carrier must stand exactly dome_thread_start above the body face");
assert(thread_diameter == 28.0 && thread_pitch == 2.0 && thread_length == 6.0,
       "male thread must match the printed dome");
assert(dome_total_height == 20.3, "dome height changed -- the printed one is 20.3");

// The snap only exists if the barb actually sticks out past the bore.
assert(snap_engage > 0.30, "engagement below 0.30 is what failed in v1");
assert(skirt_ir > 0 && tongue_ir > skirt_ir,
       "tongue must be thinner than the ring it sits in, or it cannot flex");
// The tongue deflects into open air inside the skirt, but only if the relief
// behind it is deeper than the deflection.
assert(tongue_ir - skirt_ir >= snap_engage + 0.05,
       "no room behind the tongue to deflect into");

// PCB has to fit under the skirt, not just inside the body.
assert(carrier_bore_ceiling - body_floor >= pcb_cavity[2] + 1.0,
       "PCB compartment too short");
assert(sqrt(pow(pcb_rail_length / 2, 2) +
            pow(pcb_cavity[1] / 2 + pcb_compartment_wall, 2)) < skirt_ir - 0.5,
       "PCB rails foul the carrier skirt");
assert(body_floor + rail_height < carrier_bore_ceiling, "rails hit the carrier");

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

// A pie slice centred on +X.  Used to cut a body of revolution down to the
// angular span of one tongue, so the barb is a real ring profile rather than a
// box pretending to be one.
module sector(ang, h, r) {
    rotate([0, 0, -ang / 2])
        linear_extrude(height = h)
            polygon(concat([[0, 0]],
                    [for (i = [0 : 48]) let (t = ang * i / 48)
                        [r * cos(t), r * sin(t)]]));
}

// Lightweight body core: a sealed floor, thin cylindrical exterior, and two
// free-standing PCB guide rails.  Their open ends leave the surrounding hollow
// annulus available for solder joints, wire bends, and excess wire.
module lightweight_body_shell() {
    union() {
        // Subtracting only above body_floor leaves a continuous sealed floor.
        difference() {
            cylinder(d = body_diameter, h = body_height);
            translate([0, 0, body_floor])
                cylinder(d = body_diameter - 2 * body_wall,
                         h = body_height - body_floor + eps);
        }

        // Two long rails locate the PCB laterally without enclosing its ends.
        // They stop short of the carrier: the skirt's bore is the ceiling now.
        for (y = [-(pcb_cavity[1] / 2 + pcb_compartment_wall),
                   pcb_cavity[1] / 2])
            translate([-pcb_rail_length / 2,
                       y,
                       body_floor - eps])
                rounded_box([
                    pcb_rail_length,
                    pcb_compartment_wall,
                    rail_height + eps
                ], pcb_compartment_wall / 2);
    }
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

// The groove the carrier's barbs fall into.  One continuous annulus, NOT six
// pockets: the carrier then snaps home at any rotation, which is worth more
// than the anti-rotation a segmented groove would have bought.  Profile is the
// barb's own, opened by snap_play top and bottom so the seat ledge -- not the
// barb -- is what stops the carrier going down.
module snap_groove() {
    z0 = snap_groove_z0;
    gr = barb_or + snap_groove_clr;
    rotate_extrude()
        polygon([
            [body_bore_r - 0.5, z0],
            [gr,                z0 + barb_lead_dz],
            [gr,                z0 + barb_lead_dz + barb_land + 2 * snap_play],
            [body_bore_r - 0.5, z0 + barb_lead_dz + barb_land + 2 * snap_play
                                   + barb_hold_dz]
        ]);
}

module body() {
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

        // Counterbore for the carrier's rim.  Its floor is the seat: a 1.0 mm
        // annulus the rim lands on, and the only thing setting how deep the
        // carrier goes.
        translate([0, 0, body_height - carrier_seat_bore])
            cylinder(d = carrier_diameter + 2 * general_fit,
                     h = carrier_seat_bore + 2 * eps);

        snap_groove();

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

// The flexing half of the joint.  A continuous ring so the rim above it has
// something to bridge onto and the part has a real footprint on the bed; six
// tongues cut out of that ring so the retention is bending, not hoop strain.
module carrier_skirt() {
    span = 2 * tongue_cut_off;           // tongue + half a cut either side
    difference() {
        union() {
            // Ring, with a 45 deg chamfer on the free end so it finds the bore.
            // It runs eps PAST skirt_height so it overlaps the rim instead of
            // sharing a face with it -- stacked flush, the union comes back as
            // eleven separate shells that still report "manifold".  The overlap
            // goes on THIS side because the rim's own OD is the seat: grow the
            // rim downward instead and 0.05 mm of OD30 hangs below the
            // counterbore floor, where it fouls the bore.
            rotate_extrude()
                polygon([
                    [skirt_ir, 0],
                    [skirt_or - skirt_lead, 0],
                    [skirt_or, skirt_lead],
                    [skirt_or, skirt_height + eps],
                    [skirt_ir, skirt_height + eps]
                ]);

            // One barb per tongue.  Cut from a ring of revolution so its crest
            // is a true arc against the bore, then trimmed to the tongue span.
            for (i = [0 : tongue_count - 1])
                rotate([0, 0, i * 360 / tongue_count])
                    intersection() {
                        rotate_extrude()
                            polygon([
                                [skirt_or - 0.5, snap_barb_z],
                                [barb_or, snap_barb_z + barb_lead_dz],
                                [barb_or, snap_barb_z + barb_lead_dz + barb_land],
                                [skirt_or - 0.5, barb_top_z]
                            ]);
                        sector(span, barb_top_z + eps, barb_or + 1);
                    }
        }

        // Thin the ring down to tongue_wall behind each tongue.  Everything
        // inside skirt_ir is already open air, so this is all the relief the
        // tongue needs to bend into.
        for (i = [0 : tongue_count - 1])
            rotate([0, 0, i * 360 / tongue_count])
                intersection() {
                    difference() {
                        translate([0, 0, -eps])
                            cylinder(r = tongue_ir, h = skirt_height + 2 * eps);
                        translate([0, 0, -2 * eps])
                            cylinder(r = skirt_ir - 0.5, h = skirt_height + 4 * eps);
                    }
                    translate([0, 0, -eps])
                        sector(span, skirt_height + 2 * eps, tongue_ir + 1);
                }

        // The axial cuts that make them tongues at all.
        for (i = [0 : tongue_count - 1])
            for (s = [-1, 1])
                rotate([0, 0, i * 360 / tongue_count + s * tongue_cut_off])
                    translate([skirt_ir - 1, -tongue_cut / 2, -eps])
                        cube([barb_or + 1 - (skirt_ir - 1),
                              tongue_cut,
                              skirt_height + eps]);
    }
}

module carrier() {
    difference() {
        union() {
            carrier_skirt();

            // The rim: OD30 for carrier_rim_height.  carrier_seat_bore of it
            // sits in the body's counterbore, carrier_proud of it stands above
            // the body's face and is what the dome's skirt bore rides on.
            // Its underside IS the seat, so it starts exactly at skirt_height;
            // the skirt below is what carries the overlap.
            translate([0, 0, skirt_height])
                cylinder(d = carrier_diameter, h = carrier_rim_height);

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
        // carrier can be changed to match the star's solder pads.  They only
        // cut real material through the rim -- the skirt below is open.
        for (a = [0, 180])
            rotate([0, 0, a])
                translate([led_star_diameter / 2 - 2.2, 0, skirt_height - eps])
                    cylinder(d = wire_diameter + 2 * wire_hole_clearance,
                             h = carrier_rim_height + 2 * eps);

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
        translate([0, 0, carrier_floor_z + exploded])
            carrier();

    color([0.88, 0.92, 0.85, 0.50])
        translate([0, 0, body_height + 2 * exploded])
            dome();

    // Component preview only; not exported as a printable part.
    if (part == "assembly") {
        color("silver")
            translate([0, 0,
                       carrier_floor_z + carrier_thickness
                       - led_star_thickness + exploded])
                cylinder(d = led_star_diameter,
                         h = led_star_thickness,
                         $fn = 6);

        color("gold")
            translate([0, 0, carrier_floor_z + carrier_thickness + exploded])
                cylinder(d = led_emitter_diameter,
                         h = led_emitter_height);
    }
}

// ---- probes ---------------------------------------------------------------
// Not printable parts.  Each renders a solid whose VOLUME answers one question
// that no single-part measurement can, and each is checked by verify_beacon.py.
//
// probe_fit   what the seated carrier and the body have in common.  Must be
//             EMPTY.  If the groove sits at the wrong height, or the skirt is
//             fatter than the bore, this is where it shows up.
// probe_hook  the carrier material standing outside the plain bore, in the
//             stretch of bore the barbs have to travel down.  Must NOT be
//             empty: it is literally the plastic that has to spring past, and
//             v1 -- whose bumps only ever entered the shallow counterbore --
//             renders this as nothing at all.
module seated_carrier() {
    translate([0, 0, carrier_floor_z]) carrier();
}

module probe_fit() {
    intersection() { body(); seated_carrier(); }
}

module probe_hook() {
    intersection() {
        difference() {
            seated_carrier();
            cylinder(r = body_bore_r, h = 4 * body_height, center = true);
        }
        // ... and only over the plain bore, below the counterbore.
        translate([0, 0, body_floor])
            cylinder(r = body_diameter,
                     h = body_height - carrier_seat_bore - body_floor);
    }
}

if (part == "body")
    body();
else if (part == "carrier")
    carrier();
else if (part == "dome")
    dome();
else if (part == "probe_fit")
    probe_fit();
else if (part == "probe_hook")
    probe_hook();
else
    assembly(exploded = 0);
