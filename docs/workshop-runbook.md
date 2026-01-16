**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-02
**Doc Updated:** 2026-01-11

---

# Workshop Day Runbook

Complete checklist and procedures for running a successful ComfyUI workshop.

## 📅 Timeline Overview

```
T-1 week:   Final testing & model downloads
T-3 days:   Deploy to Verda, smoke test
T-1 day:    Final verification, prepare demo workflows
T-0 (Day):  Workshop execution
T+1:        Backup & cleanup
```

---

## 🔧 T-1 Week: Pre-Workshop Preparation

### System Deployment

**Verda Instance Setup:**
```bash
# 1. Deploy to Verda
./scripts/deploy-verda.sh user@your-verda-instance

# 2. SSH to instance
ssh user@your-verda-instance
cd /opt/comfyui-workshop

# 3. Configure .env
nano .env

# 4. Place SSL certificates
mkdir -p /etc/ssl/comfy/
# Upload cert.pem and key.pem

# 5. Models are pre-loaded on SFS from R2 backup
# See docs/admin-backup-restore.md for model restore

# 6. Start services
./scripts/start.sh
```

### Model Downloads

**Workshop models (pre-loaded on SFS):**
- ✅ LTX-2 19B Checkpoint (~27GB) - `ltx-2-19b-dev-fp8.safetensors`
- ✅ Gemma 3 Text Encoder (~20GB) - `gemma_3_12B_it.safetensors`

**Total:** ~47GB (backed up to Cloudflare R2)

**Location:** `/mnt/models/` (SFS mount)

See [Admin Backup & Restore](./admin-backup-restore.md) for model download from R2.

### Workflow Preparation

**Create workshop workflows:**

1. **ltx2_text_to_video.json**
   - LTX-2 text-to-video generation
   - Pre-filled with example prompt
   - Steps: 20, duration: 4 sec

2. **ltx2_image_to_video.json**
   - Image-to-video workflow
   - Upload starting image
   - Animate with LTX-2

3. **ltx2_advanced.json** (optional)
   - Multi-stage workflow
   - Demonstrates node connections

**Save to:** `data/workflows/`

---

## 🧪 T-3 Days: Testing & Validation

### Run Full Test Suite

```bash
# Integration tests
./scripts/test.sh

# Load test (20 concurrent users)
./scripts/load-test.sh 20 1

# Smoke test each user workspace
for i in {1..20}; do
    curl -k https://your-domain/user$(printf '%03d' $i)/ || echo "Failed: user$i"
done
```

### Verify Checklist

- [ ] All 20 user workspaces accessible
- [ ] Admin dashboard loads and updates in real-time
- [ ] Can submit job and see it complete
- [ ] Outputs appear in correct user directory
- [ ] Queue handles 20 concurrent jobs
- [ ] WebSocket updates work
- [ ] SSL certificate valid
- [ ] Models load correctly in ComfyUI
- [ ] Workflows pre-loaded in each workspace

### Performance Baseline

**Measure typical job times:**
```bash
# Submit test job
JOB_ID=$(curl -s -X POST http://localhost:3000/api/jobs \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","workflow":{...}}' | jq -r '.id')

# Monitor completion time
time curl -s http://localhost:3000/api/jobs/$JOB_ID | jq -r '.status'
```

**Expected times:**
- SDXL 20 steps: ~15-30 seconds
- SDXL 50 steps + refiner: ~60-90 seconds
- Video (4sec, LTX): ~5-10 minutes

---

## 🎯 T-1 Day: Final Preparation

### System Health Check

```bash
# SSH to Verda instance
ssh user@your-verda-instance
cd /opt/comfyui-workshop

# Check all services
./scripts/status.sh

# View recent logs
docker-compose logs --tail=50

# Check GPU
nvidia-smi

# Check disk space
df -h data/
```

### Prepare Instructor Workspace

**Use user001 as instructor workspace:**

