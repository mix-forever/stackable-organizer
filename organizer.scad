// organizer.scad — the parametric modules.
//
// Derivative work, CC BY-NC. Original design by termlimit, based on STTrife:
// https://www.thingiverse.com/thing:3873672
// Every dimension lives in params.scad.
//
// AXES: X = width, Y = depth (FRONT = Y 0, back = Y +D), Z = height (0..H).
// The box corner sits at (0,0,0), so parts drop straight onto the bed.

include <params.scad>

// ─── Dovetail slot profile ───────────────────────────────────────────────────
// A NEGATIVE solid. The worked surface lies at z=0 and the slot occupies
// z ∈ [−DT_DEPTH, 0] (i.e. it goes into −z), running along +Y for `len`.
// When placing it on a face, rotate so that local −Z points INTO the material.
// (Note: rotate([-90,0,0]) maps (x,y,z) → (x, z, −y), which is why the polygon
// y-coordinates are positive — after the rotation they become depth in −z.)
module dovetail_groove(len, leadin = DT_LEADIN_LEN) {
    rotate([-90, 0, 0]) {
        // the standard-section run
        translate([0, 0, leadin])
            linear_extrude(height = len - leadin) dt_profile();
        // entry: linear taper from the enlarged section to the standard one
        if (leadin > 0)
            hull() {
                linear_extrude(height = EPS) dt_profile(true);
                translate([0, 0, leadin - EPS])
                    linear_extrude(height = EPS) dt_profile();
            }
    }
}

// Slot cross-section. Surface at y=0, depth in +y (which the rotation turns
// into −z). The polygon is convex, so hull() produces a correct linear taper
// for the entry without flooding the undercut.
module dt_profile(wide = false) {
    mw = (wide ? DT_LEADIN_W_MOUTH : DT_W_MOUTH) / 2;
    fw = (wide ? DT_LEADIN_W_FLOOR : DT_W_FLOOR) / 2;
    dp =  wide ? DT_LEADIN_DEPTH   : DT_DEPTH;
    polygon([[ mw, -EPS], [ mw, DT_STRAIGHT], [ fw, dp],
             [-fw, dp], [-mw, DT_STRAIGHT], [-mw, -EPS]]);
}

// The full set of slots for a ul×ud×uh box, in box coordinates.
// Two slots per grid unit, so boxes of any size clip together anywhere on
// the grid.
// `side_z_max` — skip side-wall slots above this height. Used when the wall is
//   cut away at the top (bin) and too little of it is left for a clip to fit.
module box_dovetails(ul, ud, uh, per_unit = true, len_override = undef,
                     skip_top = false, side_z_max = undef) {
    W = ul * UNIT_L;  D = ud * UNIT_D;  H = uh * UNIT_H;
    // Fixed length from the back face (Y=D) forward — independent of box
    // depth, because the clip's length is fixed too. `len_override` is there
    // if you ever want a longer slot.
    len = is_undef(len_override) ? min(DT_LEN, D - WALL_FRONT) : len_override;

    // Slot heights on the side walls.
    zs_all = per_unit
        ? [ for (k = [0 : uh - 1], s = [0, 1])
              k * UNIT_H + (s == 0 ? DT_POS_FROM_H_EDGE
                                   : UNIT_H - DT_POS_FROM_H_EDGE) ]
        : [ DT_POS_FROM_H_EDGE, H - DT_POS_FROM_H_EDGE ];
    zs = is_undef(side_z_max)
        ? zs_all
        : [ for (z = zs_all) if (z <= side_z_max) z ];

    // Side walls: face X=0 (slot cuts into +x) and X=W (into −x).
    // mirror([0,1,0]) flips the extrusion direction so the slot runs from the
    // back face forward, putting the enlarged entry at the back.
    for (z = zs) {
        translate([0, D, z]) mirror([0,1,0]) rotate([0, -90, 0]) dovetail_groove(len);
        translate([W, D, z]) mirror([0,1,0]) rotate([0,  90, 0]) dovetail_groove(len);
    }

    // Slot positions on the top and bottom faces (from each unit's centre).
    xs = per_unit
        ? [ for (k = [0 : ul - 1], s = [-1, 1])
              (k + 0.5) * UNIT_L + s * DT_POS_FROM_AXIS ]
        : [ W/2 - DT_POS_FROM_AXIS, W/2 + DT_POS_FROM_AXIS ];

    for (x = xs) {
        translate([x, D, 0]) mirror([0,1,0]) rotate([0, 180, 0]) dovetail_groove(len);
        if (!skip_top)
            translate([x, D, H]) mirror([0,1,0])                 dovetail_groove(len);
    }
}

