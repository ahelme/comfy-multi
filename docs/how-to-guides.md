**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-02
**Doc Updated:** 2026-01-11

---

# How-To Guides - Common Tasks

Step-by-step guides for specific tasks. Pick what you want to learn!

## Table of Contents

1. [Create Your First Image](#1-create-your-first-image)
2. [Change Image Style](#2-change-image-style)
3. [Upload Your Own Images](#3-upload-your-own-images)
4. [Create Variations](#4-create-variations-of-an-image)
5. [Fix Common Mistakes](#5-fix-common-mistakes)
6. [Download Your Work](#6-download-your-work)
7. [Use Advanced Settings](#7-use-advanced-settings)
8. [Share Your Workflow](#8-share-your-workflow)

---

## 1. Create Your First Image

**Goal:** Generate an AI image from text

**Time:** 3 minutes + queue time

### Steps:

1. **Open workspace:** `https://comfy.ahelme.net/userXXX/`

2. **Load template:**
   - Click 📁 folder icon (top-left)
   - Open `/workflows/01_intro_text_to_image.json`

3. **Write your prompt:**
   - Find the blue "CLIP Text Encode" box
   - Change the text to describe what you want
   - Example: `"a sunset over mountains, warm colors, peaceful"`

4. **Queue it:**
   - Click "Queue Prompt" button (top-right)
   - Wait for your turn

5. **See result:**
   - Image appears in output panel when done!

**Tips:**
- Be specific: "portrait of a cat" → "close-up portrait of a fluffy orange cat, studio lighting"
- Use style keywords: "photorealistic", "cartoon", "oil painting", "3D render"

---

## 2. Change Image Style

**Goal:** Make the same prompt look different (realistic vs cartoon vs painting)

### Steps:

1. **Start with a prompt:**
   ```
   "a red dragon"
   ```

2. **Add style keywords:**
   ```
   "a red dragon, photorealistic, detailed scales, cinematic lighting"
   ```
   OR
   ```
   "a red dragon, cartoon style, cute, colorful, children's book illustration"
   ```
   OR
   ```
   "a red dragon, oil painting, classical art, renaissance style"
   ```

3. **Queue and compare!**

**Common Styles:**
- **Photorealistic:** `photorealistic, 8k, detailed, professional photography`
- **Anime:** `anime style, manga, vibrant colors, detailed lineart`
- **Oil Painting:** `oil painting, classical art, brushstrokes, canvas texture`
- **3D Render:** `3D render, blender, octane render, studio lighting`
- **Sketch:** `pencil sketch, charcoal drawing, black and white, crosshatching`

---

## 3. Upload Your Own Images

**Goal:** Use your photo as a starting point

### Steps:

**Method 1: Upload via Load Image Node**

1. **Find "Load Image" node** in your workflow
   - If it doesn't exist, right-click canvas → Add Node → image → Load Image

2. **Click "Choose File" button** in the Load Image node

3. **Select your image** from your computer
   - Max size: 500MB
   - Formats: JPG, PNG, WEBP

4. **Image appears** in the node preview

5. **Connect it** to the workflow (if not already connected)

6. **Queue Prompt!**

**Method 2: Drag & Drop**

1. **Drag your image file** from your computer
2. **Drop it on the canvas**
3. ComfyUI automatically creates a Load Image node!

**Tips:**
- Lower resolution = faster processing
- Square images work best (512x512, 1024x1024)
- Resize large images before uploading

---

## 4. Create Variations of an Image

**Goal:** Generate similar but different versions

### Method 1: Change the Seed

1. **Find the "KSampler" node** (usually orange/yellow)
2. **Look for "seed" number** (e.g., 42, 156789, etc.)
3. **Change it to any number:**
   - seed: 42 → 43 → 44 → 100 → 999
4. **Queue each version!**

**Result:** Same prompt, different results!

### Method 2: Use "control_after_generate"

1. **In KSampler node**, find `control_after_generate`
2. **Set to "increment"**
3. **Click Queue Prompt multiple times**
4. Each click creates a different version automatically!

### Method 3: Batch Generation

1. **In KSampler**, find `batch_size`
2. **Change from 1 to 4** (generates 4 images at once)
3. **Queue once, get 4 variations!**

**Warning:** Batch size increases memory usage. Start small!

---

## 5. Fix Common Mistakes

### Problem: "Queue Prompt" button doesn't work

**Solution:**
1. Refresh the page (Ctrl+R or Cmd+R)
2. Check browser console (F12) for errors
3. Try a different browser (Chrome recommended)

### Problem: Image looks bad (blurry, distorted, weird)

**Solutions:**
1. **Add negative prompt:**
   - Find "CLIP Text Encode (Negative)"
   - Add: `blurry, low quality, distorted, deformed, ugly, bad anatomy`

2. **Increase steps:**
   - In KSampler, change `steps` from 20 → 30

3. **Adjust CFG scale:**
   - In KSampler, try `cfg` between 7-11
   - Lower = more creative but less accurate
   - Higher = follows prompt strictly

### Problem: Job stuck in "Processing" forever

**Solution:**
1. Check admin dashboard: `https://comfy.ahelme.net/admin`
2. Ask instructor to check worker logs
3. If truly stuck (>10 minutes for simple image), ask instructor to cancel

### Problem: "Queue is full" error

**Solution:**
1. Wait for queue to clear (check admin dashboard)
2. Ask instructor to clear failed jobs

### Problem: Can't find my outputs

**Solution:**
1. Outputs are in `/outputs/userXXX/` directory
2. Right-click on output image → "Open in new tab"
3. Save from there!

---

## 6. Download Your Work

### Download Single Image

**Method 1: Right-click**
1. Right-click on output image
2. Select "Save image as..."
3. Choose location and filename

**Method 2: Open in new tab**
1. Right-click → "Open image in new tab"
2. Right-click again → "Save image as..."

### Download All Your Outputs

**Ask instructor** to provide a ZIP file of your `/outputs/userXXX/` folder at the end of the workshop.

**Or:** Access via file system (advanced users):
```
/outputs/userXXX/
```

---

## 7. Use Advanced Settings

### Control Image Quality

**In KSampler node:**

- **steps** (10-50):
  - 10: Fast but rough
  - 20: Good balance (default)
  - 30-50: High quality but slow

- **cfg** (4-15):
  - 5-7: Creative, loose interpretation
  - 8-10: Balanced (recommended)
  - 11-15: Strict adherence to prompt

- **denoise** (0.0-1.0):
  - 1.0: Complete new image
  - 0.5-0.8: Moderate changes (for img2img)
  - 0.1-0.3: Subtle modifications

### Change Image Size

**In "Empty Latent Image" node:**

- **width** & **height**:
  - 512x512: Fast, low memory
  - 1024x1024: Standard SDXL
  - 1024x1536: Portrait
  - 1536x1024: Landscape

**Warning:** Larger = slower + more memory!

### Use Different Models

**If multiple models are loaded:**

1. Find "Load Checkpoint" node
2. Click dropdown menu
3. Select different model
4. Queue Prompt!

**Popular models:**
- SDXL Base: Photorealistic, detailed
- SDXL Turbo: Fast but lower quality
- Anime models: Cartoon/anime style

---

## 8. Share Your Workflow

### Export Your Workflow

1. **File menu** (top-left) → **Save**
2. Or press **Ctrl+S** (Cmd+S on Mac)
3. File downloads as `workflow.json`

### Share with Others

1. **Upload to ComfyWorkflows.com:**
   - Go to https://comfyworkflows.com/
   - Click "Upload Workflow"
   - Drag your `workflow.json` file
   - Get shareable link!

2. **Share in workshop chat:**
   - Post your workflow.json file
   - Others can load it by dragging onto their canvas

### Load Someone Else's Workflow

1. **Download their workflow.json**
2. **Drag and drop** onto your ComfyUI canvas
3. Or use Load button → select file

---

## Quick Reference Cards

### Prompt Writing Tips

**Structure:**
```
[SUBJECT], [STYLE], [DETAILS], [QUALITY TAGS]
```

**Example:**
```
a magical forest, fantasy art, glowing mushrooms and fireflies, detailed, cinematic lighting, 8k
```

**Negative Prompt Template:**
```
blurry, low quality, distorted, deformed, ugly, bad anatomy, watermark
```

### Common Keyboard Shortcuts

- **Ctrl+S** / **Cmd+S**: Save workflow
- **Ctrl+O** / **Cmd+O**: Load workflow
- **Ctrl+Enter**: Queue Prompt
- **Delete**: Delete selected node
- **Ctrl+C/V**: Copy/paste nodes
- **Mouse wheel**: Zoom
- **Middle mouse drag**: Pan canvas
- **Double-click canvas**: Search nodes

### Node Colors

- 🟦 **Blue**: Text/conditioning (prompts)
- 🟧 **Orange**: Sampling (main generation)
- 🟪 **Purple**: Image operations
- 🟩 **Green**: Model loaders
- 🟨 **Yellow**: Utilities

---

## Still Stuck?

1. **Check [Troubleshooting Guide](./troubleshooting.md)**
2. **Ask instructor for help**
3. **Look at [Complete User Guide](./user-guide.md)**
4. **Browse ComfyUI Wiki**: https://comfyui-wiki.com/

---

**Happy creating!** 🎨✨

Remember: The best way to learn is by experimenting. Don't be afraid to try things!
