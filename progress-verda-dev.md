**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Name:** progress-02.md 
**Purpose:** progress file for dev on Verda server
**Doc Created:** 2026-01-31
**Doc Updated:** 2026-01-31 (Session Verda 01)

---

# Project Progress Tracker (Based on progress-02.md - Verda team's progress)
**Target:** Workshop in ~1 week !!! (early February 2026)

---

## Progress Tracker Structure

0. Update Instructions

1. Task Management
   - TASKS SCRATCHPAD - QUICK ADD NEW TASKS HERE
   - CURRENT TASKS DASHBOARD - REFACTOR SESSION TASKS - END OF SESSION
        - IMPORTANT: use gh issue # as reference
        - FORMAT: [🔴] [PRIORITY] [GH#s] [SHORT DESC.]
            - [DATE-CREATED] [DATE-UPDATED]
            - Key GH Issues:
                - [GH ISSUE TITLE #1]
                - [GH ISSUE TITLE #2]
            - CONCISE NOTES
            - CONCISE NOTES INC. RELATED [GH#] (IF ANY)

2. Next Session Goals
    - SESSION GOALS - SET NEXT SESSION GOALS - END OF SESSION
        - FORMAT: [GH#] [SHORT DESC.]
            - CONCISE NOTES
            - CONCISE NOTES INC. RELATED [GH#] (IF ANY)


3. Progress Reports
   - post in reverse chronological order (LATEST AT TOP)
   - CRITICAL DETAIL - NO FLUFF/BOASTING

---

## 0. UPDATE INSTRUCTIONS

 - update Progress Report OFTEN e.g. after RESEARCH, COMMITS, DECISIONS

     - update autonomously
     - concise notes, refer to GH issues
     - new blockers / tasks / completed tasks
     - investigations needed
     - research found
     - solutions formulated
     - decisions made

 - update Task Management

    1. When NEW TASKS emerge - add tasks autonomously to "TASKS SCRATCHPAD"

    2. End of session - re-org Task Management carefully

        - thoughtfully consider and discuss with user
        - delete fully tested/completed/invalid/non-priority tasks (from this section)
        - FOR EACH TASK: merge new task notes with existing - in logical order
        - **BE CONCISE** DETAIL BELONGS IN GH ISSUE! AND IN PROGRESS REPORT BELOW
        - **USE CORRECT TASK FORMAT** See above
        - **CRITICAL:** update gh issues associated with each task!
        - **CRITICAL:** COMMIT changes when Tasks/Goals/Progress updated

     **NEVER UPDATE OR CHANGE PRIORITY AUTONOMOUSLY - ALWAYS DISCUSS FIRST WITH USER**

 - update Next Session Goals - at end of Context/Session

    - delete fully tested/completed/invalid goals
    - merge new Next Session Goals

## 2. Task Management

📋 **ALWAYS reference issues in our two Github Issue Trackers**
    GH MAIN COMFY-MULTI REPO:   https://github.com/ahelme/comfy-multi/issues/
    GH PRIVATE SCRIPTS REPO:    https://github.com/ahelme/comfymulti-scripts/issues/

### TASKS SCRATCHPAD - ADD REGULARLY e.g. on breaks, after commits

**New Tasks**

### CURRENT TASKS DASHBOARD - (UPDATED, PRIORITISED, REFERENCED) - UPDATE END SESSION

    **ALWAYS CHECK WITH USER BEFORE UPDATING**

 🔴 **(BLOCKER)** 
    **#29 VERDA TRACK: Architecture Design & Worker Container Re-Architect/Migrate**
    - Created: 2026-01-31 | Updated 2026-01-31
    - Key GH Issues:
        - `#29 VERDA TRACK: Architecture Design & Worker Container Re-Architect/Migrate`
    **GH ISSUES - REFERENCES**
    - Ref. parallel dev track (mello server):
        - `#28 MELLO TRACK: ComfyUI v0.11.1 Migration Analysis & Frontend Re-Architecture`
    - Ref: previous gh issue - to re-architect (prior to parallel migration/architect plan):
        - `#27 RE-ARCHITECT: Clean Separation + ComfyUI v0.11.1 Upgrade`
    - Ref. ComfyUI Changelogs:
        - `#26 Changelogs for Migration: ComfyUI v0.8.1 through to ComfyUI v0.11.1`
    - Ref. superceded issues (migration to v0.9.2 not v0.11.1):
        - `#22 Upgrade ComfyUI worker container to v0.9.2`
        - `#21 ComfyUI Migration 0.8.2 > 0.9.2`
    **HISTORY/BACKGROUND:**
    - PREV: we realised a very old ComfyUI was installed (~v0.8.1) when frontend failed
    - SO: started migrating frontend containers (now semi-upgraded to ComfyUI v0.9.2)
    - BUT: realised we need to migrate to ComfyUI v0.11.1
    - MEANWHILE: realised we should re-architect to migration-friendly app
    - SO: we have two parallel dev tracks in motion: 
        - ONE on Mello server - focus on migration changes
        - OTHER here on Verda server (us) - focus on architecture
    - AFTER re-architect, we must upgrade worker container on Verda for compatibility.

## Next Session Goals

1. **#28** - Re-Architect & Migrate to ComfyUIv0.11.1 - Mello Track (linked to #27)

### Pending (UNSCHEDULED)
- Produce new backups then test restore, fix til successful

---

# Progress Reports

---

## Progress Report Verda 01 - 2026-01-31 - Re-Architect app to suit migration
**Status:** In Progress
**Started:** 2026-01-31

### Summary
Successfully loaded context, read critical documentation, and discovered Translation Layer architecture pattern. Analyzed scope options and identified critical constraints from setup-verda-solo-script.sh.

### Implementation Phase
**Phase:** Phase 11 - Test Single GPU Instance (Restore & Verify)
**Current Focus:** Re-architect app to be ComfyUI-migration-friendly
**Next:** Brainstorm translation layer architecture, then plan implementation

---

### Activities

**Session Start - Architecture Investigation:**
- ✅ Created comprehensive information flow map (docs/architecture-information-flow-map.md - 446 lines)
- ✅ Mapped all API call sequences (job submission, workflow loading)
- ✅ Identified critical touchpoints for translation layer
- ✅ Updated issue #29 with architecture map findings
- ✅ Shared map with Mello Team for coordination

**Mello Team Research Integration:**
- ✅ Received holistic migration analysis from Mello Team
- ✅ Read `critique-holistic-v0.8.2-to-v0.11.1.md` (1185 lines)
- ✅ Analysis covers 7 versions, 350+ commits, 21 days timeline
- ✅ Updated issue #29 with corrected priorities based on Mello research

**Context Loading & Documentation Review (Previous):**
- ✅ Read CLAUDE.md, README.md, admin guides
- ✅ Read `docs/comfyui-0.9.2-app-structure-patterns.md` (402 lines - v0.9.2 patterns)
- ✅ Read `docs/comfy-multi-comparison-analysis-report.md` (754 lines - migration analysis)
- ✅ Read `setup-verda-solo-script.sh` (1039 lines - CRITICAL restore script)
- ✅ Reviewed issue #22 (superseded by #29 - targeting v0.11.1 not v0.9.2)
- ✅ Updated issue #29 with scope and constraints

**Key Learnings from Docs:**

**From Comparison Analysis Report:**
- Current migration ~85% complete (v0.9.2)
- What works: Unmodified ComfyUI core, volume mounts, custom_nodes/ extensions
- What needs improvement: Hardcoded paths, no abstraction layer, no integration tests
- Golden Pattern: "Treat ComfyUI as Upstream Dependency"

**From setup-verda-solo-script.sh (CRITICAL CONSTRAINTS):**
```
MUST PRESERVE:
- Project location: /home/dev/comfy-multi/
- Worker location: ~/comfy-multi/comfyui-worker/
- Docker command: cd ~/comfy-multi/comfyui-worker/ && docker compose up -d worker-1
- Symlinks: data/models → /mnt/sfs/models
           data/outputs → /mnt/scratch/outputs
           data/inputs → /mnt/scratch/inputs
- Container naming: comfyui-worker (image), worker-1 (service)
```

**From Mello Team Holistic Analysis (MAJOR DISCOVERIES):**

**🎯 CRITICAL FINDING: Worker API is Actually STABLE!**
- `/prompt`, `/queue`, `/ws`, `/api/userdata` endpoints: **UNCHANGED** across v0.9.2 → v0.11.1
- Our worker.py code (lines 84-96, 100-104) that directly calls ComfyUI: **STABLE!**
- This was our #1 critical touchpoint, but it's NOT breaking ✅

**🔴 THE REAL CRITICAL TOUCHPOINTS (Re-Prioritized):**

1. **Frontend Workflow Storage Paths** (CRITICAL)
   - v0.8.2: `/comfyui/input/` (static files)
   - v0.9.0+: `/comfyui/user/default/workflows/` (userdata API + URL encoding)
   - Impact: Workflows 404 on load (Session 20 discovery confirmed by Mello research)

2. **Frontend JavaScript Module System** (CRITICAL)
   - v0.8.2: `import { app } from "/scripts/app.js"` worked
   - v0.9.0: REMOVED, bundled frontend instead
   - Impact: All JavaScript extensions broken (Session 18-20 discoveries)

3. **Custom Node Volume Mount Trap** (ALL VERSIONS)
   - Empty host directory overwrites container contents
   - Impact: Extensions disappear (Session 20 discovery)
   - Solution: Entrypoint must populate if empty

**Key Insights:**
- **Silent Breaking Changes:** Changelogs don't document filesystem/API/extension changes
- **Testing Reveals More Testing:** API tests passed, browser tests revealed bugs
- **Dependency Omissions:** `requests`, `curl`, `libgomp1` missing from requirements.txt
- **Staged Migration Recommended:** v0.9.2 → v0.10.0 → v0.11.0 → v0.11.1 (11-13 hours, safer)

**Scope Analysis - Option B vs C:**

**Option B: Re-architect Frontend + Worker** (RECOMMENDED)
- Pros: Minimal setup script changes, preserves working services, faster, lower risk
- Cons: Half-measures, future debt, inconsistent patterns
- Effort: 2-3 days | Risk: Low-Medium

**Option C: Re-architect Entire App**
- Pros: Complete solution, maximum future-proofing, clean abstractions
- Cons: Setup script risk, scope creep, harder testing, coordination overhead
- Effort: 5-7 days | Risk: Medium-High

**BREAKTHROUGH: Translation Layer Concept** 💡

Discovered hybrid solution - adapter/facade pattern between services and ComfyUI:

```
Current (Tightly Coupled):
queue-manager → ComfyUI API (hardcoded)
nginx → ComfyUI endpoints (direct proxy)
admin → ComfyUI API (direct fetch)

Translation Layer (Decoupled):
queue-manager → [Adapter] → ComfyUI
nginx → [Adapter] → ComfyUI
admin → [Adapter] → ComfyUI
```

**Benefits:**
- Services call adapter with generic requests
- Adapter translates to version-specific ComfyUI calls
- When ComfyUI upgrades, only update adapter
- Setup script unchanged (project structure identical)
- Existing services barely change (just import adapter)
- Testable in isolation

**Three-Way Balance Principles:**
1. Setup Script Compatibility (fewest changes to restore workflow)
2. Existing Code Preservation (NO reinventing! NO writing from scratch!)
3. Migration-Friendly Architecture (ComfyUI versions drop in gracefully)

**Division of Labor:**
- **Verda Team (us):** Plan architecture + Implement worker + Deliver plan to Mello
- **Mello Team:** Plan v0.11.1 migration + Implement mello side + Deliver plan to Verda
- **Branches:** verda-track (us), mello-track (them)

---

### Decisions Made

1. **Scope:** Hybrid approach with Translation Layer (Option B+)
   - Re-architect frontend + worker (full implementation)
   - Create translation/adapter layer for services
   - Document patterns for future work

2. **Approach:** Brainstorming → Planning → Implementation
   - Use `superpowers:brainstorming` skill FIRST
   - Then `superpowers:writing-plans` for architecture doc
   - Consider `feature-dev:feature-dev` for codebase analysis

3. **Focus:** Pure architecture (division of labor - stick to it!)

4. **ARCHITECTURE PIVOT (Based on Mello Research):**
   - **Original Priority:** Worker API = CRITICAL, Frontend paths = HIGH
   - **Corrected Priority:** Worker API = STABLE ✅, Frontend patterns = CRITICAL 🔴
   - **Translation Layer Focus:** Frontend path abstraction, URL encoding, entrypoint population
   - **NOT Needed:** Worker API translation (endpoints stable across versions)

---

### Tools Identified

**Available Skills for This Task:**
1. `superpowers:brainstorming` ⭐ - Explore translation layer concept, requirements, design
2. `superpowers:writing-plans` - Document architecture, implementation roadmap
3. `feature-dev:feature-dev` - Analyze existing patterns, design new architecture

---

### Files Modified
- `docs/architecture-information-flow-map.md` - Created (446 lines - complete system map)
- `progress-verda-dev.md` - Updated with session progress + Mello research findings
- `.claude/CLAUDE-RESUME-VERDA-INSTANCE-VERDA-DEV.md` - Created (committed)
- `.claude/commands/resume-context-verda.md` - Created (committed)

---

### Commits
**Repo: comfy-multi**
- Branch: `verda-track`
- `336aa79` - docs: add comprehensive information flow map for architecture analysis
- `685eec5` - docs: note branch switch to verda-track
- `2bd56d6` - merge: sync with Mello team cleanup from dev branch
- `add4a47` - docs: Session Verda 01 progress - Translation Layer architecture discovery
- `380128c` - docs: add verda-dev context files and progress tracker (Session Verda 01)

---

### Next Steps
1. ⏸️ Wait for final Mello report (deeper layer analysis coming)
2. Update architecture map with corrected priorities (Worker API → Stable, Frontend → Critical)
3. Redesign translation layer to focus on:
   - Frontend path abstraction (version-specific workflow paths)
   - URL encoding helper utilities
   - Entrypoint directory population logic
   - Extension compatibility guidelines (avoid JavaScript, use Python backend)
4. Continue brainstorming session with corrected understanding
5. Create architecture document incorporating Mello research findings

---

