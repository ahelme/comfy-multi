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
  apps                                                                        
  for video-sharing for my non-profit.                                        
                                                                              
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
    • implementation-deployment-verda.md
    • implementation-backup-restore.md
    • docs/admin-setup-guide.md
    • docs/admin-verda-setup.md
    • docs/admin-workflow-workshop.md  
    • /home/dev/backups/verda/README-RESTORE.md
    
  • read top 100 lines (more if req.):
    • progress-2.md        
    
  • Check recent commits
  
  • Check git status
                                                                              
                                                                              
## 📋 Critical Files and Locations                                          
                                                                              
   mello: File/Directory                            │ Purpose                                     
  ──────────────────────────────────────────────────┼───────────────────────────────────────────  
    .env                                            │ Configuration (passwords, domain, etc.)     
    docker-compose.yml                              │ Container orchestration                     
    /etc/ssl/certs/fullchain.pem                    │ SSL public certificate                      
    /etc/ssl/private/privkey.pem                    │ SSL private key                             
    scripts/status.sh                               │ System health check script                  
    scripts/start.sh                                │ Start all services                          
    scripts/stop.sh                                 │ Stop all services                           
    /home/dev/backups/verda/RESTORE-SFS.sh          │ Restore Verda instance using SFS storage    
    /home/dev/backups/verda/RESTORE-BLOCK-MELLO.sh  │ Restore Verda instance using block storage  
                                                                                                  
   verda: File/Directory                            │ Purpose                                     
  ──────────────────────────────────────────────────┼────────────────────────────────────────     
    data/models/shared/                             │ Shared model files                          
    data/outputs/                                   │ User output files (isolated per user)       
    
## CURRENT TO DOs
                                                                              
  ☐ Create consolidated admin-backup-restore.md doc
  ☐ Remove duplicate backup/restore info from other docs
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
  BUT we delete the Verda GPU instance to save money.
  
  We can delete the block storage too - its only a scratch disk.
  
  **DURING 'WORKSHOP DAYS'**
  We restore the full instance - and attach our SFS - only during the days when workshops are going to run.
  
  We setup a new block storage for scratch disk.
  
  
## NEXT:
  
  Please explain to the user the basic deployment workflow as you understand it.
  
## FINAL STEP  (detail on first To Do tasks)
  

* Please note that user files etc. from mello (Hetzner - this server) are normally restored to the new instance by quick-start.sh which is added during Verda instance provisioning)


1. please read this file in FULL: ~/backups/verda/RESTORE-SFS.sh - Full restore for SFS workflow

2. please create a single backup / restore doc here:

admin-backup-restore.md

Use the OLD backup-restore doc as basis for this new doc.

I moved the OLD backup-restore doc here:

admin-backup-restore-block-storage.md


3. Ensure this new doc says that quick-start.md performs the restore of files from backup

But note that if it has not worked it can be done manually using:

`scp ~/backups/verda/* root@<ip>:/root/` 


4. Remove duplicate restore/backups information from these files and replace with link to docs/admin-backup-restore.md :

  
  implementation-deployment-verda.md
  CLAUDE.md
  README.md
  docs/implementation-backup-restore.md
  docs/admin-workflow-workshop.md
  docs/admin-cpu-testing-guide.md   
  docs/admin-gpu-environment-backup.md 
  docs/admin-scripts.md  
  docs/admin-setup-guide.md   
  docs/admin-verda-setup.md  
  docs/admin-workflow-workshop.md 
  docs/admin-workshop-checklist.md
  docs/faq.md
  docs/how-to-guides.md
  docs/troubleshooting.md
  docs/workshop-runbook.md
  
  
5. Link to docs/admin-backup-restore.md from the main admin overview doc here:

  docs/admin-guide.md   

(it may already be linked - please check first!)

