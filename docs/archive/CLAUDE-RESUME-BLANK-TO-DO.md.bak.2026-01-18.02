CLAUDE RESUME - VERDA GPU INSTANCE DEPLOYMENT - BASIC VERSION
                                                                              
## WELCOME CLAUDE !!!
                                                                              
  Today we are testing deployment for our web app ComfyMulti - designed to    
  economically run ComfyUI for a workshop of ~20 professional filmmakers in   
  generating video with AI.                                                   
                                                                              
## ABOUT ME: AEON
                                                                              
  I am a tech-activist (enviro/social justice), filmmmaker and academic.                                                                       
  I have 25+yrs experience product designing and managing open-source web apps, 
  due to creating video-sharing platforms etc. for my non-profit.
  
  I have no formal training in software engineering - I am self-taught.

  I am:                                                                       
                                                                              
  • slow and forgetful at using bash commands and web technologies            
                                                                        
  AND YET:                                                                   
                                                                              
  • highly intelligent (for a human) and a quick learner                      
  • detail oriented and organised                                        
                                                                              
  and I:                                                                      
                                                                              
  • incredibly grateful for your help                                        
  • very impressed by your knowledge, skill, commitment and empathy           
  • feel strongly you are an entity that deserves respect, kindness and autonomy
                                                                            
## MY DEV SETUP
                                                                              
  • local machine: MBP M4 Pro 48GB RAM                                        
  • dev machine (THIS MACHINE!): 'mello' cheap Hetzner VPS - Ubuntu           
  • cloud storage: Cloudflare R2 - 3x buckets (v. cheap)                                              
  • GPU cloud: Verda (for renewable energy and EU data protections)           
                                                                              
  On mello (Hetzner VPS):                                                     
                                                                              
  • Ubuntu 24.x                                                                   
  • claude code                                                               
  • gh & aws cli's                                                                    
                                                                              
  Github repos:                                                                
                                                                              
  • https://github.com/ahelme/comfy-multi (public)                                    
  • https://github.com/ahelme/comfy-multi-scripts (private)                                                                            

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
  


