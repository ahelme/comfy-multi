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
- docs/admin-guide.md
- docs/troubleshooting.md
- docs/workshop-runbook.md

### 2. Split admin-guide.md

**Keep as main overview:**
- admin-guide.md (basics, monitoring, health checks, links to all other docs)

**Create new files:**
- admin-setup-guide.md (configuration checklist, deployment for both tiers)
- admin-dashboard.md (dashboard features and usage)
- admin-security.md (security best practices)

### 3. Split Troubleshooting (Problem-Specific)

Create separate files for each common issue:
- admin-troubleshooting-queue-stopped.md
- admin-troubleshooting-out-of-memory.md  
- admin-troubleshooting-worker-not-connecting.md
- admin-troubleshooting-ssl-cert-issues.md
- admin-troubleshooting-redis-connection.md
- admin-troubleshooting-docker-issues.md

### 4. Split Workshop Checklists (Phase-Specific)

- admin-checklist-pre-workshop.md (T-1 week through T-0)
- admin-checklist-during-workshop.md (hour-by-hour procedures)
- admin-checklist-post-workshop.md (cleanup, reporting)

### 5. Update Cross-References

After splitting, update all docs to link to the new granular files.

## Notes
- All new files need standard headers with correct dates
- Maintain NO FLUFF policy - comprehensive but concise
- Ensure split architecture is correct in all new files
- Use "Remote GPU (e.g. Verda)" not just "Verda"
