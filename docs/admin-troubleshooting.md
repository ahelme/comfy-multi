# Admin Troubleshooting Guide

## Quick Diagnosis

### System Health Check

```bash
# Complete system status
./scripts/status.sh

# Check all services are running
docker-compose ps

# View system resource usage
docker stats
```

### Manual Service Checks

```bash
# Queue Manager (FastAPI)
curl https://comfy.ahelme.net/api/queue/status

# Redis connectivity
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping

# Worker logs (last 20 lines)
docker-compose logs worker-1 | tail -20

# Nginx errors
docker-compose logs nginx | grep ERROR
```

---

## Common Issues and Solutions

### Issue: Queue Not Processing (Jobs Stuck in Pending)

**Symptoms:**
- Jobs remain in "pending" state indefinitely
- Queue Manager shows jobs but workers don't process them
- No errors in queue manager logs

**Diagnosis:**

```bash
# 1. Check worker is running
docker-compose ps worker-1

# 2. Check worker logs
docker-compose logs worker-1 | tail -50

# 3. Check if worker can connect to Redis
docker-compose exec worker-1 redis-cli -h redis -p 6379 -a $REDIS_PASSWORD ping

# 4. Verify queue has jobs
docker-compose exec redis redis-cli -a $REDIS_PASSWORD LLEN queue:pending

# 5. Check for GPU availability
docker-compose exec worker-1 nvidia-smi
```

**Solutions (in order):**

1. **Restart worker:**
   ```bash
   docker-compose restart worker-1
   ```

2. **Restart queue manager:**
   ```bash
   docker-compose restart queue-manager
   ```

3. **Check Redis connectivity:**
   ```bash
   docker-compose exec queue-manager \
     python -c "import redis; r = redis.Redis(host='redis'); print(r.ping())"
   ```

4. **Reset queue (caution: clears jobs):**
   ```bash
   # Only if nothing else works!
   docker-compose restart redis
   ```

---

### Issue: Out of Memory (OOM) Errors

**Symptoms:**
- Worker crashes with CUDA out of memory error
- Jobs fail unexpectedly
- GPU memory maxes out (nvidia-smi shows 99%)
- Batch size errors in workflows

**Diagnosis:**

```bash
# 1. Check GPU memory
nvidia-smi

# 2. Check memory limit in docker config
docker inspect comfy-worker-1 | grep -i memory

# 3. Check worker logs for CUDA errors
docker-compose logs worker-1 | grep -i "cuda\|memory\|oom"

# 4. Monitor GPU memory in real-time
watch -n 1 nvidia-smi
```

**Solutions (in order):**

1. **Reduce batch size in workflows:**
   - Smaller batches = less VRAM needed
   - Modify workflow JSON files

2. **Use smaller models:**
   - Switch from SDXL to SD 1.5
   - Use lower resolution outputs
   - Disable refiner in SDXL workflows

3. **Increase worker memory limit** (if available):
   ```env
   WORKER_GPU_MEMORY_LIMIT=75G
   ```
   Then restart:
   ```bash
   docker-compose restart worker-1
   ```

4. **Clear GPU cache:**
   ```bash
   # Restart worker (forces GPU cache clear)
   docker-compose restart worker-1
   ```

5. **Add GPU worker:**
   - If you have 2+ GPUs available
   - Edit docker-compose.yml to add worker-2
   - See admin-setup-guide.md for details

---

### Issue: User Can't Access Workspace

**Symptoms:**
- 404 error when accessing user001-user020
- "Page not found" or blank page
- Other users work fine

**Diagnosis:**

```bash
# 1. Check if frontend container exists
docker-compose ps | grep user00X

# 2. Check nginx logs for routing errors
docker-compose logs nginx | grep "user00X"

# 3. Test nginx routing directly
curl -k https://localhost/user001/

# 4. Check nginx configuration
docker exec nginx cat /etc/nginx/conf.d/comfyui.conf | grep user00X
```

**Solutions (in order):**

1. **Verify frontend container is running:**
   ```bash
   docker-compose up -d frontend-user001
   ```

2. **Restart nginx:**
   ```bash
   docker-compose restart nginx
   ```

3. **Check frontend logs for errors:**
   ```bash
   docker-compose logs frontend-user001 | tail -20
   ```

4. **Rebuild frontend container:**
   ```bash
   docker-compose up -d --force-recreate frontend-user001
   ```

5. **Check disk space** (might prevent container startup):
   ```bash
   df -h
   ```

---

### Issue: SSL Certificate Errors

**Symptoms:**
- Browser shows "Not Secure" warning
- "Certificate not trusted" error
- Mixed content warnings (http/https)
- Connection refused on port 443

**Diagnosis:**

```bash
# 1. Verify certificate files exist
ls -la /etc/ssl/certs/fullchain.pem
ls -la /etc/ssl/private/privkey.pem

# 2. Check certificate expiry
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -enddate

# 3. Verify certificate is valid for domain
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -text | grep -A1 "Subject:"

# 4. Check certificate file permissions
stat /etc/ssl/certs/fullchain.pem
stat /etc/ssl/private/privkey.pem

# 5. Test SSL connection
openssl s_client -connect localhost:443

# 6. Check nginx error logs
docker-compose logs nginx | grep -i "ssl\|certificate"
```

