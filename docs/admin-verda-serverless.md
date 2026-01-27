**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-27
**Doc Updated:** 2026-01-27

---

# Admin Guide: Verda Serverless Containers

Complete guide for deploying and managing ComfyUI workers using Verda Serverless Containers for auto-scaling, pay-per-use inference.

---

## Overview

**Verda Serverless Containers** provide auto-scaling GPU compute that:
- **Scales to zero** when idle (no charges)
- **Auto-scales** based on queue depth (0-5 replicas)
- **Pays per use** in 10-minute billing intervals
- **Fast cold starts** with model caching on SFS

**vs. Dedicated GPU Instances:**
| Feature | Serverless Containers | GPU Instances |
|---------|----------------------|---------------|
| **Cost when idle** | $0 | Full hourly rate |
| **Scaling** | Automatic (0-5) | Manual |
| **Cold start** | ~30 seconds | N/A (always warm) |
| **Best for** | Variable workloads | Continuous use |
| **Billing** | Per-second, 10min min | Hourly |

---

## Architecture

```
┌─────────────────────────────────────────┐
│ Hetzner VPS (comfy.ahelme.net)          │
│  - Queue Manager (FastAPI)              │
│  - Redis (job queue)                    │
│  - 20 User Frontends                    │
└──────────────┬──────────────────────────┘
               │ HTTP REST API
┌──────────────▼──────────────────────────┐
│ Verda Serverless Container (Auto-scale) │
│  ┌───────────────────────────────────┐  │
│  │ Health Server (port 8000)         │  │
│  │  - /health endpoint               │  │
│  │  - Liveness probes                │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │ ComfyUI (port 8188)               │  │
│  │  - GPU inference                  │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │ Worker (Serverless Mode)          │  │
│  │  - Poll /api/workers/next-job     │  │
│  │  - Process 1 job                  │  │
│  │  - Exit after 10 idle polls       │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
         │
         │ Verda auto-scales containers
         │ based on queue depth
         ↓
┌─────────────────────────────────────────┐
│ SFS Network Storage                     │
│  - /models (45GB, cached models)        │
│  - /outputs (user generations)          │
└─────────────────────────────────────────┘
```

---

## Prerequisites

### 1. VPS Requirements
- Queue Manager running (`comfy.ahelme.net`)
- Redis accessible via Tailscale or public IP
- HTTPS enabled (for container→VPS communication)

### 2. Verda Account
- Account created: https://verda.com
- API key generated (Console → API Keys)
- SFS created and populated with models

### 3. Container Registry
- GitHub Container Registry (ghcr.io) recommended
- GitHub PAT with `write:packages` permission
- Or Docker Hub account

### 4. Local Tools
- Docker installed
- GitHub CLI (`gh`) for registry auth
- Python 3.10+ (for SDK deployment)

---

## Deployment Steps

### Step 1: Build Container Image

```bash
cd /home/dev/projects/comfyui

# Build serverless worker image
docker build -f comfyui-worker/Dockerfile.serverless \
  -t ghcr.io/ahelme/comfyui-worker-serverless:latest \
  comfyui-worker/
```

### Step 2: Push to Container Registry

**Option A: GitHub Container Registry (Recommended)**

```bash
# Authenticate with GitHub
echo $GITHUB_TOKEN | docker login ghcr.io -u ahelme --password-stdin

# Push image
docker push ghcr.io/ahelme/comfyui-worker-serverless:latest
```

**Option B: Docker Hub**

```bash
# Tag for Docker Hub
docker tag ghcr.io/ahelme/comfyui-worker-serverless:latest \
  ahelme/comfyui-worker-serverless:latest

# Push
docker push ahelme/comfyui-worker-serverless:latest
```

### Step 3: Deploy to Verda

**Option A: Automated Deployment Script**

```bash
cd /home/dev/projects/comfyui/verda

# Set environment variables
export VERDA_API_KEY="your-api-key"
export QUEUE_MANAGER_URL="https://comfy.ahelme.net"

# Run deployment script
./deploy-serverless.sh
```

**Option B: Manual via Verda Console**

