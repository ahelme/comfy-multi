**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-12
**Doc Updated:** 2026-01-12

---

# GPU Worker Environment Backup & Restore

How to backup and reproduce your customized Verda GPU development environment (zsh, oh-my-zsh, Tailscale, custom themes, etc.) on new machines.

---

## Why You Need This

When using hourly-billed GPU providers (Verda, RunPod, etc.), you need to:
- **Quickly spin up new instances** with your dev environment
- **Switch providers** without manual reconfiguration
- **Disaster recovery** if an instance is terminated
- **Team consistency** - same environment for all team members

---

## Recommended Approach: Dotfiles + Startup Script

**Benefits:**
- ✅ **Version controlled** (Git)
- ✅ **Provider independent** (works on any Ubuntu/Debian machine)
- ✅ **Reproducible** (automated installation)
- ✅ **Lightweight** (only config files, not data)
- ✅ **Shareable** (team members can use same setup)

### Step 1: Create Dotfiles Repository (One-Time)

Run this **on your current Verda instance**:

```bash
# Download the script
scp scripts/create-dotfiles-repo.sh dev@verda:/tmp/

# Run it on Verda
ssh dev@verda "bash /tmp/create-dotfiles-repo.sh"
```

This creates `~/comfy-multi-gpu-instance-dotfiles` with:
- `.zshrc` (your zsh configuration)
- `oh-my-zsh-themes/` (custom themes like bullet-train)
- `.vimrc`, `.tmux.conf`, `.gitconfig` (if present)
- `install.sh` (automated installation script)

### Step 2: Push to GitHub

```bash
# On Verda
ssh dev@verda

# Create GitHub repo at: https://github.com/new
# Then push:
cd ~/comfy-multi-gpu-instance-dotfiles
git remote add origin git@github.com:ahelme/dotfiles.git
git branch -M main
git push -u origin main
```

### Step 3: Update Enhanced Startup Script

Edit `scripts/verda-startup-script.sh` and add this section:

```bash
# Install dev environment
DOTFILES_REPO="https://github.com/ahelme/comfy-multi-gpu-instance-dotfiles.git"

# Install zsh
apt-get install -y zsh

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Setup for dev user
sudo -u dev bash << 'EOF'
# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Clone dotfiles
git clone $DOTFILES_REPO ~/comfy-multi-gpu-instance-dotfiles
cd ~/comfy-multi-gpu-instance-dotfiles && ./install.sh
EOF

# Change default shell
chsh -s $(which zsh) dev
```

### Step 4: Spin Up New Instance (Automated)

When you need a new GPU worker:

```bash
# 1. Create new instance (Verda, RunPod, Hetzner, etc.)
# 2. Run startup script
ssh root@new-gpu-instance
curl -fsSL https://raw.githubusercontent.com/ahelme/comfy-multi/main/scripts/verda-startup-script.sh | bash

# 3. Authenticate Tailscale
sudo tailscale up

# 4. Clone comfy-multi
git clone https://github.com/ahelme/comfy-multi.git ~/comfy-multi

# 5. Download models and start worker
cd ~/comfy-multi
# ... model download and docker compose up
```

**Time to production:** ~10 minutes (mostly model downloads)

---

## Alternative: Complete Environment Backup

For disaster recovery or when dotfiles aren't sufficient.

### Create Backup

**From VPS:**
```bash
# Run the backup script
./scripts/backup-verda-env.sh

# Backup saved to: ~/backups/verda/verda-env-backup-YYYYMMDD-HHMMSS.tar.gz
```

**Manual backup:**
```bash
# On Verda - create archive (excludes models/cache)
ssh dev@verda "tar -czf /tmp/verda-backup.tar.gz \
  --exclude='.cache' \
  --exclude='comfy-multi/data/models' \
  --exclude='comfy-multi/data/outputs' \
  -C /home/dev ."

# Download to VPS
scp dev@verda:/tmp/verda-backup.tar.gz ~/backups/verda/
```

### Restore Backup

