// ═══════════════════════════════════════════════════════════════════════════
//  Parametric Stackable Organizer  —  OPEN THIS FILE
//
//  1. Open this file in OpenSCAD
//  2. Window → Customizer  (or edit the values below)
//  3. F5 preview · F6 render · F7 export STL
//
//  Derivative work, CC BY-NC. Original design by termlimit, based on STTrife:
//  https://www.thingiverse.com/thing:3873672
// ═══════════════════════════════════════════════════════════════════════════

include <organizer.scad>

/* [What to generate] */
// Part to build
part = "demo"; // [demo:Preview — box with drawers, box:Box with drawer slots, box_bin:Box with drawers and open bin, drawer:Drawer, label:Label plates for the drawer pocket, connector:Connector clip, connector_tolerant:Connector clip (loose fit)]

/* [Size] */
// Width, in grid units of 73.06 mm
width_units = 2;   // [1, 2, 2.5, 3]
// Depth, in grid units of 67.20 mm
depth_units = 2;   // [1, 2]
// Height, in grid units of 74.64 mm (boxes only)
height_units = 1;  // [1, 2, 3, 4]

/* [Drawer slots in the box] */
// How many drawer slots the box has in total. Drawer height follows
// automatically: 4 slots → 16.20 mm drawers, 2 → 33.66 mm, 1 → 68.58 mm
// (for a box one unit tall).
drawer_slots = 4;  // [1:1:8]
// Drawer height in mm. Leave 0 to derive it from the slot count (recommended).
drawer_height_mm = 0;
// Which slot the drawer is for, counted from the bottom. Only matters when the
// slots have different heights — see slot_weights further down the file.
drawer_for_slot = 1;  // [1:1:8]

/* [Drawer] */
// Number of compartments across the width
compartments_across = 3;  // [1:1:8]
// Number of compartments front to back
compartments_deep = 2;    // [1:1:6]
// Divider thickness in mm. 1.92 gives sturdy dividers; 1.20 is slimmer and
// leaves more usable space when you want many compartments.
divider_thickness = 1.92;
// Pull handle under the drawer front
handle = true;
// Label pocket on the drawer front: two ribs and a shelf, one window per
// column of compartments. A card or a printed plate slides in from above.
label_pocket = false;
// For compartments that are NOT all the same, leave the two settings above
// alone and edit `drawer_layout` further down this file — the Customizer
// cannot show a list of lists, so it lives in the text.


/* [Label plates] */
// Plates that slide into the pocket. Printed flat, with the text raised by one
// layer, so a filament change at that layer prints the lettering in a second
// colour. Set part = "label" to generate them; they take their size from the
// drawer settings above. The texts are a list, so they live further down the
// file — the Customizer cannot show a list of strings.
// Text height in mm. 0 = size it to the plate.
label_text_size = 0;
// Font. Leave empty for the OpenSCAD default.
label_font = "";

/* [Connector slots] */
// Put slots on every grid unit, so any box can clip anywhere on the grid.
// Turn off for slots only along the outer edges.
slots_on_every_unit = true;
// Slot length in mm. Leave 0 for the standard 46.80 mm measured from the back.
slot_length_mm = 0;

/* [Open bin] */
// Bin height in mm, measured from the bin floor to the top of the box.
// 0 = half the box height, which gives a balanced split.
// Ignored when the bin has no drawers below it — then it fills the whole box.
bin_height = 0;
// Drawer slots below the bin. 0 = bin only, no drawers and no shelf.
bin_drawer_slots = 2;  // [0:1:6]
// Height of the front lip that keeps the contents in. Trimmed automatically
// if it would not fit the bin.
bin_lip_height = 28.56;
// Bin front panel flush with the face of the box.
// Turn off to recess it behind the front frame.
bin_front_flush = true;
// Roof over the back of the bin. Auto keeps it only when the box is deep
// enough to be useful — a one-unit-deep bin becomes an open shelf.
bin_roof = "auto"; // [auto, yes, no]

/* [Hidden] */
$fn = 64;

// ─── Compartments that are not a plain grid ─────────────────────────────────
// Leave empty to use compartments_across × compartments_deep above.
//
// Otherwise: one entry per column, front to back, written as
// [width weight, [row weights]]. The weights are relative and always fill the
// drawer, so [1,2,1] and [10,20,10] mean the same thing. A plain number is
// shorthand for a standard-width column with that many equal rows.
//
//   drawer_layout = [ [1, [1,1]],       // 2 equal rows
//                     [2, [1]],         // twice as wide, undivided
//                     [1, [1,2,1]] ];   // 3 rows, middle one twice as deep
//
//   drawer_layout = [2, 1, 3];          // 3 columns of 2, 1 and 3 rows
//
//   drawer_layout = [ [3, [1,1]], [1, [1,1,1,1]] ];
//                     // a wide half in 2 rows, a narrow half in 4
drawer_layout = [];

// Which way the layout is read:
//   "cols" — columns, each with its own rows   (the drawing above)
//   "rows" — bands across the drawer, each with its own columns; the first
//            weight is then the depth of the band
//
//   drawer_layout = [ [1,[1,1]], [1,[1]], [1,[1,1,1]] ];
//   drawer_layout_dir = "rows";   // 3 bands: 2 columns, none, 3 columns
drawer_layout_dir = "cols";

