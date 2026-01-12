**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-11

---

# Admin Checklist: During Workshop

## First Hour - Critical Monitoring

Run these checks continuously during the first 60 minutes as participants start using the system.

### Arrival and Startup (T+0 to T+15 min)

- [ ] Monitor admin dashboard continuously
  ```bash
  # Keep https://comfy.ahelme.net/admin open
  # Watch for any connection issues or errors
  ```

- [ ] Watch for 404 errors or connection issues
  ```bash
  docker-compose logs nginx | grep -i "404\|error"
  ```

- [ ] Be ready to assist participants with access
  - Verify each participant can load their workspace
  - Clear any browser cache if issues occur
  - Provide direct links if routing fails

### Initial Job Processing (T+15 to T+60 min)

- [ ] Verify jobs are queuing correctly
  ```bash
  curl https://comfy.ahelme.net/api/queue/status
  # Should show jobs entering queue
  ```

- [ ] Keep queue depth < 10 jobs
  ```bash
  # Monitor queue depth every 2 minutes
  # Cancel stuck jobs if depth exceeds 15
  ```

- [ ] Monitor GPU memory (should not exceed 80%)
  ```bash
  watch -n 5 nvidia-smi
  # Watch "Memory-Usage" column
  ```

- [ ] Note any errors or unusual activity
  ```bash
  docker-compose logs worker-1 | tail -20
  ```

- [ ] Be ready to assist technical issues
  - Participant workspace won't load? → Restart frontend
  - Job fails? → Check logs and error message
  - Queue slow? → Check GPU memory and worker logs

## Ongoing Monitoring - Every 5-10 Minutes

Continuous checks to maintain system health throughout the workshop.

### Queue Management

- [ ] Check admin dashboard queue depth
  ```bash
  curl https://comfy.ahelme.net/api/queue/status | jq '.queue_depth'
  ```

- [ ] Look for stuck or failed jobs
  ```bash
  # In admin dashboard, check for red/failed status
  # If job stuck > 10 minutes, consider canceling
  ```

- [ ] Monitor job completion rate
  ```bash
  # Jobs should be completing regularly
  # Not just queuing indefinitely
  ```

### System Resources

- [ ] Monitor GPU memory usage
  ```bash
  nvidia-smi
  # Look for: Memory-Usage and GPU-Memory-Usage
  # Alert if > 75GB
  ```

- [ ] Verify worker is responsive
  ```bash
  docker-compose logs worker-1 | tail -5
  # Should show recent activity
  ```

- [ ] Check CPU and disk I/O
  ```bash
  docker stats
  # Watch CPU% and I/O rates
  ```

### Service Health

- [ ] Verify all services still running
  ```bash
  docker-compose ps
  # All should show "Up"
  ```

- [ ] Check for any container restarts
  ```bash
  docker-compose ps | grep "Restarting"
  # Should show none
  ```

- [ ] Monitor error logs
  ```bash
  docker-compose logs | grep -i "error\|exception" | tail -10
  ```

## Periodic Checks - Every 30 Minutes

More thorough system checks to catch emerging issues.

### System Status

- [ ] Run full health check
  ```bash
  ./scripts/status.sh
  # All systems should report healthy
  ```

- [ ] Review worker logs for warnings
  ```bash
  docker-compose logs worker-1 | grep -i "warning" | tail -10
  ```

- [ ] Check disk space isn't filling up
  ```bash
  df -h /
  # Should have > 10% free space
  # If < 15%, delete old outputs
  ```

### Redis and Queue

- [ ] Check Redis connectivity
  ```bash
  docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping
  # Should return PONG
  ```

- [ ] Verify queue isn't corrupted
  ```bash
  docker-compose exec redis redis-cli -a $REDIS_PASSWORD DBSIZE
  # Should show reasonable number of keys
  ```

### Network Connectivity