1. Log in to Verda Console: https://verda.com/console
2. Navigate to: **Containers** → **Deploy New Container**
3. Configure container:
   - **Name:** `comfyui-worker-serverless`
   - **Image:** `ghcr.io/ahelme/comfyui-worker-serverless:latest`
   - **GPU:** H100 (1x)
   - **CPU:** 4 cores
   - **Memory:** 32GB
   - **Min replicas:** 0
   - **Max replicas:** 5

4. **Environment Variables:**
   ```
   QUEUE_MANAGER_URL=https://comfy.ahelme.net
   SERVERLESS_MODE=true
   SERVERLESS_MAX_IDLE_POLLS=10
   SERVERLESS_JOB_LIMIT=1
   INFERENCE_PROVIDER=verda-serverless
   HEALTH_PORT=8000
   ```

5. **Health Check:**
   - **Path:** `/health`
   - **Port:** 8000
   - **Interval:** 30s
   - **Initial delay:** 120s

6. **Volumes (SFS):**
   - **Models:** `/models` (read-only)
   - **Outputs:** `/outputs` (read-write)

7. Click **Deploy**

### Step 4: Verify Deployment

```bash
# Check container status in Verda Console
# Should show: "0 replicas running" when idle

# Submit test job
curl -X POST https://comfy.ahelme.net/api/queue/submit \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user001",
    "workflow": {...}
  }'

# Watch container scale up
# Verda Console should show: "1 replica running"

# After job completes and 10 idle polls
# Should scale back to: "0 replicas running"
```

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SERVERLESS_MODE` | `false` | Enable serverless behavior |
| `SERVERLESS_MAX_IDLE_POLLS` | `10` | Exit after N empty polls (×2s = 20s) |
| `SERVERLESS_JOB_LIMIT` | `0` | Max jobs before exit (0=unlimited) |
| `INFERENCE_PROVIDER` | `local` | Provider identifier (logging) |
| `HEALTH_PORT` | `8000` | Health endpoint port |
| `QUEUE_MANAGER_URL` | *required* | VPS endpoint URL |
| `WORKER_POLL_INTERVAL` | `2` | Seconds between job polls |

### Scaling Behavior

**Scale Up Triggers:**
- Queue depth > 0 and no running replicas
- Verda spawns new container (~30s cold start)
- Container polls queue, finds job, processes

**Scale Down Triggers:**
- Worker completes job
- Polls queue 10 times, no jobs found
- Worker exits gracefully
- Container terminates, Verda scales to zero

**Cost Example:**
- Container runs for 2 minutes processing job
- Billing: 10-minute minimum = $0.38 (H100 at $2.30/hr)
- Idle: $0
- 10 jobs/day = ~$4/day vs $55/day always-on instance

---

## Monitoring

### Verda Console

**Container Metrics:**
- Active replicas (0-5)
- Health check status
- Request count
- GPU utilization
- Cost per period

**Logs:**
- Container stdout/stderr
- Health check results
- Scale events

### Queue Manager Dashboard

Access: `https://comfy.ahelme.net/admin`

**Metrics:**
- Queue depth
- Active workers
- Job completion rate
- Average processing time

### Worker Logs

```bash
# View logs in Verda Console
# Or via CLI (if supported)
verda logs comfyui-worker-serverless --tail 100
```

**Look for:**
- "Worker started" - Container initialized
- "Processing job X" - Job accepted
- "Job X completed" - Success
- "Serverless idle timeout reached" - Scaling down
- "Worker shutdown complete" - Clean exit

---

## Troubleshooting

### Container Won't Start

**Symptom:** Health check fails, container restarts

**Diagnosis:**
```bash
# Check logs in Verda Console
# Look for errors in:
# 1. ComfyUI startup
# 2. Health server startup
# 3. Worker initialization
```

**Solutions:**
1. **ComfyUI not ready:** Increase `start_period` in health check to 180s
2. **Models missing:** Verify SFS mounted at `/models`
3. **Queue Manager unreachable:** Check `QUEUE_MANAGER_URL` is accessible from container

### Container Scales but No Jobs Processed

**Symptom:** Replica running but jobs stuck in queue

