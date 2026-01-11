**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-11

---

# VPS Deployment Guide (Tier 1: Application Layer)

**Target:** Hetzner VPS at comfy.ahelme.net
**Purpose:** Deploy application layer (nginx, redis, queue-manager, admin, user frontends)
**Prerequisites:** DNS configured, firewall rules set, Docker installed

---

## Dual Nginx Configuration

This deployment supports **two nginx modes** for flexibility:

| Mode | Description | Use Case |
|------|-------------|----------|
| **Container Nginx** | nginx runs in Docker container | Clean room deployments, development, portable setups |
| **Host Nginx** | nginx runs on host OS | Existing host nginx setup, shared hosting, SSL already configured |

**Switching modes:** Set `USE_HOST_NGINX=true` or `false` in `.env`

---

## Current VPS State

✅ **Already Configured:**
- VPS hostname: `mello` at 157.180.76.189
- DNS A records: comfy.ahelme.net → 157.180.76.189
- Firewall (UFW): Nginx Full allowed (ports 80/443)
- Docker: v29.1.4
- Docker Compose: v5.0.1
- Repository cloned: `/home/dev/projects/comfyui`
- Host nginx installed with Let's Encrypt SSL cert:
  - Certificate: `/etc/letsencrypt/live/comfy.ahelme.net/fullchain.pem`
  - Private Key: `/etc/letsencrypt/live/comfy.ahelme.net/privkey.pem`
  - Expiry: 2026-04-10 (89 days remaining)
- **Tailscale VPN:**
  - VPS Tailscale IP: 100.99.216.71
  - Status: Active, connected to tailnet
  - Purpose: Secure Redis access for GPU workers

---

## Security Architecture: Tailscale VPN

**Why Tailscale?**
This deployment uses Tailscale VPN to securely connect GPU workers to VPS Redis, instead of exposing Redis to the public internet.

**Architecture:**
```
GPU Worker (Verda) → Tailscale VPN → VPS Redis
  100.89.38.43           Encrypted       100.99.216.71:6379
                        WireGuard
                         Tunnel
```

**Benefits:**
- ✅ Redis NOT exposed to internet (no public port 6379)
- ✅ Encrypted WireGuard tunnel
- ✅ No firewall complexity (no IP whitelisting needed)
- ✅ Works with any GPU provider (Verda, RunPod, Modal, local)

**Firewall Configuration:**
```bash
# Allowed ports (locked down)
22/tcp      - SSH (rate limited)
80/tcp      - HTTP (redirect to HTTPS)
443/tcp     - HTTPS (nginx)
21115-21119 - RustDesk remote desktop
21116/udp   - RustDesk UDP

# Redis port 6379 - NOT exposed to public internet
# Only accessible via Tailscale VPN at 100.99.216.71:6379
```

---

## Deployment Steps

### Step 1: Configure Environment Variables

**File:** `.env`

**Required changes:**

```bash
# ============================================================================
# NGINX MODE SELECTION
# ============================================================================
# Set to 'true' to use host nginx, 'false' to use Docker nginx container
USE_HOST_NGINX=true

# ============================================================================
# DOMAIN & SSL CONFIGURATION
# ============================================================================
DOMAIN=comfy.ahelme.net

# SSL paths (already configured for Let's Encrypt)
SSL_CERT_PATH=/etc/letsencrypt/live/comfy.ahelme.net/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/comfy.ahelme.net/privkey.pem

# ============================================================================
# SECURITY: GENERATE SECURE PASSWORDS
# ============================================================================
# Generate secure Redis password
REDIS_PASSWORD=$(openssl rand -hex 32)

# Generate secure admin password
ADMIN_PASSWORD=$(openssl rand -base64 24)

# ============================================================================
# VERIFY OTHER SETTINGS
# ============================================================================
NUM_USERS=20
NUM_WORKERS=1  # Start with 1, scale later
REDIS_HOST=redis  # Docker service name
REDIS_PORT=6379
QUEUE_MODE=fifo
ENABLE_PRIORITY=true
```

