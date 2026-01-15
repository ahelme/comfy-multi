**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-02
**Doc Updated:** 2026-01-15

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
- **Multi-Provider** - Works with any GPU cloud or local hardware

---

## Quick Start

### Option A: Use Our Quick-Start Script (Recommended)

```bash
# On a fresh GPU instance
curl -sL https://raw.githubusercontent.com/ahelme/comfy-multi/main/scripts/quick-start.sh | bash -s <your-sfs-endpoint>
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
sudo tailscale up
echo "Your Tailscale IP: $(tailscale ip -4)"

# Start services
./scripts/start.sh
```

#### 2. Set Up Model Vault (R2/S3)

```bash
# Create Cloudflare R2 bucket (or any S3-compatible storage)
# Upload your models once:
aws s3 sync ./models/ s3://your-bucket/ --endpoint-url https://your-r2-endpoint
```

#### 3. Set Up GPU Worker (When Needed)

```bash
# SSH to GPU instance
ssh root@your-gpu-instance

# Install Tailscale (same account as VPS)
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up

# Download models from R2
aws s3 sync s3://your-bucket/ /mnt/models/ --endpoint-url https://your-r2-endpoint

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
├── .env.example             # Configuration template
├── scripts/
│   ├── quick-start.sh       # GPU instance bootstrap
│   ├── backup-verda.sh      # Backup to R2
│   └── start.sh             # Start VPS services
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

# Re-download from R2
aws s3 sync s3://your-bucket/ /mnt/models/ --endpoint-url $R2_ENDPOINT
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
