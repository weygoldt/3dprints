include <../BOSL2/std.scad>
include <../BOSL2/hinges.scad>

$fn = $preview ? 40 : 220;
nothing = 0.01;

// amount of slots per row
num_slots_per_row = 10; //20; //12

// amount of slot rows
num_slot_rows = 1;

// spacing between slots 
spacing = 0.8;

// thickness of the outer shell and the lid
wall_thickness = 1.2;

// make the slots slightly larger
bat_clearance = 0.25; // 0.3 -> a bit loose

// CR2032 dimension are 20 x 3.2
bat_d = 20.0 + bat_clearance;     // diameter mm
bat_h = 3.2  + bat_clearance;     // height mm

// height of the base part of the box (cut off so you can easily pull out SD cards)
case_height = bat_d * 0.65; // 35 % uncovered to be able to pull out cards
case_length = num_slots_per_row * (bat_h + spacing) + spacing;
case_width = num_slot_rows * (bat_d + spacing) + spacing;
// height of the outer box
outer_case_height = case_height - 2;

// height of the lid of the case
lid_height = bat_d - outer_case_height + spacing + wall_thickness;

outer_case_rounding = 2.0;

// text parameters
text_full = "FULL";
text_empty = "Empty";
text_height = 0.25; // height of engraved text
font_sz = 8;
font = "DIN Condensed:style=Bold";

module draw_case_base() {
  diff(){
    // Inner base case
    cuboid([case_length, case_width, case_height], anchor=BOT);
  
    // Cut holes for the batteries
    //up(wall_thickness/2){
    tag("remove") up(spacing)
      grid_copies(spacing=[bat_h+spacing, bat_d+spacing], n=[num_slots_per_row,num_slot_rows]) {
        xcyl(l=bat_h, d=bat_d, anchor=BOT);
        up(bat_d/2) // carve out more space for the batteries
          cuboid([bat_h, bat_d, bat_d/2], anchor=BOT);
      }

    // Cut out cylinder for better battery access
    up(bat_d*0.7)
    tag("remove") xcyl(l=case_length - 2*wall_thickness, d=bat_d/1.5);
    // Lid lock socket
    tag("remove") fwd(case_width/2) up(case_height-1.0)
      prismoid(size1=[case_length/3*1.05,1*1.05], size2=[case_length*1.05/4,0], h=0.4, orient=BACK);


    // Outer base case (shell with rounding)
    rect_tube(isize=[case_length, case_width], wall=wall_thickness, h=outer_case_height, rounding=outer_case_rounding, anchor=BOT)
    // Add hinge
    position(TOP+BACK) orient(anchor=BACK)
        knuckle_hinge(length=case_length*0.9, segs=num_slots_per_row/2, offset=3, arm_height=1, round_bot=1.0, teardrop=true, pin_diam=2, in_place=false);
   
    // If the height base of the case is low, the hinge might stick out at the bottom, so we cut that
    tag("remove") back(case_width/2) down(nothing) cuboid([case_length, 10, 5], anchor=TOP);
  }
}

module draw_case_top() {
  difference(){
    draw_case_lid();
   down(nothing)
      color("Grey", 1) xflip() engrave_text();
  }
}

module draw_case_lid() {
  lid_clearance=0.1;
  // Outer shell of the lid
  rect_tube(isize=[case_length+2*lid_clearance, case_width+2*lid_clearance], wall=wall_thickness-lid_clearance, h=lid_height, rounding=outer_case_rounding, ichamfer=0, anchor=BOT)
  position(TOP+BACK) orient(anchor=BACK)
    // Add hinge
    knuckle_hinge(length=case_length*0.9, segs=num_slots_per_row/2, offset=3, arm_height=1, round_bot=0.25, teardrop=true, pin_diam=2, inner=true, in_place=false);

  // Fill gap created by the rect_tube with lid_clearance above
  rect_tube(isize=[case_length, case_width], wall=wall_thickness, h=bat_d-case_height, rounding=outer_case_rounding, ichamfer=0, anchor=BOT);

  // Battery slots for the lid
  difference(){
    cuboid([case_length, case_width, bat_d-outer_case_height], anchor=BOT);
    // Cut holes for the top of batteries
    up(wall_thickness) 
      grid_copies(n=[num_slots_per_row,num_slot_rows], spacing=[bat_h+spacing, bat_d+spacing])
        xcyl(l=bat_h, d=bat_d, anchor=BOT);
  }
  // In case you don't want the slots above, we need a wall
  //cuboid([case_length, case_width, wall_thickness], anchor=BOT);

  // Lid lock
  fwd(case_width/2+lid_clearance) up(lid_height-1.0)
    prismoid(size1=[case_length/3,1], size2=[case_length/4,0], h=0.3, orient=BACK);

  fwd(case_width/2+wall_thickness) up(1.0)
    prismoid(size1=[case_length/3,2], size2=[case_length/4,1], shift=[0,-0.5], h=1.5, orient=FRONT);
}

module engrave_text() {
  left(case_length/3) zrot(90)
  linear_extrude(text_height) 
    text(text_full, size=font_sz, halign="center", valign="center", font);

  right(case_length/3) zrot(-90)
  linear_extrude(text_height)
    text(text_empty, size=font_sz, halign="center", valign="center", font);        
}

//back_half()
draw_case_base();


back(case_width+8) zrot(180) 
  //back_half()
  draw_case_top(); // with engraved text
  //draw_case_lid(); // without engraved text
