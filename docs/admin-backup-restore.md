**Doc Title:** Admin Guide - Backup & Restore
**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-16
**Doc Updated:** 2026-01-17

---

# Admin Guide: Backup & Restore

Quick reference for backing up and restoring the Verda GPU instance.

---

## Storage Strategy

| Storage | Purpose | Persistence | Cost |
|---------|---------|-------------|------|
| **Verda SFS** | Models + Container (workshop month) | Temporary | ~$14/month |
| **Cloudflare R2** | Complete backup (models, container, configs) | Permanent | ~$2/month |
| **Mello VPS** | Working backups, scripts source | Permanent | (existing) |

---

## Critical Principles

**1. Check Before Downloading/Restoring**

Never download if file already exists. Priority depends on file type:

| File Type | Check Order | Rationale |
|-----------|-------------|-----------|
| **Models** (~45GB) | SFS → R2 | Large, live on SFS |
| **Config, identity, container** | /root/ → SFS → R2 | Extracted to instance |
| **Scripts** | /root/ → SFS → GitHub | Small, versioned |

**2. Tailscale Identity Must Be Restored BEFORE Starting Tailscale**

If Tailscale starts without the backed-up identity, it gets a **NEW IP address**.
The restore scripts restore `/var/lib/tailscale/` BEFORE running `tailscale up`.
This preserves the expected IP: **100.89.38.43**

---

## Backup Locations

**Primary: Cloudflare R2** (two buckets)

**Models Bucket:** `comfy-multi-model-vault-backup` (Oceania)
| Data | R2 Path | Size |
|------|---------|------|
| **Model Checkpoints** | `checkpoints/*.safetensors` | ~25-50 GB |
| **Text Encoders** | `text_encoders/*.safetensors` | ~20 GB |

**Cache Bucket:** `comfy-multi-cache` (Eastern Europe)
| Data | R2 Path | Size |
|------|---------|------|
| **Worker Container** | `worker-image.tar.gz` | 2.5 GB |
| **Config Backup** | `verda-config-backup.tar.gz` | 14 MB |

See workshop model requirements in [admin-guide.md](./admin-guide.md).

**Primary: GitHub** (versioned scripts)

| Script | Repo |
|--------|------|
| `quick-start.sh` | `ahelme/comfymulti-scripts` (private) |
| `RESTORE-SFS.sh` | `ahelme/comfymulti-scripts` (private) |
| `RESTORE-BLOCK-MELLO.sh` | `ahelme/comfymulti-scripts` (private) |

**Secondary: Mello VPS** (working copies)

| Data | Location |
|------|----------|
| Config backups (dated) | `~/backups/verda/*.tar.gz` |
| Scripts (development) | `~/projects/comfymulti-scripts/` |
| Container image | `~/backups/verda/worker-image.tar.gz` |

---

## Running Backups

### From Mello VPS

```bash
cd ~/projects/comfyui

# Config-only backup (fast, ~2 min)
./scripts/backup-verda.sh

# Full backup including models to Cloudflare R2
./scripts/backup-verda.sh --with-models
```

### What Gets Backed Up

| Item | Destination |
|------|-------------|
| Tailscale identity | mello (preserves IP 100.89.38.43) |
| SSH host keys | mello |
| Fail2ban config | mello |
| UFW firewall rules | mello |
| Home directory (.zshrc, .ssh) | mello |
| oh-my-zsh custom (bullet-train) | mello |
| ComfyUI project | mello |
| Worker container image | mello |
| Models (.safetensors) | Cloudflare R2 (with `--with-models` flag) |

---

## Restore Scripts

Two restore scripts in `~/backups/verda/` on mello:

| Script | Storage | When to Use |
|--------|---------|-------------|
| **RESTORE-SFS.sh** | SFS (Shared File System) | Workshop month (recommended) |
| **RESTORE-BLOCK-MELLO.sh** | Block Storage | Alternative workflow |

Both scripts perform identical system restore (Tailscale, security, user environment). Only difference is storage type in NEXT STEPS.

---

## Restoring to New Instance

### Step 1: Provision Instance

1. Get latest `quick-start.sh` from **https://github.com/ahelme/comfymulti-scripts** (private repo)
2. In Verda Console, create GPU instance (A100/H100)
3. Attach your SFS (create one first if needed - 50GB recommended)
4. In **"Startup Script"** field, paste `quick-start.sh` contents (no modifications needed)
5. Add **both SSH keys**: user's Mac key + Mello VPS key
6. Provision instance

### Step 2: Run quick-start.sh

Instance boots → script runs → can't find SFS → exits with instructions.

