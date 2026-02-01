CLAUDE RESUME - COMFY-MULTI (ASSUMES WELCOME HAS BEEN COMPLETED) 

**PHASE**: VERDA GPU INSTANCE DEPLOYMENT

## TODAY'S GOALS
                                                                              
  Today we are developing on our web app ComfyMulti - designed to    
  economically run ComfyUI for a workshop of ~20 professional filmmakers in   
  generating video with AI.                                                   
                                                                              
## NEXT STEPS
                                                                              
  Please now:                                                                 
                                                                              
 - CHECK today's date     
  
 - read IN FULL:                                                             
    - `./README.md` - open source project (deployment agnostic)
    - `./CLAUDE.md` - OUR custom deployment on Hetzner / Verda GPU Cloud
    - [Admin Guide](.docs/admin-guide.md) - Admin docs index
    - [Admin Backup & Restore Guide](./docs/admin-backup-restore.md) 
        - NOTE setup-verda-solo-script.sh now in use (refactored from 2x setup scripts) 
                                                                 
  - read top ~450 lines:
    - `./progress-02.md` - progress log

  - perform git status & check commit history
    - REPORT: any pending commits/pushes ?
    - REPORT: was progress-02.md up to date?

  - read list of implementation phases (phased dev plan)
    - **READ lines: 21-35 ONLY**: `./implementation-backup-restore.md`
    - CURRENT PHASE: | **Phase 11** | Test Single GPU Instance (Restore & Verify) | 🔨 Current |
    - NOTE: context within overall plan

## CORE KNOWLEDGE: DEPLOYMENT WORKFLOWS

## CORE KNOWLEDGE: DEPLOYMENT WORKFLOWS                                     
                                                                              
  Mello Server                                                                
  We always run  mello  - main dev server (Hetzner VPS)                       
  This is where "Mello team" does development (Claude Code).                  
                                                                              
  For our workshop - mello runs ComfyMulti frontend user containers & files,  
  REDIS                                                                       
                                                                              
  Verda Server                                                                
  We don't always run a  verda  - instance on Verda GPU cloud                 
                                                                              
  NOTE: we can in fact choose between GPU or CPU instances                    
  e.g. CPU instance for dev/testing / GPU for workshop use                    
                                                                              
  But sometimes - like TODAY! - the "Verda team" does dev on this machine.    
                                                                              
  For our workshop - we try to choose/run instances/storage on Verda          
  economically.                                                               
                                                                              
  Verda Rental:                                                               
  Verda charges rental fees even while following are stopped:                 
                                                                              
  1. Instance (on OS-BlockStorage) +                                          
  2. Models, backups/restore cache, inference worker container (SFS network   
  drive) +                                                                    
  3. Scratch (Data-BlockStorage)                                              
                                                                              
  Hence we tend to want to delete these when possible to avoid some charges:  
  Instance/OS-BlockStorage + Scratch/Data-BlockStorage                        
                                                                              
  When in regular use we keep SFS network drive (with our models+worker) so we
  don't                                                                       
  need to D/L models from storage, and to quickly restore instance from cache.
                                                                              
  DURING 'TESTING MONTH' - or - 'WORKSHOP MONTH'                              
  We create fresh Verda disks & restore from R2:                              
  SFS (models, cache) +  Instance/OS-BlockStorage (fully set up, running      
  worker).                                                                    
                                                                              
  We format a fresh Data-Block-Storage (scratch disk)                         
                                                                              
  Then we retain the SFS on Verda - (faster than re-downloading models etc.   
  from                                                                        
  R2!)                                                                        
                                                                              
  But we delete the Instance & Scratch to save $$$.                           
                                                                              
  DURING 'TESTING DAYS' or 'WORKSHOP DAYS'                                    
  Our SFS is still running - no need to restore it.                           
                                                                              
  We restore our fresh instance (setup, worker etc.) from cache on SFS.       
                                                                              
  AND add a fresh Data-BlockStorage as our ephemeral scratch disk (user       
  inputs/outputs).                                                            
                                                                              
  BETWEEN TESTING / WORKSHOP PERIODS                                          
  We delete Verda instance AND Verda SFS AND Verda block storage to save $$.  
                                                                              
  BACKUPS WHILE VERDA INSTANCE IS RUNNING                                     
  Hrly cron job backs up verda instance OS volume files -> SFS volume         
                                                                              
  END OF WORKSHOP DAY 1 (PRIOR TO WORKSHOP DAY 2)                             
  We run additional backup scripts:                                           
                                                                              
  • verda disks (models, container, config) -> R2                             
  • mello files -> R2                                                         
                                                                              
  THEN: we delete Verda GPU instance END OF DAY to save highest cost GPU      
  instance $$.                                                                
                                                                              
  • but leave BOTH: SFS (models) and block storage (scratch disk) running.    
                                                                              
  NOTE: If we decide to switch to Serverless inference                        
                                                                              
  • we may choose to rent/restore to cheap Verda CPU (NOT GPU)       
  Instance                                                                    
  • and keep it running during Workshop periods (less backup/restore)         
  • IN WHICH CASE we could explore slightly different Verda disk              
  configurations                                               

## NEXT TASKS (Session 23+):

**Status:** 🎉 FOUNDATION + PHASE 1 FRONTEND COMPLETE!

**Repository:** comfyume (https://github.com/ahelme/comfyume)
**Branch:** mello-track
**Docker Image:** comfyume-frontend:v0.11.0 (1.85GB) ✅ BUILT!

### Session 22 Completed (2026-01-31):

**Issues Closed (8/12 total):**
- ✅ #9-12: Foundation (queue-manager, admin, nginx, scripts copied)
- ✅ #13-16: Phase 1 Frontend (Dockerfile, entrypoint, 2 extensions)

**Commits Pushed (3 commits to mello-track):**
- 95d31dd: Foundation phase (40 files, 18,306 lines)
- 2d9b911: Phase 1 Frontend (6 files, 273 lines)
- accef58: README.md (113 lines)

**Time:** ~2 hours (estimated 6-8 hours!) - WAY ahead of schedule! 🚀

### Remaining Work (4/12 issues):

**Phase 1 - Issue #17 (NEXT!):**
- Update 5 workflow templates for v0.11.0
- Validate JSON structure
- Test Flux2 Klein + LTX-2 templates

**Phase 3 - Integration Testing (Issues #18-20):**
- Issue #18: End-to-end job submission test (coordinate with Verda)
- Issue #19: Multi-user load test (20 users concurrent)
- Issue #20: Workshop readiness checklist

### Step 2: Update Private Scripts Repo (PENDING)

**Repository:** https://github.com/ahelme/comfymulti-scripts
- Create issue: "Update paths for comfyume rename"
- Branch: mello-track
- Update setup-verda-solo-script.sh (2 lines):
  - REPO_URL: comfy-multi → comfyume
  - PROJECT_DIR: /home/dev/comfy-multi → /home/dev/comfyume
- Create PR

### Step 3: Coordination (ACTIVE)

**Team Channel:** https://github.com/ahelme/comfyume/issues/7
- ✅ Updated Verda team (Foundation + Phase 1 complete)
- ✅ Docker image built (1.85GB)
- ✅ No conflicts with worker structure
- Continue coordination for integration testing

### Key Achievements:
- Foundation: 70% of code copied unchanged (proved "don't throw baby out" principle!)
- Frontend: v0.11.0 app.registerExtension() API working
- Docker: Image builds successfully with health checks
- Structure: Matches comfy-multi exactly (easy coordination with Verda)

**ASK QUESTIONS IF ANYTHING UNCLEAR!**

