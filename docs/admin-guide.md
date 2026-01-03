# ComfyUI Workshop - Admin Guide

This guide is for workshop instructors and administrators managing the ComfyUI Multi-User Platform.

## 🎯 Quick Reference

**Health Check**: `https://comfy.ahelme.net/health` *(Real-time system status)*
**Admin Dashboard**: `https://comfy.ahelme.net/admin`
**API Endpoint**: `https://comfy.ahelme.net/api/`
**SSH Access**: `ssh user@your-verda-instance`

## 🚀 Pre-Workshop Setup

### 1. Initial Deployment

**On Verda H100 Instance:**

```bash
# Clone repository
git clone https://github.com/ahelme/comfy-multi.git
cd comfy-multi

# Run setup
./scripts/setup.sh

# Edit configuration
nano .env

# Start services
./scripts/start.sh
```

### 2. Configuration Checklist

Edit `.env` and configure:

```env
# Domain & SSL
DOMAIN=workshop.ahelme.net
SSL_CERT_PATH=/etc/ssl/certs/fullchain.pem
SSL_KEY_PATH=/etc/ssl/private/privkey.pem

# Security
REDIS_PASSWORD=<generate-secure-password>
ADMIN_PASSWORD=<generate-secure-password>

# Queue Settings
QUEUE_MODE=fifo                 # or round_robin
ENABLE_PRIORITY=true            # Allow instructor override
NUM_WORKERS=1                   # Start with 1
NUM_USERS=20                    # Workshop size

# GPU Settings
WORKER_GPU_MEMORY_LIMIT=70G     # H100 has 80GB
JOB_TIMEOUT=3600               # 1 hour max per job
```

### 3. Download Models

**Required models for workshop:**

```bash
cd data/models/shared/

# SDXL Base (required)
wget https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0.safetensors

# SDXL Refiner (optional)
wget https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/sd_xl_refiner_1.0.safetensors

# Video models (if doing video workshop)
# LTX-Video, HunyuanVideo, or AnimateDiff
```

**Model paths:**
- Checkpoints: `data/models/shared/checkpoints/`
- VAE: `data/models/shared/vae/`
- LoRAs: `data/models/shared/loras/`

### 4. Prepare Workflows

**Create workshop templates:**

```bash
cd data/workflows/

# Copy example workflows
cp /path/to/your/workflows/*.json .

# Name clearly:
# - 01_intro_text_to_image.json
# - 02_advanced_img2img.json
# - 03_video_generation.json
```

### 5. Test Before Workshop

**System health check:**

```bash
# Script-based check
./scripts/status.sh

# Web-based check (beautiful dashboard!)
# Open: https://comfy.ahelme.net/health
```

**Test workflow:**
1. Open `https://your-domain/user001/`
2. Load example workflow
3. Queue a test job
4. Verify completion in admin dashboard

**Load test (optional):**
```bash
# Simulate 20 concurrent users
for i in {1..20}; do
  curl -X POST https://your-domain/api/jobs \
    -H "Content-Type: application/json" \
    -d "{\"user_id\": \"user$(printf '%03d' $i)\", \"workflow\": {...}}" &
done
```

## 🎛️ Admin Dashboard

### Accessing the Dashboard

**URL**: `https://your-domain/admin`

**Features:**
- Real-time queue visualization
- Job status monitoring (pending, running, completed, failed)
- Worker status indicators
- Job controls (cancel, prioritize)

### Dashboard Sections

#### 📊 Statistics Cards

- **Pending**: Jobs waiting in queue
- **Running**: Currently processing
- **Completed**: Successfully finished
- **Failed**: Errors encountered

#### 📋 Job Queue Panel

Each job shows:
- **Job ID**: Unique identifier (first 8 chars displayed)
- **User**: Which participant submitted it
- **Status**: Current state (pending/running/completed/failed)
- **Position**: Queue position (if pending)
- **Worker**: Which GPU worker is processing (if running)
- **Error**: Error message (if failed)

**Actions:**
- **⚡ Prioritize**: Move to front of queue (pending jobs only)
- **✕ Cancel**: Stop job execution

#### 🖥️ Workers Panel

Shows status of GPU workers:
- **Green indicator**: Worker active and processing
- **Gray indicator**: Worker idle
- **Worker ID**: Unique worker identifier
- **Current Job**: Job being processed (if busy)

### Common Admin Tasks

#### Cancel a Stuck Job

1. Identify job in dashboard (look for long-running jobs)
2. Click **✕ Cancel** button
3. Confirm cancellation

