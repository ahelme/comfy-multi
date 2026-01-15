**Doc Title:** Admin Guide - Backup & Restore
**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-14
**Doc Updated:** 2026-01-15

---

# Admin Guide: Backup & Restore

Quick reference for backing up and restoring the Verda GPU instance.

---

## Backup Locations

| Data | Location | Size |
|------|----------|------|
| **Models (LTX-2)** | Cloudflare R2 `comfy-multi-model-vault-backup` | ~45GB |
| **Configs** | Hetzner VPS (mello) `~/backups/verda/` | ~50KB |

---

## Running Backups

### From mello VPS

```bash
cd ~/projects/comfyui

# Config-only backup (fast, ~2 min)
./scripts/backup-verda.sh

# Full backup including models to Cloudflare R2 (compares sizes, uploads if different)
./scripts/backup-verda.sh --with-models
```

### What Gets Backed Up

| Item | Destination |
|------|-------------|
| Tailscale identity | mello (preserves IP 100.89.38.43) |
| SSH host keys | mello |
| Ubuntu Pro config | mello |
| Fail2ban config | mello |
| UFW firewall rules | mello |
| Home directory (.zshrc, .ssh) | mello |
| oh-my-zsh custom (bullet-train) | mello |
| ComfyUI project | mello |
| Models (.safetensors) | Cloudflare R2 (with `--with-models` flag) |

---

## Restoring to New Instance

### 1. Provision Instance (Verda Console)

⚠️ **CRITICAL: Verda WIPES block storage attached during provisioning!**

- Create A100/H100 instance (spot for cost savings)
- **Do NOT attach block storage during creation** - it will be formatted/wiped!
- Instance will boot with ephemeral OS disk only

### 1b. Attach Block Storage (AFTER instance is running)

For **existing** block storage with data:
1. **Shut down** the instance (required for attachment)
2. Attach block storage via Verda Dashboard
3. Boot instance
4. Mount: `mount /dev/vdc /mnt/models`

For **new** block storage:
1. Create 60GB volume in Verda Dashboard
2. Shut down instance, attach volume, boot
3. Format: `mkfs.ext4 /dev/vdc`
4. Mount: `mount /dev/vdc /mnt/models`

### 2. Transfer & Run Restore

```bash
# From mello
scp -r ~/backups/verda/ root@<new-verda-ip>:~/

# On new instance
ssh root@<new-verda-ip>
cd ~/verda
sudo bash RESTORE.sh [OPTIONS]
```

### 3. RESTORE.sh Model Options

The restore script handles model download automatically with these flags:

| Flag | Description |
|------|-------------|
| `--with-models` | Download models from R2 (default if no models found) |
| `--skip-models` | Skip download, use existing models |
| `--fresh-models` | Delete existing models and download fresh from R2 |
| *(no flag)* | Interactive prompt if models detected |

**Examples:**
```bash
# Fully automated - download models if missing
sudo bash RESTORE.sh --with-models

# Skip models (using attached block storage with models)
sudo bash RESTORE.sh --skip-models

# Fresh install - delete and re-download everything
sudo bash RESTORE.sh --fresh-models

# Interactive - script will prompt if models detected
sudo bash RESTORE.sh
```

**Smart Detection:** The script automatically checks:
- `/mnt/models` - default model directory
- `/mnt/block`, `/mnt/data`, `/mnt/storage` - common block storage mounts
- Unmounted block devices with filesystems (warns you to mount them)

### 4. Manual Model Restore (if needed)

If models didn't download (missing R2 credentials):

```bash
# As dev user on Verda
export AWS_ACCESS_KEY_ID=<R2_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<R2_SECRET_ACCESS_KEY>
R2_ENDPOINT="https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com"

# Download all models (idempotent - safe to restart)
aws s3 sync s3://comfy-multi-model-vault-backup/ /mnt/models/ --endpoint-url $R2_ENDPOINT
```

**Note:** R2 credentials are stored in mello's `.env` file (gitignored).

---

## Verification Checklist

After restore, verify:

- [ ] `tailscale ip -4` returns 100.89.38.43
- [ ] `ssh dev@verda` works from mello
- [ ] `sudo ufw status` shows SSH + Tailscale only
- [ ] `sudo fail2ban-client status` shows sshd jail active
- [ ] `echo $SHELL` shows /bin/zsh
- [ ] oh-my-zsh prompt displays correctly
- [ ] Models present in expected location
- [ ] `.env` file exists in ~/comfy-multi/

---

## Quick Commands

### Check Tailscale
```bash
tailscale status
tailscale ip -4
```

### Check Security
```bash
sudo ufw status
sudo fail2ban-client status sshd
```

### Check R2 Bucket Contents
```bash
R2_ENDPOINT="https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com"
aws --endpoint-url $R2_ENDPOINT s3 ls s3://comfy-multi-model-vault-backup/ --recursive --human-readable
```

---

## Cloudflare R2 Details

| Field | Value |
|-------|-------|
| Bucket | `comfy-multi-model-vault-backup` |
| Endpoint | `https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com` |
| Location | Oceania (OC) |
| Cost | ~$0.68/month (no egress fees) |

**Note:** R2 uses S3-compatible API, so AWS CLI works with `--endpoint-url` flag.

---

## Troubleshooting

### Block Storage Got Wiped on New Instance
**Symptom:** Attached block storage shows Ubuntu OS partitions instead of your models.

**Cause:** Attaching block storage during instance provisioning can cause Verda to format it with the OS image.

**Solution:**
1. Provision instance WITHOUT block storage
2. Attach block storage AFTER instance is running
3. Mount the existing filesystem (don't format)

```bash
# Check attached devices
lsblk -f

# Mount existing block storage (usually /dev/vdc or /dev/sdb)
sudo mount /dev/vdc /mnt/models

# If models are there, add to fstab for persistence
echo '/dev/vdc /mnt/models ext4 defaults 0 0' | sudo tee -a /etc/fstab
```

### SSH Host Key Changed
```bash
ssh-keygen -R <verda-ip>
```

### Tailscale Won't Connect
```bash
sudo systemctl restart tailscaled
tailscale up
```

### AWS CLI Not Found on Verda
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
cd /tmp && unzip -o awscliv2.zip && sudo ./aws/install
```

### R2 Transfer In Progress
If backup script reports "transfer already in progress":
```bash
# Check progress
ssh dev@verda 'ps aux | grep "aws s3"'

# Kill and restart if needed
ssh dev@verda 'pkill -f "aws s3"'
./scripts/backup-verda.sh --with-models
```

---

**Related Docs:**
- [Implementation Details](./implementation-backup-restore.md)
- [Verda Setup](./admin-verda-setup.md)
- [Budget Strategy](./admin-budget-strategy.md)
