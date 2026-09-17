#!/bin/sh
# Checks that a drawer PHYSICALLY goes into a box, which no comparison of
# volumes or bounding boxes can tell you. Every case is an intersection of two
# solids: empty means the parts clear each other.
#
#   A. closed position — a drawer sitting in its slot against the whole box
#   B. the way in — the anti-fallout catch swept along the depth against the
#      drawer, skipping the area of the drawer's BACK WALL, which the catch is
#      meant to hit: that is what stops the drawer falling out
#   C. a label plate in its pocket, with three deliberately wrong plates that
#      MUST collide — otherwise the case would pass no matter what
#
# Usage (from the openscad/ directory):  sh tools/check_fit.sh
cd "$(dirname "$0")/.." || exit 1
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fail=0

vol() {
    [ -f "$1" ] || { echo "0"; return; }
    python3 - "$1" <<'PY'
import sys,struct
f=open(sys.argv[1],'rb'); h=f.read(5); f.seek(0); t=[]
if h==b'solid':
    c=[]
    for l in f:
        s=l.split()
        if s and s[0]==b'vertex':
            c.append(tuple(float(v) for v in s[1:4]))
            if len(c)==3: t.append(c); c=[]
if not t:
    f.seek(80); n=struct.unpack('<I',f.read(4))[0]
    for _ in range(n):
        d=struct.unpack('<12fH',f.read(50)); t.append([tuple(d[3:6]),tuple(d[6:9]),tuple(d[9:12])])
v=sum((a[0]*(b[1]*d[2]-b[2]*d[1])-a[1]*(b[0]*d[2]-b[2]*d[0])+a[2]*(b[0]*d[1]-b[1]*d[0]))/6 for a,b,d in t)
print('%.1f' % abs(v))
PY
}

# Volume, not the presence of a file: CGAL leaves zero-volume slivers where two
# surfaces touch, and those are not collisions.
check() {   # check <description> <scad>
    printf '%-54s' "$1"
    printf 'include <%s/organizer.scad>\n%s\n' "$PWD" "$2" > "$TMP/t.scad"
    rm -f "$TMP/o.stl"
    openscad -o "$TMP/o.stl" "$TMP/t.scad" 2>&1 | grep -E '^ERROR' && { fail=1; return; }
    v=$(vol "$TMP/o.stl")
    if [ "$v" = "0" ] || [ "$v" = "0.0" ]; then echo "OK (clear)"
    else echo "COLLISION $v mm3"; fail=1; fi
}

SWEEP='
W = ul*UNIT_L; bl = ud*UNIT_D - DRAWER_BACK_INSET;
module swept_catch(slot_top) {
    for (m = [0, 1])
        translate([m ? W - WALL_SIDE - RAIL_STOP_INSET - RAIL_STOP_W
                     : WALL_SIDE + RAIL_STOP_INSET,
                   WALL_FRONT + RAIL_STOP_GAP,
                   slot_top - RAIL_STOP_DROP])
            cube([RAIL_STOP_W,
                  bl - DRAWER_WALL - WALL_FRONT - RAIL_STOP_GAP,
                  RAIL_STOP_DROP]);
}'

echo "A. closed position"
for r in 1 2 3; do
    check "  2x2x1, 4 slots, ${r} rows of compartments" "
ul = 2; ud = 2;
intersection() {
    box(2, 2, 1);
    translate([2*UNIT_L/2, 0, WALL_FLOOR])
        drawer(2, 2, h = drawer_height_of(1, 4), cols = 3, rows = $r);
}"
done

# Every slot above the lowest one: the rail has an R1.5 fillet where it meets
# the side wall, and the chamfer under the drawer (0.50 x 1.50) rests on it —
# 0.15 to 0.19 mm of overlap in the exact position. The drawer really does sit
# that bit higher, so the case lifts it 0.20 (0.10 of clearance is left above).
for i in 1 4; do
    check "  2x2x2, 5 slots, slot $i (+0.20), 2 rows" "
ph = pocket_height_of(2, 5);
intersection() {
    box(2, 2, 2, 5);
    translate([2*UNIT_L/2, 0, WALL_FLOOR + $i*(ph + RAIL_T) + 0.20])
        drawer(2, 2, h = drawer_height_of(2, 5), cols = 3, rows = 2);
}"
done

# Slots of different heights: [1,1,2] in a 2x2x2 box.
for i in 0 2; do
    check "  2x2x2, slots [1,1,2], slot $i (+0.20)" "
hs = box_slot_heights(2, [1,1,2]);
dh = drawer_heights_of(2, [1,1,2]);
intersection() {
    box(2, 2, 2, [1,1,2]);
    translate([2*UNIT_L/2, 0, slot_bottom(hs, $i) + 0.20])
        drawer(2, 2, h = dh[$i], cols = 3, rows = 2);
}"
done

echo "B. the way in, under the catches"
for r in 1 2 3; do
    check "  2x2x1, 4 slots, ${r} rows of compartments" "
