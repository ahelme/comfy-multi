**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-11

---

# Troubleshooting: Workers Can't Connect to Redis

## Quick Diagnosis

Workers on the remote GPU instance cannot establish a connection to Redis on the VPS. This prevents the queue from working at all since workers can't receive jobs.

## Symptoms

- Worker logs show Redis connection errors
- "Connection refused" or "Connection timed out" in worker logs
- "Cannot reach host" or "Name resolution failed" errors
- Queue Manager can see Redis but workers cannot
- Jobs pile up in queue but never process
- Firewall or network unreachable errors

## Diagnosis Steps

Run these commands from the GPU instance:

```bash
# 1. Test basic connectivity to VPS hostname
nslookup comfy.ahelme.net
ping -c 5 comfy.ahelme.net

# 2. Test Redis port directly (TCP handshake)
telnet comfy.ahelme.net 6379

# 3. Test Redis connectivity with redis-cli
redis-cli -h comfy.ahelme.net -p 6379 -a $REDIS_PASSWORD ping
# Should return: PONG

# 4. Check worker environment variables
env | grep REDIS

# 5. Check worker logs for connection errors
docker-compose logs worker-1 | grep -i "redis\|connection\|refused"
```

## Solutions (Try in Order)

### Solution 1: Verify Environment Variables

Ensure the worker has correct Redis configuration:

**On GPU instance, check `.env`:**

```env
REDIS_HOST=comfy.ahelme.net
REDIS_PORT=6379
REDIS_PASSWORD=<matches VPS password>
```

**Verify the values:**

```bash
grep REDIS .env

# Should match:
echo $REDIS_HOST        # Should be: comfy.ahelme.net
echo $REDIS_PORT        # Should be: 6379
echo $REDIS_PASSWORD    # Should not be empty
```

If values are wrong, update `.env` and restart:

```bash
docker-compose down
docker-compose up -d worker-1
```

### Solution 2: Test DNS Resolution

Redis hostname must resolve to the VPS IP.

```bash
# From GPU instance
nslookup comfy.ahelme.net
dig comfy.ahelme.net

# Should return the VPS IP address (not 127.0.0.1)
```

If DNS fails:
- Check DNS is working: `nslookup 8.8.8.8` (Google DNS)
- Check `/etc/resolv.conf` on GPU instance has valid nameservers
- Verify domain is pointing to correct VPS IP via `dig +short comfy.ahelme.net`

### Solution 3: Test Network Connectivity

Verify TCP connectivity on port 6379.

```bash
# From GPU instance

# Check if port 6379 is reachable
telnet comfy.ahelme.net 6379

# Or using nc (netcat)
nc -zv comfy.ahelme.net 6379

# Check traceroute to VPS
traceroute comfy.ahelme.net
```

If `Connection refused` or `Connection timed out`:
- Network path is broken
- Go to **Solution 4: Check Firewall**

### Solution 4: Check Firewall Rules

VPS must allow inbound connections on port 6379 from GPU instance IP.

**On VPS:**

```bash
# Check firewall status
sudo ufw status

# Get GPU instance public IP
# (Provided by Verda/RunPod console)

# Add firewall rule
sudo ufw allow from [GPU_INSTANCE_IP] to any port 6379

# Verify rule added
sudo ufw status | grep 6379
```

**Alternative: Add rule for entire network**

```bash
# Allow from specific subnet (less secure)
sudo ufw allow from 185.0.0.0/8 to any port 6379

# Or allow from anywhere (NOT recommended)
sudo ufw allow 6379/tcp
```

### Solution 5: Verify Redis Configuration

Redis must be listening on all interfaces (not just localhost).

**On VPS:**

```bash
# Check Redis bind configuration
docker-compose exec redis redis-cli CONFIG GET bind

# Should return: 0.0.0.0 (all interfaces)
# If it returns: 127.0.0.1 (only localhost), Redis needs reconfiguration
```

If Redis only binds to localhost:

**In docker-compose.yml:**

```yaml
redis:
  image: redis:7-alpine
  command: redis-server --bind 0.0.0.0 --requirepass $REDIS_PASSWORD
  ports:
    - "6379:6379"
```