// ─── Box body ────────────────────────────────────────────────────────────────
// `pockets` — TOTAL number of drawer slots in the box (not per unit).
//   Defaults to 4·uh, i.e. four slots per grid unit.
//   Slot clearance and matching drawer height come from pocket_height_of()
//   and drawer_height_of() in params.scad.
module box(ul = 1, ud = 1, uh = 1, pockets = undef, rails = true,
           per_unit_dovetails = true) {
    np = is_undef(pockets) ? 4 * uh : pockets;
    ph = pocket_height_of(uh, np);
    W = ul * UNIT_L;  D = ud * UNIT_D;  H = uh * UNIT_H;
    // Interior cavity.
    cx0 = WALL_SIDE;  cx1 = W - WALL_SIDE;
    cz0 = WALL_FLOOR; cz1 = H - WALL_TOP;
    cy1 = D - WALL_BACK;             // inner face of the back wall
    cy0 = WALL_FRONT;                // inner face of the front flange

    difference() {
        union() {
            // Block with chamfers on the bottom and top side edges.
            hull() {
                translate([EDGE_CHAMFER, 0, 0]) cube([W - 2*EDGE_CHAMFER, D, EPS]);
                translate([0, 0, EDGE_CHAMFER]) cube([W, D, H - 2*EDGE_CHAMFER]);
                translate([EDGE_CHAMFER, 0, H - EPS]) cube([W - 2*EDGE_CHAMFER, D, EPS]);
            }
        }

        // Cavity (from the front flange to the back).
        translate([cx0, cy0, cz0]) cube([cx1 - cx0, cy1 - cy0, cz1 - cz0]);

        // Front opening — wider than the cavity, leaving room for the drawer
        // flange.
        translate([FRONT_RING, -EPS, WALL_FLOOR])
            cube([W - 2*FRONT_RING, WALL_FRONT + 2*EPS, H - WALL_FLOOR - FRONT_RING]);

        // Connector slots.
        box_dovetails(ul, ud, uh, per_unit_dovetails);
    }

    // Drawer rails: np-1 pairs, on the slot boundaries.
    if (rails && np > 1)
        for (i = [1 : np - 1]) {
            z = WALL_FLOOR + i * ph + (i - 1) * RAIL_T;
            rail_pair(W, cy1 - cy0 - RAIL_BACK_GAP, z, cx0, cx1, cy0);
        }

    // Anti-fallout catches: one per drawer slot — under every rail and under
    // the ceiling (for the topmost drawer).
    if (rails)
        for (i = [1 : np]) {
            z = (i < np) ? WALL_FLOOR + i * ph + (i - 1) * RAIL_T
                         : H - WALL_TOP;
            for (m = [0, 1])
                translate([m ? cx1 : cx0, cy0, z])
                    mirror([m ? 1 : 0, 0, 0]) rail_stop();
        }
}

// A pair of rails (left + right) at height z (underside of the rail), plus the
// back rib joining their inner edges along the back wall. `len` runs from cy0
// to the inner face of the back wall.
module rail_pair(W, len, z, cx0, cx1, cy0) {
    for (m = [0, 1])
        translate([m ? cx1 : cx0, cy0, z])
        mirror([m ? 1 : 0, 0, 0])
        rail(len);
    translate([cx0 + RAIL_W - EPS, cy0 + len - BACK_RIB_D, z])
        cube([cx1 - cx0 - 2*RAIL_W + 2*EPS, BACK_RIB_D + EPS, RAIL_T]);
}

// The catch under the rail, at the front. Profile in the (Y, Z) plane: full
// depth for RAIL_STOP_FLAT behind the flange, then a ramp back up to the
// underside of the rail.
// In X it is only a narrow tab, inset by RAIL_STOP_INSET from the wall — the
// drawer's side wall passes beside it. The tab catches the drawer's rear wall.
module rail_stop() {
    // rotate([0,90,0]) maps (x,y,z) → (z, y, −x), so:
    //   the extrusion (local z) → +X (across the rail),
    //   the polygon's first coordinate → −Z, so the tab HANGS DOWN.
    translate([RAIL_STOP_INSET, 0, 0])
        rotate([0, 90, 0]) linear_extrude(height = RAIL_STOP_W)
            polygon([[0, RAIL_STOP_GAP],
                     [RAIL_STOP_DROP, RAIL_STOP_GAP],
                     [RAIL_STOP_DROP, RAIL_STOP_GAP + RAIL_STOP_FLAT],
                     [0, RAIL_STOP_GAP + RAIL_STOP_FLAT + RAIL_STOP_RAMP]]);
}

// One rail: a RAIL_FLAT ledge plus a fillet where it meets the wall.
// `z` at the call site is the rail's UNDERSIDE, so the plate must grow upward.
// rotate([-90,0,0]) maps the profile's second coordinate to −Z, so the 2D
// content is mirrored in Y first; without that the rail sits RAIL_T too low
// and every slot below it loses that much clearance.
module rail(len) {
    rotate([-90, 0, 0]) linear_extrude(height = len) mirror([0, 1]) {
        square([RAIL_W, RAIL_T]);
        // fillet against the wall, above the ledge
        difference() {
            square([RAIL_FILLET, RAIL_T + RAIL_FILLET]);
            translate([RAIL_FILLET, RAIL_T + RAIL_FILLET])
                circle(r = RAIL_FILLET, $fn = 24);
        }
    }
}

