**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-02
**Doc Updated:** 2026-01-11

---

# Troubleshooting Guide

Common issues and solutions for the ComfyUI Multi-User Platform.

## 🔍 Quick Diagnostics

### Check System Status

**Web Dashboard (Recommended):**
```
Visit: https://comfy.ahelme.net/health
```
Beautiful real-time dashboard with color-coded status!

**Command Line:**
```bash
./scripts/status.sh
```

### Check Service Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs queue-manager -f
docker-compose logs worker-1 -f
docker-compose logs nginx -f
```

### Check Individual Components

```bash
# Redis
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping

# Queue Manager API
curl http://localhost:3000/health

# Admin Dashboard
curl http://localhost:8080/health

# Nginx
docker-compose exec nginx nginx -t
```

---

## 🚫 Services Won't Start

### Issue: docker-compose fails to start

**Error**: `ERROR: Couldn't connect to Docker daemon`

**Solution**:
```bash
# Start Docker service
sudo systemctl start docker

# Or restart Docker
sudo systemctl restart docker

# Verify Docker is running
docker ps
```

### Issue: Port already in use

**Error**: `Bind for 0.0.0.0:443 failed: port is already allocated`

**Solution**:
```bash
# Find process using port
sudo lsof -i :443
sudo lsof -i :80

# Kill process or change port in .env
# Then restart
docker-compose down && docker-compose up -d
```

### Issue: Missing .env file

**Error**: `WARNING: The REDIS_PASSWORD variable is not set`

**Solution**:
```bash
# Copy template
cp .env.example .env

# Edit configuration
nano .env

# Restart
docker-compose up -d
```

---

## 🔴 Queue Manager Issues

### Issue: Queue manager won't start

**Check logs**:
```bash
docker-compose logs queue-manager
```

**Common causes**:

1. **Redis connection failed**
   ```bash
   # Verify Redis is running
   docker-compose ps redis

   # Check Redis password
   docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping
   ```

2. **Port conflict**
   ```bash
   # Check if port 3000 is free
   sudo lsof -i :3000

   # Change port in .env if needed
   QUEUE_MANAGER_PORT=3001
   ```

3. **Invalid configuration**
   ```bash
   # Verify .env settings
   cat .env | grep -v "^#" | grep -v "^$"
   ```

### Issue: Jobs stuck in pending

**Diagnosis**:
```bash
# Check queue depth
curl http://localhost:3000/api/queue/status

# Check worker logs
docker-compose logs worker-1 | tail -50

# Check if worker is polling
docker-compose logs worker-1 | grep "polling\|next job"
```

**Solutions**:
1. Restart worker:
   ```bash
   docker-compose restart worker-1
   ```

2. Clear stale jobs:
   ```bash
   docker-compose exec redis redis-cli -a $REDIS_PASSWORD ZREMRANGEBYSCORE queue:pending 0 $(date -d '1 hour ago' +%s)
   ```

3. Restart queue manager:
   ```bash
   docker-compose restart queue-manager
   ```

---

## 🖥️ Worker Issues

### Issue: Worker crashes with CUDA error

**Error**: `CUDA out of memory` or `RuntimeError: CUDA error`

**Diagnosis**:
```bash
# Check GPU memory
nvidia-smi

# Check worker memory limit
docker inspect comfy-worker-1 | grep -i memory
```

**Solutions**:

1. **Reduce GPU memory pressure**:
   ```env
   # Edit .env
   WORKER_GPU_MEMORY_LIMIT=60G  # Lower from 70G
   ```

2. **Clear GPU cache**:
   ```bash
   docker-compose restart worker-1
   ```

3. **Use smaller models**:
   - Replace SDXL with SD 1.5
   - Reduce batch sizes in workflows

### Issue: Worker not processing jobs

**Diagnosis**:
```bash
# Check worker status
docker-compose ps worker-1

# Check worker logs
docker-compose logs worker-1 | tail -100

# Verify worker can reach queue manager
docker-compose exec worker-1 curl http://queue-manager:3000/health
```

**Solutions**:

1. **Restart worker**:
   ```bash
   docker-compose restart worker-1
   ```

2. **Check network connectivity**:
   ```bash
   docker-compose exec worker-1 ping queue-manager
   docker-compose exec worker-1 ping redis
   ```

3. **Rebuild worker**:
   ```bash
   docker-compose build worker-1
   docker-compose up -d worker-1
   ```

### Issue: ComfyUI not loading

