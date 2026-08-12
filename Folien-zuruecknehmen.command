#!/usr/bin/env bash
# =====================================================================
#  Folien zurücknehmen – Ecological Economics
#
#  Macht Folien-freigeben.command rückgängig: der Download-Link auf der
#  Sitzungsseite wird wieder durch den Platzhalter ersetzt
#  ("Slides will be made available after the lecture").
#
#  Nützlich, wenn versehentlich die falsche Sitzung freigegeben wurde
#  oder ein Deck nochmal überarbeitet werden soll.
#
#  Das PDF selbst wird NICHT gelöscht – es bleibt in
#  content/material/slides/ liegen, ist aber nicht mehr verlinkt.
#
#  Doppelklick genügt.
# =====================================================================
set -uo pipefail
cd "$(dirname "$0")" || exit 1
export PATH="/usr/local/bin:/opt/homebrew/bin:/Applications/quarto/bin:$HOME/Library/TinyTeX/bin/universal-darwin:$PATH"

trap 'echo; read -n 1 -s -r -p "Zum Schließen eine Taste drücken … "; echo' EXIT

echo "== Folien zurücknehmen =="
echo

MAT="content/material"

# Freigegebene Sitzungen finden (Marker vorhanden, Platzhalter weg).
avail=""
for f in "$MAT"/s_*.qmd; do
  [ -e "$f" ] || continue
  line=$(grep -o '<!--slides:[0-9][0-9a-b]*:[^>]*-->' "$f" 2>/dev/null | head -1)
  [ -n "$line" ] || continue
  grep -q 'slides-pending' "$f" && continue
  id=$(echo "$line" | sed 's/<!--slides:\([^:]*\):.*/\1/')
  avail="$avail $id"
done

if [ -z "${avail// /}" ]; then
  echo "Aktuell ist keine Sitzung freigegeben – es gibt nichts zurückzunehmen."
  exit 0
fi

echo "Aktuell freigegeben:$avail"
printf "Welche Sitzung zurücknehmen? ID eingeben (z. B. 05 oder 07a), oder 'alle': "
read -r WANT
WANT="${WANT:-}"
if [ -z "$WANT" ]; then echo "Keine Eingabe."; exit 1; fi

if [ "$WANT" = "alle" ] || [ "$WANT" = "all" ]; then
  IDS="$avail"
else
  case " $avail " in
    *" $WANT "*) IDS="$WANT" ;;
    *) echo "»$WANT« ist nicht freigegeben. Freigegeben:$avail"; exit 1 ;;
  esac
fi
echo

CHANGED=()
for id in $IDS; do
  page=$(grep -l "<!--slides:${id}:" "$MAT"/s_*.qmd | head -1)
  [ -n "$page" ] || { echo "  Sitzung $id: Seite nicht gefunden."; continue; }

  python3 - "$id" "$page" <<'PY'
import sys, re, os
sid, page = sys.argv[1:3]

src = open(page, encoding="utf-8").read()
pat = re.compile(
    r'(<!--slides:' + re.escape(sid) + r':[^>]+?-->\n).*?(<!--/slides:' + re.escape(sid) + r'-->)',
    re.S)
m = pat.search(src)
if not m:
    print(f"  Sitzung {sid}: Marker nicht gefunden – bitte manuell prüfen.")
    raise SystemExit(1)

placeholder = (
    "::: {.slides-pending}\n"
    "📽️ Slides will be made available after the lecture.\n"
    ":::\n"
)
out = src[:m.start()] + m.group(1) + placeholder + m.group(2) + src[m.end():]
if out == src:
    print(f"  Sitzung {sid}: war schon gesperrt.")
    raise SystemExit(2)

open(page, "w", encoding="utf-8").write(out)
print(f"  Sitzung {sid}: zurückgenommen ({os.path.basename(page)}).")
PY
  rc=$?
  [ "$rc" -eq 0 ] && CHANGED+=("$page")
done

if [ "${#CHANGED[@]}" -eq 0 ]; then
  echo
  echo "Nichts geändert."
  exit 0
fi
echo

echo "→ quarto render …"
for f in "${CHANGED[@]}"; do
  echo "   • $f"
  quarto render "$f" >/dev/null || { echo "Render fehlgeschlagen: $f"; exit 1; }
done
echo
echo "→ quarto publish netlify --no-render …"
quarto publish netlify --no-render --no-prompt || {
  echo "Hochladen fehlgeschlagen. Beim ERSTEN Mal einmalig: quarto publish netlify"; exit 1;
}
echo
echo "Fertig – die Folien sind wieder offline."