// ─── Connector clip ──────────────────────────────────────────────────────────
// A bar with a double-dovetail cross-section. It lies in the XY plane with its
// thickness in Z, and joins two boxes by filling both their slots (2 × DT_DEPTH).
module connector(tolerant = false) {
    d  = tolerant ? CONN_TOLERANT_EXTRA : 0;
    db = tolerant ? CONN_TOLERANT_EXTRA_BARB : 0;

    intersection() {
        union() {
            conn_bar(CONN_W_FACE/2 - d, CONN_W_WAIST/2 - d, CONN_LEN);
            for (y0 = CONN_BARB_POS)
                translate([0, y0, 0])
                    conn_bar(CONN_BARB_W/2 - db, CONN_W_WAIST/2 - d,
                             CONN_BARB_LEN);
        }
        // tip taper over the last CONN_TIP_TAPER mm
        hull() {
            translate([-CONN_BARB_W/2, 0, -CONN_T/2])
                cube([CONN_BARB_W, CONN_LEN - CONN_TIP_TAPER, CONN_T]);
            translate([-CONN_TIP_W/2, CONN_LEN - EPS, -CONN_T/2])
                cube([CONN_TIP_W, EPS, CONN_T]);
        }
    }
}

// A length of dovetail bar: face half-width `fh`, waist half-width `wh`,
// length `len` along +Y.
module conn_bar(fh, wh, len) {
    zw = CONN_WAIST_HALF;   // 0.60
    zf = CONN_T / 2;        // 1.60
    rotate([-90, 0, 0]) linear_extrude(height = len)
        polygon([
            [ wh,  zw], [ fh,  zf], [-fh,  zf], [-wh,  zw],
            [-wh, -zw], [-fh, -zf], [ fh, -zf], [ wh, -zw]
        ]);
}

// ─── Drawer helpers ──────────────────────────────────────────────────────────
// Does a divider at x, `t` thick, reach into the path of either catch?
function in_catch_band(x, t, cw) =
    let (l = x + cw/2, r = cw/2 - (x + t))          // inboard gap on each side
    (l < CATCH_BAND_1 && l + t > CATCH_BAND_0) ||
    (r < CATCH_BAND_1 && r + t > CATCH_BAND_0);

// The two clearance channels the catches travel in.
module drawer_notches(cw, bl, bh) {
    for (m = [0, 1])
        translate([m ? cw/2 - DRAWER_NOTCH_W : -cw/2, -EPS,
                   bh - DRAWER_NOTCH_DEPTH])
            cube([DRAWER_NOTCH_W, bl + 2*EPS, DRAWER_NOTCH_DEPTH + EPS]);
}

// Drawer dimensions that other parts need too — the label plates have to know
// how wide a pocket window is without building a drawer first.
function drawer_front_w(ul) = ul * UNIT_L - 2 * FRONT_RING - 2 * DRAWER_CLEAR_SIDE;
function drawer_body_w(ul)  = ul * UNIT_L - 2 * WALL_SIDE  - 2 * DRAWER_CLEAR_SIDE;
function drawer_inner_w(ul) = drawer_body_w(ul) - 2 * DRAWER_WALL;

// Layout entries: a column is [width weight, [row weights]], and a plain
// number n is shorthand for a column of standard width split into n equal
// rows. These two functions expand either form.
function col_weight(c) = is_num(c) ? 1 : c[0];
function col_rows(c)   = is_num(c) ? [for (i = [1 : max(c, 1)]) 1]
                                   : (len(c[1]) > 0 ? c[1] : [1]);

function wsum(v, i = 0) = i >= len(v) ? 0 : v[i] + wsum(v, i + 1);

// Size and start offset of element `i` of a weighted run: `space` is what is
// left for the compartments themselves, `t` the divider thickness between them.
function share(w, i, space) = space * w[i] / wsum(w);
function offset_of(w, i, space, t, k = 0) =
    k >= i ? 0 : share(w, k, space) + t + offset_of(w, i, space, t, k + 1);

// The layout actually used: the given one, or a plain grid built from
// cols x rows (swapped when the layout is read as bands).
function layout_or_grid(layout, dir, cols, rows) =
    is_undef(layout) || len(layout) == 0
        ? (dir == "rows" ? grid_layout(rows, cols) : grid_layout(cols, rows))
        : layout;

// cols x rows as a layout, so the module has a single code path.
function grid_layout(major, minor) =
    [for (i = [1 : max(major, 1)]) [1, [for (j = [1 : max(minor, 1)]) 1]]];

// A divider running front to back, at x, `t` thick, over y0 .. y0+ylen. It
// runs parallel to the catches, so it keeps its full height — unless it lands
// in a catch's path, in which case it is notched like a cross divider.
module divider_lengthwise(x, t, y0, ylen, cw, bl, bh, cz, notch, name) {
    hit = notch && in_catch_band(x, t, cw);
    difference() {
        translate([x, y0, cz]) cube([t, ylen, bh - cz]);
        if (hit) drawer_notches(cw, bl, bh);
    }
    if (hit)
        echo(str("note: ", name, " sits in the path of the box's catches, ",
                 "so it is notched too"));
}

