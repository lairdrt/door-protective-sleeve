$vpt = [0, -15, 7.5];   // viewpoint target / translation
$fn = 64;   // finer display resolution

// Door Protective Sleeve
// Stage 1: 15 mm fit-test specimen of the U-shaped sleeve

// ============================================================
// LAYOUT
//
// The sleeve is one (X, Y) cross-section extruded straight up Z,
// so it prints with the profile flat on the build plate and every
// wall thickness - in particular the 0.8 mm tongue - is laid down
// in XY, where the printer is most accurate.
//
// Coordinates of the cross-section:
//   X = across the aluminum, from the hand side toward the lock
//   Y = along the aluminum face, toward the edge
//   Z = along the door edge (sleeve height)
//
// The slot's inner wall on the hand side is X = 0, and the slot
// bottom - where the bridge sits on the aluminum edge - is Y = 0.
// Both legs hang down into -Y from the bridge:
//
//          bridge
//    +----------------+          Y = bridge_thickness
//    |  +----------+  |          Y = 0  (slot bottom / edge tip)
//    |  | aluminum |  | tongue
//    |  |  edge    |  |
//    |  |          +--+          Y = -tongue_depth
//    |  |           .
//    |  |           .  lock side (inside the frame channel)
//    |  |
//    +--+                        Y = -grip_length
//    grip face (hand side)
//
// ============================================================


// ============================================================
// DOOR DIMENSIONS (as measured)
//
// Physically measured, single measurement each.  They describe the
// intended geometry but do not fix every surface: the lock's travel,
// the gap's uniformity along the full 65 mm, and the condition of
// the worn edge are NOT measured - see the README.
// ============================================================

edge_thickness      = 1.5;    // aluminum frame edge
channel_depth       = 6.0;    // edge tip to bottom of internal channel
lock_clearance      = 1.5;    // channel wall to locking mechanism
grip_surface_length = 35.0;   // hand-gripping surface, from the edge


// ============================================================
// SLEEVE DIMENSIONS (proposed, not yet fit-verified)
// ============================================================

grip_wall        = 1.6;    // grip-face wall thickness
slot_width       = 1.75;   // internal slot around the 1.5 mm edge (1.7 - 1.8 proposed)
tongue_thickness = 0.8;    // retaining tongue wall thickness
tongue_depth     = 5.0;    // tongue insertion depth, from the slot bottom

// The bridge thickness was not specified.  It is matched to the
// grip wall as a starting point; it only sets how far the sleeve
// stands proud of the edge tip.
bridge_thickness = grip_wall;

// The grip leg covers the measured hand surface, measured from the
// slot bottom (which seats on the edge tip) like the surface itself.
grip_length = grip_surface_length;


// ============================================================
// HEIGHT
//
// The fit-test specimen is printed first.  Override sleeve_height
// for the finished part once the profile is verified, e.g.
//   openscad -D sleeve_height=65 ...
// ============================================================

prototype_height = 15.0;
finished_height  = 65.0;

sleeve_height = prototype_height;


// ============================================================
// EDGE ROUNDING
//
// Only the exposed convex corners of the cross-section are rounded:
// the two outer corners of the bridge, the grip-face tip, and the
// tongue tip.  Each is cut by a fillet cutter that lies entirely
// inside its corner square, so the rounding can only remove
// material from that corner; no wall is thinned and no fitting
// surface moves.
//
// The tongue tip gets its own, smaller radius: it is only 0.8 mm
// thick.  Its rounded corners double as a lead-in when the tongue
// is started into the channel, and the rounded grip tip does the
// same on the hand side.
//
// Deliberately NOT rounded: the two concave slot-bottom corners
// that seat on the aluminum edge, and the top and bottom end faces
// of the extrusion.
// ============================================================

edge_round       = 0.75;   // bridge outer corners and grip tip
tongue_tip_round = 0.3;    // tongue tip, < tongue_thickness / 2
round_fn         = 32;     // arc resolution for the small rounds


// ============================================================
// DERIVED DIMENSIONS
// ============================================================

// Slot play around the aluminum edge, shared between the two sides
slot_play = slot_width - edge_thickness;

// X of the tongue's inner (slot) and outer (lock-side) faces
tongue_x_in  = slot_width;
tongue_x_out = slot_width + tongue_thickness;

// Overall cross-section
outer_width = grip_wall + slot_width + tongue_thickness;
outer_depth = grip_length + bridge_thickness;

// Tongue-to-lock clearance at the two extremes of the slot play:
//   best  - the tongue is pulled against the aluminum's inner face
//   worst - the grip face is against the aluminum's outer face, as
//           it will be once bonded, so all the play lies between
//           the aluminum and the tongue
lock_gap_best  = lock_clearance - tongue_thickness;
lock_gap_worst = lock_clearance - slot_play - tongue_thickness;

