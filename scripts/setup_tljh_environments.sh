#!/bin/bash
# Script to create useful Jupyter kernels for TLJH without breaking the base env

set -euo pipefail

# Base prefix
CONDA_PREFIX="/opt/tljh/user"

# Create a minimal data science environment
$CONDA_PREFIX/bin/conda create -y -n datasci-minimal -c conda-forge \
  python=3.12 \
  ipykernel \
  nb_conda_kernels \
  pandas matplotlib seaborn scikit-learn

# Create a Dash environment
$CONDA_PREFIX/bin/conda create -y -n dash -c conda-forge \
  python=3.12 \
  ipykernel \
  nb_conda_kernels \
  dash plotly flask

# Optional: Create an R kernel
$CONDA_PREFIX/bin/conda create -y -n r-env -c conda-forge \
  r-base=4.3 \
  r-irkernel \
  nb_conda_kernels

# Permissions fix
chown -R tljh-admin:users $CONDA_PREFIX/envs || true
chmod -R o-w $CONDA_PREFIX/envs || true

# Let Jupyter discover kernels via nb_conda_kernels
$CONDA_PREFIX/bin/conda install -y -n base -c conda-forge nb_conda_kernels

echo "✅ Environments created successfully:"
echo " - datasci-minimal"
echo " - dash"
echo " - r-env"
echo
echo "These will appear in the Jupyter dropdown after user logout/login."