**Solutions (in order):**

1. **Verify paths in .env match actual files:**
   ```bash
   # In .env:
   SSL_CERT_PATH=/etc/ssl/certs/fullchain.pem
   SSL_KEY_PATH=/etc/ssl/private/privkey.pem

   # Verify:
   ls -la [path from .env]
   ```

2. **Fix certificate permissions:**
   ```bash
   chmod 644 /etc/ssl/certs/fullchain.pem
   chmod 600 /etc/ssl/private/privkey.pem
   chmod 755 /etc/ssl/certs
   chmod 700 /etc/ssl/private
   ```

3. **Restart nginx to reload certificates:**
   ```bash
   docker-compose restart nginx
   ```

4. **Check certificate expiry and renew if needed:**
   ```bash
   openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -enddate
   # If expired, get new certificate from Namecheap and update paths
   ```

5. **Test with curl:**
   ```bash
   curl -v https://comfy.ahelme.net/health
   ```

---

### Issue: Workers Can't Connect to Redis (Remote GPU)

**Symptoms:**
- Worker logs show Redis connection errors
- "Connection refused" or "timeout" in worker logs
- Queue Manager can see Redis but workers cannot

**Diagnosis:**

```bash
# 1. On GPU instance, test Redis connection
redis-cli -h comfy.ahelme.net -p 6379 -a $REDIS_PASSWORD ping

# 2. Check firewall on VPS (allow GPU instance IP)
sudo ufw status
# Should show port 6379 open to GPU instance IP

# 3. Check Redis is listening on all interfaces
docker-compose exec redis redis-cli CONFIG GET bind

# 4. On VPS, verify Redis is accepting external connections
sudo netstat -tlnp | grep 6379

# 5. Test connection from GPU instance
nslookup comfy.ahelme.net
telnet comfy.ahelme.net 6379
```

**Solutions (in order):**

1. **Verify Redis host in .env on GPU instance:**
   ```env
   REDIS_HOST=comfy.ahelme.net
   REDIS_PORT=6379
   REDIS_PASSWORD=<same as VPS>
   ```

2. **Configure firewall on VPS** (Hetzner):
   ```bash
   # Get GPU instance public IP
   # Add firewall rule to allow it
   sudo ufw allow from [GPU_IP] to any port 6379
   ```

3. **Verify DNS resolution works:**
   ```bash
   # From GPU instance
   nslookup comfy.ahelme.net
   ping comfy.ahelme.net
   ```

4. **Restart Redis** (if configuration changed):
   ```bash
   # On VPS
   docker-compose restart redis
   ```

5. **Restart worker** (after fixes):
   ```bash
   # On GPU instance
   docker-compose restart worker-1
   ```

---

### Issue: High Queue Depth (Too Many Pending Jobs)

**Symptoms:**
- Pending jobs > 20
- Workshop participants complaining of long waits
- Queue not clearing fast enough

**Diagnosis:**

```bash
# 1. Check queue status
curl https://comfy.ahelme.net/api/queue/status

# 2. Monitor job execution time
docker-compose logs worker-1 | grep "completed"

# 3. Check if jobs are actually completing
docker-compose exec redis redis-cli -a $REDIS_PASSWORD LLEN queue:completed

# 4. Check for stuck jobs
docker-compose exec redis redis-cli -a $REDIS_PASSWORD LLEN queue:running
```

**Solutions (in order):**

1. **Add second worker** (if GPU memory allows):
   ```yaml
   # Edit docker-compose.yml, add:
   worker-2:
     # ... same config as worker-1
   ```
   Then:
   ```bash
   docker-compose up -d worker-2
   ```

2. **Cancel low-priority failed/stuck jobs:**
   ```bash
   # In admin dashboard, cancel jobs stuck > 10 minutes
   curl -X DELETE https://comfy.ahelme.net/api/jobs/{job_id}
   ```

3. **Reduce job timeout** (for faster failures):
   ```env
   JOB_TIMEOUT=1800  # 30 minutes instead of 1 hour
   ```

4. **Ask participants to submit fewer jobs**
   - Share queue depth status
   - Suggest waiting for their current job to complete

5. **Scale GPU memory limit** (if not at max):
   ```env
   WORKER_GPU_MEMORY_LIMIT=76G
   ```

---

### Issue: Slow Performance / Long Job Times

**Symptoms:**
- Simple jobs taking > 5 minutes
- GPU utilization low (<50%)
- Queue depth not decreasing

**Diagnosis:**

```bash
# 1. Monitor GPU in real-time
watch -n 1 nvidia-smi

# 2. Check CPU usage
docker stats

# 3. Check worker logs for errors
docker-compose logs worker-1 | grep -i "error\|warning"

# 4. Check if model is being loaded repeatedly
docker-compose logs worker-1 | grep "loading"

# 5. Monitor network traffic (if using remote GPU)
# Check bandwidth between VPS and GPU instance
```

