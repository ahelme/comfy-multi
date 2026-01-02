#!/bin/bash
set -e

# ComfyUI Workshop Platform - Add User Script
# ============================================

if [ -z "$1" ]; then
    echo "Usage: ./scripts/add-user.sh <user_id>"
    echo "Example: ./scripts/add-user.sh user021"
    exit 1
fi

USER_ID=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "Adding user: $USER_ID"
echo "========================================"

# Check if user already exists
if docker-compose ps | grep -q "comfy-$USER_ID"; then
    echo "❌ User $USER_ID already exists"
    exit 1
fi

# Create user directories
echo "📁 Creating user directories..."
mkdir -p "data/outputs/$USER_ID"
mkdir -p "data/inputs/$USER_ID"
mkdir -p "data/models/user/$USER_ID"

# Generate docker-compose service
SERVICE_FILE="docker-compose.user-$USER_ID.yml"

cat > "$SERVICE_FILE" <<EOF
version: '3.8'

services:
  $USER_ID:
    build:
      context: ./comfyui-frontend
      dockerfile: Dockerfile
    container_name: comfy-$USER_ID
    environment:
      - USER_ID=$USER_ID
      - QUEUE_MANAGER_URL=http://queue-manager:3000
    volumes:
      - \${OUTPUTS_PATH}:/outputs
      - \${INPUTS_PATH}:/inputs
      - \${WORKFLOWS_PATH}:/workflows:ro
      - \${MODELS_PATH}:/models:ro
    networks:
      - comfy-network
    restart: unless-stopped
EOF

echo "✅ Service file created: $SERVICE_FILE"

# Start the service
echo "🚀 Starting user service..."
docker-compose -f docker-compose.yml -f docker-compose.override.yml -f "$SERVICE_FILE" up -d "$USER_ID"

echo ""
echo "✅ User $USER_ID added successfully!"
echo "========================================"
echo "Access URL: https://\${DOMAIN}/$USER_ID/"
echo ""
