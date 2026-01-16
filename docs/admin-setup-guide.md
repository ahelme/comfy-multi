# Admin Setup Guide

## Configuration Checklist

Before deploying, ensure you have:

- [ ] Hetzner VPS with Docker installed
- [ ] Domain registered on Namecheap (ahelme.net)
- [ ] SSL certificate obtained and paths confirmed
- [ ] Remote GPU instance provisioned (e.g. Verda, RunPod, Modal)
- [ ] Redis password generated (secure, 32+ characters)
- [ ] Admin password generated
- [ ] Model list finalized for workshop
- [ ] .env file configured
- [ ] DNS A record created (comfy.ahelme.net → VPS IP)
- [ ] Firewall rules configured
- [ ] SSH access to both VPS and GPU instance verified

---

## Detailed Setup Instructions

### 1. Hetzner VPS Setup

**Initial deployment on Hetzner VPS:**

```bash
# Clone repository
git clone https://github.com/ahelme/comfy-multi.git
cd comfy-multi

# Run setup
./scripts/setup.sh

# Edit configuration
nano .env

# Start services
./scripts/start.sh
```

### 2. Remote GPU Instance Setup

**Deploy to Remote GPU (e.g. Verda H100 Instance):**

```bash
# SSH to GPU instance
ssh user@your-gpu-instance

# Clone repository
git clone https://github.com/ahelme/comfy-multi.git
cd comfy-multi

# Run setup
./scripts/setup.sh

# Edit configuration - CRITICAL: Set Redis to point to VPS
nano .env

# Start services
./scripts/start.sh
```

**Or use quick-start script (recommended for Verda):**
```bash
# Run quick-start to mount SFS and set up basics
curl -sL https://raw.githubusercontent.com/ahelme/comfy-multi/main/scripts/quick-start.sh | bash -s <sfs-endpoint>

# Authenticate Tailscale (REQUIRED for Redis connection)
sudo tailscale up --ssh=false
# Visit the URL shown in your browser to authenticate
# Verify: tailscale ip -4  # Should show 100.89.38.43

# If fresh SFS, run restore and follow NEXT STEPS for R2 download
sudo bash RESTORE-SFS.sh
```

### 3. Environment Variables Configuration

Edit `.env` and configure all required variables:

```env
# Domain & SSL (Namecheap domain + Hetzner VPS)
DOMAIN=ahelme.net
SSL_CERT_PATH=/etc/ssl/certs/fullchain.pem
SSL_KEY_PATH=/etc/ssl/private/privkey.pem

# Security
REDIS_PASSWORD=<generate-secure-password>
ADMIN_PASSWORD=<generate-secure-password>

# Queue Settings
QUEUE_MODE=fifo                 # or round_robin
ENABLE_PRIORITY=true            # Allow instructor override
NUM_WORKERS=1                   # Start with 1
NUM_USERS=20                    # Workshop size

# GPU Settings (Hetzner VPS)
WORKER_GPU_MEMORY_LIMIT=70G     # H100 has 80GB
JOB_TIMEOUT=3600               # 1 hour max per job

# Redis Configuration (Remote GPU points back to VPS)
REDIS_HOST=comfy.ahelme.net     # On GPU instance
REDIS_PORT=6379
```

**Generate secure passwords:**
```bash
openssl rand -base64 32
```

### 4. SSL Certificate Configuration

**Certificate Location and Setup:**

The SSL certificates should be on the **Hetzner VPS** (not the GPU instance):

```bash
# Verify certificate paths on VPS
ls -la /etc/ssl/certs/fullchain.pem
ls -la /etc/ssl/private/privkey.pem

# Check certificate expiry
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -enddate

# Verify certificate permissions (must be readable by docker)
chmod 644 /etc/ssl/certs/fullchain.pem
chmod 600 /etc/ssl/private/privkey.pem
```

**Update .env with correct paths:**
```env
SSL_CERT_PATH=/etc/ssl/certs/fullchain.pem
SSL_KEY_PATH=/etc/ssl/private/privkey.pem
```

### 5. DNS Configuration

**Configure DNS on Namecheap (for Hetzner VPS):**

1. Log in to Namecheap
2. Go to Domain → ahelme.net → Manage
3. Click Advanced DNS
4. Add/Update A record:
   - **Host**: comfy (or subdomain)
   - **Type**: A
   - **Value**: Your Hetzner VPS public IP
   - **TTL**: 3600

**Verify DNS resolution:**
```bash
nslookup comfy.ahelme.net
dig comfy.ahelme.net
```