**Error**: Worker logs show "Failed to connect to ComfyUI"

**Solution**:
```bash
# Check if ComfyUI is running inside worker
docker-compose exec worker-1 curl http://localhost:8188/system_stats

# Restart worker
docker-compose restart worker-1

# Check worker startup logs
docker-compose logs worker-1 | grep -i "comfyui\|startup"
```

---

## 🌐 Nginx Issues

### Issue: SSL certificate errors

**Error**: Browser shows "Not Secure" or certificate warning

**Diagnosis**:
```bash
# Verify certificate files exist
ls -la $SSL_CERT_PATH
ls -la $SSL_KEY_PATH

# Check certificate validity
openssl x509 -in $SSL_CERT_PATH -noout -enddate

# Test SSL
curl -vI https://your-domain 2>&1 | grep -i ssl
```

**Solutions**:

1. **Fix certificate paths**:
   ```env
   # Edit .env
   SSL_CERT_PATH=/correct/path/to/fullchain.pem
   SSL_KEY_PATH=/correct/path/to/privkey.pem
   ```

2. **Fix permissions**:
   ```bash
   sudo chmod 644 $SSL_CERT_PATH
   sudo chmod 600 $SSL_KEY_PATH
   ```

3. **Restart nginx**:
   ```bash
   docker-compose restart nginx
   ```

### Issue: 404 Not Found for user workspace

**Error**: Accessing `/user001/` returns 404

**Diagnosis**:
```bash
# Check nginx logs
docker-compose logs nginx | grep "404\|user001"

# Check user frontend container
docker-compose ps | grep user001

# Test nginx config
docker-compose exec nginx nginx -t
```

**Solutions**:

1. **Start user frontend**:
   ```bash
   docker-compose -f docker-compose.override.yml up -d user001
   ```

2. **Regenerate nginx config**:
   ```bash
   docker-compose restart nginx
   ```

3. **Check nginx routing**:
   ```bash
   docker-compose exec nginx cat /etc/nginx/conf.d/user-upstreams.conf
   ```

### Issue: WebSocket connection fails

**Error**: Admin dashboard shows "Reconnecting..." or no real-time updates

**Diagnosis**:
```bash
# Check browser console (F12)
# Look for WebSocket errors

# Test WebSocket endpoint
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: test" \
  http://localhost:3000/ws
```

**Solution**:
```bash
# Restart queue manager
docker-compose restart queue-manager

# Verify WebSocket support in nginx
docker-compose exec nginx cat /etc/nginx/nginx.conf | grep -i upgrade
```

---

## 💾 Redis Issues

### Issue: Redis connection refused

**Error**: `redis.exceptions.ConnectionError: Error 111 connecting to redis:6379`

**Diagnosis**:
```bash
# Check Redis status
docker-compose ps redis

# Check Redis logs
docker-compose logs redis

# Test connection
docker-compose exec redis redis-cli ping
```

**Solutions**:

1. **Start Redis**:
   ```bash
   docker-compose up -d redis
   ```

2. **Check Redis password**:
   ```bash
   # Verify password in .env matches
   docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping
   ```

3. **Restart Redis**:
   ```bash
   docker-compose restart redis
   ```

### Issue: Redis out of memory

**Error**: `OOM command not allowed when used memory > 'maxmemory'`

**Solution**:
```bash
# Check Redis memory usage
docker-compose exec redis redis-cli -a $REDIS_PASSWORD INFO memory

# Increase Redis memory limit
docker-compose exec redis redis-cli -a $REDIS_PASSWORD CONFIG SET maxmemory 2gb

# Clear old completed jobs
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ZREMRANGEBYRANK queue:completed 0 -100
```

---

## 👤 User Frontend Issues

### Issue: User can't load workflows

**Error**: Workflow files not showing in Load dialog

**Solution**:
```bash
# Verify workflows directory
ls -la data/workflows/

# Check volume mount
docker-compose exec user001 ls -la /workflows/

# Restart frontend
docker-compose restart user001
```

### Issue: Queue Prompt button does nothing

**Diagnosis**:
```bash
# Check browser console (F12) for JavaScript errors

# Verify custom node loaded
docker-compose logs user001 | grep queue_redirect

# Test queue manager connection
curl http://localhost:3000/health
```

**Solutions**:

1. **Refresh browser** (Ctrl+Shift+R)
2. **Clear browser cache**
3. **Restart user frontend**:
   ```bash
   docker-compose restart user001
   ```