**Action:**
```bash
cd /home/dev/projects/comfyui

# Update USE_HOST_NGINX
sed -i 's/USE_HOST_NGINX=.*/USE_HOST_NGINX=true/' .env

# Configure Redis to bind to Tailscale IP (VPN-only access)
TAILSCALE_IP=$(tailscale ip -4)
sed -i "s/REDIS_BIND_IP=.*/REDIS_BIND_IP=${TAILSCALE_IP}/" .env
echo "✅ Redis will bind to Tailscale IP: $TAILSCALE_IP"

# Generate and set secure Redis password
REDIS_PASS=$(openssl rand -hex 32)
sed -i "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=${REDIS_PASS}/" .env

# Generate and set secure admin password
ADMIN_PASS=$(openssl rand -base64 24)
sed -i "s/ADMIN_PASSWORD=.*/ADMIN_PASSWORD=${ADMIN_PASS}/" .env

# Verify SSL paths are correct
grep SSL_ .env
```

**Save passwords:**
```bash
# IMPORTANT: Save these credentials securely!
echo "Redis Password: $REDIS_PASS"
echo "Admin Password: $ADMIN_PASS"
# Store in password manager or secure location
```

---

### Step 2: Update docker-compose.yml for Dual Nginx Mode

**File:** `docker-compose.yml`

**Changes needed:**

1. **Make nginx service conditional** on USE_HOST_NGINX:
   ```yaml
   nginx:
     # ... existing config ...
     profiles:
       - container-nginx  # Only starts if --profile container-nginx specified
   ```

2. **Update port bindings based on mode:**

   **When USE_HOST_NGINX=true** (host nginx mode):
   ```yaml
   queue-manager:
     ports:
       - "127.0.0.1:3000:3000"  # Bind to localhost only

   admin:
     ports:
       - "127.0.0.1:8080:8080"  # Bind to localhost only

   # User frontends in docker-compose.override.yml
   user001:
     ports:
       - "127.0.0.1:8188:8188"  # Bind to localhost only
   # ... user002-user020 follow same pattern (ports 8189-8207)
   ```

   **When USE_HOST_NGINX=false** (container nginx mode):
   ```yaml
   queue-manager:
     ports:
       - "3000:3000"  # Accessible from Docker network only (nginx container proxies)

   admin:
     ports:
       - "8080:8080"  # Accessible from Docker network only

   # User frontends - NO host port binding (nginx container proxies)
   user001:
     # NO ports section - only accessible via Docker network
   ```

3. **Keep Redis internal** (no changes needed):
   ```yaml
   redis:
     # NO ports section - internal Docker network only
   ```

**Implementation approach:**
- Create a helper script `scripts/configure-nginx-mode.sh` that modifies docker-compose files based on USE_HOST_NGINX
- OR: Use Docker Compose variable substitution with conditional logic
- OR: Maintain two separate override files and select with -f flag

---

### Step 3: Verify User Frontend Services

**File:** `docker-compose.override.yml`

**Action:**
```bash
# Check if all 20 user services are defined
grep -c "user0" docker-compose.override.yml
# Should output: 20

# Verify port bindings match USE_HOST_NGINX mode
grep -A 2 "user001:" docker-compose.override.yml
```

**Expected structure for each user (when USE_HOST_NGINX=true):**
```yaml
user001:
  build: ./comfyui-frontend
  container_name: comfy-user001
  ports:
    - "127.0.0.1:8188:8188"
  volumes:
    - ./data/models/shared:/app/models
    - ./data/outputs/user001:/app/output
    - ./data/inputs/user001:/app/input
    - ./data/workflows:/app/workflows
  environment:
    - USER_ID=user001
    - QUEUE_MANAGER_URL=http://queue-manager:3000
  networks:
    - comfy-network
  depends_on:
    queue-manager:
      condition: service_healthy

user002:
  # Same pattern, port 8189
  ports:
    - "127.0.0.1:8189:8188"
  # ... continues through user020 on port 8207
```