// A divider running across, at y, `t` thick, over x0 .. x0+xlen. These cross
// the catches' path, so they are notched along both side walls — see
// DRAWER_NOTCH_* in params.scad. Without the notch the drawer will not close.
module divider_cross(y, t, x0, xlen, cw, bl, bh, cz, drop, notch) {
    difference() {
        translate([x0, y, cz]) cube([xlen, t, bh - cz - drop]);
        if (notch) drawer_notches(cw, bl, bh);
    }
}

// All the dividers of one layout. `dir` says which way the layout is read:
//   "cols" — the drawer is split into columns, each with its own rows
//   "rows" — the drawer is split into bands across, each with its own columns
// Thickness follows the orientation of the divider itself, not its role:
// front-to-back dividers are div_t, cross dividers dtr (and they drop).
module drawer_dividers(lay, dir, cw, cl, cy0, cz, bh, bl,
                       div_t, dtr, div_rows_drop, notch) {
    mw = [for (c = lay) col_weight(c)];              // weights of the outer split
    mt = dir == "rows" ? dtr : div_t;                // its divider thickness
    mspace = (dir == "rows" ? cl : cw) - (len(lay) - 1) * mt;

    // outer split
    if (len(lay) > 1)
        for (i = [1 : len(lay) - 1]) {
            o = offset_of(mw, i, mspace, mt) - mt;
            if (dir == "rows")
                divider_cross(cy0 + o, mt, -cw/2, cw, cw, bl, bh, cz,
                              div_rows_drop, notch);
            else
                divider_lengthwise(-cw/2 + o, mt, cy0, cl, cw, bl, bh, cz,
                                   notch, str("lengthwise divider ", i));
        }

    // inner split, inside each column / band
    for (i = [0 : len(lay) - 1]) {
        iw = col_rows(lay[i]);                       // weights inside this one
        it = dir == "rows" ? div_t : dtr;
        ispace = (dir == "rows" ? cw : cl) - (len(iw) - 1) * it;
        o0 = offset_of(mw, i, mspace, mt);           // where this one starts
        msize = share(mw, i, mspace);                // and how big it is
        if (len(iw) > 1)
            for (j = [1 : len(iw) - 1]) {
                p = offset_of(iw, j, ispace, it) - it;
                if (dir == "rows")
                    divider_lengthwise(-cw/2 + p, it, cy0 + o0, msize,
                                       cw, bl, bh, cz, notch,
                                       str("divider ", j, " of band ", i + 1));
                else
                    divider_cross(cy0 + p, it, -cw/2 + o0, msize,
                                  cw, bl, bh, cz, div_rows_drop, notch);
            }
    }
}

