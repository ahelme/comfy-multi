**Doc Title:** Admin Guide - Backup & Restore
**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-16
**Doc Updated:** 2026-01-18

---

# Admin Guide: Backup & Restore

Quick reference for backing up and restoring the Verda GPU instance.

**See also:** [Backup Routines](./admin-backup-routines.md) - concise reference for manual and automatic backups.

---

## Storage Strategy

| Storage | Purpose | Persistence | Cost |
|---------|---------|-------------|------|
| **Verda SFS** | Models + Container (workshop month) | Temporary | ~$14/month |
| **Verda Block** | Scratch disk for outputs/temp | Ephemeral | ~$1/month |
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

## Backup Scripts Summary

| Script | Runs From | Destination | Trigger | Schedule |
|--------|-----------|-------------|---------|----------|
| `backup-cron.sh` | Verda | SFS + triggers mello | Cron | Hourly |
| `backup-verda.sh` | Mello | Mello + R2 | Manual | Before shutdown |
| `backup-mello.sh` | Mello | R2 | Manual/Cron | Before shutdown |

### What Gets Backed Up

| Data | `backup-cron.sh` | `backup-verda.sh` | `backup-mello.sh` | Location |
|------|:----------------:|:-----------------:|:-----------------:|----------|
| Tailscale identity | ✅ | ✅ | ❌ | SFS / Mello |
| SSH host keys | ✅ | ✅ | ❌ | SFS / Mello |
| Fail2ban, UFW configs | ✅ | ✅ | ❌ | SFS / Mello |
| Project .env | ✅ | ✅ | ❌ | SFS / Mello |
| User credentials | ❌ | ❌ | ✅ | Private repo |
| Nginx htpasswd | ❌ | ❌ | ✅ | Mello VPS only |
| /home/dev/ | ❌ | ✅ | ❌ | Mello |
| ComfyUI project | ❌ | ✅ | ❌ | Mello |
| oh-my-zsh custom | ❌ | ✅ | ❌ | Mello |
| Models (.safetensors) | ❌ | ✅ (default) | ❌ | R2 |
| Container image | ❌ | ✅ (default) | ❌ | Mello + R2 |
| User workflows | ❌ | ❌ | ✅ | R2 |
| User outputs | ❌ | ❌ | ✅ | R2 |
| User inputs | ❌ | ❌ | ✅ | R2 |
| Block storage (`/mnt/scratch`) | ❌ | ❌ | ❌ | *Not backed up* |

---

## Backup Locations

**Primary: Cloudflare R2** (three buckets)

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

**User Files Bucket:** `comfy-multi-user-files` (Eastern Europe)
| Data | R2 Path | Size |
|------|---------|------|
| **User Workflows** | `user_data/userXXX/` | Variable |
| **User Outputs** | `outputs/userXXX/` | Variable |
| **User Inputs** | `inputs/` | Variable |

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

### End of Workshop Day (Manual)

Run from Mello VPS before shutting down Verda:

```bash
cd ~/projects/comfymulti-scripts

# Step 1: Backup Verda → Mello + R2
./backup-verda.sh

# Step 2: Backup Mello user files → R2
./backup-mello.sh
```

For detailed backup tables and options, see [admin-backup-routines.md](./admin-backup-routines.md).

---

## Restore Script

The private repo contains a single consolidated setup/restore script:

| Script | Purpose | When to Use |
|--------|---------|-------------|
| **setup-verda-solo-script.sh** | Full instance setup and restore | New Verda GPU instances |

**Location:** `ahelme/comfymulti-scripts` (private GitHub repo)

**Archived scripts:** `quick-start.sh`, `RESTORE-SFS.sh` - legacy two-part workflow (see `archive/` folder)

---

## Restoring to New Instance

### Step 1: Provision Instance

1. Get latest `setup-verda-solo-script.sh` from **https://github.com/ahelme/comfymulti-scripts** (private repo)
2. In Verda Console, create GPU instance (A100/H100)
3. Attach your SFS (create one first if needed - 50GB recommended)
4. Create and attach Block Storage (10-20GB) for scratch disk
5. In **"Startup Script"** field, paste `setup-verda-solo-script.sh` contents
6. Add **both SSH keys**: user's Mac key + Mello VPS key (`dev@vps-for-verda`)
7. Provision instance

### Step 2: Script Runs Automatically

The script runs on first boot and performs the following steps:

**1. Save SFS MOUNT COMMAND & NFS ENDPOINT**
- Extracts mount command from provisioning environment
- Critical step completed first (fail early if missing)