**Solutions (in order):**

1. **Check if models are properly loaded:**
   ```bash
   # Verify model files are present
   docker-compose exec worker-1 ls -lah /models/shared/checkpoints/
   ```

2. **Ensure models are on fast storage** (not network drive)

3. **Reduce model precision** (FP16 vs FP32):
   - Edit workflows to use half-precision
   - Faster but slightly lower quality

4. **Check network latency** (for remote GPU):
   ```bash
   # From GPU instance
   ping comfy.ahelme.net
   # Should be < 50ms
   ```

5. **Optimize workflow:**
   - Reduce steps in sampling
   - Use smaller resolutions
   - Disable features not needed

6. **Monitor I/O performance:**
   ```bash
   iostat -x 1
   ```

---

## Log Locations and How to Read Them

### View Logs

```bash
# All services
docker-compose logs

# Specific service
docker-compose logs queue-manager
docker-compose logs worker-1
docker-compose logs nginx
docker-compose logs redis

# Last 50 lines
docker-compose logs -n 50 worker-1

# Follow logs in real-time
docker-compose logs -f worker-1

# Export logs to file
docker-compose logs > workshop-logs.txt
```

### Log Patterns to Watch For

**Errors to investigate:**
```
ERROR
Failed
Exception
CUDA error
Out of memory
Connection refused
Timeout
500
```

**Example grep:**
```bash
docker-compose logs worker-1 | grep -i "error"
```

---

## Network Connectivity Troubleshooting

### VPS to GPU Connection Test

```bash
# From VPS, test connection to GPU instance
nslookup [gpu-instance-ip]
ping [gpu-instance-ip]
ssh -v user@[gpu-instance-ip]

# Check if Redis port is reachable from GPU
telnet [vps-ip] 6379
```

### GPU to VPS Connection Test

```bash
# From GPU instance, test connection to VPS
nslookup comfy.ahelme.net
ping comfy.ahelme.net
telnet comfy.ahelme.net 6379

# Test with redis-cli
redis-cli -h comfy.ahelme.net -p 6379 -a $REDIS_PASSWORD ping
```

### DNS Resolution

```bash
# Test DNS from both instances
dig comfy.ahelme.net
nslookup comfy.ahelme.net

# Check DNS is pointing to correct IP
dig comfy.ahelme.net +short
```

---

## Docker/Container Issues

### Container won't start

```bash
# Check logs
docker-compose logs [service_name]

# Check resource constraints
docker-compose up [service_name]  # Run in foreground

# Rebuild container
docker-compose build --no-cache [service_name]
docker-compose up -d [service_name]
```

### Container crashes immediately

```bash
# View last exit code
docker inspect [container_name] | grep -A5 "State"

# Check system limits (disk, memory)
df -h
free -h
```

### Restart all services

```bash
# Stop all
docker-compose down

# Start all
docker-compose up -d

# Verify
docker-compose ps
```

---

## Emergency Procedures

### Complete System Restart

```bash
# Stop everything
docker-compose down

# Remove cache (if corrupted)
docker system prune -a

# Restart everything
docker-compose up -d

# Verify
docker-compose ps
curl https://comfy.ahelme.net/health
```

### Manual Recovery

If automatic recovery fails:

1. **Check disk space:**
   ```bash
   df -h
   # If < 10% free, delete old output files
   ```

2. **Check GPU driver:**
   ```bash
   nvidia-smi
   # If fails, restart GPU instance
   ```

3. **Check Redis database:**
   ```bash
   docker-compose exec redis redis-cli -a $REDIS_PASSWORD INFO
   ```

4. **Contact Verda/RunPod support** if GPU issues persist

---

## Performance Metrics to Monitor

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| **GPU Memory** | < 70% | 70-85% | > 85% |
| **Queue Depth** | < 5 | 5-20 | > 20 |
| **Job Time (simple)** | < 2 min | 2-5 min | > 5 min |
| **Failed Jobs** | 0% | < 1% | > 5% |
| **Uptime** | > 99% | 95-99% | < 95% |

---

## Getting Help

If troubleshooting doesn't resolve the issue:

1. **Check logs thoroughly:**
   ```bash
   docker-compose logs > full-logs.txt
   grep -i "error\|warning" full-logs.txt
   ```

2. **Review relevant guide:**
   - **admin-setup-guide.md** - Configuration issues
   - **admin-security.md** - Access/permission issues
   - **admin-workshop-checklist.md** - During-workshop issues

3. **Check GitHub issues:**
   - ComfyUI issues
   - Project-specific issues

4. **Escalate to support:**
   - Verda/RunPod support for GPU issues
   - Hetzner support for VPS issues

For more information, see:
- **admin-guide.md** - Quick reference and monitoring
- **admin-dashboard.md** - Real-time monitoring
- **admin-workshop-checklist.md** - Workshop day procedures
