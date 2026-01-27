**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-02
**Doc Updated:** 2026-01-27

---

# Claude Project Guide

**Architecture:** App on VPS, Inference via GPU Cloud
**Health Check:** https://comfy.ahelme.net/health

---

## ⚠️  CRITICAL INSTRUCTIONS - YOU MUST:

1. **USE LATEST STABLE LIBRARIES AS OF JAN 2026**

2. **ALWAYS CHECK IF CODE HAS BEEN CREATED FIRST** 
   - **NEVER EVER** REWRITE CODE IF IT HAS ALREADY BEEN WRITTEN
   - **ALWAYS CHECK** FOR PREVIOUS SOLUTIONS

## 🎯 Project Quick Reference

### What are we building?
- A multi-user ComfyUI platform for video generation workshops.
- Optimised for cost savings:
  - App hosted separately on Hetzner VPS. 
  - Inference via a Remote GPU Cloud provider (e.g. Verda, RunPod, etc.)
  - Storage of models, user files, config, worker etc. on cheap Cloudflare R2.
- Workshop participants/end-users are professional filmmakers.

### Key Requirements
- split architecture - two servers one for CPU, one for GPU
- 20 isolated ComfyUI web interfaces 
- Central job queue (FIFO/round-robin/priority)
- 1-3 GPU workers on H100 OR serverless containers 
- HTTPS with existing ahelme.net SSL cert
- HTTP Basic Auth password protection 
- Tailscale VPN for secure Redis connection 
- Persistent user storage 
- Admin dashboard for instructor 
- Real-time health monitoring 
- Comprehensive backup routines (scripts on private repo)

### Quick Links
- **Production:** https://comfy.ahelme.net/
- **Health Check:** https://comfy.ahelme.net/health
- **Admin Dashboard:** https://comfy.ahelme.net/admin
- **API:** https://comfy.ahelme.net/api/queue/status

---

## 📁 Project Structure

```
/home/dev/projects/comfyui/
├── implementation-deployment-verda.md  # Implementation plan for deployment phases
├── progress-**.md                      # Recent session logs (UPDATE ON COMMITS)
├── CLAUDE.md                           # This file - project guide
├── README.md                           # Public project documentation
├── .env                                # Local configuration (gitignored)
├── .env.example                        # Template configuration
├── docker-compose.yml                  # Main orchestration
├── docker-compose.user.yml             # User containers on CPU VPS (Heztner)
├── nginx/                              # Reverse proxy
├── queue-manager/                      # FastAPI service
├── comfyui-worker/                     # GPU worker
├── comfyui-frontend/                   # User UI containers
├── admin/                              # Admin dashboard
├── scripts/                            # Management scripts
├── data/                               # Persistent volumes
└── docs/                               # User/admin guides

/home/dev/projects/comfymulti-scripts/
├── README-RESTORE.md              # Basic backup/restore doc
├── setup-verda-solo-script.sh     # Single consolidated setup/restore script
├── backup-cron.sh                 # Hourly backups: Verda→SFS + triggers mello→R2
├── backup-mello.sh                # Backs up user files on mello e.g. workflows
├── backup-verda.sh                # Backs up all data to R2 before instance deleted
└── archive/                       # Legacy scripts (quick-start.sh, RESTORE-SFS.sh) 
```

---
## Project Management

### 📋 Progress Tracking
- [Current Progress Log](./progress-02.md) - Session log
    - ==MUST UPDATE ON COMMIT OF CODE CHANGES==

### 📋 Issue Tracking
- **ComfyMulti Project**: https://github.com/ahelme/comfy-multi/issues
- **Private Scripts Repo**: https://github.com/ahelme/comfymulti-scripts/issues

### 📋 Implementation Plan (Phases)

- [Current Implementation Plan: Deploy/Backup/Restore](./implementation-backup-restore.md)
    - IMPLEMENTATION PLANS MUST BE CONCISE! DETAILS CHANGE!    
    - **NO CODE SNIPS**
    - Replace detail with simple steps 
    - Provide pointers to single source of truth (docs)
    - ==MUST UPDATE AS PLAN CHANGES==

