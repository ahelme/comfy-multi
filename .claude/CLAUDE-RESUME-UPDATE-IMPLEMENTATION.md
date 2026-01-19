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

  - read list of implementation phases (lines: 21-35 ONLY)
    - `./implementation-deployment-verda.md` - Phased dev plan 
    - REPORT: was current phase correct?
    - SHOULD BE CONCISE! DETAILS MAY CHANGE.

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
  
  Please explain to the user the basic deployment workflow as you understand it.
  
  Then review To Dos together before proceeding.

