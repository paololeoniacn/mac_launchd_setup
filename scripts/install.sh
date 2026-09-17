#!/bin/bash
# Genera il plist di local.brew.update con path assoluti risolti al momento
# dell'installazione (launchd non espande ~) e (ri)carica l'agent.
# Portabile: funziona da qualunque cartella in cui è clonato il repo.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="local.brew.update"
SCRIPT="$REPO/scripts/brew-update.sh"
LOG="$HOME/Library/Logs/$LABEL.log"
ERR="$HOME/Library/Logs/$LABEL.err"
TEMPLATE="$REPO/plists/$LABEL.plist.template"
DEST="$HOME/Library/LaunchAgents/$LABEL.plist"

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
chmod +x "$REPO/scripts/"*.sh

sed -e "s|__SCRIPT__|$SCRIPT|g" \
    -e "s|__LOG__|$LOG|g" \
    -e "s|__ERR__|$ERR|g" \
    "$TEMPLATE" > "$DEST"

launchctl unload "$DEST" 2>/dev/null || true
launchctl load "$DEST"

echo "installato: $DEST"
echo "  script: $SCRIPT"
launchctl list | grep "$LABEL" || true
