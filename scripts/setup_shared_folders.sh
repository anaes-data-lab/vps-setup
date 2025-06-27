#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Setting up shared directories..."

# Create the shared data folders
sudo mkdir -p /srv/shared /srv/datasets

# Set ownership and permissions
sudo chown root:jupyter-users /srv/shared
sudo chmod 2775 /srv/shared  # rwxrwsr-x, sticky group bit

sudo chown root:jupyterhub-admins /srv/datasets
sudo chmod 2755 /srv/datasets  # rwxr-sr-x, only admins can write

echo "📁 Shared folders created and permissions set."

# Create symlinks in /etc/skel so new users see them
sudo rm -f /etc/skel/shared /etc/skel/datasets
sudo ln -s /srv/shared /etc/skel/shared
sudo ln -s /srv/datasets /etc/skel/datasets

# Copy the README for new users
if [[ -f "user-readme.md" ]]; then
    sudo cp user-readme.md /etc/skel/README.md
    sudo chmod 644 /etc/skel/README.md
    echo "📝 README installed in /etc/skel."
else
    echo "⚠️  user-readme.md not found! Skipping README installation."
fi

echo "✅ Setup complete."
