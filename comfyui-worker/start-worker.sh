#!/bin/bash
set -e

echo "==================================================================="
echo "Starting ComfyUI Worker: $WORKER_ID"
echo "==================================================================="

# Start ComfyUI in the background
echo "Starting ComfyUI server on port 8188..."
cd /workspace/ComfyUI
python3 main.py --listen 0.0.0.0 --port 8188 &
COMFYUI_PID=$!

# Wait for ComfyUI to be ready
echo "Waiting for ComfyUI to start..."
for i in {1..30}; do
    if curl -sf http://localhost:8188/system_stats > /dev/null 2>&1; then
        echo "✓ ComfyUI is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "✗ ComfyUI failed to start within 30 seconds"
        exit 1
    fi
    sleep 1
done

# Start worker process
echo "Starting worker process..."
cd /workspace
python3 worker.py

# If worker exits, kill ComfyUI
kill $COMFYUI_PID 2>/dev/null || true
