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

  **Verda Rental:** 
  Verda charges rental fees even while stopped: 
  Instance (on OS-BlockStorage) + models,cache,worker (SFS network drive) + Scratch (Data-BlockStorage)
  
  Hence we can delete Instance/OS-BlockStorage + Scratch/Data-BlockStorage to avoid those charges.

  When in regular use we keep SFS network drive (with our models+worker) and to restore instance from cache.
  
  **DURING 'TESTING MONTH' - or - 'WORKSHOP MONTH'**
  We create fresh Verda disks & restore from R2: SFS (models), Instance/OS-BlockStorage (cached setup,worker)
  We format a fresh Data-Block-Storage (scratch disk)
  
  Then we keep the SFS on Verda - faster than re-downloading models etc. from R2!

  But we delete the Instance & Scratch to save $$$.

  **DURING 'TESTING DAYS' or 'WORKSHOP DAYS'**
  Our SFS is still running - no need to restore it.
  We restore our fresh instance (setup, worker etc.) from cache on SFS.
  AND add a fresh Data-BlockStorage as our ephemeral scratch disk (user inputs/outputs).
  
  **BETWEEN TESTING / WORKSHOP PERIODS**
  We delete Verda instance AND Verda SFS AND Verda block storage to save $$.
  
  **BACKUPS WHILE VERDA INSTANCE IS RUNNING**
  Hrly cron job backs up verda OS volume files -> SFS volume & mello users files -> R2
 
  **END OF WORKSHOP DAY 1 (PRIOR TO WORKSHOP DAY 2)**
  We run an additional backup scripts on verda: 
    - verda disks (models, container, config) -> R2  
    
  THEN: we delete Verda GPU instance END OF DAY to save highest cost GPU instance $$. 
    - but leave BOTH: SFS (models) and block storage (scratch disk) running.

  **NOTE: If we switch to Serverless inference** 
    - we may choose to rent/restore to a much cheaper Verda CPU (NOT GPU) Instance
    - and keep it running during Workshop periods
    - IN WHICH CASE we could explore slightly different Verda disk configurations

## NEXT:

  Please explain to the user the basic deployment workflow as you understand it.

  Review issues #13, #19 & #21 in THIS REPO - READ IN FULL

  Please print out " ## Next Session Goals " in progress-02.md

  Then please add a ToDo - review issue #16 for possible closure

  Then create & discuss further To Dos together before proceeding.

  ASK ANY QUESTIONS RE: UNCLEAR INFO OR STEPS :)

