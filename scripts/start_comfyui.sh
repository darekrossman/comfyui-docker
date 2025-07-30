#!/usr/bin/env bash

ARGS=("$@" --listen 0.0.0.0 --port 3001)

export PYTHONUNBUFFERED=1
echo "Starting ComfyUI"
cd /runpod-volume/ComfyUI
source venv/bin/activate
TCMALLOC="$(ldconfig -p | grep -Po "libtcmalloc.so.\d" | head -n 1)"
export LD_PRELOAD="${TCMALLOC}"
# python3 main.py "${ARGS[@]}" > /runpod-volume/logs/comfyui.log 2>&1 &
# echo "ComfyUI started"

echo "runpod-worker-comfy: Starting ComfyUI"
python3 /comfyui/main.py --disable-auto-launch --disable-metadata --disable-xformers --use-sage-attention &

echo "runpod-worker-comfy: Starting RunPod Handler"
python3 -u /rp_handler.py

echo "Log file: /runpod-volume/logs/comfyui.log"
deactivate