---

## 📚 Document Links

### Core Documents
- [README.md](./README.md) - Public code project overview and dev quickstart
- [Progress Log](./progress-**.md) - Session logs
- [Admin Guide](.docs/admin-guide.md) - Admin docs index / overview
- [Deploy/Backup Guide](.docs/admin-backup-restore.md) - Docs: deploy/restore/backups
- [GPU Deployment](./implementation-backup-restore.md) - Plan: deploy/restore/backup
- [Claude Guide](./CLAUDE.md) - Development context for custom deployment (this file)

### User Documentation 
- **docs/user-guide.md** - For workshop participants
- **docs/admin-guide.md** - For developer/maintainer/instructor
- **docs/troubleshooting.md** - Common issues

### Documentation Format

Ensure these details are listed the top of ALL .md documentation files:

[example]

**Project Name:** ComfyMulti 
**Project Desc:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-02
**Doc Updated:** 2026-01-18

==IMPORTANT: Docs MUST be comprehensive yet NO FLUFF== 

==NO extraneous / irrelevant info / value-statements / achievements boasting==

---

## 🔄 Update Progress on Commit: Instructions

### At EVERY GIT COMMIT update `progress-**.md`(progress files numbered - only latest kept):

```markdown
### Session N - YYYY-MM-DD

**Which Implmentation Phase**
- See current dev plan doc (see below)

**List Git Issues**

**Activities:**
- What was accomplished in this session
- Key decisions made
- Files created/modified

**Code Created:**
- List ALL files with brief description

**Commit logs**
- List for both repos:
  - comfy-multi
  - comfymulti-scripts (private repo inc. secrets)

**Blockers:**
- Any issues encountered

**Next Session Goals:**
- What to do next
```

---

## 🏗️ Architecture Overview

```
  Split Server Architecture:
  ┌─────────────────────────────────────────┐
  │ Hetzner VPS (comfy.ahelme.net)          │
  │  - Nginx (HTTPS, SSL)                   │
  │  - Redis (job queue)                    │
  │  - Queue Manager (FastAPI)              │
  │  - Admin Dashboard                      │
  │  - User Frontends x20 (CPU only)        │
  └──────────────┬──────────────────────────┘
                 │ Network
                 │ (Redis connection)
  ┌──────────────▼──────────────────────────┐
  │ Remote GPU (Verda) instance/serverless  │
  │  - Worker 1 (ComfyUI + GPU)             │
  │  - Worker 2 (ComfyUI + GPU) [optional]  │
  │  - Worker 3 (ComfyUI + GPU) [optional]  │
  │                                         │
  │  REDIS_HOST=comfy.ahelme.net            │
  └─────────────────────────────────────────┘

Code Architecture:

[User Browser]
    ↓ HTTPS
[Nginx :443] → SSL termination, routing
    ├─→ /user001-020/ → Frontend containers
    ├─→ /api → Queue Manager
    └─→ /admin → Admin Dashboard

[Queue Manager :3000] ← FastAPI + WebSocket
    ↓ Redis
[Job Queue] ← Redis list + pub/sub
    ↓
[ComfyUI Workers :8188-8190] ← GPU processing
    ↓
[Shared Volumes] ← models, outputs, workflows
```

---

## 🚀 Git Workflow

### Repository
- **Platform:** GitHub
- **URL:** https://github.com/ahelme/comfy-multi
- **Branch Strategy:**
  - `main` - production-ready code
  - `dev` - active development
  - Feature branches as needed
- **Scripts Repo** (PRIVATE!) https://github.com/ahelme/comfymulti-scripts

### Git Configuration (IMPORTANT)
**GitHub noreply email (keeps email private):**
```bash
git config user.email "ahelme@users.noreply.github.com"
git config user.name "ahelme"
```

### Commit Guidelines
```bash
# Good commit messages
feat: add queue manager REST API endpoints
fix: resolve nginx routing for user/20
docs: update admin guide with priority override
test: add integration tests for worker
```

### When to Commit
- End of each major feature
- Before trying risky changes
- End of each session
- When tests pass
- ==REMEMBER: UPDATE `progress-**.md` after commits!==
---

