#!/bin/bash
# BACKUP VERDA - Backup Verda GPU instance configs and optionally models
# Backs up system hardening configs, user environment, and project files
# Optional: --with-models flag syncs models to Cloudflare R2

set -e

# Parse flags
WITH_MODELS=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --with-models|-m)
            WITH_MODELS=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--with-models|-m]"
            exit 1
            ;;
    esac
done

VERDA_HOST="${VERDA_HOST:-dev@verda}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups/verda}"
DATE=$(date +%Y%m%d-%H%M%S)

# R2 Configuration
R2_ENDPOINT="https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com"
R2_BUCKET="comfy-multi-model-vault-backup"

echo "🔄 BACKUP VERDA"
echo "==============="
echo "Host: $VERDA_HOST"
echo "Destination: $BACKUP_DIR"
echo "Models to R2: $WITH_MODELS"
echo ""

mkdir -p "$BACKUP_DIR"

# Backup 1: Tailscale identity (CRITICAL - for persistent IP!)
echo "Step 1: Backing up Tailscale identity..."
ssh "$VERDA_HOST" "sudo tar -czf /tmp/tailscale-identity.tar.gz -C /var/lib tailscale/ 2>/dev/null || echo 'Tailscale not found'"
scp "$VERDA_HOST:/tmp/tailscale-identity.tar.gz" "$BACKUP_DIR/tailscale-identity-${DATE}.tar.gz" 2>/dev/null || echo "  ⚠️  No Tailscale state found"
ssh "$VERDA_HOST" "sudo rm -f /tmp/tailscale-identity.tar.gz" 2>/dev/null || true

if [ -f "$BACKUP_DIR/tailscale-identity-${DATE}.tar.gz" ]; then
    TS_SIZE=$(du -h "$BACKUP_DIR/tailscale-identity-${DATE}.tar.gz" | cut -f1)
    echo "  ✓ Tailscale backed up ($TS_SIZE)"
fi

# Backup 2: SSH host keys
echo "Step 2: Backing up SSH host keys..."
ssh "$VERDA_HOST" "sudo tar -czf /tmp/ssh-keys.tar.gz /etc/ssh/ssh_host_* 2>/dev/null"
scp "$VERDA_HOST:/tmp/ssh-keys.tar.gz" "$BACKUP_DIR/ssh-host-keys-${DATE}.tar.gz"
ssh "$VERDA_HOST" "sudo rm -f /tmp/ssh-keys.tar.gz"
SSH_SIZE=$(du -h "$BACKUP_DIR/ssh-host-keys-${DATE}.tar.gz" | cut -f1)
echo "  ✓ SSH keys backed up ($SSH_SIZE)"

# Backup 3: Ubuntu Pro configuration
echo "Step 3: Backing up Ubuntu Pro config..."
ssh "$VERDA_HOST" "sudo tar -czf /tmp/ubuntu-pro-config.tar.gz \
  /etc/ubuntu-advantage/ \
  /var/lib/ubuntu-advantage/ \
  2>/dev/null || echo 'Ubuntu Pro not configured'"
scp "$VERDA_HOST:/tmp/ubuntu-pro-config.tar.gz" "$BACKUP_DIR/ubuntu-pro-${DATE}.tar.gz" 2>/dev/null || echo "  ⚠️  No Ubuntu Pro config"
ssh "$VERDA_HOST" "sudo rm -f /tmp/ubuntu-pro-config.tar.gz" 2>/dev/null || true

if [ -f "$BACKUP_DIR/ubuntu-pro-${DATE}.tar.gz" ]; then
    PRO_SIZE=$(du -h "$BACKUP_DIR/ubuntu-pro-${DATE}.tar.gz" | cut -f1)
    echo "  ✓ Ubuntu Pro config backed up ($PRO_SIZE)"
fi

# Backup 4: Fail2ban configuration
echo "Step 4: Backing up Fail2ban config..."
ssh "$VERDA_HOST" "sudo tar -czf /tmp/fail2ban-config.tar.gz \
  /etc/fail2ban/jail.local \
  /etc/fail2ban/jail.d/ \
  2>/dev/null || echo 'Fail2ban not configured'"
