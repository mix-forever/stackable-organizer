#!/bin/sh
# Builds the ready-to-print example STLs into stl/.
# These are a representative sample — the library generates any size you set
# in presets.scad.
#
#   sh tools/build_examples.sh
cd "$(dirname "$0")/.." || exit 1
mkdir -p stl
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

build() {   # build <file-name> <scad-call>
    printf 'include <%s/organizer.scad>\n%s\n' "$PWD" "$2" > "$TMP/b.scad"
    openscad -o "stl/$1.stl" "$TMP/b.scad" 2>&1 | grep -E '^(ERROR|WARNING)' && return 1
    printf '  stl/%-38s %6s\n' "$1.stl" "$(du -h "stl/$1.stl" | cut -f1)"
}

echo "building example STLs:"

# Boxes
build box_1x1x1_4slots      'box(1, 1, 1);'
build box_2x2x1_4slots      'box(2, 2, 1);'
build box_2x2x2_4slots      'box(2, 2, 2, 4);'
build box_2x2x2_drawers_and_bin 'box_drawer_bin(2, 2, 2, 1, 2);'

# Drawers (match the slots above)
build drawer_2x2x1_plain            'drawer(2, 2, h = 16.20);'
build drawer_2x2x1_6compartments    'drawer(2, 2, h = 16.20, cols = 3, rows = 2);'
build drawer_2x2x2_3compartments    'drawer(2, 2, h = 34.86, cols = 3);'
build drawer_2x2x2_15compartments   'drawer(2, 2, h = 34.86, cols = 5, rows = 3, div_t = 1.20);'
build drawer_2x2x1_mixed_layout     'drawer(2, 2, h = 16.20, layout = [[1,[1,1]],[2,[1]],[1,[1,2,1]]]);'
build drawer_2x2x1_mixed_bands      'drawer(2, 2, h = 16.20, layout = [[1,[1,1]],[1,[1]],[1,[1,1,1]]], layout_dir = "rows");'
build drawer_2x2x1_label_pocket     'drawer(2, 2, h = 16.20, cols = 3, rows = 2, label_pocket = true);'
build label_plates_2x2x1_3x         'label_plates(["10k", "4k7", "220R"], 2, 16.20, undef, "cols", 3, 2, 1.92);'

# Connector clips
build connector        'connector();'
build connector_loose  'connector(true);'

echo "done."
