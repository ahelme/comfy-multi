**Project:** ComfyUI Multi-User Workshop Platform
**Project Desc:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-31
**Doc Updated:** 2026-01-31

---

# ComfyUI Baseline Analysis: v0.8.1 → v0.8.2

## Executive Summary

This document analyzes ComfyUI versions v0.8.1 and v0.8.2, released on January 8, 2026, to understand the baseline state that ComfyMulti likely started from. These versions represent a critical point where the core architecture and APIs were established but before major breaking changes in subsequent releases.

**Key Findings:**
- Both v0.8.1 and v0.8.2 exist as official releases
- v0.8.2 is a minimal patch release (1 commit, 3 files changed)
- Core API structure was mature with userdata, custom nodes, and workflow management
- Docker deployment patterns were well-established
- Multi-user support existed via `--multi-user` flag

---

## Version Verification

### v0.8.1
- **Release Date:** January 8, 2026 (04:01 UTC)
- **Status:** Official release
- **Commits:** 12 commits from v0.8.0
- **Files Changed:** 11 files
- **Contributors:** 5 (comfyanonymous, kijai, rattus128, comfyui-wiki, and others)
- **Source:** https://github.com/Comfy-Org/ComfyUI/releases/tag/v0.8.1

### v0.8.2
- **Release Date:** January 8, 2026 (06:00 UTC)
- **Status:** Official release (minimal patch)
- **Commits:** 2 commits from v0.8.1
- **Files Changed:** 3 files
- **Contributors:** 1 (comfyanonymous)
- **Source:** https://github.com/Comfy-Org/ComfyUI/releases/tag/v0.8.2

**Timeline Context:**
- v0.8.0 released January 7, 2026
- v0.8.1 released ~18 hours later (January 8, 04:01)
- v0.8.2 released ~2 hours later (January 8, 06:00)
- v0.9.0 released January 13, 2026 (5 days later)

---

## Baseline State (v0.8.1/v0.8.2)

### Core Features Available

**Model Support:**
- LTXV 2 model support (19B parameters for video generation)
- NVFP4 checkpoint support
- Gemma 12B text encoder with quantized weights
- Sage Attention 3 (via CLI argument)
- FP8MM quantization with async offloading
- VAE memory estimation

**Workflow System:**
- Node-based graph interface
- Asynchronous queue processing
- Prompt validation and execution
- History tracking
- Workflow templates (v0.7.69 in v0.8.1)

**Custom Nodes:**
- Custom node extension system
- ComfyUI-Manager integration
- Multiple custom_nodes search paths
- Auto-discovery of installed nodes

**Multi-User Support:**
- `--multi-user` flag for user isolation
- User-specific storage and resources
- User management API

### API Endpoints (Available in v0.8.x)

**Core Routes:**
```
GET  /                    - Web interface (index.html)
GET  /ws                  - WebSocket for real-time updates
GET  /embeddings          - List available embeddings
GET  /extensions          - List registered extensions
```

**Model & Resource Management:**
```
GET  /models              - List model types
GET  /models/{folder}     - List models in specific folder
POST /free                - Unload models to free memory
```

**Queue & Execution:**
```
GET  /queue               - Get current queue status
POST /queue               - Clear or delete queue items
POST /prompt              - Submit workflow for execution
POST /interrupt           - Interrupt current execution
GET  /history             - Get execution history
GET  /history/{prompt_id} - Get specific prompt history
```

**Job Management:**
```
GET  /api/jobs            - List all jobs (filtering, sorting, pagination)
GET  /api/jobs/{job_id}   - Get single job details
```

**System Information:**
```
GET  /system_stats        - Device and memory information
GET  /features            - Server feature flags
GET  /object_info         - All node types and schemas
GET  /object_info/{node}  - Specific node details
```

**File Operations:**
```
POST /upload/image        - Upload images
POST /upload/mask         - Upload mask images
GET  /view                - View/download files with preview
GET  /view_metadata/{folder} - Get safetensors metadata
```

