# Admin Dashboard Guide

## Dashboard Access

**URL**: `https://comfy.ahelme.net/admin`

The admin dashboard provides real-time monitoring and control of the entire ComfyUI Multi-User Platform.

---

## Dashboard Sections

### 📊 Statistics Cards

The top of the dashboard displays four key metrics:

- **Pending**: Number of jobs waiting in the queue (not yet assigned to a worker)
- **Running**: Jobs currently being processed by GPU workers
- **Completed**: Successfully finished jobs
- **Failed**: Jobs that encountered errors

These update in real-time via WebSocket connection.

### 📋 Job Queue Panel

The main panel shows all jobs in chronological order. Each job displays:

| Field | Description |
|-------|-------------|
| **Job ID** | Unique identifier for the job (first 8 characters displayed) |
| **User** | Participant who submitted the job (e.g., user001, user020) |
| **Status** | Current state (pending/running/completed/failed) |
| **Position** | Queue position if pending (1 = next to run) |
| **Worker** | Which GPU worker is processing (if running) |
| **Error** | Error message, if job failed |

#### Job Actions

**⚡ Prioritize** (pending jobs only)
- Moves a job to the front of the queue
- Useful for instructor demos or VIP jobs
- Useful during workshop if a key participant's job is stuck

**✕ Cancel** (pending or running jobs)
- Stops job execution immediately
- Running jobs are terminated
- Pending jobs are removed from queue
- Use for stuck jobs or to free GPU memory

### 🖥️ Workers Panel

Shows the status of all GPU workers processing jobs:

| Status | Meaning |
|--------|---------|
| **Green indicator** | Worker is active and processing a job |
| **Gray indicator** | Worker is idle and waiting for a job |

Each worker shows:
- **Worker ID**: Unique identifier (e.g., worker-1)
- **Current Job**: Job ID being processed (if busy)
- **GPU Utilization**: Real-time GPU memory and compute usage

---

## Common Admin Tasks

### Cancel a Stuck Job

**Scenario**: A job has been running for too long or appears frozen

**Via Dashboard:**
1. Open `https://comfy.ahelme.net/admin`
2. Locate the job in the queue panel (look for long-running jobs with no progress)
3. Click the **✕ Cancel** button
4. Confirm the cancellation
5. Job is terminated and GPU memory is freed

**Via API:**
```bash
curl -X DELETE https://comfy.ahelme.net/api/jobs/{job_id}
```

### Prioritize Instructor Demo

**Scenario**: You need to demonstrate a feature immediately during the workshop

**Steps:**
1. From `https://comfy.ahelme.net/user001/` (instructor workspace), queue a test job
2. Open admin dashboard: `https://comfy.ahelme.net/admin`
3. Find your job in the pending queue (it should be at the bottom)
4. Click the **⚡ Prioritize** button next to your job
5. Job moves to position 1 (front of queue) and runs immediately

**Via API:**
```bash
curl -X PATCH https://comfy.ahelme.net/api/jobs/{job_id}/priority \
  -H "Content-Type: application/json" \
  -d '{"priority": 0}'
```

### Clear Failed Jobs

**Scenario**: Failed jobs are cluttering the queue

**Via Docker:**
```bash
# SSH to Hetzner VPS
ssh desk

# Clear all failed jobs from Redis
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ZREMRANGEBYSCORE queue:failed 0 +inf
```

**Via API:**
```bash
# Get list of failed jobs
curl https://comfy.ahelme.net/api/jobs?status=failed

# Delete a specific failed job
curl -X DELETE https://comfy.ahelme.net/api/jobs/{job_id}
```

### Monitor Queue Depth

**Check current queue status:**

```bash
# Via API
curl https://comfy.ahelme.net/api/queue/status

# Response example:
{
  "pending": 5,
  "running": 1,
  "completed": 42,
  "failed": 1,
  "total_workers": 1,
  "workers_active": 1
}
```

**Monitor in dashboard:**
- Keep an eye on the "Pending" card
- If queue depth exceeds 10 jobs, consider:
  - Adding another GPU worker (if available)
  - Asking participants to submit fewer jobs
  - Canceling low-priority jobs

### Monitor GPU Memory

**In Dashboard:**
- Workers panel shows real-time GPU utilization
- Green status = GPU is active
- Watch for consistently high memory usage

**Via Command Line:**
```bash
# SSH to GPU instance
ssh user@your-gpu-instance

# Check GPU memory
nvidia-smi

# Watch GPU continuously
watch -n 1 nvidia-smi
```

---

## Dashboard Indicators and Status

### Status Colors/Indicators

- **🟢 Green**: Service running, worker active
- **🟡 Yellow**: Warning, high resource usage
- **🔴 Red**: Error, service down
- **⚪ Gray**: Service idle or disconnected

### WebSocket Connection Status

The dashboard uses WebSocket for real-time updates. If you see:
- **"Connected"**: Dashboard is receiving live updates
- **"Disconnected"**: Dashboard lost connection to queue manager (refresh page)
- **"Connecting..."**: Reconnecting to server

### Job Status Meanings

| Status | Description | Can Cancel? | Can Prioritize? |
|--------|-------------|-------------|-----------------|
| **pending** | Waiting in queue | Yes | Yes |
| **running** | Being processed by worker | Yes | No |
| **completed** | Successfully finished | No | No |
| **failed** | Error occurred | No | No |

---

## Keyboard Shortcuts (if implemented)

| Shortcut | Action |
|----------|--------|
| `R` | Refresh all data |
| `C` | Clear failed jobs |
| `?` | Show help |

---

## API Endpoints

For advanced monitoring, you can query the API directly:

**Get queue status:**
```bash
GET /api/queue/status
```

**Get all jobs:**
```bash
GET /api/jobs
GET /api/jobs?status=pending
GET /api/jobs?status=running
GET /api/jobs?user=user001
```

**Get job details:**
```bash
GET /api/jobs/{job_id}
```

**Cancel a job:**
```bash
DELETE /api/jobs/{job_id}
```

**Prioritize a job:**
```bash
PATCH /api/jobs/{job_id}/priority
Body: {"priority": 0}
```

---

## Troubleshooting Dashboard Issues

### Dashboard won't load

1. Check if queue manager is running:
   ```bash
   docker-compose ps queue-manager
   ```

2. Check queue manager logs:
   ```bash
   docker-compose logs queue-manager
   ```

3. Verify HTTPS/SSL is working:
   ```bash
   curl -k https://localhost/admin
   ```

### Dashboard not updating in real-time

1. Refresh the page (Ctrl+R or Cmd+R)
2. Check browser console for WebSocket errors (F12 → Console)
3. Restart queue manager:
   ```bash
   docker-compose restart queue-manager
   ```

### Jobs not appearing in dashboard

1. Verify jobs are being queued:
   ```bash
   curl https://comfy.ahelme.net/api/queue/status
   ```

2. Check Redis connection:
   ```bash
   docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping
   ```

3. Check queue manager logs for errors:
   ```bash
   docker-compose logs queue-manager | tail -50
   ```

---

## Best Practices

1. **Check dashboard every 5-10 minutes** during workshop
2. **Cancel stuck jobs promptly** to free GPU memory
3. **Monitor queue depth** - keep it under 20 jobs
4. **Watch GPU memory** - restart workers if approaching limit
5. **Document any failures** for post-workshop analysis
6. **Prioritize strategically** - don't abuse this feature

For more information, see:
- **admin-guide.md** - Quick reference and monitoring
- **admin-troubleshooting.md** - Problem solving
- **admin-workshop-checklist.md** - Workshop day procedures
