#!/usr/bin/env bash

export PYTHONUNBUFFERED=1
export APP="ComfyUI"
DOCKER_IMAGE_VERSION_FILE="/workspace/${APP}/docker_image_version"

echo "Template version: ${TEMPLATE_VERSION}"

if [[ -e ${DOCKER_IMAGE_VERSION_FILE} ]]; then
    EXISTING_VERSION=$(cat ${DOCKER_IMAGE_VERSION_FILE})
else
    EXISTING_VERSION="0.0.0"
fi

sync_apps() {
    # Only sync if the DISABLE_SYNC environment variable is not set
    if [ -z "${DISABLE_SYNC}" ]; then
        # Sync application to workspace to support Network volumes
        echo "Syncing ${APP} to workspace, please wait..."
        mv /${APP} /workspace/${APP}

        # Sync Application Manager to workspace to support Network volumes
        echo "Syncing Application Manager to workspace, please wait..."
        mv /app-manager /workspace/app-manager

        echo "${TEMPLATE_VERSION}" > ${DOCKER_IMAGE_VERSION_FILE}
        echo "${VENV_PATH}" > "/workspace/${APP}/venv_path"
    fi
}

fix_venvs() {
    echo "Fixing venv..."
    /fix_venv.sh /ComfyUI/venv /workspace/ComfyUI/venv
}

link_models() {
   # Link models and VAE if they are not already linked
   if [[ ! -L /workspace/ComfyUI/models/checkpoints/sd_xl_base_1.0.safetensors ]]; then
       ln -s /sd-models/sd_xl_base_1.0.safetensors /workspace/ComfyUI/models/checkpoints/sd_xl_base_1.0.safetensors
   fi

   if [[ ! -L /workspace/ComfyUI/models/checkpoints/sd_xl_refiner_1.0.safetensors ]]; then
       ln -s /sd-models/sd_xl_refiner_1.0.safetensors /workspace/ComfyUI/models/checkpoints/sd_xl_refiner_1.0.safetensors
   fi

   if [[ ! -L /workspace/ComfyUI/models/vae/sdxl_vae.safetensors ]]; then
       ln -s /sd-models/sdxl_vae.safetensors /workspace/ComfyUI/models/vae/sdxl_vae.safetensors
   fi
}

if [ "$(printf '%s\n' "$EXISTING_VERSION" "$TEMPLATE_VERSION" | sort -V | head -n 1)" = "$EXISTING_VERSION" ]; then
    if [ "$EXISTING_VERSION" != "$TEMPLATE_VERSION" ]; then
        sync_apps
        fix_venvs
        link_models

        # Create logs directory
        mkdir -p /workspace/logs
    else
        echo "Existing version is the same as the template version, no syncing required."
    fi
else
    echo "Existing version is newer than the template version, not syncing!"
fi

# Start application manager
cd /workspace/app-manager
npm start > /workspace/logs/app-manager.log 2>&1 &

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the applications will not be started automatically"
    echo "You can launch them manually using the launcher scripts:"
    echo ""
    echo "   /start_comfyui.sh"
else
    /start_comfyui.sh
fi

echo "All services have been started"