**Or via API:**
```bash
curl -X DELETE https://your-domain/api/jobs/{job_id}
```

#### Prioritize Instructor Demo

**Scenario**: You need to demo a feature immediately

1. Queue your job from `/user001/` (instructor workspace)
2. Open admin dashboard
3. Find your job in pending queue
4. Click **⚡ Prioritize**
5. Job moves to front of queue

**Or via API:**
```bash
curl -X PATCH https://your-domain/api/jobs/{job_id}/priority \
  -H "Content-Type: application/json" \
  -d '{"priority": 0}'
```

#### Clear Failed Jobs

**Via docker-compose:**
```bash
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ZREMRANGEBYSCORE queue:failed 0 +inf
```

## 📊 Monitoring & Troubleshooting

### Health Checks

**Check all services:**
```bash
./scripts/status.sh
```

**Manual checks:**
```bash
# Queue Manager
curl https://your-domain/api/queue/status

# Redis
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping

# Worker
docker-compose logs worker-1 | tail -20

# Nginx
docker-compose logs nginx | grep ERROR
```

### Common Issues

#### Queue Not Processing

**Symptoms**: Jobs stuck in "pending" forever

**Diagnosis:**
```bash
# Check worker logs
docker-compose logs worker-1

# Check queue manager
docker-compose logs queue-manager

# Check Redis connectivity
docker-compose exec queue-manager curl http://redis:6379
```

**Solutions:**
1. Restart worker: `docker-compose restart worker-1`
2. Restart queue manager: `docker-compose restart queue-manager`
3. Check GPU availability: `nvidia-smi`

#### Out of Memory (OOM)

**Symptoms**: Worker crashes, jobs fail with CUDA errors

**Diagnosis:**
```bash
# Check GPU memory
nvidia-smi

# Check worker memory limit
docker inspect comfy-worker-1 | grep -i memory
```

**Solutions:**
1. Reduce batch size in workflows
2. Use smaller models
3. Increase worker memory limit in `.env`:
   ```env
   WORKER_GPU_MEMORY_LIMIT=75G
   ```
4. Clear GPU cache:
   ```bash
   docker-compose restart worker-1
   ```

#### User Can't Access Workspace

**Symptoms**: 404 error or blank page

**Diagnosis:**
```bash
# Check nginx logs
docker-compose logs nginx | grep "user0XX"

# Check frontend container
docker-compose ps | grep user0XX

# Test nginx routing
curl -k https://localhost/user001/
```

**Solutions:**
1. Verify frontend container is running
2. Check nginx user routing configuration
3. Restart nginx: `docker-compose restart nginx`

#### SSL Certificate Errors

**Symptoms**: Browser shows "Not Secure" or certificate errors

**Diagnosis:**
```bash
# Verify certificate files
ls -la /path/to/ssl/cert.pem
ls -la /path/to/ssl/key.pem

# Check certificate expiry
openssl x509 -in /path/to/ssl/cert.pem -noout -enddate

# Test SSL
curl -vI https://your-domain 2>&1 | grep -i ssl
```

**Solutions:**
1. Verify SSL paths in `.env`
2. Check certificate permissions (must be readable)
3. Renew certificate if expired
4. Restart nginx: `docker-compose restart nginx`

### Performance Tuning

#### Optimize Queue Throughput

**FIFO mode**: Best for workshops (predictable, fair)
```env
QUEUE_MODE=fifo
```

**Round-robin**: Better for unequal job sizes
```env
QUEUE_MODE=round_robin
```

#### Scale Workers

**Add a second worker:**

1. Edit `docker-compose.yml`:
```yaml
  worker-2:
    build:
      context: ./comfyui-worker
      dockerfile: Dockerfile
    container_name: comfy-worker-2
    environment:
      - WORKER_ID=worker-2
      # ... same as worker-1
```

2. Restart:
```bash
docker-compose up -d
```

**Note**: Requires 2 GPUs or careful memory management!

#### Adjust Job Timeouts

**For long video generations:**
```env
JOB_TIMEOUT=7200  # 2 hours
```

**For quick tests:**
```env
JOB_TIMEOUT=900   # 15 minutes
```

## 🔧 Management Scripts

### ./scripts/start.sh

**Purpose**: Start all services

**What it does:**
1. Validates `.env` configuration
2. Creates required directories
3. Starts docker-compose stack
4. Displays access URLs

**Usage:**
```bash
./scripts/start.sh
```

### ./scripts/stop.sh

