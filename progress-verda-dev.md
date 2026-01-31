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

## Progress Report Verda 01 - 2026-01-31 - Re-Architect app to suit  migration
**Status:** In Progress
**Started:** 2026-01-31

### Summary

### Implementation Phase
**Phase:** Phase 11 - Test Single GPU Instance (Restore & Verify)
**Current Focus:** Re-architect app to be ComfyUI-migration-friendly
**Next:** Upgrade worker container to new comfyui version
---

