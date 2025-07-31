# miab-backups

Automated **Restic** backups to a WebDAV remote via **rclone**, with optional **Telegram** notifications.

## 📦 Prerequisites
- Bash (`#!/usr/bin/env bash`)
- **restic** installed and in `$PATH`
- **rclone** configured with a WebDAV remote (e.g. `webdavbox`)
- **jq** for parsing Telegram API responses
- **flock** to prevent concurrent cron runs (usually pre-installed)

## ⚙️ Configuration
1. **Copy and secure the environment file**

       sudo cp .env.example /etc/miab-notify.env
       sudo chmod 600 /etc/miab-notify.env

2. **Edit `/etc/miab-notify.env`**

       BOT_TOKEN="123456789:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
       CHAT_ID="987654321"
       RESTIC_PASSWORD="your_secure_password_here"

3. **Make scripts executable**

       chmod +x scripts/*.sh
       sudo chmod 700 scripts/*.sh   # Restrict access

4. **Ensure the log file is writable**

       sudo touch /var/log/restic.log
       sudo chmod 600 /var/log/restic.log

5. **Configure rclone**

       # The WebDAV remote must exist in your rclone config
       rclone lsd webdavbox:/backup

---

## 🔔 Telegram Notification Helper
`scripts/telegram_notify.sh`  
- Reads credentials from `/etc/miab-notify.env`  
- Escapes special characters for the Telegram API  
- Retries on network errors (3 attempts, 10-second timeout)  
- Verifies API responses with `jq`  

---

## 💾 Backup Script
`scripts/restic-rclone-backup.sh` performs:  
1. Dependency checks (`restic`, `rclone`, `jq`) and environment validation  
2. Repository initialization on first run (`restic init`)  
3. Backup of `/home/user-data` to `webdavbox:/backup`  
4. Integrity verification with `restic check`  
5. Pruning of old snapshots (`--keep-daily 7 --keep-weekly 4 --keep-monthly 6`)  
6. Logging to `/var/log/restic.log`  
7. Telegram notifications on success or failure, including runtime duration  

### 🔐 Security Notes
- `RESTIC_PASSWORD` is sourced exclusively from `/etc/miab-notify.env`  
- Scripts are restricted to the owner (`chmod 700`)  
- Telegram credentials remain protected in `/etc/miab-notify.env`  

---

## 🔧 Usage Example (cron)
Daily backup at **03:30**:

