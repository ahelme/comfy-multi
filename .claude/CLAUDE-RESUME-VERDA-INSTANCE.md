CLAUDE RESUME - COMFY-MULTI (ASSUMES WELCOME HAS BEEN COMPLETED) 

**PHASE**: VERDA GPU INSTANCE DEPLOYMENT

## TODAY'S GOALS
                                                                              
  Today we are testing deployment for our web app ComfyMulti - designed to    
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
                                                                 
  - read top ~150 lines:
    - `./progress-02.md` - progress log

  - perform git status & check commit history
    - REPORT: any pending commits/pushes ?
    - REPORT: was progress-02.md up to date?

  - read list of implementation phases (phased dev plan)
    - **READ lines: 21-35 ONLY**: `./implementation-backup-restore.md`
    - CURRENT PHASE: | **Phase 11** | Test Single GPU Instance (Restore & Verify) | 🔨 Current |
    - NOTE: context within overall plan

## CORE KNOWLEDGE: DEPLOYMENT WORKFLOWS

  **GPU Rental - Instance and SFS**
  Verda charges full instance AND SFS fees when they stopped.
  Both SFS and instance must be deleted to not be charged.
  
  **DURING TESTING DAYS**
  We restore full Verda instance (with ComfyUI worker & dev user config etc.)
  AND restore the Verda SFS (with models etc.) so we can test everything.
  
  We also add a new scratch disk to Verda - as block storage.
  
  **BETWEEN TESTING / PRODUCTION**
  We delete Verda instance AND Verda SFS AND Verda block storage to save $$.
  
  **DURING 'WORKSHOP MONTH'**
  We restore and keep the SFS on Verda - during periods of regular usage 
  This is faster than re-downloading models from R2.
 
  **START OF WORKSHOP DAY**
  We restore Verda worker/config from SFS to instance root - so fast! 
  
  Hrly cron job backs up verda OS volume files -> SFS volume & mello users files -> R2
 
  **END OF WORKSHOP DAY**
  We run two backup scripts on mello: 
    - verda (models, container, config) -> R2 & 
    - mello (user files) -> R2
    - (see docs/admin-backup-restore.md)   

  THEN: we delete Verda GPU instance END OF DAY to save $$. 
    - but leave SFS (models) and block storage (scratch disk) running.

## NEXT:
  Review issue #8 on private repo (ahelme/comfymulti-scripts/issues/7) via gh cli.
  
  Please explain to the user the new setup-verda.sh (installed on provisioning, secrets loaded from .env.scripts via gh PAT, secrets added to linux keyring , restore-verda-instance.sh deployment system as you understand it!
 
  Then ask questions, clarify and discuss To Dos together before proceeding.

  ASK ANY QUESTIONS RE: UNCLEAR INFO OR STEPS :)

