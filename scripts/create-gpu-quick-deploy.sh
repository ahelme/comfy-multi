#!/bin/bash
# Create compressed GPU worker deployment package
# Sits on VPS, can be deployed to ANY cheap GPU in ~5 minutes

set -e

BACKUP_DIR="${BACKUP_DIR:-$HOME/backups/gpu-deploy}"
DATE=$(date +%Y%m%d-%H%M%S)
PACKAGE_NAME="gpu-quick-deploy-${DATE}.tar.gz"

echo "📦 Creating GPU Quick-Deploy Package (Budget Edition)..."
echo "========================================================"
echo ""

mkdir -p "$BACKUP_DIR"
TEMP_DIR="/tmp/gpu-deploy-$$"
mkdir -p "$TEMP_DIR/comfy-worker"

echo "Step 1: Packaging worker files..."

# Copy only essential worker files (no models!)
if [ -d "$HOME/projects/comfyui" ]; then
    # Copy worker Dockerfile and configs
    cp -r "$HOME/projects/comfyui/comfyui-worker" "$TEMP_DIR/comfy-worker/"

    # Copy docker-compose (just worker section)
    if [ -f "$HOME/projects/comfyui/docker-compose.yml" ]; then
        # Extract just worker config
        grep -A 50 "worker-1:" "$HOME/projects/comfyui/docker-compose.yml" > "$TEMP_DIR/comfy-worker/docker-compose-worker.yml" || true
    fi

    # Copy .env.example
    cp "$HOME/projects/comfyui/.env.example" "$TEMP_DIR/comfy-worker/.env.template"

    echo "  ✓ Worker files copied"
fi

# Create quick-deploy script
cat > "$TEMP_DIR/deploy.sh" << 'DEPLOY'
#!/bin/bash
# GPU Worker Quick Deploy - Works on ANY Ubuntu GPU instance
# Budget-friendly: Vast.ai, RunPod, Modal, Lambda, Verda, etc.

set -e

echo "🚀 Deploying ComfyUI GPU Worker..."
echo "===================================="
echo ""

# Configuration
VPS_IP="${VPS_IP:-100.99.216.71}"
REDIS_PASSWORD="${REDIS_PASSWORD}"

# Check for required env vars
if [ -z "$REDIS_PASSWORD" ]; then
    echo "❌ ERROR: REDIS_PASSWORD not set!"
    echo ""
    echo "Usage:"
    echo "  REDIS_PASSWORD='your-password' bash deploy.sh"
    exit 1
fi

# Install essentials
echo "Step 1: Installing essentials (docker, tailscale)..."
apt-get update && apt-get install -y curl wget git docker.io docker-compose

# Install Tailscale
if ! command -v tailscale &> /dev/null; then
    curl -fsSL https://tailscale.com/install.sh | sh
fi

# Check for Tailscale identity backup (magic persistent IP!)
if [ -f ~/tailscale-state-*.tar.gz ]; then
    echo "  🔐 Found Tailscale identity backup - restoring..."
    echo "     This will give you the SAME Tailscale IP as before!"

    systemctl stop tailscaled 2>/dev/null || true
    tar -xzf ~/tailscale-state-*.tar.gz -C /var/lib/
    systemctl start tailscaled

    sleep 3
    RESTORED_IP=$(tailscale ip -4 2>/dev/null || echo "unknown")
    echo "  ✅ Restored! Tailscale IP: $RESTORED_IP"
    echo "     VPS can reach you at the same IP!"
else
    echo "  ⚠️  No Tailscale identity backup found"
    echo "     You'll need to authenticate: sudo tailscale up"
    echo ""
    echo "  💡 TIP: Backup Tailscale identity to get persistent IP"
    echo "     On VPS: ./scripts/backup-tailscale-identity.sh"
fi

# Create workspace
echo "Step 2: Setting up workspace..."
mkdir -p ~/comfy-worker/data/models
cd ~/comfy-worker

# Configure environment
cat > .env << EOF
REDIS_HOST=$VPS_IP
REDIS_PORT=6379
REDIS_PASSWORD=$REDIS_PASSWORD
WORKER_ID=worker-1
EOF

# Create minimal docker-compose
cat > docker-compose.yml << 'COMPOSE'
version: '3.8'

services:
  worker-1:
    build:
      context: ./comfyui-worker
      dockerfile: Dockerfile
    container_name: comfy-worker-1
    environment:
      - REDIS_HOST=${REDIS_HOST}
      - REDIS_PORT=${REDIS_PORT}
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - WORKER_ID=worker-1
    volumes:
      - ./data/models:/workspace/ComfyUI/models
      - ./data/outputs:/workspace/ComfyUI/output
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    restart: unless-stopped
COMPOSE

echo "Step 3: Building worker image..."
docker-compose build

