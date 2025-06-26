#!/usr/bin/env bash
set -eo pipefail

ENV_ROOT="/opt/tljh/user/envs"
MAMBA="/opt/tljh/user/bin/mamba"
CONDA="/opt/tljh/user/bin/conda"

# Define environments and their packages
declare -A ENVIRONMENTS
ENVIRONMENTS["datasci-minimal"]="python=3.12 numpy pandas matplotlib"
ENVIRONMENTS["datasci-full"]="python=3.12 numpy pandas matplotlib seaborn scikit-learn statsmodels sympy jupyterlab jupyter ipywidgets plotly openpyxl xlsxwriter"

# Check and create environments if they don’t exist
for env in "${!ENVIRONMENTS[@]}"; do
    ENV_PATH="$ENV_ROOT/$env"
    if [ -d "$ENV_PATH" ]; then
        echo "✅ Environment '$env' already exists at $ENV_PATH, skipping..."
    else
        echo "📦 Creating environment '$env'..."
        sudo "$MAMBA" create --yes -p "$ENV_PATH" -c conda-forge ${ENVIRONMENTS[$env]}
    fi
done

# R kernel environment (optional, skip if already exists)
R_ENV="$ENV_ROOT/r-base"
if [ -d "$R_ENV" ]; then
    echo "✅ R environment already exists at $R_ENV, skipping..."
else
    echo "📦 Installing R environment..."
    sudo "$MAMBA" create --yes -p "$R_ENV" -c conda-forge r-base=4.3 r-irkernel
fi

# Register kernels with Jupyter
echo "🔄 Refreshing Jupyter kernels..."
for env_dir in "$ENV_ROOT"/*; do
    if [ -d "$env_dir" ] && [ -x "$env_dir/bin/python" ]; then
        sudo "$env_dir/bin/python" -m ipykernel install --prefix=/opt/tljh/user --name="$(basename "$env_dir")" --display-name="$(basename "$env_dir")"
    elif [ -x "$env_dir/bin/R" ]; then
        sudo "$env_dir/bin/R" --quiet -e "IRkernel::installspec(name='$(basename "$env_dir")', displayname='R: $(basename "$env_dir")', user=FALSE)"
    fi
done

echo "✅ All done!"
