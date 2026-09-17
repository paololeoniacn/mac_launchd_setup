#!/bin/bash
# @desc: brew update && brew upgrade --cask claude-code
set -uo pipefail
BREW=/opt/homebrew/bin/brew
LOG="$HOME/Library/Logs/local.brew.update.log"

"$BREW" update >>"$LOG" 2>&1
if "$BREW" upgrade --cask claude-code >>"$LOG" 2>&1; then
  MSG="claude-code aggiornato all'ultima versione"; SOUND="Glass"
else
  MSG="upgrade claude-code fallito — controlla il log"; SOUND="Basso"
fi
/usr/bin/osascript -e "display notification \"$MSG\" with title \"brew · claude-code\" sound name \"$SOUND\""