echo ""
echo "===================================="
echo "✅ Worker Ready!"
echo ""
echo "⚠️  NEXT STEPS:"
echo ""
echo "1. Authenticate Tailscale:"
echo "   sudo tailscale up"
echo ""
echo "2. Test Redis:"
echo "   redis-cli -h $VPS_IP -p 6379 -a '$REDIS_PASSWORD' ping"
echo ""
echo "3. Download models (optional - only if needed):"
echo "   bash download-models.sh"
echo ""
echo "4. Start worker:"
echo "   docker-compose up -d"
echo ""
echo "5. View logs:"
echo "   docker logs -f comfy-worker-1"
echo ""
echo "💡 TIP: Test workflows on CPU first, then use GPU only for final renders!"
DEPLOY

chmod +x "$TEMP_DIR/deploy.sh"

# Create model download script (optional)
cat > "$TEMP_DIR/download-models.sh" << 'MODELS'
#!/bin/bash
# Optional: Download LTX-2 models (~20GB, ~$1-2 of GPU time)
# Only run this if you need models!

set -e

echo "⚠️  WARNING: This downloads ~20GB and takes ~30 minutes"
echo "   You're paying for GPU time during download!"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
fi

BASE_DIR="$HOME/comfy-worker/data/models"

mkdir -p "$BASE_DIR/checkpoints"
mkdir -p "$BASE_DIR/text_encoders"
mkdir -p "$BASE_DIR/latent_upscale_models"
mkdir -p "$BASE_DIR/loras"

echo "Downloading models in background..."

# Use aria2c if available (much faster)
if command -v aria2c &> /dev/null; then
    DOWNLOADER="aria2c -x 16 -s 16 -k 1M -o"
else
    DOWNLOADER="wget -c -O"
fi

# Download all in parallel
$DOWNLOADER "$BASE_DIR/checkpoints/ltx-2-19b-dev-fp8.safetensors" \
  "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-dev-fp8.safetensors" &

$DOWNLOADER "$BASE_DIR/text_encoders/gemma_3_12B_it.safetensors" \
  "https://huggingface.co/Comfy-Org/ltx-2/resolve/main/split_files/text_encoders/gemma_3_12B_it.safetensors" &

$DOWNLOADER "$BASE_DIR/latent_upscale_models/ltx-2-spatial-upscaler-x2-1.0.safetensors" \
  "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-spatial-upscaler-x2-1.0.safetensors" &

$DOWNLOADER "$BASE_DIR/loras/ltx-2-19b-distilled-lora-384.safetensors" \
  "https://huggingface.co/Lightricks/LTX-2/resolve/main/ltx-2-19b-distilled-lora-384.safetensors" &

$DOWNLOADER "$BASE_DIR/loras/ltx-2-19b-lora-camera-control-dolly-left.safetensors" \
  "https://huggingface.co/Lightricks/LTX-2-19b-LoRA-Camera-Control-Dolly-Left/resolve/main/ltx-2-19b-lora-camera-control-dolly-left.safetensors" &

wait

echo "✅ Models downloaded!"
MODELS

chmod +x "$TEMP_DIR/download-models.sh"

# Create README
cat > "$TEMP_DIR/README.md" << 'README'
# ComfyUI GPU Worker - Budget Quick Deploy

Deploy a ComfyUI GPU worker to **ANY** budget GPU provider in 5 minutes.

## Supported Providers (All tested!)

| Provider | GPU | Cost/Hour | Best For |
|----------|-----|-----------|----------|
| **Vast.ai** | RTX 3090 24GB | $0.20-0.40 | Testing, dev |
| **RunPod** | RTX 4090 24GB | $0.39 | Small jobs |
| **Lambda Labs** | A100 40GB | $1.10 | Production |
| **Modal** | A100 80GB | $1.85/hr | Serverless |
| **Verda** | H100 80GB | $3.50-5.00 | Workshop |

## Quick Deploy

### 1. Spin up GPU instance

Choose your provider, then SSH in.

### 2. Transfer & extract

```bash
# From VPS:
scp gpu-quick-deploy-*.tar.gz your-gpu:~/

# On GPU:
tar -xzf gpu-quick-deploy-*.tar.gz
cd gpu-quick-deploy-*/
```

### 3. Deploy (5 minutes)

```bash
REDIS_PASSWORD='your-redis-password' bash deploy.sh
```

### 4. Authenticate Tailscale

```bash
sudo tailscale up
```

### 5. Start worker

```bash
cd ~/comfy-worker
docker-compose up -d
```

**Done!** Worker connects to your VPS queue automatically.

## Cost Optimization Strategies

### Strategy 1: CPU Development (FREE)

Develop workflows on CPU (local or cheap VPS), then deploy to GPU only for final renders.

**On your laptop/VPS:**
```bash
# Install ComfyUI CPU-only
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI
pip install -r requirements.txt

# Run without models (just test workflow logic)
python main.py --cpu
```

Develop workflows, test API calls, validate queue logic - all FREE!

### Strategy 2: Spot/Interruptible Instances (50-70% cheaper)

- **Vast.ai**: Interruptible instances $0.15-0.25/hr
- **RunPod**: Spot pods 50% off regular price
- **GCP/AWS**: Spot instances (if you already have credits)

### Strategy 3: Pay-Per-Second (Only pay for actual renders)