// ─── Drawer ──────────────────────────────────────────────────────────────────
// Own frame: X centred, front flange face at Y=0 (body in +Y, handle in −Y),
// floor at Z=0.
//
// `pocket_h` is the slot clearance in the box — the drawer is DRAWER_CLEARANCE_H
// shorter. `cols` × `rows` is the compartment count (along X × along Y);
// 1×1 means a single compartment, and the dividers split the interior into
// EQUAL parts.
// `layout` — arbitrary compartments instead of a plain grid. A list of
//            columns, front to back, each written as
//            [width weight, [row weights]]:
//
//              layout = [ [1, [1,1]],     // 2 equal rows
//                         [2, [1]],       // twice as wide, undivided
//                         [1, [1,2,1]] ]  // 3 rows, middle one twice as deep
//
//            A plain number is shorthand for a standard-width column with
//            that many equal rows, so layout = [2,1,3] also works. The
//            weights are relative — [1,2,1] and [10,20,10] are the same
//            drawer — and they always fill the width and depth available.
//            `layout` overrides `cols` and `rows`.
// `layout_dir` — which way `layout` is read. "cols" (the default) splits the
//            drawer into columns, each with its own rows. "rows" splits it
//            into bands across the drawer, each with its own columns: the
//            first weight is then the depth of the band and the inner list
//            its columns.
// `div_t`         — thickness of the dividers along X (splitting the width)
// `div_t_rows`    — thickness of the dividers along Y (defaults to div_t)
// `div_rows_drop` — how much lower the Y dividers are than the walls
//                   (Drawer_2x2x1_six_div: 0.96 thick, dropped 2.0;
//                    Drawer_2x2x2_six_compartments: 1.92 and 0)
// `notch` — cut the clearance channels for the box's anti-fallout catches out
//           of the dividers' top edge. Leave on unless you know the box you
//           are printing for has no catches.
module drawer(ul = 2, ud = 2, pocket_h = POCKET_H, cols = 1, rows = 1,
              handle = true, div_t = DRAWER_DIV_T,
              div_t_rows = undef, div_rows_drop = 0, h = undef,
              notch = true, layout = undef, layout_dir = "cols",
              label_pocket = false) {
    dtr = is_undef(div_t_rows) ? div_t : div_t_rows;
    assert(layout_dir == "cols" || layout_dir == "rows",
           "layout_dir has to be \"cols\" or \"rows\"");
    lay = layout_or_grid(layout, layout_dir, cols, rows);
    assert(min([for (c = lay) col_weight(c)]) > 0,
           "layout: every column needs a width weight above 0");
    assert(min([for (c = lay) min(col_rows(c))]) > 0,
           "layout: every row weight has to be above 0");
    fw = drawer_front_w(ul);                                    // flange width
    bw = drawer_body_w(ul);                                     // body width
    // Flange height: given directly (`h`), or slot clearance minus tolerance.
    fh = is_undef(h) ? pocket_h - DRAWER_CLEARANCE_H : h;
    bh = fh - DRAWER_TOP_DROP;                                  // wall height
    bl = ud * UNIT_D - DRAWER_BACK_INSET;                       // body length

    cw  = drawer_inner_w(ul);            // interior width
    cy0 = DRAWER_WALL;                   // interior starts behind the front wall
    cl  = bl - 2 * DRAWER_WALL;          // interior length
    cz  = DRAWER_FLOOR;                  // interior floor level

    union() {
        difference() {
            union() {
                // front flange (the widest and tallest part)
                translate([-fw/2, 0, 0]) cube([fw, DRAWER_FLANGE_T, fh]);
                // body, with chamfers on the bottom edge
                hull() {
                    translate([-(bw/2 - DRAWER_BOT_CHAMFER_X), 0, 0])
                        cube([bw - 2*DRAWER_BOT_CHAMFER_X,
                              bl - DRAWER_BOT_CHAMFER_Y, EPS]);
                    translate([-bw/2, 0, DRAWER_BOT_CHAMFER_H])
                        cube([bw, bl, bh - DRAWER_BOT_CHAMFER_H]);
                }
            }
            // interior, chamfered where the floor meets the walls
            ch = DRAWER_INNER_CHAMFER;
            hull() {
                translate([-(cw/2 - ch), cy0 + ch, cz])
                    cube([cw - 2*ch, cl - 2*ch, EPS]);
                translate([-cw/2, cy0, cz + ch])
                    cube([cw, cl, bh - cz - ch + EPS]);
            }
        }

        // Dividers — see drawer_dividers() above for how a layout is read.
        drawer_dividers(lay, layout_dir, cw, cl, cy0, cz, bh, bl,
                        div_t, dtr, div_rows_drop, notch);

        // Label pocket on the front face, one window per column.
        if (label_pocket)
            front_label_pocket(lay, layout_dir, cw, fw, fh, div_t);

        // bottom handle with the thickened tip
        if (handle) {
            linear_extrude(height = HANDLE_H) handle_plan();
            // ridge: a 45° triangle on top near the tip, clipped to the handle
            // outline (which tapers)
            intersection() {
                linear_extrude(height = HANDLE_H + HANDLE_RIDGE_H) handle_plan();
                translate([-HANDLE_W_BASE/2, 0, 0]) rotate([0, 90, 0])
                    linear_extrude(height = HANDLE_W_BASE)
                        polygon([[-HANDLE_H, -HANDLE_BASE_LEN],
                                 [-(HANDLE_H + HANDLE_RIDGE_H),
                                  -(HANDLE_BASE_LEN + HANDLE_RIDGE_H)],
                                 [-HANDLE_H, -HANDLE_PROTRUDE]]);
            }
        }
    }
}

// Handle outline in plan (XY): full width at the flange, tapering to the tip.
module handle_plan() {
    hull() {
        translate([-HANDLE_W_BASE/2, -HANDLE_BASE_LEN])
            square([HANDLE_W_BASE, HANDLE_BASE_LEN + EPS]);
        translate([-HANDLE_W_TIP/2, -HANDLE_PROTRUDE])
            square([HANDLE_W_TIP, EPS]);
    }
}

