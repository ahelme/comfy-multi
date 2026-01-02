#!/bin/bash
set -e

# ComfyUI Workshop Platform - List Users Script
# ==============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "📋 ComfyUI Workshop Users"
echo "========================================"
echo ""

# Get running user containers
RUNNING=$(docker-compose ps --filter "name=comfy-user" --format "table {{.Name}}\t{{.Status}}" 2>/dev/null || echo "")

if [ -z "$RUNNING" ]; then
    echo "No user containers running"
else
    echo "Running Containers:"
    echo "$RUNNING"
fi

echo ""
echo "--------------------------------------"
echo ""

# List user data directories
echo "User Data Directories:"
if [ -d "data/outputs" ]; then
    ls -1 data/outputs/ | while read -r user; do
        if [ -d "data/outputs/$user" ]; then
            SIZE=$(du -sh "data/outputs/$user" 2>/dev/null | cut -f1)
            echo "  • $user - Outputs: $SIZE"
        fi
    done
else
    echo "  No user data found"
fi

echo ""
echo "========================================"
echo ""
