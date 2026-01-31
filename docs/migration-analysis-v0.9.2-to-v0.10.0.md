**Project Name:** ComfyMulti
**Project Desc:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-31
**Doc Updated:** 2026-01-31

---

# ComfyUI Migration Analysis: v0.9.2 → v0.10.0

**Release Date:** v0.10.0 released January 21, 2025
**Commits Between Versions:** 22 commits
**Overall Assessment:** **LOW RISK** - Mostly incremental improvements, no breaking API changes

---

## Executive Summary

ComfyUI v0.10.0 is a **minor incremental release** with **no breaking changes** to core APIs or server endpoints. The update focuses on:

1. **Internal API improvements** (advanced widgets, autogrow validation)
2. **Audio handling fixes** (AMD GPU compatibility, LTXV mono-to-stereo)
3. **API nodes discovery automation** (reduces merge conflicts)
4. **Dependency updates** (comfy-kitchen 0.2.6 → 0.2.7, workflow templates)
5. **New API nodes** (Bria Edit, ByteDance extensions)

**Migration Complexity:** **TRIVIAL** - Drop-in replacement with no code changes required.

---

## Breaking Changes

**NONE IDENTIFIED**

No breaking changes to:
- Server API endpoints
- Custom node APIs
- Frontend/backend communication
- Docker deployment
- Configuration files
- User data structures

---

## API Changes

### 1. Advanced Widget Support (comfy_api/latest/_io.py)

**Impact:** LOW - Optional parameter for custom nodes

**Change:** Added `advanced` parameter to all Input classes:
- `Input`, `WidgetInput`, `Boolean`, `Int`, `Float`, `String`, `Combo`, `MultiCombo`, `Webcam`, `MultiType`, `MatchType`, `ImageCompare`

**Purpose:** Allows custom nodes to mark inputs as "advanced" for collapsible UI sections in frontend.

**Example:**
```python
# Before (v0.9.2):
Int(id="quality", default=80)

# After (v0.10.0 - backward compatible):
Int(id="quality", default=80, advanced=True)  # Optional parameter
```

**Impact on ComfyMulti:**
- **None** - This is an optional parameter for custom node authors
- Our frontend containers use default ComfyUI UI, which will automatically support this
- No changes needed to our codebase

### 2. Autogrow Validation Improvements (comfy_api/latest/_io.py)

**Impact:** LOW - Internal validation fix

**Change:** Fixed Autogrow input validation for edge cases:
- Properly distinguishes required vs optional inputs
- Handles case where all inputs are optional and nothing is connected
- Adds `DynamicPathsDefaultValue.EMPTY_DICT` for empty optional autogrow inputs

**Impact on ComfyMulti:**
- **None** - We don't use Autogrow inputs in our custom nodes
- Improves stability for users who install custom nodes with autogrow inputs

### 3. API Nodes Auto-Discovery (nodes.py)

**Impact:** NONE - Internal refactor

**Change:**
- **Before:** Hardcoded list of 26 API node files in `init_builtin_api_nodes()`
- **After:** Auto-discovers all `nodes_*.py` files via `glob.glob()`

**Code Diff:**
```python
# Before (v0.9.2):
api_nodes_files = [
    "nodes_ideogram.py",
    "nodes_openai.py",
    # ... 24 more files
]

# After (v0.10.0):
api_nodes_files = sorted(glob.glob(os.path.join(api_nodes_dir, "nodes_*.py")))
```

**Impact on ComfyMulti:**
- **None** - Purely internal refactor
- Reduces future merge conflicts when ComfyUI adds new API nodes
- Our custom nodes are in separate directory (`custom_nodes/`)

---

## New Features

### 1. Advanced Widgets Support

**What:** Frontend support for collapsible "Advanced Inputs" section in node properties panel.

**Why:** Reduces UI clutter for power-user options (encoding params, quality settings, etc.)

**Frontend PR:** ComfyUI_frontend PR #7812 (frontend support required)

**Impact on ComfyMulti:**
- **None immediately** - Our frontend containers run default ComfyUI web UI
- **Future benefit** - Users can install custom nodes that use advanced widgets
- **No action required**

### 2. LTXV Audio Handling Improvements

**What:** Automatic mono-to-stereo audio conversion for LTXV VAE encoding.

