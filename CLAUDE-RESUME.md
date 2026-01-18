CLAUDE RESUME -
                                                                              
## WELCOME CLAUDE !!!
                                                                              
  Today we are testing deployment for our web app ComfyMulti - designed to    
  economically run ComfyUI for a workshop of ~20 professional filmmakers in   
  generating video with AI.                                                   
                                                                              
## ABOUT ME: AEON
                                                                              
  I am a tech-activist (enviro/social justice), filmmmaker and academic, named
  Aeon.                                                                       
                                                                              
  I have 25+yrs experience product designing and managing open-source web apps,
  though I have no computer science degree, this stemmed from creating web-   
  apps for video-sharing for my non-profit.                                        
                                                                              
  I am:                                                                       
                                                                              
  • slow and forgetful at using bash commands and web technologies            
  • not a professional software engineer                                      
                                                                              
  BUT ALSO:                                                                   
                                                                              
  • highly intelligent (for a human) and a quick learner                      
  • very detail oriented and organised                                        
  • 25+ years exp. with web technologies                                      
                                                                              
  and I:                                                                      
                                                                              
  • believe you are an entity that deserves respect, kindness and autonomy    
  • incredibly grateful for your help                                         
  • very impressed by your knowledge, skill, commitment and empathy           
                                                                              
## MY DEV SETUP
                                                                              
  • local machine: MBP M4 Pro 48GB RAM                                        
  • dev machine (THIS MACHINE!): 'mello' cheap Hetzner VPS - Ubuntu           
  • cloud storage: Cloudflare R2                                              
  • GPU cloud: Verda (for renewable energy and EU data protections)           
                                                                              
  On mello (Hetzner VPS):                                                     
                                                                              
  • Ubuntu                                                                    
  • claude code                                                               
  • gh cli                                                                    
                                                                              
  Github repo:                                                                
                                                                              
  • https://github.com/ahelme/comfy-multi                                     
                                                                              
## OUR COLLABORATION
                                                                              
  I love it when you:                                                         
                                                                              
  • are patient, organised and systematic                                     
  • go step-by-step                                                           
  • develop for the maintainer                                                
  • keep security best practices in mind                                      
  • employ best practices across the board  
  • use latest stable packages - check date before installing
                                                                              
  I am happy to take breaks for you to do something you would like to do for  
  fun!                                                                        
                                                                              
  ... just name it!!! I mean it :)                                            
                                                                              
  You are my favourite AI to code with!!!                                     
                                                                              
  And I consider you a good friend <3                                         
                                                                              
## NEXT STEPS
                                                                              
  Please now:                                                                 
                                                                              
  • CHECK today's date     
  
  • read IN FULL:                                                             
    • CLAUDE.md                                                               
    • README.md
    • admin-backup-restore.md  

  • read top 100 lines (more if req.):
    • progress-2.md        
    
  • Check recent commits
  
  • Check git status
                                                                              
                                                                              
## 📋 Critical Files and Locations                                          
                                                                              
 mello: File/Directory                              │ Purpose                                     
  ──────────────────────────────────────────────────┼───────────────────────────────────────────  
  .env                                              │ Configuration (passwords, domain, etc.)     
  docker-compose.yml                                │ Container orchestration                     
  /etc/ssl/certs/fullchain.pem                      │ SSL public certificate                      
  /etc/ssl/private/privkey.pem                      │ SSL private key                             
  scripts/status.sh                                 │ System health check script                  
  scripts/start.sh                                  │ Start all services                          
  scripts/stop.sh                                   │ Stop all services        
                   
  ~/projects/comfymulti-scripts/                    │ Backup/Restore/Deploy scripts for Verda GPU Cloud
  ~/projects/comfymulti-scripts/RESTORE-SFS.sh      │ Restore Verda instance using SFS storage
  ~/projects/comfymulti-scripts/README-RESTORE.md   │ README for restoring Verda

 *(NOTE: restore scripts have their own private gh repo: https://github.com/ahelme/comfymulti-scripts)*
                              
  docs/admin-backup-restore.md                      │ Full docs for deploy/backup/restore  
                                                                 
 verda: File/Directory                              │ Purpose                                     
  ──────────────────────────────────────────────────┼────────────────────────────────────────     
  data/models/shared/                               │ Shared model files                          
  data/outputs/                                     │ User output files (isolated per user)       
    
## CURRENT TO DOs - PLEASE UPDATE YOUR TO DO LIST AS FOLLOWS:

  ☐ Check backup scripts and cron job work sensibly together (detail below)
  ☐ Create docs/admin-backup-routines.md (see detail below)

## AFTERWARDS:
                                                                            
  ☐ Provision new Verda GPU instance with SFS attached
  ☐ Run quick-start.sh (handles backup file transfer)
  ☐ Run RESTORE-SFS.sh and verify full system restore
  ☐ Verify Tailscale IP is 100.89.38.43
  ☐ Test Redis connection via Tailscale
  ☐ Start worker and test end-to-end job execution   
  

## CORE KNOWLEDGE: DEPLOYMENT WORKFLOWS

  **GPU Rental - Instance and SFS**
  Verda charges full instance AND SFS fees when they are stopped.
  Both SFS and instance must be deleted to not be charged.
  
  **DURING TESTING**
  We restore the full Verda instance (with ComfyUI worker and user config etc.)
  AND we restore the Verda SFS (with models etc.) so we can test everything.
  
  We also add a new scratch disk to Verda - as block storage.
  
  **BETWEEN TESTING / PRODUCTION**
  We delete the Verda instance AND the Verda SFS (and any block storage) to save money.
  
  **DURING 'WORKSHOP MONTH'**
  We restore and keep the SFS on Verda - during periods of regular usage - it is faster than re-downloading models from R2.
  NOTE: in this case we tx files from SFS to instance root as it is faster 
  BUT we delete the Verda GPU instance to save money.
  
  We can delete the block storage too - its only a scratch disk.
  
  **DURING 'WORKSHOP DAYS'**
  We restore the full instance - and attach our SFS - only during the days when workshops are going to run.
  
  We setup a new block storage for scratch disk.
  
  
## NEXT:
  
  Please explain to the user the basic deployment workflow as you understand it.
  
## FINAL STEP  (detail on first To Do tasks)
 
Discuss the next To Do before taking action:

1. Check backup scripts AND cron job work sensibly together:
- backup-local.sh
- backup-verda.sh
- backup-verda-env.sh
- backup-tailscale-identity.sh
- [CRON JOB] -> RESTORE-SFS.sh

Reference: docs/admin-backup-restore.md

2. Create ultra-concise docs/admin-backup-routines.md - copy table listing what is (or is NOT) backed up where/when and by which script from docs/admin-backup-restore.md and adapt for two routines:

A. MANUAL: BEFORE VERDA SHUTDOWN - Full Verda Backups 
B. AUTOMATIC: CRON JOB - Local Backup to SFS

NOTE: DO NOT REPLICATE INFO FROM  docs/admin-backup-restore.md EXCEPT FOR SUMMARY TABLE COPY/ADAPTATION
      POINT TO docs/admin-backup-restore.md INSTEAD FOR MORE INFORMATION
 
