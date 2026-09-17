// params.scad — every dimension of the system in one place.
//
// Change a value here and every part follows. The grid unit is
// 73.06 × 67.20 × 74.64 mm (width × depth × height).
//
// Derivative work, CC BY-NC. Original design by termlimit, based on STTrife:
// https://www.thingiverse.com/thing:3873672

// ─── Base grid unit ──────────────────────────────────────────────────────────
// Outer size of a 1×1×1 box. All variants are whole multiples (plus 2.5×).
UNIT_L = 73.06;   // width  (X)
UNIT_D = 67.20;   // depth  (Y — front to back)
UNIT_H = 74.64;   // height (Z)

// ─── Box wall thicknesses ────────────────────────────────────────────────────
WALL_SIDE  = 3.40;   // left and right walls
WALL_BACK  = 1.00;   // back wall
WALL_FLOOR = 2.40;   // floor
WALL_TOP   = 3.36;   // ceiling
WALL_FRONT = 3.40;   // front flange (frame around the opening)
FRONT_RING = 2.40;   // width of that frame. The opening is this much smaller
                     // than the outer size on each side, and 1.00 per side
                     // WIDER than the cavity — that gap holds the drawer flange.

// Chamfers on the outer bottom and top edges, so it prints without supports.
EDGE_CHAMFER = 1.50;

// ─── Drawer slot grid ────────────────────────────────────────────────────────
// One height unit divides into 4 slots:
//   WALL_FLOOR + 4*POCKET_H + 3*RAIL_T + WALL_TOP == UNIT_H
POCKET_H = 16.50;   // clear height of one slot
RAIL_T   = 0.96;    // thickness of the rail plate the drawer rides on
RAIL_W   = 9.08;    // total rail reach from the wall (33.13 → 24.048)
RAIL_FLAT = 7.58;   // of which this much is the flat ledge (24.048 → 31.63)
RAIL_FILLET = 1.50; // R1.5 fillet where the rail meets the wall (19.86 → 21.36)
RAIL_PITCH = POCKET_H + RAIL_T;   // 17.46

// Rails run all the way into the back wall — no gap.
RAIL_BACK_GAP = 0.00;
// Back rib: at every rail level a ledge on the back wall joins the inner edges
// of the left and right rails, so each rail pair plus its rib forms a U-shaped
// frame that stiffens the box.
BACK_RIB_D = 1.50;   // how far the rib stands off the back wall (rib = RAIL_T thick)

// Anti-fallout catch at the front: a tab hanging below the rail that the
// drawer's rear wall runs into when pulled out. There is one under EVERY rail
// and one under the ceiling — one per drawer slot.
// The tab hangs 2.30 mm below the rail.
RAIL_STOP_DROP  = 2.30;   // how far it hangs below the rail
RAIL_STOP_GAP   = 0.20;   // tab face set back from the front flange
RAIL_STOP_FLAT  = 0.20;   // length at full depth
RAIL_STOP_RAMP  = 1.20;   // ramp length (slope 2.30/1.20)
// The tab does NOT span the whole rail width — it is inset from the wall so
// the drawer's SIDE wall passes beside it. The tab catches the drawer's REAR
// wall, not its side.
RAIL_STOP_INSET = 3.90;   // inset from the cavity wall face (33.13 → 29.23)
RAIL_STOP_W     = 3.46;   // width of the tab itself (29.23 → 25.78)
// Check: the drawer side wall's inner face sits 1.63 outboard of the tab,
// so the side of the drawer has clear passage.

// A drawer is this much shorter than its slot:
DRAWER_CLEARANCE_H = 0.30;   // a 16.50 slot takes a 16.20 drawer

