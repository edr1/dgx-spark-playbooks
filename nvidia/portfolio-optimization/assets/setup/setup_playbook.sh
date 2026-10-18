#!/bin/bash
set -euo pipefail
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
uv --version
cp -r ~/notebooks/playbook/setup ~/notebooks/setup/
cd /home/rapids/notebooks/setup

# Install cuOpt kernel
echo "Installing cuOpt Portfolio Optimization Kernel."
python -m venv .venv
source .venv/bin/activate

# Install with all dependencies using uv for CUDA 13 (DGX SPark CUDA version)
export PATH="$HOME/.local/bin:$PATH"
# NVIDIA wheels are large; allow slow transfers and limit competing downloads.
export UV_HTTP_TIMEOUT="${UV_HTTP_TIMEOUT:-600}"
export UV_CONCURRENT_DOWNLOADS="${UV_CONCURRENT_DOWNLOADS:-4}"
uv sync --extra cuda13 --locked --no-dev

# Install Jupyter and JupyterLab
uv pip install ipykernel

# Register directly: uv run without --extra cuda13 can remove CUDA dependencies.
.venv/bin/python -m ipykernel install --user --name=portfolio-opt --display-name "Portfolio Optimization"

# Verify the notebook imports before starting JupyterLab.
.venv/bin/python -c "from cufolio import cvar_optimizer, cvar_utils, utils; from cufolio.cvar_parameters import CvarParameters"

# Copy necessary playbook files
cp -r ~/notebooks/playbook/assets ~/notebooks/assets
cp ~/notebooks/playbook/README.md ~/notebooks/START_HERE.md
cp ~/notebooks/playbook/cvar_basic.ipynb ~/notebooks/cvar_basic.ipynb

set -m
# Start the primary process and put it in the background
jupyter-lab --notebook-dir=/home/rapids/notebooks --ip=0.0.0.0 --no-browser --NotebookApp.token='' --NotebookApp.allow_origin='*'