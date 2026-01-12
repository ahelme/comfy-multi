**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-11

---

# Admin Checklist: Pre-Workshop Preparation

## One Week Before (T-1 Week)

Complete these tasks to verify full system functionality and prepare materials.

### Infrastructure Verification

- [ ] Verify Docker, Docker Compose, and NVIDIA drivers installed on VPS
  ```bash
  docker --version
  docker-compose --version
  nvidia-smi
  ```

- [ ] Verify access to GPU instance (Verda, RunPod, etc.)
  ```bash
  ssh user@[gpu-instance-ip]
  ```

- [ ] Test complete deployment on both VPS and GPU instance
  ```bash
  docker-compose ps  # All services should be "Up"
  ```

### Model Preparation

Download all required models to avoid delays during workshop:

- [x] LTX-2 19B dev model (~10GB fp8 checkpoint)
  ```bash
  # Verify it's in ./data/models/
  ls -lah ./data/models/checkpoints/ | grep -i ltx-2
  ```

- [x] LTX-2 Gemma 3 text encoder (~5GB)
  ```bash
  ls -lah ./data/models/checkpoints/ | grep -i refiner
  ```

- [ ] Any video generation models needed
  ```bash
  ls -lah ./data/models/checkpoints/ | grep -i video
  ```

- [ ] LoRAs and embeddings
  ```bash
  ls -lah ./data/models/loras/
  ls -lah ./data/models/embeddings/
  ```

### SSL Configuration

- [ ] Verify SSL certificate is installed on VPS
  ```bash
  ls -la /etc/ssl/certs/fullchain.pem
  ls -la /etc/ssl/private/privkey.pem
  ```

- [ ] Check certificate validity
  ```bash
  openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -enddate
  # Should not expire within 30 days
  ```

- [ ] Verify .env has correct certificate paths
  ```bash
  grep SSL .env
  ```

### DNS and Network

- [ ] Verify DNS resolution works
  ```bash
  nslookup comfy.ahelme.net
  # Should resolve to VPS IP
  ```

- [ ] Test HTTPS is working
  ```bash
  curl -v https://comfy.ahelme.net/health
  # Should return 200 OK without certificate warnings
  ```

- [ ] Test network connectivity VPS ↔ GPU instance
  ```bash
  # From GPU instance:
  ping comfy.ahelme.net
  redis-cli -h comfy.ahelme.net -p 6379 -a $REDIS_PASSWORD ping
  # Should return PONG
  ```

### User Accounts and Access

- [ ] Set up 20 user accounts: user001 through user020
  ```bash
  # Verify in docker-compose.yml:
  # frontend-user001 through frontend-user020 exist
  ```

- [ ] Prepare admin account and password
  ```bash
  # Secure note with login credentials
  ```

- [ ] Test access to each user workspace
  ```bash
  for i in {001..020}; do
    curl -s https://comfy.ahelme.net/user$i/ | grep -q "ComfyUI" && echo "user$i OK" || echo "user$i FAILED"
  done
  ```

### Workflow Preparation

- [ ] Prepare 3-5 example workflows for participants
  - Simple text-to-image workflow
  - LTX-2 text-to-video workflow
  - Upscaling workflow
  - Any custom workflows

- [ ] Store example workflows in shared location
  ```bash
  # Save to ./data/example-workflows/
  ls -la ./data/example-workflows/
  ```

### Configuration Verification

- [ ] Verify .env file is complete
  ```bash
  grep -E "^[A-Z_]+=" .env | wc -l
  # Should have all required variables
  ```

- [ ] Create backup of .env file
  ```bash
  cp .env .env.backup
  ```

- [ ] Review all configuration values are correct
  ```bash
  cat .env
  # Verify REDIS_PASSWORD, DOMAIN, SSL_CERT_PATH, etc.
  ```

### Load Testing

- [ ] Test system with simulated 20 users
  ```bash
  # Verify all 20 frontends can load simultaneously
  for i in {001..020}; do curl -s https://comfy.ahelme.net/user$i/ > /dev/null &; done
  wait
  ```

- [ ] Queue test job and verify completion
  ```bash
  # Load example workflow in user001
  # Submit job and monitor completion time
  # Should complete in < 2 minutes
  ```

- [ ] Monitor peak resources
  ```bash
  docker stats
  nvidia-smi
  # Note peak GPU memory and CPU usage
  ```

### Documentation Preparation

- [ ] Review admin dashboard features
  ```bash
  # Open https://comfy.ahelme.net/admin
  # Verify all controls work
  ```

- [ ] Prepare participant guide (if not provided)
  ```bash
  # Store in ./docs/participant-guide.md or equivalent
  ```

- [ ] Prepare troubleshooting quick reference
  - Print or display on second monitor during workshop

- [ ] Verify firewall rules allow necessary connections
  ```bash
  sudo ufw status
  # Should allow ports 80, 443, 6379 (from GPU IP), 8188
  ```

## One Day Before (T-1 Day) - Evening Session

Complete these final verification checks before the workshop.

### System Startup and Stability

- [ ] Power up GPU instance and let it stabilize (30 minutes)
  ```bash
  # Check it stays healthy
  watch -n 5 'ssh user@[gpu-ip] nvidia-smi'
  ```

- [ ] Run full system health check
  ```bash
  ./scripts/status.sh
  # All services should show as healthy
  ```

- [ ] Verify clean startup
  ```bash
  docker-compose down
  docker-compose up -d
  docker-compose ps  # All containers "Up"
  ```

### GPU Readiness

