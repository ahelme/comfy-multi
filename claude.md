# Claude Project Guide

**Project:** ComfyUI Multi-User Workshop Platform
**Repository:** github.com/ahelme/comfy-multi
**Last Updated:** 2026-01-02

---

## ⚠️ CRITICAL INSTRUCTIONS - YOU MUST:

1. **USE LATEST STABLE LIBRARIES AS OF 02 JAN 2026** - All dependencies must use latest stable versions (not beta/alpha)
2. **MODULAR INFERENCE PROVIDERS** - Include config file to easily switch inference providers (Verda, RunPod, Modal, local, etc.)
3. **ALWAYS CHECK IF CODE HAS BEEN CREATED FIRST** - NEVER EVER REWRITE CODE IF IT HAS ALREADY BEEN WRITTEN AND WORK  WELL - always check!!!!!!! 
    

## 🎯 Project Quick Reference

### What are we building?
A multi-user ComfyUI platform for a video generation workshop with 20 participants sharing a single Verda H100 GPU.

### Key Requirements
- 20 isolated ComfyUI web interfaces
- Central job queue (FIFO/round-robin/priority)
- 1-3 GPU workers on H100
- HTTPS with existing ahelme.net SSL cert
- Persistent user storage
- Admin dashboard for instructor

### Timeline
- **Start Date:** 2026-01-02
- **Workshop Date:** ~Mid-January 2026 (2 weeks)
- **Development Time:** 5 days
- **Buffer:** 9 days

---
## CURRENT ISSUES

Priority 1 was not followed - outdated libraries were installed - we must create a Haiku Code Quality Expert subagent to review all files in codebase systematically for changes that must be made due to migration (and any other issues).

YOU MUST RESPECT PRIORITY ONE!!!!

## 📁 Project Structure

```
/home/dev/projects/comfyui/
├── prd.md                    # Product Requirements Document
├── implementation.md         # Implementation plan + success criteria
├── progress.md              # Session logs + metrics (UPDATE EACH RESPONSE)
├── claude.md                # This file - project guide
├── README.md                # Public project documentation
├── .env                     # Local configuration (gitignored)
├── .env.example             # Template configuration
├── docker-compose.yml       # Main orchestration
├── docker-compose.dev.yml   # Local dev overrides
├── nginx/                   # Reverse proxy
├── queue-manager/           # FastAPI service
├── comfyui-worker/          # GPU worker
├── comfyui-frontend/        # User UI containers
├── admin/                   # Admin dashboard
├── scripts/                 # Management scripts
├── data/                    # Persistent volumes
└── docs/                    # User/admin guides
```

---

## 📚 Document Links

### Core Documents
- **[PRD](./prd.md)** - Requirements, user stories, success criteria
- **[Implementation Plan](./implementation.md)** - Architecture, phases, tasks
- **[Progress Log](./progress.md)** - Session logs, metrics, standup notes
- **[Plan File](../.claude/plans/merry-bouncing-candy.md)** - Original planning artifact

### Documentation (To Be Created)
- **README.md** - Public project overview
- **docs/user-guide.md** - For workshop participants
- **docs/admin-guide.md** - For instructor
- **docs/troubleshooting.md** - Common issues

---

## 🔄 Update Instructions

### At the END of EVERY response, update `progress.md`:

```markdown
### Session N - YYYY-MM-DD

**Activities:**
- What was accomplished in this session
- Key decisions made
- Files created/modified

**Code Created:**
- List major files with brief description

**Blockers:**
- Any issues encountered

**Next Session Goals:**
- What to do next
```

### Keep these metrics current in `progress.md`:
- Lines of Code
- Files Created
- Sprint Status (🔨 In Progress / ✅ Complete / ⏳ Not Started)
- Risk Register updates

---

## 🏗️ Architecture Overview

```
[User Browser]
    ↓ HTTPS
[Nginx :443] → SSL termination, routing
    ├─→ /user/1-20 → Frontend containers
    ├─→ /api → Queue Manager
    └─→ /admin → Admin Dashboard

[Queue Manager :3000] ← FastAPI + WebSocket
    ↓ Redis
[Job Queue] ← Redis list + pub/sub
    ↓
[ComfyUI Workers :8188-8190] ← GPU processing
    ↓
[Shared Volumes] ← models, outputs, workflows
```

---

## 🚀 Git Workflow

### Repository
- **Platform:** GitHub
- **URL:** https://github.com/ahelme/comfy-multi
- **Branch Strategy:**
  - `main` - production-ready code
  - `dev` - active development
  - Feature branches as needed

### Git Configuration (IMPORTANT)
**GitHub noreply email (keeps email private):**
```bash
git config user.email "ahelme@users.noreply.github.com"
git config user.name "ahelme"
```

### Commit Guidelines
```bash
# Good commit messages
feat: add queue manager REST API endpoints
fix: resolve nginx routing for user/20
docs: update admin guide with priority override
test: add integration tests for worker
```

### When to Commit
- End of each major feature
- Before trying risky changes
- End of each session
- When tests pass

---

## 🛠️ Technology Stack

### Infrastructure
- **Container Runtime:** Docker + Docker Compose
- **Reverse Proxy:** Nginx (SSL termination, routing)
- **Queue:** Redis 7+ (job queue, pub/sub)
- **SSL:** Existing ahelme.net certificate

### Services
- **Queue Manager:** Python 3.11+ with FastAPI + WebSocket
- **Workers:** ComfyUI (official) with GPU support
- **Frontends:** ComfyUI web UI + custom queue redirect node
- **Admin:** HTML/JS or Streamlit (TBD)

