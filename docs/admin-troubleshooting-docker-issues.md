**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-11

---

# Troubleshooting: Docker and Container Issues

## Quick Diagnosis

Docker containers won't start, crash immediately, or behave unexpectedly. This prevents services from running entirely.

## Symptoms

- Container exits immediately after starting
- "docker-compose up" fails to start service
- Container shows "Exited (1)" status
- "Service not starting" errors
- Disk space issues
- Memory or resource exhaustion

## Diagnosis Steps

```bash
# 1. Check all container status
docker-compose ps

# 2. Check specific container status and exit code
docker-compose logs [service_name] | tail -50

# 3. Inspect container state
docker inspect comfy-[service_name] | grep -A5 '"State"'

# 4. Check system resources
docker stats

# 5. Check disk space
df -h

# 6. Check available memory
free -h

# 7. Check Docker logs
journalctl -u docker -n 50
```

## Solutions (Try in Order)

### Solution 1: Check Disk Space

Containers need disk space to run and store data.

```bash
# Check disk usage
df -h

# Identify what's using space
du -sh /* | sort -rh

# If < 10% free, you need to clean up
```

**If low on disk space:**

1. **Remove old Docker images:**
   ```bash
   docker image prune -a --force
   ```

2. **Remove dangling volumes:**
   ```bash
   docker volume prune -f
   ```

3. **Clean old output files:**
   ```bash
   # Find and remove old outputs
   find ./data/outputs -mtime +7 -delete  # Older than 7 days
   ```

4. **Compact Docker storage:**
   ```bash
   docker system prune -a
   ```

5. **Move data to external drive** if possible

### Solution 2: Check Memory and Resource Limits

System may be out of memory.

```bash
# Check memory usage
free -h

# Check swap
swapon --show

# Monitor real-time
watch -n 1 free -h
```

**If out of memory:**

1. **Stop non-essential services:**
   ```bash
   docker-compose stop [service_name]
   ```

2. **Restart Docker to free memory:**
   ```bash
   sudo systemctl restart docker
   docker-compose up -d
   ```

3. **Reduce memory limits in docker-compose.yml:**
   ```yaml
   services:
     worker-1:
       mem_limit: 32g  # Reduce if too high
   ```

### Solution 3: Check Container Logs for Errors

Logs reveal why container failed to start.

```bash
# View full logs for failed service
docker-compose logs [service_name]

# View last 100 lines
docker-compose logs -n 100 [service_name]

# Follow logs in real-time
docker-compose logs -f [service_name]

# Search for error keyword
docker-compose logs [service_name] | grep -i error
```

**Common error patterns:**

```
"Exit code 1" → Generic error, check logs
"Out of memory" → Not enough RAM
"Address already in use" → Port/socket conflict
"Permission denied" → File permission issue
"File not found" → Missing volume mount
"Command not found" → Missing binary in image
```

### Solution 4: Check Port Conflicts

Another process may be using the required port.

```bash
# Check what's using port 6379 (Redis)
sudo lsof -i :6379
sudo netstat -tlnp | grep 6379

# Check what's using port 3000 (Queue Manager)
sudo lsof -i :3000

# Check what's using port 8188 (Worker)
sudo lsof -i :8188

# Check what's using port 443 (Nginx)
sudo lsof -i :443
```

**If port is in use:**

```bash
# Option 1: Find what's using it and stop
ps aux | grep [process_name]
kill [pid]

# Option 2: Change port in docker-compose.yml
# ports:
#   - "6380:6379"  # Use 6380 instead

# Option 3: Restart Docker
sudo systemctl restart docker
```

### Solution 5: Check Volume Mount Issues

Volumes must exist and be accessible.

```bash
# Check if volume directories exist
ls -la ./data/redis/
ls -la ./data/models/
ls -la ./data/outputs/

# Check permissions
stat ./data/redis/

# Fix permissions if needed
chmod 755 ./data/
chmod 755 ./data/redis/
```

**If mount fails:**

```bash
# Create missing directories
mkdir -p ./data/redis/
mkdir -p ./data/models/
mkdir -p ./data/outputs/

# Fix ownership (if running with specific user)
sudo chown -R $USER:$USER ./data/

# Restart containers
docker-compose down
docker-compose up -d
```

### Solution 6: Rebuild Container Images

Images may be corrupted or outdated.

```bash
# Rebuild specific image
docker-compose build --no-cache [service_name]

# Rebuild all images
docker-compose build --no-cache

# Start after rebuild
docker-compose up -d
```

**Full rebuild from scratch:**

```bash
# Stop everything
docker-compose down

# Remove all images and containers
docker system prune -a

# Rebuild everything
docker-compose build

# Start fresh
docker-compose up -d

# Verify
docker-compose ps
```

### Solution 7: Check Environment Variables

Missing or wrong env vars can prevent startup.

```bash
# Check .env file exists
ls -la .env

# Check required variables are set
grep REDIS_PASSWORD .env
grep DOMAIN .env

# Check Docker has env vars
docker-compose config | grep -A5 "redis:"
```

**If env vars missing:**

```bash
# Copy from example
cp .env.example .env

# Edit and fill in values
nano .env

# Verify syntax
cat .env | grep -E "^[A-Z_]+=" | head -10

# Restart with new vars
docker-compose down
docker-compose up -d
```

