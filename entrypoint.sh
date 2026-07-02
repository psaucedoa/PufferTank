#!/bin/bash

# print CUDA version
echo "PufferTank 4.0 (CUDA $(nvcc --version | grep "release" | awk '{print $6}'))"

# check if NVIDIA driver is loaded
if ! nvidia-smi > /dev/null 2>&1; then
    echo "WARNING: The NVIDIA Driver was not detected. GPU functionality will not be available."
fi

# Setup PufferLib on the host-mounted workspace if missing
if [ -d "/workspaces/puffertank" ]; then
    cd /workspaces/puffertank
    . $HOME/.local/bin/env
    . /venv/bin/activate
    
    if [ ! -d "pufferlib" ]; then
        echo "Setting up PufferLib in /workspaces/puffertank on the host..."
        git clone https://github.com/pufferai/pufferlib --branch 4.0
        git clone https://github.com/pufferai/puffer.ai --branch 4.0
        cd pufferlib
        uv pip install -e .
        bash build.sh breakout
        curl -L -o experiments.zip https://github.com/PufferAI/PufferLib/releases/download/experiments/experiments.zip
        unzip -q experiments.zip
        rm experiments.zip
        python constellation/cache_data.py --full
        bash build.sh constellation --fast
    else
        cd pufferlib
        uv pip install -e . > /dev/null 2>&1
    fi
fi

# keep container running
exec "$@"
