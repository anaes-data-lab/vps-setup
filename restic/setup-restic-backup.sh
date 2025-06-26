#!/usr/bin/env bash
#
# setup-restic-backup.sh
# Installs restic, configures Backblaze B2 repo, and schedules daily TLJH backups.
# Run this as root: sudo bash setup-restic-backup.sh

set -euo pipefail

# 1) Install Restic if missing
if ! command -v restic &>/dev/null; then
  apt update
  apt install -y restic
fi

# 2) Prompt for B2 credentials & repo info
read -p "Backblaze B2 Key ID: " B2_ACCOUNT_ID
read -p "Backblaze B2 Account Key: " B2_ACCOUNT_KEY
read -p "Backblaze B2 Bucket name: " B2_BUCKET
read -p "Restic repo path inside bucket (e.g. tljh-backups): " RESTIC_PATH
read -s -p "Create a Restic repository password: " RESTIC_PASSWORD
echo

# 3) Write environment file
ENV_FILE=/etc/restic-backup.env
cat >"$ENV_FILE" <<EOF
export B2_ACCOUNT_ID="${B2_ACCOUNT_ID}"
export B2_ACCOUNT_KEY="${B2_ACCOUNT_KEY}"
export RESTIC_REPOSITORY="b2:${B2_BUCKET}:${RESTIC_PATH}"
export RESTIC_PASSWORD="${RESTIC_PASSWORD}"
EOF
chmod 600 "$ENV_FILE"

# 4) Create the backup & prune script
BACKUP_SCRIPT=/usr/local/bin/tljh-restic-backup.sh
cat >"$BACKUP_SCRIPT" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

# load credentials + repo settings
source /etc/restic-backup.env

LOGFILE=/var/log/tljh-restic-backup.log

# ensure log file exists
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"
chmod 600 "$LOGFILE"

# init repo on first run
if ! restic snapshots >/dev/null 2>&1; then
  restic init
fi

# perform backup
restic backup /opt/tljh/hub /srv/data /home \
  --verbose --tag tljh

# prune old snapshots
restic forget \
    --keep-hourly 24 \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 12 \
    --prune

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup OK" >> "$LOGFILE"
EOF

chmod +x "$BACKUP_SCRIPT"

# 5) Install cron job
CRON_FILE=/etc/cron.d/tljh-restic-backup
cat >"$CRON_FILE" <<EOF
# Run TLJH Restic backup hourly
0 * * * * root $BACKUP_SCRIPT >> /var/log/tljh-restic-backup.log 2>&1
EOF

echo "✅ Restic backup setup complete!
– Edit $ENV_FILE to rotate credentials or change bucket/repo
– Backups will run hourly via cron
– Logs at /var/log/tljh-restic-backup.log"
