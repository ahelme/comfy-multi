#!/bin/bash
# Backup Tailscale Identity from Verda GPU worker
# This allows NEW GPU instances to assume the SAME Tailscale IP!
# Genius tip from: https://tailscale.com/kb/1214/backup-restore

set -e

VERDA_HOST="${VERDA_HOST:-dev@verda}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups/tailscale}"
DATE=$(date +%Y%m%d-%H%M%S)

echo "🔐 Backing up Tailscale Identity..."
echo "===================================="
echo ""

mkdir -p "$BACKUP_DIR"

# Backup Tailscale state directory
echo "Step 1: Backing up /var/lib/tailscale from Verda..."
ssh "$VERDA_HOST" "sudo tar -czf /tmp/tailscale-state.tar.gz -C /var/lib tailscale/"
scp "$VERDA_HOST:/tmp/tailscale-state.tar.gz" "$BACKUP_DIR/tailscale-state-${DATE}.tar.gz"
ssh "$VERDA_HOST" "sudo rm /tmp/tailscale-state.tar.gz"

echo "  ✓ Tailscale state backed up"

# Backup SSH host keys (optional, for full identity preservation)
echo "Step 2: Backing up SSH host keys..."
ssh "$VERDA_HOST" "sudo tar -czf /tmp/ssh-host-keys.tar.gz /etc/ssh/ssh_host_*"
scp "$VERDA_HOST:/tmp/ssh-host-keys.tar.gz" "$BACKUP_DIR/ssh-host-keys-${DATE}.tar.gz"
ssh "$VERDA_HOST" "sudo rm /tmp/ssh-host-keys.tar.gz"

echo "  ✓ SSH host keys backed up"

# Get current Tailscale IP for reference
TAILSCALE_IP=$(ssh "$VERDA_HOST" "tailscale ip -4" 2>/dev/null || echo "unknown")

# Create restore script
cat > "$BACKUP_DIR/restore-identity.sh" << 'RESTORE'
#!/bin/bash
# Restore Tailscale Identity to NEW GPU instance
# This makes the new machine "become" the old machine on Tailscale network!

set -e

if [ "$EUID" -ne 0 ]; then
   echo "Please run as root: sudo bash restore-identity.sh"
   exit 1
fi

echo "🔄 Restoring Tailscale Identity..."
echo "===================================="
echo ""

# Stop tailscale if running
systemctl stop tailscaled 2>/dev/null || true

# Restore Tailscale state
echo "Step 1: Restoring /var/lib/tailscale..."
if [ -f "tailscale-state-*.tar.gz" ]; then
    tar -xzf tailscale-state-*.tar.gz -C /var/lib/
    echo "  ✓ Tailscale state restored"
else
    echo "  ❌ tailscale-state-*.tar.gz not found!"
    exit 1
fi

# Restore SSH host keys (optional)
echo "Step 2: Restoring SSH host keys..."
if [ -f "ssh-host-keys-*.tar.gz" ]; then
    tar -xzf ssh-host-keys-*.tar.gz -C /
    echo "  ✓ SSH host keys restored"
else
    echo "  ⚠️  SSH host keys not found (optional)"
fi

# Restart services
echo "Step 3: Restarting services..."
systemctl restart sshd 2>/dev/null || true
systemctl start tailscaled

# Wait for tailscale to come up
echo "  Waiting for Tailscale to connect..."
sleep 5

# Show status
tailscale status

echo ""
echo "===================================="
echo "✅ Identity Restored!"
echo ""
echo "🔍 Verify Tailscale IP:"
echo "   Current IP: $(tailscale ip -4)"
echo "   Should be:  TAILSCALE_IP_PLACEHOLDER"
echo ""
echo "✅ This machine now has the SAME Tailscale IP!"
echo "   Your VPS can reach it at the same address."
echo "===================================="
RESTORE

# Replace placeholder with actual IP
sed -i "s/TAILSCALE_IP_PLACEHOLDER/$TAILSCALE_IP/g" "$BACKUP_DIR/restore-identity.sh"
chmod +x "$BACKUP_DIR/restore-identity.sh"

# Keep only last 3 backups
cd "$BACKUP_DIR"
ls -t tailscale-state-*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -v
ls -t ssh-host-keys-*.tar.gz 2>/dev/null | tail -n +4 | xargs -r rm -v

STATE_SIZE=$(du -h "$BACKUP_DIR/tailscale-state-${DATE}.tar.gz" | cut -f1)
SSH_SIZE=$(du -h "$BACKUP_DIR/ssh-host-keys-${DATE}.tar.gz" | cut -f1)

echo ""
echo "===================================="
echo "✅ Tailscale Identity Backed Up!"
echo ""
echo "📦 Files:"
echo "   • tailscale-state-${DATE}.tar.gz ($STATE_SIZE)"
echo "   • ssh-host-keys-${DATE}.tar.gz ($SSH_SIZE)"
echo "   • restore-identity.sh (executable)"
echo ""
echo "📋 Current Tailscale IP: $TAILSCALE_IP"
echo ""
echo "🚀 To restore on NEW GPU instance:"
echo ""
echo "   # 1. Transfer backup files"
echo "   scp $BACKUP_DIR/tailscale-state-${DATE}.tar.gz new-gpu:~/"
echo "   scp $BACKUP_DIR/ssh-host-keys-${DATE}.tar.gz new-gpu:~/"
echo "   scp $BACKUP_DIR/restore-identity.sh new-gpu:~/"
echo ""
echo "   # 2. On NEW GPU instance (as root)"
echo "   ssh new-gpu"
echo "   sudo bash restore-identity.sh"
echo ""
echo "   # 3. Verify same IP"
echo "   tailscale ip -4"
echo "   # Should show: $TAILSCALE_IP"
echo ""
echo "💡 MAGIC: New GPU instance will have SAME Tailscale IP!"
echo "   Your VPS Redis connection will just work, no config changes!"
echo "===================================="