**On new machine:**
```bash
# Upload backup
scp ~/backups/verda/verda-backup.tar.gz new-gpu:/tmp/

# Extract
ssh new-gpu "tar -xzf /tmp/verda-backup.tar.gz -C /home/dev"

# Install system packages
ssh new-gpu "sudo apt-get install -y zsh"
ssh new-gpu "sudo chsh -s /usr/bin/zsh dev"

# Install Tailscale
ssh new-gpu "curl -fsSL https://tailscale.com/install.sh | sh"
ssh new-gpu "sudo tailscale up"
```

**Backup includes:**
- ✓ Dotfiles (.zshrc, .vimrc, etc.)
- ✓ Oh-my-zsh configuration and themes
- ✓ Git configuration
- ✓ SSH keys (~/.ssh/ directory) ⚠️
- ✓ Shell history
- ✓ Application configs

**⚠️ SSH Keys Security Note:**
- Complete backup includes private SSH keys
- Store backup in secure location only
- Never commit SSH keys to public repos

**Backup excludes:**
- ✗ Model files (~20GB+)
- ✗ Generated outputs
- ✗ Cache directories

**Backup size:** ~50-200MB (without models)

---

## Option Comparison

| Method | Time to Deploy | Provider Independent | Version Control | Team Sharing |
|--------|----------------|----------------------|-----------------|--------------|
| **Dotfiles Repo** | 10 min | ✅ Yes | ✅ Git | ✅ Easy |
| **Environment Backup** | 5 min | ✅ Yes | ❌ No | ⚠️ Manual |
| **VM Snapshot** | 2 min | ❌ Provider-locked | ❌ No | ❌ Hard |
| **Manual Setup** | 30 min | ✅ Yes | ❌ No | ❌ No |

---

## Recommended Workflow

### For Production Use

**Use comfy-multi-gpu-instance-dotfiles repo:**
1. Create and maintain comfy-multi-gpu-instance-dotfiles repo (one-time setup)
2. Update startup script to pull dotfiles automatically
3. Spin up new instances with automated setup

**Backup weekly:**
```bash
# Schedule weekly backup
crontab -e
# Add: 0 2 * * 0 /home/dev/projects/comfyui/scripts/backup-verda-env.sh
```

### For Quick Switching (Verda → RunPod)

1. **Create dotfiles** (if not already done)
2. **Spin up RunPod instance**
3. **Run startup script** (pulls dotfiles automatically)
4. **Authenticate Tailscale** and start worker
5. **Total time:** 10 minutes

### For Team Members

1. **Share comfy-multi-gpu-instance-dotfiles repo:** `git clone https://github.com/ahelme/comfy-multi-gpu-instance-dotfiles.git`
2. **Run install script:** `cd ~/comfy-multi-gpu-instance-dotfiles && ./install.sh`
3. **Consistent environment** across all team members

---

## Files Created

**On VPS:**
- `scripts/create-dotfiles-repo.sh` - Creates dotfiles backup
- `scripts/backup-verda-env.sh` - Creates complete environment backup
- `~/backups/verda/` - Backup storage directory

**On Verda (after backup):**
- `~/comfy-multi-gpu-instance-dotfiles/` - Your comfy-multi GPU instance dotfiles repository
- `~/comfy-multi-gpu-instance-dotfiles/.zshrc` - Zsh configuration
- `~/comfy-multi-gpu-instance-dotfiles/oh-my-zsh-themes/` - Custom themes
- `~/comfy-multi-gpu-instance-dotfiles/install.sh` - Automated installation

**On GitHub:**
- `github.com/ahelme/comfy-multi-gpu-instance-dotfiles` - ComfyUI GPU instance configuration repo

---

## SSH Keys Management

### Important Security Considerations

**SSH keys are critical for:**
- GitHub/GitLab repository access
- Server-to-server authentication
- Automated deployments
- Tailscale authentication (uses device keys)

**Backup strategies:**

#### Option 1: Include in Complete Backup (Most Convenient)
```bash
# Complete backup INCLUDES ~/.ssh directory
./scripts/backup-verda-env.sh

# ⚠️ CRITICAL: Store this backup securely!
# - Use encrypted storage (LUKS, VeraCrypt)
# - Never commit to public repos
# - Never upload to public cloud without encryption
# - Restrict file permissions: chmod 600 backup.tar.gz
```