- [ ] Test VPS ↔ GPU connectivity (if remote GPU)
  ```bash
  # From GPU instance:
  redis-cli -h comfy.ahelme.net -p 6379 -a $REDIS_PASSWORD ping
  # Should return PONG
  ```

- [ ] Monitor network latency
  ```bash
  # From GPU instance:
  ping -c 5 comfy.ahelme.net | grep avg
  # Should be < 50ms
  ```

## Common Tasks During Workshop

### Task 1: Cancel a Stuck Job

If a job is running for > 15 minutes and clearly stuck:

```bash
# 1. Identify the job ID in admin dashboard
# 2. Cancel via API
curl -X DELETE https://comfy.ahelme.net/api/jobs/{job_id}

# 3. Verify it was cancelled
curl https://comfy.ahelme.net/api/queue/status

# 4. Inform participant their job was cancelled
# 5. Suggest they resubmit with adjusted parameters
```

### Task 2: Prioritize Instructor Demo

To move your demo job to front of queue:

```bash
# 1. Queue demo job from user001
# 2. Get its job_id from admin dashboard
# 3. Prioritize it
curl -X POST https://comfy.ahelme.net/api/jobs/{job_id}/prioritize

# 4. Job moves to front of queue
# 5. Monitor for completion
```

### Task 3: Help Participant with Workflow

To assist a participant with workflow issues:

```bash
# 1. Ask for their user ID (e.g., user012)
# 2. Open their workspace
# 3. Review their workflow
# 4. Suggest adjustments:
#    - Reduce batch size (1 instead of 4)
#    - Reduce steps (20 instead of 50)
#    - Lower resolution (512x512 instead of 1024x1024)
# 5. Have them re-queue job
# 6. Monitor for successful completion
```

### Task 4: Monitor Growing Queue Depth

If pending jobs > 15:

```bash
# 1. Check job execution times
docker-compose logs worker-1 | grep "completed" | tail -5
# Look at time between start and completion

# 2. Look for stuck jobs
curl https://comfy.ahelme.net/api/queue/status | jq '.running'
# If many "running" but no recent completions, stuck

# 3. Consider adding second worker
# (if GPU memory allows and queue keeps growing)

# 4. Inform participants about queue wait times
# "Current wait time is 10 minutes, please be patient"
```

### Task 5: Handle GPU Memory Issues

If GPU memory approaching 80%:

```bash
# 1. Check current usage
nvidia-smi

# 2. Identify what's consuming memory
nvidia-smi pids process

# 3. If memory stuck high (not clearing between jobs):
docker-compose restart worker-1
# Wait 30 seconds for restart

# 4. If still high, cancel lowest-priority job
curl -X DELETE https://comfy.ahelme.net/api/jobs/{lowest_priority_job_id}

# 5. Monitor recovery
watch -n 1 nvidia-smi
```

### Task 6: Restart a User's Frontend

If user gets 404 or blank page:

```bash
# 1. Restart their frontend container
docker-compose restart frontend-user00X

# 2. Wait 10 seconds for restart
sleep 10

# 3. Have them refresh browser (Ctrl+Shift+R)

# 4. Verify it loaded
curl -s https://comfy.ahelme.net/user00X/ | grep "ComfyUI"
```

## Emergency Procedures

### Emergency 1: System Goes Down (Services Crash)

If queue manager, worker, or nginx stops responding:

```bash
# 1. Immediately notify participants
# "We're experiencing a brief outage, will be back online shortly"

# 2. Note the time and last known status

# 3. Start recovery
docker-compose restart queue-manager
docker-compose restart worker-1

# 4. Wait 30 seconds for restart
sleep 30

# 5. Verify recovery
./scripts/status.sh

# 6. Test with simple curl
curl https://comfy.ahelme.net/health

# 7. Resume workshop and resume accepting jobs
```

### Emergency 2: GPU Instance Crashes

If worker loses connection or GPU instance becomes unresponsive:

