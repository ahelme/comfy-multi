#!/bin/bash
# RESTORE-SFS - Populate Verda SFS with models and container from R2/mello
# Run on Verda GPU instance AFTER quick-start.sh has mounted SFS
#
# Usage: sudo bash RESTORE-SFS.sh [OPTIONS]
#   --with-models      Download models from R2 (~45GB, ~30 min)
#   --with-container   Copy container tarball from mello (~2.6GB)
#   --full             Both models and container (recommended for fresh SFS)
#   --skip-models      Skip model download (use existing)
#   --skip-container   Skip container copy (use existing)
#
# Prerequisites:
#   - SFS mounted at /mnt/models (run quick-start.sh first)
#   - AWS CLI installed (script will install if missing)
#   - SSH access to mello (for container copy)

set -e

# ============================================================================
# Configuration
# ============================================================================

SFS_MOUNT="${SFS_MOUNT:-/mnt/models}"
MELLO_HOST="dev@comfy.ahelme.net"
MELLO_CONTAINER="/home/dev/backups/verda/worker-image.tar.gz"

# R2 Configuration
R2_ENDPOINT="https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com"
R2_BUCKET="comfy-multi-model-vault-backup"
R2_ACCESS_KEY_ID="32c4d03bddf7759afa04daf0e9725ab4"
R2_SECRET_ACCESS_KEY="cc763dfc25213320f2a754ad1035a31d776094b6494aa312027fdbec21db5051"

# Model paths on SFS
CHECKPOINTS_DIR="$SFS_MOUNT/checkpoints"
TEXT_ENCODERS_DIR="$SFS_MOUNT/text_encoders"
UPSCALE_DIR="$SFS_MOUNT/latent_upscale_models"
LORAS_DIR="$SFS_MOUNT/loras"

# ============================================================================
# Parse Arguments
# ============================================================================

DOWNLOAD_MODELS=false
COPY_CONTAINER=false
SKIP_MODELS=false
SKIP_CONTAINER=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --with-models)
            DOWNLOAD_MODELS=true
            shift
            ;;
        --with-container)
            COPY_CONTAINER=true
            shift
            ;;
        --full)
            DOWNLOAD_MODELS=true
            COPY_CONTAINER=true
            shift
            ;;
        --skip-models)
            SKIP_MODELS=true
            shift
            ;;
        --skip-container)
            SKIP_CONTAINER=true
            shift
            ;;
        -h|--help)
            echo "Usage: sudo bash RESTORE-SFS.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --with-models      Download models from R2 (~45GB)"
            echo "  --with-container   Copy container from mello (~2.6GB)"
            echo "  --full             Both models and container"
            echo "  --skip-models      Skip model download"
            echo "  --skip-container   Skip container copy"
            echo ""
            echo "Examples:"
            echo "  sudo bash RESTORE-SFS.sh --full           # Fresh SFS setup"
            echo "  sudo bash RESTORE-SFS.sh --with-models    # Just models"
            echo "  sudo bash RESTORE-SFS.sh --with-container # Just container"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# If no options given, prompt user