**Diagnosis:**
```bash
# Check worker logs for:
grep "Failed to get next job" logs.txt

# Test connectivity
docker run --rm curlimages/curl curl https://comfy.ahelme.net/api/workers/next-job?worker_id=test
```

**Solutions:**
1. **Queue Manager URL wrong:** Update `QUEUE_MANAGER_URL` environment variable
2. **Network firewall:** Ensure container can reach VPS (test with curl)
3. **Redis connection:** Check Queue Manager logs, verify Redis accessible

### Container Doesn't Scale Down

**Symptom:** Replica keeps running even with empty queue

**Diagnosis:**
- Check worker logs for idle poll count
- Verify `SERVERLESS_MAX_IDLE_POLLS` is set
- Ensure `SERVERLESS_MODE=true`

**Solutions:**
1. **Mode not enabled:** Set `SERVERLESS_MODE=true` in container config
2. **High poll limit:** Reduce `SERVERLESS_MAX_IDLE_POLLS` to 5
3. **Job stuck:** Cancel stuck job in Queue Manager dashboard

### High Costs Despite Low Usage

**Symptom:** Bill higher than expected

**Diagnosis:**
- Check average replica count in Verda Console
- Review scaling events and duration

**Solutions:**
1. **Not scaling to zero:** Fix container exit logic (check logs)
2. **Slow cold starts:** Pre-warm models on SFS (check they're cached)
3. **Job limit too high:** Set `SERVERLESS_JOB_LIMIT=1` for single-job containers
4. **Poll interval too long:** Increase idle polls but reduce `WORKER_POLL_INTERVAL`

---

## Best Practices

### Cost Optimization

**1. Single-Job Containers**
```bash
SERVERLESS_JOB_LIMIT=1  # Exit after 1 job
```
Fastest scale-down, lowest cost per job.

**2. Fast Idle Detection**
```bash
SERVERLESS_MAX_IDLE_POLLS=5  # 10 seconds idle timeout
```
Reduces wasted polling time.

**3. Model Caching**
- Keep all models on SFS (45GB)
- Cold start from SFS: ~30s
- Cold start from R2: ~20 minutes

**4. Batch Similar Jobs**
For workshop bursts:
```bash
SERVERLESS_JOB_LIMIT=5  # Process 5 jobs before exit
```
Amortizes cold start cost across multiple jobs.

### Performance Optimization

**1. Pre-warm Container**
Submit dummy job before workshop:
```bash
curl -X POST https://comfy.ahelme.net/api/queue/submit \
  -d '{"user_id":"warmup","workflow":{...}}'
```
First container starts, subsequent scale-ups are faster.

**2. Increase Max Replicas**
For large workshops:
```json
{
  "max_replicas": 10  // Up from 5
}
```
Handles larger queue bursts.

**3. Monitor Queue Depth**
Set alerts:
- Queue > 10: Consider increasing `max_replicas`
- Queue > 20: May need dedicated instance

### Reliability

**1. Health Check Tuning**
```json
{
  "initial_delay": 120,  // ComfyUI startup time
  "interval": 30,        // Frequent checks
  "timeout": 10,         // Allow slow responses
  "unhealthy_threshold": 3  // Tolerance for transient failures
}
```

**2. Graceful Shutdown**
Worker handles SIGTERM, ensures job completion before exit.

**3. Fallback to Instance**
Keep instance configuration ready:
```bash
# If serverless has issues
INFERENCE_PROVIDER=verda-instance
./scripts/start-verda-instance.sh
```

---

## Switching Between Modes

See: [Admin Guide: Provider Switching](./admin-provider-switching.md)

**Quick toggle:**
```bash
# Switch to serverless
INFERENCE_PROVIDER=verda-serverless

# Switch to instance
INFERENCE_PROVIDER=verda-instance
```

Both can coexist - serverless for variable load, instance for baseline.

---

## Related Documentation

- [Admin Guide: Verda Setup](./admin-verda-setup.md) - Instance deployment
- [Admin Guide: Provider Switching](./admin-provider-switching.md) - Mode toggling
- [Admin Guide: Backup & Restore](./admin-backup-restore.md) - Data management
- [Verda Serverless Containers Docs](https://docs.verda.com/containers/overview)

---

**Last Updated:** 2026-01-27