// ─── Dovetail slots (the interlocking system) ────────────────────────────────
// The same profile on all four outer faces of a box.
DT_DEPTH      = 1.60;   // slot depth
DT_W_MOUTH    = 4.00;   // width at the surface
DT_W_FLOOR    = 6.00;   // width at the bottom (the undercut)
DT_STRAIGHT   = 0.60;   // straight run from the surface, then a 45° undercut
// The slot has a FIXED length and runs FROM THE BACK FACE forward — that is
// where the clip goes in before sliding forward. Length does not scale with
// box depth, because the clip does not either (44.80 long, so 46.80 leaves
// 2.00 of slack).
DT_LEN = 46.80;
// Pass `dovetail_len` to box() if you want a longer slot for some reason.
DT_INSET_FRONT = 20.40; // how far the slot stops short of the front face

// Enlarged ENTRY at the back face, where the clip is inserted.
// It tapers linearly to the standard section over DT_LEADIN_LEN.
DT_LEADIN_LEN     = 5.00;
DT_LEADIN_W_MOUTH = 7.80;   // mouth at the back face (standard 4.00)
DT_LEADIN_W_FLOOR = 11.25;  // floor at the back face (standard 6.00)
DT_LEADIN_DEPTH   = 1.93;   // depth at the back face (standard 1.60)

// Slot axis positions. On the side walls: measured from the box bottom and top.
DT_POS_FROM_H_EDGE = 13.062;
// On the top and bottom faces: measured from the box centre line.
DT_POS_FROM_AXIS   = 23.744;

// ─── Connector clip ──────────────────────────────────────────────────────────
// A bar with a dovetail cross-section; thickness = 2 × DT_DEPTH, so one clip
// fills the slots of two neighbouring boxes.
CONN_LEN       = 44.80;
CONN_T         = 2 * DT_DEPTH;   // 3.20
CONN_W_WAIST   = 3.30;           // waist (±1.65), for |z| <= CONN_WAIST_HALF
CONN_W_FACE    = 5.30;           // at the face (±2.65)
CONN_WAIST_HALF = 0.60;
CONN_TIP_TAPER = 5.00;           // tip taper (last 5 mm)
CONN_TIP_W     = 3.976;          // width of the tip face (±1.988)
// Clearance in the slot: (4.00-3.30)/2 = (6.00-5.30)/2 = 0.35 per side.

// Friction barbs: two bands where the face is widened. Waist unchanged.
CONN_BARB_W   = 5.65;            // face width at a barb (±2.825)
CONN_BARB_LEN = 1.00;
CONN_BARB_POS = [6.00, 38.80];   // start of each band, measured from the head
// At a barb the clearance drops from 0.35 to 0.175 per side — that is the grip.

// The TOLERANT variant is narrower by this much per side (waist and face by
// 0.15, barbs by only 0.075):
CONN_TOLERANT_EXTRA      = 0.15;
CONN_TOLERANT_EXTRA_BARB = 0.075;

// ─── Helpers ─────────────────────────────────────────────────────────────────
EPS = 0.01;   // to keep CSG cuts clean
$fn = 32;

// Outer size of a box given in grid units.
function box_size(ul, ud, uh) = [ul * UNIT_L, ud * UNIT_D, uh * UNIT_H];

// Drawer slot count of a box uh units tall, at 4 slots per unit.
function pocket_count(uh) = 4 * uh;

// ─── Link: slot count ↔ drawer height ────────────────────────────────────────
// The interior is divided into `pockets` slots separated by rails:
//   WALL_FLOOR + pockets*ph + (pockets-1)*RAIL_T + WALL_TOP == uh*UNIT_H
function pocket_height_of(uh, pockets) =
    (uh * UNIT_H - WALL_FLOOR - WALL_TOP - (pockets - 1) * RAIL_T) / pockets;

// Height of a drawer that fits such a slot.
function drawer_height_of(uh, pockets) =
    pocket_height_of(uh, pockets) - DRAWER_CLEARANCE_H;

// Reference values:
//   pocket_height_of(1, 4) = 16.50  → drawer 16.20
//   pocket_height_of(1, 2) = 33.96  → drawer 33.66
//   pocket_height_of(1, 1) = 68.88  → drawer 68.58
//   pocket_height_of(2, 4) = 35.16  → drawer 34.86

