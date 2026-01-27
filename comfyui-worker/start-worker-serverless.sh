#!/bin/bash
# =============================================================================
# Start Worker in Serverless Mode
# =============================================================================
# Launches ComfyUI, Health Server, and Worker with serverless configuration
# Health server provides /health endpoint for Verda liveness checks
# Worker exits after idle timeout or job limit reached
# =============================================================================

set -e

echo "======================================"
echo "ComfyUI Worker - Serverless Mode"
echo "======================================"
echo "Worker ID: ${WORKER_ID:-worker-serverless}"
echo "Provider: ${INFERENCE_PROVIDER:-verda-serverless}"
echo "Max Idle Polls: ${SERVERLESS_MAX_IDLE_POLLS:-10}"
echo "Job Limit: ${SERVERLESS_JOB_LIMIT:-0}"
echo "======================================"

# Function to handle cleanup on exit
cleanup() {
    echo "Shutting down services..."
    if [ ! -z "$COMFYUI_PID" ] && kill -0 $COMFYUI_PID 2>/dev/null; then
        echo "Stopping ComfyUI (PID: $COMFYUI_PID)"
        kill $COMFYUI_PID 2>/dev/null || true
    fi
    if [ ! -z "$HEALTH_PID" ] && kill -0 $HEALTH_PID 2>/dev/null; then
        echo "Stopping Health Server (PID: $HEALTH_PID)"
        kill $HEALTH_PID 2>/dev/null || true
    fi
    echo "Shutdown complete"
    exit 0
}

trap cleanup SIGTERM SIGINT EXIT

# 1. Start ComfyUI in background
echo "Starting ComfyUI..."
cd /comfyui || cd /app/ComfyUI || { echo "ComfyUI directory not found"; exit 1; }
python3 main.py --listen 0.0.0.0 --port 8188 > /var/log/comfyui.log 2>&1 &
COMFYUI_PID=$!
echo "ComfyUI started (PID: $COMFYUI_PID)"

# 2. Wait for ComfyUI to be ready
echo "Waiting for ComfyUI to be ready..."
MAX_WAIT=60
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    if curl -sf http://localhost:8188/system_stats > /dev/null 2>&1; then
        echo "ComfyUI is ready!"
        break
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

if [ $ELAPSED -ge $MAX_WAIT ]; then
    echo "ERROR: ComfyUI failed to start within ${MAX_WAIT}s"
    echo "ComfyUI logs:"
    tail -50 /var/log/comfyui.log
    exit 1
fi

# 3. Start Health Server in background
echo "Starting Health Server on port ${HEALTH_PORT:-8000}..."
cd /app || { echo "App directory not found"; exit 1; }
python3 health_server.py > /var/log/health.log 2>&1 &
HEALTH_PID=$!
echo "Health Server started (PID: $HEALTH_PID)"

# 4. Wait for Health Server to be ready
echo "Waiting for Health Server to be ready..."
sleep 3
if ! curl -sf http://localhost:${HEALTH_PORT:-8000}/health > /dev/null 2>&1; then
    echo "WARNING: Health Server may not be ready"
    echo "Health Server logs:"
    tail -20 /var/log/health.log
fi

# 5. Start Worker (foreground - main process)
echo "Starting Worker in serverless mode..."
echo "======================================"
cd /app || { echo "App directory not found"; exit 1; }
exec python3 worker.py
