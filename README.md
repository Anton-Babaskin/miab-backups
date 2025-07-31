markdown# miab-backups

Automated Restic backups to a WebDAV remote via rclone, with Telegram notifications and enhanced reliability.

## 📦 Prerequisites

- Bash (`#!/usr/bin/env bash`)
- `restic` installed and in `$PATH`
- `rclone` configured with a WebDAV remote (e.g., `webdavbox`)
- `jq` installed for parsing Telegram API responses
- `flock` for preventing concurrent cron runs (usually pre-installed)

## ⚙️ Configuration

1. **Create and secure the environment file**:

   ```bash
   sudo cp .env.example /etc/miab-notify.env
   sudo chmod 600 /etc/miab-notify.env


Edit /etc/miab-notify.env with your credentials and settings:
bashBOT_TOKEN="123456789:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
CHAT_ID="987654321"
RESTIC_PASSWORD="your_secure_password_here"
LOG_FILE="/var/log/restic.log"  # Optional, defaults to /var/log/restic.log


Make scripts executable:
bashchmod +x scripts/*.sh
sudo chmod 700 scripts/*.sh  # Restrict access


Ensure log file is writable:
bashsudo touch /var/log/restic.log
sudo chmod 600 /var/log/restic.log


Configure rclone:
Ensure a WebDAV remote (e.g., webdavbox) is set up in rclone. Test it:
bashrclone lsd webdavbox:/backup


🔔 Telegram Notification Helper
scripts/telegram_notify.sh handles Telegram notifications. It:

Loads BOT_TOKEN, CHAT_ID, RESTIC_PASSWORD, and optional LOG_FILE from /etc/miab-notify.env.
Escapes special characters for Telegram API compatibility.
Retries on network failures (3 attempts, 10-second timeout).
Verifies API responses with jq.
Logs all attempts and results to LOG_FILE (default: /var/log/restic.log).
Exports send_telegram function for use in other scripts.

💾 Backup Script
scripts/restic-rclone-backup.sh automates backups with the following features:

Validates dependencies (restic, rclone, jq) and backup source.
Initializes the Restic repository if it doesn’t exist.
Backs up /home/user-data to rclone:webdavbox:/backup.
Verifies repository integrity with restic check.
Prunes old backups (--keep-daily 7 --keep-weekly 4 --keep-monthly 6).
Logs all actions to /var/log/restic.log.
Sends Telegram notifications on success or failure, including duration.

Security Notes

RESTIC_PASSWORD is sourced from /etc/miab-notify.env, not hard-coded.
Scripts are restricted (chmod 700) to prevent unauthorized access.
Telegram credentials and passwords are stored securely in /etc/miab-notify.env.

🔧 Usage Examples
Manual Test
Run with debugging output:
bashbash -x scripts/restic-rclone-backup.sh
Cron Entry for Nightly Backup
Add to crontab (crontab -e) to run at 4 AM, using flock to prevent concurrent runs:
bash0 4 * * * flock -n /tmp/restic-backup.lock /path/to/miab-backups/scripts/restic-rclone-backup.sh >> /var/log/restic.log 2>&1
Replace /path/to/miab-backups with the actual path to the repository.
Verify Backups
Periodically test restorability (e.g., monthly):
bashrestic -r rclone:webdavbox:/backup restore latest --target /tmp/restore-test
📁 Notes

Sensitive data (Telegram credentials, Restic password) is stored in /etc/miab-notify.env, excluded by .gitignore.
Scripts include validation checks for reliability.
trap ERR sends Telegram alerts on any failure.
flock prevents concurrent cron runs, protecting the Restic repository.
Logs are centralized in /var/log/restic.log for easy debugging.
Consider monitoring cron execution (e.g., via a "heartbeat" notification) to detect scheduling issues.

🛠️ Troubleshooting

Backup fails: Check /var/log/restic.log for errors.
No Telegram notifications: Verify BOT_TOKEN and CHAT_ID in /etc/miab-notify.env, and ensure jq is installed.
WebDAV issues: Test the remote with rclone lsd webdavbox:/backup.
Cron not running: Confirm the cron daemon is active (systemctl status cron) and the lock file isn’t stuck (rm /tmp/restic-backup.lock).

🪪 License
MIT — use at your own risk.
text---

### Что обновлено в мануале
1. **Унифицированное логирование**:
   - Указано, что логи по умолчанию идут в `/var/log/restic.log`, с возможностью переопределения через `.env`.
2. **Добавлен `RESTIC_PASSWORD`**:
   - Уточнено, что он обязателен в `/etc/miab-notify.env`.
3. **Описание скриптов**:
   - Обновлены разделы про `telegram_notify.sh` и `restic-rclone-backup.sh`, чтобы отражать новые функции (экспорт `send_telegram`, проверки зависимостей).
4. **Язык**:
   - Смешанный русский/английский стиль заменён на английский для единообразия с улучшенными скриптами.
5. **Проверка и безопасность**:
   - Усилены рекомендации по настройке прав и проверке зависимостей.

---

### Как применить
1. **Скопируй текст выше**:
   - Выдели всё от `# miab-backups` до конца и вставь в файл `README.md` в корне `miab-backups`.
2. **Обнови `.env.example`**:
   - Убедись, что в `.env.example` есть:
     ```bash
     BOT_TOKEN=""
     CHAT_ID=""
     RESTIC_PASSWORD=""
     LOG_FILE="/var/log/restic.log"  # Опционально

Загрузи изменения:
bashgit add README.md .env.example
git commit -m "Update README.md with new script features and configuration"
git push origin main

Проверь:

Перейди на https://github.com/Anton-Babaskin/miab-backups и убедись, что всё отображается корректно.




Дополнительно

Если тестируешь скрипты, убедись, что /home/user-data существует или замени путь на реальный.
Проверь, что WebDAV настроен и доступен через rclone.
