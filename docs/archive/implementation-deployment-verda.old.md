**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-16

---

# GPU Deployment Guide (Tier 2: Inference Layer)

**Target:** Remote GPU Instance (Verda H100, RunPod, Modal, or local GPU)
**Purpose:** Deploy GPU workers that connect to VPS Redis for job processing
**Prerequisites:** VPS (Tier 1) deployed and accessible at comfy.ahelme.net

---

## Architecture Overview

```
┌─────────────────────────────────────┐
│  Tier 1: Hetzner VPS                │
│  comfy.ahelme.net                   │
│  Tailscale IP: 100.99.216.71        │
│  - User Frontends (20x)             │
│  - Queue Manager (FastAPI)          │
│  - Redis (VPN-only access)          │
│  - Admin Dashboard                  │
└──────────────┬──────────────────────┘
               │
               │ Tailscale VPN (WireGuard)
               │ Encrypted tunnel
               │ Port: 6379 (VPN only)
               │
┌──────────────▼──────────────────────┐
│  Tier 2: Remote GPU Instance        │
│  (Verda H100 / RunPod / Modal)      │
│  Tailscale IP: 100.89.38.43         │
│  - ComfyUI Worker 1 (+ GPU)         │
│  - ComfyUI Worker 2 (+ GPU) [opt]   │
│  - ComfyUI Worker 3 (+ GPU) [opt]   │
│                                     │
│  ENV: REDIS_HOST=100.99.216.71     │
└─────────────────────────────────────┘
```

**Key Points:**
- GPU workers connect TO VPS via **Tailscale VPN** (not public internet)
- Workers poll Redis for jobs from VPS
- Redis uses Tailscale IP (100.99.216.71), NOT public domain
- No inbound ports needed on GPU instance (outbound only)
- Can scale to 1-3 workers per H100 GPU

---

## Prerequisites Checklist

Before starting, verify:

- [ ] **VPS (Tier 1) is deployed and running**
  - Test: `curl https://comfy.ahelme.net/health` returns OK
  - Test: `curl https://comfy.ahelme.net/api/health` returns JSON

- [ ] **Tailscale VPN configured on both VPS and GPU instance**
  - REQUIRED: Both servers must be on same Tailscale network
  - VPS Tailscale IP: 100.99.216.71
  - GPU Tailscale IP: (will get after installation)
  - Verify REDIS_PASSWORD from VPS `.env` file

- [ ] **GPU instance provisioned**
  - Verda H100 instance, OR
  - RunPod GPU instance, OR
  - Modal GPU endpoint, OR
  - Local machine with NVIDIA GPU

- [ ] **GPU instance has:**
  - Docker installed
  - nvidia-docker2 / nvidia-container-toolkit installed
  - SSH access configured
  - Sufficient VRAM (recommend 40GB+ for SDXL models)

---

## Recommended: SFS Workflow (Verda)

For Verda deployments, use the automated restore workflow:

- **[Workshop Workflow Guide](./docs/admin-workflow-workshop.md)** - Daily startup & full setup
- **[Scripts Reference](./docs/admin-scripts.md)** - quick-start.sh, RESTORE-SFS.sh, RESTORE-BLOCK-MELLO.sh
- **[Backup & Restore](./docs/admin-backup-restore.md)** - Storage strategy, backup/restore procedures

Key scripts: `quick-start.sh` (daily), `RESTORE-SFS.sh` (full restore with SFS), `RESTORE-BLOCK-MELLO.sh` (full restore with Block Storage)

---

## Provider-Specific Setup (Manual)

### Option A: Verda H100 Instance

**Provision instance:**
1. Sign up at https://verda.com/
2. Create H100 instance (h100-sxm5 recommended)
3. Select region (eu-central or closest to VPS)
4. Configure SSH key access
5. Start instance and note IP address

**Connect via SSH:**
```bash
ssh user@<verda-instance-ip>
```

**Install Docker + nvidia-docker:**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install nvidia-docker2
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt update
sudo apt install -y nvidia-docker2
sudo systemctl restart docker

