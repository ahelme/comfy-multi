**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-11

---

# Admin Workshop Checklists - Quick Reference Index

Complete operational checklists organized by workshop phase. Each guide includes specific tasks, commands, and contingency procedures.

## Phase-Specific Checklists

### [Pre-Workshop Preparation](./admin-checklist-pre-workshop.md)

Comprehensive preparation tasks completed before participants arrive.

**Sections:**
- One Week Before (T-1 Week) - Infrastructure, models, SSL, configuration
- One Day Before (T-1 Day) - System startup, GPU readiness, data backup
- One Hour Before (T-1 Hour) - Final access checks, health verification

**Key tasks:**
- Download models and verify setup
- SSL certificate verification
- Network connectivity testing
- Load testing with simulated 20 users
- Example workflow preparation

---

### [During Workshop Monitoring](./admin-checklist-during-workshop.md)

Real-time monitoring and participant support during the workshop.

**Sections:**
- First Hour - Critical monitoring and issue response
- Ongoing Monitoring (Every 5-10 minutes) - Queue depth, GPU memory, service health
- Periodic Checks (Every 30 minutes) - System status, logs, connectivity
- Common Tasks - Cancel jobs, prioritize, assist participants
- Emergency Procedures - System crashes, GPU failure, fallback access

**Key tasks:**
- Continuous dashboard monitoring
- Queue depth management
- GPU memory tracking
- Participant support and troubleshooting
- Emergency response protocols

---

### [Post-Workshop Procedures](./admin-checklist-post-workshop.md)

Data collection, backup, analysis, and reporting after the workshop concludes.

**Sections:**
- Immediate Actions (Last hour) - Complete remaining jobs
- Short Term (Within 1 hour) - Export outputs, logs, database
- Medium Term (Same day) - Collect metrics, analyze performance
- Analysis and Reporting - Generate workshop report
- Long Term Actions - Documentation, team debrief

**Key tasks:**
- Backup all user outputs and logs
- Generate performance metrics
- Create workshop report
- Share results with participants
- Archive for future reference

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

# Cancel a job
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
| `https://comfy.ahelme.net/user002-020` | Participant workspaces |
| `https://comfy.ahelme.net/admin` | Admin dashboard |
| `https://comfy.ahelme.net/health` | System health |
| `https://comfy.ahelme.net/api/queue/status` | Queue status |

### SSH Commands

```bash
# VPS (Hetzner)
ssh desk

# GPU Instance (Remote GPU e.g. Verda, RunPod)
ssh user@[gpu-instance-ip]
```

---

## Performance Metrics to Monitor

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| **GPU Memory** | < 70% | 70-85% | > 85% |
| **Queue Depth** | < 5 | 5-20 | > 20 |
| **Job Time** | < 2 min | 2-5 min | > 5 min |
| **Failed Jobs** | 0% | < 1% | > 5% |
| **Uptime** | > 99% | 95-99% | < 95% |

---

## Related Troubleshooting Resources

For problem-specific help during the workshop, see:

- **[Admin Troubleshooting Guide](./admin-troubleshooting.md)** - Problem-specific guides
  - Queue Not Processing
  - Out of Memory (OOM) Errors
  - Workers Can't Connect to Redis
  - Redis Connection Issues
  - SSL Certificate Errors
  - Docker and Container Issues

---

## Tips for Success

1. **Pre-workshop:** Run through checklist T-1 week to catch issues early
2. **During workshop:** Monitor actively, don't wait for complaints
3. **Communication:** Keep participants informed about queue status
4. **Recovery:** Most issues resolve with simple service restarts
5. **Documentation:** Track what happens for post-workshop analysis

---

## Document Navigation

- **[Pre-Workshop](./admin-checklist-pre-workshop.md)** - T-1 week, day, hour
- **[During Workshop](./admin-checklist-during-workshop.md)** - Real-time monitoring
- **[Post-Workshop](./admin-checklist-post-workshop.md)** - Backup and analysis
- **[Troubleshooting](./admin-troubleshooting.md)** - Problem resolution
- **admin-guide.md** - General admin reference
- **admin-setup-guide.md** - Initial configuration
