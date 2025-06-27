#!/usr/bin/env bash
set -euo pipefail

source /etc/restic-backup.env

RESTORE_PATH=/srv/tljh-restore
LOGFILE=/var/log/tljh-restic-restore.log

mkdir -p "$RESTORE_PATH"
mkdir -p "$(dirname "$LOGFILE")"
touch "$LOGFILE"
chmod 600 "$LOGFILE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting restore..." >> "$LOGFILE"

# Show available snapshots
restic snapshots --tag tljh
read -p "Enter snapshot ID (or leave blank for latest): " SNAPSHOT
if [[ -n "$SNAPSHOT" ]]; then
    restic restore "$SNAPSHOT" --target "$RESTORE_PATH"
else
    restic restore latest --target "$RESTORE_PATH"
fi

# Reinstall TLJH if needed
if ! command -v tljh-config &>/dev/null; then
    echo "TLJH not found, reinstalling..."
    curl https://tljh.jupyter.org/bootstrap.py | sudo python3
fi

# Restore TLJH state
echo "Restoring TLJH state..."
rsync -a "$RESTORE_PATH/opt/tljh/state/" /opt/tljh/state/

# Restore config
META="$RESTORE_PATH/srv/tljh-backup-meta"
if [ -f "$META/tljh-config.yaml" ]; then
    echo "⚠️  TLJH config found at $META/tljh-config.yaml"
    echo "📝 Please reapply relevant settings manually using 'tljh-config set ...'"
fi

# Recreate users
USER_LIST="$META/jupyter-users.txt"
if [ -f "$USER_LIST" ]; then
    while read -r user; do
        if ! id "$user" &>/dev/null; then
            echo "Creating user: $user"
            useradd -m -s /bin/bash "$user"
        fi
    done < "$USER_LIST"
fi

# Restore home and shared data
echo "Restoring home directories..."
rsync -a "$RESTORE_PATH/home/" /home/
if [ -d "$RESTORE_PATH/srv/data" ]; then
    echo "Restoring /srv/data..."
    rsync -a "$RESTORE_PATH/srv/data/" /srv/data/
else
    echo "⚠️  /srv/data not present in this snapshot — skipping"
fi

# Restore kernelspecs
echo "Restoring Jupyter kernelspecs..."
if [ -d "$META/kernelspecs/tljh-user" ]; then
  cp -r "$META/kernelspecs/tljh-user/"* /opt/tljh/user/share/jupyter/kernels/
fi
if [ -d "$META/kernelspecs/system" ]; then
  cp -r "$META/kernelspecs/system/"* /usr/local/share/jupyter/kernels/
fi

# Reinstall R packages
RPKG="$META/r-packages.txt"
if [ -f "$RPKG" ] && command -v Rscript &>/dev/null; then
  echo "Reinstalling R packages from $RPKG"
  Rscript -e 'pkgs <- readLines("'"$RPKG"'"); install.packages(pkgs, repos="https://cloud.r-project.org")'
fi

# Reinstall Python packages
REQS="$META/user-requirements.txt"
if [ -f "$REQS" ]; then
    source /opt/tljh/user/bin/activate
    pip install -r "$REQS"
    deactivate
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Restore complete." >> "$LOGFILE"
echo "✅ Restore finished. Log: $LOGFILE"
