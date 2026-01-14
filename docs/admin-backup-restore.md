**Doc Title:** Admin Guide - Backup & Restore
**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-14
**Doc Updated:** 2026-01-14

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

- Create V100 16GB instance ($0.14/hr for testing)
- Attach storage volumes if needed

### 2. Transfer & Run Restore

```bash
# From mello
scp -r ~/backups/verda/ root@<new-verda-ip>:~/

# On new instance
ssh root@<new-verda-ip>
cd ~/verda
sudo bash RESTORE.sh
```

### 3. Restore Models from Cloudflare R2

```bash
# As dev user on Verda
cd /mnt/models  # or wherever models should go

# Configure AWS CLI for R2 (S3-compatible API)
export AWS_ACCESS_KEY_ID=<R2_ACCESS_KEY_ID>
export AWS_SECRET_ACCESS_KEY=<R2_SECRET_ACCESS_KEY>

# Download all models from R2
R2_ENDPOINT="https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com"
aws s3 sync s3://comfy-multi-model-vault-backup/ . --endpoint-url $R2_ENDPOINT
```

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
