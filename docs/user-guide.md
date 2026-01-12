**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-02
**Doc Updated:** 2026-01-11

---

# ComfyUI Workshop - User Guide

Welcome to the ComfyUI v0.8.2 Multi-User Workshop! This guide will help you get started with creating AI-generated videos using LTX-2, the state-of-the-art 19B parameter video generation model.

## 📍 Accessing Your Workspace

Each participant has a dedicated, password-protected workspace:

**Your URL**: `https://comfy.ahelme.net/userXXX/`

Where `XXX` is your assigned user number (001-020).

### Login Credentials

You will receive your login credentials:
- **Username**: `userXXX` (e.g., user001, user010, user020)
- **Password**: Provided by instructor (16-character secure password)

### Access Steps:
1. Navigate to your assigned URL in a web browser
2. Enter your username and password when prompted (HTTP Basic Auth)
3. Click "Sign In" or press Enter

**Examples:**
- User 1: `https://comfy.ahelme.net/user001/` (Username: user01)
- User 10: `https://comfy.ahelme.net/user010/` (Username: user10)
- User 20: `https://comfy.ahelme.net/user020/` (Username: user20)

## 🎨 Getting Started

### 1. Open Your Workspace

Navigate to your assigned URL in a web browser. You'll see the ComfyUI interface with:
- **Left Panel**: Node library and workflow selector
- **Center Canvas**: Visual workflow editor
- **Right Panel**: Properties and settings
- **Top Bar**: Load/Save buttons and Queue Prompt

### 2. Load a Pre-built Workflow

We've included several pre-built workflows for LTX-2 video generation:

1. Click the **Load** button (folder icon) in the top-left
2. Navigate to the `/workflows/` directory
3. Select a workflow:
   - `ltx2_text_to_video.json` - LTX-2 text-to-video generation
   - `ltx2_with_upscaler.json` - LTX-2 video with 2x spatial upscaling
   - `ltx2_camera_control.json` - LTX-2 with camera dolly control

### 3. Customize Your Workflow

**Text Prompts:**
1. Find the "CLIP Text Encode" node (usually blue)
2. Click on the text box
3. Enter your description:
   - Positive prompt: "cinematic sunset over mountains, golden hour, 4k"
   - Negative prompt: "blurry, low quality, distorted"

**Settings:**
- **Steps**: Higher = better quality but slower (20-30 recommended)
- **CFG Scale**: Prompt adherence (7-11 recommended)
- **Seed**: Random number for reproducibility (change for variations)

### 4. Submit Your Job

1. Click **Queue Prompt** button (top-right)
2. Your job is submitted to the shared GPU queue
3. A status overlay appears showing:
   - ✅ Queue position
   - ⏱️ Estimated wait time
   - 📊 Job progress

**Important**: Jobs are processed one at a time on the shared GPU. Please be patient!

## 🚦 Queue System

### How It Works

All users share a single H100 GPU. The queue manager ensures fair access:

- **FIFO Mode** (default): First come, first served
- **Round-robin Mode**: Alternates between users
- **Priority Mode**: Instructor can jump the queue for demos

### Queue Status

**While your job is pending:**
- Status: "📤 Job submitted..."
- Position: "You are #3 in queue"

**When your job starts:**
- Status: "⚙️ Processing..."
- Progress updates in real-time

**When complete:**
- Status: "✅ Complete! Outputs ready"
- Images/videos appear in the output panel

### Canceling Jobs

If you need to cancel a job:
1. Click the **Cancel** button on the status overlay
2. Or ask the instructor to cancel via admin dashboard

## 📂 File Management

### Outputs

Generated images and videos are saved automatically:

**Location**: `/outputs/userXXX/`

**Accessing outputs:**
1. Right-click on an output node (e.g., "Save Image")
2. Select "View output"
3. Downloads appear in your browser's download folder

**Persistent Storage**: Your outputs are saved permanently and survive system restarts.

### Uploading Files

To use your own images/videos:

1. Find the "Load Image" or "Load Video" node
2. Click the **Upload** button
3. Select your file (max 500MB)
4. File is saved to `/inputs/userXXX/`

**Supported formats:**
- Images: JPG, PNG, WEBP
- Videos: MP4, MOV, AVI

### Custom Models

If you want to use custom models:
1. Upload model files via the "Load Checkpoint" node
2. Files are saved to `/models/userXXX/`
3. Only you can access your custom models
4. Shared workshop models are available to everyone

## 🛠️ Tips & Best Practices

### ⚡ Optimize Queue Time

- **Start simple**: Test with low step counts (10-15) first
- **Batch smartly**: Don't queue many jobs at once
- **Use pre-made workflows**: They're optimized for the GPU