// ─── Drawer ──────────────────────────────────────────────────────────────────
// Inset front flange plus a bottom pull handle. These formulas cover drawers
// two grid units wide and up; a one-unit drawer needs an overlay front, which
// this library does not build.
DRAWER_CLEAR_SIDE = 0.35;   // clearance per side (same as the clip in its slot)
DRAWER_TOP_DROP   = 0.40;   // walls lower than the front flange
DRAWER_BACK_INSET = 3.618;  // body length = ud*UNIT_D − this value
DRAWER_WALL       = 1.92;   // side, front and back walls
DRAWER_FLOOR      = 0.80;   // floor
DRAWER_FLANGE_T   = 1.50;   // front flange thickness
DRAWER_DIV_T      = 1.92;   // divider thickness — 2-unit family
DRAWER_DIV_T_3U   = 1.20;   // divider thickness — slimmer, for many compartments
// Divider thickness is a parameter because it is a trade-off: thicker is
// stiffer, thinner leaves more usable space. drawer() also takes a separate
// thickness and a height drop for the cross dividers.

// Notches for the box's anti-fallout catches.
// The catches hang below every rail and reach inboard past the drawer's inner
// wall face, so any divider that runs full height across the drawer would
// collide with them and stop the drawer from closing. The dividers therefore
// get a channel cut out of their top edge along both side walls.
//
// Worst case over both box families, measured inboard from the drawer's inner
// wall face: the catch reaches 6.81 mm in, and drops 1.60 mm below the top of
// the drawer walls. These values clear that with margin:
DRAWER_NOTCH_W     = 7.00;   // how far inboard the notch reaches
DRAWER_NOTCH_DEPTH = 3.00;   // how far below the top of the walls it cuts.
                             // A catch reaches 1.60 below the wall top; the
                             // rest is clearance — 2.00 was found to catch on
                             // the rail stop in a test print.
// Where a catch actually travels, measured inboard from the inner face of the
// drawer's side wall. Only dividers reaching into this band have to be cut.
CATCH_BAND_0 = RAIL_STOP_INSET - DRAWER_CLEAR_SIDE - DRAWER_WALL;   // 1.63
CATCH_BAND_1 = CATCH_BAND_0 + RAIL_STOP_W;                          // 5.09

// Chamfers: bottom edge of the body (0.50 in X, 1.50 in Y, over 1.50 of height)
// and the floor-to-wall transition inside (1.50).
DRAWER_BOT_CHAMFER_X = 0.50;
DRAWER_BOT_CHAMFER_Y = 1.50;
DRAWER_BOT_CHAMFER_H = 1.50;
DRAWER_INNER_CHAMFER = 1.50;

// Bottom pull handle: a tab under the front, tapering towards its tip.
HANDLE_PROTRUDE = 9.00;
HANDLE_H        = 2.16;
HANDLE_W_BASE   = 45.46;
HANDLE_W_TIP    = 23.18;
HANDLE_BASE_LEN = 6.07;   // full width is kept over this length
// Thickened tip: a triangular ridge on top with 45° flanks, so a fingertip has
// something to pull against. Its peak is halfway between HANDLE_BASE_LEN and
// HANDLE_PROTRUDE, so the height follows from the 45° angle:
HANDLE_RIDGE_H = (HANDLE_PROTRUDE - HANDLE_BASE_LEN) / 2;  // 1.465

