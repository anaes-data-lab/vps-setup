# TLJH Restic Backup & Restore

A pair of helper scripts to back up and restore your The Littlest JupyterHub (TLJH) installation using Restic with Backblaze B2.

---

## Prerequisites

- Ubuntu host running TLJH  
- Restic installed (the backup script bootstraps this for you)  
- Backblaze B2 account, bucket, and application key  
- Environment file at `/etc/restic-backup.env` with:
  ```bash
  export B2_ACCOUNT_ID="YOUR_ACCOUNT_ID"
  export B2_ACCOUNT_KEY="YOUR_APPLICATION_KEY"
  export RESTIC_REPOSITORY="b2:your-bucket:your-path"  # trailing colon allowed for root
  export RESTIC_PASSWORD="your-strong-random-password"
  ```

---

## Installation

1. **Place scripts**  
   ```bash
   sudo mv tljh-restic-backup.sh /usr/local/bin/
   sudo mv tljh-restic-restore.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/tljh-restic-*.sh
   ```

2. **Schedule daily backup** (if not already):
   ```bash
   sudo tee /etc/cron.d/tljh-restic-backup > /dev/null <<EOF
   0 2 * * * root /usr/local/bin/tljh-restic-backup.sh >> /var/log/tljh-restic-backup.log 2>&1
   EOF
   sudo service cron reload
   ```

---

## Usage

### Backup

Run on demand:
```bash
sudo /usr/local/bin/tljh-restic-backup.sh
```
- Initializes the repo on first run  
- Backs up `/etc/tljh`, `/srv/data`, and `/home` (all JupyterHub users)  
- Tags snapshots with `tljh`  
- Prunes to keep 7 daily, 4 weekly, 12 monthly backups  
- Logs to `/var/log/tljh-restic-backup.log`

### Restore

Run on demand:
```bash
sudo /usr/local/bin/tljh-restic-restore.sh [-s SNAPSHOT] [-t TARGET_DIR]
```
- Lists available `tljh` snapshots  
- Restores `/etc/tljh`, `/srv/data`, and `/home` into a staging directory (default `/mnt/restore`)  
- Prompts to sync restored home-dirs back into `/home` with correct ownership

**Options**  
- `-s SNAPSHOT` – snapshot ID or `latest` (default)  
- `-t TARGET_DIR` – where to restore (default `/mnt/restore`)  

---

## Next Steps

1. Review restored files under your target directory.  
2. When ready, stop TLJH:
   ```bash
   sudo systemctl stop jupyterhub
   ```
3. Copy files back:
   ```bash
   sudo rsync -a /mnt/restore/etc/tljh/ /etc/tljh/
   sudo rsync -a /mnt/restore/srv/data/ /srv/data/
   # (and, if needed) rsync user homes:
   sudo rsync -a /mnt/restore/home/ /home/
   ```
4. Restart TLJH:
   ```bash
   sudo systemctl start jupyterhub
   ```