ul = 2; ud = 2;
$SWEEP
intersection() {
    swept_catch(WALL_FLOOR + POCKET_H);
    translate([2*UNIT_L/2, 0, WALL_FLOOR])
        drawer(2, 2, h = drawer_height_of(1, 4), cols = 3, rows = $r);
}"
done
for r in 2 3; do
    check "  3x2x2, 4 slots, ${r} rows, 1.20 dividers" "
ul = 3; ud = 2;
$SWEEP
intersection() {
    swept_catch(WALL_FLOOR + pocket_height_of(2, 4));
    translate([3*UNIT_L/2, 0, WALL_FLOOR])
        drawer(3, 2, h = drawer_height_of(2, 4), cols = 5, rows = $r, div_t = 1.20);
}"
done
check "  2x2x1, layout [[1,[1,1]],[2,[1]],[1,[1,2,1]]]" "
ul = 2; ud = 2;
$SWEEP
intersection() {
    swept_catch(WALL_FLOOR + POCKET_H);
    translate([2*UNIT_L/2, 0, WALL_FLOOR])
        drawer(2, 2, h = drawer_height_of(1, 4),
               layout = [[1,[1,1]], [2,[1]], [1,[1,2,1]]]);
}"
check "  2x2x1, bands [[1,[1,1]],[1,[1]],[1,[1,1,1]]]" "
ul = 2; ud = 2;
$SWEEP
intersection() {
    swept_catch(WALL_FLOOR + POCKET_H);
    translate([2*UNIT_L/2, 0, WALL_FLOOR])
        drawer(2, 2, h = drawer_height_of(1, 4),
               layout = [[1,[1,1]], [1,[1]], [1,[1,1,1]]],
               layout_dir = \"rows\");
}"
for i in 1 4; do
    check "  2x2x2, 5 slots, slot $i, 3 rows" "
ul = 2; ud = 2;
$SWEEP
ph = pocket_height_of(2, 5);
intersection() {
    swept_catch(WALL_FLOOR + $i*(ph + RAIL_T) + ph);
    translate([2*UNIT_L/2, 0, WALL_FLOOR + $i*(ph + RAIL_T)])
        drawer(2, 2, h = drawer_height_of(2, 5), cols = 3, rows = 3);
}"
done
for i in 0 2; do
    check "  2x2x2, slots [1,1,2], slot $i, 3 rows" "
ul = 2; ud = 2;
$SWEEP
hs = box_slot_heights(2, [1,1,2]);
dh = drawer_heights_of(2, [1,1,2]);
intersection() {
    swept_catch($i < 2 ? slot_bottom(hs, $i) + hs[$i] : 2*UNIT_H - WALL_TOP);
    translate([2*UNIT_L/2, 0, slot_bottom(hs, $i)])
        drawer(2, 2, h = dh[$i], cols = 3, rows = 3);
}"
done

echo "C. a label plate in its pocket"
PLATE='
lay = layout_or_grid(undef, "cols", 3, 2);
cards = label_card_spans(lay, "cols", drawer_inner_w(2), drawer_front_w(2), DRAWER_DIV_T);
hh = label_window_h(34.66);
module in_pocket(dy, sx, sz) {
    for (cd = cards)
        translate([(cd[0]+cd[1])/2, dy, LABEL_SHELF_SLOT + hh/2])
            scale([sx, 1, sz]) rotate([90, 0, 0])
                label_plate("10k", cd[1]-cd[0], hh);
}
module pocket_drawer() { drawer(2, 2, h = 34.66, cols = 3, rows = 2, label_pocket = true); }'

check "  plate in the pocket" "
$PLATE
intersection() { pocket_drawer(); in_pocket(0, 1, 1); }"

# These MUST collide. A case that passes whatever the geometry is tests nothing.
for c in "0,1.05,1:5% too wide" "0,1,1.5:50% too thick" "-0.5,1,1:pushed forward"; do
    args=${c%:*}; name=${c#*:}
    dy=$(echo "$args" | cut -d, -f1); sx=$(echo "$args" | cut -d, -f2)
    sz=$(echo "$args" | cut -d, -f3)
    printf '%-54s' "  control: $name has to collide"
    printf 'include <%s/organizer.scad>\n%s\nintersection() { pocket_drawer(); in_pocket(%s, %s, %s); }\n' \
        "$PWD" "$PLATE" "$dy" "$sx" "$sz" > "$TMP/n.scad"
    rm -f "$TMP/o.stl"
    openscad -o "$TMP/o.stl" "$TMP/n.scad" 2>&1 | grep -E '^ERROR' && { fail=1; continue; }
    v=$(vol "$TMP/o.stl")
    case "$v" in 0|0.0) echo "THIS CASE TESTS NOTHING"; fail=1 ;; *) echo "OK (collides, $v mm3)" ;; esac
done

echo
[ "$fail" -eq 0 ] && echo "all clear" || echo "THERE ARE COLLISIONS"
exit $fail
