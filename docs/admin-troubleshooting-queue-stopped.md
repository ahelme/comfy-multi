**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-11

---

# Troubleshooting: Queue Not Processing

## Quick Diagnosis

Jobs are stuck in "pending" state and workers are not processing them. This is one of the most common issues and usually has a straightforward fix.

## Symptoms

- Jobs remain in "pending" state indefinitely
- Queue Manager shows jobs but workers don't process them
- No errors in queue manager logs
- Admin dashboard shows jobs queued but not active

## Diagnosis Steps

Run these commands in order to identify the issue:

```bash
# 1. Check if worker is running
docker-compose ps worker-1

# 2. Check worker logs for errors
docker-compose logs worker-1 | tail -50

# 3. Verify worker can connect to Redis
docker-compose exec worker-1 redis-cli -h redis -p 6379 -a $REDIS_PASSWORD ping

# 4. Check if queue has jobs
docker-compose exec redis redis-cli -a $REDIS_PASSWORD LLEN queue:pending

# 5. Check for GPU availability
docker-compose exec worker-1 nvidia-smi

# 6. Check worker process status
docker-compose exec worker-1 ps aux | grep comfyui
```

## Solutions (Try in Order)

### Solution 1: Restart Worker

Most common fix. The worker process may be hung or in a bad state.

```bash
docker-compose restart worker-1
```

Wait 10 seconds, then check:
```bash
docker-compose logs worker-1 | tail -20
```

If jobs start processing, you're done.

### Solution 2: Restart Queue Manager

The queue manager may have lost connection to Redis or workers.

```bash
docker-compose restart queue-manager
```

Wait 5 seconds, then verify:
```bash
curl https://comfy.ahelme.net/api/queue/status
```

### Solution 3: Verify Redis Connectivity

Check if worker can actually reach Redis.

```bash
# Test from queue manager
docker-compose exec queue-manager \
  python -c "import redis; r = redis.Redis(host='redis'); print(r.ping())"

# Test from worker
docker-compose exec worker-1 \
  python -c "import redis; r = redis.Redis(host='redis', password='$REDIS_PASSWORD'); print(r.ping())"
```

Both should return `True`.

If either fails:
- Check `.env` has correct `REDIS_PASSWORD`
- Check Redis is running: `docker-compose ps redis`
- Check network connectivity between containers

### Solution 4: Check Worker GPU Status

Worker might be unable to access GPU.

```bash
docker-compose exec worker-1 nvidia-smi
```

If this fails:
- Check GPU driver is installed on host: `nvidia-smi`
- Verify Docker GPU runtime is configured in docker-compose.yml
- Check NVIDIA Container Runtime is installed

### Solution 5: Reset Queue (Nuclear Option)

Only if nothing else works. This will clear all pending jobs.

```bash
# WARNING: This deletes all pending jobs!
docker-compose restart redis
```

Then restart all services:
```bash
docker-compose restart worker-1
docker-compose restart queue-manager
```

## Monitoring for Prevention

### Real-Time Monitoring

```bash
# Watch queue depth in real-time
watch -n 2 'docker-compose exec redis redis-cli -a $REDIS_PASSWORD LLEN queue:pending'

# Follow worker logs in real-time
docker-compose logs -f worker-1
```

### Health Check

Use this script periodically during the workshop:

```bash
#!/bin/bash
echo "Queue Status Check"
echo "=================="

# Check worker running
if docker-compose ps worker-1 | grep -q "Up"; then
  echo "✓ Worker running"
else
  echo "✗ Worker NOT running"
  exit 1
fi

# Check pending jobs
pending=$(docker-compose exec redis redis-cli -a $REDIS_PASSWORD LLEN queue:pending)
echo "✓ Pending jobs: $pending"

# Check if actively processing
running=$(docker-compose exec redis redis-cli -a $REDIS_PASSWORD LLEN queue:running)
echo "✓ Running jobs: $running"

# Check GPU
if docker-compose exec worker-1 nvidia-smi &>/dev/null; then
  echo "✓ GPU accessible"
else
  echo "✗ GPU NOT accessible"
fi
```

## Prevention Tips

1. **Monitor queue depth regularly** - If it keeps growing, something is wrong
2. **Watch worker logs during workshop** - Catch issues early
3. **Restart services before workshop** - Ensures clean state
4. **Test with dummy jobs first** - Verify queue works before letting participants submit

## Remote GPU (e.g. Verda) Specific

If using a remote GPU instance, queue issues often relate to network connectivity rather than the queue itself:

```bash
# From GPU instance, test connection to Redis on VPS
redis-cli -h comfy.ahelme.net -p 6379 -a $REDIS_PASSWORD ping

# Should return PONG
```

If this fails, see **admin-troubleshooting-redis-connection.md** for network troubleshooting.

## Related Issues

- **Worker can't connect to Redis** → See admin-troubleshooting-redis-connection.md
- **Out of memory errors** → See admin-troubleshooting-out-of-memory.md
- **Worker container won't start** → See admin-troubleshooting-docker-issues.md
