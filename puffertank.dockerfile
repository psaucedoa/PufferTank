FROM nvcr.io/nvidia/cuda:13.0.2-cudnn-devel-ubuntu24.04
ARG DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /workspaces/puffertank
WORKDIR /workspaces/puffertank

# Core system packages
# Custom installs without the cudnn base also need libnccl2 libnccl-dev
RUN apt-get update && apt-get install -y curl wget sudo git build-essential clang

# UV venv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh \
    && . $HOME/.local/bin/env \
    && uv venv --python 3.12 --prompt 🐡 /venv

RUN apt-get update && apt-get install -y \
    htop gdb tmux psmisc llvm ccache \
    sqlite3 \
    libomp-dev libglfw3 libgl1-mesa-dev python3.12-dev 

# Nsight Systems for profiling
RUN apt-get update && apt-get install -y --no-install-recommends nsight-systems-2025.6.3

# PyTorch + uv env
RUN . $HOME/.local/bin/env \
    && . /venv/bin/activate \
    && uv pip install torch --index-url https://download.pytorch.org/whl/cu130

# PufferLib setup is now handled at runtime by entrypoint.sh inside the host-mounted /workspace

# Run on container startup
COPY entrypoint.sh /root/entrypoint.sh
RUN chmod +x /root/entrypoint.sh
ENTRYPOINT ["/root/entrypoint.sh"]

# Bashrc
RUN echo "export PS1=$''" >> ~/.bashrc \
 && echo "alias vim='/usr/bin/nvim'" >> ~/.bashrc \ 
 && echo "alias diff='diff --color --palette=':ad=36:de=31:ln=33''" >> ~/.bashrc \
 && echo "alias pip='uv pip'" >> ~/.bashrc \
 && echo ". /venv/bin/activate" >> ~/.bashrc \
 && echo "cd /workspaces/puffertank" >> ~/.bashrc \
 && echo "export __GLX_VENDOR_LIBRARY_NAME=mesa" >> ~/.bashrc

RUN apt-get clean
CMD ["/bin/bash"]
