# miab-backups

Automated **Restic** backups to a WebDAV remote via **rclone**, with **Telegram** notifications.

## 📦 Prerequisites
- Bash (`#!/usr/bin/env bash`)
- `restic` installed and in `$PATH`
- `rclone` configured with a WebDAV remote (e.g. `webdavbox`)
- `jq` installed for parsing Telegram API responses
- `flock` for preventing concurrent cron runs (usually pre-installed)

## ⚙️ Configuration

1. **Copy and secure the environment file**

   ~~~bash
   sudo cp .env.example /etc/miab-notify.env
   sudo chmod 600 /etc/miab-notify.env
   ~~~

2. **Edit `/etc/miab-notify.env` with your Telegram bot credentials and Restic password**

   ~~~bash
   BOT_TOKEN="123456789:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
   CHAT_ID="987654321"
   RESTIC_PASSWORD="your_secure_password_here"
   ~~~

3. **Make scripts executable**

   ~~~bash
   chmod +x scripts/*.sh
   sudo chmod 700 scripts/*.sh   # Restrict access
   ~~~

4. **Ensure the log file is writable**

   ~~~bash
   sudo touch /var/log/restic.log
   sudo chmod 600 /var/log/restic.log
   ~~~

5. **Configure rclone**

   Ensure a WebDAV remote (e.g. `webdavbox`) is set up in rclone. Test it:

   ~~~bash
   rclone lsd webdavbox:/backup
   ~~~

---

## 🔔 Telegram Notification Helper
`scripts/telegram_notify.sh` sends notifications to a Telegram chat. It:

- Sources credentials from `/etc/miab-notify.env`.
- Escapes special characters for Telegram API compatibility.
- Retries on network failures (3 attempts, 10-second timeout).
- Verifies API responses using `jq`.

---

## 💾 Backup Script
`scripts/restic-rclone-backup.sh` performs the following:

1. Validates dependencies (`restic`, `rclone`, `jq`), backup source (`/home/user-data`), log file, and WebDAV remote.  
2. Initializes the Restic repository if it doesn't exist.  
3. Backs up `/home/user-data` to `rclone:webdavbox:/backup`.  
4. Verifies repository integrity with `restic check`.  
5. Prunes old backups (`--keep-daily 7 --keep-weekly 4 --keep-monthly 6`).  
6. Logs all actions to `/var/log/restic.log`.  
7. Sends Telegram notifications on success or failure, including backup duration.

### Security Notes
- `RESTIC_PASSWORD` is sourced from `/etc/miab-notify.env`, **not** hard-coded.
- Scripts should be restricted (`chmod 700`) to prevent unauthorized access.
- Telegram credentials are stored securely in `/etc/miab-notify.env`.

---

## 🔧 Usage Examples

### Manual Test

Run with debugging output:

~~~bash
bash -x scripts/restic-rclone-backup.sh
~~~

### Cron Entry for Nightly Backup

Add to crontab (`crontab -e`) to run at **04:00**, using `flock` to prevent concurrent runs:

~~~bash
0 4 * * * flock -n /tmp/restic-backup.lock /path/to/miab-backups/scripts/restic-rclone-backup.sh >> /var/log/restic.log 2>&1
~~~

> Replace `/path/to/miab-backups` with the actual path to the repository.

### Verify Backups

Periodically test restorability (e.g. monthly):

~~~bash
restic -r rclone:webdavbox:/backup restore latest --target /tmp/restore-test
~~~

---

## 📁 Notes
- All sensitive data (Telegram credentials, Restic password) is stored in `/etc/miab-notify.env` and excluded by `.gitignore`.
- Scripts include validation checks to ensure reliability.
- `trap ERR` sends Telegram alerts on any failure.
- `flock` prevents concurrent cron runs, protecting the Restic repository.
- Logs are centralized in `/var/log/restic.log` for easy debugging.
- Consider monitoring cron execution (e.g. via a “heartbeat” notification) to detect scheduling issues.

---

## 🛠️ Troubleshooting
| Issue | What to Check |
|-------|---------------|
| **Backup fails** | Inspect `/var/log/restic.log` for errors. |
| **No Telegram notifications** | Verify `BOT_TOKEN` and `CHAT_ID` in `/etc/miab-notify.env` and ensure `jq` is installed. |
| **WebDAV issues** | Test the remote with `rclone lsd webdavbox:/backup`. |
| **Cron not running** | Confirm the cron daemon is active (`systemctl status cron`) and the lock file isn’t stuck (`rm /tmp/restic-backup.lock`). |

---

## 🪪 License
MIT — use at your own risk.
