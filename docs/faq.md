# Frequently Asked Questions (FAQ)

Quick answers to common questions about the ComfyUI Multi-User Platform.

## 🌐 Access & Login

### How do I access my workspace?

Go to: `https://comfy.ahelme.net/userXXX/` (replace XXX with your number)

Examples:
- User 1: https://comfy.ahelme.net/user001/
- User 10: https://comfy.ahelme.net/user010/
- User 20: https://comfy.ahelme.net/user020/

### Do I need to log in?

No! Each URL is your personal workspace. Just bookmark it.

### Can others see my work?

No! Each user has completely isolated storage. Your images and workflows are private.

### What if I forget my user number?

Ask the workshop instructor. They have a list of all assignments.

---

## 🎨 Creating Images

### How long does it take to generate an image?

**It varies based on:**
- Complexity of workflow (15-90 seconds typical)
- Queue depth (how many people ahead of you)
- Image size (larger = slower)

**Typical times:**
- Simple image (20 steps, 1024x1024): ~20-30 seconds
- Detailed image (50 steps, refiner): ~60-90 seconds
- Video generation: 5-10 minutes

### Why is my job in queue for so long?

Everyone shares one GPU! If there are 10 people ahead of you, you wait for ~10 jobs.

**Check your position:** The popup shows "Position #X in queue"

### Can I cancel a queued job?

Yes! Click the "Cancel" button in the job status popup.

**Or:** Ask instructor to cancel via admin dashboard.

### Can I queue multiple jobs?

Yes, but be considerate! Queue one at a time during busy periods.

---

## 🖼️ Image Quality

### My image looks blurry/weird. How do I fix it?

**Try these:**

1. **Add negative prompt:**
   ```
   blurry, low quality, distorted, deformed
   ```

2. **Increase steps:**
   - Change from 20 → 30 in KSampler

3. **Adjust CFG scale:**
   - Try values between 7-11

4. **Be more specific in prompt:**
   - Instead of: "a cat"
   - Try: "portrait of a fluffy orange cat, detailed fur, studio lighting, 4k"

### How do I make images more realistic?

Add these keywords:
```
photorealistic, detailed, 8k, professional photography, studio lighting, sharp focus
```

### How do I make images more artistic?

Add style keywords:
```
oil painting, classical art, impressionist, watercolor, artistic, painterly
```

---

## 📁 Files & Storage

### Where are my outputs saved?

Your images are in: `/outputs/userXXX/`

They persist even after you close the browser!

### How do I download my images?

**Method 1:** Right-click on output image → "Save image as..."

**Method 2:** Right-click → "Open in new tab" → Save from there

**Method 3:** Ask instructor for ZIP of all your outputs

### Can I upload my own images?

Yes!

1. Find "Load Image" node (or create one)
2. Click "Choose File"
3. Select image from your computer
4. Image uploads to `/inputs/userXXX/`

**Max size:** 500MB per file

### How much storage do I have?

Plenty! Unless you generate thousands of images, you won't run out.

### Will my work be deleted after the workshop?

Ask your instructor! Typically workspaces stay active for 1-2 weeks.

---

## 🔧 Technical Issues

### The interface won't load

**Try:**
1. Refresh page (Ctrl+R or Cmd+R)
2. Clear browser cache
3. Try different browser (Chrome recommended)
4. Check if you're using correct URL

### "Queue Prompt" button doesn't work

**Solutions:**
1. Refresh the page
2. Press F12, check console for errors
3. Ask instructor to check server logs

### I see "Queue is full" error

The queue has reached max capacity (100 jobs).

**Solution:** Wait a few minutes for queue to clear, or ask instructor.

### My workflow disappeared!

**Don't panic!** ComfyUI auto-saves.

**Try:**
1. Refresh the page
2. Load → Look for "temp_workflow" or recent saves

**Prevention:** Save important workflows (Ctrl+S)

### The page is frozen/unresponsive

1. Wait 30 seconds (might be loading)
2. Refresh page
3. Ask instructor if server is working

---

## 🎓 Learning & Help

### I'm new to AI image generation. Where do I start?

1. Read [Quick Start Guide](./quick-start.md) - 5 minutes!
2. Follow [How-To Guides](./how-to-guides.md) - task by task
3. Experiment with pre-loaded workflows
4. Ask instructor for help!

### What are all these colorful boxes (nodes)?

Nodes are building blocks:
- 🟦 **Blue**: Text/prompts
- 🟧 **Orange**: Main generation
- 🟪 **Purple**: Image editing
- 🟩 **Green**: Models/loaders

You connect them like LEGO blocks!

### Do I need to understand all of this?

**No!** Start with pre-made workflows. You can learn advanced features later.

### Where can I learn more about ComfyUI?

**Resources:**
- ComfyUI Wiki: https://comfyui-wiki.com/
- ComfyWorkflows (examples): https://comfyworkflows.com/
- YouTube tutorials: Search "ComfyUI tutorial"
- Ask your instructor!

### Can I use this after the workshop?

**This platform:** Ask instructor about access duration

