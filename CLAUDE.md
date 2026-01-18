**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-02
**Doc Updated:** 2026-01-17

---

# Claude Project Guide

**Architecture:** App on VPS, Inference via GPU Cloud
**Health Check:** https://comfy.ahelme.net/health

---

## ⚠️ CRITICAL INSTRUCTIONS - YOU MUST:

1. **USE LATEST STABLE LIBRARIES AS OF 04 JAN 2026** - ✅ COMPLETE - All dependencies using latest stable versions
2. **MODULAR INFERENCE PROVIDERS** - ✅ COMPLETE - Config file supports Verda, RunPod, Modal, local
3. **ALWAYS CHECK IF CODE HAS BEEN CREATED FIRST** - NEVER EVER REWRITE CODE IF IT HAS ALREADY BEEN WRITTEN AND WORKS WELL - always check!

## 🎯 Project Quick Reference

### What are we building?
A multi-user ComfyUI platform for a video generation workshop with 20 participants - app hosted separately on Hetzner VPS, with inference via a Remote GPU Cloud provider (e.g. Verda, RunPod, etc.) sharing a single H100 GPU.

### Key Requirements
- split architecture - two servers one for CPU, one for GPU
- 20 isolated ComfyUI web interfaces ✅
- Central job queue (FIFO/round-robin/priority) ✅
- 1-3 GPU workers on H100 ✅
- HTTPS with existing ahelme.net SSL cert ✅
- HTTP Basic Auth password protection ✅
- Tailscale VPN for secure Redis connection ✅
- Persistent user storage ✅
- Admin dashboard for instructor ✅
- Real-time health monitoring ✅

### Quick Links
- **Production:** https://comfy.ahelme.net/
- **Health Check:** https://comfy.ahelme.net/health
- **Admin Dashboard:** https://comfy.ahelme.net/admin
- **API:** https://comfy.ahelme.net/api/queue/status

---

## 📁 Project Structure

```
/home/dev/projects/comfyui/
├── prd.md                   # Product Requirements Document
├── implementation-deployment-verda.md  # GPU deployment guide
├── progress-2.md            # Session logs + metrics (UPDATE EACH RESPONSE)
├── CLAUDE.md                # This file - project guide
├── README.md                # Public project documentation
├── .env                     # Local configuration (gitignored)
├── .env.example             # Template configuration
├── docker-compose.yml       # Main orchestration
├── docker-compose.dev.yml   # Local dev overrides
├── nginx/                   # Reverse proxy
├── queue-manager/           # FastAPI service
├── comfyui-worker/          # GPU worker
├── comfyui-frontend/        # User UI containers
├── admin/                   # Admin dashboard
├── scripts/                 # Management scripts
├── data/                    # Persistent volumes
└── docs/                    # User/admin guides
```

---

## 📚 Document Links

### Core Documents
- [README.md](./README.md) - Public code project overview and dev quickstart
- [Progress Log](./progress-2.md) - Session logs, metrics, standup notes
- [GPU Deployment](./implementation-deployment-verda.md) - Verda GPU setup
- [Product Requirements](./prd.md) - Full requirements
- [Claude Guide](./CLAUDE.md) - Development context (this file)

### User Documentation 
- **docs/user-guide.md** - For workshop participants
- **docs/admin-guide.md** - For instructor
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
**Doc Updated:** 2026-01-17

==IMPORTANT: Docs MUST be comprehensive yet NO FLUFF - NO extraneous / irrelevant info / value-statements / achievements boasting==

---

## 🔄 Update Instructions

### At the END of EVERY response, update `progress.md`:

```markdown
### Session N - YYYY-MM-DD

**Activities:**
- What was accomplished in this session
- Key decisions made
- Files created/modified

**Code Created:**
- List major files with brief description

**Blockers:**
- Any issues encountered

**Next Session Goals:**
- What to do next
```

### Keep these metrics current in `progress.md`:
- Commits List (inc. description)
- Lines of Code
- Files Created
- Sprint Status (🔨 In Progress / ✅ Complete / ⏳ Not Started)
- Risk Register updates

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
  │ Remote GPU (e.g. Verda) H100            │
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
    ├─→ /user/1-20 → Frontend containers
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

---

## 🛠️ Technology Stack

### Infrastructure
- **Container Runtime:** Docker + Docker Compose
- **Reverse Proxy:** Nginx (SSL termination, routing)
- **Queue:** Redis 7+ (job queue, pub/sub)
- **SSL:** Existing ahelme.net certificate

### Services
- **Queue Manager:** Python 3.11+ with FastAPI + WebSocket
- **Workers:** ComfyUI v0.9.2 with GPU support
- **Frontends:** ComfyUI v0.9.2 web UI (CPU-only mode)
- **Admin:** HTML/JS dashboard

