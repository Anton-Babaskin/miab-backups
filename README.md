# miab-backups

Automated Restic backups to a WebDAV remote via rclone, with Telegram notifications and enhanced reliability.

## 📦 Prerequisites

- Bash (`#!/usr/bin/env bash`)
- `restic` installed and in `$PATH`
- `rclone` configured with a WebDAV remote (e.g., `webdavbox`)
- `jq` installed for parsing Telegram API responses
- `flock` for preventing concurrent cron runs (usually pre-installed)

## ⚙️ Configuration

1. **Create and secure the environment file**
   ```bash
   sudo cp .env.example /etc/miab-notify.env
   sudo chmod 600 /etc/miab-notify.env
   ```

2. **Edit `/etc/miab-notify.env`**
   ```bash
   BOT_TOKEN="123456789:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
   CHAT_ID="987654321"
   RESTIC_PASSWORD="your_secure_password_here"
   LOG_FILE="/var/log/restic.log"  # Optional, defaults to /var/log/restic.log
   ```

3. **Make scripts executable**
   ```bash
   chmod +x scripts/*.sh
   sudo chmod 700 scripts/*.sh
   ```

4. **Ensure log file is writable**
   ```bash
   sudo touch /var/log/restic.log
   sudo chmod 600 /var/log/restic.log
   ```

5. **Configure rclone**
   Ensure a WebDAV remote (e.g., `webdavbox`) is set up in rclone. Test it:
   ```bash
   rclone lsd webdavbox:/backup
   ```

## 🔔 Telegram Notification Helper

`scripts/telegram_notify.sh` handles Telegram notifications:

- Loads `BOT_TOKEN`, `CHAT_ID`, `RESTIC_PASSWORD`, and optional `LOG_FILE` from `/etc/miab-notify.env`
- Escapes special characters for Telegram API compatibility
- Retries on network failures (3 attempts, 10-second timeout)
- Verifies API responses with `jq`
- Logs all attempts and results to `LOG_FILE` (default: `/var/log/restic.log`)
- Exports `send_telegram` function for use in other scripts

## 💾 Backup Script

`scripts/restic-rclone-backup.sh` automates backups with the following features:

- Validates dependencies (`restic`, `rclone`, `jq`) and backup source
- Initializes the Restic repository if it do
