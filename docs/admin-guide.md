# ComfyUI Workshop - Admin Guide

Welcome! This is the main admin guide for the ComfyUI Multi-User Workshop Platform. This document provides a quick overview and links to detailed guides for specific tasks.

---

## 🎯 Quick Reference

**Architecture:**
```
Hetzner VPS (comfy.ahelme.net)          Remote GPU (Verda H100)
Tailscale: 100.99.216.71                Tailscale: 100.89.38.43
├── Nginx (HTTPS + Basic Auth)          ├── Worker 1 (ComfyUI v0.9.2 + GPU)
├── Redis (VPN-only access)             ├── Worker 2 (optional)
├── Queue Manager (FastAPI)             ├── Worker 3 (optional)
├── Admin Dashboard                     └── LTX-2 Models (19B params, ~47GB)
└── 20 User Frontends (CPU, v0.9.2)
    ↓ Tailscale VPN (WireGuard encrypted)
```

**Critical URLs:**
| Resource | URL |
|----------|-----|
| **Health Check** | https://comfy.ahelme.net/health |
| **Admin Dashboard** | https://comfy.ahelme.net/admin |
| **API Endpoint** | https://comfy.ahelme.net/api/ |
| **Instructor Workspace** | https://comfy.ahelme.net/user001 |
| **Participant Workspaces** | https://comfy.ahelme.net/user002 through user020 |

**Critical SSH Access:**
```bash
# Hetzner VPS
ssh desk

# GPU Instance
ssh user@your-gpu-instance
```

---

## 💡 Basics

### System Monitoring

```bash
# Overall system health
./scripts/status.sh

# Check all services running
docker-compose ps

# Check web endpoints
curl https://comfy.ahelme.net/health
```

### Common Admin Tasks

**Cancel a stuck job:** Open Admin Dashboard → Find job → Click Cancel

**Prioritize instructor demo:** Open Admin Dashboard → Find your job → Click Prioritize

**Check queue depth:** `curl https://comfy.ahelme.net/api/queue/status`

**View worker logs:** `docker-compose logs worker-1 | tail -20`

### Health Checks

**Web-based health check:**
```bash
https://comfy.ahelme.net/health
```

**Manual connectivity test:**
```bash
# From GPU instance, test Redis connection to VPS
redis-cli -h comfy.ahelme.net -p 6379 -a $REDIS_PASSWORD ping
```

### Network Connectivity Tests

**Verify DNS:**
```bash
nslookup comfy.ahelme.net
# Should return VPS IP address
```

**Test HTTPS:**
```bash
curl -v https://comfy.ahelme.net/health
# Should get 200 OK with valid SSL certificate
```

**Test Redis from GPU:**
```bash
redis-cli -h comfy.ahelme.net -p 6379 -a $REDIS_PASSWORD ping
# Should get: PONG
```

---

## 📋 Critical Files and Locations

| File/Directory | Purpose |
|----------------|---------|
| `.env` | Configuration (passwords, domain, etc.) |
| `USER_CREDENTIALS.txt` | Plain-text user credentials (gitignored, see Security Guide) |
| `/etc/nginx/comfyui-users.htpasswd` | Encrypted user passwords for HTTP Basic Auth |
| `docker-compose.yml` | Container orchestration |
| `/etc/ssl/certs/fullchain.pem` | SSL public certificate |
| `/etc/ssl/private/privkey.pem` | SSL private key |
| `data/models/shared/` | Shared model files |
| `data/outputs/` | User output files (isolated per user) |
| `scripts/status.sh` | System health check script |
| `scripts/start.sh` | Start all services |
| `scripts/stop.sh` | Stop all services |

---

## 🔧 Essential Scripts

```bash
# Start all services
./scripts/start.sh

# Stop all services
./scripts/stop.sh

# System health check
./scripts/status.sh

# Add a new user (user021+)
./scripts/add-user.sh user021

# Remove a user
./scripts/remove-user.sh user021

# List all users and stats
./scripts/list-users.sh
```

---

## 🎓 Two-Tier Architecture

The system is split across two servers:

**Hetzner VPS (App Server):**
- Hosts 20 user frontends (CPU-only, no GPU)
- Runs queue manager and Redis
- Serves HTTPS with SSL
- Lightweight

**Remote GPU Instance (Compute Server):**
- Runs GPU workers (ComfyUI + GPU)
- Connects back to VPS via Redis
- Executes actual image/video generation
- Heavy lifting