scp "$VERDA_HOST:/tmp/fail2ban-config.tar.gz" "$BACKUP_DIR/fail2ban-${DATE}.tar.gz" 2>/dev/null || echo "  ⚠️  No Fail2ban config"
ssh "$VERDA_HOST" "sudo rm -f /tmp/fail2ban-config.tar.gz" 2>/dev/null || true

# Backup 5: UFW firewall rules
echo "Step 5: Backing up UFW firewall rules..."
ssh "$VERDA_HOST" "sudo tar -czf /tmp/ufw-config.tar.gz \
  /etc/ufw/user.rules \
  /etc/ufw/user6.rules \
  /lib/ufw/user.rules \
  2>/dev/null || echo 'UFW not configured'"
scp "$VERDA_HOST:/tmp/ufw-config.tar.gz" "$BACKUP_DIR/ufw-${DATE}.tar.gz" 2>/dev/null || echo "  ⚠️  No UFW config"
ssh "$VERDA_HOST" "sudo rm -f /tmp/ufw-config.tar.gz" 2>/dev/null || true

# Backup 6: User home directory
echo "Step 6: Backing up /home/dev..."
ssh "$VERDA_HOST" "cd /home/dev && tar -czf /tmp/home-dev-backup.tar.gz \
  --exclude='.cache' \
  --exclude='comfy-multi/data/models' \
  --exclude='comfy-multi/data/outputs' \
  --exclude='.local/share' \
  --exclude='.npm' \
  --exclude='.docker' \
  --exclude='*.safetensors' \
  ."

scp "$VERDA_HOST:/tmp/home-dev-backup.tar.gz" "$BACKUP_DIR/home-dev-${DATE}.tar.gz"
ssh "$VERDA_HOST" "rm -f /tmp/home-dev-backup.tar.gz"
HOME_SIZE=$(du -h "$BACKUP_DIR/home-dev-${DATE}.tar.gz" | cut -f1)
echo "  ✓ Home directory backed up ($HOME_SIZE)"

# Backup 7: ComfyUI project
echo "Step 7: Backing up ComfyUI project..."
ssh "$VERDA_HOST" "if [ -d ~/comfy-multi ]; then \
  cd ~/comfy-multi && tar -czf /tmp/comfy-project.tar.gz \
    --exclude='data/models' \
    --exclude='data/outputs' \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    . ; \
fi"

scp "$VERDA_HOST:/tmp/comfy-project.tar.gz" "$BACKUP_DIR/comfy-project-${DATE}.tar.gz" 2>/dev/null || echo "  ⚠️  No project found"
ssh "$VERDA_HOST" "rm -f /tmp/comfy-project.tar.gz" 2>/dev/null || true

if [ -f "$BACKUP_DIR/comfy-project-${DATE}.tar.gz" ]; then
    PROJ_SIZE=$(du -h "$BACKUP_DIR/comfy-project-${DATE}.tar.gz" | cut -f1)
    echo "  ✓ Project backed up ($PROJ_SIZE)"
fi

# Backup 8: Oh-my-zsh custom themes and plugins
echo "Step 8: Backing up oh-my-zsh custom configs..."
ssh "$VERDA_HOST" "if [ -d ~/.oh-my-zsh/custom ]; then \
  tar -czf /tmp/ohmyzsh-custom.tar.gz -C ~/.oh-my-zsh custom/ ; \
fi"

scp "$VERDA_HOST:/tmp/ohmyzsh-custom.tar.gz" "$BACKUP_DIR/ohmyzsh-custom-${DATE}.tar.gz" 2>/dev/null || echo "  ⚠️  No oh-my-zsh custom found"
ssh "$VERDA_HOST" "rm -f /tmp/ohmyzsh-custom.tar.gz" 2>/dev/null || true

if [ -f "$BACKUP_DIR/ohmyzsh-custom-${DATE}.tar.gz" ]; then
    OMZ_SIZE=$(du -h "$BACKUP_DIR/ohmyzsh-custom-${DATE}.tar.gz" | cut -f1)
    echo "  ✓ oh-my-zsh custom backed up ($OMZ_SIZE)"
fi

# Backup 9: Tailscale IP
echo "Step 9: Recording Tailscale IP..."
TAILSCALE_IP=$(ssh "$VERDA_HOST" "tailscale ip -4 2>/dev/null" || echo "unknown")
echo "$TAILSCALE_IP" > "$BACKUP_DIR/tailscale-ip.txt"
echo "  ✓ Tailscale IP: $TAILSCALE_IP"

