**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-27
**Doc Updated:** 2026-01-27

---

# Admin Guide: Switching Inference Providers

Guide for switching between different inference providers (Verda instances, Verda serverless, local GPU) without conflicts.

---

## Supported Providers

| Provider | Mode | Best For | Cost Model |
|----------|------|----------|------------|
| `verda-instance` | Dedicated GPU | Continuous load, predictable cost | Hourly |
| `verda-serverless` | Auto-scaling containers | Variable load, workshops | Per-second |
| `local` | Local GPU | Development, testing | Hardware cost |

---

## Quick Switch

### Method 1: Environment Variable

**In `.env` file:**
```bash
# Current mode
INFERENCE_PROVIDER=verda-instance

# Switch to serverless
INFERENCE_PROVIDER=verda-serverless

# Switch to local
INFERENCE_PROVIDER=local
```

**No code changes required** - value used for logging and identification only.

### Method 2: Deploy Different Worker

**Verda Instance Mode:**
```bash
# On Verda GPU instance
cd ~/comfy-multi
docker compose up -d worker-1
```

**Serverless Mode:**
```bash
# Deploy to Verda Serverless Containers
cd /home/dev/projects/comfyui/verda
./deploy-serverless.sh
```

**Local Mode:**
```bash
# On dev machine with GPU
cd /home/dev/projects/comfyui
docker compose up -d worker-1
```

---

## No Conflicts Between Modes

**Key Design Principle:** All workers use the same REST API pattern.

```
All Workers → Poll /api/workers/next-job → Queue Manager
```

**This means:**
- ✅ Instance and serverless can run simultaneously
- ✅ Workers identified by `WORKER_ID`, not provider type
- ✅ Queue Manager treats all workers identically
- ✅ No configuration changes needed on VPS

**Example:** Run 1 instance (baseline) + serverless (bursts)
- Instance worker: Always running, handles steady load
- Serverless workers: Auto-scale for queue bursts
- Both poll same queue, no conflicts

---

## Comparison

### Verda Instance Mode

**Architecture:**
```
Dedicated H100 GPU Instance (Verda)
  ├─ Always running (manual start/stop)
  ├─ Worker polls queue forever
  ├─ Predictable performance
  └─ Fixed hourly cost

Billing: $2.30/hr × 24hr = $55/day
```

**Pros:**
- No cold start delay
- Consistent performance
- Simpler to manage
- Good for continuous use

**Cons:**
- Costs accumulate when idle
- Manual scaling (add more instances)
- Must remember to shut down

**Best for:**
- Multi-day workshops
- Continuous production workload
- When queue always has jobs

### Verda Serverless Mode

**Architecture:**
```
Auto-scaling Containers (0-5 replicas)
  ├─ Scale to zero when idle
  ├─ Worker exits after idle timeout
  ├─ ~30s cold start with SFS
  └─ Per-second billing

Billing: 10-min minimum × actual runtime
```

**Pros:**
- $0 when idle
- Auto-scales with queue depth
- No manual management
- Cost-effective for bursts

**Cons:**
- Cold start delay (~30s)
- 10-minute billing minimum
- More complex monitoring

**Best for:**
- Single-day workshops
- Variable workload
- Want automatic scale-to-zero

### Local GPU Mode

**Architecture:**
```
Development Machine with GPU
  ├─ Worker on localhost
  ├─ Queue Manager on VPS
  ├─ Connect via Tailscale VPN
  └─ Free compute (hardware cost)
```

**Pros:**
- No cloud costs
- Full control
- Instant iteration

**Cons:**
- Limited to single GPU
- Requires local GPU
- Not suitable for production

**Best for:**
- Development and testing
- Workflow debugging
- Pre-workshop validation

---

## When to Switch

### Scenario 1: Workshop Preparation (T-1 week)

**Use:** `local` mode
```bash
INFERENCE_PROVIDER=local
docker compose up -d worker-1
```

**Why:**
- Test workflows with real GPU
- No cloud costs during prep
- Iterate quickly on configs

### Scenario 2: Workshop Day (8 hours)

**Option A: Predictable Load** (20 users, steady generation)
```bash
INFERENCE_PROVIDER=verda-instance
# Start 1-2 instances
```
Cost: $18-36/day

**Option B: Burst Load** (sporadic after demos)
```bash
INFERENCE_PROVIDER=verda-serverless
# Auto-scale 0-5 containers
```
Cost: $10-20/day (depends on actual usage)

**Option C: Hybrid** (best of both)
```bash
# 1 instance for baseline
INFERENCE_PROVIDER=verda-instance
# + serverless for bursts
```
Cost: $25-40/day

### Scenario 3: Multi-Day Workshop (Week-long)

**Use:** `verda-instance` mode
```bash
INFERENCE_PROVIDER=verda-instance
# 1-2 instances, leave running
```

**Why:**
- Amortize costs over days
- No repeated cold starts
- Simpler management

Cost: $165/week (1 instance 24/7)

### Scenario 4: Production Platform (Always available)

**Use:** `verda-serverless` mode
```bash
INFERENCE_PROVIDER=verda-serverless
# Scale 0-10 based on demand
```

**Why:**
- $0 during off-hours
- Auto-scale for traffic spikes
- Pay only for actual use

---

## Switching Procedure

