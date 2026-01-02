# Implementation Plan: ComfyUI Workshop Infrastructure

**Project:** Multi-User ComfyUI Workshop Platform
**Started:** 2026-01-02
**Status:** 🔨 In Progress

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Verda H100 Instance                          │
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │                    Docker Compose Stack                      │    │
│  │                                                              │    │
│  │  ┌─────────┐  ┌─────────────────────────────────────────┐   │    │
│  │  │  Nginx  │  │         Redis Queue                     │   │    │
│  │  │  :443   │  │  - Job queue with priority support      │   │    │
│  │  │  SSL    │  │  - User session tracking                │   │    │
│  │  └────┬────┘  │  - Result pub/sub                       │   │    │
│  │       │       └─────────────────────────────────────────┘   │    │
│  │       │                         ▲                            │    │
│  │       ▼                         │                            │    │
│  │  ┌─────────────────────────────┴────────────────────────┐   │    │
│  │  │              Queue Manager Service                    │   │    │
│  │  │  - FastAPI REST API + WebSocket                      │   │    │
│  │  │  - FIFO / Round-robin / Priority scheduling          │   │    │
│  │  │  - Instructor override API                           │   │    │
│  │  └──────────────────────────────────────────────────────┘   │    │
│  │                              │                               │    │
│  │       ┌──────────────────────┼──────────────────────┐       │    │
│  │       ▼                      ▼                      ▼       │    │
│  │  ┌─────────┐           ┌─────────┐           ┌─────────┐   │    │
│  │  │ComfyUI 1│           │ComfyUI 2│           │ComfyUI N│   │    │
│  │  │ Worker  │           │ Worker  │           │ Worker  │   │    │
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
│  │  ┌──────────────────────────────────────────────────────┐   │    │
│  │  │      User Frontend Containers (x20)                  │   │    │
│  │  │  - ComfyUI UI with queue redirect extension         │   │    │
│  │  │  - Routes: /user/1 → /user/20                       │   │    │
│  │  └──────────────────────────────────────────────────────┘   │    │
│  └──────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Success Criteria

### Phase 1: Core Infrastructure ✅ / ❌
- [ ] Docker Compose orchestrates all services
- [ ] Nginx routes /user/1 through /user/20 correctly
- [ ] Nginx serves HTTPS with existing ahelme.net cert
- [ ] Redis running and accessible to queue manager
- [ ] All services start with `./scripts/start.sh`
- [ ] All services stop cleanly with `./scripts/stop.sh`

### Phase 2: Queue Manager & Workers ✅ / ❌
- [ ] Queue manager REST API responds at `/api/health`
- [ ] Queue manager accepts job submissions via POST `/api/jobs`
- [ ] Queue manager returns job status via GET `/api/jobs/{id}`
- [ ] WebSocket endpoint broadcasts queue updates
- [ ] ComfyUI worker polls queue and executes jobs
- [ ] Worker completes test workflow successfully
- [ ] Worker returns results to queue manager
- [ ] Multiple jobs queue and execute sequentially

### Phase 3: User Frontends ✅ / ❌
- [ ] 20 frontend containers start successfully
- [ ] Each frontend accessible at unique URL
- [ ] ComfyUI UI loads in browser
- [ ] Queue redirect extension intercepts "Queue Prompt"
- [ ] Jobs submit to queue manager instead of local ComfyUI
- [ ] Pre-loaded workflows appear in sidebar
- [ ] User can see their queue position
- [ ] Completed outputs appear in user workspace

### Phase 4: Admin Dashboard & Scripts ✅ / ❌
- [ ] Admin dashboard accessible at /admin
- [ ] Dashboard shows all pending jobs
- [ ] Dashboard shows currently running job
- [ ] Dashboard shows worker status (idle/busy)
- [ ] Admin can cancel jobs
- [ ] Admin can change job priority
- [ ] `./scripts/status.sh` shows system health
- [ ] `./scripts/add-user.sh` adds new user container
- [ ] Documentation complete (README + guides)

### Phase 5: Deployment & Testing ✅ / ❌
- [ ] Local deployment tested end-to-end
- [ ] Verda deployment script tested
- [ ] All 20 users can access simultaneously
- [ ] Queue handles 20 concurrent submissions
- [ ] Video generation workflow completes successfully
- [ ] Outputs persist after restart
- [ ] System runs stable for 2+ hours
- [ ] Workshop runbook created

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
- [ ] Package for Verda deployment
- [ ] SSH to Verda instance
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

**Phase:** Phase 1 - Setup
**Last Updated:** 2026-01-02
**Next Steps:** Create docker-compose.yml and nginx configuration

### Completed Tasks
- [x] PRD created
- [x] Implementation plan created
- [x] Git repository initialized
- [ ] ...

### Blockers
None currently.

### Notes
Starting with MVP features. Nice-to-have features deferred to v1.1 post-workshop.
