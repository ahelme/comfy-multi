**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-12
**Doc Updated:** 2026-01-12

---

# CPU Testing Guide - Develop Workflows for FREE

How to develop and test ComfyUI workflows on CPU before deploying to expensive GPU instances.

**Cost:** $0 (completely free!)
**Use case:** Workflow development, queue testing, API validation

---

## Why Test on CPU First?

### Cost Savings
- **GPU (H100):** $3.50-5.00/hour
- **GPU (RTX 3090):** $0.20-0.40/hour
- **CPU:** $0 (FREE!)

**Example savings:**
- 10 hours workflow development on H100: **$35-50**
- 10 hours workflow development on CPU: **$0**
- **Savings: $35-50** 💰

### What You Can Test on CPU

✅ **Works great:**
- Workflow logic and node connections
- API endpoints and job submission
- Queue management system
- User authentication
- Output file handling
- Error handling
- Webhook notifications
- Job scheduling algorithms

❌ **Doesn't work (needs GPU):**
- Actual image/video generation
- Model loading
- CUDA operations
- Performance benchmarking

**Strategy:** Develop everything on CPU, then deploy to GPU ONLY for final renders!

---

## Option 1: Local Development (Your Laptop/Desktop)

### Setup (5 minutes)

```bash
# Install ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git
cd ComfyUI

# Install dependencies
pip install -r requirements.txt

# Start ComfyUI (CPU mode)
python main.py --cpu --listen 0.0.0.0 --port 8188
```

**Access:** http://localhost:8188

### Test Workflow Creation

1. **Create workflow in UI** (drag nodes, connect them)
2. **Export workflow** (Save button → Download as JSON)
3. **Test API submission:**

```bash
curl -X POST http://localhost:8188/prompt \
  -H "Content-Type: application/json" \
  -d @your-workflow.json
```

4. **Verify:**
   - ✅ API accepts workflow
   - ✅ Job queues correctly
   - ✅ Error messages are clear
   - ✅ Output paths work

**No GPU needed!** You're just testing the plumbing.

---

## Option 2: Test on Hetzner VPS (Already Paid For!)

Your VPS (mello) is already running - use it for CPU testing!

### Setup on VPS

```bash
# On VPS mello
cd ~
git clone https://github.com/comfyanonymous/ComfyUI.git comfyui-cpu-test
cd comfyui-cpu-test

# Install in virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Start on different port (don't conflict with production)
python main.py --cpu --listen 0.0.0.0 --port 9999
```

**Access via SSH tunnel:**
```bash
# From your laptop
ssh -L 9999:localhost:9999 dev@mello

# Then open: http://localhost:9999
```

### Test Integration with Queue

```bash
# On VPS, test queue submission
cd ~/projects/comfyui

# Submit test job via queue manager API
curl -X POST https://comfy.ahelme.net/api/queue/submit \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test-user",
    "workflow": {...},
    "priority": "normal"
  }'
```

Validates:
- ✅ Queue manager accepts jobs
- ✅ Redis connection works
- ✅ Job metadata stored correctly
- ✅ Queue depth tracking

**Still $0 cost!** No GPU used.

---

## Option 3: Mock GPU Worker (Simulate Processing)

Create a fake worker that pretends to process jobs - great for load testing!

### Create Mock Worker Script

```bash
# On VPS
cat > ~/mock-gpu-worker.py << 'EOF'
#!/usr/bin/env python3
"""
Mock GPU Worker - Simulates job processing without GPU
Connects to real Redis queue, pretends to render
"""

import redis
import json
import time
import random
from datetime import datetime

# Connect to Redis
r = redis.Redis(
    host='localhost',
    port=6379,
    password='your-redis-password',
    decode_responses=True
)

print("🎭 Mock GPU Worker Started")
print("   (Simulating job processing without GPU)")

while True:
    # Check for jobs
    job = r.blpop('comfy:job:queue', timeout=5)

    if job:
        job_data = json.loads(job[1])
        job_id = job_data['job_id']
        user_id = job_data['user_id']

        print(f"\n📥 Received job: {job_id} (user: {user_id})")

        # Simulate processing
        processing_time = random.uniform(30, 90)  # 30-90 seconds
        print(f"   Processing for {processing_time:.1f}s...")

        # Update status to processing
        r.hset(f'comfy:job:{job_id}', 'status', 'processing')
        r.hset(f'comfy:job:{job_id}', 'started_at', datetime.now().isoformat())

        # Sleep to simulate work
        time.sleep(processing_time)

        # Mark as complete
        r.hset(f'comfy:job:{job_id}', 'status', 'completed')
        r.hset(f'comfy:job:{job_id}', 'completed_at', datetime.now().isoformat())
        r.hset(f'comfy:job:{job_id}', 'output', f'/outputs/{user_id}/{job_id}.mp4')

        print(f"   ✅ Job {job_id} complete!")
    else:
        print(".", end="", flush=True)
EOF

chmod +x ~/mock-gpu-worker.py
```

### Run Mock Worker

```bash
python3 ~/mock-gpu-worker.py
```

### Load Test with Mock Worker

```bash
# Submit 100 jobs
for i in {1..100}; do
    curl -X POST https://comfy.ahelme.net/api/queue/submit \
      -H "Content-Type: application/json" \
      -d "{
        \"user_id\": \"user$(printf %03d $i)\",
        \"workflow\": {},
        \"priority\": \"normal\"
      }"
done

# Watch mock worker process them all
# Still $0 cost!
```

Validates:
- ✅ Queue handles 100+ jobs
- ✅ Jobs processed in order (FIFO)
- ✅ Status updates work
- ✅ Multiple workers can run (start 3 mock workers!)
- ✅ Admin dashboard shows correct metrics