# Backup 10: Models to R2 (optional)
if [ "$WITH_MODELS" = true ]; then
    echo ""
    echo "Step 10: Syncing models to Cloudflare R2..."

    # Check if AWS CLI is available on Verda (used for R2 S3-compatible API)
    if ! ssh "$VERDA_HOST" "which aws" &>/dev/null; then
        echo "  ⚠️  AWS CLI not installed on Verda - skipping R2 sync"
        echo "  Install with: curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o '/tmp/awscliv2.zip' && cd /tmp && unzip -o awscliv2.zip && sudo ./aws/install"
    # Check if R2 transfer already in progress (uses AWS CLI for S3-compatible API)
    elif ssh "$VERDA_HOST" "pgrep -f 'aws s3'" &>/dev/null; then
        echo "  ⚠️  Cloudflare R2 transfer already in progress - skipping to avoid duplicates"
        echo ""
        echo "  To check progress:  ssh $VERDA_HOST 'ps aux | grep \"aws s3\"'"
        echo "  To kill & restart:  ssh $VERDA_HOST 'pkill -f \"aws s3\"' && $0 --with-models"
        echo ""
    else
        # Find model directories (check common locations)
        MODEL_DIRS=$(ssh "$VERDA_HOST" "ls -d ~/comfy-multi/data/models 2>/dev/null || ls -d /mnt/models 2>/dev/null || echo ''")

        if [ -z "$MODEL_DIRS" ]; then
            echo "  ⚠️  No model directory found"
        else
            echo "  Model directory: $MODEL_DIRS"

            # Get list of .safetensors files
            MODEL_FILES=$(ssh "$VERDA_HOST" "find $MODEL_DIRS -name '*.safetensors' -type f 2>/dev/null")

            if [ -z "$MODEL_FILES" ]; then
                echo "  ⚠️  No .safetensors files found"
            else
                SYNCED=0
                SKIPPED=0

                while IFS= read -r LOCAL_FILE; do
                    [ -z "$LOCAL_FILE" ] && continue

                    # Get relative path from models dir
                    REL_PATH=$(ssh "$VERDA_HOST" "echo '$LOCAL_FILE' | sed 's|.*/models/||'")
                    LOCAL_SIZE=$(ssh "$VERDA_HOST" "stat -c%s '$LOCAL_FILE' 2>/dev/null || echo 0")

                    # Check if file exists in R2 with same size
                    R2_SIZE=$(ssh "$VERDA_HOST" "aws --endpoint-url $R2_ENDPOINT s3api head-object --bucket $R2_BUCKET --key '$REL_PATH' --query ContentLength --output text 2>/dev/null || echo 0")

                    if [ "$LOCAL_SIZE" = "$R2_SIZE" ] && [ "$R2_SIZE" != "0" ]; then
                        echo "  ✓ $REL_PATH (already in R2, same size)"
                        ((SKIPPED++))
                    else
                        echo "  ↑ Uploading $REL_PATH ($(numfmt --to=iec $LOCAL_SIZE))..."
                        if ssh "$VERDA_HOST" "aws s3 cp '$LOCAL_FILE' 's3://$R2_BUCKET/$REL_PATH' --endpoint-url $R2_ENDPOINT" 2>/dev/null; then
                            echo "    ✓ Uploaded"
                            ((SYNCED++))
                        else
                            echo "    ✗ Failed"
                        fi
                    fi
                done <<< "$MODEL_FILES"

                echo "  Summary: $SYNCED uploaded, $SKIPPED already synced"
            fi
        fi
    fi
fi

# Create comprehensive restore script
cat > "$BACKUP_DIR/RESTORE.sh" << 'RESTORE'
#!/bin/bash
# Restore Verda backup with full security hardening
# Run as root on NEW Verda instance

set -e

if [ "$EUID" -ne 0 ]; then
   echo "Please run as root: sudo bash RESTORE.sh"
   exit 1
fi

echo "🔄 Restoring Verda backup with security hardening..."
echo "===================================================="
echo ""