**User Data API (CRITICAL for ComfyMulti):**
```
GET    /userdata          - List user files (CRUD operations)
POST   /userdata          - Create/update user files
DELETE /userdata          - Delete user files
GET    /v2/userdata       - Enhanced structured file listing
```

**User Management:**
```
GET  /users               - Create and retrieve user information
POST /users               - Create new user
```

**Workflow Templates:**
```
GET  /workflow_templates  - Access custom node templates
```

### API Structure Insights

**WebSocket Communication (`/ws`):**
- Real-time execution status updates
- Progress notifications
- Error messages
- JSON message format

**Prompt Submission (`/prompt`):**
- Validates workflow before execution
- Returns `prompt_id` and queue position on success
- Returns `error` and `node_errors` on validation failure

**History Retrieval (`/history/{prompt_id}`):**
- Returns queue status or output
- Includes execution results

**View Endpoint (`/view`):**
- Returns images by filename, subfolder, and type
- Types: `input`, `output`, `temp`

**Userdata API:**
- Manages user-specific settings
- Configuration data storage
- File management (CRUD operations)
- v2 endpoint provides enhanced structured listing

### Directory Structure (v0.8.1)

```
ComfyUI/
├── api_server/              # API implementation
│   ├── routes/              # API route definitions
│   │   ├── user_data_routes.py (likely)
│   │   └── [other routes]
│   ├── services/            # Business logic
│   └── utils/               # Utilities
├── comfy/                   # Core engine
├── comfy_api/               # API layer
├── comfy_api_nodes/         # API-specific nodes
├── comfy_execution/         # Workflow execution
├── comfy_config/            # Configuration management
├── comfy_extras/            # Extended utilities
├── app/                     # Frontend application
├── middleware/              # Request/response processing
├── custom_nodes/            # Custom node extensions
├── models/                  # Model storage
│   ├── checkpoints/
│   ├── text_encoders/
│   ├── vae/
│   └── [other model types]
├── input/                   # User input files
├── output/                  # Generated outputs
├── user/                    # User data directory
│   └── default/
│       ├── workflows/       # User workflows (likely)
│       └── [settings]
├── server.py                # Main server entry point
├── main.py                  # Application launcher
├── requirements.txt         # Dependencies
└── Dockerfile               # Docker setup (community)
```

### Docker Deployment Approach

**Community Docker Images (v0.8 era):**
- Multiple community-maintained Dockerfiles
- CUDA 12.8 base images recommended
- PyTorch 2.8.0 with CUDA 12.8 runtime
- Volume mounts for models, inputs, outputs
- Environment variables for configuration
- Default port: 8188

**Typical Docker Setup:**
```dockerfile
FROM nvidia/cuda:12.8-runtime-ubuntu22.04
# Install Python 3.11+
# Install PyTorch 2.8.0+cu128
# Clone ComfyUI
# Install requirements
# Expose 8188
# CMD ["python", "main.py"]
```

**Volume Mounts:**
```yaml
volumes:
  - ./models:/comfyui/models
  - ./input:/comfyui/input
  - ./output:/comfyui/output
  - ./custom_nodes:/comfyui/custom_nodes
  - ./user:/comfyui/user
```

**Multi-User Mode:**
```bash
python main.py --multi-user
```

### Custom Node System State

**Installation Methods:**
1. Manual: Clone to `custom_nodes/` directory
2. ComfyUI-Manager: Install via web UI
3. Multiple search paths supported

**Custom Nodes Search Paths:**
- `./custom_nodes/` (default)
- User documents folder (OS-specific)
- AppData/Local folder (Windows)

**Auto-Discovery:**
- Scans custom_nodes directories on startup
- Registers nodes automatically
- No manual registration required

### Userdata API State

**Status:** EXISTED in v0.8.x

**Capabilities:**
- User-specific file management
- Configuration storage
- CRUD operations for user data
- Workflow storage (likely in `user/default/workflows/`)
- Settings persistence

**Multi-User Isolation:**
- Separate storage per user when `--multi-user` enabled
- User-specific resource allocation
- Isolated execution environments

---

## Changes in v0.8.2

### Summary
**Minimal patch release** addressing a single memory estimation issue.

### Commits (2 total)