#### Option 2: Separate SSH Keys Backup (Most Secure)
```bash
# Backup SSH keys separately
ssh dev@verda "tar -czf /tmp/ssh-keys-backup.tar.gz ~/.ssh"
scp dev@verda:/tmp/ssh-keys-backup.tar.gz ~/secure-backups/
chmod 600 ~/secure-backups/ssh-keys-backup.tar.gz

# Restore on new machine
scp ~/secure-backups/ssh-keys-backup.tar.gz new-gpu:~/
ssh new-gpu "tar -xzf ~/ssh-keys-backup.tar.gz -C ~"
ssh new-gpu "chmod 700 ~/.ssh && chmod 600 ~/.ssh/id_* && chmod 644 ~/.ssh/*.pub"
```

#### Option 3: Use ssh-agent Forwarding (No Backup Needed)
```bash
# On your local machine (laptop/desktop), add this to ~/.ssh/config:
Host verda
    HostName 65.108.32.146
    User dev
    ForwardAgent yes

# Now SSH from your laptop forwards your local keys
ssh verda
git clone git@github.com:ahelme/comfy-multi.git  # Uses YOUR local keys!
```

**Recommended approach:**
- **For personal dev work:** Use ssh-agent forwarding (Option 3)
- **For automated deployments:** Create deployment-specific SSH keys
- **For disaster recovery:** Include in backup but store securely (Option 1)

### Deployment-Specific SSH Keys (Best Practice)

Instead of backing up personal SSH keys, create machine-specific deploy keys:

```bash
# On new GPU instance
ssh-keygen -t ed25519 -C "verda-gpu-worker" -f ~/.ssh/id_ed25519_verda

# Add public key to GitHub as deploy key
cat ~/.ssh/id_ed25519_verda.pub
# Go to: https://github.com/ahelme/comfy-multi/settings/keys/new
# Add as "Read-only" deploy key

# Configure git to use this key
echo "Host github.com
    IdentityFile ~/.ssh/id_ed25519_verda" >> ~/.ssh/config

# Test
ssh -T git@github.com
```

**Benefits:**
- ✅ Revocable (delete deploy key, not your personal SSH key)
- ✅ Scoped (read-only access to specific repo)
- ✅ Auditable (see which machines have access)
- ✅ Secure (no personal key exposure)

---

## Troubleshooting

### Dotfiles install.sh fails

**Issue:** Permission denied or package not found

**Fix:**
```bash
# Ensure script is executable
chmod +x ~/comfy-multi-gpu-instance-dotfiles/install.sh

# Run with sudo for system packages
cd ~/comfy-multi-gpu-instance-dotfiles
sudo apt-get update
./install.sh
```

### Theme not loading

**Issue:** Bullet-train theme not appearing after restore

**Fix:**
```bash
# Verify theme copied
ls ~/.oh-my-zsh/custom/themes/

# Re-source .zshrc
source ~/.zshrc

# Check ZSH_THEME in .zshrc
grep ZSH_THEME ~/.zshrc
```

### Tailscale authentication fails

**Issue:** "tailscale up" returns error

**Fix:**
```bash
# Restart Tailscale service
sudo systemctl restart tailscaled

# Try auth again
sudo tailscale up

# Check status
tailscale status
```

### Backup script fails

**Issue:** "Permission denied" or "tar: Cannot stat"

**Fix:**
```bash
# Ensure SSH key access to Verda
ssh dev@verda "echo OK"

# Check if tar exists
ssh dev@verda "which tar"

# Run with verbose output
VERDA_HOST=dev@verda ./scripts/backup-verda-env.sh
```

---

## Related Documentation

- **[Admin Guide](./admin-guide.md)** - Main administrator documentation
- **[Backup & Restore](./admin-backup-restore.md)** - Storage strategy and restore procedures
- **[GPU Worker Setup](./admin-setup-guide.md)** - Initial GPU instance setup
- **[Deployment Guide](../implementation-deployment-verda.md)** - Full Verda deployment details

---

**Last Updated:** 2026-01-12
