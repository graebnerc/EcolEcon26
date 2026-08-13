#!/usr/bin/env bash
# =====================================================================
#  Abbildungen bauen – Ecological Economics
#
#  Lädt die Rohdaten neu herunter und baut alle Foliengrafiken für
#  Sitzung 3b ("Working with data") als PDF und PNG neu.
#
#  Ergebnis: analysis/figures/  (PDF = Vektor, für Keynote nehmen)
#  Details:  analysis/README.md
#
#  Optionen im Terminal:
#      ./Abbildungen-bauen.command             # Daten laden + bauen
#      ./Abbildungen-bauen.command --nur-bauen # nur bauen (Daten behalten)
#
#  Doppelklick im Finder genügt.
# =====================================================================
set -uo pipefail
cd "$(dirname "$0")" || exit 1
export PATH="/usr/local/bin:/opt/homebrew/bin:/Applications/quarto/bin:$PATH"

trap 'echo; read -n 1 -s -r -p "Zum Schließen eine Taste drücken … "; echo' EXIT

if ! command -v Rscript >/dev/null 2>&1; then
  echo "Rscript wurde nicht gefunden. Ist R installiert?"
  exit 1
fi

SKIP_DL=0
case "${1:-}" in --nur-bauen|--no-download) SKIP_DL=1 ;; esac

if [ "$SKIP_DL" -eq 0 ]; then
  echo "== 1/2  Rohdaten herunterladen =="
  echo "(braucht Internet; bei fehlender Verbindung mit --nur-bauen starten)"
  echo
  Rscript analysis/01_download.R || { echo; echo "Download fehlgeschlagen."; exit 1; }
  echo
else
  echo "== 1/2  Download übersprungen, vorhandene Daten werden benutzt =="
  if [ ! -d analysis/data-raw ]; then
    echo "Es gibt noch keine Daten in analysis/data-raw/ — bitte einmal ohne --nur-bauen starten."
    exit 1
  fi
  echo
fi

echo "== 2/2  Abbildungen bauen =="
echo
Rscript analysis/02_figures.R || { echo; echo "Bauen fehlgeschlagen."; exit 1; }

echo
echo "Fertig. Die Grafiken liegen in analysis/figures/ (PDF für Keynote)."
open analysis/figures 2>/dev/null || true