```bash
# Pre-load demo workflows
cp demos/*.json data/workflows/

# Test priority override
curl -X POST http://localhost:3000/api/jobs \
  -H "Content-Type: application/json" \
  -d '{"user_id":"user001","workflow":{...},"priority":0}'
```

### Participant Communication

**Send email with:**
- Workshop date/time
- Access URL: `https://workshop.ahelme.net/userXXX/`
- Login credentials (if using auth)
- Pre-workshop survey link

**Email template:**
```
Subject: ComfyUI Workshop - Your Access Details

Hi [Name],

You're all set for tomorrow's AI Video Generation Workshop!

Your workspace: https://workshop.ahelme.net/user0XX/

What to bring:
- Laptop with modern browser (Chrome/Firefox recommended)
- Headphones (optional)
- Ideas for images/videos you want to create!

See you tomorrow!
```

### Backup Configuration

```bash
# Backup current state
tar -czf backup-$(date +%Y%m%d).tar.gz \
  .env \
  docker-compose.yml \
  data/workflows/ \
  data/models/shared/

# Copy to safe location
scp backup-*.tar.gz backup-server:/backups/
```

---

## 🚀 Workshop Day (T-0)

### Morning Setup (60 minutes before)

**Time: T-60min**

```bash
# 1. SSH to Verda instance
ssh user@your-verda-instance
cd /opt/comfyui-workshop

# 2. Check system status
./scripts/status.sh

# 3. Verify GPU
nvidia-smi

# 4. Clear any stale jobs
docker-compose exec redis redis-cli -a $REDIS_PASSWORD FLUSHDB

# 5. Restart services (fresh state)
docker-compose restart

# 6. Test instructor workspace
curl -k https://workshop.ahelme.net/user001/

# 7. Open admin dashboard
# Browser: https://workshop.ahelme.net/admin
```

### Pre-Workshop Checklist

**Time: T-30min**

- [ ] All services running (`docker-compose ps`)
- [ ] Admin dashboard accessible
- [ ] Test job submission works
- [ ] GPU memory clear (nvidia-smi shows 0% usage)
- [ ] Queue empty (admin dashboard shows 0 pending)
- [ ] Projector/screen sharing working
- [ ] Participant URLs tested (spot check 3-5)

### Opening (15 minutes)

**Time: T+0**

1. **Welcome & Introductions** (5 min)
   - Introduce yourself and workshop goals
   - Brief overview of ComfyUI
   - Workshop format: demo → hands-on → experimentation

2. **Share Access URLs** (5 min)
   - Display URL list on screen
   - Have participants navigate to their workspace
   - Verify everyone can access (show of hands)

3. **Quick Interface Tour** (5 min)
   - Point out: node library, canvas, queue button
   - Show admin dashboard (explain queue system)
   - Set expectations: jobs process one at a time

### Demonstration Block (30 minutes)

**Time: T+15**

**Demo 1: Basic Text-to-Image** (15 min)
```bash
# Load workflow: 01_intro_text_to_image.json
# Show participants:
# - How to load a workflow
# - Where to edit prompts
# - How to queue a job
# - Where outputs appear
```

**Your demo job (use priority override):**
- Admin dashboard → find your job → click "Prioritize"
- Or use instructor priority: `priority: 0` in job submission

**Demo 2: Customization** (15 min)
```bash
# Show how to:
# - Change prompt text
# - Adjust steps/CFG
# - Modify seed for variations
# - Upload custom image (if doing img2img)
```

### Hands-On Session (60 minutes)

**Time: T+45**

**Activity: Create Your First Image**

Instructions to participants:
1. Load workflow `01_intro_text_to_image.json`
2. Modify the prompt with your own description
3. Click "Queue Prompt"
4. Wait for your job to process
5. Download your output

**Your role:**
- Monitor admin dashboard for stuck jobs
- Watch queue depth (if >5, remind patience)
- Cancel failed jobs
- Answer questions
- Walk around helping individuals