# Verify GPU accessible from Docker
docker run --rm --gpus all nvidia/cuda:12.1.0-base-ubuntu22.04 nvidia-smi
```

### Option B: RunPod GPU Instance

**Provision instance:**
1. Sign up at https://runpod.io/
2. Deploy pod with GPU (RTX 4090 / A100 / H100)
3. Use template: "PyTorch" or "CUDA"
4. Configure SSH via RunPod dashboard
5. Start instance and note connection details

**Connect via SSH:**
```bash
# RunPod provides SSH command in dashboard
ssh root@<runpod-instance>:port
```

**Install Docker if not present:**
```bash
# RunPod templates usually include Docker
docker --version

# If missing, install as above (Verda instructions)
```

### Option C: Modal GPU Endpoint

**Note:** Modal uses a different architecture (serverless functions). For this workshop, Verda or RunPod is recommended for persistent workers.

If using Modal, see: https://modal.com/docs/examples/comfyui

### Option D: Local GPU Machine

**Requirements:**
- NVIDIA GPU with 16GB+ VRAM (40GB+ recommended for SDXL)
- Ubuntu 22.04 or similar
- CUDA 12.1+ installed
- Docker + nvidia-docker2 installed

**Setup same as Verda instructions above.**

---

## GPU Instance Deployment Steps

### Step 1: Clone Repository on GPU Instance

**Connect to GPU instance:**
```bash
ssh user@<gpu-instance-ip>
```

**Clone repository:**
```bash
# Install git if needed
sudo apt install -y git

# Clone repository
cd ~
git clone https://github.com/ahelme/comfy-multi.git
cd comfy-multi
```

---

### Step 2: Configure .env for GPU Worker Mode

**Create .env file on GPU instance:**

```bash
cd ~/comfy-multi

# Copy example
cp .env.example .env

# Edit .env
nano .env
```

**Critical environment variables for GPU worker:**

```bash
# ============================================================================
# REDIS CONNECTION (Points to VPS)
# ============================================================================
# IMPORTANT: This must point to your VPS, NOT localhost!
REDIS_HOST=100.99.216.71
REDIS_PORT=6379

# IMPORTANT: Use SAME password as VPS Redis
# Copy this value from VPS /home/dev/projects/comfyui/.env
REDIS_PASSWORD=<paste-redis-password-from-vps>

# ============================================================================
# WORKER CONFIGURATION
# ============================================================================
NUM_WORKERS=1  # Start with 1, increase to 2-3 after testing

# Worker resource limits (H100 has 80GB VRAM)
WORKER_GPU_MEMORY_LIMIT=70G  # Leave 10GB headroom
WORKER_RESTART_POLICY=unless-stopped

# Worker behavior
WORKER_HEARTBEAT_TIMEOUT=60
WORKER_POLL_INTERVAL=2  # Check queue every 2 seconds

# ============================================================================
# MODELS & STORAGE
# ============================================================================
MODELS_PATH=./data/models
OUTPUTS_PATH=./data/outputs
INPUTS_PATH=./data/inputs
WORKFLOWS_PATH=./data/workflows

# ============================================================================
# LOGGING
# ============================================================================
LOG_LEVEL=INFO
DEBUG=false
VERBOSE_LOGS=true  # Set to true for debugging

# ============================================================================
# GPU WORKER ONLY - These are NOT needed
# ============================================================================
# No need for nginx, queue-manager, admin on GPU instance
# Only worker containers will run
```

**Save .env file** (Ctrl+O, Enter, Ctrl+X in nano)

---

### Step 3: Download Workshop Models on GPU Instance

**IMPORTANT:** Models must be on GPU instance for fast loading.

**Create model directories:**
```bash
cd ~/comfy-multi
mkdir -p data/models/shared/checkpoints
mkdir -p data/models/shared/vae
mkdir -p data/models/shared/loras
mkdir -p data/models/shared/controlnet
mkdir -p data/models/shared/upscale_models
mkdir -p data/models/shared/video_models
mkdir -p data/models/shared/3d_models
```

**Workshop Model Requirements**

This workshop uses cutting-edge video and image models. Choose models based on your workshop focus:

**Priority 1: Core Video Models (Choose 1-2 based on H100 capacity)**

```bash
cd ~/comfy-multi/data/models/shared/checkpoints

