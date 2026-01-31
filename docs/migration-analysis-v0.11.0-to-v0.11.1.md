**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-31
**Doc Updated:** 2026-01-31

---

# ComfyUI Migration: v0.11.0 → v0.11.1

## Summary

**Version:** v0.11.1 (Released January 29, 2026)
**Type:** Minor patch release
**Commits:** 7 commits over 2 days
**Contributors:** 5 developers (guill, bigcat88, comfyanonymous, ltdrdata, comfyui-wiki)

v0.11.1 is a small incremental patch released 2 days after v0.11.0. This release focuses on developer tooling improvements, API expansion, and minor bug fixes. No breaking changes were introduced.

## Bug Fixes

### Spatial Downscale Ratios Restored
- **Issue:** Missing spatial downscale ratio options in v0.11.0
- **Fix:** Added missing spatial downscale ratio configurations
- **Impact:** Restores functionality for workflows using specific downscaling ratios
- **Severity:** Low (feature restoration, not a critical bug)

### Manager Stability Update
- **Change:** Manager version bumped to 4.1b1
- **Purpose:** Likely includes bug fixes and stability improvements in the manager component
- **Details:** Specific fixes not documented in release notes
- **Impact:** Improved stability for ComfyUI Manager operations

## New Features

### Dev-Only Nodes Support
- **Purpose:** Hide development/testing nodes from production UI
- **Implementation:** Nodes can be marked as dev-only and won't appear unless developer mode is enabled
- **Benefit:** Cleaner UI for end users, separates testing tools from production workflows
- **Impact on ComfyMulti:** No impact - workshop users won't see test nodes cluttering their interface

### API Expansion: Grok Imagine Nodes
- **Addition:** New API nodes for Grok Imagine integration
- **Type:** External service integration
- **Requirements:** Likely requires API credentials for Grok service
- **Impact on ComfyMulti:** Optional - not required for LTX-2 or Flux.2 Klein workflows

### Python 3.14 Compatibility
- **Status:** Documentation updated to note Python 3.14 compatibility
- **Reality Check:** Python 3.14 not yet released (current stable is 3.13)
- **Interpretation:** Forward-looking documentation for future Python releases
- **Impact on ComfyMulti:** None - we're using Python 3.11+ in Docker images

### Workflow Templates Update
- **Version:** Updated from v0.8.24 (v0.11.0) to v0.8.27 (v0.11.1)
- **Changes:** 3 minor template revisions
- **Impact:** Improved default workflow examples and templates
- **Relevance:** Low - ComfyMulti uses custom workshop templates

## Production Readiness

### Stability Assessment

**Rating:** ⭐⭐⭐⭐☆ (4/5 - Stable for Production)

**Strengths:**
- No breaking changes
- Small, focused patch (only 7 commits)
- Bug fixes restore missing functionality
- Active development with quick releases (2 days after v0.11.0)

**Weaknesses:**
- Very recent release (January 29, 2026 - only 2 days old as of analysis)
- Limited community feedback due to recency
- Desktop v0.8.0 (which includes v0.11.1) just released today (January 31, 2026)
- No stability guarantees in release notes

**Community Feedback:**
- **Positive reception:** 10 thumbs-up on v0.11.1 release
- **Desktop version concerns:** Some users reported issues with desktop v0.8.0 (Windows 11 crashes after update)
- **Performance mixed:** No specific v0.11.1 performance issues reported yet
- **Custom nodes:** Most ComfyUI issues are custom node conflicts, not core stability

### Known Issues

#### Desktop Version Instability (Windows)
- **Platform:** ComfyUI Desktop v0.8.0 (includes core v0.11.1)
- **Issue:** Some Windows 11 users report crashes after update
- **Workaround:** Clean reinstall required in some cases
- **Impact on ComfyMulti:** None - we use Docker deployment, not desktop app