---

### Step 4: Configure Host Nginx (USE_HOST_NGINX=true)

**File:** `/etc/nginx/sites-available/comfy.ahelme.net`

**Current config** proxies to single backend (127.0.0.1:8188). Replace with multi-service routing.

**Backup existing config:**
```bash
sudo cp /etc/nginx/sites-available/comfy.ahelme.net /etc/nginx/sites-available/comfy.ahelme.net.bak.$(date +%Y%m%d)
```

**New configuration:**

Create the config file with all required routes:

```bash
sudo tee /etc/nginx/sites-available/comfy.ahelme.net > /dev/null << 'NGINX_EOF'
# HTTP → HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name comfy.ahelme.net;
    return 301 https://$host$request_uri;
}

# Main HTTPS server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name comfy.ahelme.net;

    # SSL Configuration
    ssl_certificate     /etc/letsencrypt/live/comfy.ahelme.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/comfy.ahelme.net/privkey.pem;

    # SSL Security (Let's Encrypt recommendations)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;

    # Logging
    access_log /var/log/nginx/comfy.access.log;
    error_log /var/log/nginx/comfy.error.log;

    # Root location - landing page
    location = / {
        return 302 /user001/;  # Redirect to instructor workspace
    }

    # Health check
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }

    # Queue Manager API
    location /api/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # CORS headers
        add_header Access-Control-Allow-Origin "https://comfy.ahelme.net" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type, Authorization" always;

        # Handle preflight
        if ($request_method = OPTIONS) {
            return 204;
        }
    }

    # WebSocket endpoint for Queue Manager
    location /ws {
        proxy_pass http://127.0.0.1:3000/ws;
        proxy_http_version 1.1;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Long timeout for WebSocket
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }

    # Admin Dashboard
    location /admin {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Static outputs (optional - for direct file access)
    location /outputs/ {
        alias /home/dev/projects/comfyui/data/outputs/;
        autoindex off;
        # Optional: Add authentication here
    }

    # User Frontend Routing - user001 through user020
    # Generated via script below

NGINX_EOF
```

**Generate user location blocks:**

```bash
# Append user routing blocks to config
for i in {1..20}; do
  user_num=$(printf "%03d" $i)
  port=$((8187 + i))

  sudo tee -a /etc/nginx/sites-available/comfy.ahelme.net > /dev/null << USER_EOF

    # User ${user_num}
    location /user${user_num}/ {
        proxy_pass http://127.0.0.1:${port}/;
        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";

        # Long timeout for ComfyUI workflows
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
USER_EOF
done

# Close server block
echo "}" | sudo tee -a /etc/nginx/sites-available/comfy.ahelme.net
```

**Test nginx configuration:**
```bash
sudo nginx -t
# Should output: syntax is ok, test is successful
```

---

### Step 5: Build Docker Images

**Action:**
```bash
cd /home/dev/projects/comfyui

# Build all images
docker-compose build

# Verify images built successfully
docker images | grep comfy
```

**Expected output:**
```
comfy-multi-queue-manager   latest   ...
comfy-multi-admin          latest   ...
comfy-multi-user001        latest   ...
# ... etc
```

---

### Step 6: Start Core Services

**Start services in stages for easier debugging:**

**Stage 1: Core infrastructure**
```bash
# Start Redis and Queue Manager
docker-compose up -d redis queue-manager

# Wait for services to be healthy (30 seconds)
sleep 30

# Check status
docker-compose ps redis queue-manager
docker-compose logs --tail=20 queue-manager
```

**Stage 2: Admin Dashboard**
```bash
# Start admin
docker-compose up -d admin

# Verify
docker-compose ps admin
docker-compose logs --tail=10 admin
```