### 🎯 Better Results

- **Be specific**: "portrait of a woman, studio lighting, 50mm lens" beats "woman"
- **Use negative prompts**: "blurry, low quality, distorted" prevents bad outputs
- **Iterate**: Try different seeds to explore variations

### 💾 Save Your Work

- **Export workflows**: File → Save to download your custom workflow
- **Name your files**: Use descriptive names for easy retrieval
- **Backup important outputs**: Download your best results

### 🐛 Troubleshooting

**Problem**: Queue Prompt button does nothing
- **Solution**: Check browser console (F12) for errors, refresh page

**Problem**: Job stuck in "Processing" for >10 minutes
- **Solution**: Ask instructor to check - job may have failed

**Problem**: Can't see my outputs
- **Solution**: Refresh the page or check `/outputs/userXXX/` directory

**Problem**: "Queue is full" error
- **Solution**: Wait for queue to clear, or ask instructor to clear stale jobs

## 🎓 Workflow Examples

### Basic Text-to-Image (SDXL)

```
1. CLIP Text Encode (Positive) → KSampler
2. CLIP Text Encode (Negative) → KSampler
3. Load Checkpoint → KSampler
4. Empty Latent Image → KSampler
5. KSampler → VAE Decode
6. VAE Decode → Save Image
```

**Prompt ideas:**
- "cyberpunk city at night, neon lights, rain, cinematic"
- "fantasy landscape, magical forest, ethereal lighting"
- "product photography, white background, studio lighting"

### Image-to-Image Variation

```
1. Load Image → VAE Encode
2. VAE Encode → KSampler (set denoise to 0.5-0.7)
3. CLIP Text Encode → KSampler
4. KSampler → VAE Decode → Save Image
```

**Use cases:**
- Style transfer
- Image enhancement
- Creative variations

### Video Generation

```
1. CLIP Text Encode → Video Model
2. Video Model → Video Output
3. Video Output → Save Video
```

**Tips:**
- Keep videos short (2-4 seconds) for faster processing
- Use descriptive motion prompts: "camera pans left to right"
- Video generation takes 5-10 minutes on average

## ⌨️ Keyboard Shortcuts

- **Ctrl+S** / **Cmd+S**: Save workflow
- **Ctrl+O** / **Cmd+O**: Load workflow
- **Ctrl+Enter**: Queue prompt
- **Delete**: Delete selected node
- **Ctrl+C/V**: Copy/paste nodes
- **Mouse wheel**: Zoom in/out
- **Middle mouse drag**: Pan canvas

## 🆘 Getting Help

**During the workshop:**
- Raise your hand and ask the instructor
- Check the admin dashboard for queue status
- Look at example workflows in `/workflows/` directory

**After the workshop:**
- ComfyUI documentation: https://comfyui-wiki.com/
- Community examples: https://comfyworkflows.com/
- GitHub repository: https://github.com/ahelme/comfy-multi

## 📊 Understanding the Interface

### Node Types

- **Loaders** (Green): Load models, images, videos
- **Conditioning** (Blue): Text prompts and embeddings
- **Sampling** (Orange): The main generation process
- **Latent** (Pink): Work with latent space
- **Image** (Purple): Image processing
- **Output** (Yellow): Save results

### Connection Colors

- **Purple**: Latent tensors
- **Blue**: Conditioning (prompts)
- **Red**: Models
- **White**: Images
- **Green**: Masks
- **Yellow**: Primitives (numbers, text)

### Status Indicators

- **🟢 Green node**: Ready to execute
- **🔴 Red node**: Missing input or error
- **🟡 Yellow border**: Currently executing
- **✅ Checkmark**: Successfully executed

## 🎯 Workshop Goals

By the end of this workshop, you should be able to:

- ✅ Navigate the ComfyUI interface
- ✅ Load and customize pre-built workflows
- ✅ Generate images from text prompts
- ✅ Upload and process your own images
- ✅ Create basic video generations
- ✅ Understand the queue system
- ✅ Troubleshoot common issues

## 🌟 Advanced Topics (Optional)

### Custom Nodes

ComfyUI supports custom nodes for extended functionality:
- ControlNet: Guided image generation
- IP-Adapter: Style reference
- AnimateDiff: Animation from still images

Ask the instructor if these are available!

### Workflow Sharing

To share your workflow with others:
1. File → Save
2. Upload to ComfyWorkflows.com
3. Share the link with classmates

### API Access

Advanced users can submit jobs via API:
```bash
curl -X POST https://comfy.ahelme.net/api/jobs \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user001", "workflow": {...}}'
```

See API documentation for details.

---

**Happy creating!** 🎨✨

If you have questions, don't hesitate to ask the instructor or check the troubleshooting section above.