### Solution 8: Force Container Recreation

Sometimes cached images or volumes cause issues.

```bash
# Force recreate all containers
docker-compose up -d --force-recreate

# Or for specific service
docker-compose up -d --force-recreate [service_name]

# Or remove and start fresh
docker-compose down -v  # -v removes volumes!
docker-compose up -d
```

**WARNING:** Using `-v` flag deletes volumes! Only use if you're sure you don't need the data.

### Solution 9: Check Docker Daemon Issues

Docker daemon itself may have issues.

```bash
# Check Docker status
sudo systemctl status docker

# Restart Docker daemon
sudo systemctl restart docker

# Wait for restart
sleep 10

# Check it's running
sudo systemctl status docker

# Try starting containers again
docker-compose up -d
```

## Container Lifecycle Troubleshooting

### Container Starts Then Stops

Check exit code to see why it crashed:

```bash
# Check exit code
docker inspect comfy-redis | grep '"ExitCode"'

# Exit codes:
# 0 = Normal exit
# 1 = Generic error
# 2 = Command not found
# 137 = Out of memory (SIGKILL)
# 139 = Segmentation fault

# View full state
docker inspect comfy-redis | grep -A10 '"State"'
```

### Container Hangs (Doesn't Respond)

Force restart if container is stuck:

```bash
# Kill container immediately
docker-compose kill [service_name]

# Wait 5 seconds
sleep 5

# Start fresh
docker-compose up -d [service_name]
```

## Performance and Resource Issues

### Check Container Resource Usage

```bash
# Real-time stats
docker stats

# Detailed stats for one container
docker stats comfy-worker-1

# Historical stats (requires Docker Pro)
docker stats --all
```

**If resource usage too high:**

1. **Reduce memory limit:**
   ```yaml
   worker-1:
     mem_limit: 40g
   ```

2. **Reduce CPU limit:**
   ```yaml
   worker-1:
     cpus: "8"
   ```

3. **Increase memory/CPU on host** if possible

### Monitor Container Health

Enable health checks in docker-compose.yml:

```yaml
redis:
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    timeout: 5s
    retries: 3

queue-manager:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
    interval: 30s
    timeout: 10s
    retries: 3
```

Check health status:

```bash
docker-compose ps
# Look at "Status" column for health status

docker inspect comfy-redis | grep -A5 '"Health"'
```

## Network Issues Between Containers

### Check Container Networking

```bash
# List networks
docker network ls

# Inspect network
docker network inspect comfyui_default

# Check if containers are connected
docker network inspect comfyui_default | grep "comfy-"
```

### Test Connectivity Between Containers

```bash
# From one container, test connection to another
docker-compose exec queue-manager \
  ping -c 3 redis

docker-compose exec worker-1 \
  telnet redis 6379
```

## Log Analysis

### Find and Review Errors

```bash
# Extract all errors across services
docker-compose logs | grep -i "error\|failed\|exception"

# Get errors for specific time period
docker-compose logs --since 10m | grep -i error

# Follow errors in real-time
docker-compose logs -f | grep -i error
```

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `Connection refused` | Port not open or service down | Check firewall, service status |
| `Out of memory` | Not enough RAM | Increase mem_limit or host RAM |
| `File not found` | Missing volume/mount | Create directory, check docker-compose.yml |
| `Address already in use` | Port conflict | Change port or kill conflicting process |
| `Permission denied` | File ownership/permissions | Fix with chmod, chown |
| `Cannot connect to Docker daemon` | Docker not running | `sudo systemctl start docker` |

## Docker Cleanup

**Remove stopped containers:**

```bash
docker container prune
```

**Remove unused images:**

```bash
docker image prune
```

**Remove dangling volumes:**

```bash
docker volume prune
```

**Full system cleanup (CAUTION!):**

```bash
# This removes all unused containers, images, networks, and volumes
docker system prune -a --volumes
```

## Prevention Tips

1. **Monitor disk space** - Keep at least 20% free
2. **Set resource limits** - Prevent runaway processes
3. **Enable health checks** - Auto-restart unhealthy containers
4. **Use restart policies:**
   ```yaml
   restart: unless-stopped
   ```
5. **Regularly update images** - Patch security issues

## Docker Compose Commands Reference

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose stop

# Restart services
docker-compose restart [service_name]

# View logs
docker-compose logs -f [service_name]

# Execute command in container
docker-compose exec [service_name] [command]

# Remove containers
docker-compose down

# Remove containers and volumes
docker-compose down -v

# Rebuild images
docker-compose build --no-cache
```

## Emergency Recovery

**If everything is broken:**

```bash
# 1. Stop everything
docker-compose kill

# 2. Remove containers
docker-compose rm -f

# 3. Clear system
docker system prune -a

# 4. Restart Docker
sudo systemctl restart docker

# 5. Start fresh
docker-compose up -d

# 6. Check status
docker-compose ps
```

## Related Issues

- **Queue not processing** → May be caused by worker container crash, see admin-troubleshooting-queue-stopped.md
- **Redis connection errors** → Container networking issue, see admin-troubleshooting-redis-connection.md
- **Worker out of memory** → Resource limit issue, see admin-troubleshooting-out-of-memory.md