// ─── Box with drawers and an open bin ────────────────────────────────────────
// The lower part (uh_drawers units) holds `pockets` drawers, with a shelf above
// it and an open bin on top. Bin shape: flat floor at the back, a 45° rise
// towards the front, a low lip, and an R100 arc along the top edge.
// `uh_drawers`      — how many height units the drawer section takes.
//                     0 = no drawers, the whole box is a bin.
// `shelf_z`         — explicit position of the shelf UNDERSIDE; overrides
//                     `uh_drawers`. Needed for a box one unit tall, where the
//                     unit boundary lands on the top face and no bin would fit.
// `bin_front_flush` — true: bin front panel FLUSH with the face (full BIN_LIP_T
//                     thick). false: recessed 3.40 behind the front frame, so
//                     only the 2.40 side posts reach the face.
module box_drawer_bin(ul = 2, ud = 2, uh = 2, uh_drawers = 1, pockets = 2,
                      per_unit_dovetails = true, dovetail_len = undef,
                      rails = true, bin_lip_h = BIN_LIP_H,
                      shelf_z = undef, bin_front_flush = true,
                      bin_roof = undef) {
    W = ul * UNIT_L;  D = ud * UNIT_D;  H = uh * UNIT_H;

    has_dr   = uh_drawers > 0 || !is_undef(shelf_z);
    shelf_t  = BIN_SHELF_BELOW + BIN_SHELF_ABOVE;

    // Requested position of the shelf top (= the bin floor).
    zst_req = !is_undef(shelf_z) ? shelf_z + shelf_t
            : has_dr ? uh_drawers * UNIT_H + BIN_SHELF_ABOVE
                     : WALL_FLOOR;
    // The bin needs at least BIN_MIN_H of height, otherwise the result is
    // nonsense (with uh=1 and uh_drawers=1 the shelf landed on the top face).
    zst = min(zst_req, H - BIN_MIN_H);
    zsb = has_dr ? zst - shelf_t : WALL_FLOOR;
    // The lip may not exceed BIN_LIP_MAX_FRAC of the bin height.
    lip = min(bin_lip_h, BIN_LIP_MAX_FRAC * (H - zst));

    ph  = has_dr && pockets > 0
        ? (zsb - WALL_FLOOR - (pockets - 1) * RAIL_T) / pockets : 0;

    if (zst < zst_req - 0.001)
        echo(str("box_drawer_bin: shelf moved from ", zst_req, " to ", zst,
                 " — the bin needs at least ", BIN_MIN_H, " mm"));
    if (lip < bin_lip_h - 0.001)
        echo(str("box_drawer_bin: lip trimmed from ", bin_lip_h, " to ", lip,
                 " (max ", BIN_LIP_MAX_FRAC, " of the bin height)"));
    if (has_dr && pockets > 0 && ph < 8)
        echo(str("WARNING box_drawer_bin: drawer slot is only ", ph,
                 " mm — use fewer drawers or a taller box"));

    // The roof over the back of the bin survives only behind the arc, i.e.
    // from half the depth backwards. If that strip is shorter than a slot,
    // neither a clip fits in it nor does the roof make sense — the bin then
    // becomes a PLAIN OPEN SHELF: no roof, walls dropping to the lip at 45°.
    // Depth decides by default; `bin_roof` forces it either way.
    roof = is_undef(bin_roof) ? (D / 2 >= DT_LEN) : bin_roof;
    // Top-face slots only make sense when there is a roof long enough to hold
    // a clip.
    skip_top = !roof;

    // The side wall is cut away at the top (by the arc or the 45° slope), so a
    // slot at a given height only has as much wall as remains behind that cut.
    // Above `side_z_max` a clip (CONN_LEN) no longer fits and the slot would be
    // decorative — skip it.
    ac = arc_center([BIN_ARC_LIP_Y, zst + lip], [D/2, H], BIN_ARC_R);
    q  = D - CONN_LEN - ac[0];
    side_z_max = roof
        ? (q >= BIN_ARC_R ? H
                          : ac[1] - sqrt(BIN_ARC_R*BIN_ARC_R - q*q))
        : zst + lip + D - BIN_LIP_T - CONN_LEN;

    if (!roof)
        echo(str("box_drawer_bin: depth ", D, " → bin without a roof ",
                 "(open shelf), no slots on the top face"));
    if (side_z_max < H)
        echo(str("box_drawer_bin: skipping side slots above z=", side_z_max,
                 " (wall cut away, a ", CONN_LEN, " clip would not fit)"));

    cx0 = WALL_SIDE;  cx1 = W - WALL_SIDE;
    cy1 = D - WALL_BACK;

    difference() {
        union() {
            // body with chamfers (as in box())
            hull() {
                translate([EDGE_CHAMFER, 0, 0])
                    cube([W - 2*EDGE_CHAMFER, D, EPS]);
                translate([0, 0, EDGE_CHAMFER])
                    cube([W, D, H - 2*EDGE_CHAMFER]);
                translate([EDGE_CHAMFER, 0, H - EPS])
                    cube([W - 2*EDGE_CHAMFER, D, EPS]);
            }
            // shelf between the drawers and the bin
            if (has_dr)
                translate([cx0, WALL_FRONT, zsb])
                    cube([cx1 - cx0, cy1 - WALL_FRONT, zst - zsb]);
        }

        // drawer cavity
        if (has_dr)
            translate([cx0, WALL_FRONT, WALL_FLOOR])
                cube([cx1 - cx0, cy1 - WALL_FRONT, zsb - WALL_FLOOR]);
        // Bin cavity — the front wall is thicker (the lip). With a roof: up to
        // the underside of the ceiling, because the ceiling stays and only the
        // arc opens it. Without a roof: all the way up, so the ceiling goes.
        translate([cx0, BIN_LIP_T, zst])
            cube([cx1 - cx0, cy1 - BIN_LIP_T,
                  (roof ? H - WALL_TOP : H + EPS) - zst]);
        // Front recess. With `bin_front_flush` it stops at the shelf underside,
        // leaving the bin panel solid and flush. Without it, the recess runs up
        // to the lip and the panel ends up recessed by 3.40.
        translate([FRONT_RING, -EPS, WALL_FLOOR])
            cube([W - 2*FRONT_RING, WALL_FRONT + 2*EPS,
                  (bin_front_flush ? zsb : zst + lip) - WALL_FLOOR]);
        // Top edge of the bin.
        if (roof)
            // With a roof: the inside of an R100 cylinder. The centre follows
            // the rule — the arc passes through the top of the lip and meets
            // the top face at half the depth.
            let (c = arc_center([BIN_ARC_LIP_Y, zst + lip], [D/2, H],
                                BIN_ARC_R))
                translate([-EPS, c[0], c[1]]) rotate([0, 90, 0])
                    cylinder(r = BIN_ARC_R, h = W + 2*EPS, $fn = 180);
        else
            // Without a roof: the walls drop from full height to the lip at
            // 45°, a straight stand-in for the arc.
            let (zl = zst + lip)
                translate([-EPS, 0, 0]) rotate([0, 90, 0])
                    linear_extrude(height = W + 2*EPS)
                        polygon([[-zl, -EPS], [-zl, BIN_LIP_T],
                                 [-(H + EPS), BIN_LIP_T + (H - zl)],
                                 [-(H + EPS), -EPS]]);
        // connector slots
        box_dovetails(ul, ud, uh, per_unit_dovetails, dovetail_len,
                      skip_top, side_z_max);
    }

    // The bin floor's 45° rise — ADDED AFTER the cavity is subtracted, or the
    // bin cavity would eat it. Its peak sits 0.23 below the arc, so it does not
    // stick into the opening.
    translate([cx0, 0, 0]) bin_ramp(cx1 - cx0, zst, lip);

    // rails and catches in the drawer section
    if (rails && has_dr && pockets > 0) {
        if (pockets > 1)
            for (i = [1 : pockets - 1])
                rail_pair(W, cy1 - WALL_FRONT - RAIL_BACK_GAP,
                          WALL_FLOOR + i * ph + (i - 1) * RAIL_T,
                          cx0, cx1, WALL_FRONT);
        for (i = [1 : pockets]) {
            z = (i < pockets) ? WALL_FLOOR + i * ph + (i - 1) * RAIL_T : zsb;
            for (m = [0, 1])
                translate([m ? cx1 : cx0, WALL_FRONT, z])
                    mirror([m ? 1 : 0, 0, 0]) rail_stop();
        }
    }
}