# Get backup date (use most recent backup that has home-dev file)
BACKUP_DATE=$(ls home-dev-*.tar.gz 2>/dev/null | tail -1 | sed 's/home-dev-\(.*\)\.tar\.gz/\1/')

if [ -z "$BACKUP_DATE" ]; then
    echo "❌ No backup files found!"
    exit 1
fi

echo "Found backup from: $BACKUP_DATE"
echo ""

# Step 1: Install essential packages (skip if already installed)
echo "Step 1: Installing essential packages..."
apt-get update

# Install packages that won't conflict
apt-get install -y \
    fail2ban \
    ufw \
    redis-tools \
    zsh \
    git \
    curl \
    wget

# Only install docker if not already present (Verda images have it pre-installed)
if ! command -v docker &> /dev/null; then
    apt-get install -y docker.io docker-compose
    echo "  ✓ Docker installed"
else
    echo "  ✓ Docker already installed (skipping)"
fi

echo "  ✓ Packages installed"
echo ""

# Step 2: Restore Tailscale identity (CRITICAL!)
if [ -f "tailscale-identity-${BACKUP_DATE}.tar.gz" ]; then
    echo "Step 2: Restoring Tailscale identity..."
    systemctl stop tailscaled 2>/dev/null || true
    tar -xzf "tailscale-identity-${BACKUP_DATE}.tar.gz" -C /var/lib/
    systemctl start tailscaled
    sleep 3

    # Disable SSH over Tailscale (security!)
    tailscale set --ssh=false 2>/dev/null || true

    RESTORED_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")
    echo "  ✓ Tailscale restored! IP: $RESTORED_IP"

    if [ -f "tailscale-ip.txt" ]; then
        ORIGINAL_IP=$(cat tailscale-ip.txt)
        if [ "$RESTORED_IP" = "$ORIGINAL_IP" ]; then
            echo "  ✅ SUCCESS! Same Tailscale IP: $ORIGINAL_IP"
        else
            echo "  ⚠️  IP changed: $ORIGINAL_IP → $RESTORED_IP"
        fi
    fi
else
    echo "Step 2: ⚠️  No Tailscale backup - will need manual setup"
fi
echo ""

# Step 3: Restore SSH host keys
if [ -f "ssh-host-keys-${BACKUP_DATE}.tar.gz" ]; then
    echo "Step 3: Restoring SSH host keys..."
    tar -xzf "ssh-host-keys-${BACKUP_DATE}.tar.gz" -C /
    systemctl restart ssh || systemctl restart sshd || true
    echo "  ✓ SSH keys restored"
fi
echo ""

# Step 4: Restore Ubuntu Pro
if [ -f "ubuntu-pro-${BACKUP_DATE}.tar.gz" ]; then
    echo "Step 4: Restoring Ubuntu Pro..."
    tar -xzf "ubuntu-pro-${BACKUP_DATE}.tar.gz" -C /
    echo "  ✓ Ubuntu Pro config restored"
    echo "  ⚠️  May need: sudo pro attach <token>"
fi
echo ""

# Step 5: Configure Fail2ban
echo "Step 5: Configuring Fail2ban..."
if [ -f "fail2ban-${BACKUP_DATE}.tar.gz" ]; then
    tar -xzf "fail2ban-${BACKUP_DATE}.tar.gz" -C /
    echo "  ✓ Restored previous config"
else
    # Create secure default config
    cat > /etc/fail2ban/jail.local << 'FAIL2BAN'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
FAIL2BAN
    echo "  ✓ Created default secure config"
fi

systemctl enable fail2ban
systemctl restart fail2ban
echo "  ✓ Fail2ban active"
echo ""

# Step 5b: Install oh-my-zsh and bullet-train theme
echo "Step 5b: Installing oh-my-zsh and bullet-train..."
if [ ! -d /home/dev/.oh-my-zsh ]; then
    sudo -u dev sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "  ✓ oh-my-zsh installed"
else
    echo "  ✓ oh-my-zsh already present from backup"
fi

# Restore oh-my-zsh custom themes/plugins if backed up
if [ -f "ohmyzsh-custom-${BACKUP_DATE}.tar.gz" ]; then
    echo "  Restoring oh-my-zsh custom themes/plugins..."
    sudo -u dev tar -xzf "ohmyzsh-custom-${BACKUP_DATE}.tar.gz" -C /home/dev/.oh-my-zsh/
    echo "  ✓ oh-my-zsh custom restored from backup"
