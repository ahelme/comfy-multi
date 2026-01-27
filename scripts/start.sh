#!/bin/bash
set -e

# ComfyUI Workshop Platform - Start Script
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "🚀 Starting ComfyUI Workshop Platform..."
echo "=========================================="

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  No .env file found. Creating from .env.example..."
    cp .env.example .env
    echo "✅ Created .env file. Please edit it with your configuration before starting."
    echo "   Required: DOMAIN, SSL_CERT_PATH, SSL_KEY_PATH, REDIS_PASSWORD"
    exit 1
fi

# Source environment variables
set -a
source .env
set +a

# Validate required variables
REQUIRED_VARS=("DOMAIN" "SSL_CERT_PATH" "SSL_KEY_PATH" "REDIS_PASSWORD")
MISSING_VARS=()

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        MISSING_VARS+=("$var")
    fi
done

if [ ${#MISSING_VARS[@]} -gt 0 ]; then
    echo "❌ Missing required environment variables:"
    for var in "${MISSING_VARS[@]}"; do
        echo "   - $var"
    done
    echo ""
    echo "Please edit .env and set these variables."
    exit 1
fi

# Check SSL certificates
if [ ! -f "$SSL_CERT_PATH" ]; then
    echo "❌ SSL certificate not found: $SSL_CERT_PATH"
    exit 1
fi

if [ ! -f "$SSL_KEY_PATH" ]; then
    echo "❌ SSL key not found: $SSL_KEY_PATH"
    exit 1
fi

echo "✅ Configuration validated"
echo ""

# Create data directories if they don't exist
echo "📁 Creating data directories..."
mkdir -p data/models/shared data/models/user data/outputs data/inputs data/workflows
echo "✅ Data directories ready"
echo ""

# Start services
echo "🐳 Starting Docker containers..."
docker-compose up -d

# Ensure all containers have restart policy set
echo "🔄 Setting restart policy on containers..."
sudo docker update --restart=unless-stopped $(sudo docker ps -q --filter "name=comfy") 2>/dev/null || true

echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 5

# Check service health
echo ""
echo "🔍 Service Status:"
docker-compose ps

echo ""
echo "✅ ComfyUI Workshop Platform is running!"
echo "=========================================="
echo ""
echo "📍 Access Points:"
echo "   • Landing Page: https://${DOMAIN}/"
echo "   • Admin Dashboard: https://${DOMAIN}/admin"
echo "   • API: https://${DOMAIN}/api/health"
echo ""
echo "👥 User Workspaces:"
for i in $(seq 1 ${NUM_USERS:-20}); do
    USER_ID=$(printf "user%03d" $i)
    echo "   • https://${DOMAIN}/${USER_ID}/"
done
echo ""
echo "📊 Management Commands:"
echo "   • View logs: docker-compose logs -f"
echo "   • Stop platform: ./scripts/stop.sh"
echo "   • Check status: ./scripts/status.sh"
echo ""