// The bin floor's rise: a triangular prism at 45°.
module bin_ramp(w, z_floor, lip_h = BIN_LIP_H) {
    rotate([0, 90, 0]) linear_extrude(height = w)
        polygon([[-z_floor, BIN_LIP_T],
                 [-(z_floor + lip_h), BIN_LIP_T],
                 [-z_floor, BIN_LIP_T + lip_h]]);
}

// ─── Label pocket and label plates ───────────────────────────────────────────
// The pocket is two ribs and a shelf standing proud of the drawer front, one
// window per column of compartments — a card or a printed plate slides in from
// above. Measured off the original design; see LABEL_* in params.scad.

// Weights of the columns that meet the front face. Read as columns, that is
// the layout itself; read as bands, it is the columns of the front band.
function front_col_weights(lay, dir) =
    dir == "rows" ? col_rows(lay[0]) : [for (c = lay) col_weight(c)];

// Left and right edge of column i, in drawer coordinates.
function front_col_span(w, i, cw, t) =
    let (space = cw - (len(w) - 1) * t,
         x0 = -cw/2 + offset_of(w, i, space, t))
    [x0, x0 + share(w, i, space)];

// The windows of the pocket as [x0, x1] pairs: the pocket spans the front face
// (minus LABEL_EDGE_INSET), and the ribs sit over the dividers.
function label_windows(lay, dir, cw, fw, div_t) =
    let (w = front_col_weights(lay, dir), n = len(w))
    [for (i = [0 : n - 1])
        [i == 0     ? -fw/2 + LABEL_EDGE_INSET + LABEL_RIB_W
                    : front_col_span(w, i, cw, div_t)[0] - div_t/2 + LABEL_RIB_MID,
         i == n - 1 ?  fw/2 - LABEL_EDGE_INSET - LABEL_RIB_W
                    : front_col_span(w, i, cw, div_t)[1] + div_t/2 - LABEL_RIB_MID]];

// The cards themselves: wider than the windows, so the ribs hold them in.
function label_card_spans(lay, dir, cw, fw, div_t) =
    [for (w = label_windows(lay, dir, cw, fw, div_t))
        [w[0] - LABEL_CARD_OVER, w[1] + LABEL_CARD_OVER]];

