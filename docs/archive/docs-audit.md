**Project:** ComfyUI Multi-User Workshop Platform
**Doc Created:** 2026-01-16
**Doc Updated:** 2026-01-16 (All HIGH/MEDIUM fixed)

---

# Documentation Audit Report

Review of all documentation for duplicated and outdated information.

---

## Summary

| Category | Count | Severity | Status |
|----------|-------|----------|--------|
| RESTORE.sh script naming errors | 15+ refs | HIGH | ✅ FIXED |
| ComfyUI version outdated (v0.8.2) | 4 docs | HIGH | ✅ FIXED |
| Model references (SDXL instead of LTX-2) | 2 docs | HIGH | ✅ FIXED |
| Backup/restore duplication | 5 docs | MEDIUM | ✅ REDUCED |
| Storage strategy duplication | 5 docs | MEDIUM | ✅ REDUCED |
| Tailscale docs duplication | 5 docs | MEDIUM | Acceptable |
| quick-start.sh duplication | 5 docs | LOW | Acceptable |
| SSL provider description wrong | 1 doc | LOW | ✅ FIXED |
| implementation.md link broken | 1 doc | LOW | ✅ FIXED |

---

## HIGH PRIORITY - Outdated Information

### 1. RESTORE.sh Script Naming (15+ references)

**Problem:** Docs reference `RESTORE.sh` but actual script is `RESTORE-SFS.sh`

