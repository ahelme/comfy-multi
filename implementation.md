**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-02
**Doc Updated:** 2026-01-10

---

# Implementation Plan: ComfyUI Workshop Infrastructure

**Project Status:** ✅ Production Ready - Deploying to comfy.ahelme.net

---

## Architecture Overview

**Split Deployment: Two-Tier Architecture**

```
┌─────────────────────────────────────────────────────────────────────┐
│           TIER 1: Hetzner VPS (comfy.ahelme.net)                    │
│                    Application Layer (CPU Only)                     │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Docker Compose Stack                      │    │
│  │                                                              │    │
│  │  ┌─────────┐  ┌─────────────────────────────────────────┐   │    │
│  │  │  Nginx  │  │         Redis Queue                     │   │    │
│  │  │  :443   │  │  - Job queue with priority support      │   │    │
│  │  │  SSL    │  │  - User session tracking                │   │    │
│  │  └────┬────┘  │  - Result pub/sub                       │   │    │
│  │       │       │  - Network port: 6379                    │   │    │
│  │       │       └─────────────────────────────────────────┘   │    │
│  │       │                         ▲                            │    │
│  │       ▼                         │                            │    │
│  │  ┌─────────────────────────────┴────────────────────────┐   │    │
│  │  │              Queue Manager Service                    │   │    │
│  │  │  - FastAPI REST API + WebSocket                      │   │    │
│  │  │  - FIFO / Round-robin / Priority scheduling          │   │    │
│  │  │  - Instructor override API                           │   │    │
│  │  └──────────────────────────────────────────────────────┘   │    │
│  │                                                              │    │
│  │  ┌──────────────────────────────────────────────────────┐   │    │
│  │  │      User Frontend Containers (x20)                  │   │    │
│  │  │  - ComfyUI UI with queue redirect extension         │   │    │
│  │  │  - Routes: /user001 → /user020 (CPU only, no GPU)   │   │    │
│  │  └──────────────────────────────────────────────────────┘   │    │
│  │                                                              │    │
│  │  ┌──────────────────────────────────────────────────────┐   │    │
│  │  │           Admin Dashboard                            │   │    │
│  │  │  - Real-time queue monitoring                        │   │    │
│  │  │  - Job management UI                                 │   │    │
│  │  └──────────────────────────────────────────────────────┘   │    │
│  └──────────────────────────────────────────────────────────────┘    │
└──────────────────────────────┬───────────────────────────────────────┘
                               │
                               │ Network: Redis Protocol
                               │ REDIS_HOST=comfy.ahelme.net
                               │
┌──────────────────────────────▼───────────────────────────────────────┐
│      TIER 2: Remote GPU (e.g. Verda) H100 Instance                  │
│                    GPU Inference Layer Only                          │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              ComfyUI GPU Workers (1-3)                       │    │
│  │                                                              │    │
│  │  ┌─────────┐           ┌─────────┐           ┌─────────┐   │    │
│  │  │ComfyUI 1│           │ComfyUI 2│           │ComfyUI 3│   │    │
│  │  │ Worker  │           │ Worker  │           │ Worker  │   │    │
│  │  │ + GPU   │           │ + GPU   │           │ + GPU   │   │    │
│  │  │ :8188   │           │ :8189   │           │ :8190   │   │    │
│  │  └─────────┘           └─────────┘           └─────────┘   │    │
│  │       │                      │                      │       │    │
│  │       └──────────────────────┴──────────────────────┘       │    │
│  │                              │                               │    │
│  │                    ┌─────────┴─────────┐                    │    │
│  │                    │  Shared Volumes   │                    │    │
│  │                    │  - models/        │                    │    │
│  │                    │  - outputs/       │                    │    │
│  │                    │  - workflows/     │                    │    │
│  │                    └───────────────────┘                    │    │
│  │                                                              │    │
│  │  ENV: REDIS_HOST=comfy.ahelme.net (connects to VPS)        │    │
│  └──────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

**Key Points:**
- **Tier 1 (Hetzner VPS):** Runs all application components (no GPU needed)
- **Tier 2 (Remote GPU):** Runs ONLY ComfyUI workers with GPU access
- **Communication:** Workers connect to Redis on VPS via network
- **Cost Efficiency:** VPS is cheap for app layer, GPU cloud only for inference

---

## Success Criteria

### Phase 1: Core Infrastructure ✅
- [x] Docker Compose orchestrates all services
- [x] Nginx routes /user/1 through /user/20 correctly
- [x] Nginx serves HTTPS with existing ahelme.net cert
- [x] Redis running and accessible to queue manager
- [x] All services start with `./scripts/start.sh`
- [x] All services stop cleanly with `./scripts/stop.sh`

### Phase 2: Queue Manager & Workers ✅
- [x] Queue manager REST API responds at `/api/health`
- [x] Queue manager accepts job submissions via POST `/api/jobs`
- [x] Queue manager returns job status via GET `/api/jobs/{id}`
- [x] WebSocket endpoint broadcasts queue updates
- [x] ComfyUI worker polls queue and executes jobs
- [x] Worker completes test workflow successfully
- [x] Worker returns results to queue manager
- [x] Multiple jobs queue and execute sequentially

### Phase 3: User Frontends ✅
- [x] 20 frontend containers start successfully
- [x] Each frontend accessible at unique URL
- [x] ComfyUI UI loads in browser
- [x] Queue redirect extension intercepts "Queue Prompt"
- [x] Jobs submit to queue manager instead of local ComfyUI
- [x] Pre-loaded workflows appear in sidebar
- [x] User can see their queue position
- [x] Completed outputs appear in user workspace

### Phase 4: Admin Dashboard & Scripts ✅
- [x] Admin dashboard accessible at /admin
- [x] Dashboard shows all pending jobs
- [x] Dashboard shows currently running job
- [x] Dashboard shows worker status (idle/busy)
- [x] Admin can cancel jobs
- [x] Admin can change job priority
- [x] `./scripts/status.sh` shows system health
- [x] `./scripts/add-user.sh` adds new user container
- [x] Documentation complete (README + guides)

### Phase 5: Production Readiness  ✅
- [x] Integration test script created (`./scripts/test.sh`)
- [x] Load test script created (`./scripts/load-test.sh`)
- [x] Remote GPU deployment script ready (`./scripts/deploy-verda.sh` - works with Verda, RunPod, etc.)
- [x] Workshop runbook complete with timeline & procedures
- [x] All test scripts executable and documented
- [x] Pre-flight checklist prepared
- [x] Emergency procedures documented
- [x] Post-workshop procedures defined

### Phase 6: Testing and Code Quality
- [x] Comprehensive test suite
- [x] 2x cycles of autonomous code review
- [x] Fix security vulnerabilities

### Phase 7: Documentation Improvement ✅
- [x] ✅ Add .gitignore file & remove tests/, .env from git tracking
- [x] ✅ Improve ALL code project docs - COMPREHENSIVE BUT NO FLUFF!
- [x] ✅ Split architecture documentation (Hetzner VPS + Remote GPU) consistent across all docs
- [x] ✅ Add standard headers to all .md files
- [x] ✅ Split admin documentation into granular, problem-specific guides
- [x] ✅ Update all cross-references between docs
- [x] ✅ Update implementation.md status to "Production Ready"

### Phase 8: Production Deployment 🔨
**Goal:** Deploy to production at comfy.ahelme.net (Hetzner VPS + Remote GPU)

**Detailed Deployment Guides:**
- **[VPS Deployment (Tier 1)](./implementation-deployment.md)** - Hetzner VPS application layer setup
- **[GPU Deployment (Tier 2)](./implementation-deployment-verda.md)** - Remote GPU worker setup (Verda/RunPod/Modal)

---

#### 8.1 VPS Setup & Configuration
- [ ] SSH access configured to Hetzner VPS (desk.ahelme.net)
- [ ] Verify DNS A records (desk.ahelme.net → VPS IP, comfy.ahelme.net → VPS IP)
- [ ] Review existing nginx configuration on VPS (if any)
- [ ] Install required packages (Docker, Docker Compose, git)
- [ ] Clone repository to VPS
- [ ] Configure .env file with production settings

#### 8.2 SSL Certificate Setup
- [ ] Locate SSL certificate files for ahelme.net domain
  - fullchain.pem (public certificate chain)
  - privkey.pem (private key)
- [ ] Copy SSL certificates to VPS at /etc/ssl/certs/ and /etc/ssl/private/
- [ ] Update .env with SSL_CERT_PATH and SSL_KEY_PATH
- [ ] Verify certificate validity and expiration date
- [ ] Test HTTPS access to comfy.ahelme.net

#### 8.3 Model Download & Storage
- [ ] Create data/models/shared/ directory structure
- [ ] Download required models (SDXL, ControlNet, etc.)
- [ ] Verify model checksums and integrity
- [ ] Configure model paths in extra_model_paths.yaml
- [ ] Test model loading in ComfyUI

#### 8.4 VPS Deployment (Tier 1: Application Layer)
- [ ] Start VPS services: `docker-compose up -d nginx redis queue-manager admin`
- [ ] Start 20 user frontends: `docker-compose up -d user-001 user-002 ... user-020`
- [ ] Verify nginx routing: https://comfy.ahelme.net/user001/
- [ ] Verify admin dashboard: https://comfy.ahelme.net/admin
- [ ] Verify API endpoints: https://comfy.ahelme.net/api/health
- [ ] Check logs for errors: `docker-compose logs`

#### 8.5 Remote GPU Deployment (Tier 2: Inference Layer)
- [ ] Provision Remote GPU instance (Verda H100 or similar)
- [ ] SSH access to Remote GPU instance
- [ ] Install Docker + nvidia-docker2
- [ ] Clone repository to Remote GPU instance
- [ ] Configure .env with REDIS_HOST=comfy.ahelme.net
- [ ] Configure .env with REDIS_PASSWORD (same as VPS)
- [ ] Start GPU worker(s): `docker-compose up -d worker-1`
- [ ] Verify worker connects to VPS Redis
- [ ] Test job execution end-to-end

#### 8.6 Integration Testing
- [ ] Run integration test suite: `./scripts/test.sh`
- [ ] Submit test job from user frontend
- [ ] Verify job appears in queue (admin dashboard)
- [ ] Verify worker picks up job and executes
- [ ] Verify output appears in user workspace
- [ ] Test WebSocket real-time updates
- [ ] Test job cancellation
- [ ] Test job prioritization (instructor override)

#### 8.7 Load Testing
- [ ] Run load test: `./scripts/load-test.sh` (20 users, 2 jobs each)
- [ ] Monitor queue depth and latency
- [ ] Monitor GPU memory usage (nvidia-smi)
- [ ] Monitor Redis memory usage
- [ ] Monitor nginx request rate
- [ ] Identify bottlenecks and optimize

#### 8.8 Production Hardening
- [ ] Verify firewall rules (VPS: 80, 443, 6379; GPU: outbound only)
- [ ] Enable Redis password authentication
- [ ] Review nginx security headers
- [ ] Test SSL certificate auto-renewal (if using Let's Encrypt)
- [ ] Configure log rotation for Docker containers
- [ ] Set up monitoring/alerting (optional)
- [ ] Document deployment commands in DEPLOYMENT.md

#### 8.9 Workshop Preparation
- [ ] Follow pre-workshop checklist: docs/admin-checklist-pre-workshop.md
- [ ] Verify all 20 user workspaces accessible
- [ ] Load workshop example workflows
- [ ] Test instructor workspace (user001)
- [ ] Prepare emergency fallback plan
- [ ] Share participant URLs

### Phase 9: UI Improvements
- [ ] Test and improve UI with PD A Helme
- [ ] Gather user feedback during workshop
- [ ] Address UI/UX issues

### Phase 10: Code Quality Polish
- [ ] Address deferred code quality issues
- [ ] Comment code as per best practices

---

## Detailed Implementation Steps

### Phase 1: Core Infrastructure (Day 1)

#### 1.1 Project Structure
```
comfyui-workshop/
├── docker-compose.yml
├── docker-compose.dev.yml
├── .env
├── .env.example
├── .gitignore
├── README.md
├── nginx/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── templates/
│   └── ssl/
├── redis/
│   └── redis.conf
├── queue-manager/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── main.py
│   ├── scheduler.py
│   ├── models.py
│   └── websocket.py
├── comfyui-worker/
│   ├── Dockerfile
│   ├── worker.py
│   ├── requirements.txt
│   └── extra_model_paths.yaml
├── comfyui-frontend/
│   ├── Dockerfile
│   └── custom_nodes/
│       └── queue_redirect/
├── admin/
│   ├── Dockerfile
│   └── app.py
├── scripts/
│   ├── setup.sh
│   ├── start.sh
│   ├── stop.sh
│   ├── status.sh
│   ├── add-user.sh
│   ├── remove-user.sh
│   ├── download-models.sh
│   └── deploy-verda.sh
├── data/
│   ├── models/
│   ├── outputs/
│   ├── inputs/
│   └── workflows/
└── docs/
    ├── user-guide.md
    ├── admin-guide.md
    └── troubleshooting.md
