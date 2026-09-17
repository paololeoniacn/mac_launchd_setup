#!/bin/bash
# Rigenera dashboard-data.js dallo stato reale di launchd e apre la dashboard.
# Scansiona TUTTI i ~/Library/LaunchAgents/local.*.plist, ne legge schedule/stato
# e scrive un file JS che dashboard.html carica via <script src> (ok su file://).
set -uo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LA="$HOME/Library/LaunchAgents"
LOGDIR="$HOME/Library/Logs"
OUT="$DIR/dashboard-data.js"
PB=/usr/libexec/PlistBuddy

esc() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

LLIST=$(launchctl list 2>/dev/null)

{
  echo "// generato da refresh-dashboard.sh — $(date '+%Y-%m-%d %H:%M:%S')"
  echo "window.TASKS = ["
  for plist in "$LA"/local.*.plist; do
    [ -e "$plist" ] || continue
    label=$(basename "$plist" .plist)

    # schedule: StartCalendarInterval (hh:mm) oppure StartInterval (secondi)
    hour=$("$PB" -c "Print :StartCalendarInterval:Hour"   "$plist" 2>/dev/null)
    min=$( "$PB" -c "Print :StartCalendarInterval:Minute" "$plist" 2>/dev/null)
    interval=$("$PB" -c "Print :StartInterval"            "$plist" 2>/dev/null)
    if [ -n "$hour" ]; then
      schedule=$(printf 'ogni giorno %02d:%02d' "$hour" "${min:-0}")
    elif [ -n "$interval" ]; then
      schedule="ogni ${interval}s"
    else
      schedule="—"
    fi

    # stato da launchctl list: colonne  PID  ExitCode  Label
    line=$(printf '%s\n' "$LLIST" | awk -v l="$label" '$3==l {print; exit}')
    if [ -z "$line" ]; then
      status="unknown"; exitcode="null"
    else
      pid=$(printf '%s' "$line" | awk '{print $1}')
      ec=$( printf '%s' "$line" | awk '{print $2}')
      exitcode="$ec"
      if   [ "$pid" != "-" ]; then status="ok"
      elif [ "$ec" = "0" ];   then status="ok"
      else                         status="fail"
      fi
    fi

    # ultima esecuzione dal mtime del log; se assente → idle
    log="$LOGDIR/$label.log"
    if [ -f "$log" ]; then
      lastRun=$(stat -f "%Sm" -t "%d/%m %H:%M" "$log")
    else
      lastRun="mai"; [ "$status" = "ok" ] && status="idle"
    fi

    # descrizione: riga "# @desc:" dello script lanciato (i comandi reali);
    # fallback al nome dello script se il marker non c'è
    scriptpath=$("$PB" -c "Print :ProgramArguments:1" "$plist" 2>/dev/null)
    desc=""
    if [ -n "$scriptpath" ] && [ -f "$scriptpath" ]; then
      desc=$(sed -n 's/^# *@desc: *//p' "$scriptpath" | head -1)
    fi
    [ -z "$desc" ] && desc=$(basename "${scriptpath:-$label}")

    echo "  { label: \"$(esc "$label")\", desc: \"$(esc "$desc")\", schedule: \"$(esc "$schedule")\", status: \"$status\", lastRun: \"$(esc "$lastRun")\", exitCode: ${exitcode}, plist: \"$(esc "$(basename "$plist")")\" },"
  done
  echo "];"
} > "$OUT"

echo "scritto $OUT"
open "$DIR/dashboard.html"