# Wan 2.2 (Wand AI - 28GB VRAM) - RECOMMENDED for video workshops
# Download from: https://huggingface.co/wand-ai/wan-2.2
# Example (adjust based on actual model hosting):
huggingface-cli download wand-ai/wan-2.2 --local-dir ./wan-2.2 --local-dir-use-symlinks False

# LTX-2 (Lightricks - 10GB VRAM) - Lightweight video option
# Download from: https://huggingface.co/Lightricks/LTX-2
huggingface-cli download Lightricks/LTX-2 --local-dir ./ltx-2 --local-dir-use-symlinks False

# Mochi 1 (Genmo - 18GB VRAM) - Alternative video model
# Download from: https://huggingface.co/genmo/mochi-1
huggingface-cli download genmo/mochi-1 --local-dir ./mochi-1 --local-dir-use-symlinks False
```

**Priority 2: Core Image Models (Choose 2-3)**

```bash
cd ~/comfy-multi/data/models/shared/checkpoints

# Flux.2 Dev (Black Forest Labs - 24GB VRAM) - Cutting-edge image quality
# Download from: https://huggingface.co/black-forest-labs/FLUX.1-dev
huggingface-cli download black-forest-labs/FLUX.1-dev --local-dir ./flux-2-dev --local-dir-use-symlinks False

# Z-Image Turbo (Stability AI - 8GB VRAM) - Fast generation
# Download from: https://huggingface.co/stabilityai/z-image-turbo
huggingface-cli download stabilityai/z-image-turbo --local-dir ./z-image-turbo --local-dir-use-symlinks False

# HunyuanImage-3.0 (Tencent - 20GB VRAM) - High quality multilingual
# Download from: https://huggingface.co/Tencent/HunyuanImage-3.0
huggingface-cli download Tencent/HunyuanImage-3.0 --local-dir ./hunyuan-image-3.0 --local-dir-use-symlinks False

# SD3.5 (Stability AI - 10GB VRAM) - Stable Diffusion 3.5
# Download from: https://huggingface.co/stabilityai/stable-diffusion-3.5
huggingface-cli download stabilityai/stable-diffusion-3.5 --local-dir ./sd35 --local-dir-use-symlinks False

# Juggernaut XL (RunDiffusion - 8GB VRAM) - Popular community model
# Download from: https://huggingface.co/RunDiffusion/Juggernaut-XL-v9
huggingface-cli download RunDiffusion/Juggernaut-XL-v9 --local-dir ./juggernaut-xl --local-dir-use-symlinks False
```

**Priority 3: Additional Video Models (Optional)**

```bash
# HunyuanVideo-I2V (Tencent - 25GB VRAM) - Image-to-video
huggingface-cli download Tencent/HunyuanVideo-I2V --local-dir ./hunyuan-video-i2v --local-dir-use-symlinks False

# SkyReels V1 (SkyworkAI - 15GB VRAM) - Sky/aerial video
huggingface-cli download SkyworkAI/SkyReels-v1 --local-dir ./skyreels-v1 --local-dir-use-symlinks False
```

**Priority 4: Utilities & Upscalers**

```bash
cd ~/comfy-multi/data/models/shared/upscale_models

# Stream DiffVSR (Video super-resolution - 6GB VRAM)
# Download from appropriate source

# HiStream (High-quality streaming - 8GB VRAM)
# Download from appropriate source
```

**Install huggingface-cli (if not already installed):**
```bash
pip install huggingface-hub
# Login (optional, for gated models)
huggingface-cli login
```

**Verify downloads:**
```bash
cd ~/comfy-multi/data/models/shared
find . -type f -name "*.safetensors" -o -name "*.bin" -o -name "*.ckpt" | sort
# Should show all downloaded models

