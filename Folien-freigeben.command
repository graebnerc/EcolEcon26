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
#  Dieses Skript ersetzt den Inhalt zwischen den Markern und lädt die Seite
#  anschließend zu Netlify hoch.
#
#  WAS EINGESETZT WIRD, HÄNGT AN DER DATEIENDUNG IM MARKER:
#
#    *.pdf   – ein Download-Link. Für die aus Keynote exportierten Decks.
#
#    *.html  – der revealjs-Foliensatz wird direkt in die Seite eingebettet
#              (16:9-iframe), dazu ein Knopf "in eigenem Tab öffnen" und ein
#              Hinweis, wie man sich daraus selbst ein PDF druckt.
#              Voraussetzung: content/material/slides/*.qmd steht in der
#              render-Liste in _quarto.yml, sonst liegt das Deck nicht in
#              _site und der iframe zeigt ins Leere.
#
#  Voraussetzung: die Datei liegt in content/material/slides/.
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
  deck=$(echo "$line" | sed 's/.*:\(.*\)-->/\1/')
  # Bei einem revealjs-Deck muss die QUELLE dort liegen: das fertige HTML baut
  # quarto beim Rendern nach _site, nicht neben die .qmd.
  case "$deck" in
    *.html) need="${deck%.html}.qmd" ;;
    *)      need="$deck" ;;
  esac
  if [ -f "$SLIDEDIR/$need" ]; then
    avail="$avail $id"
  else
    missing="$missing $id"
  fi
done

if [ -n "${missing// /}" ]; then
  echo "Gesperrt, aber die Foliendatei fehlt noch in $SLIDEDIR:$missing"
  echo
fi

if [ -z "${avail// /}" ]; then
  echo "Es kann gerade nichts freigeschaltet werden."
  echo "(Entweder ist alles schon freigegeben, oder die Dateien fehlen noch.)"
  exit 0
fi

echo "Freischaltbar (Foliendatei liegt bereit):$avail"
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

deck = m.group(2)
# Beim revealjs-Deck ist die .qmd die Datei, die vorliegen muss - das HTML
# entsteht erst beim Rendern und landet in _site.
need = os.path.splitext(deck)[0] + ".qmd" if deck.lower().endswith(".html") else deck
if not os.path.exists(os.path.join(slidedir, need)):
    print(f"  Sitzung {sid}: {need} liegt nicht in {slidedir}.")
    raise SystemExit(1)

if deck.lower().endswith(".html"):
    # revealjs-Deck: direkt einbetten. padding-top 56.25% haelt den Kasten auf
    # 16:9, damit der iframe nicht an der Fensterhoehe haengt.
    # Der Menue-Knopf sitzt in diesem Theme OBEN rechts (siehe
    # content/material/slides/euf-slides.scss) - der Hinweistext muss dazu
    # passen, sonst suchen die Studierenden in der falschen Ecke.
    body = (
        "```{=html}\n"
        '<div class="container" style="position: relative;overflow: hidden;'
        'width: 100%;padding-top: 56.25%;">\n'
        f'<iframe src="slides/{deck}" style="position: absolute;top: 0;left: 0;'
        'bottom: 0;right: 0;width: 100%;height: 100%;" allowfullscreen '
        'loading="lazy"></iframe>\n'
        "</div>\n"
        "```\n"
        "\n"
        f"[📽️ Open the slides in a separate tab](slides/{deck})"
        '{.btn .btn-primary target="_blank"}\n'
        "\n"
        "::: {.callout-tip}\n"
        "## Would you rather have a PDF?\n"
        "Open the slides, click the ☰ button in the upper right corner, and choose\n"
        "**Tools → PDF Export Mode**. Then print the page "
        "(<kbd>Cmd</kbd>/<kbd>Ctrl</kbd> + <kbd>P</kbd>)\n"
        "and save it as a PDF.\n"
        ":::\n"
    )
else:
    body = f"[📽️ Download the slides (PDF)](slides/{deck})\n"

out = src[:m.start()] + m.group(1) + body + m.group(3) + src[m.end():]
if out == src:
    print(f"  Sitzung {sid}: schon freigegeben.")
    raise SystemExit(2)

open(page, "w", encoding="utf-8").write(out)
kind = "eingebettet" if deck.lower().endswith(".html") else "verlinkt"
print(f"  Sitzung {sid}: {deck} {kind} ({os.path.basename(page)}).")
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

# Falls seit dem letzten Build die Konfiguration (Sidebar/Navigation), das Theme
# oder die Literaturliste geaendert wurde, betrifft das ALLE Seiten. Dann reicht
# es nicht, nur die freigegebene Seite zu rendern – sonst wird ein halb
# veralteter Stand hochgeladen.
for cfg in _quarto.yml assets/styles/custom.scss assets/euf-pdf.tex references/references.bib; do
  if [ -e "$cfg" ] && [ "$cfg" -nt "_site/index.html" ]; then
    echo "Konfiguration/Theme geaendert ($cfg) → alle Seiten werden neu gebaut."
    echo
    shopt -s nullglob
    while IFS= read -r pat; do
      [ -n "$pat" ] || continue
      case "$pat" in
        *'*'*) for g in $pat; do
                 [ -f "$g" ] || continue
                 dup=0
                 for c in "${CHANGED[@]}"; do [ "$c" = "$g" ] && dup=1 && break; done
                 [ "$dup" -eq 0 ] && CHANGED+=("$g")
               done ;;
        *)     if [ -f "$pat" ]; then
                 dup=0
                 for c in "${CHANGED[@]}"; do [ "$c" = "$pat" ] && dup=1 && break; done
                 [ "$dup" -eq 0 ] && CHANGED+=("$pat")
               fi ;;
      esac
    done < <(awk '
      /^  render:/{f=1; next}
      f && /^  [a-zA-Z_-]+:/{f=0}
      f && /- *"/{ gsub(/.*- *"|".*/, ""); print }
    ' _quarto.yml)
    break
  fi
done

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
