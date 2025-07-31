# miab-backups

Automated Restic + rclone/WebDAV backups with Telegram notifications.

---

## 📦 Prerequisites

- **Bash** (`#!/usr/bin/env bash`)  
- **restic** installed and in `$PATH`  
- **rclone** configured with a WebDAV remote (e.g. `webdavbox`)  
- **jq** (for checking Telegram API responses)

---

## ⚙️ Configuration

1. Copy the example environment file and secure it:

```bash
sudo cp .env.example /etc/miab-notify.env
sudo chmod 600 /etc/miab-notify.env
```

2. Edit `/etc/miab-notify.env` and fill in your Telegram bot credentials:

```ini
BOT_TOKEN="123456789:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
CHAT_ID="987654321"
```

3. Make scripts executable:

```bash
chmod +x scripts/*.sh
```

---

## 🔔 Telegram Notification Helper

**scripts/telegram_notify.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
source /etc/miab-notify.env

send_telegram() {
  local msg enc
  msg="$1"
  enc=$(printf '%s' "$msg" \
    | sed -e 's/%/%25/g' -e 's/&/%26/g' -e 's/#/%23/g')
  curl -fsSL --retry 3 --max-time 10 \
       -d "chat_id=$CHAT_ID&text=$enc" \
       "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
    | jq -e '.ok' >/dev/null
}
```

---

## 💾 Backup Script

**scripts/restic-rclone-backup.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/telegram_notify.sh"

# on any error → send ❌ and exit
trap 'send_telegram "❌ *Restic Backup Failed* on $(hostname -f) at $(date +%F %T)"; exit 1' ERR

export RESTIC_PASSWORD="cvZ7zJHHigkL7Rcw"
export RESTIC_REPO="rclone:webdavbox:/backup"
BACKUP_SRC="/home/user-data"
LOG_FILE="/var/log/restic.log"

echo "[$(date +'%F %T')] 🔄 Starting Restic backup" >> "$LOG_FILE"
START_TIME=$(date +%s)

restic -r "$RESTIC_REPO" backup "$BACKUP_SRC" >> "$LOG_FILE" 2>&1
restic -r "$RESTIC_REPO" check                        >> "$LOG_FILE" 2>&1
restic -r "$RESTIC_REPO" forget --keep-daily 7 \
  --keep-weekly 4 --keep-monthly 6 --prune           >> "$LOG_FILE" 2>&1

END_TIME=$(date +%s)
DURATION=$(( END_TIME - START_TIME ))
DURATION_FMT=$(printf '%02d:%02d:%02d' $((DURATION/3600)) $((DURATION%3600/60)) $((DURATION%60)))

echo "[$(date +'%F %T')] ✅ Restic backup completed in $DURATION_FMT" >> "$LOG_FILE"

send_telegram "✅ *Restic Backup Completed*\n\
📦 Host: \`$(hostname -f)\`\n\
📁 Source: \`$BACKUP_SRC\`\n\
🗂 Repository: \`$RESTIC_REPO\`\n\
⏱ Duration: *$DURATION_FMT*\n\
📅 $(date +'%F %T')"
```

---

## 🔧 Usage Examples

### Manual test

```bash
bash -x scripts/restic-rclone-backup.sh
```

### Cron entry for nightly backup

```cron
0 4 * * * /root/miab-backups/scripts/restic-rclone-backup.sh >> /var/log/restic-cron.log 2>&1
```

---

## 📁 Notes

- All Telegram credentials live in `/etc/miab-notify.env` and are excluded by `.gitignore`
- Scripts never hard-code tokens or chat IDs
- `trap ERR` ensures alerts on any failure
- Central `telegram_notify.sh` makes reuse trivial

---

## 🪪 License

MIT — use at your own risk.
