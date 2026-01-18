# Verda Backup, Restore & Serverless Migration Plan

**Date:** 2026-01-14
**Status:** Phase 9 - Emergency Backup

## Context

**Current State:**
- Verda instance is SHUTDOWN - data at risk of deletion
- VPS (mello) at 157.180.76.189 is running with 23 Docker containers
- Emergency backup script exists at scripts/emergency-backup-verda.sh
- Budget strategy documented in docs/admin-budget-strategy.md
- Tailscale VPN configured (VPS: 100.99.216.71, Verda: 100.89.38.43)

**New Storage Strategy:**
- SFS 50GB: Ubuntu, user-config, Tailscale, fail2ban, SSH, Redis CLI, ComfyMulti repo
- Block Storage 40GB: Model Vault (LTX-2 models ~21GB)
- Block Storage 10GB: Temp Scratch Disk for testing

---

## Phase 9: Emergency Backup Verda

### 9.1 Pre-Backup Preparation
- [ ] Verify emergency-backup-verda.sh is latest version (2026-01-14)
- [ ] Verify script includes ALL required items (checklist below)
- [ ] **USER ACTION:** Restart Verda instance from Verda console
- [ ] SSH into Verda and upgrade system packages

### 9.2 Backup Script Verification Checklist

**System Files (backed up for restore):**
- [ ] Tailscale identity (/var/lib/tailscale/) - for persistent IP 100.89.38.43
- [ ] SSH host keys (/etc/ssh/ssh_host_*)
- [ ] Ubuntu Pro configuration (/etc/ubuntu-advantage/, /var/lib/ubuntu-advantage/)
- [ ] Fail2ban config (/etc/fail2ban/)
- [ ] UFW firewall rules (/etc/ufw/)

**User Files (backup only - restore via dotfiles repo):**
- [ ] /home/dev directory (excluding .cache, models, outputs)
- [ ] .zshrc configuration
- [ ] oh-my-zsh installation (~/.oh-my-zsh/)
- [ ] bullet-train theme and custom plugins
- [ ] SSH keys (~/.ssh/)

**Project Files:**
- [ ] ComfyUI project (~/comfy-multi)
- [ ] Custom nodes
- [ ] Workflows
- [ ] .env file

### 9.3 Restore Script Must Include

The embedded RESTORE.sh must perform:
- [ ] Install essential packages (fail2ban, ufw, redis-tools, zsh, docker)
- [ ] Restore Tailscale identity (same IP: 100.89.38.43)
- [ ] Disable SSH over Tailscale (`tailscale set --ssh=false`)
- [ ] Restore SSH host keys
- [ ] Restore Ubuntu Pro config
- [ ] Configure Fail2ban (SSH protection)
- [ ] Configure UFW (Tailscale 41641/udp + SSH 22/tcp only)
- [ ] Create dev user with zsh shell
- [ ] Restore home directory
- [ ] Install oh-my-zsh, bullet-train, custom plugins
- [ ] Set zsh as default shell
- [ ] Source .zshrc
- [ ] Restore project files
- [ ] Create symlinks for block storage:
  - /mnt/models -> ~/comfy-multi/data/models
  - /mnt/scratch -> ~/comfy-multi/data/outputs
- [ ] Instructions for mounting block storage
- [ ] Instructions for model download

### 9.4 Execute Backup
- [ ] Run `./scripts/emergency-backup-verda.sh` from mello (VPS)
- [ ] Verify SSH connection to Verda works
- [ ] Monitor backup progress
- [ ] Verify all files transferred successfully

### 9.5 Post-Backup Verification
- [ ] List all backed up files with sizes
- [ ] Verify backup directory on mello: ~/backups/verda-emergency/
- [ ] Check total backup size
- [ ] Identify any missing files
- [ ] Create manifest of backed up files and source locations

### 9.6 Cron Job Setup (Optional)
- [ ] Create cron job for regular backups
- [ ] User folder backup (daily)
- [ ] System config backup (weekly)
- [ ] Dotfiles repo sync

---

## Phase 10: Research Verda Containers & Serverless Options

### 10.1 Research Verda Serverless
- [ ] Review https://docs.verda.com/containers/overview
- [ ] Document pricing model (per-second? per-minute?)
- [ ] Document billing intervals
- [ ] Document cold start times
- [ ] Document storage integration (SFS/Block mounting)
- [ ] Document GPU availability (V100, H100)

### 10.2 Research Competitor Pricing
- [ ] RunPod Serverless
- [ ] Vast.ai
- [ ] Modal
- [ ] Banana.dev
- [ ] Replicate

### 10.3 Create Documentation
- [ ] Create docs/serverless-comparison.md
- [ ] Create docs/verda-instance-serverless-price-comparison.md
- [ ] Compare against current strategy from admin-verda-setup.md:
  - SFS 50GB @ $0.20/GB = $10/month
  - Block 40GB @ $0.10/GB = $4/month
  - Block 10GB @ $0.10/GB = $1/month
  - V100 testing: $0.14/hr x 10hrs = $1.40
  - H100 workshop: $4/hr x 6hrs = $24

