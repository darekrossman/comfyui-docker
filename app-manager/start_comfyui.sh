#!/usr/bin/env bash
export PYTHONUNBUFFERED=1
cd /runpod-volume/ComfyUI
source venv/bin/activate
echo "COMFYUI: Starting ComfyUI"
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"
# python3 main.py --listen 0.0.0.0 --port 3001 > /runpod-volume/logs/comfyui.log 2>&1 &
echo "runpod-worker-comfy: Starting ComfyUI"
python3 /comfyui/main.py --disable-auto-launch --disable-metadata &

echo "runpod-worker-comfy: Starting RunPod Handler"
python3 -u /rp_handler.py

deactivate