**Zero GPU cost!** You're testing the entire system for free.

---

## Option 4: Docker CPU Worker

Test your actual worker Docker image in CPU mode:

```bash
# On VPS or laptop
cd ~/projects/comfyui

# Build worker image
docker build -t comfy-worker-cpu comfyui-worker/

# Run in CPU mode (no --gpus flag)
docker run -it --rm \
  -e REDIS_HOST=localhost \
  -e REDIS_PORT=6379 \
  -e REDIS_PASSWORD=your-password \
  -e CUDA_VISIBLE_DEVICES="" \
  -v $PWD/data:/workspace/ComfyUI/output \
  comfy-worker-cpu \
  python main.py --cpu
```

Validates:
- ✅ Worker Docker image builds correctly
- ✅ Environment variables work
- ✅ Volume mounts correct
- ✅ Redis connectivity from container

**Still free!** No GPU used in container.

---

## Workflow Development Best Practices

### 1. Start Simple, Add Complexity

```
Iteration 1: Basic workflow (1 node)
↓ Test on CPU
Iteration 2: Add text prompt
↓ Test on CPU
Iteration 3: Add LoRA
↓ Test on CPU
Iteration 4: Add upscaler
↓ NOW deploy to GPU for first test render
```

**Cost:** 10 hours CPU dev ($0) + 30 min GPU test ($2.50) = **$2.50 total**

vs.

**Alternate:** 10.5 hours on GPU = **$52.50**

**Savings: $50!**

### 2. Use Workflow Templates

Create tested workflow templates on CPU:
- `template-basic-video.json` (simple LTX-2 workflow)
- `template-upscaled-video.json` (with upscaler)
- `template-camera-control.json` (with camera LoRA)

Test all templates on CPU, then users just customize prompts on GPU.

### 3. Validate Before GPU Deploy

**Pre-GPU checklist:**
```bash
✅ Workflow loads without errors
✅ All nodes connect correctly
✅ Input parameters are valid
✅ Output paths exist
✅ API submission works
✅ Error messages are helpful
```

Only THEN deploy to GPU.

---

## Budget Workshop Strategy

### Phase 1: Pre-Workshop (1 week before)
**Location:** Your laptop/VPS (CPU only)
**Cost:** $0

- Create 5-10 example workflows
- Test queue system
- Validate user authentication
- Load test with mock workers
- Fix any bugs

### Phase 2: GPU Validation (1 day before)
**Location:** Cheap GPU (Vast.ai RTX 3090 @ $0.30/hr)
**Cost:** 3 hours × $0.30 = **$0.90**

- Test 1-2 workflows end-to-end
- Verify LTX-2 models work
- Time actual generation (estimate queue times)
- Verify outputs look good

### Phase 3: Workshop Day
**Location:** H100 (if needed) or 3× RTX 3090
**Cost:**

**Option A - Single H100:**
- 8 hours × $4/hr = **$32**
- Trade-off: Users wait in queue

**Option B - Triple RTX 3090:**
- 8 hours × 3 × $0.30/hr = **$7.20**
- Benefit: 3× throughput

**Total workshop cost:** $0.90 + $7.20 = **$8.10 USD**

Compare to: Running H100 for 1 week of dev + workshop = **$800+**

**You saved $790+** by doing CPU development! 🎉

---

## Real Example: My Workflow

```
Sunday: 5 hours workflow dev on laptop (CPU)
  Cost: $0

Monday: 2 hours integration testing on VPS (CPU)
  Cost: $0

Tuesday: 30 min GPU validation on Vast.ai RTX 3090
  Cost: $0.15

Wednesday: Load testing with mock workers (CPU)
  Cost: $0

Thursday: 1 hour GPU testing on Vast.ai RTX 3090
  Cost: $0.30

Friday (Workshop): 8 hours with 3× RTX 3090
  Cost: $7.20

TOTAL: $7.65

vs. doing everything on H100: $70+ per day = $350+

SAVED: $342.35 🎉
```

---

## CPU Testing Checklist

Before deploying to GPU, verify:

**System Tests:**
- [ ] ComfyUI starts in CPU mode
- [ ] API accepts workflow JSON
- [ ] Queue manager receives jobs
- [ ] Redis connection stable
- [ ] Jobs stored correctly
- [ ] Status updates propagate
- [ ] Admin dashboard shows metrics

**Workflow Tests:**
- [ ] All nodes load without errors
- [ ] Connections valid
- [ ] Parameters in valid ranges
- [ ] Output paths configured
- [ ] Error messages helpful

**Integration Tests:**
- [ ] Multiple users can submit jobs
- [ ] Jobs queue in correct order
- [ ] Worker picks up jobs
- [ ] Outputs save to correct location
- [ ] Failed jobs handled gracefully

**Only THEN deploy to GPU!**

---

## Troubleshooting CPU Testing

### "ModuleNotFoundError: No module named 'torch'"

```bash
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
```

### "CUDA out of memory"

You're not in CPU mode! Add --cpu flag:
```bash
python main.py --cpu
```

### ComfyUI won't start

Check port not in use:
```bash
netstat -tuln | grep 8188
```

Use different port:
```bash
python main.py --cpu --port 9999
```

### Workflow fails with "Model not found"

That's fine! You're testing workflow structure, not actually generating.
The error proves your error handling works!

---

## Next Steps

1. **[← Back to Admin Guide](./admin-guide.md)**
2. **[Budget GPU Options →](./admin-gpu-environment-backup.md)**
3. **[Scripts Reference →](./admin-scripts.md)**

---

**Last Updated:** 2026-01-12