if [ "$DOWNLOAD_MODELS" = false ] && [ "$COPY_CONTAINER" = false ]; then
    echo ""
    echo "No options specified. What would you like to restore?"
    echo ""
    echo "  1) Full restore (models + container) - recommended for fresh SFS"
    echo "  2) Models only (from R2)"
    echo "  3) Container only (from mello)"
    echo "  4) Check what's already on SFS"
    echo ""
    read -p "Enter choice [1-4]: " choice

    case $choice in
        1)
            DOWNLOAD_MODELS=true
            COPY_CONTAINER=true
            ;;
        2)
            DOWNLOAD_MODELS=true
            ;;
        3)
            COPY_CONTAINER=true
            ;;
        4)
            echo ""
            echo "=== SFS Contents ==="
            if mountpoint -q "$SFS_MOUNT" 2>/dev/null; then
                echo "SFS mounted at: $SFS_MOUNT"
                echo ""
                echo "Checkpoints:"
                ls -lh "$CHECKPOINTS_DIR"/*.safetensors 2>/dev/null || echo "  (none)"
                echo ""
                echo "Text Encoders:"
                ls -lh "$TEXT_ENCODERS_DIR"/*.safetensors 2>/dev/null || echo "  (none)"
                echo ""
                echo "Container:"
                ls -lh "$SFS_MOUNT/worker-image.tar.gz" 2>/dev/null || echo "  (none)"
                echo ""
                du -sh "$SFS_MOUNT" 2>/dev/null || echo "Total: unknown"
            else
                echo "SFS not mounted at $SFS_MOUNT"
                echo "Run quick-start.sh first!"
            fi
            exit 0
            ;;
        *)
            echo "Invalid choice"
            exit 1
            ;;
    esac
fi

# ============================================================================
# Preflight Checks
# ============================================================================

echo ""
echo ">>> RESTORE-SFS: Populate SFS with models and container"
echo "========================================================="
echo ""

# Check root
if [ "$EUID" -ne 0 ]; then
    echo "!! Please run as root: sudo bash RESTORE-SFS.sh"
    exit 1
fi

# Check SFS mounted
echo "Step 0: Checking SFS mount..."
if ! mountpoint -q "$SFS_MOUNT" 2>/dev/null; then
    echo "  !! SFS not mounted at $SFS_MOUNT"
    echo "  Run quick-start.sh first to mount SFS"
    exit 1
fi
echo "  OK SFS mounted at $SFS_MOUNT"
df -h "$SFS_MOUNT" | tail -1
echo ""

# ============================================================================
# Install AWS CLI if needed
# ============================================================================

if [ "$DOWNLOAD_MODELS" = true ] && [ "$SKIP_MODELS" = false ]; then
    echo "Step 1: Checking AWS CLI..."
    if ! command -v aws &> /dev/null; then
        echo "  Installing AWS CLI..."
        apt-get update -qq
        apt-get install -y -qq unzip curl

        # Install AWS CLI v2
        curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
        unzip -q /tmp/awscliv2.zip -d /tmp
        /tmp/aws/install --update
        rm -rf /tmp/aws /tmp/awscliv2.zip

        echo "  OK AWS CLI installed"
    else
        echo "  OK AWS CLI already installed"
    fi
    echo ""
fi

# ============================================================================
# Download Models from R2
# ============================================================================

if [ "$DOWNLOAD_MODELS" = true ] && [ "$SKIP_MODELS" = false ]; then
    echo "Step 2: Downloading models from R2..."
    echo "  Bucket: $R2_BUCKET"
    echo "  This may take 20-40 minutes for ~45GB"
    echo ""

    # Configure AWS CLI for R2
    export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
    export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"

    # Create directories
    mkdir -p "$CHECKPOINTS_DIR" "$TEXT_ENCODERS_DIR" "$UPSCALE_DIR" "$LORAS_DIR"

    # Sync from R2
    echo "  Syncing from R2 to $SFS_MOUNT..."
    aws s3 sync "s3://$R2_BUCKET/" "$SFS_MOUNT/" \
        --endpoint-url "$R2_ENDPOINT" \
        --no-progress

    echo ""
    echo "  OK Models downloaded"
    echo ""
    echo "  Contents:"
    ls -lh "$CHECKPOINTS_DIR"/*.safetensors 2>/dev/null | head -5 || echo "    No checkpoints"
    ls -lh "$TEXT_ENCODERS_DIR"/*.safetensors 2>/dev/null | head -3 || echo "    No text encoders"
    echo ""
else
    echo "Step 2: Skipping model download"
    echo ""
fi

# ============================================================================
# Copy Container from Mello
# ============================================================================

if [ "$COPY_CONTAINER" = true ] && [ "$SKIP_CONTAINER" = false ]; then
    echo "Step 3: Copying container from mello..."

    CONTAINER_DEST="$SFS_MOUNT/worker-image.tar.gz"

    # Check if already exists
    if [ -f "$CONTAINER_DEST" ]; then
        EXISTING_SIZE=$(du -h "$CONTAINER_DEST" | cut -f1)
        echo "  Container already exists: $EXISTING_SIZE"
        read -p "  Overwrite? [y/N]: " overwrite
        if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
            echo "  Skipping container copy"
            SKIP_CONTAINER=true
        fi
    fi

    if [ "$SKIP_CONTAINER" = false ]; then
        echo "  Copying from $MELLO_HOST:$MELLO_CONTAINER"
        echo "  Size: ~2.6GB"

        scp "$MELLO_HOST:$MELLO_CONTAINER" "$CONTAINER_DEST"

        NEW_SIZE=$(du -h "$CONTAINER_DEST" | cut -f1)
        echo "  OK Container copied: $NEW_SIZE"
    fi
    echo ""
else
    echo "Step 3: Skipping container copy"
    echo ""
fi

# ============================================================================
# Summary
# ============================================================================

echo "========================================================="
echo "RESTORE-SFS COMPLETE!"
echo ""
echo "SFS Contents:"
du -sh "$SFS_MOUNT"/* 2>/dev/null | head -10
echo ""
echo "Total SFS usage:"
df -h "$SFS_MOUNT" | tail -1
echo ""

# Check what's ready
MODELS_READY=false
CONTAINER_READY=false

if [ -f "$CHECKPOINTS_DIR/ltx-2-19b-dev-fp8.safetensors" ]; then
    MODELS_READY=true
    echo "OK Models ready"
else
    echo "!! Models not found - run with --with-models"
fi

if [ -f "$SFS_MOUNT/worker-image.tar.gz" ]; then
    CONTAINER_READY=true
    echo "OK Container ready"
else
    echo "!! Container not found - run with --with-container"
fi

echo ""
if [ "$MODELS_READY" = true ] && [ "$CONTAINER_READY" = true ]; then
    # Auto-load container into Docker
    echo "Step 4: Loading container into Docker..."
    if docker images | grep -q "comfyui-worker"; then
        echo "  OK Container already loaded in Docker"
    else
        if docker load < "$SFS_MOUNT/worker-image.tar.gz"; then
            echo "  OK Container loaded!"
            docker images | grep -E "comfy|worker" | head -3
        else
            echo "  !! Failed to load container"
        fi
    fi
    echo ""
    echo "Ready to start worker:"
    echo "  cd ~/comfy-multi && docker compose up -d worker-1"
else
    echo "Run again with missing options to complete setup."
fi
echo "========================================================="