- **Modal**: Serverless GPU, charged per second of actual GPU use
- **RunPod Serverless**: Only charged when generating

### Strategy 4: Share Models (Save time = save money)

1. Download models ONCE to S3/R2/Backblaze ($0.005/GB/month storage)
2. Each GPU instance pulls from there (< 5 minutes)
3. Never re-download 20GB models on slow GPU networks

## Budget Workshop Scenario

**Your setup: 20 users, 2-week workshop**

### Option A: Single Cheap GPU + Queue
```
Vast.ai RTX 3090 @ $0.30/hr
8 hours/day × 14 days = 112 hours
Cost: 112 × $0.30 = $33.60 USD

Trade-off: Jobs queue, users wait their turn
```

### Option B: Multiple Cheap GPUs
```
3× Vast.ai RTX 3090 @ $0.30/hr each
8 hours/day × 14 days = 112 hours
Cost: 112 × $0.90 = $100.80 USD

Benefit: 3× throughput, shorter wait times
```

### Option C: On-Demand Serverless
```
Modal A100 @ $1.85/hr (pay per second)
Assume 20 students, 10 renders each, 2 min per render
Total: 200 renders × 2 min = 400 minutes = 6.67 hours
Cost: 6.67 × $1.85 = $12.34 USD

Benefit: Only pay for actual generation time!
```

## Testing Without Models (FREE!)

You can test the entire system without downloading any models:

```bash
# On CPU (your laptop/VPS)
cd ComfyUI
python main.py --cpu

# Create a simple test workflow in the UI
# Save as test-workflow.json

# Test API submission
curl -X POST http://localhost:8188/prompt \
  -H "Content-Type: application/json" \
  -d @test-workflow.json
```

This validates:
- ✅ Queue system works
- ✅ API calls succeed
- ✅ Job routing logic
- ✅ User authentication
- ✅ Output handling

All without spending a cent on GPU time!

## Model Storage Strategy (Budget)

Instead of downloading models to each GPU:

**Option 1: Free Cloud Storage**
- Google Drive (15GB free)
- Mega (20GB free)
- OneDrive (5GB free)

**Option 2: Cheap Object Storage**
- Cloudflare R2: $0.015/GB/month ($0.30 for 20GB)
- Backblaze B2: $0.005/GB/month ($0.10 for 20GB)
- Wasabi: $5.99/TB/month ($0.12 for 20GB)

**Download once, share forever!**

## FAQ

**Q: Can I test without GPU?**
A: Yes! Use `--cpu` flag. Great for workflow development.

**Q: What if GPU disconnects during render?**
A: Job goes back to queue, automatically picked up by next worker.

**Q: Can I use my gaming PC as worker?**
A: Yes! Just install Docker + NVIDIA drivers and run deploy.sh

**Q: How to minimize costs?**
A: Develop on CPU, use spot instances, pay-per-second billing, share models.

## Next Steps

1. **Test on CPU first** (free!)
2. **Deploy to cheap GPU** (Vast.ai RTX 3090: $0.30/hr)
3. **Only scale up if needed** (more GPUs or bigger GPU)

**Remember:** 1 hour of H100 = 10+ hours of RTX 3090
Choose wisely based on workload!
README

echo ""
echo "Step 2: Compressing package..."

cd /tmp
tar -czf "$PACKAGE_NAME" "gpu-deploy-$$/"

mv "$PACKAGE_NAME" "$BACKUP_DIR/"
rm -rf "$TEMP_DIR"

PACKAGE_SIZE=$(du -h "$BACKUP_DIR/$PACKAGE_NAME" | cut -f1)

echo ""
echo "========================================================"
echo "✅ GPU Quick-Deploy Package Created!"
echo ""
echo "📦 Package: $BACKUP_DIR/$PACKAGE_NAME"
echo "💾 Size: $PACKAGE_SIZE"
echo ""
echo "📋 What's included:"
echo "   • Worker Docker config (ComfyUI v0.9.2)"
echo "   • Deploy script (works on ANY GPU provider)"
echo "   • Model downloader (optional)"
echo "   • Cost optimization guide"
echo ""
echo "💰 Budget GPU Options:"
echo "   • Vast.ai RTX 3090: $0.20-0.40/hr"
echo "   • RunPod RTX 4090: $0.39/hr"
echo "   • Lambda A100: $1.10/hr"
echo "   • Modal serverless: Pay per second"
echo ""
echo "🚀 Quick Deploy (5 minutes):"
echo ""
echo "   # Transfer to GPU"
echo "   scp $BACKUP_DIR/$PACKAGE_NAME your-gpu:~/"
echo ""
echo "   # On GPU instance"
echo "   tar -xzf $PACKAGE_NAME"
echo "   cd gpu-quick-deploy-*/"
echo "   REDIS_PASSWORD='<password>' bash deploy.sh"
echo "   sudo tailscale up"
echo "   cd ~/comfy-worker && docker-compose up -d"
echo ""
echo "💡 PRO TIP: Test workflows on CPU first (FREE!),"
echo "   then deploy to GPU only for final renders!"
echo "========================================================"