### Deployment
- **Development:** Docker Compose locally
- **Production:** Verda H100 instance
- **GPU:** NVIDIA H100 80GB (shared)

---

## ⚙️ Configuration

### Environment Variables (.env)
```env
# Domain & SSL
DOMAIN=ahelme.net
SSL_CERT_PATH=/path/to/fullchain.pem
SSL_KEY_PATH=/path/to/privkey.pem

# Inference Provider (verda, runpod, modal, local)
INFERENCE_PROVIDER=verda
VERDA_API_KEY=
RUNPOD_API_KEY=
MODAL_API_KEY=

# User configuration
NUM_USERS=20
NUM_WORKERS=1
QUEUE_MODE=fifo
REDIS_PASSWORD=changeme
```

### SSL Certificate
- **Domain:** ahelme.net
- **Location:** User will provide cert paths
- **Type:** Existing cert (not Let's Encrypt)
- **Format:** PEM files (fullchain.pem + privkey.pem)

---

## 📋 Implementation Phases

### Phase 1: Core Infrastructure (Day 1) - 🔨 IN PROGRESS
- [x] Project structure
- [x] Documentation setup
- [ ] docker-compose.yml
- [ ] Nginx configuration
- [ ] Redis setup
- [ ] Start/stop scripts

### Phase 2: Queue Manager & Workers (Day 2)
- [ ] FastAPI queue manager
- [ ] Job scheduler (FIFO/round-robin/priority)
- [ ] ComfyUI worker implementation
- [ ] WebSocket broadcasting

### Phase 3: User Frontends (Day 3)
- [ ] Frontend containers (x20)
- [ ] Queue redirect custom node
- [ ] Pre-loaded workflows
- [ ] User workspace isolation

### Phase 4: Admin Dashboard & Scripts (Day 4)
- [ ] Admin dashboard UI
- [ ] Management scripts (setup, add-user, etc.)
- [ ] Documentation (user guide, admin guide)

### Phase 5: Deployment & Testing (Day 5)
- [ ] Local end-to-end testing
- [ ] Verda deployment script
- [ ] Load testing (20 concurrent users)
- [ ] Workshop runbook

---

## ✅ Success Criteria

### MVP Requirements (Must Have)
- ✅ 20 isolated user interfaces accessible
- ✅ Jobs queue and execute on GPU
- ✅ HTTPS working with SSL cert
- ✅ Outputs persist after restart
- ✅ Admin can monitor queue
- ✅ System stable for 8-hour workshop

### Nice to Have (v1.1)
- Round-robin scheduling
- User model uploads
- Queue position ETA
- Resource usage metrics

### Workshop Ready Definition
1. All 20 URLs accessible and working
2. Video generation workflow completes successfully
3. Queue handles concurrent submissions
4. Instructor can override priorities
5. Documentation complete
6. Tested on Verda H100

---

## 🐛 Known Issues / Technical Debt

None yet.

---

## 🔗 External Links

### Research References
- [Visionatrix Discussion](https://github.com/comfyanonymous/ComfyUI/discussions/3569) - Multi-user architecture
- [SaladTechnologies/comfyui-api](https://github.com/SaladTechnologies/comfyui-api) - Queue patterns
- [Modal ComfyUI Scaling](https://modal.com/blog/scaling-comfyui) - Architecture insights
- [9elements ComfyUI API](https://9elements.com/blog/hosting-a-comfyui-workflow-via-api/) - Workflow execution

### Deployment Targets
- [Verda H100](https://verda.com/h100-sxm5) - GPU cloud provider
- [Verda Products](https://verda.com/products) - Instance types

### ComfyUI Resources
- [ComfyUI GitHub](https://github.com/comfyanonymous/ComfyUI)
- [ComfyUI Wiki](https://comfyui-wiki.com/)
- [ComfyUI API Docs](https://github.com/comfyanonymous/ComfyUI/discussions/2073)

---

## 🎓 Context for Claude

### User Background
- Running AI/video generation workshop
- Has Hetzner VPS with ahelme.net SSL cert
- Wants to use Verda H100 for GPU compute
- 20 participants need isolated environments
- Workshop in ~2 weeks

### Key Decisions Made
1. **Custom build** chosen over managed services (cost, control, Verda usage)
2. **Existing SSL cert** will be mounted (not Let's Encrypt)
3. **Queue modes:** FIFO + round-robin + instructor priority
4. **Single H100** with 1-3 workers (test then scale)
5. **Persistent storage** for all user data
6. **User model uploads** allowed

### User Preferences
- Appreciates thoroughness and detail
- Values documentation
- Wants progress tracking (hence progress.md)
- Likes structured approaches

---

## 📝 Session Checklist

Before each session ends:
- [ ] Update progress.md with session log
- [ ] Update implementation.md task checkboxes
- [ ] Commit code changes to git
- [ ] Update metrics (files created, LOC, etc.)
- [ ] Note any blockers or decisions
- [ ] Clear next session goals

---

## 🚨 Emergency Contacts / Fallbacks

If critical issues:
1. Check docs/troubleshooting.md
2. Review GitHub issues in referenced projects
3. Fallback: Simple mode (manual worker selection)
4. Last resort: Standalone ComfyUI instances for participants

---

**Repository:** https://github.com/USER/comfyui-workshop (TBD - creating now)
**Last Updated:** 2026-01-02 by Claude
**Next Update:** End of current session
