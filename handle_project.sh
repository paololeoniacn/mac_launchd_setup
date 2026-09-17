#!/bin/bash
# Entry point centralizzato per gestire gli agent launchd di questo workspace.
# Portabile: usa $HOME e la propria posizione, nessun path hardcoded.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LABEL="local.brew.update"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/$LABEL.log"

usage() {
  cat <<EOF
uso: ./handle_project.sh <comando>

comandi:
  install     genera il plist coi path locali e carica l'agent launchd
  uninstall   scarica e rimuove l'agent
  dashboard   rigenera lo stato live e apre la dashboard nel browser
  status      stato degli agent local.* (launchctl)
  logs        segue il log di $LABEL (tail -f)
  run         esegue subito brew-update (update + upgrade cask + toast)
  help        mostra questo messaggio
EOF
}

cmd="${1:-help}"
case "$cmd" in
  install)
    "$REPO/scripts/install.sh"
    ;;
  uninstall)
    launchctl unload "$PLIST" 2>/dev/null || true
    rm -f "$PLIST"
    echo "rimosso: $PLIST"
    ;;
  dashboard)
    "$REPO/scripts/dashboard/refresh-dashboard.sh"
    ;;
  status)
    launchctl list | grep 'local\.' || echo "nessun agent local.* caricato"
    ;;
  logs)
    tail -n 40 -f "$LOG"
    ;;
  run)
    bash "$REPO/scripts/brew-update.sh"
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    echo "comando sconosciuto: $cmd"
    echo
    usage
    exit 1
    ;;
esac