**Change:** `comfy/ldm/lightricks/vae/audio_vae.py`
```python
# Before (v0.9.2):
if waveform.shape[1] != expected_channels:
    raise ValueError(f"Input audio must have {expected_channels} channels")

# After (v0.10.0):
if waveform.shape[1] != expected_channels:
    if waveform.shape[1] == 1:
        waveform = waveform.expand(-1, expected_channels, *waveform.shape[2:])
    else:
        raise ValueError(...)
```

**Impact on ComfyMulti:**
- **Positive** - Users can now use mono audio files with LTXV video workflows
- **No changes required** - Automatic conversion handled internally
- **Benefit for workshop** - More flexible audio input options

### 3. AMD GPU Audio Fix

**What:** Fixed `TypeError` when converting audio tensors on AMD GPUs.

**Change:** `comfy_api/latest/_input_impl/video_types.py`
```python
# Before (v0.9.2):
frame = av.AudioFrame.from_ndarray(
    waveform.movedim(2, 1).reshape(1, -1).float().numpy(), ...
)

# After (v0.10.0):
frame = av.AudioFrame.from_ndarray(
    waveform.movedim(2, 1).reshape(1, -1).float().cpu().numpy(), ...
)
```

**Impact on ComfyMulti:**
- **None** - We use NVIDIA H100 GPUs on Verda
- **Benefit** - Improves cross-platform stability if we ever test on AMD

### 4. New API Nodes

**Added:**
- `nodes_bria.py` - Bria Edit API integration (198 lines)
- Extended `nodes_bytedance.py` - Seedance-1-5-pro model support (+106 lines)

**Impact on ComfyMulti:**
- **None** - These are optional API nodes for external services
- **No cost/config needed** - Only activate if users have API keys

### 5. Error Handling Improvements

**What:** Try-except wrapper around `seed_assets()` call in server.py.

**Change:**
```python
# Before (v0.9.2):
seed_assets(["models"])

# After (v0.10.0):
try:
    seed_assets(["models"])
except Exception as e:
    logging.error(f"Failed to seed assets: {e}")
```

**Impact on ComfyMulti:**
- **Positive** - Server won't crash if model seeding fails
- **Better error reporting** - Logs errors instead of silent failure
- **No changes required**

---

## Deprecations

**NONE**

No features marked as deprecated in this release.

---

## Dependency Changes

### Python Dependencies (requirements.txt)

| Package | v0.9.2 | v0.10.0 | Impact |
|---------|--------|---------|--------|
| `comfyui-workflow-templates` | 0.8.4 | 0.8.14 | Updated workflow templates |
| `comfy-kitchen` | >=0.2.6 | >=0.2.7 | Minor version bump |

**Impact on ComfyMulti:**
- **LOW** - Dependency bumps are backward compatible
- **Action:** Update `requirements.txt` in Dockerfile
- **Testing:** Verify workflow templates still load correctly

### No Changes To:
- PyTorch version
- CUDA toolkit version
- System dependencies
- Docker base image requirements

---

## Migration Notes

### For ComfyMulti Deployment

**RECOMMENDED STEPS:**

1. **Update Dockerfile** (comfyui-frontend/Dockerfile, comfyui-worker/Dockerfile):
   ```dockerfile
   # Update git checkout tag
   RUN git checkout v0.10.0
   ```

2. **Test workflow templates**:
   - Verify 5 template workflows still load: `flux2_klein_9b`, `flux2_klein_4b`, `ltx2_text_to_video`, etc.
   - Test LTX-2 video generation with mono audio files

3. **Rebuild images**:
   ```bash
   docker compose build comfy-frontend
   docker compose build comfy-worker
   ```

4. **No configuration changes needed**:
   - `.env` settings unchanged
   - `docker-compose.yml` unchanged
   - Nginx routes unchanged
   - Redis queue unchanged

### For Custom Nodes

**If we create custom nodes in the future:**
- Can optionally use `advanced=True` parameter for power-user settings
- Autogrow validation improvements automatically apply

### For Users