**Common issues:**
- "Queue Prompt doesn't work" → Refresh browser
- "Job stuck" → Check worker logs, restart if needed
- "Can't see output" → Check `/outputs/userXXX/`

### Break (15 minutes)

**Time: T+105**

- Let queue clear
- Participants can continue experimenting
- Good time to fix any issues

### Advanced Techniques (45 minutes)

**Time: T+120**

**Demo 3: Advanced Workflow** (20 min)
- Load `02_advanced_composition.json`
- Explain multi-stage processing
- Show node connections
- Demonstrate refiner

**Demo 4: Video Generation** (25 min) *(if applicable)*
- Load `03_video_generation.json`
- Explain video model
- Show motion prompts
- Queue (this will take longer - good time for Q&A)

### Free Experimentation (60 minutes)

**Time: T+165**

**Open practice:**
- Participants work on their own ideas
- Provide 1-on-1 help
- Encourage sharing results
- Optionally: screen share cool results

**Monitor:**
- Queue depth (admin dashboard)
- System resources (`nvidia-smi` via SSH)
- Failed jobs (cancel and help debug)

### Wrap-Up (15 minutes)

**Time: T+225**

1. **Showcase** (10 min)
   - Ask volunteers to share their favorite output
   - Screen share from their workspace

2. **Q&A** (5 min)
   - Answer final questions
   - Provide resources for continued learning

3. **Thank You**
   - Share links to:
     - ComfyUI documentation
     - Example workflows
     - Community forums
   - Explain output retention (how long will workspaces stay up?)

---

## 📊 During Workshop: Monitoring

### Admin Dashboard

**Keep open at all times:**
- URL: `https://workshop.ahelme.net/admin`
- Refresh every 5-10 seconds (auto-updates via WebSocket)

**Watch for:**
- ⚠️ Queue depth >10 (remind patience)
- ⚠️ Jobs stuck in "running" >5 min (check worker)
- ⚠️ Failed jobs (cancel and investigate)
- ✅ Steady progress through queue

### Terminal Monitoring

**In SSH session, run:**
```bash
# Watch GPU usage
watch -n 2 nvidia-smi

# Tail worker logs
docker-compose logs -f worker-1

# Watch queue manager
docker-compose logs -f queue-manager
```

### Common Interventions

**Cancel stuck job:**
```bash
# Via admin dashboard: Click "✕ Cancel"
# Or via API:
curl -X DELETE http://localhost:3000/api/jobs/{job_id}
```

**Prioritize instructor demo:**
```bash
# Via admin dashboard: Click "⚡ Prioritize"
# Or via API:
curl -X PATCH http://localhost:3000/api/jobs/{job_id}/priority \
  -H "Content-Type: application/json" \
  -d '{"priority": 0}'
```

**Restart worker (if crashed):**
```bash
docker-compose restart worker-1
```

**Clear failed jobs:**
```bash
docker-compose exec redis redis-cli -a $REDIS_PASSWORD \
  ZREMRANGEBYSCORE queue:failed 0 +inf
```

---

## 🧹 Post-Workshop (T+1 Day)

### Data Collection

**Gather metrics:**
```bash
# SSH to instance
ssh user@your-verda-instance
cd /opt/comfyui-workshop

# Get statistics
docker-compose exec redis redis-cli -a $REDIS_PASSWORD INFO stats

# Check queue counts
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ZCARD queue:completed
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ZCARD queue:failed

# Export logs
docker-compose logs > workshop-logs-$(date +%Y%m%d).txt
```

**Metrics to record:**
- Total jobs submitted
- Jobs completed
- Jobs failed
- Average queue wait time
- Peak queue depth
- System uptime

### Backup User Outputs

```bash
# Create backup of all participant outputs
tar -czf workshop-outputs-$(date +%Y%m%d).tar.gz data/outputs/

# Download to local machine
scp user@verda-instance:/opt/comfyui-workshop/workshop-outputs-*.tar.gz ./

# Optionally share with participants
```

### Cleanup (Optional)

