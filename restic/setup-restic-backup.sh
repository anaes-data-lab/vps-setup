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
