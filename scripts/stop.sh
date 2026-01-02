#!/bin/bash
set -e

# ComfyUI Workshop Platform - Stop Script
# ========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "🛑 Stopping ComfyUI Workshop Platform..."
echo "=========================================="

# Ask about data preservation
read -p "Do you want to preserve data volumes? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "📦 Stopping containers (preserving volumes)..."
    docker-compose down
else
    echo "🗑️  Stopping containers and removing volumes..."
    docker-compose down -v
    echo "⚠️  All data has been deleted!"
fi

echo ""
echo "✅ Platform stopped successfully"