### From Instance to Serverless

**1. Deploy Serverless Container** (doesn't affect running instance)
```bash
cd /home/dev/projects/comfyui/verda
./deploy-serverless.sh
```

**2. Test with Single Job**
```bash
# Submit test job
curl -X POST https://comfy.ahelme.net/api/queue/submit -d '{...}'

# Watch serverless container scale up in Verda Console
# Verify job completes
# Verify container scales down
```

**3. Stop Instance** (when confident)
```bash
# SSH to Verda instance
ssh root@<instance-ip>
docker compose down

# Or terminate instance in Verda Console
```

**4. Update `.env`** (for clarity)
```bash
INFERENCE_PROVIDER=verda-serverless
```

### From Serverless to Instance

**1. Provision Verda Instance**
See: [Admin Guide: Verda Setup](./admin-verda-setup.md)

**2. Run Setup Script** (on instance)
```bash
# Restore from backup
./setup-verda-solo-script.sh "<MOUNT_COMMAND>"
```

**3. Start Worker**
```bash
su - dev
cd ~/comfy-multi
docker compose up -d worker-1

# Set restart policy
sudo docker update --restart=unless-stopped $(sudo docker ps -q --filter "name=comfy")
```

**4. Test**
```bash
# Submit job, verify instance processes it
curl -X POST https://comfy.ahelme.net/api/queue/submit -d '{...}'
```

**5. Scale Down Serverless** (optional)
```bash
# In Verda Console: Set max_replicas=0
# Or keep both running for hybrid mode
```

**6. Update `.env`**
```bash
INFERENCE_PROVIDER=verda-instance
```

### Hybrid Mode (Both Running)

**1. Start Instance Worker**
```bash
WORKER_ID=worker-instance-1
INFERENCE_PROVIDER=verda-instance
docker compose up -d worker-1
```

**2. Deploy Serverless**
```bash
# Containers use different WORKER_ID
WORKER_ID=worker-serverless-<random>
```

**3. Monitor Queue Manager**
Both workers visible in admin dashboard:
- `worker-instance-1` - Always active
- `worker-serverless-xyz` - Appears/disappears as containers scale

**Use Case:**
- Instance handles baseline (1-2 jobs always queued)
- Serverless handles bursts (10+ jobs after demo)

---

## Verification

### Check Active Workers

**Queue Manager API:**
```bash
curl https://comfy.ahelme.net/api/workers

# Response shows all active workers:
{
  "workers": [
    {"id": "worker-instance-1", "provider": "verda-instance"},
    {"id": "worker-serverless-abc", "provider": "verda-serverless"}
  ]
}
```

**Admin Dashboard:**
```
https://comfy.ahelme.net/admin
→ View active workers
→ Check provider type
→ Monitor job assignments
```

### Check Queue Status

```bash
curl https://comfy.ahelme.net/api/queue/status

# Response:
{
  "pending": 0,
  "running": 1,
  "completed": 45,
  "failed": 2,
  "active_workers": 2
}
```

---

## Troubleshooting

### Both Modes Running, Jobs Not Distributing

**Symptom:** Only instance worker getting jobs

**Cause:** Serverless containers not polling or exiting immediately

**Solution:**
```bash
# Check serverless container logs in Verda Console
# Ensure QUEUE_MANAGER_URL correct
# Verify health checks passing
```

### Switch Not Taking Effect

**Symptom:** Changed INFERENCE_PROVIDER but behavior unchanged

**Explanation:** `INFERENCE_PROVIDER` is metadata only (for logging/tracking)

**Action Required:**
- Deploy appropriate worker type (instance vs serverless)
- Both workers functionally identical, just different lifecycle

### Costs Higher Than Expected

**Scenario:** Switched to serverless but costs similar to instance

**Diagnosis:**
```bash
# Check Verda Console metrics:
# - Average replica count
# - Total runtime hours
# - Scale events
```

**Common Issues:**
1. Containers not scaling to zero (check idle timeout)
2. High `SERVERLESS_JOB_LIMIT` (keeping containers alive)
3. Long `SERVERLESS_MAX_IDLE_POLLS` (delayed exit)

**Fix:**
```bash
SERVERLESS_MODE=true
SERVERLESS_MAX_IDLE_POLLS=5  # Reduce from 10
SERVERLESS_JOB_LIMIT=1       # Single job per container
```

---

## Best Practices

**1. Test Before Production Switch**
- Deploy new mode alongside existing
- Submit test jobs
- Monitor for 1 hour
- Verify costs and performance

**2. Keep Instance Config Ready**
- Backup instance configuration
- Document setup process
- Can revert quickly if needed

**3. Monitor Both Cost and Performance**
- Track per-job cost
- Measure average processing time
- Compare queue wait times

**4. Document Your Choice**
Update `.env` and progress log with:
- Why provider chosen
- Expected cost/performance
- When to re-evaluate

---

## Related Documentation

- [Admin Guide: Verda Setup](./admin-verda-setup.md) - Instance deployment
- [Admin Guide: Verda Serverless](./admin-verda-serverless.md) - Serverless deployment
- [Admin Guide: Backup & Restore](./admin-backup-restore.md) - Data management
- [CLAUDE.md](../CLAUDE.md) - Project overview

---

**Last Updated:** 2026-01-27