// Space left below the tongue tip in the channel
channel_floor_gap = channel_depth - tongue_depth;


// ============================================================
// GUARDS
// ============================================================

assert(slot_width > edge_thickness,
       "slot_width must exceed edge_thickness");
assert(lock_gap_worst > 0,
       "tongue plus slot play does not fit the measured lock clearance");
assert(tongue_depth < channel_depth,
       "tongue_depth must be less than channel_depth");
assert(2 * edge_round <= grip_wall,
       "edge_round too large for grip_wall");
assert(edge_round <= bridge_thickness,
       "edge_round too large for bridge_thickness");
assert(2 * tongue_tip_round <= tongue_thickness,
       "tongue_tip_round too large for tongue_thickness");


// ============================================================
// CROSS-SECTION
// ============================================================

// The sharp U, one simple polygon, counter-clockwise from the
// outer corner of the grip tip.
module sleeve_profile_sharp() {

    polygon([
        // grip tip
        [-grip_wall, -grip_length],
        [0,          -grip_length],

        // up the hand-side slot wall to the slot bottom
        [0, 0],
        [tongue_x_in, 0],

        // down the tongue's inner face, across its tip
        [tongue_x_in,  -tongue_depth],
        [tongue_x_out, -tongue_depth],

        // up the tongue's outer face, back across the bridge
        [tongue_x_out, bridge_thickness],
        [-grip_wall,   bridge_thickness]
    ]);
}


// Material removed to round a convex corner at p by radius r.
// dir gives the corner's outward directions, e.g. [1, 1] for a
// corner whose material lies to -X and -Y of p.  The cutter is the
// corner square less the fillet disc, so it never reaches beyond
// r from the corner along either face.
module corner_cutter(p, dir, r) {

    eps = 0.01;

    translate(p)
        scale(dir)
            difference() {
                translate([-r, -r])
                    square([r + eps, r + eps]);
                translate([-r, -r])
                    circle(r = r, $fn = round_fn);
            }
}


module sleeve_profile() {

    difference() {
        sleeve_profile_sharp();

        // Bridge outer corners
        corner_cutter([-grip_wall,   bridge_thickness], [-1, 1], edge_round);
        corner_cutter([tongue_x_out, bridge_thickness], [ 1, 1], edge_round);

        // Grip-face tip
        corner_cutter([-grip_wall, -grip_length], [-1, -1], edge_round);
        corner_cutter([0,          -grip_length], [ 1, -1], edge_round);

        // Tongue tip
        corner_cutter([tongue_x_in,  -tongue_depth], [-1, -1], tongue_tip_round);
        corner_cutter([tongue_x_out, -tongue_depth], [ 1, -1], tongue_tip_round);
    }
}


// ============================================================
// SLEEVE
// ============================================================

module sleeve() {
    linear_extrude(height = sleeve_height)
        sleeve_profile();
}


// ============================================================
// FIT-CHECK DUMMIES
//
// The aluminum edge seated on the slot bottom with the grip face
// against its outer surface (the bonded position), and the face of
// the locking mechanism lock_clearance beyond the aluminum's inner
// face.  Only the measured 1.5 mm gap is modelled; the lock's real
// shape and travel are unknown.
// ============================================================

module aluminum_dummy() {

    color("silver", 0.6)
        translate([0, -grip_length - 5, 0])
            cube([edge_thickness, grip_length + 5, sleeve_height]);
}


module lock_face_dummy() {

    color("red", 0.4)
        translate([edge_thickness + lock_clearance, -channel_depth, 0])
            cube([2, channel_depth, sleeve_height]);
}


// ============================================================
// DESIGN CHECKS
// ============================================================

echo(str("sleeve section ", outer_width, " wide x ", outer_depth,
         " deep, height ", sleeve_height,
         " (prototype ", prototype_height, ", finished ",
         finished_height, ")"));

echo(str("slot ", slot_width, " around ", edge_thickness,
         " edge = ", slot_play, " play"));

echo(str("tongue ", tongue_thickness, " thick in ", lock_clearance,
         " lock clearance: ", lock_gap_best,
         " to lock if against the aluminum, ", lock_gap_worst,
         " if the grip face is against the aluminum (bonded)"));

echo(str("tongue depth ", tongue_depth, " in ", channel_depth,
         " channel, ", channel_floor_gap, " left below the tip"));

echo(str("grip face covers ", grip_length, " of the ",
         grip_surface_length, " hand surface; stands ", grip_wall,
         " proud of it, bridge ", bridge_thickness,
         " proud of the edge tip"));


// ============================================================
// MODEL
// ============================================================

sleeve();

// aluminum_dummy();
// lock_face_dummy();
