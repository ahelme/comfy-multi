**Doc Title:** Admin Workflow - Workshop Month
**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-15
**Doc Updated:** 2026-01-15

---

# Workshop Month Workflow

Quick reference for setting up and running the workshop infrastructure using Verda Shared File System (SFS).

---

## Storage Strategy

| Storage | Purpose | Cost (AUD/month) |
|---------|---------|------------------|
| **Verda SFS 50GB** | Models + Container (workshop month only) | ~$14 |
| **Cloudflare R2** | Permanent backup of models | ~$1 |
| **Hetzner VPS** | Configs, RESTORE.sh, container backup | (existing) |

---

## JAN 31: Initial Setup (~45 min)

### 1. Create Shared File System

```
Verda Dashboard → Storage → Shared File System → Create
- Size: 50GB (expandable in 1GB increments)
- Note the mount endpoint (e.g., 10.x.x.x:/share)
```

### 2. Get SFS Mount Endpoint

```
Verda Dashboard → Storage → Shared File Systems → SFS-Model-Vault
Copy the mount command - note Verda adds a random ID suffix
Example: nfs.fin-01.datacrunch.io:/SFS-Model-Vault-273f8ad9
```

### 3. Create GPU Instance

```
Verda Dashboard → Instances → Create
- Type: A100 80GB or H100 (spot for cost savings)
- Attach SFS: SFS-Model-Vault
- Add SSH keys: Your key + mello VPS key
- Add provisioning script: quick-start.sh
```

### 4. Mount SFS & Restore

```bash
# SSH to instance
ssh root@<instance-ip>

# Mount SFS (use YOUR endpoint from Step 2)
mkdir -p /mnt/models
mount -t nfs -o nconnect=16 <sfs-endpoint> /mnt/models

# Add to fstab for persistence
echo "<sfs-endpoint> /mnt/models nfs defaults 0 0" >> /etc/fstab

# Transfer backup from mello
scp -r mello:~/backups/verda/ ~/

# Run restore with model download
cd ~/verda
sudo bash RESTORE.sh --with-models --build-container
```

### 5. Authenticate Tailscale

After RESTORE.sh runs, Tailscale is installed but needs authentication:

```bash
# Authenticate Tailscale (opens browser URL)
sudo tailscale up --ssh=false

# You'll see a URL like: https://login.tailscale.com/a/abc123xyz
# Visit this URL in your browser to authenticate the device

# Verify connection (should show mello VPS)
tailscale status
tailscale ip -4  # Should be 100.89.38.43
```

**Note:** `--ssh=false` disables Tailscale SSH - we use regular SSH instead.

### 6. Verify Setup

```bash
# Check models (~45GB)
ls -lh /mnt/models/checkpoints/
ls -lh /mnt/models/text_encoders/

# Check container image (~3GB)
ls -lh /mnt/models/worker-image.tar.gz

# Test worker
su - dev
cd ~/comfy-multi
docker compose up worker-1
```

### 7. Backup Container to Mello

```bash
# From mello
./scripts/backup-verda.sh --with-container
```

---

## FEB 1-28: Daily Startup (~30 seconds!)

### Quick Start (existing SFS)

**Option A: One-liner with quick-start.sh**
```bash
# 1. Create GPU spot instance (Verda Dashboard)

# 2. SSH and run quick-start script
ssh root@<new-instance-ip>
curl -sL https://raw.githubusercontent.com/ahelme/comfy-multi/main/scripts/quick-start.sh | bash -s <sfs-endpoint>

# Done! Mello SSH access + SFS mount + container loaded + worker started
```

**Option B: Manual steps**
```bash
# 1. Create GPU spot instance (Verda Dashboard)
#    - NO storage attached during creation

# 2. SSH and mount SFS
ssh root@<new-instance-ip>
mkdir -p /mnt/models
mount -t nfs <sfs-endpoint> /mnt/models

# 3. Load container (2 seconds!)
docker load < /mnt/models/worker-image.tar.gz

# 4. Start worker
su - dev
cd ~/comfy-multi
docker compose up -d worker-1

# Done! Total time: ~30 seconds
```

### If Instance Was Terminated Overnight

Same as Quick Start - SFS persists independently of instances!

### If SFS Needs Recreation

```bash
# Use backup from mello
sudo bash RESTORE.sh --with-models --load-container
# Takes ~45 min (R2 download)
```

---

## MAR 1: Post-Workshop Cleanup

```bash
# 1. Terminate any running Verda instances

# 2. Delete SFS (Verda Dashboard)
#    Storage → Shared File System → Delete
#    $14/month → $0

# 3. Keep backups (minimal cost)
#    - R2: ~$1/month (models)
#    - Mello: Free (configs + container)

# Next workshop? Start from JAN 31 steps again.
```

---

## Cost Summary

| Period | Verda Compute | Verda SFS | R2 | Total |
|--------|--------------|-----------|-----|-------|
| **Setup (Jan 31)** | ~€2 (A100 spot, 2hrs) | €0.35 (1 day) | $0 | ~$5 |
| **Workshop (Feb)** | Variable (spot) | ~$14 | $1 | $15 + compute |
| **Off-season** | $0 | $0 | $1 | $1/month |

---

## Troubleshooting

### SFS Won't Mount
```bash
# Check NFS client installed
apt-get install -y nfs-common

# Check endpoint is correct
ping <sfs-endpoint>

# Try manual mount with verbose
mount -v -t nfs <sfs-endpoint> /mnt/models
```

### Container Image Not Found
```bash
# Check SFS is mounted
df -h /mnt/models

# If missing, copy from mello backup
scp mello:~/backups/verda/worker-image.tar.gz /mnt/models/
```

### Models Missing
```bash
# Re-download from R2
export AWS_ACCESS_KEY_ID=<key>
export AWS_SECRET_ACCESS_KEY=<secret>
aws --endpoint-url https://...r2.cloudflarestorage.com \
    s3 sync s3://comfy-multi-model-vault-backup/ /mnt/models/
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Mount SFS | `mount -t nfs <endpoint>:/share /mnt/models` |
| Load container | `docker load < /mnt/models/worker-image.tar.gz` |
| Start worker | `cd ~/comfy-multi && docker compose up -d worker-1` |
| Check models | `ls -lh /mnt/models/checkpoints/` |
| Check Redis | `redis-cli -h $REDIS_HOST -a $REDIS_PASSWORD ping` |

---

**Related Docs:**
- [Backup & Restore](./admin-backup-restore.md)
- [Verda Setup](./admin-verda-setup.md)
- [Budget Strategy](./admin-budget-strategy.md)
