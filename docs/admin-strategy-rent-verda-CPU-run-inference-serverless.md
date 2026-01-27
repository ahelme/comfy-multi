Architecture: Cheap CPU Instance + Serverless GPU       
                                                          
  ┌─────────────────────────────────────┐                 
  │ Verda CPU Instance (~$0.01/hr)      │  ← CHEAP!       
  │  - Queue Manager (FastAPI)          │                 
  │  - Redis (job queue)                │                 
  │  - 20 User Frontends                │                 
  │  - Nginx (HTTPS)                    │                 
  │  - NO GPU NEEDED                    │                 
  └──────────────┬──────────────────────┘                 
                 │ HTTP REST API                          
                 ↓                                        
  ┌──────────────────────────────────────┐                
  │ Verda Serverless Containers          │  ← AUTO-SCALE! 
  │  - Scales 0-5 based on queue         │                
  │  - H100 GPU ($2.30/hr per replica)   │                
  │  - $0 when idle                      │                
  └──────────────────────────────────────┘                
                                                          
  Why This Is Perfect:                                    
                                                          
  ✅ CPU instance runs 24/7 (~$7/month instead of $15+    
  Hetzner)                                                
  ✅ GPU only when needed ($0 when idle)                  
  ✅ All in one cloud provider (simpler networking)       
  ✅ Fast interconnect (same datacenter)                  
  ✅ Perfect for testing serverless setup                 
                                                          
  Verda CPU Pricing:                                      
  - 2 vCPU, 4GB RAM: ~$0.009/hr = $6.50/month             
  - 4 vCPU, 8GB RAM: ~$0.018/hr = $13/month               
                                                          
  vs Current Setup:                                       
  - Hetzner VPS: ~$10-15/month                            
  - About the same cost, but:                             
    - GPU serverless in same network                      
    - No Tailscale VPN needed                             
    - Faster Queue Manager ↔ Worker communication   

   OR

   Keep Hetzner (main dev sandbox)
   Keep Backups System
   During Workshops periods restore cheap Verda CPU instance
   Run AI Inference as serverless for performance & cost savings