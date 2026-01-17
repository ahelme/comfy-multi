# ComfyUI Workshop Workflows

Pre-loaded workflows for the ComfyUI Multi-User Workshop.

---

## Video Generation (LTX-2)

### ltx2_text_to_video.json
Full LTX-2 19B model for high-quality text-to-video generation.
- **Model:** ltx-2-19b-dev-fp8.safetensors
- **Steps:** 20-50 (quality)
- **VRAM:** ~40GB

### ltx2_text_to_video_distilled.json
Distilled LTX-2 for faster generation (8 steps).
- **Model:** ltx-2-19b-distilled-fp8.safetensors
- **Steps:** 8 (fast)
- **VRAM:** ~30GB

---

## Image Generation (Flux 2 Klein)

### flux2_klein_4b_text_to_image.json
Flux 2 Klein 4B comparison workflow - compares base (50 steps) vs distilled (4 steps).
- **Models:** flux-2-klein-4b.safetensors, flux-2-klein-base-4b.safetensors
- **VRAM:** ~9GB
- **Output:** Side-by-side comparison

### flux2_klein_9b_text_to_image.json
Flux 2 Klein 9B for higher quality image generation.
- **Models:** flux-2-klein-9b-fp8.safetensors, flux-2-klein-base-9b-fp8.safetensors
- **VRAM:** ~20GB
- **Output:** Side-by-side comparison

---

## Legacy

### example_workflow.json
Basic SDXL workflow (demo only).

---

## Adding Custom Workflows

1. Create your workflow in ComfyUI
2. Go to Menu → Save (API Format)
3. Save the JSON file to this directory
4. Workflows are automatically available to all users

---

**Source:** Official Comfy-Org workflow templates
**Last Updated:** 2026-01-17