**Stage 3: User Frontends**
```bash
# Start all 20 user frontends
# Option A: Start all at once
docker-compose up -d $(seq -f "user%03g" 1 20 | tr '\n' ' ')

# Option B: Start in batches (recommended for monitoring)
for batch in {1..4}; do
  start=$((($batch - 1) * 5 + 1))
  end=$(($batch * 5))
  echo "Starting users ${start}-${end}..."
  docker-compose up -d $(seq -f "user%03g" $start $end | tr '\n' ' ')
  sleep 10
done

# Verify all running
docker-compose ps | grep user | wc -l
# Should output: 20
```

**Check overall status:**
```bash
# All services should show "Up" or "Up (healthy)"
docker-compose ps

# Check for errors
docker-compose logs --tail=50 | grep -i error
```

---

### Step 7: Reload Host Nginx

**Only if USE_HOST_NGINX=true:**

```bash
# Test configuration
sudo nginx -t

# Reload nginx to apply changes
sudo systemctl reload nginx

# Verify nginx is running
sudo systemctl status nginx

# Check listening ports
sudo netstat -tlnp | grep nginx
# Should show:
# 0.0.0.0:80 (nginx)
# 0.0.0.0:443 (nginx)
```

---

### Step 8: Verification & Testing

#### 8.1 Local Health Checks

```bash
# Health endpoint
curl -k https://localhost/health
# Expected: OK

# Queue Manager API
curl -k https://localhost/api/health
# Expected: {"status":"healthy",...}

# Check all ports are listening
sudo netstat -tlnp | grep -E ':(80|443|3000|8080|8188|8189)'
```

#### 8.2 External Access Tests

From your local machine or browser:

```bash
# Health check
curl https://comfy.ahelme.net/health

# API endpoint
curl https://comfy.ahelme.net/api/health

# Queue status
curl https://comfy.ahelme.net/api/queue/status
```

#### 8.3 Browser Tests

Open in browser:

1. **Admin Dashboard:**
   - URL: https://comfy.ahelme.net/admin
   - Should show login or dashboard
   - Verify real-time updates work

2. **Instructor Workspace:**
   - URL: https://comfy.ahelme.net/user001/
   - ComfyUI interface should load
   - Check browser console for errors

3. **Participant Workspace:**
   - URL: https://comfy.ahelme.net/user002/
   - ComfyUI interface should load
   - Verify isolation (different from user001)

4. **WebSocket Connectivity:**
   - Open browser DevTools → Network tab → WS filter
   - Should see WebSocket connection to /ws
   - Status should be "101 Switching Protocols"

#### 8.4 End-to-End Workflow Test

**Prerequisites:** Need GPU worker connected (see implementation-deployment-verda.md)

1. Open https://comfy.ahelme.net/user001/
2. Load example workflow from sidebar
3. Click "Queue Prompt"
4. Verify:
   - Job appears in admin dashboard
   - Job status shows "pending" → "processing" → "complete"
   - Output image appears in workspace

#### 8.5 Security Verification

```bash
# Verify Redis is bound to Tailscale IP (VPN-only, NOT public)
sudo netstat -tlnp | grep 6379
# Should show: 100.99.216.71:6379 (Tailscale IP)
# ✅ CORRECT: 100.99.216.71:6379 (VPN only)
# ❌ WRONG: 0.0.0.0:6379 (exposed to entire internet)
# ❌ WRONG: 157.180.76.189:6379 (public IP)

# Verify Tailscale is running
tailscale status | grep mello
# Should show: 100.99.216.71  mello  ...

# Verify SSL certificate
echo | openssl s_client -connect comfy.ahelme.net:443 -servername comfy.ahelme.net 2>/dev/null | openssl x509 -noout -dates
# Should show valid dates

# Check firewall
sudo ufw status
# Should show: Nginx Full ALLOW
```

#### 8.6 Isolation Verification

