#!/usr/bin/env bash

export PYTHONUNBUFFERED=1
export APP="ComfyUI"

TEMPLATE_NAME="comfyui"
TEMPLATE_VERSION_FILE="/workspace/${APP}/template.json"

echo "Template name: ${TEMPLATE_NAME}"
echo "Template version: ${TEMPLATE_VERSION}"

if [[ -e ${TEMPLATE_VERSION_FILE} ]]; then
    EXISTING_TEMPLATE_NAME=$(jq -r '.template_name // empty' "$TEMPLATE_VERSION_FILE")

    if [[ -n "${EXISTING_TEMPLATE_NAME}" ]]; then
        if [[ "${EXISTING_TEMPLATE_NAME}" != "${TEMPLATE_NAME}" ]]; then
            EXISTING_VERSION="0.0.0"
        else
            EXISTING_VERSION=$(jq -r '.template_version // empty' "$TEMPLATE_VERSION_FILE")
        fi
    else
        EXISTING_VERSION="0.0.0"
    fi
else
    EXISTING_VERSION="0.0.0"
fi

save_template_json() {
    cat << EOF > ${TEMPLATE_VERSION_FILE}
{
    "template_name": "${TEMPLATE_NAME}",
    "template_version": "${TEMPLATE_VERSION}"
}
EOF
}

sync_directory() {
    local src_dir="$1"
    local dst_dir="$2"

    echo "Syncing from $src_dir to $dst_dir"

    # Ensure destination directory exists
    mkdir -p "$dst_dir"

    # Get total size of source directory
    local total_size=$(du -sb "$src_dir" | cut -f1)

    # Use parallel tar with fast compression and exclusions
    tar --use-compress-program="pigz -p 4" \
        --exclude='*.pyc' \
        --exclude='__pycache__' \
        --exclude='*.log' \
        -cf - -C "$src_dir" . | \
    pv -s $total_size | \
    tar --use-compress-program="pigz -p 4" -xf - -C "$dst_dir"

    echo "Sync completed"
}

sync_apps() {
    # Only sync if the DISABLE_SYNC environment variable is not set
    if [ -z "${DISABLE_SYNC}" ]; then
        # Sync application to workspace to support Network volumes
        echo "Syncing ${APP} to workspace, please wait..."
        sync_directory "/${APP}" "/workspace/${APP}"
        save_template_json
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
cd /app-manager
npm start > /workspace/logs/app-manager.log 2>&1 &

if [[ ${DISABLE_AUTOLAUNCH} ]]
then
    echo "Auto launching is disabled so the applications will not be started automatically"
    echo "You can launch them manually using the launcher scripts:"
    echo ""
    echo "   /start_comfyui.sh"
else
    ARGS=()

    if [[ ${EXTRA_ARGS} ]];
    then
          ARGS=("${ARGS[@]}" ${EXTRA_ARGS})
    fi

    /start_comfyui.sh "${ARGS[@]}"
fi

echo "All services have been started"
