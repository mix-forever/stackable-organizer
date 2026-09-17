#!/bin/sh
# Sprawdza KAZDY tryb `part` i KAZDY modul w presets.scad:
#   - czy sie kompiluje bez bledow ORAZ bez ostrzezen
#     (brak modulu OpenSCAD raportuje jako WARNING, nie ERROR — dlatego
#      sprawdzanie samego ERROR jest niewystarczajace)
#   - czy daje niepusta bryle
#
# Uzycie:  sh tools/check_presets.sh
cd "$(dirname "$0")/.." || exit 1
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
fail=0

printf '%-44s %-9s %s\n' "tryb / modul" "status" "trojkatow"

for pt in demo box box_bin drawer connector connector_tolerant; do
    out=$(openscad -D "part=\"$pt\"" -o "$TMP/t.stl" presets.scad 2>&1 \
          | grep -E '^(ERROR|WARNING)')
    n=$(grep -c "facet normal" "$TMP/t.stl" 2>/dev/null || echo 0)
    if   [ -n "$out" ];  then st=PROBLEM; fail=1
    elif [ "$n" -lt 4 ]; then st=PUSTY;   fail=1
    else st=OK; fi
    printf '%-44s %-9s %s\n' "part=$pt" "$st" "$n"
    [ -n "$out" ] && echo "$out" | sed 's/^/      /'
done

# Szuflada z wlasnym ukladem komor (drawer_layout jest poza Customizerem).
for lay in '[[1,[1,1]],[2,[1]],[1,[1,2,1]]]:cols' '[2,1,3]:cols' \
           '[[1,[1,1]],[1,[1]],[1,[1,1,1]]]:rows'; do
    dir=${lay##*:}; lay=${lay%:*}
    out=$(openscad -D 'part="drawer"' -D "drawer_layout=$lay" \
          -D "drawer_layout_dir=\"$dir\"" \
          -o "$TMP/t.stl" presets.scad 2>&1 | grep -E '^(ERROR|WARNING)')
    n=$(grep -c "facet normal" "$TMP/t.stl" 2>/dev/null || echo 0)
    if   [ -n "$out" ];  then st=PROBLEM; fail=1
    elif [ "$n" -lt 4 ]; then st=PUSTY;   fail=1
    else st=OK; fi
    printf '%-44s %-9s %s\n' "drawer_layout=$lay ($dir)" "$st" "$n"
    [ -n "$out" ] && echo "$out" | sed 's/^/      /'
done

for m in $(grep "^module " presets.scad | sed 's/module //;s/(.*//'); do
    # include musi wskazywac plik absolutnie — plik tymczasowy jest poza projektem
    echo "include <$PWD/presets.scad> $m();" > "$TMP/m.scad"
    out=$(openscad -D 'part="none"' -o "$TMP/m.stl" "$TMP/m.scad" 2>&1 \
          | grep -E '^(ERROR|WARNING)')
    n=$(grep -c "facet normal" "$TMP/m.stl" 2>/dev/null || echo 0)
    if   [ -n "$out" ];  then st=PROBLEM; fail=1
    elif [ "$n" -lt 4 ]; then st=PUSTY;   fail=1
    else st=OK; fi
    printf '%-44s %-9s %s\n' "$m" "$st" "$n"
    [ -n "$out" ] && echo "$out" | sed 's/^/      /'
done

echo
[ "$fail" -eq 0 ] && echo "wszystko OK" || echo "SA PROBLEMY"
exit $fail