```bash
# Create test file in user001
docker exec comfy-user001 touch /app/output/test-user001.txt

# Verify it doesn't appear in user002
docker exec comfy-user002 ls /app/output/test-user001.txt
# Should show: No such file or directory

# Verify separate output directories
ls -la /home/dev/projects/comfyui/data/outputs/
# Should show: user001/ user002/ ... user020/
```

---

## Troubleshooting

### Issue: Services won't start

**Diagnosis:**
```bash
docker-compose logs <service-name>
docker-compose ps
```

**Common causes:**
- Port already in use: `sudo netstat -tlnp | grep <port>`
- Missing environment variables: Check `.env` file
- Image build failed: Re-run `docker-compose build`

### Issue: Nginx config test fails

**Diagnosis:**
```bash
sudo nginx -t
# Shows exact line with error
```

**Common causes:**
- Syntax error: Check for missing semicolons, braces
- Invalid proxy_pass: Verify ports match docker-compose
- SSL cert path wrong: Verify with `ls -la /etc/letsencrypt/live/comfy.ahelme.net/`

### Issue: Can't access endpoints externally

**Diagnosis:**
```bash
# Test locally first
curl https://localhost/health

# Check firewall
sudo ufw status

# Check DNS
nslookup comfy.ahelme.net
```

**Common causes:**
- Firewall blocking: `sudo ufw allow 'Nginx Full'`
- DNS not propagated: Wait up to 24 hours
- nginx not reloaded: `sudo systemctl reload nginx`

### Issue: WebSocket connections fail

**Diagnosis:**
```bash
# Check nginx error logs
sudo tail -f /var/log/nginx/error.log

# Check browser console for WebSocket errors
```

**Common causes:**
- Missing Upgrade headers in nginx config
- Long timeout not set (proxy_read_timeout)
- Queue Manager not running: `docker-compose ps queue-manager`

### Issue: User frontends return 502 Bad Gateway

**Diagnosis:**
```bash
# Check if container is running
docker-compose ps user001

# Check container logs
docker-compose logs user001

# Test direct access
curl http://127.0.0.1:8188
```

**Common causes:**
- Container not started: `docker-compose up -d user001`
- Wrong port in nginx config: Should be 127.0.0.1:8188-8207
- Container crashed: Check logs for errors

---

## Rollback Procedure

If deployment fails and needs rollback:

```bash
# Stop all containers
docker-compose down

# Restore original nginx config
sudo cp /etc/nginx/sites-available/comfy.ahelme.net.bak.YYYYMMDD /etc/nginx/sites-available/comfy.ahelme.net

# Reload nginx
sudo systemctl reload nginx

# Restore .env if needed
git checkout .env
```

---

## Next Steps

Once VPS (Tier 1) is deployed and verified:

1. ✅ VPS Application Layer Running
2. → **Deploy GPU Worker** (see [implementation-deployment-verda.md](./implementation-deployment-verda.md))
3. → Test end-to-end job execution
4. → Load test with 20 concurrent users
5. → Follow pre-workshop checklist

---

## Quick Reference

**Start all services:**
```bash
docker-compose up -d
```

**Stop all services:**
```bash
docker-compose down
```

**View logs:**
```bash
docker-compose logs -f <service>
```

**Restart service:**
```bash
docker-compose restart <service>
```

**Update nginx config:**
```bash
sudo nano /etc/nginx/sites-available/comfy.ahelme.net
sudo nginx -t
sudo systemctl reload nginx
```

**Check service health:**
```bash
./scripts/status.sh  # If script exists
docker-compose ps
curl https://comfy.ahelme.net/health
```

---

**Related Documentation:**
- [Implementation Plan](./implementation.md) - Phase 8 deployment checklist
- [GPU Deployment Guide](./implementation-deployment-verda.md) - Tier 2 setup
- [Admin Pre-Workshop Checklist](./docs/admin-checklist-pre-workshop.md)
- [Troubleshooting Guide](./docs/admin-troubleshooting.md)

---

**Last Updated:** 2026-01-10
