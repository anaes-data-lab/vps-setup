#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Setting up shared directories..."

# 1) Ensure required groups exist
groups=(jupyterhub-users jupyterhub-admins)
for grp in "${groups[@]}"; do
  if ! getent group "$grp" >/dev/null; then
    echo "➕ Creating group: $grp"
    sudo groupadd "$grp"
  fi
done

# 2) Define directories, owners, groups, and permissions
#    Format: path=owner:group:perm
declare -A DIRS=(
  ["/srv/shared"]="root:jupyterhub-users:2775"
  ["/srv/shared/.ipynb_checkpoints"]="root:jupyterhub-users:2775"
  ["/srv/datasets"]="root:jupyterhub-admins:2775"
  ["/srv/datasets/.ipynb_checkpoints"]="root:jupyterhub-admins:2775"
)

# 3) Create and configure each directory
for path in "${!DIRS[@]}"; do
  IFS=":" read -r owner group perm <<< "${DIRS[$path]}"
  echo "📂 Ensuring $path ($owner:$group, chmod $perm)"
  sudo mkdir -p "$path"
  sudo chown "$owner":"$group" "$path"
  sudo chmod "$perm" "$path"
done

# 4) Fix permissions on existing content and enforce setgid inheritance
echo "🔧 Applying group permissions recursively and setgid defaults"
sudo chmod -R g+rwX /srv/shared
sudo chmod -R g+rwX /srv/datasets
# Set default ACLs so new files inherit group write
if command -v setfacl >/dev/null 2>&1; then
  sudo setfacl -R -d -m g::rwx /srv/shared
  sudo setfacl -R -d -m g::rwx /srv/datasets
fi

echo "✅ Shared folder structure in place with recursive permissions."

# 5) Create or update symlinks in /etc/skel
echo "🔗 Creating symlinks in /etc/skel"
for name in shared datasets; do
  target="/srv/$name"
  link="/etc/skel/$name"
  if [ ! -L "$link" ] || [ "$(readlink "$link")" != "$target" ]; then
    echo "   ↪ Linking $link -> $target"
    sudo ln -sfn "$target" "$link"
  fi
done

# 6) Install README for new users, if present
if [ -f "user-readme.md" ]; then
  echo "📝 Installing README to /etc/skel"
  sudo install -m 644 user-readme.md /etc/skel/README.md
else
  echo "⚠️  user-readme.md not found; skipping README"
fi

echo "🎉 Setup complete."