```

**Tasks:**
- [x] Create directory structure
- [ ] Write docker-compose.yml (nginx, redis, queue-manager)
- [ ] Create .env.example with all configuration
- [ ] Build nginx Dockerfile with SSL support
- [ ] Configure nginx routing for /user/{1-20}
- [ ] Test nginx routing locally
- [ ] Create start/stop scripts

#### 1.2 Nginx Configuration
- [ ] SSL termination with ahelme.net cert
- [ ] WebSocket proxy support
- [ ] Route /user/N → frontend-N:8188
- [ ] Route /api → queue-manager:3000
- [ ] Route /admin → admin:8080
- [ ] Health check endpoint
- [ ] Static file serving for outputs

#### 1.3 Redis Setup
- [ ] Basic redis.conf
- [ ] Persistence enabled (AOF)
- [ ] Password protection (optional)
- [ ] Volume for data persistence

---

### Phase 2: Queue Manager & Workers (Day 2)

#### 2.1 Queue Manager Service (FastAPI)
**Files:** queue-manager/main.py, scheduler.py, models.py, websocket.py

**Endpoints:**
- POST `/api/jobs` - Submit job
- GET `/api/jobs/{job_id}` - Get job status
- GET `/api/jobs` - List all jobs (admin)
- DELETE `/api/jobs/{job_id}` - Cancel job
- PATCH `/api/jobs/{job_id}/priority` - Change priority
- WS `/ws` - Real-time updates
- GET `/health` - Health check

**Data Models:**
```python
Job:
  - id: str (UUID)
  - user_id: str
  - workflow: dict
  - status: enum (pending, running, completed, failed, cancelled)
  - priority: int (0=highest)
  - created_at: datetime
  - started_at: datetime | None
  - completed_at: datetime | None
  - result: dict | None
  - error: str | None
