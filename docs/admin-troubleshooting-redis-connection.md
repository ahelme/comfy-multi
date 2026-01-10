**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-10

---

# Troubleshooting: Redis Connection Issues

## Quick Diagnosis

Services (Queue Manager, Workers) can't connect to Redis or Redis is unresponsive. This breaks the entire queue system since Redis is the message broker.

## Symptoms

- Queue Manager logs show Redis connection errors
- Workers show "Connection refused" to Redis
- Admin dashboard shows no queue data
- Jobs don't process regardless of worker status
- Redis timeout errors in logs
- Services crash on startup

## Diagnosis Steps

```bash
# 1. Check if Redis container is running
docker-compose ps redis

# 2. Check Redis logs
docker-compose logs redis | tail -20

# 3. Try to connect to Redis
docker-compose exec redis redis-cli ping
# Should return: PONG

# 4. Check Redis with password
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping

# 5. Check what port Redis is listening on
docker-compose exec redis redis-cli CONFIG GET port

# 6. Check if Redis has password configured
docker-compose exec redis redis-cli CONFIG GET requirepass

# 7. Check network connectivity to Redis from host
telnet localhost 6379

# 8. Monitor Redis in real-time
docker-compose exec redis redis-cli --stat
```

## Solutions (Try in Order)

### Solution 1: Check Redis is Running

Redis must be running before any services can connect.

```bash
# Check status
docker-compose ps redis

# If not running, start it
docker-compose up -d redis

# Wait 5 seconds for startup
sleep 5

# Verify
docker-compose exec redis redis-cli ping
# Should return: PONG
```

If Redis won't start, check logs:

```bash
docker-compose logs redis
```

Common startup errors:
- **Address already in use** → Another Redis already running
- **Out of memory** → Not enough disk/RAM
- **Permission denied** → File permission issue on mounted volume

### Solution 2: Verify Redis Password Configuration

Password must match in `.env` and Redis configuration.

**Check current Redis password setting:**

```bash
docker-compose exec redis redis-cli CONFIG GET requirepass
```

**Check .env has matching password:**

```bash
grep REDIS_PASSWORD .env

# Should match the requirepass value above
```

**If passwords don't match:**

1. Update `.env` to match Redis password
2. Restart services:
   ```bash
   docker-compose restart queue-manager
   docker-compose restart worker-1
   ```

**To change Redis password:**

```bash
# Set new password in Redis
docker-compose exec redis redis-cli CONFIG SET requirepass "newpassword"

# Make permanent by restarting
docker-compose restart redis

# Verify
docker-compose exec redis redis-cli -a newpassword ping
```

### Solution 3: Check Redis Connection from Services

Verify Queue Manager and Workers can reach Redis.

```bash
# From Queue Manager container
docker-compose exec queue-manager \
  python -c "import redis; r = redis.Redis(host='redis', port=6379); print(r.ping())"

# From Worker container (if worker is running)
docker-compose exec worker-1 \
  python -c "import redis; r = redis.Redis(host='redis', port=6379, password='$REDIS_PASSWORD'); print(r.ping())"

# Both should return: True
```

If either fails:
- Check Redis is running (Solution 1)
- Check Redis accepts connections: `docker-compose logs redis`
- Check container networking (Solution 4)

### Solution 4: Check Container Networking

Services must be on same Docker network to reach Redis.

```bash
# List all networks
docker network ls

# Find the comfyui network
docker network inspect [network_name] | grep "Name"

# Verify Redis is connected
docker network inspect [network_name] | grep "redis"

# Verify Queue Manager is connected
docker network inspect [network_name] | grep "queue-manager"
```

If services aren't on same network:

**In docker-compose.yml:**

```yaml
services:
  redis:
    networks:
      - comfyui

  queue-manager:
    networks:
      - comfyui

  worker-1:
    networks:
      - comfyui

networks:
  comfyui:
    driver: bridge
```

Then restart:

```bash
docker-compose down
docker-compose up -d
```

### Solution 5: Check Redis Configuration

Redis may be bound to wrong interface or have wrong settings.

```bash
# Check what Redis is bound to
docker-compose exec redis redis-cli CONFIG GET bind
# Should return: 0.0.0.0 (accessible from containers)

# Check port
docker-compose exec redis redis-cli CONFIG GET port
# Should return: 6379

# Check memory limit
docker-compose exec redis redis-cli CONFIG GET maxmemory
```

If Redis has wrong configuration:

**In docker-compose.yml:**

```yaml
redis:
  image: redis:7-alpine
  command: redis-server --bind 0.0.0.0 --port 6379 --requirepass $REDIS_PASSWORD
  ports:
    - "6379:6379"
  volumes:
    - ./data/redis:/data
  restart: unless-stopped
```

