#!/bin/bash
#
# Quick deployment script for comfy.ahelme.net VPS
#
# Usage: ./scripts/deploy-vps.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=================================================="
echo "  ComfyUI Platform - VPS Deployment"
echo "  Domain: comfy.ahelme.net"
echo "=================================================="
echo ""

cd "$PROJECT_DIR"

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "   Please create .env from .env.example"
    exit 1
fi

# Source .env
source .env

echo "📋 Pre-flight Checks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not installed"
    echo "   Install: curl -fsSL https://get.docker.com | sh"
    exit 1
fi
echo "✅ Docker installed"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose not installed"
    exit 1
fi
echo "✅ Docker Compose installed"

# Check SSL certificates
if [ ! -f "$SSL_CERT_PATH" ]; then
    echo "❌ SSL certificate not found: $SSL_CERT_PATH"
    echo "   Update SSL_CERT_PATH in .env"
    exit 1
fi
echo "✅ SSL certificate found"

if [ ! -f "$SSL_KEY_PATH" ]; then
    echo "❌ SSL key not found: $SSL_KEY_PATH"
    echo "   Update SSL_KEY_PATH in .env"
    exit 1
fi
echo "✅ SSL key found"

# Check domain
echo ""
echo "🌐 Domain Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   Domain: $DOMAIN"
echo ""

# Check DNS
if command -v dig &> /dev/null; then
    DNS_IP=$(dig +short "$DOMAIN" | head -n1)
    if [ ! -z "$DNS_IP" ]; then
        echo "✅ DNS resolves to: $DNS_IP"
    else
        echo "⚠️  DNS not resolving yet (this is OK if you just added the record)"
    fi
else
    echo "ℹ️  Install 'dig' to verify DNS: sudo apt-get install dnsutils"
fi

# Check passwords
echo ""
echo "🔐 Security Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$REDIS_PASSWORD" = "changeme_secure_password" ] || [ "$REDIS_PASSWORD" = "comfy_redis_secure_$(openssl rand -hex 16)" ]; then
    echo "⚠️  REDIS_PASSWORD still set to default!"
    echo "   Please update in .env before deploying to production"
fi

if [ "$ADMIN_PASSWORD" = "change_me_secure_password" ]; then
    echo "⚠️  ADMIN_PASSWORD still set to default!"
    echo "   Please update in .env before deploying to production"
fi

echo ""
read -p "Continue with deployment? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Create directories
echo ""
echo "📁 Creating Directories"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

mkdir -p data/models/shared/checkpoints
mkdir -p data/models/shared/vae
mkdir -p data/models/shared/loras
mkdir -p data/models/custom
mkdir -p data/outputs
mkdir -p data/inputs
mkdir -p data/workflows

# Create user output directories
for i in $(seq 1 ${NUM_USERS:-20}); do
    USER_ID=$(printf "user%03d" $i)
    mkdir -p data/outputs/$USER_ID
done

echo "✅ Directories created"

# Check if services are already running
if docker-compose ps | grep -q "Up"; then
    echo ""
    echo "⚠️  Services already running!"
    read -p "   Restart services? (y/N): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping services..."
        docker-compose down
    else
        echo "Keeping existing services running"
        exit 0
    fi
fi

# Pull images
echo ""
echo "📦 Pulling Docker Images"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker-compose pull

# Build custom images
echo ""
echo "🔨 Building Custom Images"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker-compose build

# Start services
echo ""
echo "🚀 Starting Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker-compose up -d

# Wait for services to be ready
echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check health
echo ""
echo "🏥 Health Checks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Redis
if docker-compose exec -T redis redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q "PONG"; then
    echo "✅ Redis"
else
    echo "❌ Redis not responding"
fi

# Queue Manager
sleep 5
QUEUE_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${QUEUE_MANAGER_PORT:-3000}/health)
if [ "$QUEUE_HEALTH" = "200" ]; then
    echo "✅ Queue Manager"
else
    echo "⚠️  Queue Manager (HTTP $QUEUE_HEALTH) - may still be starting"
fi

# Admin
ADMIN_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${ADMIN_PORT:-8080}/health)
if [ "$ADMIN_HEALTH" = "200" ]; then
    echo "✅ Admin Dashboard"
else
    echo "⚠️  Admin Dashboard (HTTP $ADMIN_HEALTH) - may still be starting"
fi

# Display results
echo ""
echo "=================================================="
echo "  ✅ Deployment Complete!"
echo "=================================================="
echo ""
echo "Access Points:"
echo "  🌐 Landing Page:    https://$DOMAIN/"
echo "  🏥 Health Check:    https://$DOMAIN/health"
echo "  🎛️  Admin Dashboard: https://$DOMAIN/admin"
echo "  👥 User Workspaces: https://$DOMAIN/user001/ - user020/"
echo "  🔌 API:             https://$DOMAIN/api/"
echo ""
echo "Management:"
echo "  Status:  ./scripts/status.sh"
echo "  Logs:    docker-compose logs -f"
echo "  Stop:    docker-compose down"
echo "  Restart: docker-compose restart"
echo ""
echo "Next Steps:"
echo "  1. Download models: cd data/models/shared/checkpoints/"
echo "  2. Test platform:   ./scripts/test.sh"
echo "  3. Load test:       ./scripts/load-test.sh 5 1"
echo ""
echo "Admin Credentials:"
echo "  Username: $ADMIN_USERNAME"
echo "  Password: (set in .env)"
echo ""
echo "Documentation: See DEPLOYMENT.md for details"
echo ""
