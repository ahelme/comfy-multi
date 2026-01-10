# Product Requirements Document: ComfyUI Workshop Multi-User Web App 

## Project Overview

**Project Name:** ComfyUI Multi-User Workshop Platform
**Doc Created:** 2026-01-02
**Doc Updated:** 2026-01-03
**Deployment Architecture:** Split - Application Layer on Hetzner VPS, GPU Inference on Verda H100
**Workshop Date:** ~2 weeks from now (mid-January 2026)

## Problem Statement

Running a video generation workshop with 20 participants requires isolated ComfyUI instances with shared GPU resources. Current solutions either:
- Lack user isolation (shared single interface)
- Are expensive managed services
- Don't support custom queue management
- Require separate GPU per user (not feasible)

## Target Users

### Primary: Workshop Participants (20 users)
- Need full ComfyUI node editor interface
- Want to experiment with video generation models
- May upload custom models
- Require persistent storage of outputs
- Mixed technical skill levels

### Secondary: Workshop Instructor
- Needs queue visibility and control
- Can override priorities for demos
- Monitors all participant activity
- Manages system resources

## Requirements

### Functional Requirements

#### FR1: User Isolation
- Each participant gets isolated ComfyUI web interface
- Separate workspace per user (workflows, outputs, uploads)
- Users cannot see each other's work
- Accessible via unique URL (e.g., `https://ahelme.net/user/1`)

#### FR2: Queue Management
- Centralized job queue for GPU workers
- Support three scheduling modes:
  - FIFO (First In, First Out)
  - Round-robin (fair distribution per user)
  - Priority (instructor override)
- Real-time queue status visibility
- Job cancellation capability

#### FR3: GPU Worker Pool
- 1-3 ComfyUI worker instances on H100
- Workers pull jobs from central queue
- Shared model storage (read-only)
- Support video generation models (Wan, HunyuanVideo, LTX-Video, etc.)

#### FR4: Storage
- **Persistent:**
  - User outputs (generated videos/images)
  - User uploads (input media, custom models)
  - Shared models (pre-installed)
  - Pre-built workflows
- **Per-user quotas** (optional, nice-to-have)

#### FR5: Pre-loaded Workflows
- Video generation workflows available on launch
- Accessible from ComfyUI sidebar
- Documented and workshop-ready

#### FR6: Admin Dashboard
- Queue visualization (pending, running, completed jobs)
- User activity monitoring
- Priority override controls
- System health metrics

### Non-Functional Requirements

#### NFR1: Security
- HTTPS required (existing SSL cert: ahelme.net)
- No plaintext credentials in config files
- User workspace isolation (no cross-user file access)

#### NFR2: Performance
- Job submission < 500ms
- Queue status updates in real-time (WebSocket)
- Minimal cold-start time (<30s for worker)

#### NFR3: Scalability
- Split web app server and inference server
- Support 20 concurrent users
- Easy to scale workers (1→3 instances)
- Configurable user count (10-30 users)

#### NFR4: Reliability
- System survives worker crashes (jobs re-queue)
- Persistent queue (survives Redis restart)
- Health checks for all services

#### NFR5: Maintainability
- Clear documentation (deployment, troubleshooting)
- Simple configuration (.env file)
- Management scripts (start/stop/status)
- Logs accessible for debugging

