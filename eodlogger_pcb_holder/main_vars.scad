
// ---------- print / preview quality ----------
//$fn = 64; // facet count for all curved surfaces
$fn = $preview ? 24 : 120;

// ---------- primary body ----------
main_d = 50; // Ø of the main cylinder (mm)
main_h = 28; // height of the main cylinder (mm)

// ---------- port holes ----------
port_large_d = 25;
port_small_d = 17;
port_large_y = 18;
port_small_x = 14;
port_small_y = -12;

// ---------- rounding / fillet ----------
edge_r = 1; // set 0 → disable Minkowski rounding

// back plate
plate_thick = 5;

// battery plate
batt_plate_thick = 5;