```

**Scheduler Logic:**
- FIFO: Simple queue.pop()
- Round-robin: Track jobs-per-user, prioritize users with fewer completions
- Priority: Sort by priority field, then FIFO

**Tasks:**
- [ ] Implement FastAPI app skeleton
- [ ] Create Job model (Pydantic)
- [ ] Redis client integration
- [ ] Job submission endpoint
- [ ] Job status endpoint
- [ ] Scheduler with FIFO mode
- [ ] WebSocket broadcasting
- [ ] Error handling
- [ ] Tests for endpoints

#### 2.2 ComfyUI Worker
**Files:** comfyui-worker/worker.py

**Workflow:**
1. Connect to Redis queue
2. BLPOP for next job (blocking)
3. Update job status → "running"
4. Send workflow to ComfyUI `/prompt`
5. Poll ComfyUI `/history/{prompt_id}` for completion
6. Download outputs from ComfyUI
7. Upload outputs to shared volume
8. Update job status → "completed" with results
9. Broadcast completion via Redis pub/sub
10. Loop to step 2

**Tasks:**
- [ ] Create ComfyUI Docker image with GPU support
- [ ] Implement worker polling loop
- [ ] ComfyUI API client (submit, poll, download)
- [ ] File management (outputs to user directory)
- [ ] Error handling and retry logic
- [ ] Graceful shutdown (finish current job)
- [ ] Health check endpoint
- [ ] Logging

---

### Phase 3: User Frontends (Day 3)

#### 3.1 Frontend Container
**Base:** Official ComfyUI Docker image
**Modifications:** Custom node for queue redirect

**Custom Node: queue_redirect**
- Intercepts "Queue Prompt" button click
- Reads user_id from environment variable
- POSTs workflow to queue manager instead of local ComfyUI
- Displays queue position in UI
- Polls for job completion
- Loads result when ready

**Tasks:**
- [ ] Create comfyui-frontend Dockerfile
- [ ] Build queue_redirect custom node (JavaScript)
- [ ] Inject USER_ID environment variable
- [ ] Pre-load workflows in /workflows directory
- [ ] Test single frontend container
- [ ] Generate 20 frontend services in docker-compose
- [ ] Test all 20 frontends accessible
- [ ] Verify queue submission works

#### 3.2 Pre-loaded Workflows
- [ ] Create video gen workflow templates
- [ ] Export as API format JSON
- [ ] Mount to frontend containers
- [ ] Document workflow usage

---

### Phase 4: Admin Dashboard & Scripts (Day 4)

#### 4.1 Admin Dashboard
**Tech:** Simple HTML/JS or Streamlit
**URL:** /admin

**Features:**
- Queue visualization (table or kanban)
- Worker status (idle/busy, current job)
- Job controls (cancel, change priority)
- User activity log
- System metrics (optional: GPU usage, queue depth)

**Tasks:**
- [ ] Choose dashboard tech (HTML or Streamlit)
- [ ] Build queue visualization
- [ ] Implement job controls
- [ ] WebSocket integration for live updates
- [ ] Worker status display
- [ ] Deploy in docker-compose

#### 4.2 Management Scripts

**scripts/setup.sh:**
- [ ] Check prerequisites (Docker, docker-compose)
- [ ] Create data directories
- [ ] Copy .env.example → .env
- [ ] Prompt for SSL cert paths
- [ ] Download models (optional)

**scripts/start.sh:**
- [ ] docker-compose up -d
- [ ] Wait for health checks
- [ ] Display URLs for users
- [ ] Display admin URL

**scripts/stop.sh:**
- [ ] docker-compose down
- [ ] Option to preserve volumes

**scripts/status.sh:**
- [ ] Show container status
- [ ] Show queue depth
- [ ] Show worker status
- [ ] Show recent errors

**scripts/add-user.sh:**
- [ ] Generate new frontend service
- [ ] Update nginx config
- [ ] Reload nginx

**scripts/deploy-verda.sh:**
- [ ] Package for remote GPU deployment
- [ ] SSH to GPU instance
- [ ] Transfer files
- [ ] Run setup and start

---

### Phase 5: Deployment & Testing (Day 5)

#### 5.1 Local Testing
- [ ] End-to-end workflow test
- [ ] Load test (simulate 20 users)
- [ ] Failure scenarios (worker crash, Redis restart)
- [ ] SSL cert validation
- [ ] Performance benchmarking

#### 5.2 Verda Deployment
- [ ] Create Verda H100 instance
- [ ] Configure firewall/security groups
- [ ] Deploy via deploy-verda.sh
- [ ] Smoke test on Verda
- [ ] Load test on Verda

#### 5.3 Documentation
**README.md:**
- [ ] Project overview
- [ ] Quick start
- [ ] Architecture diagram
- [ ] Configuration guide

**docs/user-guide.md:**
- [ ] Accessing your workspace
- [ ] Running workflows
- [ ] Uploading files
- [ ] Downloading outputs

**docs/admin-guide.md:**
- [ ] Starting/stopping system
- [ ] Monitoring queue
- [ ] Managing priorities
- [ ] Troubleshooting

**docs/troubleshooting.md:**
- [ ] Common issues and solutions
- [ ] Log locations
- [ ] Support contacts

---

## Configuration (.env)

```env
# Domain & SSL
DOMAIN=ahelme.net
SSL_CERT_PATH=/path/to/fullchain.pem
SSL_KEY_PATH=/path/to/privkey.pem