**2. Ubuntu Pro Authentication** (if available)
- Enables security updates
- Completed early so not forgotten

**3. Update OS & Install Dependencies**
- Updates package repositories
- Installs: fail2ban, ufw, redis-tools, zsh, git, curl, wget, nfs-common, unzip, keyutils
- Changes dev user shell to zsh
- Installs/updates AWS CLI and sets R2 credentials
- Installs/updates Docker
- Installs/updates Tailscale

**4. Mount SFS Network Disk**
- Mounts SFS at `/mnt/sfs`
- Creates directory structure: `models/`, `cache/`
- Starts model downloads if needed (parallel with other steps)

**5. Mount Block Storage (Scratch Disk)**
- Auto-formats if blank
- Mounts at `/mnt/scratch`
- Creates subdirectories: `outputs/`, `inputs/`, `temp/`

**6. Get Docker GPU Worker Container**
- Downloads container image from R2 or SFS cache (~2.5GB)
- Runs in background while other steps continue

**7. Configure Tailscale & Restore Identity**
- Restores Tailscale identity from backup (critical!)
- Stops tailscaled, restores `/var/lib/tailscale/`, starts tailscaled
- Disables SSH over Tailscale
- Verifies IP matches expected: **100.89.38.43**

**8. Restore Root SSH Keys**
- Restores SSH host keys from SFS backup
- Note: Public keys (mello + user Mac) added during provisioning

**9. Security Hardening (UFW Firewall)**
- Enables UFW firewall
- Allows only: SSH (22), Tailscale (41641/udp)
- Redis accessed via Tailscale only (no public port)

**10. Create Dev User on Verda**
- Creates `dev` user if doesn't exist
- Sets password from script variables
- Adds to sudoers with NOPASSWD (workshop simplicity)

**11. Restore ComfyMulti Project**
- Clones or restores project to `/home/dev/comfy-multi/`
- Restores `.env` and config files

**12. Get Dev Home & Config**
- Restores dev user dotfiles: oh-my-zsh, Bullettrain theme, aliases, Claude Code config
- Restores from most recent backup tarball

**13. Setup Hourly Backup Cron**
- Gets backup script from GitHub
- Creates cron job for hourly backups to SFS

**14. Wait for Container Download & Load**
- Waits for background download if still running
- Loads container image into Docker
- Caches to SFS for future instances

**15. Create Symlinks**
- `data/models` → `/mnt/sfs/models`
- `data/outputs` → `/mnt/scratch/outputs`
- `data/inputs` → `/mnt/scratch/inputs`
- Fixes ownership to dev user

### Step 3: Authenticate Tailscale (Manual)

After script completes, you'll need to authenticate Tailscale:

```bash
sudo tailscale up --ssh=false
# Visit the URL shown in your browser to authenticate
```

**Note:** Script verifies Tailscale IP is **100.89.38.43** before prompting. If wrong, it aborts with error (logged to `/root/setup-error.log`).

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
- [ ] SFS mounted: `mountpoint /mnt/sfs`
- [ ] Block storage mounted: `mountpoint /mnt/scratch`
- [ ] Models present at /mnt/sfs/models/
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

# User files bucket (EU)
aws --endpoint-url $R2_ENDPOINT s3 ls s3://comfy-multi-user-files/ --recursive --human-readable
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

**User Files Bucket:** `comfy-multi-user-files` (Eastern Europe)
```
user_data/userXXX/              (workflows, settings)
outputs/userXXX/                (generated files)
inputs/                         (user uploads)
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

### Block Storage Not Found
**Cause:** No block storage attached to instance.

**Solution:**
1. Go to Verda Dashboard → Storage
2. Create Block Storage volume (10-20GB)
3. Attach to instance
4. Re-run quick-start.sh

### Block Storage Needs Formatting
**Cause:** Blank volume with no filesystem.

**Solution:** quick-start.sh auto-formats blank volumes. If manual:
```bash
sudo mkfs.ext4 /dev/vdb
sudo mount /dev/vdb /mnt/scratch
```

---

## Related Docs

- [Backup Routines](./admin-backup-routines.md) - Concise reference for manual and automatic backups
- [Workshop Workflow](./admin-workflow-workshop.md) - Daily startup procedures
- [Scripts Reference](./admin-scripts.md) - All available scripts
- [Verda Setup](./admin-verda-setup.md) - Verda configuration
- [Block Storage Workflow](./archive/admin-backup-restore-block-storage.md) - Alternative workflow

---

**Archive:** For Block Storage workflow, see [admin-backup-restore-block-storage.md](./archive/admin-backup-restore-block-storage.md)
