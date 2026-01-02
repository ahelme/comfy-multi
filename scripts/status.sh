#!/bin/bash
set -e

# ComfyUI Workshop Platform - Status Script
# ==========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "📊 ComfyUI Workshop Platform Status"
echo "=========================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "⚠️  No .env file found. Platform not configured."
    exit 1
fi

# Source environment variables
set -a
source .env 2>/dev/null || true
set +a

# Container status
echo "🐳 Docker Containers:"
docker-compose ps
echo ""

# Service health checks
echo "🏥 Health Checks:"
echo ""

# Check Redis
echo -n "   Redis: "
if docker-compose exec -T redis redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q "PONG"; then
    echo "✅ Healthy"
else
    echo "❌ Unhealthy"
fi

# Check Queue Manager
echo -n "   Queue Manager: "
if curl -sf http://localhost:${QUEUE_MANAGER_PORT:-3000}/health > /dev/null 2>&1; then
    echo "✅ Healthy"
else
    echo "❌ Unhealthy"
fi

# Check Nginx
echo -n "   Nginx: "
if curl -sf -k https://localhost/health > /dev/null 2>&1; then
    echo "✅ Healthy"
else
    echo "❌ Unhealthy"
fi

echo ""

# Queue status (if queue manager is running)
echo "📋 Queue Status:"
QUEUE_STATUS=$(curl -sf http://localhost:${QUEUE_MANAGER_PORT:-3000}/api/queue/status 2>/dev/null || echo "{}")
if [ "$QUEUE_STATUS" != "{}" ]; then
    echo "$QUEUE_STATUS" | jq '.' 2>/dev/null || echo "$QUEUE_STATUS"
else
    echo "   Queue manager not responding"
fi

echo ""

# Resource usage
echo "💾 Resource Usage:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker-compose ps -q)

echo ""
echo "=========================================="