### Issue: Outputs not appearing

**Error**: Job completes but no output visible

**Solution**:
```bash
# Check output directory
ls -la data/outputs/user001/

# Verify volume mount
docker-compose exec user001 ls -la /outputs/user001/

# Check worker logs for save errors
docker-compose logs worker-1 | grep -i "save\|output"
```

---

## 🔧 Performance Issues

### Issue: Jobs take too long

**Diagnosis**:
```bash
# Check GPU utilization
nvidia-smi dmon -s u

# Check system resources
docker stats

# Check queue depth
curl http://localhost:3000/api/queue/status
```

**Solutions**:

1. **Optimize workflows**:
   - Reduce steps (20-30 instead of 50)
   - Use smaller batch sizes
   - Disable refiner pass

2. **Clear queue**:
   ```bash
   # Cancel all pending jobs
   curl -X DELETE http://localhost:3000/api/jobs/clear
   ```

3. **Scale workers** (if you have multiple GPUs):
   - Edit docker-compose.yml to add worker-2
   - Restart: `docker-compose up -d`

### Issue: High memory usage

**Diagnosis**:
```bash
# Check memory usage
docker stats --no-stream

# Check specific container
docker stats comfy-worker-1 --no-stream
```

**Solutions**:

1. **Increase memory limit**:
   ```yaml
   # Edit docker-compose.yml
   deploy:
     resources:
       limits:
         memory: 32G  # Increase from default
   ```

2. **Restart containers**:
   ```bash
   docker-compose restart
   ```

---

## 🆘 Emergency Procedures

### Complete System Restart

```bash
# Stop everything
docker-compose down

# Wait 10 seconds
sleep 10

# Start everything
docker-compose up -d

# Check status
./scripts/status.sh
```

### Clear All Data (DANGER!)

```bash
# Stop services
docker-compose down -v

# Remove data
rm -rf data/outputs/*
rm -rf data/inputs/*

# Restart
docker-compose up -d
```

### Rollback to Previous Version

```bash
# Stop services
docker-compose down

# Revert git changes
git reset --hard HEAD~1

# Rebuild
docker-compose build

# Start
docker-compose up -d
```

---

## 📝 Logging

### Enable Debug Logging

```env
# Edit .env
LOG_LEVEL=DEBUG
QUEUE_MANAGER_LOG_LEVEL=DEBUG
```

```bash
# Restart services
docker-compose restart queue-manager worker-1
```

### Save Logs for Analysis

```bash
# Save all logs
docker-compose logs > all-logs-$(date +%Y%m%d-%H%M%S).txt

# Save specific service
docker-compose logs queue-manager > queue-manager-$(date +%Y%m%d).log
```

### Watch Logs in Real-time

```bash
# All services
docker-compose logs -f

# Multiple services
docker-compose logs -f queue-manager worker-1

# With timestamps
docker-compose logs -f --timestamps
```

---

## 🔍 Diagnostic Commands

### System Health

**Web Dashboard (Best!):**
```
https://comfy.ahelme.net/health
```
Shows all services with real-time status updates!

**Command Line:**
```bash
# Quick ping
curl https://comfy.ahelme.net/health/ping

# Docker health
docker-compose ps

# Service endpoints
curl http://localhost:3000/health  # Queue Manager
curl http://localhost:8080/health  # Admin
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping  # Redis

# GPU status
nvidia-smi

# Disk space
df -h data/
```

### Queue Status

```bash
# API status
curl http://localhost:3000/api/queue/status | jq

# Redis queue depth
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ZCARD queue:pending

# List pending jobs
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ZRANGE queue:pending 0 -1
```

### Network Connectivity

```bash
# Test from worker to queue manager
docker-compose exec worker-1 curl http://queue-manager:3000/health

# Test from queue manager to Redis
docker-compose exec queue-manager curl http://redis:6379

# Test nginx routing
curl -k https://localhost/admin
curl -k https://localhost/user001/
```

---

## 📞 Getting Help

If you can't resolve the issue:

1. **Check GitHub Issues**: https://github.com/ahelme/comfy-multi/issues
2. **Review logs**: Save logs and share relevant excerpts
3. **Provide details**:
   - Error message
   - Steps to reproduce
   - System info (`docker --version`, `nvidia-smi`)
   - Configuration (`.env` with passwords redacted)

4. **Create minimal reproduction**:
   - Fresh install
   - Minimal .env
   - Default workflows

---

**Good luck troubleshooting!** 🔧