**Benefits:**
- Users don't compete for GPU resources
- GPU instance can be scaled independently
- Can use cloud GPU providers (Verda, RunPod, Modal)
- One H100 serves 20 users efficiently

---

## 📚 Documentation Guide

Choose a guide based on what you need to do:

### [Admin Setup Guide](./admin-setup-guide.md)
**When:** During initial deployment or if starting from scratch

**Contents:**
- Configuration checklist (all items to configure)
- Detailed setup for Hetzner VPS and Remote GPU
- Environment variables explained
- SSL certificate configuration
- Model download and verification
- Initial testing procedures
- Two-tier architecture overview

**Use this for:** Setting up the system for the first time, configuring .env, understanding the split architecture.

---

### [Admin Dashboard Guide](./admin-dashboard.md)
**When:** During and after workshop to monitor and manage jobs

**Contents:**
- Dashboard access and features overview
- Real-time monitoring (statistics, queue, workers)
- Job management (cancel, prioritize)
- Common admin tasks with step-by-step instructions
- API endpoints for programmatic access
- Dashboard troubleshooting

**Use this for:** Monitoring system during workshop, managing jobs, understanding dashboard indicators, API access.

---

### [Admin Troubleshooting Guide](./admin-troubleshooting.md)
**When:** When something isn't working right

**Contents:**
- Quick diagnosis procedures and index of problem-specific guides
- Links to detailed troubleshooting for specific issues:
  - [Queue Stopped](./admin-troubleshooting-queue-stopped.md)
  - [Out of Memory](./admin-troubleshooting-out-of-memory.md)
  - [Worker Not Connecting](./admin-troubleshooting-worker-not-connecting.md)
  - [SSL Certificate Issues](./admin-troubleshooting-ssl-cert-issues.md)
  - [Redis Connection](./admin-troubleshooting-redis-connection.md)
  - [Docker Issues](./admin-troubleshooting-docker-issues.md)
- Performance metrics and tuning
- Emergency procedures

**Use this for:** When system is not working, diagnosing problems, performance issues, emergency recovery.

---

### [Admin Workshop Checklist](./admin-workshop-checklist.md)
**When:** Before and during your workshop

**Contents:**
- Quick reference index linking to phase-specific checklists:
  - [Pre-Workshop Checklist](./admin-checklist-pre-workshop.md) - T-1 Week, T-1 Day, T-1 Hour
  - [During Workshop Checklist](./admin-checklist-during-workshop.md) - Monitoring, tasks, emergencies
  - [Post-Workshop Checklist](./admin-checklist-post-workshop.md) - Cleanup, metrics, reporting
- Essential commands and quick reference
- Tips for success

**Use this for:** Preparing for workshop day, final checks, during-workshop monitoring, post-workshop procedures.

---

### [Admin Backup & Restore](./admin-backup-restore.md)
**When:** Setting up a new Verda instance or restoring from backup

**Contents:**
- Storage strategy (SFS, R2, mello backups)
- Backup procedures and what gets backed up
- Restore scripts (RESTORE-SFS.sh, RESTORE-BLOCK-MELLO.sh)
- Step-by-step restore instructions
- Verification checklist
- Troubleshooting

**Use this for:** Provisioning new Verda instances, restoring from backups, understanding storage workflows.

**See also:** [Backup Routines](./admin-backup-routines.md) - concise reference for manual and automatic backups.

---

### [Verda Serverless Containers](./admin-verda-serverless.md)
**When:** Want auto-scaling, pay-per-use inference (alternative to dedicated instances)

**Contents:**
- Serverless vs Instance comparison
- Architecture and scaling behavior
- Deployment steps (build, push, deploy)
- Configuration and environment variables
- Monitoring and cost optimization
- Troubleshooting serverless-specific issues

**Use this for:** Deploying serverless containers, understanding auto-scaling, optimizing costs for variable workloads.

**See also:** [Provider Switching](./admin-provider-switching.md) - switch between instance and serverless modes.

---

### [Provider Switching Guide](./admin-provider-switching.md)
**When:** Switching between GPU providers or deployment modes

**Contents:**
- Supported providers (verda-instance, verda-serverless, local)
- When to use each mode
- Switching procedures (no conflicts)
- Hybrid mode (instance + serverless simultaneously)
- Cost and performance comparison
- Verification and troubleshooting

**Use this for:** Toggling between inference providers, running hybrid deployments, choosing the right mode for your workload.

