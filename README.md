**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-02
**Doc Updated:** 2026-01-18

---

# ComfyUI Multi-User Workshop Platform

A scalable, multi-user ComfyUI platform with **split CPU/GPU architecture** - run 20 user interfaces on cheap VPS hosting while spinning up GPU workers only when needed.

**Perfect for:** Workshops, team environments, or anyone who wants ComfyUI without 24/7 GPU costs.

---

## Core Strategy: Split Architecture

```
┌─────────────────────────────────────┐
│   CHEAP CPU HOSTING (~$5-20/month)  │
│   (Hetzner, DigitalOcean, Linode)   │
│                                     │
│   - Web App (Nginx + SSL)           │
│   - 20 User Interfaces (CPU only)   │
│   - Job Queue (Redis)               │
│   - Admin Dashboard                 │
│   - Always running, minimal cost    │
└────────────────┬────────────────────┘
                 │
                 │ VPN (Tailscale)
                 │
┌────────────────▼────────────────────┐
│   GPU CLOUD (Pay-per-use)           │
│   (Verda, RunPod, Lambda, Local)    │
│                                     │
│   - ComfyUI Workers (GPU)           │
│   - Spin up when needed             │
│   - Spin down when done             │
│   - $0 when not running             │
└────────────────┬────────────────────┘
                 │
                 │ S3 API
                 │
┌────────────────▼────────────────────┐
│   MODEL VAULT (Permanent Storage)   │
│   (Cloudflare R2, S3, Backblaze B2) │
│                                     │
│   - LTX-2 models (~45GB)            │
│   - ~$1/month (R2 has free egress)  │
│   - Download to GPU on startup      │
└─────────────────────────────────────┘
```

**Why this works:**
- VPS runs 24/7 for ~$10/month (users can queue jobs anytime)
- GPU costs $0 when not running
- Models stored permanently for ~$1/month
- Spin up GPU in ~30 seconds when ready to generate

---

## Cost Comparison

| Approach | Monthly Cost | Notes |
|----------|--------------|-------|
| **This architecture** | ~$15 + GPU hours | VPS $10 + R2 $1 + GPU only when used |
| H100 always-on | ~$1,700 | 24/7 × $2.30/hr |
| Gaming PC + electricity | ~$50-100 | Plus wear, noise, heat |
| Managed services | ~$100-500 | Replicate, Banana.dev markup |

**Workshop example (8-hour day):**
- VPS: $10/month (already running)
- GPU (H100 × 8hrs): $18
- R2: $1/month
- **Total: ~$30** vs $1,700/month always-on

---

## Features

- **20 Isolated User Workspaces** - Each participant gets their own ComfyUI interface
- **HTTP Basic Auth** - Password protection for all workspaces
- **Tailscale VPN Security** - Encrypted tunnel for Redis (no public exposure)
- **Intelligent Queue** - FIFO, round-robin, and priority scheduling
- **Real-time Updates** - WebSocket queue status broadcasting
- **Admin Dashboard** - Monitor and manage all activity
- **LTX-2 Video Generation** - 19B parameter video model support
- **Flux.2 Klein Image Gen/Editing** - fast open-source image (good for video) 
- **Multi-Provider** - Works with any GPU cloud or local hardware

---

## Quick Start

### Option A: Use Our Quick-Start Script (Recommended)

1. Get latest `quick-start.sh` from **https://github.com/ahelme/comfymulti-scripts** (private repo)
2. In Verda Console, paste into "Startup Script" field, add both SSH keys, provision
3. SSH in and run:
```bash
bash /root/quick-start.sh <PSEUDOPATH>
# Get PSEUDOPATH from Verda Dashboard: Storage tab → SFS dropdown → PSEUDOPATH
```

### Option B: Manual Setup

#### 1. Set Up VPS (CPU Hosting)

```bash
# Clone repo
git clone https://github.com/ahelme/comfy-multi.git
cd comfy-multi

# Configure
cp .env.example .env
nano .env  # Set DOMAIN, SSL paths, REDIS_PASSWORD

# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh=false
# Visit the URL shown in your browser to authenticate
# Example: https://login.tailscale.com/a/abc123xyz
echo "Your Tailscale IP: $(tailscale ip -4)"

# Start services
./scripts/start.sh
```

#### 2. Set Up Model Vault (R2/S3)

```bash
# Create three Cloudflare R2 buckets:
# - Models bucket (Oceania): checkpoints, text_encoders
# - Cache bucket (EU): container image, configs
# - User files bucket (EU): user workflows, outputs, uploads

# Upload models to Models bucket:
aws s3 sync ./models/ s3://comfy-multi-model-vault-backup/ \
  --endpoint-url https://your-r2-endpoint
```

#### 3. Set Up GPU Worker (When Needed)

```bash
# SSH to GPU instance
ssh root@your-gpu-instance

# Install Tailscale (same account as VPS)
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh=false
# Visit the URL shown in your browser to authenticate

# Download models from R2 Models bucket
aws s3 sync s3://comfy-multi-model-vault-backup/ /mnt/models/ \
  --endpoint-url https://your-r2-endpoint

# Start worker
cd ~/comfy-multi
REDIS_HOST=<vps-tailscale-ip> docker compose up -d worker-1
```

