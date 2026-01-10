# Admin Workshop Checklist

## Pre-Workshop Checklist

### T-1 Week Before

- [ ] Verify all dependencies are installed (Docker, Docker Compose, NVIDIA drivers)
- [ ] Test complete deployment on both VPS and GPU instance
- [ ] Download all required models:
  - [ ] SDXL Base (50GB)
  - [ ] SDXL Refiner (24GB) - if using
  - [ ] Any video models needed
  - [ ] LoRAs and embeddings
- [ ] Verify SSL certificate is installed on VPS
- [ ] Test DNS resolution (comfy.ahelme.net → VPS IP)
- [ ] Prepare 3-5 example workflows for participants
- [ ] Set up user accounts: user001 through user020
- [ ] Test network connectivity: VPS ↔ GPU instance
- [ ] Create backup of .env file
- [ ] Prepare admin account and password
- [ ] Review admin dashboard features
- [ ] Test load with simulated 20 users
- [ ] Prepare documentation for participants (participant guide if available)
- [ ] Verify firewall rules allow connections

### T-1 Day Before (Evening)

- [ ] Power up GPU instance and let it stabilize (30 minutes)
- [ ] Run full system health check: `./scripts/status.sh`
- [ ] Restart all services to verify clean startup:
  ```bash
  docker-compose down
  docker-compose up -d
  ```
- [ ] Check GPU memory availability: `nvidia-smi`
- [ ] Verify all 20 user workspaces load: `for i in {001..020}; do curl -s https://localhost/user$i/ > /dev/null && echo "user$i OK"; done`
- [ ] Load and test example workflows
- [ ] Queue test job and verify completion
- [ ] Test admin dashboard: `https://comfy.ahelme.net/admin`
- [ ] Export clean database backup:
  ```bash
  docker-compose exec redis redis-cli -a $REDIS_PASSWORD SAVE
  ```
- [ ] Review logs for any warnings: `docker-compose logs | grep -i warning`
- [ ] Prepare printout of:
  - Access URLs
  - Emergency contacts
  - Basic troubleshooting steps
- [ ] Set up monitoring (keep terminal/dashboard visible during workshop)
- [ ] Get good sleep! 😴

### T-1 Hour Before (Final Checks)

- [ ] SSH to VPS: `ssh desk` and verify access
- [ ] SSH to GPU instance: `ssh user@your-gpu-instance` and verify access
- [ ] Run final health check:
  ```bash
  ./scripts/status.sh
  ```
- [ ] Verify services are running:
  ```bash
  docker-compose ps
  # All containers should show "Up"
  ```
- [ ] Check GPU is ready:
  ```bash
  nvidia-smi  # Should show available VRAM
  ```
- [ ] Test instructor workspace (user001):
  ```bash
  # Open https://comfy.ahelme.net/user001/
  # Load a workflow and queue a test job
  # Verify it completes in < 2 minutes
  ```
- [ ] Open admin dashboard in separate tab/window:
  ```bash
  https://comfy.ahelme.net/admin
  ```
- [ ] Verify health check endpoint is responsive:
  ```bash
  curl https://comfy.ahelme.net/health
  ```
- [ ] Test participant user access:
  ```bash
  # Pick a random user (e.g., user012)
  # Open https://comfy.ahelme.net/user012/
  # Verify page loads
  ```
- [ ] Share access information with participants:
  - Base URL: https://comfy.ahelme.net/user001 through user020
  - Username if needed (usually email or registration code)
- [ ] Have backup plan ready (fallback URLs, phone numbers, etc.)

---

## During Workshop

### First Hour

- [ ] Monitor admin dashboard continuously
- [ ] Watch for any 404 errors or connection issues
- [ ] Verify jobs are queuing and processing
- [ ] Keep queue depth < 10 jobs
- [ ] Be ready to assist participants with technical issues
- [ ] Monitor GPU memory (should not exceed 80%)
- [ ] Note any errors or unusual activity

### Ongoing Monitoring

**Every 5-10 minutes:**
- [ ] Check admin dashboard queue depth
- [ ] Look for stuck or failed jobs
- [ ] Monitor GPU memory usage
- [ ] Verify all services are running

