#!/bin/bash
# QUICK-START - Daily worker startup script for Verda GPU instances
#
# Usage:
#   sudo bash quick-start.sh                    # Auto-detect SFS
#   sudo bash quick-start.sh <sfs-endpoint>     # Manual endpoint
#
# Example: sudo bash quick-start.sh nfs.fin-01.datacrunch.io:/SFS-Model-Vault-273f8ad9

set -e

echo ">>> QUICK-START: Verda GPU Worker"
echo "================================="
echo ""

# Step 0: Detect or use provided SFS endpoint
echo "Step 0: Finding SFS mount..."
SFS_ENDPOINT="${1:-}"
SFS_MOUNT="/mnt/models"

# Check if already mounted
if mountpoint -q "$SFS_MOUNT" 2>/dev/null; then
    echo "  OK $SFS_MOUNT already mounted"
    SFS_READY=true
elif mountpoint -q /mnt/SFS-Model-Vault 2>/dev/null; then
    echo "  OK /mnt/SFS-Model-Vault already mounted"
    SFS_MOUNT="/mnt/SFS-Model-Vault"
    SFS_READY=true
else
    SFS_READY=false

    # If no endpoint provided, try to auto-detect
    if [ -z "$SFS_ENDPOINT" ]; then
        echo "  Checking for Verda auto-mounted SFS..."

        # Check common Verda SFS mount locations
        for dir in /mnt/SFS-* /mnt/sfs-* /mnt/models; do
            if [ -d "$dir" ] && mountpoint -q "$dir" 2>/dev/null; then
                SFS_MOUNT="$dir"
                SFS_READY=true
                echo "  OK Found SFS at $SFS_MOUNT"
                break
            fi
        done

        # Check if NFS is mounted anywhere
        if [ "$SFS_READY" = false ]; then
            NFS_MOUNT=$(mount | grep nfs | head -1 | awk '{print $3}')
            if [ -n "$NFS_MOUNT" ]; then
                SFS_MOUNT="$NFS_MOUNT"
                SFS_READY=true
                echo "  OK Found NFS mount at $SFS_MOUNT"
            fi
        fi

        # Still not found - check Verda's mount info
        if [ "$SFS_READY" = false ]; then
            # Look for SFS mount command in Verda's provisioning
            if [ -f /etc/fstab ]; then
                SFS_LINE=$(grep -E "nfs.*SFS" /etc/fstab 2>/dev/null | head -1)
                if [ -n "$SFS_LINE" ]; then
                    SFS_ENDPOINT=$(echo "$SFS_LINE" | awk '{print $1}')
                    echo "  Found SFS in fstab: $SFS_ENDPOINT"
                fi
            fi
        fi
    fi

    # If still no endpoint, add login reminder and show helpful message
    if [ "$SFS_READY" = false ] && [ -z "$SFS_ENDPOINT" ]; then
        # Add MOTD reminder for next login
        cat > /etc/motd << 'MOTD'

+-----------------------------------------------------------------------+
|  SFS NOT MOUNTED - ACTION REQUIRED                                    |
+-----------------------------------------------------------------------+
|                                                                       |
|  1. Get PSEUDOPATH from Verda Dashboard:                              |
|     Storage tab -> Click dropdown on SFS-Model-Vault -> PSEUDOPATH    |
|     Example: nfs.fin-01.datacrunch.io:/SFS-Model-Vault-273f8ad9       |
|                                                                       |
|  2. Create mount point:                                               |
|     mkdir -p /mnt/models                                              |
|                                                                       |
|  3. Mount SFS (replace <PSEUDOPATH> with value from step 1):          |
|     mount -t nfs -o nconnect=16 <PSEUDOPATH> /mnt/models              |
|                                                                       |
|  4. Run quick-start again:                                            |
|     bash /root/quick-start.sh                                         |
|                                                                       |
+-----------------------------------------------------------------------+

MOTD

        # Also save script to /root for easy access
        cp "$0" /root/quick-start.sh 2>/dev/null || true

        echo ""
        echo "  !! SFS not detected. Please provide the endpoint:"
        echo ""
        echo "  Usage: sudo bash quick-start.sh <sfs-endpoint>"
        echo "  Example: sudo bash quick-start.sh nfs.fin-01.datacrunch.io:/SFS-Model-Vault-273f8ad9"
        echo ""
        echo "  Find your endpoint in Verda Dashboard -> SFS -> Mount command"
        echo ""
        echo "  A reminder has been added to /etc/motd (shown on next login)"
        echo ""
        exit 1
    fi
fi
echo ""

# Step 1: Add mello's SSH key (if not already there)
echo "Step 1: Ensuring mello SSH access..."
MELLO_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiwaT6NQcHe7cYDKB5LrtmyIU0O8iRc7DJUmZJsNkDD dev@vps-for-verda"

mkdir -p /root/.ssh
chmod 700 /root/.ssh

if ! grep -q "dev@vps-for-verda" /root/.ssh/authorized_keys 2>/dev/null; then
    echo "$MELLO_KEY" >> /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "  OK Mello SSH key added to root"
else
    echo "  OK Mello SSH key already present"
fi

# Also add for dev user if exists
if id dev &>/dev/null; then
    mkdir -p /home/dev/.ssh
    chmod 700 /home/dev/.ssh
    if ! grep -q "dev@vps-for-verda" /home/dev/.ssh/authorized_keys 2>/dev/null; then
        echo "$MELLO_KEY" >> /home/dev/.ssh/authorized_keys
        chmod 600 /home/dev/.ssh/authorized_keys
        chown -R dev:dev /home/dev/.ssh
        echo "  OK Mello SSH key added to dev user"
    else
        echo "  OK Mello SSH key already present for dev"
    fi