### 6. Model Download and Configuration

**Required models for workshop:**

```bash
# SSH to GPU instance
ssh user@your-gpu-instance

# Navigate to models directory
cd data/models/shared/

# LTX-2 19B Dev Model (required - main checkpoint)
wget https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-dev-fp8.safetensors \
  -O ./data/models/checkpoints/ltx-2-19b-dev-fp8.safetensors

# Gemma 3 Text Encoder (required for LTX-2)
wget https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it.safetensors \
  -O ./data/models/text_encoders/gemma_3_12B_it.safetensors

# LTX-2 Spatial Upscaler (optional - 2x upscaling)
wget https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-spatial-upscaler-x2-1.0.safetensors \
  -O ./data/models/latent_upscale_models/ltx-2-spatial-upscaler-x2-1.0.safetensors

# Video models (if doing video workshop)
# LTX-Video, HunyuanVideo, or AnimateDiff
```

**Model directory structure:**
```
data/models/shared/
├── checkpoints/      # Model checkpoints (SDXL, etc.)
├── vae/              # VAE models
├── loras/            # LoRA adapters
├── embeddings/       # Textual inversion
└── controlnets/      # ControlNet models
```

**Verify models are accessible:**
```bash
# From GPU worker
docker-compose exec worker-1 ls -lah /models/shared/checkpoints/

# Check free disk space
df -h /data/models/
```

### 7. Workflow Templates

**Create workshop templates:**

```bash
cd data/workflows/

# Copy example workflows
cp /path/to/your/workflows/*.json .

# Name clearly:
# - 01_intro_text_to_image.json
# - 02_advanced_img2img.json
# - 03_video_generation.json
```

**Verify workflows are accessible:**
```bash
ls -la data/workflows/
```

### 8. Initial Testing Procedures

**System health check:**

```bash
# On Hetzner VPS
./scripts/status.sh

# Check all services running
docker-compose ps

# Verify web access
curl -k https://localhost/health
```

**Test workflow execution:**

1. Open `https://comfy.ahelme.net/user001/` (instructor workspace)
2. Load example workflow
3. Queue a test job
4. Monitor in admin dashboard: `https://comfy.ahelme.net/admin`
5. Verify job completes successfully

**Test network connectivity (GPU ↔ VPS):**

```bash
# First: Authenticate Tailscale on GPU instance
sudo tailscale up --ssh=false
# Visit the URL shown (e.g., https://login.tailscale.com/a/abc123) in your browser
# Verify connection: tailscale status

# From GPU instance, test Redis connection to VPS via Tailscale
redis-cli -h 100.99.216.71 -p 6379 -a $REDIS_PASSWORD ping
# Should return: PONG
```

**Load test (optional - simulate workshop load):**

```bash
# On VPS
for i in {1..20}; do
  curl -X POST https://localhost/api/jobs \
    -H "Content-Type: application/json" \
    -d "{\"user_id\": \"user$(printf '%03d' $i)\", \"workflow\": {...}}" &
done
```

---

## Two-Tier Architecture Summary

```
┌─────────────────────────────────────────┐
│ Hetzner VPS (comfy.ahelme.net)          │
│  - Nginx (HTTPS, SSL on port 443)       │
│  - Redis (job queue, port 6379)         │
│  - Queue Manager (FastAPI, port 3000)   │
│  - Admin Dashboard (web UI)             │
│  - User Frontends x20 (CPU only)        │
└──────────────┬──────────────────────────┘
               │ Network
               │ (Redis connection)
               │ Firewall rule: allow GPU IP on port 6379
               │
┌──────────────▼──────────────────────────┐
│ Remote GPU (e.g. Verda H100)            │
│  - Worker 1 (ComfyUI + GPU, H100)       │
│  - Worker 2 (ComfyUI + GPU) [optional]  │
│  - Worker 3 (ComfyUI + GPU) [optional]  │
│                                         │
│  Redis client connects to:              │
│  REDIS_HOST=comfy.ahelme.net            │
│  REDIS_PORT=6379                        │
│  REDIS_PASSWORD=<from .env>             │
└─────────────────────────────────────────┘
```

---

## Next Steps

Once setup is complete:
1. Read **admin-guide.md** for monitoring and health checks
2. Review **admin-dashboard.md** for real-time management
3. Check **admin-troubleshooting.md** for common issues
4. Use **admin-workshop-checklist.md** before workshop day
5. Follow **admin-security.md** for production security
