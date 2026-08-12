#!/usr/bin/env bash
# =====================================================================
#  Veröffentlichen – Ecological Economics (Website → Netlify)
#
#  Rendert nur die geänderten Seiten (Quell-.qmd neuer als gebautes HTML)
#  und lädt das Ergebnis mit `quarto publish netlify --no-render` hoch.
#  So wird NICHT jedes Mal die ganze Seite neu gebaut.
#
#  Doppelklick im Finder genügt. Optionen im Terminal:
#      ./Veroeffentlichen.command          # nur Geändertes rendern + hochladen
#      ./Veroeffentlichen.command --voll   # alles neu rendern + hochladen
#      ./Veroeffentlichen.command --test   # nur zeigen, was gerendert würde
#
#  Einmalig vorab nötig (legt Netlify-Site + Token an):
#      quarto publish netlify
# =====================================================================
set -uo pipefail
cd "$(dirname "$0")" || exit 1

# Finder startet mit minimalem PATH – Quarto + TinyTeX ergänzen:
export PATH="/usr/local/bin:/opt/homebrew/bin:/Applications/quarto/bin:$HOME/Library/TinyTeX/bin/universal-darwin:$PATH"

MODE="incremental"
case "${1:-}" in
  --voll|--full) MODE="full" ;;
  --test|--dry-run) MODE="test" ;;
esac

# Liste der öffentlichen Seiten aus dem render:-Block in _quarto.yml lesen.
# Globs (content/material/*.qmd) werden dabei aufgelöst.
# (while-read statt mapfile → läuft auch mit System-Bash 3.2 bei Doppelklick)
shopt -s nullglob
TARGETS=()
while IFS= read -r pat; do
  [ -n "$pat" ] || continue
  case "$pat" in
    *'*'*) for f in $pat; do [ -f "$f" ] && TARGETS+=("$f"); done ;;
    *)     [ -f "$pat" ] && TARGETS+=("$pat") ;;
  esac
done < <(awk '
  /^  render:/{f=1; next}
  f && /^  [a-zA-Z_-]+:/{f=0}
  f && /- *"/{ gsub(/.*- *"|".*/, ""); print }
' _quarto.yml)

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "Fehler: keine render:-Liste in _quarto.yml gefunden."; read -n 1 -s -r -p "Taste …"; echo; exit 1
fi

# Theme, Literaturliste oder PDF-Header geändert? -> betrifft ALLE Seiten -> Vollrender.
NEED_FULL=0
for cfg in assets/styles/custom.scss assets/euf-pdf.tex references/references.bib; do
  [ -e "$cfg" ] && [ "$cfg" -nt "_site/index.html" ] && NEED_FULL=1
done

# Zu rendernde Dateien bestimmen
TO_RENDER=()
if [ "$MODE" = "full" ]; then
  TO_RENDER=("${TARGETS[@]}")
  echo "Modus: VOLL – alle ${#TARGETS[@]} Seiten werden neu gebaut."
elif [ "$NEED_FULL" -eq 1 ]; then
  TO_RENDER=("${TARGETS[@]}")
  echo "Theme oder Literaturliste geändert → alle Seiten werden neu gebaut."
else
  for t in "${TARGETS[@]}"; do
    out="_site/${t%.qmd}.html"
    if [ ! -f "$out" ] || [ "$t" -nt "$out" ]; then TO_RENDER+=("$t"); fi
  done
fi

echo
if [ "${#TO_RENDER[@]}" -eq 0 ]; then
  echo "Keine geänderten Seiten gefunden."
  echo "→ Es wird trotzdem der aktuelle Stand hochgeladen."
else
  echo "Wird gerendert (${#TO_RENDER[@]}):"
  printf '  • %s\n' "${TO_RENDER[@]}"
fi
echo

if [ "$MODE" = "test" ]; then
  echo "(Testlauf – es wird nichts gebaut oder hochgeladen.)"
  read -n 1 -s -r -p "Zum Schließen eine Taste drücken … "; echo; exit 0
fi

# 1) Rendern
if [ "${#TO_RENDER[@]}" -gt 0 ]; then
  # WICHTIG: `quarto render` nimmt nur EINE Eingabedatei. Mehrere Dateien in
  # einem Aufruf werden an pandoc durchgereicht und schlagen fehl.
  echo "→ quarto render …"
  for f in "${TO_RENDER[@]}"; do
    echo "   • $f"
    quarto render "$f" >/dev/null || {
      echo "Render fehlgeschlagen: $f"; read -n 1 -s -r -p "Taste …"; echo; exit 1; }
  done
  echo
fi

# 2) Hochladen (ohne erneutes Rendern)
echo "→ quarto publish netlify --no-render …"
quarto publish netlify --no-render --no-prompt || {
  echo
  echo "Hochladen fehlgeschlagen. Beim ERSTEN Mal einmalig einrichten mit:"
  echo "    quarto publish netlify"
  read -n 1 -s -r -p "Taste …"; echo; exit 1
}

echo
echo "Fertig – Website aktualisiert."
read -n 1 -s -r -p "Zum Schließen eine Taste drücken … "
echo
