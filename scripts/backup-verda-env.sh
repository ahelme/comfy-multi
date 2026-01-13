#!/bin/bash
# Backup Verda GPU worker environment to VPS
# This creates a complete backup excluding large files (models, cache)

set -e

VERDA_HOST="${VERDA_HOST:-dev@verda}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups/verda}"
DATE=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="verda-env-backup-${DATE}.tar.gz"

echo "🔄 Backing up Verda environment..."
echo "   Source: $VERDA_HOST:/home/dev"
echo "   Destination: $BACKUP_DIR/$BACKUP_NAME"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create backup on Verda (excluding large files)
echo "Step 1: Creating backup archive on Verda..."
ssh "$VERDA_HOST" "tar -czf /tmp/${BACKUP_NAME} \
  --exclude='.cache' \
  --exclude='comfy-multi/data/models' \
  --exclude='comfy-multi/data/outputs' \
  --exclude='.local/share' \
  --exclude='.npm' \
  --exclude='.docker' \
  -C /home/dev ."

# Download backup to VPS
echo "Step 2: Downloading backup to VPS..."
scp "$VERDA_HOST:/tmp/${BACKUP_NAME}" "$BACKUP_DIR/"

# Clean up remote backup
echo "Step 3: Cleaning up remote backup..."
ssh "$VERDA_HOST" "rm -f /tmp/${BACKUP_NAME}"

# Calculate backup size
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)

echo ""
echo "✅ Backup complete!"
echo "   File: $BACKUP_DIR/$BACKUP_NAME"
echo "   Size: $BACKUP_SIZE"
echo ""
echo "To restore on a new machine:"
echo "  scp $BACKUP_DIR/$BACKUP_NAME newmachine:/tmp/"
echo "  ssh newmachine 'tar -xzf /tmp/${BACKUP_NAME} -C /home/dev'"
echo ""
echo "Backup includes:"
echo "  ✓ Dotfiles (.zshrc, .vimrc, etc.)"
echo "  ✓ Oh-my-zsh configuration and themes"
echo "  ✓ Git configuration"
echo "  ✓ SSH keys (if present)"
echo "  ✓ Shell history"
echo "  ✓ Application configs"
echo ""
echo "Backup excludes:"
echo "  ✗ Large model files (comfy-multi/data/models)"
echo "  ✗ Generated outputs (comfy-multi/data/outputs)"
echo "  ✗ Cache directories (.cache, .npm, .docker)"
echo "  ✗ Package caches (.local/share)"

# Keep only last 5 backups
echo ""
echo "Cleaning up old backups (keeping last 5)..."
cd "$BACKUP_DIR"
ls -t verda-env-backup-*.tar.gz | tail -n +6 | xargs -r rm -v

echo ""
echo "Current backups:"
ls -lh "$BACKUP_DIR"/verda-env-backup-*.tar.gz 2>/dev/null || echo "  No backups found"
