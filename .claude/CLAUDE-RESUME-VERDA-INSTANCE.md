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

## NEXT TASKS (Session 22+):

**Primary Goal:** Create detailed GitHub issues for Mello team rebuild work

### Step 1: Create Mello Team Issues in comfyume Repo

**Foundation Issues (#20-24)** - Mello creates & executes:
- Copy queue-manager/ from comfy-multi
- Copy admin/ from comfy-multi
- Copy nginx/ from comfy-multi (update paths)
- Copy scripts/ (start.sh, stop.sh, etc.)
- Create docker-compose.yml (main orchestration)

**Phase 1 - Frontend Issues (#8-14 estimated):**
- Build frontend Dockerfile (v0.11.0 base)
- Create docker-entrypoint.sh (version-aware)
- Rewrite default_workflow_loader extension
- Rewrite queue_redirect extension
- Update 5 workflow templates
- Test single container startup

**Phase 3 - Integration Issues (#15-19)** - Both teams:
- End-to-end job submission test
- WebSocket connection test (frontend ↔ worker)
- VRAM monitoring integration
- Multi-user load test (20 users)
- Workshop readiness checklist

### Step 2: Update Private Scripts Repo

**Repository:** https://github.com/ahelme/comfymulti-scripts
- Create issue: "Update paths for comfyume rename"
- Branch: mello-track
- Update setup-verda-solo-script.sh:
  - REPO_URL: comfy-multi → comfyume
  - PROJECT_DIR: /home/dev/comfy-multi → /home/dev/comfyume
- Create PR

### Step 3: Coordinate via Issue #7

**Check regularly:** https://github.com/ahelme/comfyume/issues/7
- Post updates on Mello team progress
- Answer Verda team questions
- Coordinate integration testing

### Key Context:
- Session 21 research COMPLETE (14 agents, 11,320 lines)
- Mello Plan V1 ready (comfy-multi Issue #31)
- Verda team ready (Issues #2-6 created)
- Hooks configured (SessionStart, PreCompact, Stop)
- Worker API is STABLE (only rebuild frontend!)

**ASK QUESTIONS IF ANYTHING UNCLEAR!**

