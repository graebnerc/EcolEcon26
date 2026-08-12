#!/usr/bin/env bash
# =====================================================================
#  Folien freigeben – Ecological Economics
#
#  Verlinkt für EINE Sitzung die Foliendatei, die erst nach dem Termin
#  sichtbar sein soll.
#
#  Auf jeder Sitzungsseite steht dafür ein Markerblock, z. B.:
#
#      <!--slides:05:EcolEcon26_L05_Trade.pdf-->
#      ::: {.slides-pending}
#      📽️ Slides will be made available after the lecture.
#      :::
#      <!--/slides:05-->
#
#  Der Marker enthält die Sitzungs-ID (05) und den erwarteten Dateinamen.
#  Dieses Skript ersetzt den Inhalt zwischen den Markern durch einen
#  Download-Link, rendert die Seite und lädt sie zu Netlify hoch.
#
#  Voraussetzung: das PDF liegt in content/material/slides/.
#  Rückgängig machen: Folien-zuruecknehmen.command
#
#  Doppelklick genügt.
# =====================================================================
set -uo pipefail
cd "$(dirname "$0")" || exit 1
export PATH="/usr/local/bin:/opt/homebrew/bin:/Applications/quarto/bin:$HOME/Library/TinyTeX/bin/universal-darwin:$PATH"

trap 'echo; read -n 1 -s -r -p "Zum Schließen eine Taste drücken … "; echo' EXIT

echo "== Folien freigeben =="
echo

MAT="content/material"
SLIDEDIR="$MAT/slides"

# Noch gesperrte Sitzungen finden – und prüfen, ob das PDF schon da ist.
avail=""
missing=""
for f in "$MAT"/s_*.qmd; do
  [ -e "$f" ] || continue
  line=$(grep -o '<!--slides:[0-9][0-9a-b]*:[^>]*-->' "$f" 2>/dev/null | head -1)
  [ -n "$line" ] || continue
  # Nur wenn der Platzhalter noch drinsteht, ist die Sitzung gesperrt.
  grep -q 'slides-pending' "$f" || continue
  id=$(echo "$line" | sed 's/<!--slides:\([^:]*\):.*/\1/')
  pdf=$(echo "$line" | sed 's/.*:\(.*\)-->/\1/')
  if [ -f "$SLIDEDIR/$pdf" ]; then
    avail="$avail $id"
  else
    missing="$missing $id"
  fi
done

if [ -n "${missing// /}" ]; then
  echo "Gesperrt, aber PDF fehlt noch in $SLIDEDIR:$missing"
  echo
fi

if [ -z "${avail// /}" ]; then
  echo "Es kann gerade nichts freigeschaltet werden."
  echo "(Entweder ist alles schon freigegeben, oder die PDFs fehlen noch.)"
  exit 0
fi

echo "Freischaltbar (PDF liegt bereit):$avail"
printf "Welche Sitzung freigeben? ID eingeben (z. B. 05 oder 07a), oder 'alle': "
read -r WANT
WANT="${WANT:-}"
if [ -z "$WANT" ]; then echo "Keine Eingabe."; exit 1; fi

if [ "$WANT" = "alle" ] || [ "$WANT" = "all" ]; then
  IDS="$avail"
else
  case " $avail " in
    *" $WANT "*) IDS="$WANT" ;;
    *) echo "»$WANT« ist nicht freischaltbar. Verfügbar:$avail"; exit 1 ;;
  esac
fi
echo

CHANGED=()
for id in $IDS; do
  page=$(grep -l "<!--slides:${id}:" "$MAT"/s_*.qmd | head -1)
  [ -n "$page" ] || { echo "  Sitzung $id: Seite nicht gefunden."; continue; }

  python3 - "$id" "$page" "$SLIDEDIR" <<'PY'
import sys, os, re
sid, page, slidedir = sys.argv[1:4]

src = open(page, encoding="utf-8").read()
pat = re.compile(
    r'(<!--slides:' + re.escape(sid) + r':([^>]+?)-->\n).*?(<!--/slides:' + re.escape(sid) + r'-->)',
    re.S)
m = pat.search(src)
if not m:
    print(f"  Sitzung {sid}: Marker nicht gefunden – bitte manuell prüfen.")
    raise SystemExit(1)

pdf = m.group(2)
if not os.path.exists(os.path.join(slidedir, pdf)):
    print(f"  Sitzung {sid}: {pdf} liegt nicht in {slidedir}.")
    raise SystemExit(1)

link = f"[📽️ Download the slides (PDF)](slides/{pdf})\n"
out = src[:m.start()] + m.group(1) + link + m.group(3) + src[m.end():]
if out == src:
    print(f"  Sitzung {sid}: schon freigegeben.")
    raise SystemExit(2)

open(page, "w", encoding="utf-8").write(out)
print(f"  Sitzung {sid}: Link auf {pdf} gesetzt ({os.path.basename(page)}).")
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

# Rendern und hochladen.
# WICHTIG: `quarto render` nimmt nur EINE Eingabedatei – deshalb einzeln.
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
echo "Fertig – die Folien sind jetzt live."
