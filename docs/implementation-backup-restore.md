**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-14
**Doc Updated:** 2026-01-14

---

# Implementation: Verda Backup, Restore & Serverless Migration

Complete guide for backing up Verda GPU instance, restoring to new storage configuration, and evaluating serverless options.

---

## Overview

This document covers Phases 9-12 of the ComfyUI Multi-User Workshop implementation:

| Phase | Description | Status |
|-------|-------------|--------|
| **Phase 9** | Emergency Backup Verda | In Progress |
| **Phase 10** | Research Verda Containers & Serverless | Pending |
| **Phase 11** | Test Restore to Verda Instance | Pending |
| **Phase 12** | Docker Container Registry & Serverless | Pending |

---

## Backup Locations Summary

| Data | Location | Size | Notes |
|------|----------|------|-------|
| **Models (LTX-2)** | Cloudflare R2 | ~45GB | `comfy-multi-model-vault-backup` bucket |
| **Configs** | Hetzner VPS (mello) | ~32KB | `~/backups/verda-block-recovery-20260114/` |
| **Tailscale identity** | Hetzner VPS (mello) | 5KB | Preserves IP 100.89.38.43 |
| **oh-my-zsh custom** | Hetzner VPS (mello) | 9KB | bullet-train theme |
| **.zshrc** | Hetzner VPS (mello) | 14KB | Full shell config |
| **.env** | Hetzner VPS (mello) | 1.6KB | Environment variables |

### Cloudflare R2 Details

- **Bucket:** `comfy-multi-model-vault-backup`
- **Endpoint:** `https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com`
- **Location:** Oceania (OC)
- **Cost:** ~$0.68/month (no egress fees)
- **Contents:**
  - `checkpoints/ltx-2-19b-dev-fp8.safetensors` (26GB)
  - `text_encoders/gemma_3_12B_it.safetensors` (19GB)

---

## Phase 9: Emergency Backup Verda

### Prerequisites

- VPS (mello) running at 157.180.76.189
- SSH access to Verda configured (`ssh dev@verda` works)
- Verda instance must be RUNNING (start from Verda console)

### Backup Script

**Location:** `scripts/emergency-backup-verda.sh`

**Run from:** VPS mello (NOT from Verda!)

```bash
cd ~/projects/comfyui
./scripts/emergency-backup-verda.sh
```

### What Gets Backed Up

| Item | Source | Purpose |
|------|--------|---------|
| Tailscale identity | /var/lib/tailscale/ | Preserves IP 100.89.38.43 |
| SSH host keys | /etc/ssh/ssh_host_* | Preserves server identity |
| Ubuntu Pro config | /etc/ubuntu-advantage/ | ESM updates |
| Fail2ban config | /etc/fail2ban/ | SSH protection |
| UFW rules | /etc/ufw/ | Firewall config |
| Home directory | /home/dev/ | User configs, .zshrc |
| oh-my-zsh custom | ~/.oh-my-zsh/custom/ | Themes, plugins |
| ComfyUI project | ~/comfy-multi/ | App code |
| Tailscale IP | tailscale ip -4 | Reference |

### Backup Location

```
~/backups/verda-emergency/
├── tailscale-identity-YYYYMMDD-HHMMSS.tar.gz
├── ssh-host-keys-YYYYMMDD-HHMMSS.tar.gz
├── ubuntu-pro-YYYYMMDD-HHMMSS.tar.gz
├── fail2ban-YYYYMMDD-HHMMSS.tar.gz
├── ufw-YYYYMMDD-HHMMSS.tar.gz
├── home-dev-YYYYMMDD-HHMMSS.tar.gz
├── ohmyzsh-custom-YYYYMMDD-HHMMSS.tar.gz
├── comfy-project-YYYYMMDD-HHMMSS.tar.gz
├── tailscale-ip.txt
└── RESTORE.sh
```

### RESTORE.sh Capabilities

The generated restore script performs:

1. **Package Installation**
   - fail2ban, ufw, redis-tools, zsh, docker, git, curl, wget

2. **Security Hardening**
   - Restore Tailscale with same IP (100.89.38.43)
   - Disable SSH over Tailscale
   - Configure Fail2ban (SSH brute-force protection)
   - Configure UFW (SSH + Tailscale ports only)