# Check disk usage
du -sh checkpoints/ video_models/ upscale_models/
```

**Typical model sizes for workshop:**
- **Video Models:** 10-28GB each
- **Image Models:** 8-24GB each
- **Utilities:** 4-12GB each
- **Recommended setup (H100 80GB):**
  - 1 video model (Wan 2.2: 28GB)
  - 2 image models (Flux.2: 24GB + Z-Image: 8GB)
  - **Total in VRAM:** ~60GB (leaves 20GB headroom)
  - **Total on disk:** ~100-150GB storage needed

**Model Loading Strategy:**
- H100 80GB can hold 2-3 large models in VRAM simultaneously
- Plan workshop schedule around model loading times (2-5 min per model)
- Keep frequently-used models loaded to minimize swap time

---

### Step 4: Build Worker Docker Image

**Build the worker image:**
```bash
cd ~/comfy-multi

# Build worker image only (not other services)
docker-compose build worker-1

# Verify image built successfully
docker images | grep worker
```

**Expected output:**
```
comfy-multi-worker-1    latest    <image-id>    <timestamp>    <size>
```

---

### Step 5: Test Redis Connectivity

**Before starting worker, verify it can reach VPS Redis:**

```bash
# Test Redis connection from GPU instance
docker run --rm --network host redis:7-alpine redis-cli -h comfy.ahelme.net -p 6379 -a "<redis-password>" ping

# Expected output: PONG
```

**If connection fails:**
- Verify Tailscale is running on both VPS and GPU instance: `tailscale status`
- Verify REDIS_HOST in .env uses Tailscale IP (100.99.216.71, NOT comfy.ahelme.net or localhost)
- Verify REDIS_PASSWORD matches VPS
- Test Tailscale connectivity: `ping -c 3 100.99.216.71`

**Tailscale troubleshooting:**
```bash
# On GPU instance - verify Tailscale is running
tailscale status
# Should show VPS: 100.99.216.71  mello  ...

# Test connectivity
ping -c 3 100.99.216.71
redis-cli -h 100.99.216.71 -p 6379 -a '<password>' ping
```

**Security note:** Consider using Redis password authentication + SSL/TLS for production. For workshop, password authentication is sufficient.

---

### Step 6: Start GPU Worker(s)

**Start first worker:**
```bash
cd ~/comfy-multi

# Start worker-1 only
docker-compose up -d worker-1

# Monitor logs
docker-compose logs -f worker-1
```

**Expected log output:**
```
[INFO] Worker starting...
[INFO] Connecting to Redis at 100.99.216.71:6379
[INFO] Redis connection successful
[INFO] Loading models from /app/models
[INFO] Model checkpoint loaded: sdxl_base_1.0.safetensors
[INFO] Worker ready, polling for jobs...
```

**Check worker status:**
```bash
# Container should be "Up"
docker-compose ps worker-1

# Check GPU usage
nvidia-smi

# Should show Docker container using GPU
```

---

### Step 7: Verify Worker Registration

**On VPS, check if worker registered:**

```bash
# SSH to VPS
ssh dev@comfy.ahelme.net

# Check admin dashboard or query Redis
docker exec comfy-redis redis-cli -a "$REDIS_PASSWORD" keys "worker:*"

# Should show: worker:<worker-id>
```

**Or check via admin dashboard:**
- Open https://comfy.ahelme.net/admin
- Look for "Workers" section
- Should show 1 worker as "idle" or "ready"

---

### Step 8: End-to-End Test

**Submit test job from VPS user frontend:**

1. Open https://comfy.ahelme.net/user001/
2. Load simple workflow (text-to-image)
3. Click "Queue Prompt"

**Verify on GPU instance:**
```bash
# Watch worker logs
docker-compose logs -f worker-1

# Should show:
# [INFO] Job received: <job-id>
# [INFO] Executing workflow...
# [INFO] Step 1/20 (5%)...
# [INFO] Job completed: <job-id>

# Watch GPU usage during execution
watch -n 1 nvidia-smi
```

**Verify on VPS:**
- Admin dashboard should show job: pending → processing → completed
- Output image should appear in user001 workspace
- Output file saved to VPS: `/home/dev/projects/comfyui/data/outputs/user001/`

---

### Step 9: Scale Workers (Optional)

**If H100 has capacity, run 2-3 workers:**

```bash
cd ~/comfy-multi

# Start worker-2 and worker-3
docker-compose up -d worker-2 worker-3

# Verify all running
docker-compose ps | grep worker

