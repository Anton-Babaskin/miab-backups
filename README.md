# miab-backups

Automated **Restic** backups to a WebDAV remote via **rclone**, with **Telegram** notifications and enhanced reliability.

---

## 📦 Prerequisites
- Bash (`#!/usr/bin/env bash`)
- **restic** installed and in `$PATH`
- **rclone** configured with a WebDAV remote (e.g. `webdavbox`)
- **jq** installed for parsing Telegram API responses
- **flock** for preventing concurrent cron runs (usually pre-installed)

---

## ⚙️ Configuration

1. **Create and secure the environment file**
   ~~~bash
   sudo cp .env.example /etc/miab-notify.env
   sudo chmod 600 /etc/miab-notify.env
   ~~~

2. **Edit `/etc/miab-notify.env` with your credentials and settings**
   ~~~bash
   BOT_TOKEN="123456789:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
   CHAT_ID="987654321"
   RESTIC_PASSWORD="your_secure_password_here"
   LOG_FILE="/var/log/restic.log"      # optional (default: /var/log/restic.log)
   ~~~

3. **Make scripts executable**
   ~~~bash
   chmod +x scripts/*.sh
   sudo chmod 700 scripts/*.sh         # restrict access
   ~~~

4. **Ensure the log file is writable**
   ~~~bash
   sudo touch /var/log/restic.log
   sudo chmod 600 /var/log/restic.log
   ~~~

5. **Configure rclone** – create a WebDAV remote (e.g. `webdavbox`) and test it
   ~~~bash
   rclone lsd webdavbox:/backup
   ~~~

---

## 🔔 Telegram Notification Helper

`scripts/telegram_notify.sh` sends notifications to Telegram **and exports `send_telegram`** for use in other scripts.

* Reads `BOT_TOKEN`, `CHAT_ID`, `RESTIC_PASSWORD`, and optional `LOG_FILE` from `/etc/miab-notify.env`
* Escapes special characters for Telegram API compatibility
* Retries on network failures (3 attempts, 10-second timeout)
* Verifies API responses with **jq**
* Logs every attempt/result to `LOG_FILE` (default `/var/log/restic.log`)

---

## 💾 Backup Script

`scripts/restic-rclone-backup.sh` automates backups:

1. Validates dependencies (`restic`, `rclone`, `jq`) and the backup source  
2. Initializes the Restic repository if it doesn’t exist  
3. Backs up **/home/user-data** → `rclone:webdavbox:/backup`  
4. Verifies repository integrity with `restic check`  
5. Prunes old backups (`--keep-daily 7 --keep-weekly 4 --keep-monthly 6`)  
6. Logs all actions to `/var/log/restic.log`  
7. Sends Telegram notifications on **success or failure** (includes duration)

### 🔐 Security Notes
- `RESTIC_PASSWORD` is sourced from `/etc/miab-notify.env` — **never** hard-coded
- Scripts are restricted (`chmod 700`) to prevent unauthorized access
- Telegram credentials & passwords stay in `/etc/miab-notify.env` (ignored by Git)

---

## 🔧 Usage Examples

### Manual test
~~~bash
bash -x scripts/restic-rclone-backup.sh
~~~

### Cron (nightly backup @ 04:00)
~~~bash
0 4 * * * flock -n /tmp/restic-backup.lock /path/to/miab-backups/scripts/restic-rclone-backup.sh >> /var/log/restic.log 2>&1
~~~
> Replace `/path/to/miab-backups` with the actual path.

### Verify backups (monthly)
~~~bash
restic -r rclone:webdavbox:/backup restore latest --target /tmp/restore-test
~~~

---

## 📁 Notes
- Secrets live in `/etc/miab-notify.env` and are excluded by `.gitignore`
- Scripts include validation checks for reliability
- `trap ERR` triggers an immediate Telegram alert on any failure
- `flock` prevents concurrent cron runs, protecting the Restic repo
- Central log: `/var/log/restic.log`
- Consider adding a “heartbeat” cron notification to detect scheduling issues

---

## 🛠️ Troubleshooting

| Issue                       | What to check                                                  |
|-----------------------------|----------------------------------------------------------------|
| Backup fails                | Inspect `/var/log/restic.log`                                  |
| No Telegram notifications   | Verify `BOT_TOKEN`, `CHAT_ID`; confirm `jq` is installed       |
| WebDAV errors               | `rclone lsd webdavbox:/backup` for connectivity/auth problems   |
| Cron not running            | Ensure cron service is active; remove stale lock file if any   |

---

## 🪪 License
MIT — use at your own risk.
