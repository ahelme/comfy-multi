## Available Pre-Installed Workflows
as of 2026-01-30

  Workflows Available:                                                          
  - `ltx2_text_to_video.json`           - LTX-2 full 19B model (96.8 KB)                 
  - `ltx2_text_to_video_distilled.json` - LTX-2 distilled for faster generation (89.2 KB)   
  - `flux2_klein_9b_text_to_image.json` - Flux 2 Klein 9B image generation (72.3 KB)             
  - `flux2_klein_4b_text_to_image.json` - Flux 2 Klein 4B image generation (71.6 KB)         
  - `example_workflow.json`             - Legacy SDXL demo workflow (1.1 KB)

  All workflows are:                                                                                
  - Located in /home/dev/projects/comfyui/data/workflows/                                           
  - Documented in comprehensive README.md                                                           
  - Mounted read-only to all 20 user containers via docker-entrypoint.sh symlinks                   
  - Properly formatted with correct model references                                                
                                                                                                    
  Symlink Logic (comfyui-frontend/docker-entrypoint.sh:22-31):                                      
  - Correctly iterates through `/models/shared/*` subdirectories                                   
  - Creates symlinks: `/models/shared/checkpoints` → `/comfyui/models/checkpoints` 
  - Expects subdirectories: `checkpoints/, text_encoders/, loras/, vae/, latent_upscale_models/`  


  
