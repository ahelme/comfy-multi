**Project:** ComfyUI Multi-User Workshop Platform  
**Project Started:** 2026-01-02  
**Repository:** github.com/ahelme/comfy-multi  
**Domain:** comfy.ahelme.net  
**Doc Created:** 2026-01-04  
**Doc Updated:** 2026-01-04  

---

# Phase 7 Remaining Work

## Completed ✅
- Added .gitignore (tests/, .env excluded)
- Fixed split architecture across all docs (Hetzner VPS + Remote GPU)
- Corrected SSL cert documentation (Namecheap domain)
- Changed "Verda" → "Remote GPU (e.g. Verda)" everywhere
- Added comprehensive workshop model lists to .env.example
- Added inline comments for queue/GPU settings
- Removed tests/, .env, TEST_REPORT.md from git tracking
- **Split admin-guide.md into 6 files:**
  - admin-guide.md (main overview - 346 lines)
  - admin-setup-guide.md (deployment, configuration - 291 lines)
  - admin-dashboard.md (dashboard usage - 302 lines)
  - admin-security.md (security practices - 632 lines)
  - admin-troubleshooting.md (troubleshooting - 659 lines)
  - admin-workshop-checklist.md (workshop procedures - 453 lines)

## Remaining Tasks

### 1. Add Standard Headers to All .md Files
Add to TOP of every .md file:
```markdown
**Project:** ComfyUI Multi-User Workshop Platform  
**Project Started:** 2026-01-02  
**Repository:** github.com/ahelme/comfy-multi  
**Domain:** comfy.ahelme.net  
**Doc Created:** [actual date file was created]  
**Doc Updated:** 2026-01-04  

---
```

Files needing headers:
- README.md
- prd.md
- implementation.md
- CLAUDE.md
- DEPLOYMENT.md
- docs/user-guide.md
- docs/admin-guide.md (done ✅)
- docs/admin-setup-guide.md (done ✅)
- docs/admin-dashboard.md (done ✅)
- docs/admin-security.md (done ✅)
- docs/admin-troubleshooting.md (done ✅)
- docs/admin-workshop-checklist.md (done ✅)
- docs/troubleshooting.md
- docs/workshop-runbook.md

### 2. Further Split Troubleshooting (Optional - Problem-Specific)

Create separate files for each common issue:
- admin-troubleshooting-queue-stopped.md
- admin-troubleshooting-out-of-memory.md  
- admin-troubleshooting-worker-not-connecting.md
- admin-troubleshooting-ssl-cert-issues.md
- admin-troubleshooting-redis-connection.md
- admin-troubleshooting-docker-issues.md

### 3. Further Split Workshop Checklists (Optional - Phase-Specific)

If admin-workshop-checklist.md is too long, split into:
- admin-checklist-pre-workshop.md (T-1 week through T-0)
- admin-checklist-during-workshop.md (hour-by-hour procedures)
- admin-checklist-post-workshop.md (cleanup, reporting)

### 4. Update Cross-References

After splitting, update all docs to link to the new granular files.

## Notes
- All new files need standard headers with correct dates
- Maintain NO FLUFF policy - comprehensive but concise
- Ensure split architecture is correct in all new files
- Use "Remote GPU (e.g. Verda)" not just "Verda"
