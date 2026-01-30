# Storage                                        
as of 2026-01-30                                                                                                    
  1. Cloudflare R2 - eu-central (permanent, ~$3/month) - Models, container, configs 
        - ??? GB as of 2026-01-30
        - fully elastic - add data to grow buckets
         
  2. Verda SFS - Finland (workshop month, ~$14/month) - Fast model access 
        - 50GB as of 2026-01-30
        - scalable - can shutdown, scale up, restart
  
  3. Verda Block - Finland (considered ephemeral, 50GB=~$14/month) - Scratch disk for outputs
        - 50GB as of 2026-01-30
        - scalable - can shutdown, scale up, restart
         
  4. Mello Hetzner VPS - Finland (always-on) - Working backups, scripts source  
        - 80GB as of 2026-01-30
        - scalable - can shutdown, scale up, restart (CANNOT SCALE DOWN!)
        - OR can add Volumes or object storage via Hetzner console

  5. Verda OS Instance - Finland (considered ephemeral, 50GB=~$14/month) 
        - 50GB as of 2026-01-30
        - scalable - can shutdown, scale up, restart



