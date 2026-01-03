# Deployment Guide for comfy.ahelme.net

Quick deployment guide for setting up the ComfyUI Multi-User Platform on your VPS.

## 🚀 Quick Setup (15 minutes)

### Prerequisites Check

Your VPS should have:
- ✅ Docker & Docker Compose installed
- ✅ SSL cert for ahelme.net (already configured for desk.ahelme.net)
- ✅ Ports 80, 443 available (or nginx reverse proxy configured)

### Step 1: Clone & Configure

```bash
# SSH to your VPS
ssh your-vps

# Clone repository
cd /opt
git clone https://github.com/ahelme/comfy-multi.git
cd comfy-multi

# The .env is already configured for comfy.ahelme.net!
# Just update passwords:
nano .env
```

**Update these lines in .env:**
```bash
REDIS_PASSWORD=your_secure_redis_password_here
ADMIN_PASSWORD=your_secure_admin_password_here
```

**Verify SSL cert paths:**
```bash
# Check if certs exist
ls -la /etc/letsencrypt/live/ahelme.net/fullchain.pem
ls -la /etc/letsencrypt/live/ahelme.net/privkey.pem

# If certs are elsewhere, update SSL_CERT_PATH and SSL_KEY_PATH in .env
```

### Step 2: DNS Configuration

Add DNS record for comfy.ahelme.net:

**If using Cloudflare/DNS provider:**
```
Type: A
Name: comfy
Value: [Your VPS IP]
TTL: Auto
Proxy: Optional (orange cloud)
```

**Verify DNS propagation:**
```bash
dig comfy.ahelme.net
# Should show your VPS IP
```

### Step 3: Nginx Reverse Proxy Setup

**Option A: Direct Docker Binding (Recommended for dedicated server)**

If ComfyUI will be the only service:
```bash
# Let Docker bind directly to ports 80/443
# No additional nginx config needed!

# Start the platform
./scripts/start.sh
```

**Option B: Existing Nginx Reverse Proxy (If desk.ahelme.net uses main nginx)**

Add this to your main nginx configuration:

```bash
# Edit main nginx config
sudo nano /etc/nginx/sites-available/comfy.ahelme.net
```

```nginx
# /etc/nginx/sites-available/comfy.ahelme.net
server {
    listen 80;
    server_name comfy.ahelme.net;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name comfy.ahelme.net;

    ssl_certificate /etc/letsencrypt/live/ahelme.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ahelme.net/privkey.pem;

    # Proxy to Docker nginx
    location / {
        proxy_pass https://localhost:8443;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_read_timeout 86400;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/comfy.ahelme.net /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Update docker-compose to use different port
# Edit .env:
nano .env
# Change: NGINX_HTTPS_PORT=8443
```

### Step 4: Start Platform

```bash
# Run setup script
./scripts/setup.sh

# Start all services
./scripts/start.sh
```

**You should see:**
```
✅ All services started successfully!

Access points:
  Landing Page: https://comfy.ahelme.net/
  Admin Dashboard: https://comfy.ahelme.net/admin
  User Workspaces: https://comfy.ahelme.net/user001/ - user020/
  API: https://comfy.ahelme.net/api/

Status: docker-compose ps
Logs: docker-compose logs -f
```

### Step 5: Verify Deployment

```bash
# Run tests
./scripts/test.sh

# Check specific endpoints
curl https://comfy.ahelme.net/health
curl https://comfy.ahelme.net/api/queue/status
```

**Open in browser:**
- Landing page: https://comfy.ahelme.net/
- Admin dashboard: https://comfy.ahelme.net/admin

---

## 🎯 Post-Deployment Steps

### 1. Download Models

```bash
cd data/models/shared/checkpoints/

# SDXL Base (required - ~7GB)
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

# SDXL VAE (recommended - ~350MB)
wget https://huggingface.co/stabilityai/sdxl-vae/resolve/main/sdxl_vae.safetensors

# Check space
df -h
```

### 2. Load Sample Workflows

```bash
cd data/workflows/

# Create a simple text-to-image workflow
# (You can export from ComfyUI or create manually)
```

### 3. Test End-to-End

```bash
# Open user workspace
# Browser: https://comfy.ahelme.net/user001/

# Load a workflow
# Click "Queue Prompt"
# Watch admin dashboard: https://comfy.ahelme.net/admin
```

---

## 📊 Monitoring

### Check Status

```bash
cd /opt/comfy-multi

# System health
./scripts/status.sh

# Live logs
docker-compose logs -f

# Specific service
docker-compose logs -f queue-manager
docker-compose logs -f worker-1
```

### Admin Dashboard

Open: https://comfy.ahelme.net/admin

Monitor:
- ✅ Queue depth
- ✅ Jobs pending/running/completed
- ✅ Worker status
- ✅ Real-time updates

---

## 🔧 Troubleshooting

### Can't access comfy.ahelme.net

```bash
# Check DNS
dig comfy.ahelme.net

# Check nginx
sudo nginx -t
sudo systemctl status nginx

# Check Docker
docker-compose ps

# Check ports
sudo netstat -tulpn | grep -E ':(80|443|8443)'
```

### SSL Certificate Issues

```bash
# Verify cert files
sudo ls -la /etc/letsencrypt/live/ahelme.net/

# Test SSL
curl -vI https://comfy.ahelme.net 2>&1 | grep -i ssl

# If using Certbot, renew
sudo certbot renew
```

### Services Won't Start

```bash
# Check logs
docker-compose logs

# Check .env
cat .env | grep -v "^#" | grep -v "^$"

# Restart
docker-compose down
docker-compose up -d
```

### Port Conflicts

```bash
# If ports 80/443 already in use
# Option 1: Use nginx reverse proxy (see Step 3, Option B)
# Option 2: Use different ports
nano .env
# Set: NGINX_HTTP_PORT=8080
# Set: NGINX_HTTPS_PORT=8443

docker-compose down
docker-compose up -d
```

---

## 🆘 Quick Commands Reference

```bash
# Start platform
./scripts/start.sh

# Stop platform
./scripts/stop.sh

# Check status
./scripts/status.sh

# View logs
docker-compose logs -f

# Restart service
docker-compose restart queue-manager

# Run tests
./scripts/test.sh

# Load test
./scripts/load-test.sh 5 1
```

---

## 🎓 Next Steps

1. **Test the platform** - Submit a job from user001
2. **Load test** - Run `./scripts/load-test.sh 5 1`
3. **Download more models** - SDXL Refiner, LoRAs, etc.
4. **Prepare workflows** - Create workshop-specific workflows
5. **Share access** - Give participants their URLs

---

## 📞 Support

- **Documentation**: See `/docs` directory
- **Troubleshooting**: `docs/troubleshooting.md`
- **GitHub**: https://github.com/ahelme/comfy-multi

---

**Platform configured for: comfy.ahelme.net** ✨

Ready to run your workshop! 🚀