**Every 30 minutes:**
- [ ] Check system health: `./scripts/status.sh`
- [ ] Review logs for errors:
  ```bash
  docker-compose logs worker-1 | tail -20
  ```
- [ ] Verify worker is responsive
- [ ] Check if any participants need assistance

### Common Tasks During Workshop

#### Cancel a Stuck Job

1. Identify job in admin dashboard (running for > 15 minutes)
2. Click **✕ Cancel** button
3. Inform participant their job was cancelled (free GPU memory)
4. Suggest they resubmit with adjusted parameters

#### Prioritize Instructor Demo

1. Queue demo job from user001
2. Open admin dashboard
3. Click **⚡ Prioritize** on your job
4. Job moves to front of queue

#### Help Participant with Workflow

1. Ask for their user ID (e.g., user012)
2. Open their workspace: `https://comfy.ahelme.net/user012/`
3. Review their workflow
4. Suggest adjustments (batch size, steps, resolution)
5. Have them re-queue job

#### Monitor Queue Depth Growing

**If pending > 15:**
1. Check job execution times are normal
2. Look for stuck jobs and cancel them
3. Consider adding second worker if available
4. Inform participants about queue wait times

#### Handle GPU Memory Issues

**If GPU memory near 80%:**
1. Check what's consuming memory: `nvidia-smi`
2. Cancel lowest-priority job to free memory
3. Restart worker if memory not freeing:
   ```bash
   docker-compose restart worker-1
   ```

### Emergency Procedures

#### If System Goes Down

1. Immediately notify participants
2. Note the time and last known status
3. Start recovery:
   ```bash
   docker-compose restart queue-manager
   docker-compose restart worker-1
   ```
4. Wait 30 seconds
5. Verify recovery: `./scripts/status.sh`
6. Resume workshop

#### If GPU Instance Crashes

1. Notify participants (workshop paused)
2. Power cycle GPU instance (via Verda/RunPod console)
3. Wait 2-3 minutes for instance to restart
4. SSH to verify it's back up
5. Verify Redis connection works
6. Resume workshop

#### If VPS Goes Down (Nginx/Frontends Down)

1. SSH to VPS (or console access if SSH down)
2. Restart docker:
   ```bash
   sudo systemctl restart docker
   docker-compose up -d
   ```
3. Verify: `docker-compose ps`
4. Resume workshop

#### Complete System Failure

1. Notify participants immediately
2. Provide fallback:
   - Standalone ComfyUI instances
   - RunPod/Modal serverless links
   - Manual GPU access instructions
3. Document what happened for post-mortem

---

## Participant Support During Workshop

### Common Participant Issues

**"My workspace won't load"**
- Check user001-user020 frontends are running: `docker-compose ps | grep frontend`
- Restart that user's frontend: `docker-compose restart frontend-user00X`
- Have participant refresh browser

**"My job is stuck"**
- Check admin dashboard for their job status
- If stuck > 10 minutes, cancel it
- Have them resubmit with smaller settings

**"How long will my job take?"**
- Use history from admin dashboard
- Typical times:
  - SDXL text-to-image: 20-60 seconds
  - SDXL with refiner: 60-120 seconds
  - Video generation: 3-10 minutes

**"Can I upload my own model?"**
- Check if model uploads are enabled in .env
- If enabled, provide clear instructions
- Monitor disk space usage

**"Can you prioritize my job?"**
- Use admin dashboard **⚡ Prioritize** feature
- Reserve for instructors/important demos only
- Explain to participant why they need to wait

### Collect Feedback During Workshop

- Note any technical issues that arise
- Ask participants about their experience
- Observe workflow patterns and pain points
- Track which models are most popular

---

## Post-Workshop Procedures

### Immediate (During Last Hour)

- [ ] Stop accepting new jobs (inform participants)
- [ ] Clear admin priority queue for final completions
- [ ] Monitor remaining jobs to completion
- [ ] Note completion time and total jobs processed

### Short Term (Within 1 Hour of End)

```bash
# Export user outputs for participants
tar -czf outputs-backup-$(date +%Y%m%d-%H%M%S).tar.gz data/outputs/

# Export complete logs for analysis
docker-compose logs > workshop-logs-$(date +%Y%m%d-%H%M%S).txt

# Export database snapshot
docker-compose exec redis redis-cli -a $REDIS_PASSWORD SAVE
```