Restart Redis:

```bash
docker-compose restart redis
```

### Solution 6: Clear Redis and Restart

If Redis has corrupt data, clear it completely.

**WARNING: This deletes all jobs in queue!**

```bash
# Stop Redis
docker-compose stop redis

# Remove Redis data volume (if using volume mount)
rm -rf ./data/redis/*

# Start fresh
docker-compose up -d redis

# Wait for startup
sleep 5

# Verify
docker-compose exec redis redis-cli ping
```

Then restart all services:

```bash
docker-compose restart queue-manager
docker-compose restart worker-1
```

### Solution 7: Monitor Redis Memory Usage

Redis may be running out of memory.

```bash
# Check Redis memory usage
docker-compose exec redis redis-cli INFO memory

# Look for:
# used_memory: (current usage)
# maxmemory: (limit)

# If used > 80% of maxmemory, increase limit
docker-compose exec redis redis-cli CONFIG SET maxmemory 2gb
```

**Persistent memory increase:**

In docker-compose.yml:

```yaml
redis:
  command: redis-server --maxmemory 2gb --maxmemory-policy allkeys-lru
```

### Solution 8: Test with redis-cli

Use redis-cli to diagnose connection issues.

```bash
# From host machine (requires redis-tools)
sudo apt-get install redis-tools
redis-cli -p 6379 ping
redis-cli -p 6379 -a $REDIS_PASSWORD ping

# Inside container
docker-compose exec redis redis-cli ping
```

## Redis Performance Monitoring

### Real-Time Monitoring

```bash
# Watch Redis stats in real-time
docker-compose exec redis redis-cli --stat

# Watch specific metrics
watch -n 1 'docker-compose exec redis redis-cli INFO stats | grep "total_commands_processed"'
```

### Queue Depth Monitoring

```bash
# Check job queue sizes
docker-compose exec redis redis-cli \
  -a $REDIS_PASSWORD \
  LLEN queue:pending

docker-compose exec redis redis-cli \
  -a $REDIS_PASSWORD \
  LLEN queue:running

docker-compose exec redis redis-cli \
  -a $REDIS_PASSWORD \
  LLEN queue:completed
```

### Connection Count

```bash
# Check number of connected clients
docker-compose exec redis redis-cli INFO clients

# Shows: connected_clients: [X]
```

## Troubleshooting Connectivity (Local to Remote GPU)

If using remote GPU (e.g. Verda, RunPod), test from GPU instance:

```bash
# From GPU instance
redis-cli -h comfy.ahelme.net -p 6379 -a $REDIS_PASSWORD ping

# Should return: PONG
```

If this fails, see **admin-troubleshooting-worker-not-connecting.md** for network troubleshooting.

## Persistence and Backups

**Enable Redis persistence:**

In docker-compose.yml:

```yaml
redis:
  command: redis-server --appendonly yes --appendfsync everysec
  volumes:
    - ./data/redis:/data
```

**Backup Redis database:**

```bash
# Manual save
docker-compose exec redis redis-cli -a $REDIS_PASSWORD SAVE

# Check backup file
ls -lah ./data/redis/
```

**Restore from backup:**

```bash
# Copy backup RDB file to redis data directory
cp redis-backup.rdb ./data/redis/dump.rdb

# Restart Redis
docker-compose restart redis
```

## Emergency Recovery

**If Redis is corrupted:**

```bash
# 1. Stop Redis
docker-compose stop redis

# 2. Backup existing data
cp ./data/redis/dump.rdb ./data/redis/dump.rdb.backup

# 3. Delete corrupt data
rm -f ./data/redis/dump.rdb

# 4. Start fresh
docker-compose up -d redis

# 5. Verify
docker-compose exec redis redis-cli ping
```

## Prevention Tips

1. **Monitor Redis health regularly** - Check memory, connections, latency
2. **Enable persistence** - Use AOF or RDB to prevent data loss
3. **Set resource limits** - Don't let Redis use all available memory
4. **Monitor queue depth** - Alert if pending jobs growing unbounded
5. **Restart Redis regularly** - During maintenance windows, clear any memory leaks

## Performance Thresholds

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| **Memory Usage** | < 50% of max | 50-80% | > 80% |
| **Connected Clients** | < 10 | 10-20 | > 20 |
| **Avg Command Time** | < 1ms | 1-5ms | > 5ms |
| **Queue Pending Jobs** | < 10 | 10-30 | > 30 |

## Related Issues

- **Queue not processing** → Often caused by Redis connection failure, see admin-troubleshooting-queue-stopped.md
- **Workers can't connect to Redis** → Network issue, see admin-troubleshooting-worker-not-connecting.md
- **Performance degradation** → May be related to Redis memory pressure