# Monitor GPU memory
nvidia-smi

# Should show all workers loaded models
# Total VRAM usage should be < 70GB
```

**Expected performance:**
- 1 worker: Processes 1 job at a time
- 2 workers: Processes 2 jobs concurrently (queue moves faster)
- 3 workers: Processes 3 jobs concurrently (max for H100)

**Memory guidelines:**
- SDXL base model: ~6-8GB VRAM per worker
- With 3 workers: ~24GB VRAM used
- H100 has 80GB → plenty of headroom

---

## Monitoring & Maintenance

### Check Worker Health

```bash
# Container status
docker-compose ps

# Worker logs (last 50 lines)
docker-compose logs --tail=50 worker-1

# GPU utilization
nvidia-smi

# GPU usage history
nvidia-smi dmon -s u -c 10  # 10 seconds of utilization stats
```

### Check Network Connectivity

```bash
# Test Redis connection
docker exec comfy-worker-1 redis-cli -h comfy.ahelme.net -p 6379 -a "$REDIS_PASSWORD" ping

# Check DNS resolution
docker exec comfy-worker-1 nslookup comfy.ahelme.net

# Test HTTP to VPS
docker exec comfy-worker-1 curl -k https://comfy.ahelme.net/health
```

### Restart Worker

```bash
# Graceful restart
docker-compose restart worker-1

# Full restart (rebuild if code changed)
docker-compose down worker-1
docker-compose build worker-1
docker-compose up -d worker-1
```

### Update Models

```bash
# Add new model
cd ~/comfy-multi/data/models/checkpoints
wget -O new-model.safetensors <url>

# Worker will auto-detect on next restart
docker-compose restart worker-1
```

---

## Troubleshooting

### Issue: Worker can't connect to Redis

**Diagnosis:**
```bash
# Test from GPU instance
redis-cli -h comfy.ahelme.net -p 6379 -a "<password>" ping

# Check firewall on VPS
# (SSH to VPS)
sudo ufw status | grep 6379
```

**Solutions:**
- Verify Tailscale running on both instances: `tailscale status`
- Verify REDIS_HOST in .env uses Tailscale IP: `grep REDIS_HOST .env` (should be 100.99.216.71)
- Test connectivity: `redis-cli -h 100.99.216.71 -p 6379 -a '<password>' ping`
- Check REDIS_PASSWORD matches VPS

### Issue: Worker out of memory

**Diagnosis:**
```bash
# Check GPU memory
nvidia-smi

# Check worker logs
docker-compose logs worker-1 | grep -i "out of memory"
```

**Solutions:**
- Reduce NUM_WORKERS (try 1 instead of 3)
- Reduce WORKER_GPU_MEMORY_LIMIT in .env
- Use smaller models or reduce image resolution
- Check for memory leaks (restart worker)

### Issue: Job stuck processing

**Diagnosis:**
```bash
# Check worker logs
docker-compose logs worker-1

# Check if worker crashed
docker-compose ps worker-1
```

**Solutions:**
- Worker may have crashed: `docker-compose restart worker-1`
- Check job timeout settings in VPS .env
- Verify workflow is valid (test locally first)
- Check GPU is not hung: `nvidia-smi`

### Issue: Models not loading

**Diagnosis:**
```bash
# Check model paths
ls -la ~/comfy-multi/data/models/checkpoints/

# Check worker logs
docker-compose logs worker-1 | grep -i "model"