### Backup and Archive

```bash
# Backup everything important
tar -czf workshop-backup-$(date +%Y%m%d).tar.gz \
  data/outputs/ \
  workshop-logs-*.txt \
  .env.backup

# Move to safe location
mv workshop-backup-*.tar.gz /secure/backup/location/
```

### Collect Metrics

```bash
# Generate report
echo "=== Workshop Report ===" > workshop-report.md
echo "Date: $(date)" >> workshop-report.md
echo "" >> workshop-report.md

# Total jobs processed
echo "## Statistics" >> workshop-report.md
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ZCARD queue:completed >> workshop-report.md
```

### System Cleanup

```bash
# Optional: Stop services (preserve data)
docker-compose stop

# Or shut down completely
docker-compose down

# Clean up large temporary files
docker system prune -a
```

### Post-Workshop Analysis

- [ ] Review logs for errors and warnings
- [ ] Count total jobs completed and failed
- [ ] Calculate average job duration
- [ ] Identify peak queue depth and times
- [ ] Note any GPU memory issues
- [ ] Document what worked well
- [ ] Document what needs improvement

### Create Workshop Report

Use this template:

```markdown
# Workshop Report - [Date]

## Participants
- Total: 20
- Attended: [X]
- Dropouts: [X]

## System Performance
- Total jobs submitted: [X]
- Successfully completed: [X]
- Failed: [X]
- Success rate: [X]%

## Timing
- Workshop duration: [X] hours
- Average job time: [X] seconds
- Peak queue depth: [X]
- Longest job: [X] minutes

## Issues Encountered
1. [Issue 1 and resolution]
2. [Issue 2 and resolution]
3. [Issue 3 and resolution]

## GPU Performance
- Model: H100 80GB
- Peak memory usage: [X]%
- Temperature: [X]°C
- Any thermal throttling: [Yes/No]

## Network Performance
- Latency VPS ↔ GPU: [X]ms
- Connection stability: [Stable/Issues]
- Any timeouts: [Yes/No]

## Participant Feedback Summary
- [General feedback themes]
- [Most popular features]
- [Most requested improvements]

## Recommendations for Next Time
1. [Improvement 1]
2. [Improvement 2]
3. [Improvement 3]

## Files Generated
- Logs: workshop-logs-*.txt
- Outputs backup: outputs-backup-*.tar.gz
- Full backup: workshop-backup-*.tar.gz
```

### Share Outputs with Participants

- [ ] Create download link for their outputs
- [ ] Include instructions for accessing results
- [ ] Provide feedback form/survey link
- [ ] Send thank you message

---

## Quick Reference During Workshop

### Essential Commands

```bash
# System status
./scripts/status.sh

# View admin dashboard
https://comfy.ahelme.net/admin

# Check GPU
nvidia-smi

# View worker logs
docker-compose logs worker-1 | tail -20

# Cancel a job (via API)
curl -X DELETE https://comfy.ahelme.net/api/jobs/{job_id}

# Restart worker
docker-compose restart worker-1

# Restart everything
docker-compose restart
```

### Key URLs

| URL | Purpose |
|-----|---------|
| `https://comfy.ahelme.net/user001` | Instructor workspace |
| `https://comfy.ahelme.net/user002-user020` | Participant workspaces |
| `https://comfy.ahelme.net/admin` | Admin dashboard |
| `https://comfy.ahelme.net/health` | System health check |
| `https://comfy.ahelme.net/api/queue/status` | Queue status API |

### SSH Commands

```bash
# VPS (Hetzner)
ssh desk

# GPU Instance (Verda/RunPod)
ssh user@your-gpu-instance
```

---

## Troubleshooting Quick Links

For detailed troubleshooting, see **admin-troubleshooting.md**:

- **Queue not processing** → Check worker logs
- **User can't access** → Restart frontend container
- **Out of memory** → Cancel jobs, reduce batch size
- **GPU issues** → Check nvidia-smi
- **SSL errors** → Verify certificate paths
- **Redis connection** → Check firewall rules

For more information, see:
- **admin-setup-guide.md** - Initial setup
- **admin-dashboard.md** - Monitoring tools
- **admin-security.md** - Security practices
- **admin-guide.md** - Quick reference
