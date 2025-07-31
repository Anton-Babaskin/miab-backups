miab-backups
Automated Restic backups to a WebDAV remote via rclone, with Telegram notifications.
📦 Prerequisites

Bash (#!/usr/bin/env bash)
restic installed and in $PATH
rclone configured with a WebDAV remote (e.g., webdavbox)
jq installed for parsing Telegram API responses
flock for preventing concurrent cron runs (usually pre-installed)

⚙️ Configuration

Copy and secure the environment file:
sudo cp .env.example /etc/miab-notify.env
sudo chmod 600 /etc/miab-notify.env


Edit /etc/miab-notify.env with your Telegram bot credentials and Restic password:
BOT_TOKEN="123456789:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
CHAT_ID="987654321"
RESTIC_PASSWORD="your_secure_password_here"


Make scripts executable:
chmod +x scripts/*.sh
sudo chmod 700 scripts/*.sh  # Restrict access


Ensure log file is writable:
sudo touch /var/log/restic.log
sudo chmod 600 /var/log/restic.log


Configure rclone:
Ensure a WebDAV remote (e.g., webdavbox) is set up in rclone. Test it:
rclone lsd webdavbox:/backup



🔔 Telegram Notification Helper
scripts/telegram_notify.sh sends notifications to a Telegram chat. It:

Sources credentials from /etc/miab-notify.env.
Escapes special characters for Telegram API compatibility.
Retries on network failures (3 attempts, 10-second timeout).
Verifies API responses using jq.

💾 Backup Script
scripts/restic-rclone-backup.sh performs the following:

Validates dependencies (restic, rclone, jq), backup source (/home/user-data), log file, and WebDAV remote.
Initializes the Restic repository if it doesn't exist.
Backs up /home/user-data to rclone:webdavbox:/backup.
Verifies repository integrity with restic check.
Prunes old backups (--keep-daily 7 --keep-weekly 4 --keep-monthly 6).
Logs all actions to /var/log/restic.log.
Sends Telegram notifications on success or failure, including backup duration.

Security Notes

RESTIC_PASSWORD is sourced from /etc/miab-notify.env, not hard-coded.
Scripts should be restricted (chmod 700) to prevent unauthorized access.
Telegram credentials are stored securely in /etc/miab-notify.env.

🔧 Usage Examples
Manual Test
Run with debugging output:
bash -x scripts/restic-rclone-backup.sh

Cron Entry for Nightly Backup
Add to crontab (crontab -e) to run at 4 AM, using flock to prevent concurrent runs:
0 4 * * * flock -n /tmp/restic-backup.lock /path/to/miab-backups/scripts/restic-rclone-backup.sh >> /var/log/restic.log 2>&1

Replace /path/to/miab-backups with the actual path
