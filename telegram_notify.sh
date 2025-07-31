#!/usr/bin/env bash
set -euo pipefail

##############################################################################
# Telegram notification helper with logging
# - Reads BOT_TOKEN, CHAT_ID, and optional RESTIC_PASSWORD, LOG_FILE from /etc/miab-notify.env
# - Exports send_telegram() for other scripts
# - Logs to LOG_FILE (default: /var/log/restic.log)
##############################################################################

CONF_FILE=/etc/miab-notify.env
[[ -r "$CONF_FILE" ]] || { echo "Error: Config $CONF_FILE not found" >&2; exit 1; }
# shellcheck disable=SC1090
source "$CONF_FILE"

: "${BOT_TOKEN:?Error: BOT_TOKEN missing in $CONF_FILE}"
: "${CHAT_ID:?Error: CHAT_ID missing in $CONF_FILE}"
: "${RESTIC_PASSWORD:?Error: RESTIC_PASSWORD missing in $CONF_FILE}"
LOG_FILE="${LOG_FILE:-/var/log/restic.log}"  # Default to restic log

command -v jq >/dev/null 2>&1 || { echo "Error: jq is required" >&2; exit 1; }
touch "$LOG_FILE" 2>/dev/null || {
  echo "Error: Cannot write to $LOG_FILE" >&2
  exit 1
}

log() { printf '%s %s\n' "$(date '+%F %T')" "$*" >>"$LOG_FILE"; }

send_telegram() {
  local msg="$1" resp
  log "INFO: Sending Telegram message: ${msg//[$'\n']/ }"
  
  resp=$(
    curl -fsSL --retry 3 --max-time 10 \
      --data-urlencode "chat_id=${CHAT_ID}" \
      --data-urlencode "text=${msg}" \
      "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" 2>&1
  ) || {
    log "ERROR: curl failed: $resp"
    return 1
  }

  if [[ $(jq -r '.ok' <<<"$resp") == "true" ]]; then
    log "OK: Telegram API success"
    return 0
  else
    log "ERROR: Telegram API error: $resp"
    return 1
  fi
}

export -f send_telegram
log "INFO: telegram_notify.sh loaded successfully"
