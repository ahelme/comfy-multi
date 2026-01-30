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

    # Create workflows index for v0.9.2 userdata API
    cat > /comfyui/user/default/workflows/.index.json << 'INDEXEOF'
{
  "version": "1.0",
  "workflows": [
    "flux2_klein_9b_text_to_image.json",
    "flux2_klein_4b_text_to_image.json",
    "ltx2_text_to_video.json",
    "ltx2_text_to_video_distilled.json",
    "example_workflow.json"
  ],
  "default": "flux2_klein_9b_text_to_image.json"
}
INDEXEOF

    # Create templates metadata for v0.9.2
    cat > /comfyui/user/default/comfy.templates.json << 'TEMPLATEEOF'
{
  "templates": [
    {
      "id": "flux2_klein_9b",
      "name": "Flux2 Klein 9B - Text to Image",
      "description": "High-quality text-to-image generation using Flux2 Klein 9B model",
      "file": "flux2_klein_9b_text_to_image.json",
      "category": "Image Generation",
      "tags": ["flux2", "text-to-image", "9b"],
      "default": true
    },
    {
      "id": "flux2_klein_4b",
      "name": "Flux2 Klein 4B - Text to Image",
      "description": "Fast text-to-image generation using Flux2 Klein 4B model",
      "file": "flux2_klein_4b_text_to_image.json",
      "category": "Image Generation",
      "tags": ["flux2", "text-to-image", "4b", "fast"]
    },
    {
      "id": "ltx2_video",
      "name": "LTX-2 - Text to Video",
      "description": "State-of-the-art text-to-video generation with LTX-2 19B model",
      "file": "ltx2_text_to_video.json",
      "category": "Video Generation",
      "tags": ["ltx2", "text-to-video", "19b"]
    },
    {
      "id": "ltx2_video_distilled",
      "name": "LTX-2 Distilled - Text to Video",
      "description": "Faster text-to-video generation with distilled LTX-2 model",
      "file": "ltx2_text_to_video_distilled.json",
      "category": "Video Generation",
      "tags": ["ltx2", "text-to-video", "distilled", "fast"]
    },
    {
      "id": "example",
      "name": "Example Workflow",
      "description": "Basic example workflow for learning ComfyUI",
      "file": "example_workflow.json",
      "category": "Examples",
      "tags": ["example", "tutorial"]
    }
  ]
}
TEMPLATEEOF

    echo "✓ Userdata structure initialized for v0.9.2"
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