#### Performance Concerns (Unconfirmed for v0.11.1)
- **Context:** Some users reported v0.10.0 performance degradation with Flux2.dev
- **Status for v0.11.1:** No specific reports yet (too recent)
- **Recommendation:** Monitor performance during testing phase

#### UI Change Controversies
- **Community feedback:** Some users unhappy with recent UI changes (zoom behavior, button placement)
- **Impact on ComfyMulti:** Minimal - users interact with ComfyUI's standard web interface
- **Note:** UI changes are in frontend, not core backend

### No Critical Issues Found

After extensive research of GitHub issues, discussions, and release notes:
- **No blocking bugs** identified in v0.11.1
- **No security vulnerabilities** reported
- **No data loss issues** documented
- **No breaking API changes** in release notes

## Model Compatibility

### LTX-2 Support

**Status:** ✅ **Fully Compatible**

- **LTX-2 19B:** Native support confirmed in v0.11.0+
- **LTX-2 Tiny VAE:** Added in v0.11.0, stable in v0.11.1
- **Required Nodes:** Available in core ComfyUI v0.11.1
  - `LTXAVTextEncoderLoader`
  - `LTXVAudioVAEDecode`
  - `LTXVAudioVAELoader`
  - `LTXVEmptyLatentAudio`
- **Performance:** VRAM optimizations from v0.11.0 carry forward
- **ComfyMulti Impact:** No changes needed for existing LTX-2 workflows

