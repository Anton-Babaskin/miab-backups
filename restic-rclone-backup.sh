#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/telegram_notify.sh"

# Проверка зависимостей
command -v restic >/dev/null || { send_telegram "❌ restic не установлен"; exit 1; }
command -v rclone >/dev/null || { send_telegram "❌ rclone не установлен"; exit 1; }
command -v jq >/dev/null || { send_telegram "❌ jq не установлен"; exit 1; }

# Проверка .env
[ -f /etc/miab-notify.env ] || { send_telegram "❌ /etc/miab-notify.env не найден"; exit 1; }
source /etc/miab-notify.env

# Проверка источника бэкапа
BACKUP_SRC="/home/user-data"
[ -d "$BACKUP_SRC" ] || { send_telegram "❌ Папка $BACKUP_SRC не существует"; exit 1; }

# Проверка логов
LOG_FILE="/var/log/restic.log"
touch "$LOG_FILE" || { send_telegram "❌ Нет доступа к $LOG_FILE"; exit 1; }

# Проверка WebDAV
RESTIC_REPO="rclone:webdavbox:/backup"
rclone lsd webdavbox:/backup >/dev/null 2>&1 || { send_telegram "❌ WebDAV недоступен"; exit 1; }

# Инициализация репозитория, если нужно
restic -r "$RESTIC_REPO" snapshots >/dev/null 2>&1 || restic -r "$RESTIC_REPO" init >> "$LOG_FILE" 2>&1

# Ловушка ошибок
trap 'send_telegram "❌ *Бэкап упал* на $(hostname -f) в $(date +%F %T)"; exit 1' ERR

echo "[$(date +'%F %T')] 🔄 Старт бэкапа" >> "$LOG_FILE"
START_TIME=$(date +%s)

restic -r "$RESTIC_REPO" backup "$BACKUP_SRC" >> "$LOG_FILE" 2>&1
restic -r "$RESTIC_REPO" check >> "$LOG_FILE" 2>&1
restic -r "$RESTIC_REPO" forget --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune >> "$LOG_FILE" 2>&1

END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))
DURATION_FMT=$(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))

echo "[$(date +'%F %T')] ✅ Бэкап завершён за $DURATION_FMT" >> "$LOG_FILE"

send_telegram "✅ *Бэкап завершён*\n\
📦 Хост: \`$(hostname -f)\`\n\
📁 Источник: \`$BACKUP_SRC\`\n\
🗂 Репозиторий: \`$RESTIC_REPO\`\n\
⏱ Время: *$DURATION_FMT*\n\
📅 $(date +'%F %T')"
