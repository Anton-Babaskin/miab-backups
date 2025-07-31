# miab-backups

Simple automated **Restic → rclone/WebDAV** backups **with Telegram alerts**.

---

## ✨ Features
- Encrypted backups of `/home/user-data` with **Restic**
- Upload to any **WebDAV** storage via **rclone**
- **Telegram** notifications (✅ success / ❌ failure)
- One-line dry-run for safe testing
- Designed for cron or systemd-timer

---

## ⚙️ Requirements
| Tool | Tested version |
|------|----------------|
| bash | ≥ 5.x |
| restic | ≥ 0.16 |
| rclone | ≥ 1.65 |
| jq | any |

---

## 🚀 Quick Start

### 1. Clone
```bash
git clone https://github.com/Anton-Babaskin/miab-backups.git
cd miab-backups
2. Create Telegram secrets
bash
Копировать
Редактировать
sudo cp .env.example /etc/miab-notify.env
sudo chmod 600 /etc/miab-notify.env
# edit the file and set BOT_TOKEN / CHAT_ID
3. Make scripts executable
bash
Копировать
Редактировать
chmod +x scripts/*.sh
4. Configure rclone (once)
bash
Копировать
Редактировать
rclone config   # create a remote named   webdavbox
5. Test without uploading
bash
Копировать
Редактировать
bash -x scripts/restic-rclone-backup.sh --dry-run
You should instantly get a ✅ message in Telegram.

📝 Cron example
cron
Копировать
Редактировать
0 4 * * * /root/miab-backups/scripts/restic-rclone-backup.sh \
  >> /var/log/restic-cron.log 2>&1
📰 Script overview
File	Purpose
scripts/telegram_notify.sh	Shared helper; loads BOT_TOKEN / CHAT_ID from /etc/miab-notify.env and exposes send_telegram()
scripts/restic-rclone-backup.sh	Full backup → check → prune → ✅/❌ alert (uses rclone:webdavbox:/backup)
scripts/restic-backup.sh	Same flow but targets a local or other Restic repo

Both backup scripts start with:

bash
Копировать
Редактировать
#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/telegram_notify.sh"
trap 'send_telegram "❌ *Restic Backup Failed* on $(hostname -f) at $(date +%F %T)"; exit 1' ERR
and finish with a formatted success message.

📂 Customisation
Change RESTIC_REPO, RESTIC_PASSWORD, BACKUP_SRC, retention policy and log path inside the script(s).

Add additional alerts anywhere with

bash
Копировать
Редактировать
send_telegram "ℹ️ Custom message"
❓ FAQ
Dry-run uploads data? — No. --dry-run only prints what would be backed up, still triggering alerts.
Where do I put my token? — /etc/miab-notify.env, never inside the repo.
Can I use S3 instead of WebDAV? — Yes, just set RESTIC_REPO="s3:s3remote:bucket/folder" (must exist).
