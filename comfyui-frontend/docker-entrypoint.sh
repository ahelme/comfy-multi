#!/bin/bash
set -e

echo "==================================================================="
echo "ComfyUI Frontend - User: ${USER_ID:-unknown}"
echo "==================================================================="

# Set USER_ID environment variable for custom node
export COMFYUI_USER_ID="${USER_ID}"
export QUEUE_MANAGER_URL="${QUEUE_MANAGER_URL:-http://queue-manager:3000}"

# Create user-specific directories
mkdir -p /comfyui/output/${USER_ID}
mkdir -p /comfyui/input/${USER_ID}

# Link user workflows
if [ -d "/workflows" ]; then
    ln -sf /workflows /comfyui/user_workflows
fi

# Copy template workflows to user directory for ComfyUI v0.9.2
if [ -d "/workflows" ]; then
    mkdir -p /comfyui/user/default/workflows
    cp -f /workflows/*.json /comfyui/user/default/workflows/ 2>/dev/null || true
    echo "✓ Workflows copied to user/default/workflows/"
fi

# Link shared models (read-only)
if [ -d "/models/shared" ]; then
    for model_dir in /models/shared/*; do
        if [ -d "$model_dir" ]; then
            model_name=$(basename "$model_dir")
            if [ ! -e "/comfyui/models/$model_name" ]; then
                ln -s "$model_dir" "/comfyui/models/$model_name"
            fi
        fi
    done
fi

# Link user models
if [ -d "/models/user/${USER_ID}" ]; then
    mkdir -p /comfyui/models/user_models
    ln -sf "/models/user/${USER_ID}" "/comfyui/models/user_models/${USER_ID}"
fi

echo "✓ User directories configured"
echo "✓ Queue Manager: ${QUEUE_MANAGER_URL}"
echo "✓ Starting ComfyUI..."
echo ""

# Execute ComfyUI
exec "$@"
