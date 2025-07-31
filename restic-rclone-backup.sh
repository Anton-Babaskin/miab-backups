#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/telegram_notify.sh"

# Проверка зависимостей
command -v restic >/dev/null || { send_telegram "❌ Error: restic not installed"; exit 1; }
command -v rclone >/dev/null || { send_telegram "❌ Error: rclone not installed"; exit 1; }

# Проверка источника бэкапа
BACKUP_SRC="/home/user-data"
[ -d "$BACKUP_SRC" ] || { send_telegram "❌ Error: Backup source $BACKUP_SRC does not exist"; exit 1; }

# Проверка WebDAV
RESTIC_REPO="rclone:webdavbox:/backup"
rclone lsd webdavbox:/backup >/dev/null 2>&1 || { send_telegram "❌ Error: WebDAV unavailable"; exit 1; }

# Ловушка ошибок
trap 'send_telegram "❌ *Backup failed* on $(hostname -f) at $(date +%F %T)"; exit 1' ERR

echo "[$(date +'%F %T')] 🔄 Starting backup" >> "$LOG_FILE"
START_TIME=$(date +%s)

# Установка пароля для restic
export RESTIC_PASSWORD

restic -r "$RESTIC_REPO" backup "$BACKUP_SRC" >> "$LOG_FILE" 2>&1
restic -r "$RESTIC_REPO" check >> "$LOG_FILE" 2>&1
restic -r "$RESTIC_REPO" forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune >> "$LOG_FILE" 2>&1

END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))
DURATION_FMT=$(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))

echo "[$(date +'%F %T')] ✅ Backup completed in $DURATION_FMT" >> "$LOG_FILE"

send_telegram "✅ *Backup completed*\n\
📦 Host: \`$HOSTNAME\`\n\
📁 Source: \`$BACKUP_SRC\`\n\
🗂 Repository: \`$RESTIC_REPO\`\n\
⏱ Duration: *$DURATION_FMT*\n\
📅 $(date +'%F %T')"
