#!/usr/bin/env bash
set -e

# Clone the repo
git clone https://github.com/comfyanonymous/ComfyUI.git /ComfyUI
cd /ComfyUI
git checkout ${COMFYUI_VERSION}

# Create and activate the venv
python3 -m venv --system-site-packages venv
source venv/bin/activate

# Install torch, xformers and sageattention
pip3 install --no-cache-dir torch=="${TORCH_VERSION}" torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128
pip3 install --no-cache-dir xformers=="${XFORMERS_VERSION}" --index-url https://download.pytorch.org/whl/cu128

# Install requirements
pip3 install -r requirements.txt
pip3 install accelerate
pip install setuptools --upgrade

git clone https://github.com/thu-ml/SageAttention.git
cd SageAttention 
sed -i "/compute_capabilities = set()/a compute_capabilities = {\"$TORCH_CUDA_ARCH_LIST\"}" setup.py
# export EXT_PARALLEL=4 NVCC_APPEND_FLAGS="--threads 8" MAX_JOBS=32 # parallel compiling (Optional)
pip install . --no-build-isolation
cd ..


pip install runpod requests

# Install ComfyUI Custom Nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git custom_nodes/ComfyUI-Manager
cd custom_nodes/ComfyUI-Manager
pip3 install -r requirements.txt
pip3 cache purge

# Fix some incorrect modules
pip3 install numpy==1.26.4
deactivate