3. **User Environment**
   - Create dev user with zsh shell
   - Restore home directory
   - Install oh-my-zsh if needed
   - Restore/install bullet-train theme
   - Restore custom oh-my-zsh plugins

4. **Project Setup**
   - Restore ComfyUI project
   - Instructions for block storage mounting
   - Instructions for model download

---

## Phase 10: Research Verda Containers & Serverless

### Research Tasks

1. **Verda Containers** (https://docs.verda.com/containers/overview)
   - Pricing model (per-second? per-minute?)
   - Billing intervals
   - Cold start times
   - Storage integration (SFS/Block mounting)
   - GPU availability (V100, H100)

2. **Competitor Pricing**
   - RunPod Serverless
   - Vast.ai
   - Modal
   - Banana.dev
   - Replicate

### Documentation to Create

- `docs/serverless-comparison.md`
- `docs/verda-instance-serverless-price-comparison.md`

### Current Strategy Costs (Dedicated Instance)

| Storage | Size | Monthly |
|---------|------|---------|
| SFS (System) | 50GB | $10.00 |
| Block (Models) | 40GB | $4.00 |
| Block (Scratch) | 10GB | $1.00 |
| **Total Storage** | 100GB | **$15.00** |

| Compute | Rate | Hours | Cost |
|---------|------|-------|------|
| V100 Testing | $0.14/hr | 10 | $1.40 |
| H100 Workshop | $4.00/hr | 6 | $24.00 |
| **Total Compute** | | 16 | **$25.40** |

**Grand Total:** ~$40-50 for workshop

---

## Phase 11: Test Restore to Verda Instance

### Storage Setup (Verda Console)

1. **Create 50GB SFS** - Ubuntu, ComfyMulti, user config
2. **Create 40GB Block Storage** - "Model Vault"
3. **Create 10GB Block Storage** - "Scratch Disk"
4. **Provision V100 16GB** - $0.14/hr for testing

### Mount SFS (Shared File System)

The SFS contains your system files, user config, and ComfyUI project.

```bash
# 1. Create mount directory
sudo mkdir -p /mnt/SFS-3kFzriy5

# 2. Mount the shared filesystem
sudo mount -t nfs -o nconnect=16 nfs.fin-01.datacrunch.io:/SFS-3kFzriy5-7f7ec672 /mnt/SFS-3kFzriy5

# 3. Add to fstab for persistence (auto-mount on reboot)
grep -qxF 'nfs.fin-01.datacrunch.io:/SFS-3kFzriy5-7f7ec672 /mnt/SFS-3kFzriy5 nfs defaults,nconnect=16 0 0' /etc/fstab || \
  echo 'nfs.fin-01.datacrunch.io:/SFS-3kFzriy5-7f7ec672 /mnt/SFS-3kFzriy5 nfs defaults,nconnect=16 0 0' | sudo tee -a /etc/fstab
```

**Note:** You can customize the mount point (e.g., `/mnt/sfs` instead of `/mnt/SFS-3kFzriy5`).

### Mount Block Storage

Block storage is for models and scratch data.

```bash
# As root on new Verda instance
mkfs.ext4 /dev/vdb  # Model Vault (only run once on NEW volumes!)
mkfs.ext4 /dev/vdc  # Scratch Disk (only run once on NEW volumes!)
mkdir -p /mnt/models /mnt/scratch
mount /dev/vdb /mnt/models
mount /dev/vdc /mnt/scratch
chown dev:dev /mnt/models /mnt/scratch

# Add to fstab for persistence
echo '/dev/vdb /mnt/models ext4 defaults 0 0' >> /etc/fstab
echo '/dev/vdc /mnt/scratch ext4 defaults 0 0' >> /etc/fstab
```

### Restore Steps

```bash
# 1. Transfer backup to new instance
scp -r ~/backups/verda-emergency/ root@new-verda:~/

# 2. SSH in and run restore
ssh root@new-verda
cd ~/verda-emergency
bash RESTORE.sh

# 3. Create symlinks (as dev user)
su - dev
mkdir -p ~/comfy-multi/data
ln -sf /mnt/models ~/comfy-multi/data/models
ln -sf /mnt/scratch ~/comfy-multi/data/outputs
```

### Model Restore

**Option A: Restore from Cloudflare R2 (Recommended - faster)**

Models are backed up to Cloudflare R2 for fast restore:

```bash
# Install AWS CLI (if not present)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
cd /tmp && unzip -o awscliv2.zip && ./aws/install

# Configure R2 credentials
mkdir -p ~/.aws
cat > ~/.aws/credentials << 'EOF'
[default]
aws_access_key_id = <R2_ACCESS_KEY_ID>
aws_secret_access_key = <R2_SECRET_ACCESS_KEY>
EOF

# Download models from R2 (~45GB, ~15-20 min)
cd /mnt/models
R2_ENDPOINT="https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com"
R2_BUCKET="comfy-multi-model-vault-backup"

aws s3 sync s3://$R2_BUCKET/ . --endpoint-url $R2_ENDPOINT
```

**Option B: Download from HuggingFace (Fallback)**

If R2 backup unavailable, download fresh from HuggingFace (~45GB, ~30 min):

```bash
cd /mnt/models
mkdir -p checkpoints text_encoders latent_upscale_models loras

# Main checkpoint (~26GB)
wget https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-dev-fp8.safetensors \
  -O checkpoints/ltx-2-19b-dev-fp8.safetensors

# Text encoder (~19GB)
wget https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it.safetensors \
  -O text_encoders/gemma_3_12B_it.safetensors

# Upscaler (~2GB)
wget https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-spatial-upscaler-x2-1.0.safetensors \
  -O latent_upscale_models/ltx-2-spatial-upscaler-x2-1.0.safetensors

# LoRAs (~4GB)
wget https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled-lora-384.safetensors \
  -O loras/ltx-2-19b-distilled-lora-384.safetensors

wget https://huggingface.co/Lightricks/LTX-2-19b-LoRA-Camera-Control-Dolly-Left/resolve/main/ltx-2-19b-lora-camera-control-dolly-left.safetensors \
  -O loras/ltx-2-19b-lora-camera-control-dolly-left.safetensors
```

### Verification Checklist

- [ ] Tailscale IP is 100.89.38.43
- [ ] SSH access works
- [ ] UFW active (SSH + Tailscale only)
- [ ] Fail2ban active
- [ ] zsh is default shell
- [ ] oh-my-zsh with bullet-train working
- [ ] Block storage mounted at /mnt/models and /mnt/scratch
- [ ] Symlinks created to ComfyUI directories
- [ ] Redis connectivity to VPS (100.99.216.71:6379)
- [ ] Docker containers start successfully
- [ ] Test workflow runs on user01

---

## Phase 12: Docker Container Registry & Serverless

### Container Registry Options

1. **Docker Hub** - Free tier available
2. **GitHub Container Registry** - Free for public repos
3. **Verda Registry** - If available

### Build and Push

```bash
# Build worker image
cd ~/projects/comfyui
docker build -t comfyui-worker:latest -f comfyui-worker/Dockerfile .

# Tag for registry
docker tag comfyui-worker:latest username/comfyui-worker:latest

# Push
docker push username/comfyui-worker:latest
```

### Serverless Configuration (TBD)

Depends on Phase 10 research results.

---

## Quick Reference Commands

### Backup (from mello)
```bash
cd ~/projects/comfyui
./scripts/emergency-backup-verda.sh
```

### Restore (on new Verda)
```bash
cd ~/verda-emergency
sudo bash RESTORE.sh
```

### Check Tailscale
```bash
tailscale status
tailscale ip -4
```

### Check Security
```bash
sudo ufw status
sudo fail2ban-client status
```

### Check Storage
```bash
df -h /mnt/models /mnt/scratch
ls -la ~/comfy-multi/data/
```

---

## Related Documentation

- [Budget Strategy](./admin-budget-strategy.md) - Cost optimization
- [CPU Testing Guide](./admin-cpu-testing-guide.md) - Free development
- [GPU Environment Backup](./admin-gpu-environment-backup.md) - Dotfiles approach
- [Scripts Reference](./admin-scripts.md) - All available scripts
- [Verda Setup](./admin-verda-setup.md) - Verda configuration

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Data loss | Run backup IMMEDIATELY when Verda restarts |
| IP change | Backup Tailscale identity preserves 100.89.38.43 |
| Cost overrun | Test on V100 ($0.14/hr) before H100 ($4/hr) |
| Storage full | Start with 40GB models + 10GB scratch, expand as needed |

---

**Last Updated:** 2026-01-14