---

## Deployment Options

### GPU Cloud Providers

| Provider | H100 Price | Best For |
|----------|------------|----------|
| **Verda** | ~$2.30/hr | EU compliance, green energy |
| **RunPod** | ~$2.40/hr | Per-second billing, good availability |
| **Lambda Labs** | ~$2.50/hr | Reliable, good support |
| **Vast.ai** | ~$1.50/hr | Cheapest, variable quality |
| **Local GPU** | $0/hr | If you have hardware |

### Serverless Containers for AI inference
Scalable inference for elastic workshop sizes / demands

### Storage Options

| Provider | Cost | Notes |
|----------|------|-------|
| **Cloudflare R2** | ~$0.015/GB/month | Free egress (recommended) |
| **AWS S3** | ~$0.023/GB/month | Egress fees apply |
| **Backblaze B2** | ~$0.006/GB/month | Cheapest, S3-compatible |
| **Verda SFS** | ~$0.20/GB/month | Network-attached, instant mount |

### VPS Options

| Provider | ~$10/month Plan | Notes |
|----------|-----------------|-------|
| **Hetzner** | CX22 (4GB RAM) | Great EU option |
| **DigitalOcean** | Basic (4GB RAM) | Simple, reliable |
| **Linode** | Shared 4GB | Good performance |
| **Vultr** | Cloud Compute | Many locations |

---

## Deployment Learnings

Hard-won insights from deploying ComfyUI on cloud GPU infrastructure.

### Inference Strategies

**Dedicated Instance** - Spin up a GPU, run jobs, shut down.
- Simple, predictable pricing
- Best for: small workshops, testing, development
- Gotcha: queue backlog during bursts (everyone generates at once after a demo)

**Serverless Containers** - Auto-scale 0→N based on queue depth.
- Pay per second/minute of actual compute
- Best for: 10+ concurrent users, bursty workloads
- Gotcha: cold start time (10-30 seconds for first request)

**Reality check:** A single H100 processes ~15 jobs/hour. With 20 filmmakers generating 5 iterations each after a demo, that's 100 jobs = 6+ hour queue. Serverless with 16 containers clears it in ~25 minutes.

### Storage Proximity Matters

Models are 45GB+. Download time dominates cold start.

| Storage Location | Time to GPU | Best For |
|------------------|-------------|----------|
| Same-region SFS/NFS | ~2 seconds (mount) | Fastest warm-up |
| Same-provider block | ~30 seconds (attach + mount) | Good balance |
| Cross-region S3/R2 | ~15-30 minutes | Permanent backup only |

**The pattern:** Keep models on provider-local storage (SFS) during active use. Use R2 for permanent backup, not runtime loading.

### Container Strategies

**Container Registry** (Docker Hub, GHCR, provider registry)
- Pros: Versioned, pull from anywhere, integrates with serverless
- Cons: Push/pull overhead, registry costs at scale
- Best for: Serverless, multi-region, team environments

**Tarball on Shared Storage** (our approach)
- Pros: `docker load` in ~2 seconds from SFS, no registry needed
- Cons: Manual versioning, tied to one provider's storage
- Best for: Single-provider deployments, workshops

**Why we chose tarball:** With models on Verda SFS anyway, adding the container image (~3GB) means instant `docker load` - no registry round-trip, no cold pull. Total warm-up: mount SFS + load container = ~5 seconds.

### Cloud Provider Gotchas

**Block storage wipe:** Some providers (Verda, others) format block storage attached during instance creation. Always attach storage *after* the instance is running.

**Spot instance termination:** Your GPU can disappear mid-job. Use persistent storage (SFS/NFS) so you don't lose models. Keep state in Redis on your VPS, not on the GPU.

**Container conflicts:** GPU cloud images often have Docker pre-installed. Don't `apt install docker.io` - it conflicts. Check what's already there.

### The Optimal Setup

For workshops and bursty workloads:

```
Off-season ($1/month):
  └─ Models in R2 (permanent backup)

Workshop month ($15/month + compute):
  ├─ VPS running 24/7 (queue + UI)
  ├─ SFS with models + container tarball
  └─ GPU instances spin up/down as needed

Daily workflow (30 seconds):
  1. Create spot GPU instance (no storage attached)
  2. Mount SFS → models instantly available
  3. docker load < tarball → worker ready
  4. Worker connects to VPS queue via Tailscale
```

**Cost breakdown:** $10 VPS + $14 SFS + $1 R2 + GPU hours. An 8-hour workshop day costs ~$30 total vs $1,700/month for always-on H100.

---

## Architecture Details

```
[User Browser]
    ↓ HTTPS
[Nginx :443] → SSL termination, routing, HTTP Basic Auth
    ├─→ /user001-020/ → Frontend containers (CPU only)
    ├─→ /api → Queue Manager (FastAPI)
    └─→ /admin → Admin Dashboard

[Queue Manager :3000]
    ↓ Redis (via Tailscale VPN)
[Job Queue]
    ↓
[ComfyUI Workers :8188+] ← GPU processing
    ↓
[Shared Storage] ← models from R2, outputs to local
```