#### NFR6: Deployment
- Single command deployment to Hetzner + Verda
- Works on local dev environment (for testing)
- Uses existing SSL cert (no Let's Encrypt needed)

## Technical Constraints

### Infrastructure
- **Application Layer:** Hetzner VPS (comfy.ahelme.net) - Handles app, web UI, queue management
- **GPU Inference Layer:** Remote GPU (e.g. Verda) H100 (80GB VRAM) - GPU workers only
- **Domain:** ahelme.net (registered on Namecheap, SSL cert installed on Hetzner VPS)
- **GPU:** Single H100 shared across workers on remote GPU provider
- **Container Platform:** Docker + Docker Compose on both tiers
- **Network:** VPS and remote GPU connected via Redis protocol over internet

### Technology Stack (Proposed)
- **Reverse Proxy:** Nginx (SSL termination, routing)
- **Queue:** Redis (job queue, pub/sub)
- **Queue Manager:** Python FastAPI (custom service)
- **Workers:** ComfyUI (official Docker images)
- **Frontend:** ComfyUI web UI (with queue redirect extension)
- **Admin Dashboard:** Simple HTML/JS or Streamlit

### Video Models (To Be Confirmed)
- Wan 2.1 (14B) - ~28GB VRAM
- HunyuanVideo - ~25GB VRAM
- LTX-Video - ~10GB VRAM
- AnimateDiff - ~5GB VRAM
- CogVideoX - ~20GB VRAM

**Note:** H100 80GB can hold 2-3 models simultaneously

## User Stories

### US1: Participant Submits Job
**As a** workshop participant
**I want to** queue a video generation workflow
**So that** my job is processed on the shared GPU

**Acceptance Criteria:**
- Click "Queue Prompt" in ComfyUI UI
- Job enters queue with status visible
- Real-time progress updates
- Completed output appears in my workspace

### US2: Instructor Demos Feature
**As an** instructor
**I want to** jump the queue for my demo
**So that** participants see results immediately

**Acceptance Criteria:**
- Admin dashboard has priority toggle
- Demo jobs process immediately (interrupt current job or go to front)
- Normal queue resumes after demo

### US3: User Uploads Custom Model
**As a** participant
**I want to** upload my own model file
**So that** I can experiment with custom models

**Acceptance Criteria:**
- Upload interface in ComfyUI
- Model appears in model selector
- Only accessible to my user workspace
- Persistent across sessions

### US4: Monitor Queue Status
**As a** participant
**I want to** see my position in queue
**So that** I know when my job will run

**Acceptance Criteria:**
- Queue position displayed (e.g., "Position 3 of 8")
- ETA estimate (optional)
- Update in real-time without refresh

### US5: Admin Views System Health
**As an** instructor
**I want to** monitor all user activity
**So that** I can troubleshoot issues

**Acceptance Criteria:**
- Dashboard shows all active jobs
- Worker status (busy/idle)
- Recent errors visible
- Can cancel stuck jobs

## Success Criteria

### Minimum Viable Product (MVP)
- ✅ 20 isolated user interfaces
- ✅ Central queue with FIFO scheduling
- ✅ 1 GPU worker processing jobs
- ✅ HTTPS with existing SSL cert
- ✅ Persistent user outputs
- ✅ Basic admin dashboard

### Nice-to-Have (v1.1)
- Round-robin scheduling mode
- Job priority system
- User model uploads
- Queue position ETA
- Resource usage metrics
- Mobile-responsive admin dashboard

### Workshop Ready Definition
1. All 20 users can access their unique URL
2. Jobs queue and complete successfully
3. Video generation workflows pre-loaded
4. Outputs persist and are downloadable
5. System runs stable for 8-hour workshop
6. Instructor can monitor and intervene
7. Documentation complete (user guide + admin guide)

## Out of Scope (v1.0)

- User authentication (assume trusted workshop participants)
- Payment/billing integration
- Multi-GPU support (single H100 only)
- Job scheduling (cron, recurring jobs)
- Workflow version control
- Collaborative editing (real-time multi-user on same workflow)
- Mobile app
- Email notifications

## Implementation Phases

MUST READ: implementation.md

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| H100 VRAM insufficient for 2+ models | High | Medium | Start with 1-2 models, test memory usage |
| Queue manager bugs during workshop | High | Medium | Extensive pre-testing, fallback to simple mode |
| Verda instance network issues | High | Low | Test deployment 3+ days before workshop |
| Video models too slow (>5min/job) | Medium | Medium | Set expectations, optimize settings |
| SSL cert compatibility issues | Medium | Low | Test nginx config locally first |
| Docker build fails on Verda | Medium | Low | Build locally, push to registry |

## Dependencies

**External Services:**
- Hetzner VPS to serve web app and comfyui
- Verda account with H100 access
- GitHub for code hosting
- Docker Hub for image hosting (optional)
- Domain: ahelme.net with SSL cert files

**Technical Knowledge:**
- Docker & Docker Compose
- Nginx configuration
- Python/FastAPI basics
- Redis basics
- ComfyUI workflow JSON format

## Open Questions

1. **Which video models to pre-install?** (TBD with user)
2. **User naming scheme:** user1-user20, or custom names?
3. **Job timeout:** Max runtime before auto-cancel?
4. **Storage limits:** Per-user quota or unlimited?
5. **Workflow sharing:** Can users share workflows with each other?

## Approval

**Status:** ✅ Approved - proceeding with custom build
**Date:** 2026-01-02
**Next Steps:** Create implementation plan and begin Phase 1
