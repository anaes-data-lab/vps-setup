#!/usr/bin/env bash
# TLJH provisioning script for a 2GB RAM VPS
# Usage: sudo bash provision-tljh-datascience.sh

set -euo pipefail

echo "📦 Installing essential Python packages..."
sudo /opt/tljh/user/bin/pip install --upgrade pip
sudo /opt/tljh/user/bin/pip install \
  numpy pandas matplotlib seaborn scikit-learn jupyterlab

echo "📊 Installing R and IRkernel (lightweight)..."
sudo apt update
sudo apt install -y --no-install-recommends \
  r-base libcurl4-openssl-dev libssl-dev libxml2-dev

sudo R --no-save <<EOF
install.packages(c('IRkernel', 'ggplot2', 'dplyr'), repos='https://cloud.r-project.org')
IRkernel::installspec(user = FALSE)
EOF

echo "🛡️ Setting TLJH resource limits..."
sudo tljh-config set limits.memory 512M
sudo tljh-config set limits.cpu 1
sudo tljh-config reload

echo "🧯 Optional: enabling swap (1 GB)..."
if ! swapon --summary | grep -q '/swapfile'; then
  sudo fallocate -l 1G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
else
  echo "🔄 Swap already configured, skipping."
fi

echo "✅ TLJH data science setup complete."
echo "➡️  Log in and test kernels: Python 3 and R should both be available."