// Height of a card: from the shelf it rests on to the top of the ribs.
function label_window_h(fh) = fh - LABEL_TOP_DROP - LABEL_SHELF_SLOT;

module front_label_pocket(lay, dir, cw, fw, fh, div_t) {
    wins = label_windows(lay, dir, cw, fw, div_t);
    L    = -fw/2 + LABEL_EDGE_INSET;
    R    =  fw/2 - LABEL_EDGE_INSET;
    top  = fh - LABEL_TOP_DROP;
    assert(top > LABEL_SHELF_Z1 + 2,
           "label_pocket: the drawer front is too low for a label pocket");

    // The slot layer, right against the front face: a low shelf for the card
    // to stand on, and the walls that separate one card from the next.
    cards = label_card_spans(lay, dir, cw, fw, div_t);
    translate([0, -LABEL_SLOT, 0]) {
        translate([L, 0, LABEL_SHELF_Z0])
            cube([R - L, LABEL_SLOT, LABEL_SHELF_SLOT - LABEL_SHELF_Z0]);
        for (i = [0 : len(cards)]) {
            x0 = i == 0          ? L : cards[i-1][1];
            x1 = i == len(cards) ? R : cards[i][0];
            if (x1 - x0 > EPS)
                translate([x0, 0, LABEL_SHELF_Z0])
                    cube([x1 - x0, LABEL_SLOT, top - LABEL_SHELF_Z0]);
        }
    }

    // The rail layer, LABEL_SLOT in front of the face: shelf, ribs, braces.
    translate([0, -(LABEL_SLOT + LABEL_RAIL_T), 0]) {
        // shelf, right across the pocket
        translate([L, 0, LABEL_SHELF_Z0])
            cube([R - L, LABEL_RAIL_T, LABEL_SHELF_Z1 - LABEL_SHELF_Z0]);

        // ribs: the outer two and one block between each pair of windows
        for (i = [0 : len(wins)]) {
            x0 = i == 0           ? L : wins[i-1][1];
            x1 = i == len(wins)   ? R : wins[i][0];
            translate([x0, 0, LABEL_SHELF_Z0])
                cube([x1 - x0, LABEL_RAIL_T, top - LABEL_SHELF_Z0]);
        }

        // braces in the lower corners of every window
        for (win = wins) {
            label_gusset(win[0],  1);
            label_gusset(win[1], -1);
        }
    }
}

// A 45° brace from the shelf up into a rib, in the plane of the pocket.
module label_gusset(x, s) {
    translate([x, LABEL_RAIL_T, LABEL_SHELF_Z1]) rotate([90, 0, 0])
        linear_extrude(height = LABEL_RAIL_T)
            polygon([[0, 0], [s * LABEL_GUSSET, 0], [0, LABEL_GUSSET]]);
}

// One plate, lying flat with the text facing up — print it as generated.
// `size` 0 sizes the text to the plate; `font` "" uses OpenSCAD's default.
module label_plate(txt, w, h, size = 0, font = "") {
    t    = LABEL_SLOT - LABEL_PLATE_CLEAR;
    base = t - LABEL_TEXT_H;
    pw   = w - 2 * LABEL_PLATE_SIDE;
    ph   = h - 2 * LABEL_PLATE_SIDE;
    assert(pw > 2 && ph > 2, "label_plate: the window is too small for a plate");
    n    = max(len(txt), 1);
    // The notch eats into the top edge, so the text is centred on what is
    // left below it — otherwise it clips the lettering on a short plate.
    r    = min(LABEL_NOTCH_R, ph / 4);
    s    = size > 0 ? size : min((ph - r) * 0.6, pw / n / 0.62);
    difference() {
        union() {
            translate([-pw/2, -ph/2, 0]) cube([pw, ph, base]);
            translate([0, -r/2, base - EPS]) linear_extrude(LABEL_TEXT_H + EPS)
                text(txt, size = s, halign = "center", valign = "center",
                     font = font == "" ? undef : font);
        }
        // finger notch in the top edge, to pull the plate back out
        translate([0, ph/2, -EPS])
            cylinder(r = r, h = t + 2*EPS, $fn = 32);
    }
}

// A row of plates, ready to print in one go. Each plate takes the size of the
// window it belongs to; more texts than windows simply wrap around.
module label_plates(texts, ul = 2, fh = POCKET_H - DRAWER_CLEARANCE_H,
                    layout = undef, layout_dir = "cols", cols = 1, rows = 1,
                    div_t = DRAWER_DIV_T, size = 0, font = "") {
    lay  = layout_or_grid(layout, layout_dir, cols, rows);
    cards = label_card_spans(lay, layout_dir, drawer_inner_w(ul),
                             drawer_front_w(ul), div_t);
    h     = label_window_h(fh);
    for (i = [0 : len(texts) - 1]) {
        win = cards[i % len(cards)];
        w   = win[1] - win[0];
        translate([i * (w + LABEL_PLATE_GAP), 0, 0])
            label_plate(texts[i], w, h, size, font);
    }
}
