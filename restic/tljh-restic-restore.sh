#!/usr/bin/env bash
#
# tljh-restic-restore.sh
# Restore from TLJH Restic backups on Backblaze B2.
# Usage:
#   sudo tljh-restic-restore.sh [-s SNAPSHOT] [-t TARGET_DIR] [-p PATH]...
# Examples:
#   # full restore of latest into /mnt/restore
#   sudo tljh-restic-restore.sh
#   # restore snapshot 5 into /backup/tljh, only /etc/tljh and /home
#   sudo tljh-restic-restore.sh -s 5 -t /backup/tljh \
#       -p /etc/tljh -p /home

set -euo pipefail

ENV_FILE=/etc/restic-backup.env

if [[ ! -r $ENV_FILE ]]; then
  echo "❌ Cannot read credentials file $ENV_FILE"
  exit 1
fi

# Load B2 creds & repo settings
# (expects B2_ACCOUNT_ID, B2_ACCOUNT_KEY, RESTIC_REPOSITORY, RESTIC_PASSWORD)
source "$ENV_FILE"

# defaults
snapshot="latest"
target="/mnt/restore"
includes=()

usage() {
  cat <<EOF
Usage: $0 [-s SNAPSHOT] [-t TARGET_DIR] [-p PATH]...
  -s SNAPSHOT     restic snapshot ID or 'latest' (default: latest)
  -t TARGET_DIR   directory to restore into (default: $target)
  -p PATH         path within snapshot to include; repeatable
  -h              show this help
EOF
  exit 1
}

# parse flags
while getopts ":s:t:p:h" opt; do
  case $opt in
    s) snapshot="$OPTARG" ;;
    t) target="$OPTARG" ;;
    p) includes+=("$OPTARG") ;;
    h) usage ;;
    *) usage ;;
  esac
done

echo "🔍 Available TLJH snapshots (tag tljh):"
restic snapshots --tag tljh
echo

echo "📌 Restoring snapshot: $snapshot"
echo "📂 Target directory : $target"
if [ ${#includes[@]} -gt 0 ]; then
  echo "➡️  Including only paths:"
  for p in "${includes[@]}"; do echo "   - $p"; done
else
  echo "➡️  Restoring entire snapshot"
fi
echo

# ensure target exists
mkdir -p "$target"
chmod 700 "$target"

# build restic command
cmd=(restic restore "$snapshot" --target "$target")
for p in "${includes[@]}"; do
  cmd+=(--include "$p")
done

# run restore
"${cmd[@]}"

echo
echo "✅ Restore complete. Check your files under $target"
echo "   When ready, stop TLJH services and copy files back:"
echo "     systemctl stop jupyterhub"
echo "     rsync -a $target/etc/tljh/ /etc/tljh/"
echo "     rsync -a $target/srv/data/ /srv/data/"
echo "     rsync -a $target/home/ /home/"
echo "     systemctl start jupyterhub"