- [ ] Check GPU memory availability
  ```bash
  nvidia-smi
  # Should show full VRAM available (79-80GB on H100)
  ```

- [ ] Monitor GPU temperature
  ```bash
  watch -n 1 nvidia-smi
  # Should be < 50°C at idle
  ```

### Service Verification

- [ ] Verify all 20 user workspaces load correctly
  ```bash
  for i in {001..020}; do
    curl -s https://localhost/user$i/ > /dev/null && echo "user$i OK" || echo "user$i FAILED"
  done
  # All should show OK
  ```

- [ ] Load and test example workflows
  ```bash
  # Manually load each example workflow
  # Verify they load without errors
  ```

- [ ] Queue test job and monitor completion
  ```bash
  # Submit a simple job
  # Monitor queue: curl https://comfy.ahelme.net/api/queue/status
  # Verify it processes and completes
  ```

- [ ] Test admin dashboard access
  ```bash
  # Open https://comfy.ahelme.net/admin
  # Verify you can see queue depth, jobs, etc.
  ```

### Data and Backup

- [ ] Export clean database backup
  ```bash
  docker-compose exec redis redis-cli -a $REDIS_PASSWORD SAVE
  cp ./data/redis/dump.rdb ./data/redis/dump.rdb.pre-workshop
  ```

- [ ] Review logs for any warnings
  ```bash
  docker-compose logs | grep -i warning
  # Investigate and resolve any warnings
  ```

### Admin Preparation

- [ ] Prepare printed reference materials
  ```
  - Access URLs for participants
  - Emergency contact numbers
  - Basic troubleshooting steps
  - Admin commands quick reference
  ```

- [ ] Set up monitoring
  ```bash
  # Open terminal with admin dashboard visible
  # Or create dashboard display for workshop room
  ```

- [ ] Arrange workspace
  - Two monitors if possible (one for admin, one for participants)
  - Quick access to notes and documentation
  - SSH access to both VPS and GPU instance ready

- [ ] Review emergency procedures
  ```bash
  # Read admin-troubleshooting.md for common issues
  # Know how to restart services quickly
  # Know how to cancel stuck jobs
  ```

- [ ] Get adequate sleep! You'll need to be sharp during the workshop.

## One Hour Before (T-1 Hour) - Final Checks

Run these final checks in the hour before participants arrive.

### Access Verification

- [ ] SSH to VPS and verify access
  ```bash
  ssh desk
  # Should connect immediately
  ```

- [ ] SSH to GPU instance and verify access
  ```bash
  ssh user@[gpu-instance]
  # Should connect immediately
  ```

### Final Health Check

- [ ] Run system health check
  ```bash
  ./scripts/status.sh
  # All services should be healthy
  ```

- [ ] Verify all services are running
  ```bash
  docker-compose ps
  # All containers should show "Up"
  ```

### GPU Readiness

- [ ] Check GPU is ready for computation
  ```bash
  nvidia-smi
  # Should show full VRAM available (no lingering processes)
  ```

- [ ] Check GPU temperature is normal
  ```bash
  # Should be < 40°C at idle
  ```

### Workshop Access

- [ ] Test instructor workspace (user001)
  ```bash
  # Open https://comfy.ahelme.net/user001/
  # Load a workflow and queue a test job
  # Verify it completes in < 2 minutes
  ```

- [ ] Test participant user access
  ```bash
  # Pick a random user (e.g., user012)
  # Open https://comfy.ahelme.net/user012/
  # Verify page loads without errors
  ```

### Health Checks

- [ ] Verify health check endpoint is responsive
  ```bash
  curl https://comfy.ahelme.net/health
  # Should return 200 OK with status
  ```

- [ ] Check queue is empty and ready
  ```bash
  curl https://comfy.ahelme.net/api/queue/status
  # Should show 0 pending jobs
  ```

### Admin Dashboard

- [ ] Open admin dashboard in separate tab/window
  ```bash
  https://comfy.ahelme.net/admin
  # Should load without errors
  # Test all controls work
  ```

- [ ] Verify you can see real-time queue updates
  ```bash
  # Open dashboard, monitor queue in real-time
  ```

### Participant Communication

- [ ] Share access information with participants
  ```
  Base URLs:
  https://comfy.ahelme.net/user001 (Instructor)
  https://comfy.ahelme.net/user002 through user020 (Participants)
  ```

- [ ] Have backup plan ready
  ```
  - Fallback URLs (standalone instances if available)
  - Phone/Slack numbers for issues
  - Secondary device access instructions
  ```

### Final Readiness

- [ ] Confirm all services are stable and ready
- [ ] Verify you have access to all admin tools
- [ ] Confirm monitoring and logging are set up
- [ ] Ensure you can quickly cancel/restart jobs if needed
- [ ] Ready to begin workshop when participants arrive

---

## Troubleshooting During Pre-Workshop Setup

### If a test fails, see:

- **DNS resolution fails** → Check domain provider settings
- **HTTPS certificate error** → See admin-troubleshooting-ssl-cert-issues.md
- **User workspace won't load** → Restart frontend container: `docker-compose restart frontend-user00X`
- **Test job won't process** → See admin-troubleshooting-queue-stopped.md
- **GPU not accessible** → Check NVIDIA drivers: `nvidia-smi`
- **Redis connection fails** → See admin-troubleshooting-redis-connection.md

### Quick Recovery Commands

```bash
# Restart everything
docker-compose down && docker-compose up -d

# Check logs for errors
docker-compose logs | grep -i error

# View real-time logs
docker-compose logs -f
```