**Wrong flags documented:**
- `--build-container` (doesn't exist, should be `--with-container`)
- `--load-container` (doesn't exist, should be `--with-container`)

**Found in:**
| Doc | Line | Issue |
|-----|------|-------|
| admin-backup-restore.md | 74-75 | "RESTORE-SFS.sh" and "RESTORE-BLOCK-MELLO.sh" |
| admin-workflow-workshop.md | 73 | `RESTORE.sh --with-models --build-container` |
| admin-workflow-workshop.md | 163 | `RESTORE.sh --with-models --load-container` |
| admin-setup-guide.md | 75 | Generic RESTORE.sh reference |
| admin-scripts.md | 35 | Decision table |
| implementation-backup-restore.md | 119-130 | Multiple references |
| CLAUDE.md | Multiple | Generic RESTORE.sh |

**Fix:** Replace all `RESTORE.sh` with `RESTORE-SFS.sh`, fix flag names

---

### 2. ComfyUI Version Outdated (4 docs)

**Problem:** Docs say v0.8.2 but deployed version is v0.9.2

| Doc | Line | Current | Should Be |
|-----|------|---------|-----------|
| CLAUDE.md | 225-226 | "ComfyUI v0.8.2" | v0.9.2 |
| README.md | 12 | "ComfyUI v0.8.2" | v0.9.2 |
| admin-guide.md | 13, 17 | "v0.8.2" | v0.9.2 |
| prd.md | 134 | Generic | v0.9.2 |

**Evidence:** progress-2.md confirms `comfyui-worker:v0.9.2` and `comfyui-frontend:v0.9.2`

---

### 3. Old Model References (SDXL instead of LTX-2)

**Problem:** Workshop uses LTX-2 but some docs still reference SDXL/other models

| Doc | Lines | Issue |
|-----|-------|-------|
| workshop-runbook.md | 45-80 | Lists SDXL as required model, LTX-Video as optional |
| workshop-runbook.md | 72-75 | Workflow `01_intro_text_to_image.json` uses SDXL |
| prd.md | 64 | Lists "Wan, HunyuanVideo, LTX-Video, AnimateDiff, CogVideoX" |
| prd.md | 137-143 | "Video Models (To Be Confirmed)" - stale since Jan 02 |
| admin-setup-guide.md | 180 | "LTX-Video, HunyuanVideo, or AnimateDiff" vague guidance |

**Current state:** Only LTX-2 is backed up to R2 and deployed (~47GB total)

---

### 4. SSL Certificate Provider Wrong

**Problem:** CLAUDE.md has contradictory SSL info

| Line | Says | Should Say |
|------|------|------------|
| 280 | "Type: Existing cert (not Let's Encrypt)" | Correct |
| 339 | "Provider: Let's Encrypt" | "Existing certificate (ahelme.net)" |

---

### 5. Model Size Wrong

**Problem:** admin-guide.md line 16 says "LTX-2 Models (19B params, 21GB)"

**Actual:** R2 bucket shows ~47GB total:
- checkpoints/ltx-2-19b-dev-fp8.safetensors (~27GB)
- text_encoders/gemma_3_12B_it.safetensors (~20GB)

---

### 6. implementation.md Link Broken

**Problem:** CLAUDE.md line 54 lists "implementation.md" but file doesn't exist

**Fix:** Update to `implementation-deployment.md` or `implementation-deployment-verda.md`

---

## MEDIUM PRIORITY - Duplicated Information

### 1. Backup & Restore Procedures (5 docs)

Same restore steps appear in multiple places:

| Doc | Content |
|-----|---------|
| admin-backup-restore.md | **PRIMARY** - Full backup/restore reference |
| implementation-backup-restore.md | Planning doc - has redirect notice now |
| admin-workflow-workshop.md | Lines 55-74 duplicate mount/restore steps |
| admin-setup-guide.md | Lines 50-75 duplicate restore steps |
| CLAUDE.md | Lines 440-580 Pre-Workshop SFS section |

**Recommendation:** Keep admin-backup-restore.md as single source, others link to it

---

### 2. Storage Strategy Comparison (5 docs)

SFS vs Block vs R2 explained in multiple places:

| Doc | Lines |
|-----|-------|
| admin-backup-restore.md | 17-24 |
| admin-workflow-workshop.md | 17-23 |
| admin-verda-setup.md | 17-32 |
| README.md | 168-175 |
| CLAUDE.md | 363-392 |

**Recommendation:** Keep in admin-backup-restore.md and README.md, link from others

---

### 3. Tailscale VPN Configuration (5 docs)

Authentication steps duplicated:

| Doc | Lines | Content |
|-----|-------|---------|
| CLAUDE.md | 330-336 | VPN section with IPs |
| README.md | 116-121, 141-145 | VPS and GPU setup |
| admin-setup-guide.md | 69-72 | Network test section |
| admin-workflow-workshop.md | 76-92 | Step 5: Authenticate |
| implementation-deployment-verda.md | 47-51 | Architecture overview |

**Recommendation:** Keep detailed steps in admin-backup-restore.md, others reference it

---

### 4. quick-start.sh Documentation (5 docs)

Same script documented multiple times:

| Doc | Purpose |
|-----|---------|
| admin-scripts.md | **PRIMARY** - Script reference |
| admin-backup-restore.md | Lines 90-104 |
| admin-workflow-workshop.md | Lines 55-74 |
| README.md | Lines 99-101 |
| implementation-deployment-verda.md | Lines 84-92 |

**Recommendation:** Keep in admin-scripts.md, link from others

---

### 5. R2 Endpoint/Bucket Details (4 docs)

Same R2 details repeated:

| Doc | Content |
|-----|---------|
| admin-backup-restore.md | Lines 28-35, 202-209 |
| implementation-backup-restore.md | Lines 45-54 |
| admin-scripts.md | backup-verda.sh section |
| CLAUDE.md | Lines 340-345 |

**Recommendation:** Keep in admin-backup-restore.md, reference from others

---

## LOW PRIORITY - Minor Issues

### 0. User Naming Inconsistency ✅ FIXED

**Problem:** htpasswd used user01 format, docs used mix of user01 and user001

**Fix applied:**
- Updated htpasswd to use user001-user020 format
- Updated user-guide.md, CLAUDE.md, prd.md
- All systems now use consistent 3-digit format

### 1. Archive References

Some docs still reference files in `docs/archive/`:
- CLAUDE-RESUME.md references archived progress
- Some admin guides reference old block storage docs

**Fix:** Search for `archive/` links and update or remove

### 2. Non-existent Workflows

admin-cpu-testing-guide.md line 308 references `template-basic-video.json` which doesn't exist

**Fix:** Update to reference actual LTX-2 workflow

### 3. Verda Instance Details

progress-2.md shows old Verda IP (65.108.33.124) became unreachable. Current docs show Tailscale IP 100.89.38.43 which is correct (preserved via identity backup).

**Status:** Okay - Tailscale IP is stable

---

## Recommended Fixes by File

### CLAUDE.md
- [ ] Line 225-226: Change v0.8.2 to v0.9.2
- [ ] Line 339: Change "Let's Encrypt" to "Existing certificate"
- [ ] Line 54: Fix implementation.md link

### README.md
- [ ] Line 12: Change v0.8.2 to v0.9.2

### admin-guide.md
- [ ] Lines 13, 17: Change v0.8.2 to v0.9.2
- [ ] Line 16: Change "21GB" to "~47GB"

### admin-workflow-workshop.md
- [ ] Line 73: Change `RESTORE.sh --build-container` to `RESTORE-SFS.sh --with-container`
- [ ] Line 163: Change `RESTORE.sh --load-container` to `RESTORE-SFS.sh --with-container`

### workshop-runbook.md
- [ ] Lines 45-80: Replace SDXL references with LTX-2
- [ ] Update workflow examples for LTX-2

### prd.md
- [ ] Line 64: Update supported models list to focus on LTX-2
- [ ] Lines 137-143: Remove "To Be Confirmed" - LTX-2 is confirmed

### admin-setup-guide.md
- [ ] Line 180: Remove vague "LTX-Video, HunyuanVideo, or AnimateDiff" guidance

---

## Action Items

**Immediate (High Priority):**
1. Fix all RESTORE.sh references to RESTORE-SFS.sh
2. Update v0.8.2 to v0.9.2 in 4 docs
3. Update model references from SDXL to LTX-2

**Soon (Medium Priority):**
4. Remove duplicate backup/restore steps (replace with links)
5. Consolidate storage strategy explanations
6. Clean up Tailscale docs duplication

**Later (Low Priority):**
7. Fix archive references
8. Update workflow examples

---

**Last Updated:** 2026-01-16