else
    # Install bullet-train theme if not present
    if [ ! -f /home/dev/.oh-my-zsh/custom/themes/bullet-train.zsh-theme ]; then
        sudo -u dev mkdir -p /home/dev/.oh-my-zsh/custom/themes
        sudo -u dev curl -fsSL https://raw.githubusercontent.com/caiogondim/bullet-train.zsh/master/bullet-train.zsh-theme \
            -o /home/dev/.oh-my-zsh/custom/themes/bullet-train.zsh-theme
        echo "  ✓ bullet-train theme installed"
    else
        echo "  ✓ bullet-train theme already present"
    fi
fi
echo ""

# Step 6: Configure UFW (lock down!)
echo "Step 6: Configuring UFW firewall..."
ufw --force reset

# Allow only essential ports
ufw default deny incoming
ufw default allow outgoing

# SSH (standard port)
ufw allow 22/tcp comment 'SSH'

# NO web ports needed - worker only connects to VPS via Tailscale!
# All web access goes through VPS nginx

# Tailscale (if using direct connection)
ufw allow 41641/udp comment 'Tailscale'

if [ -f "ufw-${BACKUP_DATE}.tar.gz" ]; then
    tar -xzf "ufw-${BACKUP_DATE}.tar.gz" -C / 2>/dev/null || true
    echo "  ✓ Restored previous firewall rules"
fi

ufw --force enable
systemctl enable ufw
echo "  ✓ UFW firewall active (SSH only!)"
echo ""

# Step 7: Restore home directory
if [ -f "home-dev-${BACKUP_DATE}.tar.gz" ]; then
    echo "Step 7: Restoring /home/dev..."

    # Create dev user if needed
    if ! id "dev" &>/dev/null; then
        useradd -m -s /usr/bin/zsh dev
        usermod -aG docker dev
        echo "  ✓ Created dev user with zsh shell"
    fi

    tar -xzf "home-dev-${BACKUP_DATE}.tar.gz" -C /home/dev/
    chown -R dev:dev /home/dev

    # Source .zshrc for dev user (add to .profile if not there)
    if ! grep -q ".zshrc" /home/dev/.profile 2>/dev/null; then
        echo "[ -f ~/.zshrc ] && source ~/.zshrc" >> /home/dev/.profile
    fi

    echo "  ✓ Home directory restored"
    echo "  ✓ zsh configured as default shell"
fi
echo ""

# Step 8: Restore project
if [ -f "comfy-project-${BACKUP_DATE}.tar.gz" ]; then
    echo "Step 8: Restoring comfy-multi project..."
    mkdir -p /home/dev/comfy-multi
    tar -xzf "comfy-project-${BACKUP_DATE}.tar.gz" -C /home/dev/comfy-multi/
    chown -R dev:dev /home/dev/comfy-multi

    # Load .env if exists
    if [ -f /home/dev/comfy-multi/.env ]; then
        echo "  ✓ .env file found"
        echo "  💡 To load: cd ~/comfy-multi && source .env"
    fi

    echo "  ✓ Project restored"
fi
echo ""