1. SSH into instance
2. Get **PSEUDOPATH** from Verda Dashboard: Storage tab → SFS dropdown → PSEUDOPATH
3. Run:
```bash
bash /root/quick-start.sh <PSEUDOPATH>
# Example: bash /root/quick-start.sh nfs.fin-01.datacrunch.io:/SFS-Model-Vault-273f8ad9
```

**What quick-start.sh does (resumable):**
1. Mounts SFS at /mnt/sfs using provided PSEUDOPATH
2. Adds mello SSH key for access
3. Gets files (checking /root/ → SFS → remote in order):
   - RESTORE scripts from GitHub (~20KB)
   - Config backup from R2 (~14MB)
   - Container image from R2 (~2.5GB) - background download
4. Extracts config backup to /root/
5. Runs RESTORE-SFS.sh automatically (restores Tailscale identity BEFORE starting Tailscale)
6. Loads container from SFS (or waits for R2 download)
7. Creates symlinks for ComfyUI

### Step 3: Authenticate Tailscale (manual)

RESTORE-SFS.sh verifies Tailscale IP is 100.89.38.43 before prompting. If wrong, it aborts with an error (logged to `/root/restore-error.log`).

When prompted, authenticate Tailscale:

```bash
sudo tailscale up --ssh=false
# Visit the URL shown in your browser to authenticate
```

### Step 4: Verify & Start Worker

```bash
# Check models are on SFS
ls -lh /mnt/models/checkpoints/

# Check container is loaded
docker images | grep comfyui

# Start worker
su - dev
cd ~/comfy-multi
docker compose up -d worker-1

# Verify Redis connection to mello
redis-cli -h 100.99.216.71 -p 6379 -a '<password>' ping
# Should return: PONG
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
- [ ] Models present at /mnt/models/
- [ ] Container loaded: `docker images | grep comfyui`
- [ ] Redis connection: `redis-cli -h 100.99.216.71 -p 6379 -a '<password>' ping`

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

# Models bucket (Oceania)
aws --endpoint-url $R2_ENDPOINT s3 ls s3://comfy-multi-model-vault-backup/ --recursive --human-readable

# Cache bucket (EU)
aws --endpoint-url $R2_ENDPOINT s3 ls s3://comfy-multi-cache/ --human-readable
```

---

## Cloudflare R2 Details

| Field | Value |
|-------|-------|
| Endpoint | `https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com` |
| Cost | ~$2/month total (no egress fees) |

**Models Bucket:** `comfy-multi-model-vault-backup` (Oceania)
```
checkpoints/*.safetensors       (LTX-2, Flux.2 Klein, etc.)
text_encoders/*.safetensors     (model text encoders)
```

**Cache Bucket:** `comfy-multi-cache` (Eastern Europe)
```
worker-image.tar.gz             ~2.5 GB
verda-config-backup.tar.gz      ~14 MB
```

**Note:** Scripts (RESTORE-*.sh, quick-start.sh) are in GitHub repo `ahelme/comfymulti-scripts`.

---

## Troubleshooting

### Tailscale Got New IP Instead of 100.89.38.43
**Cause:** Tailscale identity wasn't restored before running `tailscale up`.

**Solution:** Restore identity from backup:
```bash
sudo systemctl stop tailscaled
sudo tar -xzf /root/tailscale-identity-*.tar.gz -C /var/lib/
sudo systemctl start tailscaled
tailscale ip -4  # Should now show 100.89.38.43
```

### quick-start.sh Failed to Download from R2
**Cause:** Network issue or R2 credentials problem.

**Solution:** Check error log and retry:
```bash
cat /root/restore-error.log
# Then retry quick-start.sh
```

### SSH Host Key Changed
```bash
ssh-keygen -R <verda-ip>
```

### SFS Won't Mount
```bash
# Check NFS client installed
apt-get install -y nfs-common

# Check endpoint is correct
ping <sfs-endpoint>

# Try manual mount with verbose
mount -v -t nfs <sfs-endpoint> /mnt/sfs
```

### AWS CLI Not Found
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
cd /tmp && unzip -o awscliv2.zip && sudo ./aws/install
```

---

## Related Docs

- [Workshop Workflow](./admin-workflow-workshop.md) - Daily startup procedures
- [Scripts Reference](./admin-scripts.md) - All available scripts
- [Verda Setup](./admin-verda-setup.md) - Verda configuration
- [Block Storage Workflow](./archive/admin-backup-restore-block-storage.md) - Alternative workflow

---

**Archive:** For Block Storage workflow, see [admin-backup-restore-block-storage.md](./archive/admin-backup-restore-block-storage.md)
