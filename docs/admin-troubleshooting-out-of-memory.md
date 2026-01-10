**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-10

---

# Troubleshooting: Out of Memory (OOM) Errors

## Quick Diagnosis

GPU runs out of VRAM during job execution. This crashes jobs and leaves the GPU in an unusable state until the worker is restarted.

## Symptoms

- Worker crashes with CUDA out of memory error
- Jobs fail unexpectedly mid-execution
- `nvidia-smi` shows GPU memory at 99-100%
- Batch size errors in workflow logs
- Worker container exits suddenly

## Diagnosis Steps

```bash
# 1. Check current GPU memory usage
nvidia-smi

# 2. Check worker memory limit configuration
docker inspect comfy-worker-1 | grep -i memory

# 3. Check worker logs for CUDA errors
docker-compose logs worker-1 | grep -i "cuda\|memory\|oom"

# 4. Monitor GPU memory in real-time
watch -n 1 nvidia-smi

# 5. Check what process is using GPU
nvidia-smi process-list
```

## Solutions (Try in Order)

### Solution 1: Reduce Workflow Batch Size

Smaller batches use less VRAM. This is the quickest fix.

**In the workflow JSON:**

```json
{
  "1": {
    "class_type": "KSampler",
    "inputs": {
      "steps": 20,
      "cfg": 7.5,
      "batch_size": 1  // Reduce from 4 or 8 to 1
    }
  }
}
```

Typical VRAM usage for SDXL:
- Batch size 1: ~22GB
- Batch size 2: ~28GB
- Batch size 4: ~40GB
- Batch size 8: ~60GB+

### Solution 2: Use Smaller Models

Switch to models that use less VRAM:

```
Instead of:           Use:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SDXL Base            → Stable Diffusion 1.5 (4GB VRAM)
SDXL + Refiner       → SDXL Base only (no refiner)
Higher resolution    → Lower resolution (512x512 instead of 1024x1024)
Multiple refiner passes → Single pass
```

### Solution 3: Clear GPU Cache

Restart the worker to free any cached data.

```bash
# Stop all jobs first (optional but recommended)
# Then:
docker-compose restart worker-1
```

Wait 30 seconds for worker to restart, then:
```bash
nvidia-smi  # Should show GPU memory returned to baseline
```

### Solution 4: Increase GPU Memory Limit (if available)

Only if you have unused VRAM above 80GB on the GPU.

In `.env`:
```env
WORKER_GPU_MEMORY_LIMIT=75G  # Increase from 70G
```

Then restart:
```bash
docker-compose restart worker-1
```

**Note:** H100 has 80GB total. Leave ~5GB for system.

### Solution 5: Enable Memory Optimization

ComfyUI has several memory optimization techniques. Add to docker-compose.yml worker environment:

```yaml
worker-1:
  environment:
    # Enable memory optimization
    PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb=512
    # Use lower precision
    ENABLE_FP16=true
    # Clear cache between jobs
    CLEAR_VRAM_AFTER_JOB=true
```

Then restart:
```bash
docker-compose down
docker-compose up -d worker-1
```

### Solution 6: Add Second Worker (Distribute Load)

If you have 2+ GPUs or enough VRAM for 2 workers:

```yaml
# In docker-compose.yml, duplicate worker-1 as worker-2
worker-2:
  image: comfyui:latest
  environment:
    REDIS_HOST: redis
    REDIS_PORT: 6379
    REDIS_PASSWORD: $REDIS_PASSWORD
    WORKER_ID: worker-2
  # Same GPU allocation as worker-1
  volumes:
    - ./data/models:/models/shared
    - ./data/outputs:/outputs
```

Start it:
```bash
docker-compose up -d worker-2
```

Verify both workers connected:
```bash
docker-compose logs | grep "Worker.*connected"
```

## GPU Memory Reference

**H100 80GB breakdown:**
- ComfyUI base: ~2GB
- Model loading: Varies
- Working memory: ~3-5GB
- Safe max allocation: 70-75GB

**SDXL with typical workflow:**
- Base model: ~14GB
- Refiner model: ~12GB
- Working space: ~5GB
- **Total: ~31GB with batch size 1**

**SDXL at higher batch sizes:**
- Batch 2: +4-6GB
- Batch 4: +8-12GB
- Batch 8: +16-24GB

## Monitoring During Workshop

### GPU Memory Dashboard

```bash
#!/bin/bash
# Run this in a terminal to monitor GPU in real-time

watch -n 1 'echo "=== GPU Status ===" && \
nvidia-smi --query-gpu=name,driver_version,memory.total,memory.free,memory.used \
  --format=csv,noheader && \
echo "" && \
echo "=== Processes ===" && \
nvidia-smi pids=$(nvidia-smi --query-compute-apps=pid,process_name,gpu_memory_usage --format=csv,noheader)'
```

### Alert Thresholds

Monitor and alert on these conditions:

```
GPU Memory Usage:
- < 50% = Normal
- 50-70% = Monitor
- 70-85% = Warning (cancel lowest priority job)
- > 85% = Critical (restart worker immediately)
```

## Prevention Tips

1. **Set reasonable defaults** in example workflows:
   - Batch size: 1
   - Steps: 20-30 (not 50+)
   - Resolution: 768x768 or lower

2. **Document model VRAM requirements** for participants:
   ```
   SDXL Base: 14GB minimum, 20GB recommended
   SD 1.5: 4GB minimum, 8GB recommended
   ```

3. **Monitor queue submission patterns**:
   - If many high batch size jobs queued, warn participants
   - Cancel jobs consuming > 70GB

4. **Pre-allocate memory at startup**:
   ```bash
   # In worker startup script
   # Load model to memory before workshop starts
   ```

## Troubleshooting Memory Leaks

If memory usage grows over time without proper cleanup:

```bash
# Check for memory leaks in worker
docker stats comfy-worker-1 --no-stream

# If memory keeps growing, restart worker regularly
# Add to cron (run every 2 hours during workshop)
*/120 * * * * docker-compose restart worker-1
```

## Related Issues

- **Queue not processing** → Usually caused by OOM crashes, see admin-troubleshooting-queue-stopped.md
- **Slow performance** → May be related to GPU memory pressure, see admin-troubleshooting.md
- **Worker won't start** → May be memory allocation issue, see admin-troubleshooting-docker-issues.md