## 🛠️ Technology Stack

### Development Machines
- **dev machine (THIS MACHINE!)**: 'mello' cheap Hetzner VPS - Ubuntu
- **user's machine**: MBP M4 Pro 48GB RAM

### Production Servers & Storage
- **main app & user frontends**: 'mello' cheap Hetzner VPS - Ubuntu
- **AI inference**: 'verda' GPU cloud (renewable energy & EU policy): rented instance / serverless

### Backups
- **cloud storage**: Cloudflare R2 ( .eu ) - 3x buckets (v. cheap)
- **local storage**: 'verda' SFS (network drive) & block storage + 'mello'

### Infrastructure
- **Container Runtime:** Docker + Docker Compose
- **Reverse Proxy:** Nginx (SSL termination, routing)
- **Queue:** Redis 7+ (job queue, pub/sub)
- **SSL:** Existing ahelme.net certificate via Namecheap

### Services
- **Queue Manager:** Python 3.11+ with FastAPI + WebSocket
- **Workers:** ComfyUI v0.9.2 with GPU support
- **Frontends:** ComfyUI v0.9.2 web UI (CPU-only mode)
- **Admin:** HTML/JS dashboard

### Deployment
- **Development:** Docker Compose locally (Hetzner VPS)
- **Production:** Hetzner VPS + Remote GPU (e.g. Verda) instance/serverless

### Workshop Models

**Primary Video Generation Model:**
- **LTX-2** (19B parameters) - State-of-the-art open-source video generation
  - Checkpoint: `ltx-2-19b-dev-fp8.safetensors` (checkpoints/)
  - Text Encoder: `gemma_3_12B_it.safetensors` (text_encoders/)
  - Upscaler: `ltx-2-spatial-upscaler-x2-1.0.safetensors` (latent_upscale_models/)
  - LoRAs:
    - `ltx-2-19b-distilled-lora-384.safetensors`
    - `ltx-2-19b-lora-camera-control-dolly-left.safetensors`

**Required ComfyUI Nodes:**
- **Core v0.7.0+:** `LTXAVTextEncoderLoader`, `LTXVAudioVAEDecode`
- **Core v0.3.68+:** `LTXVAudioVAELoader`, `LTXVEmptyLatentAudio`

**Model Sources:**
- HuggingFace: `Lightricks/LTX-2`
- HuggingFace: `Comfy-Org/ltx-2`

**NEW: ADDED IMAGE MODEL**
- **Flux.2 Klein**

---

## ⚙️ Configuration

### Environment Variables (.env)
```env
# Domain & SSL
DOMAIN=ahelme.net
SSL_CERT_PATH=/path/to/fullchain.pem
SSL_KEY_PATH=/path/to/privkey.pem

# Inference Provider (verda, runpod, modal, local)
INFERENCE_PROVIDER=verda
VERDA_API_KEY=
RUNPOD_API_KEY=
MODAL_API_KEY=

# User configuration
NUM_USERS=20
NUM_WORKERS=1
QUEUE_MODE=fifo
REDIS_PASSWORD=changeme
```

---