**ComfyUI at home:**
- Download ComfyUI: https://github.com/comfyanonymous/ComfyUI
- Run locally on your computer
- Or use cloud services (RunPod, Modal, etc.)

---

## ⚙️ Advanced Questions

### How do I change models?

If multiple models are loaded:
1. Find "Load Checkpoint" node
2. Click model dropdown
3. Select different model

### Can I create videos?

If video models are installed, yes!

Look for workflows named: `video_generation.json`

**Warning:** Videos take 5-10 minutes to generate!

### What's a "seed"?

The seed controls randomness:
- Same seed + same prompt = **same image**
- Different seed + same prompt = **different variations**

**Use seeds to:**
- Reproduce exact results (save seed number)
- Generate variations (change seed number)

### What's CFG scale?

Controls how closely it follows your prompt:
- **Low (4-6):** Creative, loose interpretation
- **Medium (7-10):** Balanced (recommended)
- **High (11-15):** Strict, literal

### What's a negative prompt?

Words you DON'T want in the image:
```
blurry, low quality, distorted, watermark, text, ugly
```

Always use one for better results!

### Can I combine multiple images?

Yes! Advanced workflows can:
- Blend images
- Use one image to guide another
- Create collages
- Apply styles from one image to another

Ask instructor for advanced workflows!

---

## 👥 Workshop-Specific

### How many people are using this?

Up to 20 participants share the platform.

### Can the instructor see my work?

Yes, via admin dashboard (for monitoring/troubleshooting only).

### What if I break something?

**You can't break it!** Each user is isolated. Worst case:
1. Refresh your page
2. Ask instructor to restart your container

### Can I help other participants?

Yes! Share workflows, tips, and cool results!

**To share a workflow:**
1. Save it (Ctrl+S)
2. Share the JSON file in chat
3. Others drag-and-drop it onto their canvas

### What happens if the server crashes?

**Rare, but if it does:**
1. Instructor will fix it quickly
2. Your work is saved (outputs persist)
3. Restart from where you left off

---

## 🚀 Performance & Optimization

### How can I make my jobs faster?

**Reduce:**
- Steps (20 instead of 50)
- Image size (512x512 instead of 1024x1024)
- Batch size (1 instead of 4)

**Strategy:** Test with low settings, then go high quality for final image!

### My job failed. What happened?

**Common causes:**
1. Out of memory (image too large)
2. Invalid workflow (missing connections)
3. Model not loaded

**Solution:** Ask instructor to check error logs

### Can I run multiple jobs at once?

**You can queue multiple**, but they process one at a time.

Be considerate during busy times!

---

## 🎨 Creative Tips

### How do I get better results?

**1. Be specific:**
- ❌ "a dog"
- ✅ "golden retriever puppy playing in grass, sunny day, 4k photo"

**2. Use style keywords:**
- photorealistic, anime, oil painting, 3D render

**3. Add quality tags:**
- detailed, masterpiece, best quality, 8k

**4. Use negative prompts:**
- blurry, low quality, distorted

### What makes a good prompt?

**Template:**
```
[SUBJECT], [ACTION], [SETTING], [STYLE], [QUALITY]
```

**Example:**
```
a wizard casting a spell, magical energy swirling, ancient library interior, fantasy art, detailed, dramatic lighting, 4k
```

### How do I create consistent characters?

**Tip 1:** Save the seed number!
- Same seed + similar prompt = same character

**Tip 2:** Be very specific in description:
```
young woman with long red hair, green eyes, freckles, wearing blue dress
```

### Where can I find inspiration?

- ComfyWorkflows.com
- Midjourney showcase
- ArtStation
- Pinterest
- Other workshop participants!

---

## 📞 Getting Help

### Who do I ask for help?

1. **Workshop instructor** - raise your hand!
2. **Other participants** - share tips!
3. **Documentation** - check guides

### What info should I provide when asking for help?

**Helpful info:**
- Your user number (e.g., user005)
- What you were trying to do
- Error message (if any)
- Screenshot (if possible)

### Can I contact support after the workshop?

Check with your instructor about post-workshop support options.

---

## 🎉 Fun Stuff

### What are some fun prompts to try?

**Fantasy:**
```
mystical dragon perched on crystal mountain, northern lights, magical atmosphere, fantasy art, detailed
```

**Sci-Fi:**
```
futuristic city floating in clouds, flying cars, sunset, cyberpunk, neon lights, detailed architecture
```

**Nature:**
```
bioluminescent forest at night, glowing plants, fireflies, magical atmosphere, cinematic, 4k
```

**Portrait:**
```
portrait of elegant woman, 1920s fashion, art deco style, detailed face, studio lighting, vintage photography
```

**Abstract:**
```
abstract explosion of colors, fluid dynamics, particles, energy, vibrant, digital art, 4k
```

### Can I create memes?

Absolutely! AI art is for everyone. Have fun! 😄

### What's the weirdest thing I can create?

**Limits?** Only your imagination! Try ridiculous combinations:
```
astronaut riding a unicorn through a donut-shaped galaxy, glitter explosion, surreal art
```

---

**Still have questions?** Ask your instructor! That's what they're here for. 🙋

Happy creating! 🎨✨