```bash
# 1. Notify participants immediately
# "GPU instance is restarting, jobs will resume in 2-3 minutes"

# 2. Power cycle GPU instance
# (via Verda/RunPod console - click restart/reboot)

# 3. Wait 2-3 minutes for instance to come back

# 4. SSH to verify it's back up
ssh user@[gpu-instance] nvidia-smi

# 5. Verify Redis connection works
redis-cli -h comfy.ahelme.net -p 6379 -a $REDIS_PASSWORD ping

# 6. Check worker logs for recovery
docker-compose logs worker-1 | tail -20

# 7. Resume workshop
```

### Emergency 3: VPS Goes Down (Nginx/Frontends Down)

If participants can't access workspaces:

```bash
# 1. SSH to VPS
ssh desk

# 2. Check service status
docker-compose ps

# 3. Restart Docker if completely hung
sudo systemctl restart docker
docker-compose up -d

# 4. Wait 30 seconds for startup
sleep 30

# 5. Verify
docker-compose ps  # All "Up"
curl https://comfy.ahelme.net/health

# 6. Notify participants to refresh browsers
# 7. Resume workshop
```

### Emergency 4: Complete System Failure

If nothing works and you need to provide fallback access:

```bash
# 1. Notify participants immediately
# "Main system is down, providing fallback access..."

# 2. Provide fallback options:
#    - Standalone ComfyUI instances (if available)
#    - Direct GPU access (if available)
#    - RunPod/Modal serverless links
#    - Manual GPU instance links

# 3. Document what happened for post-mortem
#    - Time of failure
#    - Last known state
#    - Error messages

# 4. Continue workshop on fallback
# 5. Resume on main system when ready
```

## Participant Support

### Common Participant Issues

**"My workspace won't load"**
```bash
docker-compose restart frontend-user00X
# Have participant refresh browser (Ctrl+Shift+R)
```

**"My job is stuck"**
```bash
# Check admin dashboard
# If stuck > 10 minutes, cancel it
curl -X DELETE https://comfy.ahelme.net/api/jobs/{job_id}
```

**"How long will my job take?"**
```
Answer based on current history:
- LTX-2 text-to-video: 60-180 seconds (varies by length)
- LTX-2 with upscaler: 120-240 seconds
- Video generation: 3-10 minutes
- Current queue: X jobs ahead
```

**"Can I upload my own model?"**
```bash
# Check if model uploads enabled:
grep MODEL_UPLOADS .env
# If enabled, provide instructions
# If disabled: "Not available in this workshop"
```

**"Can you prioritize my job?"**
```
Use admin dashboard ⚡ Prioritize feature.
Reserve for instructors/important demos only.
Explain to participant: "Jobs run in order, thanks for patience"
```

## Quick Reference Commands

```bash
# View system status
./scripts/status.sh

# Check queue status
curl https://comfy.ahelme.net/api/queue/status

# Monitor GPU
watch -n 1 nvidia-smi

# View worker logs
docker-compose logs worker-1 | tail -50

# Cancel a job
curl -X DELETE https://comfy.ahelme.net/api/jobs/{job_id}

# Restart worker
docker-compose restart worker-1

# Restart all
docker-compose restart

# Check disk space
df -h

# Monitor in real-time
docker stats
```

## Key URLs

| URL | Purpose |
|-----|---------|
| `https://comfy.ahelme.net/user001` | Instructor workspace |
| `https://comfy.ahelme.net/user002-020` | Participant workspaces |
| `https://comfy.ahelme.net/admin` | Admin dashboard |
| `https://comfy.ahelme.net/health` | System health |
| `https://comfy.ahelme.net/api/queue/status` | Queue status API |

## Tips for Success

1. **Monitor proactively** - Don't wait for complaints
2. **Keep communications open** - Update participants on status
3. **Cancel problematic jobs** - Don't let them consume resources
4. **Watch for patterns** - Multiple failures of same model?
5. **Restart conservatively** - Full restart only as last resort
6. **Document issues** - Track what happens for post-workshop analysis
7. **Stay calm** - System usually recovers with simple restarts
