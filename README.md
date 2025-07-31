# miab-backups# 📦 Mail-in-a-Box Backup Script

Automated encrypted backups using Restic + rclone + WebDAV + Telegram notifications.

---

## 🚀 Features

- 🔒 Encrypted backups of `/home/user-data` using **Restic**
- ☁️ Upload to **WebDAV** storage via **rclone**
- 📣 Telegram alerts on success/failure
- ⏱️ Automated via **systemd** timer

---

## ⚙️ Quick Setup

### 1. Clone the repository

```bash
git clone https://github.com/Anton-Babaskin/miab-backups.git
cd miab-backups
```

### 2. Install required tools

```bash
apt update
apt install -y restic rclone curl
```

### 3. Configure rclone

```bash
rclone config
```

- Type: `WebDAV`  
- URL: `https://uXXXXXX.your-storagebox.de/backup`  
- Vendor: `Other`  
- Username & Password: from your provider

### 4. Set variables in the script

Edit `restic_rclone_webdav_backup.sh`:

```bash
BACKUP_SRC="/home/user-data"
RCLONE_REMOTE="remote:webdav-folder"
RESTIC_PASSWORD="your_restic_password"
TELEGRAM_BOT_TOKEN="your_bot_token"
TELEGRAM_CHAT_ID="your_chat_id"
```

### 5. Initialize the Restic repository

```bash
RESTIC_PASSWORD=your_restic_password \
restic -r rclone:remote:webdav-folder init
```

### 6. Make the script executable

```bash
chmod +x restic_rclone_webdav_backup.sh
```

### 7. Setup systemd

```bash
cp systemd/restic-backup.service /etc/systemd/system/
cp systemd/restic-backup.timer /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now restic-backup.timer
```

---

## 🕒 Example systemd timer: Daily at 03:30

```ini
# /etc/systemd/system/restic-backup.timer
[Unit]
Description=Daily Restic backup

[Timer]
OnCalendar=*-*-* 03:30:00
Persistent=true

[Install]
WantedBy=timers.target
```

---

## 📤 Telegram Alerts

- ✅ On success: snapshot ID + duration  
- ❌ On failure: error message

---

## 🔐 Security Tips

- Use `EnvironmentFile=` in systemd service to store secrets
- Protect script:

```bash
chmod 700 restic_rclone_webdav_backup.sh
```

---

## 🧪 Manual run

```bash
./restic_rclone_webdav_backup.sh
```

---

## 📄 License

MIT — use at your own risk.