**Documentation:** [Using ComfyUI with LTX-2](https://docs.ltx.video/open-source-model/integration-tools/comfy-ui)

### Flux.2 Klein Support

**Status:** ✅ **Fully Compatible**

- **Flux.2 Klein 4B:** Supported (base and distilled variants)
- **Flux.2 Klein 9B:** Supported
- **Checkpoint Loading:** Improved in v0.11.0 (SaveCheckpoint support)
- **LoRA Support:** Multiple formats supported (ModelScope-Trainer, DiffSynth)
- **GGUF Support:** Requires ComfyUI-GGUF and ComfyUI-KJNodes custom nodes
- **ComfyMulti Impact:** No changes needed for existing Flux.2 Klein workflows

**Documentation:** [ComfyUI Flux.2 Klein Guide](https://docs.comfy.org/tutorials/flux/flux-2-klein)

### Model Loading Notes

- **Checkpoint formats:** .safetensors fully supported
- **Text encoders:** Gemma 3 12B support stable
- **VAE support:** Both LTX-2 and Flux VAEs working
- **LoRA loading:** Multiple format compatibility maintained

## Last-Minute Changes

### Commits Between v0.11.0 and v0.11.1

1. **Dev-only nodes** - Feature addition, low risk
2. **Python 3.14 docs** - Documentation only, zero risk
3. **Grok Imagine API** - Optional API nodes, no impact if unused
4. **Manager v4.1b1** - Stability update, low risk
5. **Workflow templates** - Template updates, cosmetic only
6. **Spatial downscale** - Bug fix, restores missing feature
7. **Version bump** - Release tag

**Risk Assessment:** All changes are low-risk, non-breaking additions or fixes.

### No Surprise Breaking Changes

- No unexpected API changes
- No model compatibility regressions
- No workflow format changes
- No dependency updates that could cause conflicts

## Recommendation

### Should We Use v0.11.1 for Workshop?

**YES** ✅ - With Caveats

### Reasoning

**Arguments FOR v0.11.1:**
1. **Bug fixes:** Restores missing spatial downscale ratios
2. **Model support:** Full LTX-2 and Flux.2 Klein compatibility
3. **Stability:** No breaking changes from v0.11.0
4. **Active development:** Quick bug fix release shows responsive maintainers
5. **Clean upgrade:** Small, focused patch without risky refactors

**Arguments AGAINST v0.11.1:**
1. **Recency:** Only 2 days old (limited community testing)
2. **Desktop issues:** Some Windows crashes (though Docker deployment unaffected)
3. **Limited feedback:** Not enough time for community bug reports
4. **Untested performance:** No workshop-scale testing yet

### Recommended Approach

**Staged Migration Strategy:**

1. **Testing Phase (1-2 weeks):**
   - Deploy v0.11.1 to Verda GPU instance
   - Test all 5 template workflows (LTX-2, Flux.2 Klein)
   - Monitor memory usage, queue performance, stability
   - Check for custom node conflicts
   - Validate user isolation still works

2. **Rollback Plan:**
   - Keep v0.9.2 Docker images available
   - Document known-good custom node versions
   - Maintain v0.9.2 worker image in R2 cache

3. **Production Deployment:**
   - If no issues in testing: use v0.11.1 for workshop
   - If critical bugs found: fall back to v0.9.2
   - Monitor first workshop session closely

### Alternative: Wait for v0.11.2

**If workshop is >2 weeks away:**
- Wait for community feedback on v0.11.1
- Check for v0.11.2 release (likely bug fix if issues found)
- Benefit from additional testing by broader community

**If workshop is <2 weeks away:**
- Use v0.11.1 with intensive pre-workshop testing
- Have v0.9.2 rollback ready
- Document all changes for troubleshooting

## Impact on ComfyMulti

### Docker Images

**Frontend Containers:**
- Update `comfyui-frontend/Dockerfile` to use v0.11.1
- Rebuild `comfy-multi-frontend:latest` image
- Test all 20 user containers with new image
- Verify custom nodes compatibility:
  - `default_workflow_loader`
  - `queue_redirect`
  - ComfyUI-Manager

**Worker Containers:**
- Update `comfyui-worker/Dockerfile` to use v0.11.1
- Rebuild worker image
- Upload to R2 cache bucket
- Test GPU worker startup and model loading

### Custom Nodes Compatibility

**Critical Nodes to Test:**

1. **queue_redirect** - Job submission to Redis queue
   - Test with v0.11.1 API changes
   - Verify WebSocket communication still works

2. **default_workflow_loader** - Auto-load Flux2 Klein on startup
   - Verify workflow path still `/comfyui/user/default/workflows/`
   - Check userdata API compatibility

3. **ComfyUI-Manager** - Custom node installation
   - Verify v4.1b1 manager compatibility
   - Test node installation in isolated user containers

### Configuration Changes

**No configuration changes required:**
- Environment variables unchanged
- Volume mounts remain the same
- Nginx routing no impact
- Redis queue API stable

### Workflow Storage

**v0.9.2 userdata API format maintained:**
- Workflows still served via `/api/userdata?dir=workflows`
- Load menu discovery unchanged
- No migration needed for existing workflows

### Testing Checklist

Before deploying v0.11.1 to production:

- [ ] Build frontend image with v0.11.1
- [ ] Build worker image with v0.11.1
- [ ] Test LTX-2 19B workflow (text-to-video)
- [ ] Test LTX-2 19B distilled workflow
- [ ] Test Flux.2 Klein 4B (text-to-image)
- [ ] Test Flux.2 Klein 9B (text-to-image)
- [ ] Test job queue submission via queue_redirect
- [ ] Test multi-user isolation (2+ concurrent jobs)
- [ ] Monitor VRAM usage on GPU worker
- [ ] Verify output files saved correctly
- [ ] Check custom nodes load without errors
- [ ] Validate workflow templates appear in Load menu
- [ ] Test ComfyUI-Manager functionality
- [ ] Verify health checks pass for all containers

### Rollback Procedure

If v0.11.1 causes issues:

```bash
# On mello VPS (frontend)
cd /home/dev/projects/comfyui/comfyui-frontend
git checkout <v0.9.2-commit-hash>
docker build -t comfy-multi-frontend:latest .
docker compose up -d

# On Verda GPU instance (worker)
cd /root/comfyui-worker
git checkout <v0.9.2-commit-hash>
docker build -t comfy-worker:latest .
docker compose up -d worker
```

### Performance Monitoring

**Key metrics to track after v0.11.1 deployment:**

1. **Queue throughput** - Jobs/hour compared to v0.9.2 baseline
2. **VRAM usage** - Peak memory during LTX-2 generation
3. **Generation time** - Compare against v0.9.2 benchmarks
4. **Container stability** - Uptime, crash frequency
5. **User feedback** - Workshop participant reports

## Additional Considerations

### Community Sentiment

**Recent UI Changes Controversy:**
- Some users unhappy with UI changes in recent releases
- Complaints about removed features (zoom behavior, button placement)
- **Impact on ComfyMulti:** Minimal - we use standard web interface
- **Mitigation:** If users complain, can document UI differences

### Long-Term Support

**ComfyUI Release Cadence:**
- Weekly releases typical (v0.11.0 on Jan 27, v0.11.1 on Jan 29)
- Active development continues
- Bug fixes released quickly

**Implication for ComfyMulti:**
- Expect frequent updates available
- Can stay on v0.11.1 long-term if stable
- Or upgrade to v0.11.2+ if improvements released

### Workshop Timeline

**If workshop is in February 2026:**
- v0.11.1 will have 2-4 weeks of community testing by then
- Sufficient time to identify critical issues
- Recommend using v0.11.1

**If workshop is in January 2026 (next week):**
- Stick with v0.9.2 (known stable)
- Upgrade after workshop when time permits
- Avoid last-minute version changes

## Conclusion

**v0.11.1 is production-ready with appropriate testing.**

The version introduces no breaking changes, fixes bugs from v0.11.0, and maintains full compatibility with LTX-2 and Flux.2 Klein models. The main risk is its recency (2 days old), which limits community feedback.

**Recommended Migration Path:**
```
v0.9.2 → v0.11.0 → v0.11.1 (current)
```

**Action Items:**

1. **Test v0.11.1 on Verda instance** (1-2 weeks before workshop)
2. **Validate all template workflows** (LTX-2, Flux.2 Klein)
3. **Monitor performance and stability**
4. **Keep v0.9.2 rollback available**
5. **Deploy to production** only after successful testing

**Final Verdict:** Use v0.11.1 for workshop, but only after thorough testing. If workshop is imminent (<1 week), stick with v0.9.2 and upgrade post-workshop.

## Sources

- [ComfyUI v0.11.1 Release](https://github.com/Comfy-Org/ComfyUI/releases/tag/v0.11.1) - Official release notes
- [ComfyUI v0.11.0 Release](https://github.com/Comfy-Org/ComfyUI/releases/tag/v0.11.0) - Previous version
- [ComfyUI Desktop v0.8.0 Release](https://github.com/Comfy-Org/desktop/releases) - Desktop version with v0.11.1
- [Official Changelog](https://docs.comfy.org/changelog) - ComfyUI documentation
- [ComfyUI Releases](https://github.com/Comfy-Org/ComfyUI/releases) - All releases
- [LTX-2 ComfyUI Documentation](https://docs.ltx.video/open-source-model/integration-tools/comfy-ui) - Model compatibility
- [Flux.2 Klein Guide](https://docs.comfy.org/tutorials/flux/flux-2-klein) - Model support
- [GitHub Issues](https://github.com/Comfy-Org/ComfyUI/issues) - Bug reports and discussions
- [Community Feedback Thread](https://github.com/Comfy-Org/ComfyUI/issues/11160) - UI changes discussion
- [Performance Discussion](https://github.com/Comfy-Org/ComfyUI/discussions/4457) - Performance issues
- [Desktop Stability Issue](https://github.com/LykosAI/StabilityMatrix/issues/1510) - Windows crash reports

---

**Analysis Complete:** 2026-01-31
**Analyst:** Claude Sonnet 4.5
**Status:** Production-ready with testing recommended
**Recommendation:** Deploy after 1-2 weeks testing, keep v0.9.2 rollback ready