**No user-facing changes:**
- All workflows compatible
- UI remains the same (unless frontend PR #7812 is merged separately)
- No re-training or workflow migration needed

---

## Impact on ComfyMulti Architecture

### Frontend Containers (20x user001-user020)

**Changes Required:** NONE

**Why:**
- No API endpoint changes
- No userdata API changes
- No custom node API changes
- Workflow storage location unchanged (`/comfyui/user/default/workflows/`)

**Compatibility:**
- All template workflows compatible
- Custom nodes installed by users will benefit from autogrow fixes
- Advanced widget support available for future custom nodes

### Worker Containers (1-3x GPU workers)

**Changes Required:** NONE

**Why:**
- No model loading changes
- No queue processing changes
- LTXV audio improvements are additive (mono now works)
- Error handling improvements reduce crash risk

**Benefits:**
- Better error logging via `seed_assets()` try-except
- AMD GPU compatibility (if we ever switch providers)

### Queue Manager (FastAPI service)

**Changes Required:** NONE

**Why:**
- No ComfyUI API endpoint changes
- WebSocket protocol unchanged
- Job queue format unchanged

### Nginx Reverse Proxy

**Changes Required:** NONE

**Why:**
- No routing changes
- No new endpoints added to core ComfyUI

### Data Volumes

**No changes to:**
- `/comfyui/user/default/workflows/` - Workflow storage
- `/comfyui/models/` - Model storage
- `/comfyui/output/` - Output directory
- `/comfyui/input/` - Input directory
- `/comfyui/custom_nodes/` - Custom nodes directory

---

## Testing Checklist

Before deploying v0.10.0 to production:

- [ ] Build frontend image with v0.10.0
- [ ] Build worker image with v0.10.0
- [ ] Test all 5 template workflows:
  - [ ] `flux2_klein_9b_text_to_image.json`
  - [ ] `flux2_klein_4b_text_to_image.json`
  - [ ] `ltx2_text_to_video.json`
  - [ ] `ltx2_text_to_video_distilled.json`
- [ ] Test LTX-2 with mono audio file (new feature)
- [ ] Test LTX-2 with stereo audio file (regression test)
- [ ] Verify custom nodes installed by users still load
- [ ] Check server logs for `seed_assets` errors
- [ ] Test queue manager job submission
- [ ] Verify user workflows persist after restart
- [ ] Check ComfyUI Manager compatibility

---

## Rollback Plan

**If v0.10.0 causes issues:**

1. **Revert Dockerfile**:
   ```dockerfile
   RUN git checkout v0.9.2
   ```

2. **Rebuild images**:
   ```bash
   docker compose build comfy-frontend comfy-worker
   docker compose up -d
   ```

3. **No data loss risk**:
   - User workflows unchanged
   - Model files unchanged
   - Settings databases unchanged

**Estimated rollback time:** 5 minutes

---

## Recommendation

**APPROVE FOR DEPLOYMENT**

**Rationale:**
1. **No breaking changes** - Drop-in replacement
2. **Low risk** - Only 22 commits, mostly internal refactors
3. **Positive improvements** - Better error handling, audio flexibility
4. **No config changes** - Same deployment process
5. **Easy rollback** - Single git tag change if needed

**Deployment Strategy:**
- **Phase 1:** Test on local dev instance (mello)
- **Phase 2:** Deploy to Verda GPU worker
- **Phase 3:** Monitor for 24 hours before workshop

**Estimated Migration Time:** 15 minutes (build + test)

---

## Related Issues

- **GitHub Issue #27** - ComfyUI version upgrade research
- **GitHub Issue #28** - Test v0.10.0 compatibility with Flux2 Klein
- **GitHub Issue #29** - Validate LTX-2 audio workflows

---

## Sources

- [ComfyUI GitHub Releases](https://github.com/comfyanonymous/ComfyUI/releases)
- [ComfyUI v0.10.0 Release](https://github.com/comfyanonymous/ComfyUI/releases/tag/v0.10.0)
- [Git commit diff v0.9.2...v0.10.0](https://github.com/comfyanonymous/ComfyUI/compare/v0.9.2...v0.10.0)
- [Apatero Blog: ComfyUI Updates 2025](https://apatero.com/blog/custom-nodes-breaking-comfyui-updates-fix-guide-2025)

---

**Analysis Completed:** 2026-01-31
**Analyzed By:** Claude Code (Sonnet 4.5)
**Next Steps:** Proceed to v0.10.0 → v0.10.1 analysis (Task #2)
