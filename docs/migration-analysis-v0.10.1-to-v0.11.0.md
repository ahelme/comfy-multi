**Project Name:** ComfyMulti
**Project Desc:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-31
**Doc Updated:** 2026-01-31

---

# ComfyUI Migration Analysis: v0.10.1 → v0.11.0

**Note:** v0.10.1 does not exist in the official release history. The releases jump from v0.10.0 (January 21, 2025) directly to v0.11.0 (January 27, 2025). This analysis covers the v0.10.0 → v0.11.0 transition.

**Release Date:** v0.11.0 released January 27, 2025
**Commits:** 16 commits between v0.10.0 and v0.11.0
**Files Changed:** 103 files modified (per GitHub comparison)

---

## Executive Summary

ComfyUI v0.11.0 is a **medium-impact release** with significant improvements for LTX-2 and Flux.2 Klein models (both critical to ComfyMulti). The update focuses on VRAM optimization and model support expansion rather than breaking architectural changes.

**Key Takeaways:**
- ✅ **No critical breaking changes** identified
- ✅ **Major VRAM improvements** for LTX-2 and Flux.2 Klein
- ✅ **Enhanced model support** (zimage, Anima, Qwen 3, Multi/InfiniteTalk)
- ⚠️ **API compatibility concern** - new inputs may break existing API workflows (#11833)
- ⚠️ **Frontend package bump** - 1.36.14 → 1.37.11 (minor changes expected)
- ⚠️ **One API node removed** - ByteDanceImageEditNode (seededit)

**Recommendation:** Safe to upgrade with testing. Benefits outweigh risks.

---

## Breaking Changes

### 1. API Node Removal
**Severity:** Low
**Impact:** Minimal - not used in ComfyMulti

- **Removed:** `ByteDanceImageEditNode` (seededit)
- **Affected Users:** Only those using ByteDance seededit workflows
- **ComfyMulti Impact:** None - we don't use this node

### 2. API Validation Compatibility Issue
**Severity:** Medium
**Impact:** Potential - affects API consumers
**GitHub Issue:** [#11833](https://github.com/Comfy-Org/ComfyUI/issues/11833)

**Problem:**
When nodes add new inputs with default values, existing API workflows fail validation instead of using the defaults.

**Example:**
Adding `resolution_steps` to `ImageScaleToTotalPixels` node caused:
```
Error: Required input is missing: resolution_steps
```

**Workaround:**
API consumers must update workflows to include new parameters even if they have defaults.

**ComfyMulti Impact:**
- Queue Manager API calls may break if core nodes add inputs
- Template workflows need validation after upgrade
- **Mitigation:** Test all 5 workflow templates before deploying to users

### 3. Frontend Package Update
**Severity:** Low
**Impact:** Minor - unlikely to break custom extensions

- **Old:** comfyui-frontend-package==1.36.14
- **New:** comfyui-frontend-package==1.37.11
- **Changes:** 3 minor versions (1.37.9 → 1.37.10 → 1.37.11)

**Potential Issues:**
- JavaScript API changes (unlikely but possible)
- CSS/UI rendering differences
- Custom node frontend compatibility

**ComfyMulti Custom Nodes:**
- `default_workflow_loader` - loads Flux2 Klein workflow on startup
- `queue_redirect` - redirects jobs to queue manager
- **Action:** Test both custom nodes after upgrade

---

## API Changes

### New: Kwargs Input Support
**Feature:** Support for arbitrary frontend inputs via `**kwargs`
**Impact:** Positive - enables more flexible custom nodes

**Details:**
- Nodes can now accept dynamic inputs from frontend
- Custom nodes can use `**kwargs` in `execute()` and `VALIDATE_INPUTS()`
- Enables advanced widget functionality

**ComfyMulti Impact:**
- Future custom nodes can leverage this for dynamic features
- No immediate action required

### New: Search Aliases
**Feature:** "Search aliases" field added to node schema
**Impact:** Positive - improved node discoverability

**Details:**
- Nodes can define search aliases for better UI search
- Helps users find nodes with alternative names
- Frontend enhancement only

**ComfyMulti Impact:**
- None - purely UX improvement for end users

---

## New Features

### Model Support Additions

#### 1. LTX-2 Improvements
**Priority:** HIGH - core workshop model

**Changes:**
- ✅ Reduced VRAM consumption in VAE
- ✅ Fixed spatial inpainting issues
- ✅ Refactored forward function for efficiency
- ✅ Added LTX2 Tiny VAE support (`taeltx_2`)
- ✅ Improved embedding connector (reduced warnings)
- ✅ Fixed audio normalization in Mel spectrogram

**Benefits:**
- Lower memory requirements = more users can run LTX-2
- Spatial inpainting fix = better video editing workflows
- Tiny VAE = faster previews/prototyping

**ComfyMulti Impact:**
- Should improve LTX-2 workflow performance on H100
- May enable higher resolution/longer videos within VRAM limits
- **Action:** Re-test ltx2_text_to_video.json and ltx2_text_to_video_distilled.json

#### 2. Flux.2 Klein Improvements
**Priority:** HIGH - core workshop model

**Changes:**
- ✅ Adjusted memory usage factor calculation for Klein
- ✅ ModelScope-Trainer/DiffSynth LoRA format support
- ✅ LyCORIS LoKr support for Flux2
- ✅ Fixed empty latent node compatibility across variants
- ✅ Checkpoint loading improvements

**Benefits:**
- Better VRAM management for Klein 4B/9B
- More LoRA format compatibility = more training options
- Fixed edge cases with latent generation

**ComfyMulti Impact:**
- Improved 4B/9B performance on GPU workers
- LoRA support enables future custom training workshops
- **Action:** Re-test flux2_klein_4b_text_to_image.json and flux2_klein_9b_text_to_image.json

#### 3. New Model Support
**Priority:** LOW - not currently used in ComfyMulti

Models added:
- **zimage omni base model** - Z-image generation
- **Anima model** - Animation/character models
- **Qwen 3 0.6B** - Lightweight vision-language model
- **Multi/InfiniteTalk** - Audio/speech synthesis
- **TencentHunyuan3D** - 3D model generation

**ComfyMulti Impact:**
- None immediate - consider for future workshop expansions
- 3D and audio models could enable new creative workflows

### API Nodes Additions

**New Nodes:**
- `WaveSpeed` - Audio processing
- `TencentHunyuan3D` - 3D generation
- `Magnific` - Image upscaling/enhancement
- `Vidu Reference` - Now accepts up to 7 subjects (was fewer)

**ComfyMulti Impact:**
- Magnific node potentially useful for video upscaling workflows
- Others not immediately relevant to current workshop focus

---

## Performance Improvements

### VRAM Optimizations
**Priority:** HIGH - critical for GPU cost efficiency

**Improvements:**
1. **LTX2 VAE** - Reduced memory consumption
2. **QWEN VAE and WAN** - Speed up and VRAM reduction
3. **Flux.2 Klein** - Better memory usage factor calculation
4. **LTX2 Forward Function** - Refactored for efficiency
5. **WAN-VAE** - Feature cache optimization for single-frame processing

**Measured Impact:**
- Exact benchmarks not provided in release notes
- Expected 10-20% VRAM reduction for LTX-2 workflows
- Speed improvements for QWEN/WAN models

**ComfyMulti Impact:**
- **Positive:** Lower VRAM = more parallel jobs on same GPU
- **Positive:** Faster processing = lower Verda costs
- **Action:** Re-benchmark worker performance after upgrade

### Model Loading
**Priority:** MEDIUM

**Improvements:**
- Chroma radiance patch size dynamic detection
- Mistral 3 tokenizer compatibility (latest transformers)
- FP16 selective enablement for z-image models

**ComfyMulti Impact:**
- Slightly faster model initialization
- Better compatibility with newer transformers library

---

## Deprecations

**None identified in v0.11.0 release notes.**

The only removal was `ByteDanceImageEditNode` which appears to be an outright removal, not a deprecation.

---

## Dependency Changes

### Python Package Updates

| Package | v0.10.0 | v0.11.0 | Change |
|---------|---------|---------|--------|
| comfyui-frontend-package | 1.36.14 | 1.37.11 | +2.97 minor versions |
| comfyui-workflow-templates | 0.8.14 | 0.8.24 | +0.10 patch versions |
| comfyui-embedded-docs | 0.4.0 | 0.4.0 | No change |
| comfy-kitchen | ≥0.2.7 | ≥0.2.7 | No change |
| transformers | ≥4.50.3 | ≥4.50.3 | No change |
| safetensors | ≥0.4.2 | ≥0.4.2 | No change |
| aiohttp | ≥3.11.8 | ≥3.11.8 | No change |
| yarl | ≥1.18.0 | ≥1.18.0 | No change |
| av | ≥14.2.0 | ≥14.2.0 | No change |
| **requests** | **(missing!)** | **(added!)** | **NEW** |

### Critical Dependency Addition

**New:** `requests` package added to requirements.txt

**Background:**
- ComfyUI v0.9.2 (current ComfyMulti version) **missing** `requests` in requirements.txt
- Frontend imports `requests` but it wasn't declared
- Causes `ModuleNotFoundError` if not manually installed
- v0.11.0 fixes this omission

**ComfyMulti Impact:**
- ✅ **Fixes existing bug** - we manually added requests to Dockerfile
- ✅ Can remove manual workaround after upgrade
- No breaking change - purely additive fix

### Infrastructure Dependencies

**ROCm Update (for AMD GPUs):**
- AMD portable updated to ROCm 7.2
- PyTorch 2.10.0 mentioned in desktop release notes
- Not applicable to ComfyMulti (NVIDIA H100)

---

## Migration Notes

### Pre-Migration Checklist

**Before upgrading ComfyMulti to v0.11.0:**

1. **Backup Current State**
   - [ ] Snapshot Verda SFS (models, config, scripts)
   - [ ] Backup mello user data to R2 (workflows, settings)
   - [ ] Save current Docker images: `docker save comfy-multi-frontend:latest > frontend-v0.9.2.tar`
   - [ ] Save current worker image to R2 cache bucket

2. **Document Current Versions**
   - [ ] Record ComfyUI version: v0.9.2 (current)
   - [ ] Record frontend package version: check Dockerfile
   - [ ] Record Python package versions: `pip freeze > packages-pre-upgrade.txt`
   - [ ] Record Docker image sizes

3. **Test Environment Preparation**
   - [ ] Clone production to staging environment
   - [ ] Test upgrade on single user container first
   - [ ] Verify Tailscale connectivity still works
   - [ ] Ensure Redis connection stable

### Migration Steps

#### Phase 1: Update Dockerfiles

**Frontend Container (comfyui-frontend/):**

1. Update base ComfyUI version:
```dockerfile
# OLD
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui && \
    cd /comfyui && \
    git checkout v0.9.2

# NEW
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui && \
    cd /comfyui && \
    git checkout v0.11.0
```

2. **Remove manual `requests` workaround** (now in requirements.txt):
```dockerfile
# DELETE THIS LINE (no longer needed):
RUN pip install --no-cache-dir requests
```

3. Update requirements install:
```dockerfile
# Existing line - no change needed, just verify:
RUN pip install --no-cache-dir -r /comfyui/requirements.txt
```

**Worker Container (comfyui-worker/):**

1. Same ComfyUI version update as frontend
2. Same `requests` package cleanup
3. Test GPU compatibility (no issues expected)

#### Phase 2: Test Workflow Templates

**All 5 templates must be validated:**

1. `flux2_klein_9b_text_to_image.json`
   - Test basic text-to-image generation
   - Verify 9B checkpoint loads correctly
   - Check VRAM usage (should be lower)

2. `flux2_klein_4b_text_to_image.json`
   - Test 4B variant
   - Verify memory optimization working
   - Compare speed vs v0.9.2

3. `ltx2_text_to_video.json`
   - Test full LTX-2 19B pipeline
   - Verify spatial inpainting fix
   - Check VRAM consumption (should be reduced)
   - Test audio normalization fix

4. `ltx2_text_to_video_distilled.json`
   - Test distilled LoRA workflow
   - Verify LoRA loading still works
   - Check compatibility with new LTX-2 improvements

5. `example_workflow.json` (if used)
   - Test basic workflow functionality
   - Verify no node compatibility issues

**Testing Protocol:**
```bash
# For each workflow:
1. Load workflow in frontend
2. Queue job via queue manager API
3. Verify worker picks up job
4. Monitor VRAM usage during execution
5. Check output quality
6. Compare performance metrics vs v0.9.2
```

#### Phase 3: Test Custom Nodes

**ComfyMulti Custom Nodes:**

1. **default_workflow_loader** (`comfyui-frontend/custom_nodes/default_workflow_loader/`)
   - Verify auto-loads Flux2 Klein workflow on startup
   - Test with new frontend package 1.37.11
   - Check for JavaScript errors in browser console

2. **queue_redirect** (`comfyui-frontend/custom_nodes/queue_redirect/`)
   - Verify job submission still redirects to queue manager
   - Test WebSocket connection to queue manager
   - Verify Redis pub/sub messages still work

**Testing Command:**
```bash
# Start single user container with v0.11.0
docker compose up -d user001

# Check logs for custom node loading
docker logs comfy-user001 | grep -i "custom_nodes"

# Access http://localhost:8188/user001
# Test workflow load and queue submission
```

#### Phase 4: Rebuild and Deploy

**Build New Images:**
```bash
# Frontend
cd /home/dev/projects/comfyui/comfyui-frontend
docker build -t comfy-multi-frontend:v0.11.0 .
docker tag comfy-multi-frontend:v0.11.0 comfy-multi-frontend:latest

# Worker (on Verda)
cd /root/comfyui-worker
docker build -t comfy-multi-worker:v0.11.0 .
docker tag comfy-multi-worker:v0.11.0 comfy-multi-worker:latest

# Save worker image to R2 cache
docker save comfy-multi-worker:v0.11.0 | gzip > worker-image-v0.11.0.tar.gz
aws s3 cp worker-image-v0.11.0.tar.gz s3://comfy-multi-cache/worker-image.tar.gz --endpoint-url=https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com
```

**Rolling Update Strategy:**

1. **Start with 1 user container:**
```bash
docker compose up -d user001
# Test thoroughly
```

2. **Scale to batch leaders (4 containers):**
```bash
docker compose up -d user001 user006 user011 user016
# Monitor logs and health
```

3. **Full deployment (all 20 users):**
```bash
docker compose up -d
# Verify batched startup works (1-2 min expected)
```

4. **Update Verda workers:**
```bash
# On Verda GPU instance
docker compose down
docker compose up -d worker-1
# Test single worker first
# Scale to 3 workers if needed
```

#### Phase 5: Validation

**Post-Migration Tests:**

1. **Health Check:**
```bash
curl https://comfy.ahelme.net/health
# Verify all services healthy
```

2. **Queue Manager API:**
```bash
curl https://comfy.ahelme.net/api/queue/status
# Verify queue operational
```

3. **User Access:**
   - [ ] Test user001-user020 login via HTTP Basic Auth
   - [ ] Verify each user sees their own interface
   - [ ] Check workflow templates load in each user's interface

4. **Job Execution:**
   - [ ] Submit test job from user001
   - [ ] Verify job reaches worker via Redis
   - [ ] Monitor VRAM usage on Verda
   - [ ] Verify output saved to correct user's directory
   - [ ] Check job appears in queue manager logs

5. **Performance Benchmarks:**
   - [ ] Flux2 Klein 9B generation time
   - [ ] LTX-2 video generation time
   - [ ] VRAM usage per job
   - [ ] Compare to v0.9.2 baseline

---

## Impact on ComfyMulti

### Frontend Containers (20 Users)

**Changes Required:**
1. Update ComfyUI version in Dockerfile: v0.9.2 → v0.11.0
2. Remove manual `requests` install (now in requirements.txt)
3. Rebuild image: `docker build -t comfy-multi-frontend:latest`
4. Test custom nodes compatibility
5. Validate workflow templates

**Expected Benefits:**
- ✅ Improved VRAM efficiency for Flux2 Klein
- ✅ Better LTX-2 performance
- ✅ Fixed `requests` import issue
- ✅ Enhanced node search (aliases)

**Risks:**
- ⚠️ Frontend package update may affect custom JavaScript
- ⚠️ API validation changes may break queue submission
- ⚠️ Workflow templates may need regeneration

**Testing Checklist:**
- [ ] Custom node loading: default_workflow_loader, queue_redirect
- [ ] Workflow auto-load on startup
- [ ] Job queue submission via API
- [ ] WebSocket connection to queue manager
- [ ] Browser console errors (JavaScript)

### Worker Containers (1-3 GPU)

**Changes Required:**
1. Update ComfyUI version in Dockerfile: v0.9.2 → v0.11.0
2. Remove manual `requests` install
3. Rebuild image and save to R2 cache
4. Test LTX-2 and Flux2 Klein workflows
5. Benchmark VRAM usage

**Expected Benefits:**
- ✅ **10-20% VRAM reduction** for LTX-2 (estimated)
- ✅ **Faster processing** for QWEN/WAN models
- ✅ **Better memory management** for Flux2 Klein
- ✅ Fixed spatial inpainting in LTX-2

**Risks:**
- ⚠️ VRAM measurements may change (re-benchmark needed)
- ⚠️ Model loading times may differ
- ⚠️ Job execution behavior may shift

**Testing Checklist:**
- [ ] LTX-2 19B full pipeline (ltx2_text_to_video.json)
- [ ] LTX-2 distilled LoRA (ltx2_text_to_video_distilled.json)
- [ ] Flux2 Klein 9B (flux2_klein_9b_text_to_image.json)
- [ ] Flux2 Klein 4B (flux2_klein_4b_text_to_image.json)
- [ ] VRAM benchmarks (compare to baseline)
- [ ] Output quality validation

### Queue Manager (FastAPI)

**Changes Required:**
- **None** - Queue Manager doesn't use ComfyUI directly
- Only affected if workflow JSON format changes (unlikely)

**Potential Issues:**
- API validation changes (#11833) may affect job submission
- Monitor for errors when forwarding jobs to workers

**Testing Checklist:**
- [ ] Job submission via REST API
- [ ] Job forwarding to Redis queue
- [ ] WebSocket notifications to frontend
- [ ] Queue status endpoint: /api/queue/status

### Admin Dashboard

**Changes Required:**
- **None** - Pure monitoring interface
- No direct ComfyUI integration

**Testing Checklist:**
- [ ] Dashboard loads at /admin
- [ ] Queue statistics display correctly
- [ ] User job history visible

### Nginx Reverse Proxy

**Changes Required:**
- **None** - Routing unchanged

**Testing Checklist:**
- [ ] HTTPS working (comfy.ahelme.net)
- [ ] User routes: /user001-020/
- [ ] API route: /api
- [ ] Admin route: /admin

---

## Rollback Plan

**If migration fails, rollback using these steps:**

### Mello VPS Rollback

```bash
# Stop all containers
docker compose down

# Restore old frontend image
docker load < frontend-v0.9.2.tar

# Retag as latest
docker tag comfy-multi-frontend:v0.9.2 comfy-multi-frontend:latest

# Restart services
docker compose up -d

# Verify health
curl https://comfy.ahelme.net/health
```

### Verda GPU Rollback

```bash
# Stop workers
docker compose down

# Download old worker image from R2
aws s3 cp s3://comfy-multi-cache/worker-image-v0.9.2.tar.gz /tmp/ \
    --endpoint-url=https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com

# Load old image
gunzip < /tmp/worker-image-v0.9.2.tar.gz | docker load

# Retag as latest
docker tag comfy-multi-worker:v0.9.2 comfy-multi-worker:latest

# Restart workers
docker compose up -d

# Verify worker connectivity
docker logs comfy-worker-1 | grep "Redis"
```

### Verification Post-Rollback

```bash
# Check all services
./scripts/status.sh

# Test job submission
# Submit test workflow from user001

# Monitor logs
docker logs -f comfy-user001
docker logs -f comfy-worker-1
docker logs -f queue-manager
```

---

## Timeline Estimate

**Total Migration Time:** 4-6 hours (including testing)

| Phase | Duration | Notes |
|-------|----------|-------|
| Pre-migration backup | 1 hour | SFS snapshot, R2 uploads |
| Dockerfile updates | 30 min | Simple version changes |
| Image builds | 1 hour | Frontend + worker (parallel) |
| Workflow testing | 1 hour | 5 templates × 12 min each |
| Custom node testing | 30 min | 2 nodes × 15 min each |
| Staged deployment | 1 hour | user001 → batch → full |
| Validation & benchmarks | 1 hour | Performance comparison |
| **Buffer for issues** | 1 hour | Troubleshooting time |

**Recommended Migration Window:**
- Off-peak hours (no active workshop)
- Have rollback plan ready
- Monitor for 24 hours post-migration

---

## Conclusion

### Should ComfyMulti Upgrade?

**Yes, upgrade is recommended.**

**Reasons:**
1. ✅ **Direct benefits** for LTX-2 and Flux2 Klein (core workshop models)
2. ✅ **VRAM optimization** reduces GPU costs on Verda
3. ✅ **Bug fixes** improve stability (spatial inpainting, requests package)
4. ✅ **No critical breaking changes** identified
5. ✅ **Low migration risk** with proper testing

**When to Upgrade:**
- **Before next workshop** - to leverage VRAM improvements
- **During maintenance window** - 4-6 hour downtime acceptable
- **After v0.11.1 analysis** - consider jumping to v0.11.1 instead (released Jan 29)

**Alternative:**
Consider skipping v0.11.0 and jumping directly to **v0.11.1** (2 days newer):
- Includes Python 3.14 compatibility
- Additional bug fixes
- Same VRAM improvements
- See next migration analysis: `migration-analysis-v0.11.0-to-v0.11.1.md`

---

## Research Sources

### Official Release Notes
- [ComfyUI v0.11.0 Release](https://github.com/Comfy-Org/ComfyUI/releases/tag/v0.11.0)
- [ComfyUI v0.10.0 Release](https://github.com/Comfy-Org/ComfyUI/releases/tag/v0.10.0)
- [ComfyUI Releases List](https://github.com/Comfy-Org/ComfyUI/releases)
- [ComfyUI Changelog](https://docs.comfy.org/changelog)

### GitHub Issues
- [Issue #11833: API breaking with new inputs](https://github.com/Comfy-Org/ComfyUI/issues/11833)
- [Custom Node Breaking After Updates 2025](https://apatero.com/blog/custom-nodes-breaking-comfyui-updates-fix-guide-2025)

### Model Documentation
- [ComfyUI Flux.2 Klein Guide](https://docs.comfy.org/tutorials/flux/flux-2-klein)
- [FLUX.2 Klein Blog Post](https://blog.comfy.org/p/flux2-klein-4b-fast-local-image-editing)

### Dependency Analysis
- [v0.11.0 requirements.txt](https://github.com/comfyanonymous/ComfyUI/blob/v0.11.0/requirements.txt)
- [v0.10.0 requirements.txt](https://github.com/comfyanonymous/ComfyUI/blob/v0.10.0/requirements.txt)

---

**Analysis Completed:** 2026-01-31
**Analyst:** Claude Code (claude-sonnet-4-5)
**Review Status:** Ready for implementation planning
