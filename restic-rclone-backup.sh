source "$(dirname "$0")/telegram_notify.sh"

for bin in restic rclone jq; do
  command -v "$bin" >/dev/null || { echo "❌ $bin не установлен"; exit 1; }
done

CONF_FILE=/etc/miab-notify.env
[ -f "$CONF_FILE" ] || { echo "❌ $CONF_FILE не найден"; exit 1; }
source "$CONF_FILE"

LOG_FILE="${LOG_FILE:-/var/log/restic.log}"
touch "$LOG_FILE" || { echo "❌ Нет доступа к $LOG_FILE"; exit 1; }

trap 'send_telegram "❌ *Backup failed* on $(hostname -f) at $(date +%F %T)"; exit 1' ERR

BACKUP_SRC="/home/user-data"
[ -d "$BACKUP_SRC" ] || { send_telegram "❌ Backup source $BACKUP_SRC does not exist"; exit 1; }

RESTIC_REPO="rclone:webdavbox:/backup"
rclone lsd webdavbox:/backup >/dev/null 2>&1 || { send_telegram "❌ WebDAV unavailable"; exit 1; }

restic -r "$RESTIC_REPO" snapshots >/dev/null 2>&1 || restic -r "$RESTIC_REPO" init >> "$LOG_FILE" 2>&1

START_TIME=$(date +%s)
echo "[$(date +'%F %T')] 🔄 Starting backup" >> "$LOG_FILE"

export RESTIC_PASSWORD

restic -r "$RESTIC_REPO" backup "$BACKUP_SRC" >> "$LOG_FILE" 2>&1
restic -r "$RESTIC_REPO" check >> "$LOG_FILE" 2>&1
restic -r "$RESTIC_REPO" forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune >> "$LOG_FILE" 2>&1

END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))
DURATION_FMT=$(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))

echo "[$(date +'%F %T')] ✅ Backup completed in $DURATION_FMT" >> "$LOG_FILE"

send_telegram "✅ *Backup completed*\n\
📦 Host: \`$(hostname -f)\`\n\
📁 Source: \`$BACKUP_SRC\`\n\
🗂 Repository: \`$RESTIC_REPO\`\n\
⏱ Duration: *$DURATION_FMT*\n\
📅 $(date +'%F %T')"