### 10.4 Update Restore Script
- [ ] Add serverless deployment option
- [ ] Document container registry requirements

---

## Phase 11: Test Restore to Verda Instance

### 11.1 Verda Console Setup (USER ACTION REQUIRED)
- [ ] Create new 50GB SFS volume
- [ ] Create 40GB Block Storage - "Model Vault"
- [ ] Create 10GB Block Storage - "Scratch Disk"
- [ ] Provision V100 16GB GPU instance ($0.14/hr for testing)
- [ ] Attach storage volumes to instance

### 11.2 Storage Mount Setup
```bash
# Mount Block Storage (after provisioning)
sudo mkfs.ext4 /dev/vdb  # Model Vault
sudo mkfs.ext4 /dev/vdc  # Scratch Disk
sudo mkdir -p /mnt/models /mnt/scratch
sudo mount /dev/vdb /mnt/models
sudo mount /dev/vdc /mnt/scratch
# Add to /etc/fstab for persistence
```

### 11.3 Restore Execution
- [ ] Transfer backup files to new instance
- [ ] Run RESTORE.sh as root
- [ ] Verify Tailscale connects with IP 100.89.38.43
- [ ] Verify SSH access works
- [ ] Verify security hardening (UFW, fail2ban active)
- [ ] Verify zsh is default shell
- [ ] Verify oh-my-zsh and bullet-train working

### 11.4 Model Download
- [ ] Download LTX-2 checkpoint (~10GB)
- [ ] Download text encoder (~5GB)
- [ ] Download upscaler (~2GB)
- [ ] Download LoRAs (~4GB)
- [ ] Total: ~21GB to /mnt/models

### 11.5 Application Testing
- [ ] Create symlinks to block storage
- [ ] Start Docker containers
- [ ] Test Redis connectivity to VPS (100.99.216.71:6379)
- [ ] Test comfy.ahelme.net/user01
- [ ] Run a test LTX-2 workflow
- [ ] Verify outputs saved to scratch disk

---

## Phase 12: Docker Container Registry & Serverless

### 12.1 Container Registry Setup
- [ ] Choose registry (Verda Registry, Docker Hub, GitHub Container Registry)
- [ ] Create account/project
- [ ] Build ComfyUI worker image with LTX-2 support
- [ ] Tag and push image
- [ ] Document image versions

### 12.2 Serverless Configuration
- [ ] Configure Verda Containers with custom image
- [ ] Set up storage mounts (SFS for system, Block for models)
- [ ] Configure environment variables
- [ ] Set scaling parameters (min/max instances)
- [ ] Configure GPU type (V100 for test, H100 for workshop)

### 12.3 Testing
- [ ] Test cold start time
- [ ] Test job execution
- [ ] Measure actual GPU time per job
- [ ] Calculate cost per video generation
- [ ] Compare to dedicated instance costs

### 12.4 Workshop Preparation
- [ ] Pre-warm containers before workshop
- [ ] Configure autoscaling limits
- [ ] Set up monitoring/alerts
- [ ] Document failover to dedicated instance

---

## Cost Comparison

### Current Strategy (Dedicated Instance)
| Component | Size | Monthly Cost |
|-----------|------|--------------|
| SFS (System) | 50GB | $10.00 |
| Block (Models) | 40GB | $4.00 |
| Block (Scratch) | 10GB | $1.00 |
| **Storage Total** | 100GB | **$15.00/month** |

| GPU Usage | Rate | Hours | Cost |
|-----------|------|-------|------|
| V100 Testing | $0.14/hr | 10 | $1.40 |
| H100 Workshop | $4.00/hr | 6 | $24.00 |
| **Compute Total** | | 16 hrs | **$25.40** |

**Grand Total:** ~$40-50 for workshop

### Serverless (TBD in Phase 10)
| Component | Pricing | Est. Cost |
|-----------|---------|-----------|
| Cold storage | TBD | TBD |
| GPU per-second | TBD | TBD |
| **Potential Savings** | | 50%+? |

---

## Deliverables

1. **implementation-backup-restore.md** - Full plan documentation
2. **docs/serverless-comparison.md** - Serverless pricing research
3. **docs/verda-instance-serverless-price-comparison.md** - Cost comparison
4. **Updated scripts/emergency-backup-verda.sh** - If changes needed
5. **Updated progress-2.md** - Session notes
6. **Backup manifest** - List of all backed up files

---

## Risk Mitigation

- **Data Loss Risk:** Run backup IMMEDIATELY after Verda restarts
- **IP Change Risk:** Backup Tailscale identity to preserve 100.89.38.43
- **Cost Risk:** Test on V100 ($0.14/hr) before H100 ($4/hr)
- **Time Risk:** Verda may auto-delete data if instance not restarted soon

---

## Next Actions (When Plan Approved)

1. Verify emergency-backup-verda.sh has all required items
2. **USER:** Restart Verda from console
3. SSH into Verda, upgrade system
4. Execute backup from mello
5. Verify backup completeness
6. Continue with Phase 10 research
