#!/usr/bin/env bash
#
# setup-restic-backup.sh
# Run as root: sudo bash setup-restic-backup.sh

set -euo pipefail

# 1. Install Restic if missing
if ! command -v restic &>/dev/null; then
  apt update && apt install -y restic
fi

# 2. Prompt for B2 credentials
read -p "Backblaze B2 Key ID: " B2_ACCOUNT_ID
read -p "Backblaze B2 Account Key: " B2_ACCOUNT_KEY
read -p "Backblaze B2 Bucket name: " B2_BUCKET
read -p "Restic repo path inside bucket (e.g. tljh-backups): " RESTIC_PATH
read -s -p "Create a Restic repository password: " RESTIC_PASSWORD
echo

# 3. Create environment file
ENV_FILE=/etc/restic-backup.env
cat >"$ENV_FILE" <<EOF
export B2_ACCOUNT_ID="${B2_ACCOUNT_ID}"
export B2_ACCOUNT_KEY="${B2_ACCOUNT_KEY}"
export RESTIC_REPOSITORY="b2:${B2_BUCKET}:${RESTIC_PATH}"
export RESTIC_PASSWORD="${RESTIC_PASSWORD}"
EOF
chmod 600 "$ENV_FILE"

# 4. Install backup script
BACKUP_SCRIPT=/usr/local/bin/tljh-restic-backup.sh
cat >"$BACKUP_SCRIPT" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

source /etc/restic-backup.env
LOGFILE=/var/log/tljh-restic-backup.log
BACKUP_META_DIR=/srv/tljh-backup-meta

mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"
chmod 600 "$LOGFILE"
mkdir -p "$BACKUP_META_DIR"

# Dump TLJH config
tljh-config show > "$BACKUP_META_DIR/tljh-config.yaml"
[ -f /opt/tljh/config/jupyterhub_config.py ] && cp /opt/tljh/config/jupyterhub_config.py "$BACKUP_META_DIR/" || true
source /opt/tljh/user/bin/activate
pip freeze > "$BACKUP_META_DIR/user-requirements.txt"
deactivate
cut -d: -f1 /etc/passwd | grep '^jupyter-' > "$BACKUP_META_DIR/jupyter-users.txt"

# Log installed R packages (if present)
if command -v Rscript &>/dev/null; then
  echo "Logging installed R packages..."
  Rscript -e 'writeLines(installed.packages()[,1])' > "$BACKUP_META_DIR/r-packages.txt" || true
fi

# Backup kernelspecs
mkdir -p "$BACKUP_META_DIR/kernelspecs"
if [ -d /opt/tljh/user/share/jupyter/kernels ]; then
  cp -r /opt/tljh/user/share/jupyter/kernels "$BACKUP_META_DIR/kernelspecs/tljh-user/"
fi
if [ -d /usr/local/share/jupyter/kernels ]; then
  cp -r /usr/local/share/jupyter/kernels "$BACKUP_META_DIR/kernelspecs/system/"
fi

# Init repo if needed
if ! restic snapshots >/dev/null 2>&1; then
  restic init
fi

# Perform backup
restic backup \
  /home/jupyter-* \
  /srv/data \
  /opt/tljh/state \
  "$BACKUP_META_DIR" \
  --verbose \
  --tag tljh

# Prune old backups
restic forget \
  --keep-hourly 24 \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 12 \
  --prune

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup OK" >> "$LOGFILE"
EOF

chmod +x "$BACKUP_SCRIPT"

# 5. Create cron job
CRON_FILE=/etc/cron.d/tljh-restic-backup
cat >"$CRON_FILE" <<EOF
0 * * * * root $BACKUP_SCRIPT
EOF

echo "✅ Restic backup setup complete!
– Credentials: $ENV_FILE
– Backup script: $BACKUP_SCRIPT
– Cron job: $CRON_FILE
– Logs: /var/log/tljh-restic-backup.log"

echo "Run sudo /usr/local/bin/tljh-restic-backup.sh to test"