---

## Daily Workflow

### Workshop Day

```bash
# Morning: Spin up GPU (~30 seconds)
1. Create GPU spot instance (no storage attached)
2. SSH in and run quick-start script
3. Workers connect to VPS queue automatically

# During workshop
- Users submit jobs via web interface
- Queue distributes to GPU workers
- Monitor via admin dashboard
- Cron jobs run backup scripts: VPS (user files) & GPU cloud (models, config)

# Evening: Shut down GPU
1. docker compose down
2. Terminate GPU instance
3. $0 GPU costs overnight
```

### Development (Free)

```bash
# Test queue system without GPU
./scripts/start.sh  # VPS services only
# Submit test jobs - they queue but don't process
# Perfect for UI/UX development
```

---

## Configuration

### Environment Variables

```env
# Domain & SSL
DOMAIN=your-domain.com
SSL_CERT_PATH=/etc/letsencrypt/live/your-domain/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/your-domain/privkey.pem

# Security
REDIS_PASSWORD=your_secure_password
REDIS_BIND_IP=100.x.x.x  # Your VPS Tailscale IP

# Users
NUM_USERS=20

# Queue
QUEUE_MODE=fifo  # fifo, round-robin, priority

# Model Storage (R2/S3)
R2_ENDPOINT=https://xxx.r2.cloudflarestorage.com
R2_BUCKET=your-model-bucket
```

---

## Project Structure

```
comfy-multi/
├── docker-compose.yml       # Service orchestration
├── docker-compose.users.yml # Isolated user containers
├── .env.example             # Configuration template
├── scripts/
│   ├── start.sh             # Start VPS services
│   ├── stop.sh              # Stop VPS services
│   └── status.sh            # Check service health
│   # Backup/restore scripts in private repo: github.com/ahelme/comfymulti-scripts
├── nginx/                   # Reverse proxy + SSL
├── queue-manager/           # FastAPI job scheduler
├── comfyui-worker/          # GPU worker container
├── comfyui-frontend/        # User interface containers
├── admin/                   # Admin dashboard
├── data/                    # Persistent storage
│   ├── models/              # Symlink to mounted storage
│   └── outputs/             # Generated outputs
└── docs/                    # Documentation
```

---

## Documentation

### For Workshop Organizers
- [Workshop Workflow](./docs/admin-workflow-workshop.md) - Daily startup procedures
- [Backup & Restore](./docs/admin-backup-restore.md) - Backup to R2
- [Budget Strategy](./docs/admin-budget-strategy.md) - Cost optimization
- [Verda Setup](./docs/admin-verda-setup.md) - GPU cloud configuration

### For Participants
- [Quick Start](./docs/quick-start.md) - Get creating in 5 minutes
- [User Guide](./docs/user-guide.md) - Full reference
- [FAQ](./docs/faq.md) - Common questions

### For Developers
- [Implementation Plan](./implementation.md) - Architecture details
- [Progress Log](./progress.md) - Development history
- [Claude Guide](./CLAUDE.md) - AI assistant context

---

## Adapting for Your Setup

### Different GPU Provider

```bash
# Edit comfyui-worker/.env or pass at runtime
REDIS_HOST=<your-vps-tailscale-ip>
REDIS_PASSWORD=<your-password>

# The worker connects to your VPS queue automatically
docker compose up -d worker-1
```

### Different Storage

```bash
# Any S3-compatible storage works
# Just change the endpoint and credentials
aws s3 sync s3://your-bucket/ /mnt/models/ \
  --endpoint-url https://your-storage-endpoint
```

### Local GPU

```bash
# Same setup, just run worker locally
cd comfy-multi
REDIS_HOST=<vps-tailscale-ip> docker compose up -d worker-1
```

### Serverless (RunPod, Modal)

See [Serverless Research](./docs/research-serverless-gpu.md) for auto-scaling configuration with 16-40 concurrent containers.

---

## Troubleshooting

### GPU Worker Won't Connect

```bash
# Check Tailscale
tailscale status  # Should show VPS and GPU

# Test Redis connectivity
redis-cli -h <vps-tailscale-ip> -a <password> ping
```

### Models Not Loading

```bash
# Check mount
ls -la /mnt/models/checkpoints/

# Re-download from R2 Models bucket
aws s3 sync s3://comfy-multi-model-vault-backup/ /mnt/models/ \
  --endpoint-url $R2_ENDPOINT
```

### Queue Not Processing

```bash
# Check worker logs
docker logs comfy-multi-worker-1

# Check queue manager
curl https://your-domain/api/queue/status
```

---

## License

MIT License - see LICENSE file

---

## Acknowledgments

- Built with [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
- Queue patterns from [SaladTechnologies/comfyui-api](https://github.com/SaladTechnologies/comfyui-api)
- Architecture concepts from [Visionatrix](https://github.com/Visionatrix/Visionatrix)

---

**Version:** 1.0.0
**Status:** Production Ready
