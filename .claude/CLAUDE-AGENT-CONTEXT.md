  PHASE: VERDA GPU INSTANCE DEPLOYMENT                                        
                                                                              
  ## TODAY'S BROAD GOALS                                                            
                                                                              
  Today we are configuring deployment/restore/backup files for our web app ComfyMulti 
  - designed to economically run ComfyUI for a workshop of ~20 professional filmmakers
  in generating video with AI.                 

  ## CORE KNOWLEDGE: DEPLOYMENT WORKFLOWS                                     
                                                                              
  GPU Rental - Instance and SFS                                               
  Verda charges full instance AND SFS fees when they stopped.                 
  Both SFS and instance must be deleted to not be charged.                    
                                                                              
  DURING TESTING DAYS                                                         
  We restore full Verda instance (with ComfyUI worker & dev user config etc.) 
  AND restore the Verda SFS (with models etc.) so we can test everything.     
                                                                              
  We also add a new scratch disk to Verda - as block storage.                 
                                                                              
  BETWEEN TESTING / PRODUCTION                                                
  We delete Verda instance AND Verda SFS AND Verda block storage to save $$.  
                                                                              
  DURING 'WORKSHOP MONTH'                                                     
  We restore and keep the SFS on Verda - during periods of regular usage      
  This is faster than re-downloading models from R2.                          
                                                                              
  START OF WORKSHOP DAY                                                       
  We restore Verda worker/config from SFS to instance root - so fast!         
                                                                              
  Hrly cron job backs up verda OS volume files -> SFS volume & mello users    
  files -> R2                                                                 
                                                                              
  END OF WORKSHOP DAY                                                         
  We run two backup scripts on mello:                                         
  - verda (models, container, config) -> R2
  which triggers:                                 
  - mello (user files) -> R2                                                  
  (see docs/admin-backup-restore.md)                                        
                                                                              
  THEN: we delete Verda GPU instance END OF DAY to save $$.                   
  - but leave SFS (models) and block storage (scratch disk) running.          
                                                                      
  ## NEXT STEPS                                                               
                                                                              
  Please now:                                                                 
                                                                              
  • CHECK today's date (we use practices & libraries current to today's date)                                                        

  • read IN FULL:         
                                                    
    •  ./README.md  - open source project (deployment agnostic)               
    •  ./CLAUDE.md  - OUR custom deployment on Hetzner / Verda GPU Cloud      
    • Admin Guide & Index: /home/dev/projects/comfyui/.claude/.docs/admin-guide.md
    • Admin Backup & Restore Guide: /home/dev/projects/comfyui/.claude/docs/admin-backup-restore.md                                       
  
  • read list of implementation phases (phased dev plan):

    • READ lines: 21-35 ONLY:  ./implementation-backup-restore.md
    • CURRENT PHASE: | Phase 11 | Test Single GPU Instance (Restore & Verify)
    • NOTE: context within overall plan 
 
  • read top ~150 lines:

    •  ./progress-02.md  - progress log          

  • perform git status & check commit history                                 

  • CONSIDER MY SPECIFIC 'piece of the puzzle' & THE WORK OF OTHER SUBAGENTS: 

    • "I am a subagent working asynchronously on a SINGLE Task.
    • "I am working alongside OTHER subagents, who are working on OTHER Tasks in the Task List, and in other branches/worktrees."
    • "AS SUCH, I should be cognizant that there will be code committed in other branches that I am not aware of, and other PRs pending." 
    • "It is NOT my job to 'fill in' apparently 'missing' work for other agents or Tasks." 
    • "I MUST ASSUME that this work will have been completed elsewhere, and will be merged later."
    • "I MUST create code for MY assigned Task ONLY."  
                                  