fi
echo ""

# Step 2: Install NFS client if needed
echo "Step 2: Checking NFS client..."
if ! command -v mount.nfs &>/dev/null; then
    apt-get update -qq && apt-get install -y -qq nfs-common
    echo "  OK NFS client installed"
else
    echo "  OK NFS client already installed"
fi
echo ""

# Step 3: Mount SFS (if not already mounted)
echo "Step 3: Mounting SFS..."
if [ "$SFS_READY" = true ]; then
    echo "  OK SFS already mounted at $SFS_MOUNT"
else
    mkdir -p "$SFS_MOUNT"

    # Try mounting with nconnect for better performance
    if mount -t nfs -o nconnect=16 "$SFS_ENDPOINT" "$SFS_MOUNT" 2>/dev/null; then
        echo "  OK SFS mounted at $SFS_MOUNT (nconnect=16)"
    elif mount -t nfs "$SFS_ENDPOINT" "$SFS_MOUNT"; then
        echo "  OK SFS mounted at $SFS_MOUNT"
    else
        echo "  FAIL Failed to mount SFS"
        echo "  Endpoint: $SFS_ENDPOINT"
        echo "  Check: Is the SFS attached to this instance in Verda Dashboard?"
        exit 1
    fi
fi
echo ""

# Step 4: Check for restore scripts
echo "Step 4: Checking restore scripts..."
MELLO_HOST="dev@comfy.ahelme.net"
MELLO_BACKUP_DIR="/home/dev/backups/verda"

if [ -f /root/RESTORE-SFS.sh ] && [ -f /root/RESTORE-BLOCK-MELLO.sh ]; then
    chmod +x /root/RESTORE-SFS.sh /root/RESTORE-BLOCK-MELLO.sh 2>/dev/null || true
    echo "  OK Restore scripts found in /root/"
else
    echo "  !! Restore scripts not found"
    echo ""
    echo "  Run this FROM MELLO to push restore scripts:"
    echo "  scp $MELLO_BACKUP_DIR/RESTORE-*.sh $MELLO_BACKUP_DIR/README-RESTORE.md root@$(hostname -I | awk '{print $1}'):/root/"
    echo ""
fi
echo ""

# Step 5: Verify models exist
echo "Step 5: Verifying models..."
if [ -f "$SFS_MOUNT/checkpoints/ltx-2-19b-dev-fp8.safetensors" ]; then
    echo "  OK LTX-2 checkpoint found"
else
    echo "  !! Models not found on SFS"
    echo "  Run: bash /root/RESTORE-SFS.sh --full"
fi
echo ""

# Step 6: Load container image
echo "Step 6: Loading worker container..."
CONTAINER_IMAGE="$SFS_MOUNT/worker-image.tar.gz"
MELLO_HOST="dev@comfy.ahelme.net"
MELLO_BACKUP="/home/dev/backups/verda/worker-image.tar.gz"

# Check if container already loaded
if docker images | grep -q "comfyui-worker"; then
    echo "  OK Container already loaded"
    docker images | grep -E "comfy|worker" | head -3
elif [ -f "$CONTAINER_IMAGE" ]; then
    IMAGE_SIZE=$(du -h "$CONTAINER_IMAGE" | cut -f1)
    echo "  Loading $IMAGE_SIZE image from SFS..."

    if docker load < "$CONTAINER_IMAGE"; then
        echo "  OK Container loaded!"
        docker images | grep -E "comfy|worker" | head -3
    else
        echo "  FAIL Failed to load container"
        exit 1
    fi
else
    echo "  !! Container image not on SFS"
    echo "  Run: bash /root/RESTORE-SFS.sh --with-container"
fi
echo ""

# Step 7: Create symlinks for ComfyUI
echo "Step 7: Setting up symlinks..."
mkdir -p /home/dev/comfy-multi/data 2>/dev/null || true
ln -sf "$SFS_MOUNT" /home/dev/comfy-multi/data/models 2>/dev/null || true
mkdir -p /mnt/scratch 2>/dev/null || true
ln -sf /mnt/scratch /home/dev/comfy-multi/data/outputs 2>/dev/null || true

if id dev &>/dev/null; then
    chown -R dev:dev /home/dev/comfy-multi/data /mnt/scratch 2>/dev/null || true
fi
echo "  OK Symlinks created"
echo ""

# Step 8: Check for comfy-multi project
echo "Step 8: Checking project setup..."
if [ -f /home/dev/comfy-multi/docker-compose.yml ]; then
    echo "  OK comfy-multi project found"
else
    echo "  !! comfy-multi project not found"
    echo "  Run: bash /root/RESTORE-BLOCK-MELLO.sh (for full system restore)"
fi
echo ""

# Clear the MOTD reminder since SFS is now mounted
if [ -f /etc/motd ] && grep -q "SFS NOT MOUNTED" /etc/motd 2>/dev/null; then
    echo "" > /etc/motd
fi

echo "================================="
echo "QUICK-START COMPLETE!"
echo ""
echo "SFS mounted at: $SFS_MOUNT"
echo ""
echo "Restore scripts in /root/:"
echo "  - RESTORE-SFS.sh --full      (populate SFS: models + container)"
echo "  - RESTORE-BLOCK-MELLO.sh     (full system restore from mello)"
echo "  - README-RESTORE.md          (which script to use when)"
echo ""
echo "Next steps:"
echo "  If models/container missing: bash /root/RESTORE-SFS.sh --full"
echo "  If all ready: cd ~/comfy-multi && docker compose up -d worker-1"
echo ""
echo "Connect from mello:"
echo "  ssh root@$(hostname -I | awk '{print $1}')"
echo "================================="
