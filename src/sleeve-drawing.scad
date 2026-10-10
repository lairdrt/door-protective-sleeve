// Door Protective Sleeve - review drawings
//
// Generates the images in photos/ from the real model.  It includes
// sleeve.scad, so every shape and every dimension label below comes
// from the current source; nothing is restated here.
//
// Pick the drawing with "view":
//   "profile" - dimensioned cross-section, with a 4x slot detail
//               (render with --projection=ortho)
//   "fit"     - cross-section with the aluminum and lock-face dummies
//               (render with --projection=ortho)
//   "tongue"  - perspective from the lock side, showing the tongue
//               against the grip face
//
// scripts/regenerate.sh renders all of them.

// Declared before the include: OpenSCAD evaluates a reassigned
// variable where it was FIRST assigned, so the $vp* framing below
// (first assigned inside sleeve.scad) can only see what precedes it.
view = "profile";

include <sleeve.scad>

// Draw only what is chosen below, not the default model
show_model = false;


// ============================================================
// FRAMING
//
// These replace sleeve.scad's default isometric view.
// ============================================================

$vpr = view == "tongue" ? [62, 0, 120] : [0, 0, 0];

$vpt = view == "profile" ? [14, -14.5, sleeve_height]
     : view == "fit"     ? [1.5, -3.5, sleeve_height]
     : [(tongue_x_out - grip_wall) / 2,
        (bridge_thickness - grip_length) / 2,
        sleeve_height / 2];

$vpd = view == "profile" ? 124
     : view == "fit"     ? 40
     : 3.0 * norm([outer_width, outer_depth, sleeve_height]);


// ============================================================
// ANNOTATION HELPERS
//
// Drawing coordinates for "profile": the model is turned +90 about
// Z, so the grip leg runs along +X from the bridge, the grip face
// is at the bottom and the tongue at the top.
// ============================================================

lw  = 0.07;                  // dimension line width
ts  = 0.95;                  // text size
zt  = sleeve_height + 0.2;   // annotation layer, above the part
det = 4;                     // detail magnification
D   = [2, -26];              // detail origin

// Number with at least one decimal place, e.g. 5 -> "5.0"
function f1(v) = let(s = str(v)) (search(".", s) == [] ? str(s, ".0") : s);

// A point of the detail drawing, in drawing coordinates
function dp(p) = D + det * p;

module flat(c = "black")
    color(c) translate([0, 0, zt]) linear_extrude(0.05) children();

module seg(a, b)
    hull() {
        translate(a) circle(d = lw, $fn = 8);
        translate(b) circle(d = lw, $fn = 8);
    }

// Arrowhead with its tip at p, pointing along dir
module arrow(p, dir)
    translate(p) rotate(atan2(dir[1], dir[0]))
        polygon([[0, 0], [-0.45, 0.16], [-0.45, -0.16]]);

module label(p, s, h = "center", v = "center", size = ts)
    translate(p)
        text(s, size = size, halign = h, valign = v,
             font = "Liberation Sans");

// Dimension line with arrowheads at both ends
module dim(a, b) {
    d = (b - a) / norm(b - a);
    seg(a, b);
    arrow(a, -d);
    arrow(b, d);
}

module view_sleeve() rotate([0, 0, 90]) sleeve();


// ============================================================
// PROFILE: full cross-section at true scale
// ============================================================

module profile_full() {

    color("SteelBlue") view_sleeve();

    flat() {
        // grip coverage, slot bottom to grip tip
        seg([0, -grip_wall - 0.2], [0, -4.2]);
        seg([grip_length, -1.8], [grip_length, -4.2]);
        dim([0, -3.6], [grip_length, -3.6]);
        label([grip_length / 2, -3.2],
              str(f1(grip_length), " grip surface (from slot bottom)"),
              v = "bottom");

        // overall depth
        seg([-bridge_thickness, -1.8], [-bridge_thickness, -6.2]);
        seg([grip_length, -4.2], [grip_length, -6.2]);
        dim([-bridge_thickness, -5.6], [grip_length, -5.6]);
        label([grip_length / 2, -5.2], str(f1(outer_depth), " overall"),
              v = "bottom");

        // tongue depth
        seg([0, slot_width + tongue_thickness + 0.15], [0, 4.6]);
        seg([tongue_depth, slot_width + tongue_thickness + 0.2],
            [tongue_depth, 4.6]);
        dim([0, 4.0], [tongue_depth, 4.0]);
        label([tongue_depth + 0.6, 4.0],
              str(f1(tongue_depth), " tongue depth"), h = "left");

        label([12, 1.0], "open slot", h = "left", size = 0.8);
        label([-bridge_thickness, 7.0],
              str("profile ", f1(outer_width), " x ", f1(outer_depth),
                  ",  height ", f1(sleeve_height),
                  "   (true scale, looking down on the top face)"),
              h = "left", size = 0.8);
    }
}