**If workshop is complete:**
```bash
# Stop services
./scripts/stop.sh

# Remove user frontends (save resources)
docker-compose -f docker-compose.override.yml down

# Keep core services for future use
# (nginx, redis, queue-manager, worker, admin)
```

### Participant Follow-Up

**Send thank-you email:**
```
Subject: Thank You + Workshop Resources

Thanks for participating in the AI Video Generation Workshop!

Your outputs: [Link to shared folder if applicable]

Resources:
- ComfyUI Docs: https://comfyworkflows.com/
- Workshop Workflows: [GitHub link]
- Continue learning: [Tutorial links]

Your workspace will remain active until [date].

Feedback survey: [Link]
```

### Post-Workshop Report

**Template:**
```markdown
# Workshop Report - [Date]

## Attendance
- Registered: 20
- Attended: [X]
- Completion rate: [X]%

## Statistics
- Total jobs submitted: [X]
- Jobs completed: [X]
- Jobs failed: [X]
- Success rate: [X]%
- Average wait time: [X] seconds
- Peak queue depth: [X]

## Technical Issues
- [List any incidents]
- [Resolutions applied]

## Participant Feedback
- [Survey results summary]
- [Common questions]
- [Feature requests]

## System Performance
- GPU utilization: [X]%
- Uptime: [X] hours
- Errors: [X]

## Improvements for Next Time
- [Lessons learned]
- [Process improvements]
- [Technical enhancements]

## Budget
- Verda costs: $[X]
- Total compute hours: [X]
```

---

## 🆘 Emergency Procedures

### Complete System Failure

**If everything goes down:**

1. **Stay calm** - Announce 5-minute technical break
2. **Restart all services:**
   ```bash
   docker-compose down
   docker-compose up -d
   ```
3. **Check logs:** `docker-compose logs`
4. **Verify health:** `./scripts/status.sh`

**If restart fails:**

Fallback option:
- Use public ComfyUI instances (comfyworkflows.com)
- Share your screen and continue demos
- Reschedule hands-on portion

### GPU Out of Memory

**Symptoms:** Worker crashes, CUDA errors

**Quick fix:**
```bash
docker-compose restart worker-1
```

**Prevention:**
- Use smaller models (SD 1.5 instead of SDXL)
- Reduce batch sizes
- Lower step counts

### Queue Completely Stuck

**Symptoms:** No jobs processing for >5 minutes

**Fix:**
```bash
# Restart queue manager
docker-compose restart queue-manager

# Restart worker
docker-compose restart worker-1

# Check Redis
docker-compose exec redis redis-cli -a $REDIS_PASSWORD PING
```

### Network/SSL Issues

**Symptoms:** Can't access website

**Check:**
```bash
# Test nginx
docker-compose logs nginx | grep -i error

# Test SSL
curl -vI https://your-domain 2>&1 | grep -i ssl

# Restart nginx
docker-compose restart nginx
```

**Fallback:**
- Use HTTP instead (http://ip-address:80)
- Update participant URLs

---

## 📋 Quick Reference

### URLs
- Landing: `https://comfy.ahelme.net/`
- **Health Check**: `https://comfy.ahelme.net/health` ⬅️ **Check this first!**
- Admin: `https://comfy.ahelme.net/admin`
- User workspaces: `https://comfy.ahelme.net/user001/` - `/user020/`
- API: `https://comfy.ahelme.net/api/`

### Key Commands
```bash
# Status check
./scripts/status.sh

# Restart all
docker-compose restart

# View logs
docker-compose logs -f

# Check GPU
nvidia-smi

# Clear queue
docker-compose exec redis redis-cli -a $REDIS_PASSWORD FLUSHDB
```

### Support Contacts
- Verda support: support@verda.com
- GitHub issues: https://github.com/ahelme/comfy-multi/issues
- Emergency backup: [Your phone number]

---

**Good luck with your workshop!** 🎓🚀

Remember: Stay calm, monitor the admin dashboard, and have fun! The system is robust and tested. You've got this! 💪