## 📋 Critical Files and Locations                                          

 mello: File/Directory                              │ Purpose
  ──────────────────────────────────────────────────┼───────────────────────────────────────────
  .env                                              │ Configuration (passwords, domain, etc.)
  docker-compose.yml                                │ Container orchestration
  /etc/ssl/certs/fullchain.pem                      │ SSL public certificate
  /etc/ssl/private/privkey.pem                      │ SSL private key
  scripts/status.sh                                 │ System health check script
  scripts/start.sh                                  │ Start all services
  scripts/stop.sh                                   │ Stop all services

  ~/projects/comfymulti-scripts/                       │ Backup/Restore/Deploy scripts for Verda GPU Cloud
  ~/projects/comfymulti-scripts/setup-verda-solo-script.sh │ Single setup/restore script for Verda
  ~/projects/comfymulti-scripts/README-RESTORE.md      │ README for restoring Verda

 *(NOTE: restore scripts have their own private gh repo: https://github.com/ahelme/comfymulti-scripts)*

  docs/admin-backup-restore.md                      │ Full docs for deploy/backup/restore

 verda: File/Directory                              │ Purpose
  ──────────────────────────────────────────────────┼────────────────────────────────────────
  data/models/shared/   (SFS network drive)         │ Shared model files
  data/outputs/         (block storage: scratch)    │ User output files (isolated per user)
  data/inputs/          (block storage: scratch)    │ User uploads (isolated per user)
---

## ✅ Success Criteria

### MVP Requirements (Must Have)
- ✅ 20 isolated user interfaces accessible
- ✅ Jobs queue and execute on GPU
- ✅ HTTPS working with SSL cert
- ✅ Outputs persist after restart
- ✅ Admin can monitor queue
- ✅ System stable for 8-hour workshop
- ✅ Deployment tested on Verda GPU instance AND serverless

---

## 🔒 Security & Firewall Configuration

### VPS Firewall (UFW)
Current firewall rules lock down all ports except essential services:

```bash
sudo ufw status
```

**Allowed Ports:**
- **22/tcp** - SSH (rate limited)
- **80/tcp, 443/tcp** - HTTP/HTTPS (Nginx Full)
- **21115-21119/tcp** - RustDesk remote desktop
- **21116/udp** - RustDesk UDP

**Redis Security:**
- **Port 6379** - NOT exposed to public internet
- **Access:** Only via Tailscale VPN (100.99.216.71:6379)
- **Auth:** Password protected (REDIS_PASSWORD)

### User Authentication
- **Method:** HTTP Basic Auth (nginx)
- **Users:** 20 users (user001-user020)
- **Credentials File:** `/home/dev/projects/comfyui/USER_CREDENTIALS.txt`
- **htpasswd File:** `/etc/nginx/comfyui-users.htpasswd`
- **Encryption:** bcrypt (cost 10)

### Tailscale VPN
- **VPS Tailscale IP:** 100.99.216.71
- **GPU (Verda) Tailscale IP:** 100.89.38.43
- **Purpose:** Secure encrypted tunnel for Redis access between VPS and GPU workers
- **Protocol:** WireGuard (modern, fast, secure)
- **Authentication:** Run `sudo tailscale up --ssh=false`, visit the URL shown in browser to authenticate
- **Note:** Use `--ssh=false` to disable Tailscale SSH (we use regular SSH)

### SSL/TLS
- **Provider:** Existing ahelme.net certificate
- **Domain:** comfy.ahelme.net
- **Expiry:** 2026-04-10
- **Protocols:** TLSv1.2, TLSv1.3

### Cloudflare R2 (Three Buckets)
- **Provider:** Cloudflare R2 (S3-compatible)
- **Endpoint:** `https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com`
- **Cost:** ~$3/month total (no egress fees)
- **Access:** Via AWS CLI with R2 API credentials

**Models Bucket:** `comfy-multi-model-vault-backup`
- Location: Oceania
- Contents: `checkpoints/*.safetensors`, `text_encoders/*.safetensors`
- Purpose: Model files only (~45GB)

**Cache Bucket:** `comfy-multi-cache`
- Location: Eastern Europe (closer to Verda/Finland)
- Contents: `worker-image.tar.gz` (~2.5GB), `verda-config-backup.tar.gz` (~14MB)
- Purpose: Container image and config backup

**User Files Bucket:** `comfy-multi-user-files`
- Location: Eastern Europe (same as mello VPS)
- Contents: `user_data/userXXX/`, `outputs/userXXX/`, `inputs/`
- Purpose: User workflows, settings, outputs, uploads from mello

### Restore Scripts (Private GitHub Repo)
- **Repo:** `ahelme/comfymulti-scripts` (private)
- **URL:** https://github.com/ahelme/comfymulti-scripts
- **Local path on mello:** `/home/dev/projects/comfymulti-scripts/`
- **Purpose:** Version-controlled setup/restore scripts for Verda instances
- **Contents:**
  - `setup-verda-solo-script.sh` - Single consolidated setup/restore script
  - `backup-cron.sh`, `backup-mello.sh`, `backup-verda.sh` - Backup scripts
  - `README-RESTORE.md` - Quick reference for restore scenarios
  - `archive/` - Legacy scripts (quick-start.sh, RESTORE-SFS.sh, etc.)
- **Note:** Script downloads binary files (models, container) from R2 or SFS cache

---

## ⚠️  Gotchas

### CRITICAL: Server Unresponsive Emergency Fix
**If server stops responding:**
1. Hard Reset the server via hosting provider dashboard
2. SSH in ASAP after reboot
3. Run: `sudo docker stop $(sudo docker ps -q --filter "name=comfy")`

This stops all ComfyUI containers to prevent resource exhaustion on startup.

### Cloudflare R2 EU location
- don't forget the '.eu' domain!

### Verda Storage Options

**Recommended: Shared File System (SFS)** - €0.01168/h for 50GB (~$14 AUD/month)
- Network-attached (NFS), mount from any instance
- No provisioning gotchas - just mount and go
- Multiple instances can share same storage
- Mount: `mount -t nfs <sfs-endpoint>:/share /mnt/sfs`
- Structure: `/mnt/sfs/models/` (ComfyUI models), `/mnt/sfs/cache/` (container, config, scripts)

**Alternative: Block Storage** - Cheaper but riskier
- ⚠️ **CRITICAL: Gets WIPED if attached during instance provisioning!**
- Must use shutdown-attach-boot workflow for existing data
- Only one instance can use it at a time
- Good for scratch disk

### Block Storage Safe Workflow (if using)

1. Create instance **WITHOUT** block storage attached
2. Boot the instance
3. **Shut down** the instance (required for attachment)
4. Attach block storage via Verda Dashboard
5. Boot instance again
6. Mount the volume: `mount /dev/vdc /mnt/models`

**Volume naming convention:**
- `OS-*` = OS disks (will have Ubuntu installed)
- `Volume-*` = Data volumes (your actual block storage)

### Other Verda Notes
- Verda images have Docker pre-installed (don't try to install docker.io - conflicts with containerd)
- Ubuntu 24.04 uses `ssh` service name, not `sshd`
- Spot instances can be terminated anytime - always use persistent storage (SFS or Block)

---

## 🔗 External Links

### Research References
- [Visionatrix Discussion](https://github.com/comfyanonymous/ComfyUI/discussions/3569) - Multi-user architecture
- [SaladTechnologies/comfyui-api](https://github.com/SaladTechnologies/comfyui-api) - Queue patterns
- [Modal ComfyUI Scaling](https://modal.com/blog/scaling-comfyui) - Architecture insights
- [9elements ComfyUI API](https://9elements.com/blog/hosting-a-comfyui-workflow-via-api/) - Workflow execution

### Deployment Targets
- [Verda Products](https://verda.com/products) - Instance types
- [Verda Containers](https://verda.com/serverless-containers) - Serverless options - dynamic scaling
- [Verda Instances](https://docs.verda.com/cpu-and-gpu-instances/set-up-a-gpu-instance) - Setup an instance
- [Verda Serverless Containers](https://docs.verda.com/containers/overview) - Setup a container 

### ComfyUI Resources
- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [ComfyUI Wiki](https://comfyui-wiki.com/)
- [ComfyUI API Docs](https://github.com/comfyanonymous/ComfyUI/discussions/2073)

---

## 🎓 Context for Claude

1. **Existing SSL cert** via Namecheap mounted (not Let's Encrypt)
2. **Queue modes:** FIFO + round-robin + instructor priority
3. **Test with Single H100 Instance** with 1-3 workers (test then scale)
4. **Then try Serverless Containers** for price/performance
5. **Persistent storage** for all user data
6. **User model uploads** allowed

### User Preferences
- Appreciates thoroughness and detail
- Values comprehensive and accurate documentation
- Wants progress tracking (hence `progress-**.md`)
- Likes structured approaches

## Deployment

### SSH Keys for Verda

**During Verda provisioning, add BOTH public keys via Verda console:**

1. **User's Mac key** - for manual SSH access
2. **Mello VPS key** - for mello to SSH into Verda

```
# Mello VPS public key (MUST ADD):
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiwaT6NQcHe7cYDKB5LrtmyIU0O8iRc7DJUmZJsNkDD dev@vps-for-verda
```

**Why this matters for restore scripts:**
- Mac can SSH into Verda ✓ (Mac has private key)
- Mello can SSH into Verda ✓ (Mello has private key)
- Verda CANNOT pull from mello ✗ (Verda has no private key for mello until setup script finishes)

### Restore scripts are adaptive

**Core Restore Workflow:** Restore scripts first check SFS (fast, for workshop month), then fall back to remote:
- **SFS** - First choice (files cached from previous session)
- **R2** - Binary files (models, container image, config tarball)
- **GitHub** - Scripts (`ahelme/comfymulti-scripts` private repo)

### Critical Principles

**1. Check Before Downloading/Restoring (Scripts Check in This Order)**

| File Type                       | Check Order           | Rationale             |
|---------------------------------|-----------------------|-----------------------|
| **Models** (~45GB)              | SFS → R2              | Large, live on SFS    |
| **Config, identity, container** | /root/ → SFS → R2     | Extracted to instance |
| **Scripts**                     | /root/ → SFS → GitHub | Small, versioned      |

**2. Tailscale Identity Must Be Restored BEFORE Starting Tailscale**

If Tailscale starts without the backed-up identity, it gets a **NEW IP address**.
The restore scripts restore `/var/lib/tailscale/` BEFORE running `tailscale up`.
This preserves the expected IP: **100.89.38.43**

### Deployment Prerequisites Checklist

Before starting, verify:
- [ ] mello VPS is running (comfy.ahelme.net)
- [ ] R2: **Models bucket** (`comfy-multi-model-vault-backup`) contains:
  - [ ] `checkpoints/*.safetensors` (~25-50 GB)
  - [ ] `text_encoders/*.safetensors` (~20 GB)
- [ ] R2: **Cache bucket** (`comfy-multi-cache`) contains:
  - [ ] `worker-image.tar.gz` (~2.5 GB)
  - [ ] `verda-config-backup.tar.gz` (~14 MB)
- [ ] GitHub: **Private Scripts Repo** (`ahelme/comfymulti-scripts`) contains:
  - [ ] `setup-verda-solo-script.sh`
- [ ] User's Mac: **SSH Keys and Setup Script** added to Verda console during provisioning
  - [ ] `dev@vps-for-verda` (Mello's key) & `developer@annahelme.com` (User's key) - paste into console
  - [ ] `setup-verda-solo-script.sh` (latest version from GitHub!) - paste into console 
- [ ] R2: **User files bucket** (`comfy-multi-user-files`)
  - [ ] available to receive backups

### Step-by-Step Deployment Process

See [Admin Backup & Restore Guide](./docs/admin-backup-restore.md) for complete step-by-step instructions including:
- Provisioning SFS and GPU instance and block storage (scratch disk) on Verda
- Running setup-verda-solo-script.sh on Verda (runs automatically on first boot)
- Script downloads models from R2 (unless available on SFS already)
- Backup cron jobs are set up automatically by the script

### Deployment To-Dos for Claude (pre-populated)
- Copy these to TodoWrite when deploying: `.claude/DEPLOYMENT-TO-DO.md`

### Troubleshooting

See [Admin Backup & Restore Guide - Troubleshooting](./docs/admin-backup-restore.md#troubleshooting) for common issues and solutions.

---

## 📝 Session Checklist

Before each session ends:
- [ ] Commit & push code changes to git
- [ ] Update `progress-**.md` with session log
- [ ] Update admin/dev docs with key changes made (IMPORTANT!) - CLAUDE.md, README.md, linked dev / project docs
- [ ] Update current `implementation-*.md` when plan changes (push details to docs - single source of truth)
- [ ] Consider any changes made that are relevant to users - if any: scour `user-*.md` docs for details that need changing
- [ ] Note any blockers or decisions
- [ ] Clear next session goals

---

**Last Updated:** 2026-01-19