// ─── What the label plates say ──────────────────────────────────────────────
// One entry per plate, laid out in a row ready to print. Each plate is sized
// to the window it belongs to; with more texts than windows the list simply
// wraps around, which is what you want when several drawers share a layout.
label_texts = ["10k", "100k", "1M"];

// ─── Slots of different heights ─────────────────────────────────────────────
// Leave empty for slots that are all the same, as set by drawer_slots above.
// Otherwise one weight per slot, bottom to top — relative, like the compartment
// weights, and always filling the box:
//
//   slot_weights = [1, 1, 2];     // two ordinary slots, then a double one
//   slot_weights = [2, 1, 1, 1];  // a tall one at the bottom
//
// Set drawer_for_slot above to say which of them you are printing a drawer for.
slot_weights = [];

// Effective bin height: given, or half the box.
bin_height_eff = bin_height > 0 ? bin_height : height_units * UNIT_H / 2;

// The slots of the box: equal, or the weights given in slot_weights.
slots        = len(slot_weights) > 0 ? slot_weights : drawer_slots;
slot_hs      = box_slot_heights(height_units, slots);
// Which slot a drawer is being made for (clamped to what the box has).
slot_i       = min(max(drawer_for_slot, 1), len(slot_hs)) - 1;
slot_clear_h = slot_hs[slot_i];
drawer_h     = drawer_height_mm > 0 ? drawer_height_mm
                                    : slot_clear_h - DRAWER_CLEARANCE_H;

if (part == "label")
    echo(str("label plates: ", len(label_texts), ", each ",
             label_window_h(drawer_h), " mm tall"));
if (part == "demo" || part == "box" || part == "drawer")
    echo(len(slot_hs) > 1 && min(slot_hs) < max(slot_hs) - 0.001
         ? str("slots (bottom to top): ", slot_hs,
               " mm — drawers: ", [for (h = slot_hs) h - DRAWER_CLEARANCE_H],
               " mm. This drawer is for slot ", slot_i + 1,
               ", so ", drawer_h, " mm tall.")
         : str("drawer slots: ", len(slot_hs), "   slot clearance: ",
               slot_clear_h, " mm   drawer height: ", drawer_h, " mm"));
if (part == "box_bin")
    echo(bin_drawer_slots > 0
         ? str("bin height ", bin_height_eff, " mm, with ", bin_drawer_slots,
               " drawer slots below")
         : str("bin only, fills the box — height ",
               height_units * UNIT_H - WALL_FLOOR,
               " mm (bin_height ignored)"));
// The module reports any further bin adjustments (trimmed lip, moved shelf).

// ─── Part selection ──────────────────────────────────────────────────────────
if (part == "box")
    box(width_units, depth_units, height_units, slots, true,
        slots_on_every_unit);
else if (part == "drawer")
    drawer(width_units, depth_units, cols = compartments_across,
           rows = compartments_deep, div_t = divider_thickness,
           h = drawer_h, handle = handle, layout = drawer_layout,
           layout_dir = drawer_layout_dir, label_pocket = label_pocket);
else if (part == "box_bin")
    box_drawer_bin(width_units, depth_units, height_units,
                   bin_drawer_slots > 0 ? 1 : 0,   // unused when shelf_z given
                   // slot_weights applies below the bin as well, as long as
                   // there are drawers there at all
                   bin_drawer_slots > 0 && len(slot_weights) > 0
                       ? slot_weights : bin_drawer_slots,
                   slots_on_every_unit,
                   slot_length_mm > 0 ? slot_length_mm : undef,
                   true, bin_lip_height,
                   // Bin height converted to the shelf position. With no
                   // drawers there is no shelf — the bin sits on the floor.
                   bin_drawer_slots > 0
                       ? height_units * UNIT_H - bin_height_eff
                         - BIN_SHELF_BELOW - BIN_SHELF_ABOVE
                       : undef,
                   bin_front_flush,
                   bin_roof == "yes" ? true : bin_roof == "no" ? false : undef);
else if (part == "label")
    label_plates(label_texts, width_units, drawer_h, drawer_layout,
                 drawer_layout_dir, compartments_across, compartments_deep,
                 divider_thickness, label_text_size, label_font);
else if (part == "connector")            connector();
else if (part == "connector_tolerant")   connector(true);
else if (part == "demo")                 demo_box_with_drawers();

// Preview: a box filled with drawers, one pulled out.
module demo_box_with_drawers() {
    W = width_units * UNIT_L;
    box(width_units, depth_units, height_units, slots, true,
        slots_on_every_unit);
    out = floor(len(slot_hs) / 2);   // which drawer is pulled out
    for (i = [0 : len(slot_hs) - 1])
        translate([W/2, i == out ? -45 : 0, slot_bottom(slot_hs, i)])
            drawer(width_units, depth_units,
                   h = slot_hs[i] - DRAWER_CLEARANCE_H,
                   cols = compartments_across, rows = compartments_deep,
                   div_t = divider_thickness, handle = handle,
                   layout = drawer_layout, layout_dir = drawer_layout_dir,
                   label_pocket = label_pocket);
}
