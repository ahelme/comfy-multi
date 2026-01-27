#!/bin/bash
# =============================================================================
# Deploy ComfyUI Worker Serverless Container to Verda
# =============================================================================
# This script helps deploy the serverless worker container to Verda.
# Prerequisites:
#   - Docker installed and running
#   - GitHub CLI (gh) or manual image push
#   - Verda account with API key
#   - Queue Manager running on VPS (comfy.ahelme.net)
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "======================================"
echo "Verda Serverless Deployment"
echo "======================================"

# Load environment if .env exists
if [ -f "$PROJECT_DIR/.env" ]; then
    echo "Loading configuration from .env..."
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

# Configuration
IMAGE_NAME="${CONTAINER_IMAGE_NAME:-ghcr.io/ahelme/comfyui-worker-serverless}"
IMAGE_TAG="${CONTAINER_IMAGE_TAG:-latest}"
FULL_IMAGE="$IMAGE_NAME:$IMAGE_TAG"

QUEUE_MANAGER_URL="${QUEUE_MANAGER_URL:-https://comfy.ahelme.net}"
VERDA_API_KEY="${VERDA_API_KEY:-}"

echo ""
echo "Configuration:"
echo "  Image: $FULL_IMAGE"
echo "  Queue Manager: $QUEUE_MANAGER_URL"
echo "  Verda API Key: ${VERDA_API_KEY:0:10}..."
echo ""

# Step 1: Build Docker image
echo "Step 1: Building Docker image..."
cd "$PROJECT_DIR"
docker build -f comfyui-worker/Dockerfile.serverless -t "$FULL_IMAGE" comfyui-worker/

if [ $? -ne 0 ]; then
    echo "ERROR: Docker build failed"
    exit 1
fi
echo "✓ Image built successfully"

# Step 2: Push to container registry
echo ""
echo "Step 2: Push image to registry..."
echo "Choose push method:"
echo "  1) GitHub Container Registry (ghcr.io) - Recommended"
echo "  2) Docker Hub"
echo "  3) Skip (already pushed)"
read -p "Enter choice [1-3]: " PUSH_CHOICE

case $PUSH_CHOICE in
    1)
        echo "Pushing to GitHub Container Registry..."
        echo "You may need to authenticate: echo \$GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin"
        docker push "$FULL_IMAGE"
        ;;
    2)
        echo "Pushing to Docker Hub..."
        DOCKERHUB_IMAGE="ahelme/comfyui-worker-serverless:$IMAGE_TAG"
        docker tag "$FULL_IMAGE" "$DOCKERHUB_IMAGE"
        docker push "$DOCKERHUB_IMAGE"
        ;;
    3)
        echo "Skipping image push"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo "✓ Image available in registry"

# Step 3: Deploy to Verda
echo ""
echo "Step 3: Deploy to Verda..."
echo ""
echo "Deployment options:"
echo "  1) Deploy via Verda Web Console (Manual)"
echo "  2) Deploy via Verda Python SDK (Automatic)"
echo "  3) View deployment instructions only"
read -p "Enter choice [1-3]: " DEPLOY_CHOICE

case $DEPLOY_CHOICE in
    1)
        echo ""
        echo "Manual Deployment Steps:"
        echo ""
        echo "1. Log in to Verda Console: https://verda.com/console"
        echo "2. Navigate to: Containers → Deploy New Container"
        echo "3. Configure container:"
        echo "   - Name: comfyui-worker-serverless"
        echo "   - Image: $FULL_IMAGE"
        echo "   - GPU: H100 (1x)"
        echo "   - Min replicas: 0"
        echo "   - Max replicas: 5"
        echo "   - Health check: HTTP GET /health on port 8000"
        echo "4. Add environment variables:"
        echo "   - QUEUE_MANAGER_URL=$QUEUE_MANAGER_URL"
        echo "   - SERVERLESS_MODE=true"
        echo "   - SERVERLESS_MAX_IDLE_POLLS=10"
        echo "   - SERVERLESS_JOB_LIMIT=1"
        echo "5. Attach SFS volumes:"
        echo "   - Models: /models (read-only)"
        echo "   - Outputs: /outputs"
        echo "6. Click 'Deploy'"
        echo ""
        ;;
    2)
        if [ -z "$VERDA_API_KEY" ]; then
            echo "ERROR: VERDA_API_KEY not set in .env"
            echo "Set VERDA_API_KEY and try again"
            exit 1
        fi

        echo "Installing Verda Python SDK..."
        pip3 install datacrunch-python

        echo "Deploying via SDK..."
        python3 << EOF
from datacrunch import DataCrunchClient
import os

client = DataCrunchClient(api_key=os.getenv('VERDA_API_KEY'))

# Deploy container
deployment = client.containers.deploy(
    name='comfyui-worker-serverless',
    image='$FULL_IMAGE',
    gpu_type='H100',
    gpu_count=1,
    cpu_cores=4,
    memory_gb=32,
    min_replicas=0,
    max_replicas=5,
    health_check_path='/health',
    health_check_port=8000,
    environment={
        'QUEUE_MANAGER_URL': '$QUEUE_MANAGER_URL',
        'SERVERLESS_MODE': 'true',
        'SERVERLESS_MAX_IDLE_POLLS': '10',
        'SERVERLESS_JOB_LIMIT': '1',
        'INFERENCE_PROVIDER': 'verda-serverless',
    }
)

print(f"Deployment created: {deployment.id}")
print(f"Endpoint: {deployment.endpoint}")
EOF
        ;;
    3)
        echo ""
        echo "See deployment instructions: docs/admin-verda-serverless.md"
        ;;
esac

echo ""
echo "======================================"
echo "Deployment Complete!"
echo "======================================"
echo ""
echo "Next steps:"
echo "1. Verify container health: curl https://<verda-endpoint>/health"
echo "2. Submit test job via Queue Manager"
echo "3. Monitor container scaling in Verda Console"
echo "4. Check logs for any errors"
echo ""
echo "For troubleshooting, see: docs/admin-verda-serverless.md"
echo ""