echo "===================================================="
echo "✅ RESTORE COMPLETE!"
echo ""
echo "🔒 Security Status:"
echo "  ✓ Fail2ban active (SSH brute-force protection)"
echo "  ✓ UFW firewall active (SSH only)"
echo "  ✓ Tailscale SSH disabled (more secure)"
echo "  ✓ Docker installed"
echo "  ✓ redis-tools installed"
echo "  ✓ zsh configured for dev user"
echo ""
echo "📋 System Info:"
tailscale status 2>/dev/null || echo "  Tailscale: Not running"
ufw status | head -5
fail2ban-client status | head -3
echo ""
echo "⚠️  NEXT STEPS:"
echo ""
echo "1. Create Block Storage volumes:"
echo "   Verda Dashboard → Storage → Create Block Volume"
echo "   - Model Vault: 40GB (for LTX-2 models ~21GB)"
echo "   - Scratch Disk: 10GB (for outputs/temp files)"
echo ""
echo "2. Attach and mount Block Storage:"
echo "   # As root:"
echo "   mkfs.ext4 /dev/vdb  # Model Vault"
echo "   mkfs.ext4 /dev/vdc  # Scratch Disk"
echo "   mkdir -p /mnt/models /mnt/scratch"
echo "   mount /dev/vdb /mnt/models"
echo "   mount /dev/vdc /mnt/scratch"
echo "   chown dev:dev /mnt/models /mnt/scratch"
echo "   echo '/dev/vdb /mnt/models ext4 defaults 0 0' >> /etc/fstab"
echo "   echo '/dev/vdc /mnt/scratch ext4 defaults 0 0' >> /etc/fstab"
echo ""
echo "3. Create symlinks to ComfyUI directories:"
echo "   # As dev user:"
echo "   su - dev"
echo "   mkdir -p ~/comfy-multi/data"
echo "   ln -sf /mnt/models ~/comfy-multi/data/models"
echo "   ln -sf /mnt/scratch ~/comfy-multi/data/outputs"
echo ""
echo "4. Download models to /mnt/models (~30 min):"
echo "   cd ~/comfy-multi"
echo "   # Run: bash scripts/download-models.sh"
echo "   # Or download manually from HuggingFace:"
echo "   # - ltx-2-19b-dev-fp8.safetensors (~10GB)"
echo "   # - gemma_3_12B_it.safetensors (~5GB)"
echo "   # - ltx-2-spatial-upscaler-x2-1.0.safetensors (~2GB)"
echo "   # - ltx-2-19b-distilled-lora-384.safetensors (~2GB)"
echo "   # - ltx-2-19b-lora-camera-control-dolly-left.safetensors (~2GB)"
echo ""
echo "5. Load environment and start worker:"
echo "   cd ~/comfy-multi"
echo "   source .env"
echo "   docker compose up -d worker-1"
echo ""
echo "6. Verify connection to VPS:"
echo "   redis-cli -h \${REDIS_HOST} -p 6379 -a '\${REDIS_PASSWORD}' ping"
echo "   # Should return: PONG"
echo ""
echo "💰 Storage costs: SFS 50GB (\$10) + Block 40GB (\$4) + Block 10GB (\$1) = \$15/month"
echo "===================================================="
RESTORE

chmod +x "$BACKUP_DIR/RESTORE.sh"

# Calculate total size
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

echo ""
echo "================================"
echo "✅ BACKUP COMPLETE!"
echo ""
echo "📦 Location: $BACKUP_DIR"
echo "💾 Size: $TOTAL_SIZE"
echo ""
echo "📋 Backed up:"
[ -f "$BACKUP_DIR/tailscale-identity-${DATE}.tar.gz" ] && echo "  ✓ Tailscale identity ($TS_SIZE)"
echo "  ✓ SSH host keys ($SSH_SIZE)"
[ -f "$BACKUP_DIR/ubuntu-pro-${DATE}.tar.gz" ] && echo "  ✓ Ubuntu Pro ($PRO_SIZE)"
echo "  ✓ Fail2ban config"
echo "  ✓ UFW firewall rules"
echo "  ✓ Home directory ($HOME_SIZE)"
[ -f "$BACKUP_DIR/comfy-project-${DATE}.tar.gz" ] && echo "  ✓ Project ($PROJ_SIZE)"
[ -f "$BACKUP_DIR/ohmyzsh-custom-${DATE}.tar.gz" ] && echo "  ✓ oh-my-zsh custom ($OMZ_SIZE)"
echo "  ✓ Tailscale IP: $TAILSCALE_IP"
echo ""
echo "🚀 TO RESTORE:"
echo "  1. Create NEW Verda instance with:"
echo "     - 50GB SFS (\$10/mo) for system/config"
echo "     - 40GB Block Storage (\$4/mo) for Model Vault"
echo "     - 10GB Block Storage (\$1/mo) for Scratch Disk"
echo "  2. scp -r $BACKUP_DIR new-verda:~/"
echo "  3. ssh root@new-verda"
echo "  4. cd ~/$(basename $BACKUP_DIR) && bash RESTORE.sh"
echo ""
echo "⏱️  Restore time: ~10 min system + 30 min models"
echo "💰 Total storage: \$15/month (was \$20/month)"
echo "================================"
