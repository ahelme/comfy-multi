**Doc Title:** Admin Guide - Backup & Restore
**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-16
**Doc Updated:** 2026-01-16

---

# Admin Guide: Backup & Restore

Quick reference for backing up and restoring the Verda GPU instance.

---

## Storage Strategy

| Storage | Purpose | Persistence | Cost |
|---------|---------|-------------|------|
| **Verda SFS** | Models + Container (workshop month) | Temporary | ~$14/month |
| **Cloudflare R2** | Model backup (permanent) | Permanent | ~$1/month |
| **Mello VPS** | Configs, scripts, container backup | Permanent | (existing) |

---

## Backup Locations

| Data | Location | Size |
|------|----------|------|
| **Models (LTX-2)** | Cloudflare R2 `comfy-multi-model-vault-backup` | ~45GB |
| **Configs** | Mello VPS `~/backups/verda/` | ~50KB |
| **Container** | Mello VPS `~/backups/verda/worker-image.tar.gz` | ~2.6GB |
| **Tailscale identity** | Mello VPS (preserves IP 100.89.38.43) | ~5KB |

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

1. Create SFS in Verda Dashboard (50GB recommended)
2. Note the **PSEUDOPATH** (e.g., `nfs.fin-01.datacrunch.io:/SFS-Model-Vault-273f8ad9`)
3. Create GPU instance (A100/H100) with SFS attached
4. Add quick-start.sh as provisioning script with PSEUDOPATH argument

### Step 2: Run quick-start.sh

`quick-start.sh` is run automatically during provisioning, or manually:

```bash
curl -sL https://raw.githubusercontent.com/ahelme/comfy-multi/main/scripts/quick-start.sh | bash -s <PSEUDOPATH>
```

**What quick-start.sh does:**
- Mounts SFS at /mnt/models
- Adds mello SSH key for access
- Checks for restore scripts in /root/
- Shows scp command if scripts are missing
- Loads container image from SFS
- Creates symlinks for ComfyUI

### Step 3: Transfer Backup Files (if needed)

`quick-start.sh` checks for restore scripts. If missing, it displays the command to push them from mello.

**Manual transfer from mello:**
```bash
scp ~/backups/verda/* root@<verda-ip>:/root/
```

### Step 4: Run Restore Script

```bash
cd /root
sudo bash RESTORE-SFS.sh
```

**What RESTORE-SFS.sh does:**
- Installs packages (fail2ban, ufw, zsh, docker, redis-tools)
- Restores Tailscale identity (preserves IP 100.89.38.43)
- Restores SSH host keys
- Configures fail2ban and UFW
- Creates dev user with zsh shell
- Installs oh-my-zsh + bullet-train theme
- Restores comfy-multi project

### Step 5: Authenticate Tailscale

```bash
sudo tailscale up --ssh=false
# Visit the URL shown in your browser to authenticate
```

**Verify IP preserved:**
```bash
tailscale ip -4  # Should show 100.89.38.43
```

### Step 6: Download Models (if fresh SFS)

Models download from R2 (instructions shown by RESTORE-SFS.sh):

```bash
export AWS_ACCESS_KEY_ID=<key>
export AWS_SECRET_ACCESS_KEY=<secret>
aws s3 sync s3://comfy-multi-model-vault-backup/ /mnt/models/ \
    --endpoint-url https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com
```

### Step 7: Start Worker

```bash
su - dev
cd ~/comfy-multi
docker compose up -d worker-1
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

### quick-start.sh Didn't Find Restore Scripts
**Solution:** Push from mello manually:
```bash
scp ~/backups/verda/* root@<verda-ip>:/root/
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
mount -v -t nfs <sfs-endpoint> /mnt/models
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