Restart Redis:

```bash
docker-compose down redis
docker-compose up -d redis
```

Verify it's listening on all interfaces:

```bash
sudo netstat -tlnp | grep 6379
# Should show: 0.0.0.0:6379
```

### Solution 6: Verify Redis Password

Worker and VPS must use the same Redis password.

```bash
# On VPS, check current password
docker-compose exec redis redis-cli CONFIG GET requirepass

# On GPU instance, verify REDIS_PASSWORD in .env matches VPS
echo $REDIS_PASSWORD
```

If passwords don't match, update GPU instance `.env`:

```env
REDIS_PASSWORD=<exact password from VPS>
```

Then restart:

```bash
docker-compose restart worker-1
```

### Solution 7: Test Redis Connection Directly

Once network is verified, test with redis-cli:

```bash
# From GPU instance
redis-cli -h comfy.ahelme.net -p 6379 -a $REDIS_PASSWORD ping

# Should return: PONG
```

If this works but worker still can't connect:
- Issue may be with Python Redis library
- Try restarting worker: `docker-compose restart worker-1`
- Check worker logs for specific error

## Troubleshooting Network Issues

### Network Latency

High latency between VPS and GPU can cause timeouts.

```bash
# From GPU instance
ping -c 10 comfy.ahelme.net
# Look at average RTT (should be < 50ms)

# If > 100ms:
traceroute comfy.ahelme.net
# Check if routing is inefficient
```

Typical latencies:
- Same cloud provider: < 10ms
- Different cloud providers: 20-50ms
- Intercontinental: 100-300ms

### Network Throughput

Check if bandwidth is limited.

```bash
# From GPU instance, test download speed from VPS
wget -O /dev/null https://comfy.ahelme.net/health

# Should complete quickly (< 1 second)
```

### Connection Pooling

If many workers connect to same Redis:

```env
# In GPU instance .env, limit connection pool
REDIS_CONNECTION_POOL_MAX_CONNECTIONS=10
```

## Monitoring Connection Health

### Continuous Health Check

```bash
#!/bin/bash
# Run on GPU instance to monitor Redis connection

while true; do
  result=$(redis-cli -h comfy.ahelme.net -p 6379 -a $REDIS_PASSWORD ping 2>&1)
  if [ "$result" = "PONG" ]; then
    echo "✓ $(date): Redis connected"
  else
    echo "✗ $(date): Redis FAILED - $result"
  fi
  sleep 10
done
```

### Check Connection in Logs

```bash
# Monitor worker logs in real-time
docker-compose logs -f worker-1 | grep -i "redis\|connection"
```

## Prevention Tips

1. **Test connection before workshop** - Run full connectivity test
2. **Document configuration** - Keep record of firewall rules and IP addresses
3. **Monitor during workshop** - Watch for disconnection messages in logs
4. **Use static IPs** - If possible, use static IP for GPU instance
5. **Add redundancy** - Plan for Redis failover if possible

## VPS Networking Checklist

- [ ] Redis is running: `docker-compose ps redis`
- [ ] Redis binds to 0.0.0.0: `docker-compose exec redis redis-cli CONFIG GET bind`
- [ ] Port 6379 is open: `sudo netstat -tlnp | grep 6379`
- [ ] Firewall allows GPU IP: `sudo ufw status | grep 6379`
- [ ] Password is set: `docker-compose exec redis redis-cli CONFIG GET requirepass`

## GPU Instance Networking Checklist

- [ ] Environment variables correct: `env | grep REDIS`
- [ ] DNS resolution works: `nslookup comfy.ahelme.net`
- [ ] Port is reachable: `telnet comfy.ahelme.net 6379`
- [ ] Redis password matches: `echo $REDIS_PASSWORD`
- [ ] Worker can connect: `redis-cli -h comfy.ahelme.net -a $REDIS_PASSWORD ping`

## Related Issues

- **Queue not processing** → Caused by worker disconnection, see admin-troubleshooting-queue-stopped.md
- **High latency / slow jobs** → May be network related, see admin-troubleshooting.md
- **Worker won't start** → May prevent Redis connection attempt, see admin-troubleshooting-docker-issues.md