### Deployment
- **Development:** Docker Compose locally
- **Production:** Hetzner VPS + Remote GPU (e.g. Verda) H100 instance
- **GPU:** NVIDIA H100 80GB (shared)

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

### SSL Certificate
- **Domain:** ahelme.net
- **Location:** User will provide cert paths
- **Type:** Existing cert (not Let's Encrypt)
- **Format:** PEM files (fullchain.pem + privkey.pem)

---

## 📋 Implementation Phases

==MUST READ: implementation-deployment-verda.md==

## ✅ Success Criteria

==MUST READ: prd.md==

### MVP Requirements (Must Have)
- ✅ 20 isolated user interfaces accessible
- ✅ Jobs queue and execute on GPU
- ✅ HTTPS working with SSL cert
- ✅ Outputs persist after restart
- ✅ Admin can monitor queue
- ✅ System stable for 8-hour workshop

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

### Cloudflare R2 (Two Buckets)
- **Provider:** Cloudflare R2 (S3-compatible)
- **Endpoint:** `https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com`
- **Cost:** ~$2/month total (no egress fees)
- **Access:** Via AWS CLI with R2 API credentials

**Models Bucket:** `comfy-multi-model-vault-backup`
- Location: Oceania
- Contents: `checkpoints/*.safetensors`, `text_encoders/*.safetensors`
- Purpose: Model files only (~45GB)

**Cache Bucket:** `comfy-multi-cache`
- Location: Eastern Europe (closer to Verda/Finland)
- Contents: `worker-image.tar.gz` (~2.5GB), `verda-config-backup.tar.gz` (~14MB)
- Purpose: Container image and config backup

### Restore Scripts (Private GitHub Repo)
- **Repo:** `ahelme/comfymulti-scripts` (private)
- **URL:** https://github.com/ahelme/comfymulti-scripts
- **Local path on mello:** `/home/dev/projects/comfymulti-scripts/`
- **Purpose:** Version-controlled restore/bootstrap scripts for Verda instances
- **Contents:**
  - `quick-start.sh` - Bootstrap script (mounts SFS, downloads from R2/GitHub)
  - `RESTORE-SFS.sh` - System restore with flag support (`--with-models`, `--with-container`, `--full`)
  - `RESTORE-BLOCK-MELLO.sh` - Alternative block storage workflow
  - `README-RESTORE.md` - Quick reference for restore scenarios
- **Note:** Scripts downloaded from GitHub, binary files (models, container) from R2

---

## 🐛 Known Issues / Technical Debt

None yet.

---

## ⚠️ Verda GPU Cloud Gotchas

### Storage Options

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
- [Verda H100](https://verda.com/h100-sxm5) - GPU cloud provider
- [Verda Products](https://verda.com/products) - Instance types

### ComfyUI Resources
- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [ComfyUI Wiki](https://comfyui-wiki.com/)
- [ComfyUI API Docs](https://github.com/comfyanonymous/ComfyUI/discussions/2073)

---

## 🎓 Context for Claude

### User Background
- Running AI/video generation workshop
- Has Hetzner VPS with ahelme.net SSL cert
- Wants to use Remote GPU provider (Verda, RunPod, etc.) H100 for GPU compute
- 20 participants need isolated environments
- Workshop in ~2 weeks

### Key Decisions Made
1. **Custom build** chosen over managed services (cost, control, flexibility for any GPU provider)
2. **Existing SSL cert** will be mounted (not Let's Encrypt)
3. **Queue modes:** FIFO + round-robin + instructor priority
4. **Single H100** with 1-3 workers (test then scale)
5. **Persistent storage** for all user data
6. **User model uploads** allowed

### User Preferences
- Appreciates thoroughness and detail
- Values comprehensive and accurate documentation
- Wants progress tracking (hence progress.md)
- Likes structured approaches

---

## 🗓️ CLAUDE TO-DO LIST: Pre-Workshop SFS Creation

**When:** Jan 31 (or chosen pre-workshop date)
**Duration:** ~45 minutes
**Cost:** ~$3 (V100 spot for setup)

### SSH Keys for Verda

**During Verda provisioning, add BOTH public keys:**

1. **User's Mac key** - for manual SSH access
2. **Mello VPS key** - for mello to SSH into Verda

```
# Mello VPS public key (MUST ADD):
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiwaT6NQcHe7cYDKB5LrtmyIU0O8iRc7DJUmZJsNkDD dev@vps-for-verda
```

**Why this matters for restore scripts:**
- Mac can SSH into Verda ✓ (Mac has private key)
- Mello can SSH into Verda ✓ (Mello has private key)
- Verda CANNOT pull from mello ✗ (Verda has no private key for mello)

**Therefore:** Restore scripts first check SFS (fast, for workshop month), then fall back to remote:
- **SFS** - First choice (files cached from previous session)
- **R2** - Binary files (models, container image, config tarball)
- **GitHub** - Scripts (`ahelme/comfymulti-scripts` private repo)

### Critical Principles

**1. Check Before Downloading/Restoring**

| File Type | Check Order | Rationale |
|-----------|-------------|-----------|
| **Models** (~45GB) | SFS → R2 | Large, live on SFS |
| **Config, identity, container** | /root/ → SFS → R2 | Extracted to instance |
| **Scripts** | /root/ → SFS → GitHub | Small, versioned |

**2. Tailscale Identity Must Be Restored BEFORE Starting Tailscale**

If Tailscale starts without the backed-up identity, it gets a **NEW IP address**.
The restore scripts restore `/var/lib/tailscale/` BEFORE running `tailscale up`.
This preserves the expected IP: **100.89.38.43**

### Prerequisites Checklist

Before starting, verify:
- [ ] mello VPS is running (comfy.ahelme.net)
- [ ] R2 bucket contains binary files:
  - [ ] `checkpoints/*.safetensors` (models)
  - [ ] `text_encoders/*.safetensors`
  - [ ] `worker-image.tar.gz` (2.5 GB)
  - [ ] `verda-config-backup.tar.gz` (14 MB)
- [ ] GitHub repo `ahelme/comfymulti-scripts` contains scripts:
  - [ ] `quick-start.sh`
  - [ ] `RESTORE-SFS.sh`
  - [ ] `RESTORE-BLOCK-MELLO.sh`
- [ ] User's Mac SSH key is ready for Verda provisioning

### Step-by-Step Process

**See [Admin Backup & Restore Guide](./docs/admin-backup-restore.md)** for complete step-by-step instructions including:
- Provisioning SFS and GPU instance
- Running quick-start.sh and RESTORE-SFS.sh
- Downloading models from R2
- Verification checklist
- Troubleshooting

### Pre-Populated To-Dos for Claude

Copy these to TodoWrite at session start:

```json
[
  {"content": "Verify mello VPS is running", "status": "pending", "activeForm": "Verifying mello VPS"},
  {"content": "Verify R2 has models + container", "status": "pending", "activeForm": "Checking R2 contents"},
  {"content": "Create SFS 50GB on Verda", "status": "pending", "activeForm": "Creating SFS on Verda"},
  {"content": "Create GPU instance with quick-start.sh", "status": "pending", "activeForm": "Creating GPU instance"},
  {"content": "Verify quick-start.sh ran correctly", "status": "pending", "activeForm": "Verifying quick-start"},
  {"content": "Transfer backup files to Verda", "status": "pending", "activeForm": "Transferring backup files"},
  {"content": "Run RESTORE-SFS.sh", "status": "pending", "activeForm": "Running RESTORE-SFS.sh"},
  {"content": "Verify Tailscale connected", "status": "pending", "activeForm": "Verifying Tailscale"},
  {"content": "Verify models downloaded to SFS", "status": "pending", "activeForm": "Checking models on SFS"},
  {"content": "Verify container loaded", "status": "pending", "activeForm": "Checking container"},
  {"content": "Start worker and test connection", "status": "pending", "activeForm": "Testing worker"},
  {"content": "Shut down GPU instance (keep SFS)", "status": "pending", "activeForm": "Cleaning up"}
]
```

### Troubleshooting

See [Admin Backup & Restore Guide - Troubleshooting](./docs/admin-backup-restore.md#troubleshooting) for common issues and solutions.

---

## 📝 Session Checklist

Before each session ends:
- [ ] Update progress-2.md with session log
- [ ] Update relevant implementation docs if needed
- [ ] Commit code changes to git
- [ ] Update development docs with key changes made (IMPORTANT!) - CLAUDE.md, README.md, linked dev / project docs
- [ ] Consider any changes made that are relevant to users - if any then scour docs for any details that need changing
- [ ] Update metrics (files created, LOC, etc.)
- [ ] Note any blockers or decisions
- [ ] Clear next session goals

---

## 🚨 Emergency Contacts / Fallbacks

If critical issues:
1. Check docs/troubleshooting.md
2. Review GitHub issues in referenced projects
3. Fallback: Simple mode (manual worker selection)
4. Last resort: Standalone ComfyUI instances for participants

---

**Repository:** https://github.com/USER/comfyui-workshop (TBD - creating now)
**Last Updated:** 2026-01-02 by Claude
**Next Update:** End of current session
