// Are the two guard hands a TRUE mirror pair?  A mirror is invisible to a bounding box and to a volume,
// so this file asks the only question that can answer it: the SYMMETRIC DIFFERENCE of mirror(dirP) and
// dirN, as a solid.  Render both directions -- a one-sided difference can be empty while the other is not.
//
//   probe_case = "src"   RUN THIS FIRST.  Renders the imported mirror(dirP) alone.  It MUST be NON-EMPTY.
//                        OpenSCAD treats a missing import() as an empty object with only a console warning,
//                        so without this step every other case comes back "EMPTY" the moment you forget to
//                        build the two STLs -- and "EMPTY" is the answer that means SUCCESS here.  That is
//                        the repo's classic false pass, wearing a different hat.
//   probe_case = "fwd"   mirror(dirP) MINUS dirN
//   probe_case = "rev"   dirN MINUS mirror(dirP)
//   probe_case = "ctl"   CONTROL: the same difference with dirN shifted 0.5 mm, which MUST be non-empty
//                        (otherwise the boolean is not running and "empty" means nothing)
//
// Both STLs must exist first:
//   openscad -o stl/_m_dirP.stl --export-format binstl --render=force -D motor_offset_dir=1  -D '$fn=128' propguard.scad
//   openscad -o stl/_m_dirN.stl --export-format binstl --render=force -D motor_offset_dir=-1 -D '$fn=128' propguard.scad
probe_case = "fwd";
probe_shift = (probe_case == "ctl") ? 0.5 : 0;

module A() mirror([1,0,0]) import("stl/_m_dirP.stl");
module B() translate([probe_shift,0,0]) import("stl/_m_dirN.stl");

if      (probe_case == "src") A();                          // liveness: MUST be non-empty
else if (probe_case == "rev") difference() { B(); A(); }
else                          difference() { A(); B(); }
