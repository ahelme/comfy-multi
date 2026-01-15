#!/bin/bash
# QUICK-START - Daily worker startup script for Verda GPU instances
# Save this on SFS alongside worker-image.tar.gz
#
# Usage: sudo bash quick-start.sh <sfs-endpoint>
# Example: sudo bash quick-start.sh 10.0.0.5

set -e

SFS_ENDPOINT="${1:-}"

if [ -z "$SFS_ENDPOINT" ]; then
    echo "Usage: sudo bash quick-start.sh <sfs-endpoint>"
    echo "Example: sudo bash quick-start.sh 10.0.0.5"
    exit 1
fi

echo "🚀 QUICK-START: Verda GPU Worker"
echo "================================="
echo ""

# Step 1: Add mello's SSH key (if not already there)
echo "Step 1: Ensuring mello SSH access..."
MELLO_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiwaT6NQcHe7cYDKB5LrtmyIU0O8iRc7DJUmZJsNkDD dev@vps-for-verda"

mkdir -p /root/.ssh
chmod 700 /root/.ssh

if ! grep -q "dev@vps-for-verda" /root/.ssh/authorized_keys 2>/dev/null; then
    echo "$MELLO_KEY" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "  ✓ Mello SSH key added to root"
else
    echo "  ✓ Mello SSH key already present"
fi

# Also add for dev user if exists
if id dev &>/dev/null; then
    mkdir -p /home/dev/.ssh
    chmod 700 /home/dev/.ssh
    if ! grep -q "dev@vps-for-verda" /home/dev/.ssh/authorized_keys 2>/dev/null; then
        echo "$MELLO_KEY" >> /home/dev/.ssh/authorized_keys
        chmod 600 /home/dev/.ssh/authorized_keys
        chown -R dev:dev /home/dev/.ssh
        echo "  ✓ Mello SSH key added to dev user"
    else
        echo "  ✓ Mello SSH key already present for dev"
    fi
fi
echo ""

# Step 2: Install NFS client if needed
echo "Step 2: Checking NFS client..."
if ! command -v mount.nfs &>/dev/null; then
    apt-get update && apt-get install -y nfs-common
    echo "  ✓ NFS client installed"
else
    echo "  ✓ NFS client already installed"
fi
echo ""

# Step 3: Mount SFS
echo "Step 3: Mounting SFS..."
mkdir -p /mnt/models

if mountpoint -q /mnt/models; then
    echo "  ✓ /mnt/models already mounted"
else
    if mount -t nfs "$SFS_ENDPOINT":/share /mnt/models; then
        echo "  ✓ SFS mounted at /mnt/models"
    else
        echo "  ✗ Failed to mount SFS"
        echo "  Check endpoint: $SFS_ENDPOINT"
        exit 1
    fi
fi
echo ""

# Step 4: Verify models exist
echo "Step 4: Verifying models..."
if [ -f /mnt/models/checkpoints/ltx-2-19b-dev-fp8.safetensors ]; then
    echo "  ✓ LTX-2 checkpoint found"
else
    echo "  ⚠️  Models not found - run RESTORE.sh --with-models first"
fi
echo ""

# Step 5: Load container image
echo "Step 5: Loading worker container..."
CONTAINER_IMAGE="/mnt/models/worker-image.tar.gz"

if [ -f "$CONTAINER_IMAGE" ]; then
    IMAGE_SIZE=$(du -h "$CONTAINER_IMAGE" | cut -f1)
    echo "  Loading $IMAGE_SIZE image..."

    if docker load < "$CONTAINER_IMAGE"; then
        echo "  ✓ Container loaded!"
        docker images | grep -E "comfy|worker" | head -3
    else
        echo "  ✗ Failed to load container"
        exit 1
    fi
else
    echo "  ⚠️  Container image not found at $CONTAINER_IMAGE"
    echo "  Run RESTORE.sh --build-container first"
    exit 1
fi
echo ""

# Step 6: Create symlinks for ComfyUI
echo "Step 6: Setting up symlinks..."
if id dev &>/dev/null; then
    mkdir -p /home/dev/comfy-multi/data
    ln -sf /mnt/models /home/dev/comfy-multi/data/models 2>/dev/null || true
    mkdir -p /mnt/scratch
    ln -sf /mnt/scratch /home/dev/comfy-multi/data/outputs 2>/dev/null || true
    chown -R dev:dev /home/dev/comfy-multi/data /mnt/scratch
    echo "  ✓ Symlinks created"
fi
echo ""

# Step 7: Start worker
echo "Step 7: Starting worker..."
if [ -f /home/dev/comfy-multi/docker-compose.yml ]; then
    cd /home/dev/comfy-multi

    # Source .env if exists
    [ -f .env ] && source .env

    if sudo -u dev docker compose up -d worker-1; then
        echo "  ✓ Worker started!"
    else
        echo "  ⚠️  Failed to start worker - check docker compose logs"
    fi
else
    echo "  ⚠️  docker-compose.yml not found"
    echo "  Clone the repo first or run RESTORE.sh"
fi
echo ""

echo "================================="
echo "✅ QUICK-START COMPLETE!"
echo ""
echo "Check worker status:"
echo "  docker ps"
echo "  docker logs comfy-multi-worker-1"
echo ""
echo "Connect from mello:"
echo "  ssh dev@<this-instance-ip>"
echo "================================="