// ============================================================
// PROFILE: 4x detail of the slot end
// ============================================================

module detail_window() translate([-2.6, -2.6]) square([8.4, 6.0]);

module profile_detail() {

    translate(D) scale([det, det, 1])
        color("SteelBlue") intersection() {
            view_sleeve();
            linear_extrude(sleeve_height) detail_window();
        }

    flat() {
        label(dp([-2.6, 3.4]) + [0, 1.4],
              str("detail x", det, " (dimensions in true mm)"),
              h = "left", v = "bottom");

        // bridge thickness and tongue depth, above
        seg(dp([-bridge_thickness, 2.7]), dp([-bridge_thickness, 3.25]));
        seg(dp([0, slot_width + tongue_thickness + 0.15]), dp([0, 3.25]));
        seg(dp([tongue_depth, 2.7]), dp([tongue_depth, 3.25]));
        dim(dp([-bridge_thickness, 3.0]), dp([0, 3.0]));
        dim(dp([0, 3.0]), dp([tongue_depth, 3.0]));
        label(dp([-bridge_thickness / 2, 3.0]) + [0, 0.5],
              str(f1(bridge_thickness), " bridge"), v = "bottom");
        label(dp([tongue_depth / 2, 3.0]) + [0, 0.5],
              str(f1(tongue_depth), " tongue depth"), v = "bottom");

        // tongue thickness, right of the tongue tip
        seg(dp([tongue_depth + 0.1, slot_width]),
            dp([tongue_depth + 0.9, slot_width]));
        seg(dp([tongue_depth + 0.1, slot_width + tongue_thickness]),
            dp([tongue_depth + 0.9, slot_width + tongue_thickness]));
        dim(dp([tongue_depth + 0.7, slot_width]),
            dp([tongue_depth + 0.7, slot_width + tongue_thickness]));
        label(dp([tongue_depth + 0.95, slot_width + tongue_thickness / 2]),
              str(f1(tongue_thickness), " tongue (lock side)"), h = "left");

        // slot width, inside the open slot
        dim(dp([1.2, 0]), dp([1.2, slot_width]));
        label(dp([1.4, slot_width / 2]),
              str(slot_width, " slot (edge ", f1(edge_thickness), " + ",
                  slot_play, ")"),
              h = "left", size = 0.8);

        // grip wall, right of the detail window
        seg(dp([5.9, -grip_wall]), dp([6.4, -grip_wall]));
        seg(dp([5.9, 0]), dp([6.4, 0]));
        dim(dp([6.2, -grip_wall]), dp([6.2, 0]));
        label(dp([6.45, -grip_wall / 2]),
              str(f1(grip_wall), " grip wall"), h = "left");

        // part names
        label(dp([-1.0, -grip_wall]) - [0, 0.8],
              str("grip face (hand side), continues to ",
                  f1(grip_length), " ->"),
              h = "left", v = "top", size = 0.85);
        label(dp([-bridge_thickness, 1.0]) - [0.8, 0], "bridge",
              h = "right", size = 0.85);
        label(dp([-bridge_thickness, 0.1]) - [0.8, 0], "(on edge tip)",
              h = "right", size = 0.75);
    }
}


// ============================================================
// DRAWING
// ============================================================

if (view == "profile") {
    profile_full();
    profile_detail();
}

if (view == "fit") {
    sleeve();
    aluminum_dummy();
    lock_face_dummy();
}

if (view == "tongue")
    sleeve();