# Verify volume mounts
docker inspect comfy-worker-1 | grep -A 10 Mounts
```

**Solutions:**
- Verify models exist and have correct permissions
- Check model paths in docker-compose.yml volumes
- Re-download corrupted models
- Verify sufficient disk space: `df -h`

---

## Performance Optimization

### Recommended Settings for H100

**For video generation workshops (Wan 2.2, Mochi):**
```
NUM_WORKERS=1  # 1 worker for video (high VRAM per job)
WORKER_GPU_MEMORY_LIMIT=70G  # Leave headroom for spikes
```

**For image generation workshops (Flux.2, Z-Image, Juggernaut):**
```
NUM_WORKERS=2  # 2 workers for balanced throughput
WORKER_GPU_MEMORY_LIMIT=70G  # Leave headroom for spikes
```

**Expected throughput:**
- **Video (Wan 2.2, 5sec clip):** ~2-5 minutes per generation
- **Image (Flux.2, 1024x1024):** ~15-30 seconds per image
- **Image (Z-Image Turbo):** ~5-10 seconds per image (fast)
- **Image (Juggernaut XL, 30 steps):** ~10-15 seconds per image
- **20 users, 2 image workers:** Average queue wait ~2-5 minutes during peak
- **20 users, 1 video worker:** Average queue wait ~10-20 minutes during peak

### Tips for Faster Processing

1. **Pre-load models** - Keep workers running (models stay in VRAM)
2. **Use fast models** - Z-Image Turbo is much faster than Flux.2
3. **Optimize generation settings** - Lower steps/frames for faster results
4. **Batch similar jobs** - Group image generation requests when possible
5. **Add more workers** - Scale from 1 → 2 for image workshops (if H100 can handle it)
6. **Workshop scheduling** - Schedule video generation sessions separately from image sessions

---

## Scaling Guidelines

| Scenario | Workers | Expected Performance |
|----------|---------|---------------------|
| Development/Testing | 1 | One job at a time, good for debugging |
| Small Workshop (<10 users) | 1 | Adequate, ~2-3 min wait during peak |
| Medium Workshop (10-15 users) | 2 | Good, ~1-2 min wait during peak |
| Large Workshop (15-20 users) | 3 | Best, minimal wait during peak |

**GPU Instance Sizing:**
- **H100 80GB:** Can run 3 workers comfortably
- **A100 40GB:** Can run 2 workers
- **RTX 4090 24GB:** Limit to 1 worker

---

## Shutdown & Cleanup

**Stop workers:**
```bash
docker-compose down
```

**Preserve models (don't delete):**
```bash
# Models are in ./data/models - keep for next session
du -sh data/models/  # Check size
```

**Remove outputs (optional cleanup):**
```bash
# Outputs are on VPS, not GPU instance
# Safe to delete if needed on GPU instance
rm -rf data/outputs/*
```

**Full cleanup (including models):**
```bash
# WARNING: This deletes all models (15-20GB+ download to restore)
rm -rf data/models/*
rm -rf data/outputs/*
```

---

## Post-Deployment Checklist

After GPU worker is deployed:

- [ ] Worker connects to VPS Redis successfully
- [ ] Worker appears in admin dashboard as "idle"
- [ ] Test job submitted from user001 completes successfully
- [ ] Output appears in VPS user001 workspace
- [ ] GPU memory usage is reasonable (<70% of total)
- [ ] Worker logs show no errors
- [ ] Multiple jobs queue and process correctly
- [ ] Worker restarts automatically if crashed (restart policy)

---

## Next Steps

✅ **VPS (Tier 1) deployed**
✅ **GPU Worker (Tier 2) deployed**

**Ready for workshop:**
1. → Run load test: `./scripts/load-test.sh` (from VPS)
2. → Follow [Pre-Workshop Checklist](./docs/admin-checklist-pre-workshop.md)
3. → Test all 20 user workspaces
4. → Prepare example workflows
5. → Share participant URLs

---

## Quick Reference

**Start workers:**
```bash
docker-compose up -d
```

**Stop workers:**
```bash
docker-compose down
```

**View logs:**
```bash
docker-compose logs -f worker-1
```

**Check GPU:**
```bash
nvidia-smi
watch -n 1 nvidia-smi  # Live monitoring
```

**Test Redis connection:**
```bash
redis-cli -h comfy.ahelme.net -p 6379 -a "$REDIS_PASSWORD" ping
```

**Restart worker:**
```bash
docker-compose restart worker-1
```

---

**Related Documentation:**
- [VPS Deployment Guide](./implementation-deployment.md) - Tier 1 setup
- [Implementation Plan](./implementation.md) - Phase 8 deployment
- [Admin Troubleshooting](./docs/admin-troubleshooting.md)
- [Worker Connection Issues](./docs/admin-troubleshooting-worker-not-connecting.md)

---

**Last Updated:** 2026-01-10