1. **"Tweak ltxv vae mem estimation"** (#11722)
   - Author: comfyanonymous
   - Date: January 8, 2026
   - Commit: 50d6e1c

2. **"ComfyUI version v0.8.2"**
   - Version bump commit
   - Commit: 2e9d516

### Files Changed
- **3 files modified** (specific files not disclosed in web diff)
- Likely changes:
  - `comfy/ldm/modules/diffusionmodules/ltxv_vae.py` (or similar)
  - Version file
  - Changelog/release notes

### Nature of Change
**Memory optimization** for LTXV VAE (Video Auto-Encoder)
- Adjusts memory estimation calculations
- Improves VRAM usage predictions
- Follows v0.8.1's focus on memory optimization

### Impact
- **Non-breaking change**
- Internal optimization only
- No API changes
- No user-facing feature changes
- Compatible with v0.8.1 workflows

---

## Detailed Changelog: v0.8.0 → v0.8.1

### Model Support Improvements

**Gemma 12B Text Encoder:**
- Added support for Gemma 12B with quantized weights (#11696)
- Enables larger text encoding models
- Quantization reduces memory footprint

**LTXAV Enhancements:**
- Added device selection for LTXAVTextEncoderLoader (#11700)
- Lowered LTXV text encoder VRAM usage (#11713)
- Added memory estimation function (#11716)
- Increased LTXAV memory estimation (#11715)

### Performance & Bug Fixes

**FP8MM Offloading:**
- Fixed offloading with FP8MM performance (#11697)
- Resolved issues preventing FP8MM quantization with async offload

**Model Patcher:**
- Removed confusing "1e32" memory indicator (#11710)
- Simplified load statistics reporting

**Workflow Fixes:**
- Fixed stable release workflow not pulling latest comfy-kitchen (#11695)
- Bumped required comfy-kitchen version (#11714)

### Developer Experience

**PyTorch Warning:**
- Added warning for old PyTorch versions (#11718)
- Recommends upgrading to cu130 for performance boost

**Template Updates:**
- Updated workflow templates to v0.7.69 (#11719)

---

## Impact on ComfyMulti

### What We Likely Started With

**Baseline Version:** v0.8.1 or v0.8.2 (January 8, 2026)

**Evidence:**
1. Project started January 2, 2026 (CLAUDE.md)
2. First documented work with v0.9.2 (noted in CLAUDE.md)
3. v0.8.x would have been the latest stable before v0.9.0 (January 13)

**Architecture Inherited:**
- Multi-user support via `--multi-user` flag
- Userdata API for user-specific storage
- Custom nodes system
- Queue management
- WebSocket real-time updates
- Docker deployment patterns

### Features We Had from the Start

**Available in v0.8.2:**
- ✅ Userdata API (`/userdata`, `/v2/userdata`)
- ✅ Multi-user mode (`--multi-user`)
- ✅ Workflow management (via userdata)
- ✅ Custom nodes support
- ✅ Queue system (`/queue`, `/prompt`)
- ✅ WebSocket updates (`/ws`)
- ✅ File uploads (`/upload/image`, `/upload/mask`)
- ✅ History tracking (`/history`)
- ✅ Job management (`/api/jobs`)
- ✅ System stats (`/system_stats`)
- ✅ LTXV 2 model support (19B video generation)
- ✅ Docker deployment capability

### Features We Never Had (Post-v0.8.2)

**Added in v0.9.0 or later:**
- V3 API enhancements
- Additional model integrations (Kling Omni, WAN2.6, Tripo3D)
- Desktop application
- Enhanced workflow template system
- Additional memory optimizations
- Breaking API changes (see separate migration docs)

### ComfyMulti-Specific Customizations

**What We Built on Top of v0.8.x:**
1. **20 Isolated User Containers:**
   - Built on `--multi-user` foundation
   - Per-user ComfyUI frontend instances
   - Separate userdata directories per user

2. **Centralized Queue Manager:**
   - FastAPI service wrapping ComfyUI queue
   - FIFO/round-robin/priority scheduling
   - WebSocket aggregation across users

3. **Split Architecture:**
   - CPU-only frontends on Hetzner VPS
   - GPU workers on Verda Cloud
   - Redis job queue over Tailscale VPN

4. **Nginx Reverse Proxy:**
   - SSL termination (existing ahelme.net cert)
   - HTTP Basic Auth per user
   - Routing to user containers (`/user001/` → container)

5. **Persistent Storage:**
   - Per-user data volumes (`./data/user_data/userXXX/`)
   - Shared model storage (`./data/models/shared/`)
   - Workflow templates (`./data/workflows/`)

6. **Admin Dashboard:**
   - Queue monitoring
   - User management
   - Health checks

### Baseline Understanding for Migration

**Critical Insight:**
v0.8.1/v0.8.2 had a **mature and stable API** that we built ComfyMulti on top of. This means:

1. **API Compatibility Expectations:**
   - Userdata API should work the same
   - Workflow storage patterns should be consistent
   - Queue management API should be familiar

2. **Migration Risks:**
   - Breaking changes in v0.9.0+ could affect our customizations
   - Need to verify userdata API compatibility in later versions
   - Docker setup may need updates for newer CUDA versions

3. **Upgrade Strategy:**
   - Can skip v0.8.2 → v0.9.0 intermediate versions if APIs stable
   - Must test multi-user mode in newer versions
   - Verify userdata workflow storage location consistency

4. **Known Stable Patterns:**
   - `user/default/workflows/` for workflow storage
   - `/api/userdata?dir=workflows` for workflow listing
   - `/ws` for real-time updates
   - `/prompt` for job submission

---

## Technical Specifications (v0.8.2 Baseline)

### Dependencies

**Python:** 3.11+
**PyTorch:** 2.8.0+cu128 (CUDA 12.8)
**CUDA:** 12.8 runtime
**Key Libraries:**
- aiohttp (server framework)
- requests (HTTP client)
- safetensors (model format)
- PIL/Pillow (image processing)

### System Requirements

**GPU:**
- NVIDIA GPU with CUDA support
- 8GB+ VRAM for basic models
- 24GB+ VRAM for LTXV 2 (19B)

**CPU:**
- Multi-core CPU (4+ cores recommended)
- Can run in CPU-only mode (very slow)

**Memory:**
- 16GB+ RAM recommended
- Varies by model size

**Storage:**
- Models: 50GB+ (for full model collection)
- Outputs: Variable (depends on usage)

### Network Ports

**Default:** 8188 (HTTP)
**WebSocket:** Same port (8188)
**Custom:** Configurable via CLI args

### CLI Arguments (v0.8.x)

```bash
python main.py \
  --multi-user              # Enable multi-user mode
  --listen 0.0.0.0          # Listen on all interfaces
  --port 8188               # Custom port
  --cpu                     # CPU-only mode
  --preview-method auto     # Preview generation method
  --sage-attention-3        # Enable Sage Attention 3
```

---

## Comparison with Current ComfyMulti (v0.9.2)

### What Changed in Our Deployment

**ComfyMulti Currently Uses:** v0.9.2 (as of Session 18)

**From v0.8.2 → v0.9.2:**
- See separate migration analysis: `migration-analysis-v0.8.2-to-v0.9.0.md`
- See separate migration analysis: `migration-analysis-v0.9.0-to-v0.9.2.md`

**Key Differences:**
1. **Userdata API location changed** (v0.9.x)
   - v0.8.x: `/comfyui/input/` (legacy)
   - v0.9.x: `/comfyui/user/default/workflows/` (new)

2. **Docker entrypoint updates:**
   - Added workflow copying logic (Session 18 fix)
   - Healthcheck dependencies (curl, libgomp1, requests)

3. **Custom nodes handling:**
   - Volume mount per user (overwrites container defaults)
   - Need to copy default nodes to each user directory

4. **Model support expanded:**
   - Added Flux.2 Klein (image generation)
   - Kept LTXV 2 (video generation)

### Compatibility Notes

**What Still Works:**
- ✅ Multi-user mode fundamentals
- ✅ Queue management patterns
- ✅ WebSocket communication
- ✅ Custom nodes system
- ✅ Docker deployment approach

**What Needed Updates:**
- ⚠️ Userdata workflow location
- ⚠️ Docker healthchecks
- ⚠️ Custom nodes volume mounting
- ⚠️ Model paths and naming

---

## Migration Planning Insights

### For Future Upgrades

**Low Risk Changes:**
- Memory optimizations (like v0.8.2)
- Performance improvements
- Bug fixes in execution logic

**Medium Risk Changes:**
- New model support
- API endpoint additions (non-breaking)
- CLI argument additions

**High Risk Changes:**
- Userdata API changes
- Multi-user mode modifications
- Queue system refactoring
- Docker base image updates

### Testing Checklist for Upgrades

Before upgrading ComfyMulti to newer ComfyUI versions:

1. **API Compatibility:**
   - [ ] Verify `/userdata` endpoint still works
   - [ ] Check workflow storage location (`user/default/workflows/`)
   - [ ] Test multi-user mode (`--multi-user`)
   - [ ] Confirm queue API (`/queue`, `/prompt`)

2. **Frontend Functionality:**
   - [ ] Load workflows from userdata API
   - [ ] Submit jobs via `/prompt`
   - [ ] Receive WebSocket updates
   - [ ] Upload files (`/upload/image`)

3. **Worker Compatibility:**
   - [ ] GPU workers connect to queue
   - [ ] Model loading works
   - [ ] Custom nodes load correctly
   - [ ] Outputs saved to correct locations

4. **Docker Deployment:**
   - [ ] Containers build successfully
   - [ ] Healthchecks pass
   - [ ] Volume mounts work
   - [ ] Networking configured correctly

5. **Multi-User Isolation:**
   - [ ] Users see separate workflows
   - [ ] Outputs isolated per user
   - [ ] Queue jobs tracked correctly

---

## References

### Official Sources
- [ComfyUI v0.8.1 Release](https://github.com/Comfy-Org/ComfyUI/releases/tag/v0.8.1)
- [ComfyUI v0.8.2 Release](https://github.com/Comfy-Org/ComfyUI/releases/tag/v0.8.2)
- [ComfyUI Changelog](https://docs.comfy.org/changelog)
- [ComfyUI API Routes Documentation](https://docs.comfy.org/development/comfyui-server/comms_routes)
- [ComfyUI GitHub Repository](https://github.com/comfyanonymous/ComfyUI)

### Community Resources
- [YanWenKun/ComfyUI-Docker](https://github.com/YanWenKun/ComfyUI-Docker)
- [AI-Dock ComfyUI Images](https://github.com/ai-dock/comfyui)
- [SaladCloud ComfyUI Deployment Guide](https://docs.salad.com/container-engine/how-to-guides/ai-machine-learning/deploy-stable-diffusion-comfy)
- [9elements ComfyUI API Guide](https://9elements.com/blog/hosting-a-comfyui-workflow-via-api/)

### ComfyMulti Project
- [ComfyMulti CLAUDE.md](/home/dev/projects/comfyui/CLAUDE.md)
- [ComfyMulti Progress Log](/home/dev/projects/comfyui/progress-02.md)
- [Session 18 Workflow Path Fix](/home/dev/projects/comfyui/progress-02.md#session-18)

---

## Conclusion

**ComfyUI v0.8.1 and v0.8.2 represent a solid baseline** with mature APIs, multi-user support, and Docker deployment patterns. The minimal nature of the v0.8.2 patch (1 commit, memory optimization) shows the codebase was stable at this point.

**For ComfyMulti:**
- We likely built on v0.8.x foundations (January 2026)
- Core APIs (userdata, queue, WebSocket) were already established
- Multi-user mode existed, we extended it with isolation containers
- Migration to newer versions requires careful API compatibility testing

**Next Steps:**
- See `migration-analysis-v0.8.2-to-v0.9.0.md` for the HUGE migration
- Review breaking changes in v0.9.x series
- Plan upgrade path considering API stability

---

**Document Version:** 1.0
**Last Updated:** 2026-01-31
**Author:** Claude Code (research assistant)
