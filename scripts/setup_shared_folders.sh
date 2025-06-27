#!/usr/bin/env bash
# TLJH shared folders setup script
# Run as root: sudo bash setup-shared-folders.sh

set -euxo pipefail

# 1. Ensure jupyter-users group exists
groupadd --force jupyter-users || true

# 2. Add all current Jupyter users to the group
for u in $(cut -d: -f1 /etc/passwd | grep '^jupyter-'); do
  usermod -aG jupyter-users "$u"
done

# 3. Create /srv/data/shared (writable by all users)
mkdir -p /srv/data/shared
chown root:jupyter-users /srv/data/shared
chmod 2775 /srv/data/shared  # rwxr-sr-x to maintain group on new files
setfacl -d -m g::rwx /srv/data/shared  # default ACL for group write

# 4. Create /srv/data/datasets (read-only, writable only by admins)
mkdir -p /srv/data/datasets
chown root:jupyterhub-admins /srv/data/datasets
chmod 755 /srv/data/datasets  # readable by all, writable only by admins

# 5. Update skeleton for new users
ln -sf /srv/data/shared /etc/skel/shared
ln -sf /srv/data/datasets /etc/skel/datasets

# 6. Add symlinks for existing users
for u in $(cut -d: -f1 /etc/passwd | grep '^jupyter-'); do
  HOME_DIR="/home/$u"
  ln -sf /srv/data/shared "$HOME_DIR/shared"
  ln -sf /srv/data/datasets "$HOME_DIR/datasets"
  chown -h "$u:$u" "$HOME_DIR/shared" "$HOME_DIR/datasets"
done

echo "✅ Shared folders set up:"
echo "– ~/shared   (read/write for all users)"
echo "– ~/datasets (read-only for users, writable by admins)"