**Purpose**: Stop all services

**Options:**
```bash
# Stop services (preserve data)
./scripts/stop.sh

# Stop and remove volumes (DANGER: deletes all data!)
./scripts/stop.sh --remove-volumes
```

### ./scripts/status.sh

**Purpose**: System health check

**Output:**
- Service status (running/stopped)
- Queue depth (pending/running/completed)
- Worker status
- Resource usage (CPU, memory, GPU)

**Usage:**
```bash
./scripts/status.sh
```

### ./scripts/add-user.sh

**Purpose**: Add a new user (21+)

**Usage:**
```bash
./scripts/add-user.sh user021
```

**What it does:**
1. Creates user frontend container
2. Updates nginx routing
3. Creates user output directory
4. Reloads nginx

### ./scripts/remove-user.sh

**Purpose**: Remove a user

**Usage:**
```bash
./scripts/remove-user.sh user021
```

**Warning**: Preserves user data by default!

### ./scripts/list-users.sh

**Purpose**: List all users and their stats

**Output:**
- User ID
- Container status
- Jobs completed
- Disk usage

**Usage:**
```bash
./scripts/list-users.sh
```

### ./scripts/deploy-verda.sh

**Purpose**: Deploy to Verda instance

**Usage:**
```bash
./scripts/deploy-verda.sh user@your-verda-instance.com
```

**What it does:**
1. Creates deployment package
2. Uploads to Verda instance
3. Extracts and runs setup
4. Optionally starts services

## 📈 Workshop Day Checklist

### Morning (1 hour before)

- [ ] SSH to Verda instance
- [ ] Run `./scripts/status.sh` - verify all services healthy
- [ ] Check GPU: `nvidia-smi` - verify available memory
- [ ] Test user001 workspace - load and queue test job
- [ ] Check admin dashboard - verify real-time updates
- [ ] Prepare instructor workspace (user001) with demo workflows
- [ ] Share access URLs with participants

### During Workshop

- [ ] Monitor admin dashboard for stuck jobs
- [ ] Watch for high queue depth (>10 jobs)
- [ ] Check GPU memory usage periodically
- [ ] Be ready to prioritize instructor demos
- [ ] Cancel failed/stuck jobs promptly

### After Workshop

- [ ] Export user outputs: `tar -czf outputs-backup.tar.gz data/outputs/`
- [ ] Review logs for errors: `docker-compose logs > workshop-logs.txt`
- [ ] Collect metrics:
  - Total jobs completed
  - Average queue wait time
  - Failed jobs count
- [ ] Stop services: `./scripts/stop.sh`
- [ ] Backup database: `docker-compose exec redis redis-cli -a $REDIS_PASSWORD SAVE`

## 🔐 Security Best Practices

### Access Control

- Use strong `REDIS_PASSWORD` (generate with `openssl rand -base64 32`)
- Use strong `ADMIN_PASSWORD`
- Restrict SSH access to your IP only
- Keep SSL certificates up to date

### Monitoring

```bash
# Monitor failed login attempts (if authentication enabled)
docker-compose logs admin | grep -i "failed\|unauthorized"

# Monitor unusual activity
docker-compose logs queue-manager | grep -i "error\|warning"
```

### Backups

**Before workshop:**
```bash
# Backup configuration
cp .env .env.backup
tar -czf config-backup.tar.gz nginx/ redis/ .env

# Backup models
tar -czf models-backup.tar.gz data/models/
```

**After workshop:**
```bash
# Backup all user data
tar -czf workshop-outputs-$(date +%Y%m%d).tar.gz data/outputs/
```

## 📞 Emergency Contacts

**If something goes wrong:**

1. **System down**: Restart all services
   ```bash
   docker-compose down && docker-compose up -d
   ```

2. **GPU issues**: Check NVIDIA drivers
   ```bash
   nvidia-smi
   sudo systemctl restart docker
   ```

3. **Complete failure**: Fallback plan
   - Provide participants with standalone ComfyUI links
   - Use RunPod/Modal serverless as backup

## 📊 Post-Workshop Report Template

```markdown
# Workshop Report - [Date]

## Statistics
- Participants: 20
- Total jobs:
- Successful:
- Failed:
- Average wait time:
- Peak queue depth:

## Issues Encountered
-

## Participant Feedback
-

## System Performance
- GPU utilization:
- Uptime:
- Errors:

## Improvements for Next Time
-
```

---

**Good luck with your workshop!** 🎓

For additional support, consult the troubleshooting section or check GitHub Issues.