// ─── Open bin (instead of drawers) ───────────────────────────────────────────
// Scoop shape: flat floor at the back, a 45° rise towards the front, a low
// lip, and a large R100 arc sweeping the top edge down from the ceiling to
// that lip.
BIN_SHELF_BELOW = 0.86;   // shelf: this much below the unit boundary
BIN_SHELF_ABOVE = 1.54;   // and this much above it (2.40 thick in total)
BIN_LIP_T       = 5.40;   // thickness of the bin's front wall (the lip)
BIN_LIP_H       = 28.56;  // default lip height above the bin floor (2× variant)
// The 45° rise runs as far back as the lip is tall.
BIN_ARC_R       = 100.00; // radius of the top edge arc
BIN_ARC_LIP_Y   = 4.40;   // where the arc meets the lip (= BIN_LIP_T − 1.00)

// The arc centre is not stored — it follows from the rule: an arc of radius
// BIN_ARC_R passes through the top of the lip and reaches the top face exactly
// at HALF THE BOX DEPTH. arc_center() below computes it.
//
// Two lip heights that work well:
BIN_LIP_H_2U    = 28.56;  // deeper bin, taller front lip
BIN_LIP_H_3U    = 18.56;  // shallower lip, easier to reach into

// Auto-fit for when the requested split leaves no room for the bin (e.g. a box
// one unit tall with the shelf landing on the top face). The shelf is then
// moved down and the lip trimmed to stay in proportion.
BIN_MIN_H        = 20.00;  // minimum bin height at the back
BIN_LIP_MAX_FRAC = 0.45;   // lip at most this fraction of the bin height

// Centre of the circle of radius r through p1 and p2
// (the branch that bows the arc up and towards the front).
function arc_center(p1, p2, r) =
    let (d  = [p2[0] - p1[0], p2[1] - p1[1]],
         L  = norm(d),
         h  = sqrt(max(0, r*r - L*L/4)),
         nn = [-d[1]/L, d[0]/L])
    [(p1[0]+p2[0])/2 + h*nn[0], (p1[1]+p2[1])/2 + h*nn[1]];

// ─── Label pocket on the drawer front ────────────────────────────────────────
// Two side ribs and a shelf standing proud of the front face; a paper card or
// a printed plate slides in from above. One window per column of compartments.
LABEL_SLOT       = 0.80;   // gap between the front face and the rail
LABEL_RAIL_T     = 0.96;   // rail thickness — the pocket stands 1.76 proud
LABEL_EDGE_INSET = 1.50;   // pocket edge, inside the edge of the front
LABEL_RIB_W      = 2.50;   // rib at the outer ends
LABEL_RIB_MID    = 2.81;   // rib on each side of the boundary between windows
LABEL_SHELF_Z0   = 2.16;   // shelf bottom, above the bottom of the front
LABEL_SHELF_Z1   = 4.00;   // shelf top — a card rests here
LABEL_TOP_DROP   = 1.50;   // rib top, below the top of the front
LABEL_GUSSET     = 2.00;   // triangular brace between the shelf and the ribs
LABEL_CARD_OVER  = 1.54;   // how far the ribs overlap the card that is in the
                           // slot — the card is wider than the window it shows
                           // through, which is what keeps it from falling out
LABEL_SHELF_SLOT = 2.46;   // shelf top inside the slot; the card rests here

// ─── Label plate — the part that slides into the pocket ──────────────────────
// Printed flat, for multi-material printing: the lettering is inlaid into the
// face, not raised, so the base and the text sit side by side in the same
// layers. Two parts come out of the same 2D outline — the plate with the
// letters cut out of it, and the letters themselves — and the slicer prints
// them as one object with two filaments. No clearance between them on purpose:
// the boolean happens in the slicer, so the outlines have to match exactly.
LABEL_PLATE_CLEAR = 0.20;  // thinner than the slot
LABEL_PLATE_SIDE  = 0.30;  // clearance per side inside the window
LABEL_PLATE_BACK  = 0.20;  // solid backing under the inlay — one layer at 0.2
LABEL_TEXT_D      = 0.40;  // inlay depth: plate thickness minus the backing
LABEL_NOTCH_R     = 3.00;  // finger notch in the top edge
LABEL_PLATE_GAP   = 4.00;  // spacing when plates are laid out in a row
