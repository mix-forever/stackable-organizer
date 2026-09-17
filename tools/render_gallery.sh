#!/bin/sh
# Renders the images used in README.md into images/.
# Reproducible: delete images/ and run this again.
#
#   sh tools/render_gallery.sh
#
# Note: OpenSCAD needs --viewall --autocenter, otherwise --camera alone
# produces empty frames.
cd "$(dirname "$0")/.." || exit 1
mkdir -p images
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

ISO="60,0,25,0"        # front-right isometric
SIZE="1200,800"

render() {           # render <name> <camera-rot> <size> <scad-body>
    name=$1; rot=$2; size=$3; body=$4
    # OpenSCAD reads six --camera numbers as eye+centre and seven as
    # translation+rotation+distance. We always pass the second form, so the
    # rotation has to be four numbers (rx,ry,rz,dist) — three silently gives
    # a nonsense frame instead of an error.
    case $(echo "$rot" | tr -cd , | wc -c) in
        3) ;;
        *) echo "  $name: camera needs rx,ry,rz,dist — got '$rot'"; return 1 ;;
    esac
    printf 'include <%s/organizer.scad>\n%s\n' "$PWD" "$body" > "$TMP/s.scad"
    # --render forces a full CGAL render; without it OpenSCAD draws the CSG
    # preview and shows subtracted faces in a highlight colour.
    # Monotone paints front and back faces the same, so looking into a cavity
    # does not produce a second colour.
    openscad -o "images/$name.png" --render \
             --camera=0,0,0,"$rot" --viewall --autocenter \
             --imgsize="$size" --colorscheme=Monotone \
             "$TMP/s.scad" 2>&1 | grep -E '^(ERROR|WARNING)' && return 1
    printf '  images/%-22s %s\n' "$name.png" "$(du -h "images/$name.png" | cut -f1)"
}

echo "rendering gallery:"

# 1. Hero — a box full of drawers, one pulled out, clip in front
render hero "$ISO" "1400,900" '
W = 2*UNIT_L;
box(2, 2, 1);
for (i = [0:3])
    translate([W/2, i == 1 ? -55 : 0, WALL_FLOOR + i*(POCKET_H + RAIL_T)])
        drawer(2, 2, h = 16.20, cols = (i == 1) ? 3 : 1, rows = (i == 1) ? 2 : 1);
translate([-40, -70, 1.6]) rotate([0, 0, -20]) connector();'

# 2. Box sizes side by side
render box_sizes "$ISO" "$SIZE" '
box(1, 1, 1);
translate([UNIT_L + 25, 0, 0])       box(2, 2, 1);
translate([UNIT_L + 2*UNIT_L + 50, 0, 0]) box(3, 2, 2);'

# 3. Drawer compartment layouts
render drawer_types "60,0,20,0" "$SIZE" '
d = 2*UNIT_L + 20;
drawer(2, 2, h = 34.66);
translate([d, 0, 0])   drawer(2, 2, h = 34.66, cols = 3);
translate([2*d, 0, 0]) drawer(2, 2, h = 34.66, cols = 3, rows = 2);
translate([3*d, 0, 0]) drawer(2, 2, h = 34.66, cols = 5, rows = 3, div_t = 1.20);'

# 3b. Drawers with compartments that are not a plain grid
render drawer_layouts "60,0,20,0" "$SIZE" '
d = 2*UNIT_L + 20;
drawer(2, 2, h = 34.66, layout = [[1,[1,1]], [2,[1]], [1,[1,2,1]]]);
translate([d, 0, 0])   drawer(2, 2, h = 34.66, layout = [2, 1, 3]);
translate([2*d, 0, 0]) drawer(2, 2, h = 34.66,
                              layout = [[3,[1,1]], [1,[1,1,1,1]]]);
translate([3*d, 0, 0]) drawer(2, 2, h = 34.66, layout_dir = "rows",
                              layout = [[1,[1,1]], [1,[1]], [1,[1,1,1]]]);'

# 3c. The same two layouts as a plan, cut above the floor — the clearest way
# to read the notation. projection() gives a 2D section, so this one is drawn
# from straight above (camera rotation 0,0,0).
render drawer_plans "0,0,0,0" "1200,700" '
projection(cut = true) translate([0, 0, -8]) {
    drawer(2, 2, h = 34.66, layout = [[1,[1,1]], [2,[1]], [1,[1,2,1]]]);
    translate([2*UNIT_L + 30, 0, 0])
        drawer(2, 2, h = 34.66, layout_dir = "rows",
               layout = [[1,[1,1]], [1,[1]], [1,[1,1,1]]]);
}'

# 3d. Label pocket on the drawer front, with plates
render labels "62,0,18,0" "$SIZE" '
lay   = layout_or_grid(undef, "cols", 3, 2);
cards = label_card_spans(lay, "cols", drawer_inner_w(2), drawer_front_w(2),
                         DRAWER_DIV_T);
h     = label_window_h(34.66);
drawer(2, 2, h = 34.66, cols = 3, rows = 2, label_pocket = true);
for (i = [0, 2])
    translate([(cards[i][0]+cards[i][1])/2, 0, LABEL_SHELF_SLOT + h/2])
        rotate([90, 0, 0])
            label_plate(i == 0 ? "10k" : "1M", cards[i][1]-cards[i][0], h);
translate([-24, -62, 0]) label_plate("100k", cards[1][1]-cards[1][0], h);'

# 4. Box with drawers and an open bin
render box_bin "$ISO" "$SIZE" '
box_drawer_bin(2, 2, 2, 1, 2);
translate([UNIT_L, -55, WALL_FLOOR]) drawer(2, 2, h = 34.86, cols = 3, rows = 2);'

# 5. Bin without a roof (shallow box) next to one with a roof
render bin_variants "$ISO" "$SIZE" '
box_drawer_bin(2, 2, 2, 1, 2);
translate([2*UNIT_L + 30, 0, 0]) box_drawer_bin(2, 1, 2, 1, 2);'

# 6. Connector clip, close up
render connector "70,0,35,0" "900,600" '
connector();
translate([14, 0, 0]) connector(true);'

# 7. One drawer slot sliced open: rails and the anti-fallout catches
render box_interior "55,0,25,0" "1000,700" '
intersection() {
    box(2, 2, 1);
    translate([-1, -1, -1])
        cube([2*UNIT_L + 2, 2*UNIT_D + 2, WALL_FLOOR + POCKET_H + RAIL_T + 1]);
}'

# 8. Two boxes joined with connector clips
render stacking "58,0,205,0" "$SIZE" '
box(1, 1, 1);
translate([UNIT_L, 0, 0]) box(1, 1, 1);
// Clips sit in the seam, spanning the slots of both boxes.
// rotate([0,90,0]) maps (x,y,z) -> (z,y,-x): clip thickness lands on X,
// its width on Z, its length stays on Y.
// Shown half-inserted so the clips are visible; in use they slide fully in.
for (z = [DT_POS_FROM_H_EDGE, UNIT_H - DT_POS_FROM_H_EDGE])
    translate([UNIT_L, UNIT_D - 26, z]) rotate([0, 90, 0]) connector();'

echo "done."