# User configuration
NUM_USERS=20

# Worker configuration
NUM_WORKERS=1
WORKER_GPU_MEMORY_LIMIT=70G

# Queue configuration
QUEUE_MODE=fifo  # fifo, round-robin
ENABLE_PRIORITY=true

# Storage paths (persistent volumes)
MODELS_PATH=./data/models
OUTPUTS_PATH=./data/outputs
INPUTS_PATH=./data/inputs
WORKFLOWS_PATH=./data/workflows

# Redis
REDIS_PASSWORD=changeme

# Queue Manager
QUEUE_MANAGER_PORT=3000

# Admin Dashboard
ADMIN_PORT=8080

# ComfyUI
COMFYUI_VERSION=latest
```

---

## Testing Checklist

### Unit Tests
- [ ] Queue manager API endpoints
- [ ] Scheduler logic (FIFO, round-robin, priority)
- [ ] Job state transitions
- [ ] WebSocket broadcasting

### Integration Tests
- [ ] Worker → Queue manager communication
- [ ] Frontend → Queue manager communication
- [ ] Admin dashboard → Queue manager communication
- [ ] File upload/download flow

### End-to-End Tests
- [ ] User submits job → job completes → output appears
- [ ] 20 users submit simultaneously → all jobs complete
- [ ] Worker crash → job re-queues automatically
- [ ] Redis restart → queue persists
- [ ] Instructor priority override works

### Performance Tests
- [ ] Job submission latency < 500ms
- [ ] Queue status query < 100ms
- [ ] 20 concurrent users (load test)
- [ ] System stable for 2+ hours

---

## Rollback Plan

If critical issues arise:

1. **Queue manager down:** Fallback to simple mode (users manually choose worker)
2. **Worker crash:** Restart worker, jobs auto-re-queue
3. **Redis failure:** Use in-memory fallback (ephemeral queue)
4. **Complete failure:** Provide participants with standalone ComfyUI instances

---

## Post-Workshop

### Metrics to Collect
- Total jobs completed
- Average job duration
- Queue wait times
- Peak concurrent users
- System uptime
- Errors encountered

### Feedback Collection
- User survey (workshop experience)
- Technical issues log
- Feature requests
- Performance observations

---

## Current Status

**Phase:** ✅ ALL PHASES COMPLETE - Production Ready!
**Last Updated:** 2026-01-03
**Status:** Ready for deployment and workshop execution

### Completed Phases
- [x] Phase 1: Core Infrastructure
- [x] Phase 2: Queue Manager & Workers
- [x] Phase 3: User Frontends
- [x] Phase 4: Admin Dashboard & Documentation
- [x] Phase 5: Deployment & Testing Scripts

### Final Deliverables
- **Code:** 50 files, ~9,000 lines
- **Documentation:** 5 comprehensive guides (2,500+ lines)
- **Scripts:** 10 production-ready management scripts
- **Tests:** Integration test suite + load testing tools
- **Deployment:** Automated Verda deployment ready

### Ready for Workshop
✅ All success criteria met
✅ Complete documentation suite
✅ Testing and monitoring tools ready
✅ Emergency procedures documented

### Notes
Platform exceeds MVP requirements. Optional enhancements for v1.1:
- User authentication system
- Advanced queue analytics dashboard
- Multi-GPU worker scaling
- Job scheduling (cron/recurring)
