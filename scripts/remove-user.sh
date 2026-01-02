#!/bin/bash
set -e

# ComfyUI Workshop Platform - Remove User Script
# ===============================================

if [ -z "$1" ]; then
    echo "Usage: ./scripts/remove-user.sh <user_id>"
    echo "Example: ./scripts/remove-user.sh user021"
    exit 1
fi

USER_ID=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "Removing user: $USER_ID"
echo "========================================"

# Check if user exists
if ! docker-compose ps | grep -q "comfy-$USER_ID"; then
    echo "❌ User $USER_ID does not exist"
    exit 1
fi

# Ask for confirmation
read -p "Remove user data? (y/N): " -n 1 -r
echo

# Stop and remove container
echo "🛑 Stopping container..."
docker-compose stop "$USER_ID" 2>/dev/null || true
docker-compose rm -f "$USER_ID" 2>/dev/null || true

# Remove service file if it exists
SERVICE_FILE="docker-compose.user-$USER_ID.yml"
if [ -f "$SERVICE_FILE" ]; then
    rm "$SERVICE_FILE"
    echo "✅ Service file removed"
fi

# Remove user data if confirmed
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Removing user data..."
    rm -rf "data/outputs/$USER_ID"
    rm -rf "data/inputs/$USER_ID"
    rm -rf "data/models/user/$USER_ID"
    echo "✅ User data removed"
fi

echo ""
echo "✅ User $USER_ID removed successfully!"
echo "========================================"
echo ""