---

### [Admin Security Guide](./admin-security.md)
**When:** During setup and before going live

**Contents:**
- Security principles and architecture
- Authentication and access control
- Password management best practices
- SSL/TLS configuration and renewal
- Redis security configuration
- User isolation verification
- Network security and firewall rules
- Audit logging and compliance
- Incident response procedures

**Use this for:** Securing the system before workshop, setting passwords, verifying isolation, compliance requirements.

---

## 🚀 Getting Started

### First Time Setup?
1. Follow the **[Admin Setup Guide](./admin-setup-guide.md)**
2. Verify with the **[Admin Workshop Checklist](./admin-workshop-checklist.md)** (T-1 Week section)
3. Review **[Admin Security Guide](./admin-security.md)** to lock down the system

### Before Workshop Day?
1. Review **[Pre-Workshop Checklist](./admin-checklist-pre-workshop.md)** (all sections)
2. Have **[Admin Dashboard Guide](./admin-dashboard.md)** open nearby
3. Familiarize yourself with **[Admin Troubleshooting Guide](./admin-troubleshooting.md)** and specific problem guides

### During Workshop?
1. Monitor using **[Admin Dashboard](./admin-dashboard.md)**
2. Keep **[During Workshop Checklist](./admin-checklist-during-workshop.md)** visible
3. Refer to **[Admin Troubleshooting Guide](./admin-troubleshooting.md)** as needed

### Something's Broken?
1. Go to **[Admin Troubleshooting Guide](./admin-troubleshooting.md)**
2. Find your issue in the list
3. Follow the diagnosis and solutions
4. Escalate if needed

---

## 📈 Key Metrics to Watch

During the workshop, keep these metrics in mind:

| Metric | Good | Warning | Action |
|--------|------|---------|--------|
| **Pending jobs** | < 5 | 5-15 | Monitor |
| **Running jobs** | 1 | > 1 (need 2+ GPUs) | Normal |
| **Failed jobs** | 0% | < 1% | Investigate |
| **GPU memory** | < 70% | 70-85% | Warning |
| **Queue latency** | < 2 min | 2-10 min | Normal |

---

## ⏰ Typical Workshop Timeline

- **T-1 Week:** Complete [Pre-Workshop Checklist](./admin-checklist-pre-workshop.md) (T-1 Week section)
- **T-1 Day:** Run through [Pre-Workshop Checklist](./admin-checklist-pre-workshop.md) (T-1 Day section)
- **T-1 Hour:** Final verification with [Pre-Workshop Checklist](./admin-checklist-pre-workshop.md) (T-1 Hour section)
- **During Workshop:** Monitor with [Admin Dashboard Guide](./admin-dashboard.md), follow [During Workshop Checklist](./admin-checklist-during-workshop.md)
- **After Workshop:** Complete [Post-Workshop Checklist](./admin-checklist-post-workshop.md)

---

## 🆘 Need Help?

**For setup issues:**
→ See [Admin Setup Guide](./admin-setup-guide.md)

**For monitoring/dashboard:**
→ See [Admin Dashboard Guide](./admin-dashboard.md)

**For technical problems:**
→ See [Admin Troubleshooting Guide](./admin-troubleshooting.md)

**For workshop day preparation:**
→ See [Pre-Workshop Checklist](./admin-checklist-pre-workshop.md), [During Workshop Checklist](./admin-checklist-during-workshop.md), [Post-Workshop Checklist](./admin-checklist-post-workshop.md)

**For security concerns:**
→ See [Admin Security Guide](./admin-security.md)

---

## 📞 Emergency Contacts

**If critical system issue:**
1. Check [Admin Troubleshooting Guide](./admin-troubleshooting.md)
2. Restart services: `docker-compose restart`
3. Provide fallback to participants if needed

**For GPU issues:**
- Verda support (if using Verda instance)
- RunPod support (if using RunPod)
- Check NVIDIA drivers: `nvidia-smi`

**For VPS issues:**
- Hetzner support for infrastructure
- Check Docker: `docker-compose ps`

---

## 📚 Related Documentation

- **User Guide** (participants): `docs/user-guide.md`
- **Technical README**: `README.md`
- **Implementation Plan**: `implementation.md`
- **Product Requirements**: `prd.md`

---

**Last Updated:** 2026-01-18

For detailed information on any topic, refer to the specific guide linked above. Good luck with your workshop!
