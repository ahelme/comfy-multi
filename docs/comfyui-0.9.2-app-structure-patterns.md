# ComfyUI v0.9.2 - App Structure & Patterns (Mini Guide)

**Project:** ComfyUI Multi-User Workshop Platform
**Doc Created:** 2026-01-31
**ComfyUI Version:** v0.9.2
**Purpose:** Quick reference for v0.9.2 patterns and best practices

---

## 🎯 Core Architecture Patterns

### Entry Point
```bash
python main.py --listen 0.0.0.0 --port 8188 [--cpu]
```
- `--cpu`: Disables GPU (keeps all APIs working)
- Server: aiohttp on port 8188
- Singleton: `PromptServer.instance`

### Directory Structure (REQUIRED)
```
/comfyui/user/default/
├── workflows/              ← Workflow JSON files
│   └── *.json
├── comfy.settings.json     ← Auto-created by app
├── comfy.templates.json    ← Optional metadata
└── custom_nodes/           ← Per-user extensions
```

---

## 📡 Userdata API Patterns

### List Files
```http
GET /api/userdata?dir=workflows
→ ["workflow1.json", "workflow2.json"]
```

### Get File (URL-ENCODED paths!)
```http
GET /api/userdata/workflows%2Ffile.json  ✅ CORRECT
GET /api/userdata/workflows/file.json    ❌ WRONG (404)
```

### Save File
```http
POST /api/userdata/workflows%2Ffile.json
Content-Type: application/json
{ workflow JSON }
```

### Key Pattern
**Root files:** `/api/userdata/filename.json` (no encoding needed)
**Nested files:** `/api/userdata/subdir%2Ffilename.json` (MUST encode `/` as `%2F`)

---

## 🔌 Custom Extension Patterns

### v0.9.2 Extension Structure
```python
# /comfyui/custom_nodes/my_extension/__init__.py

import server
from aiohttp import web

# Define node class (optional)
class MyNode:
    @classmethod
    def INPUT_TYPES(cls):
        return {"required": {"text": ("STRING",)}}

    RETURN_TYPES = ("STRING",)
    FUNCTION = "process"
    CATEGORY = "custom"

    def process(self, text):
        return (text.upper(),)

# Export node mappings
NODE_CLASS_MAPPINGS = {
    "MyNode": MyNode
}

NODE_DISPLAY_NAME_MAPPINGS = {
    "MyNode": "My Custom Node"
}

# Register API endpoint (optional)
@server.PromptServer.instance.routes.get("/api/my_endpoint")
async def my_endpoint(request):
    return web.json_response({"status": "ok"})
```

### ❌ DON'T (v0.8.2 pattern - incompatible!)
```javascript
import { app } from "/scripts/app.js";  // Doesn't exist in v0.9.2!
import { api } from "/scripts/api.js";  // Doesn't exist in v0.9.2!
```

### ✅ DO (v0.9.2 pattern)
- Register endpoints via Python API
- Use `server.PromptServer.instance.routes`
- Frontend calls your endpoints via fetch()

---

## 🐳 Docker Volume Patterns

### User Isolation (Per-User Volume)
```yaml
volumes:
  - ./data/user_data/user001:/comfyui/user
```
**Contains:** workflows/, settings, custom_nodes/

### Shared Models (Read-Only)
```yaml
volumes:
  - /models/shared:/models:ro
```
**Why `:ro`:** Prevents accidental modification

### Workflow Templates (Read-Only Source)
```yaml
volumes:
  - ./data/workflows:/workflows:ro
```
**Purpose:** Copied to each user's `/comfyui/user/default/workflows/` on startup

### ⚠️ Volume Mount Gotcha
**Empty host directory OVERWRITES container contents!**

Solution: Entrypoint copies defaults if missing:
```bash
if [ ! -d "$USER_DIR/workflows" ]; then
    cp -r /workflows/* $USER_DIR/workflows/
fi
```

---

## 🚀 Startup Sequence (Best Practice)

### Entrypoint Pattern
```bash
#!/bin/bash
set -e

# 1. Set environment
export COMFYUI_USER_ID="${USER_ID}"
export QUEUE_MANAGER_URL="${QUEUE_MANAGER_URL:-http://queue-manager:3000}"

# 2. Create user directories
mkdir -p /comfyui/user/default/workflows

# 3. Copy templates (if user directory empty)
if [ ! -f "/comfyui/user/default/workflows/.initialized" ]; then
    cp -f /workflows/*.json /comfyui/user/default/workflows/
    touch /comfyui/user/default/workflows/.initialized
fi

# 4. Symlink shared models
for model_dir in /models/shared/*; do
    model_name=$(basename "$model_dir")
    ln -sf "$model_dir" "/comfyui/models/$model_name"
done

# 5. Start ComfyUI
exec python main.py --listen 0.0.0.0 --port 8188 --cpu
```

---

## 🏥 Health Check Pattern

### Docker Compose Health Check
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8188/"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 10s
```

### Batched Startup (Prevents Thundering Herd)
```yaml
# Batch leaders (parallel)
user001:
  depends_on:
    queue-manager: { condition: service_healthy }

user006:
  depends_on:
    queue-manager: { condition: service_healthy }

# Batch members (sequential)
user002:
  depends_on:
    user001: { condition: service_healthy }

user003:
  depends_on:
    user002: { condition: service_healthy }
```

**Result:** 20 containers start in ~2-3 minutes (not 20 seconds!)

---

## 📋 Workflow JSON Structure

### Minimal Workflow
```json
{
  "1": {
    "inputs": {
      "text": "positive prompt",
      "clip": ["4", 1]
    },
    "class_type": "CLIPTextEncode"
  },
  "4": {
    "inputs": {
      "ckpt_name": "flux2_klein_9b.safetensors"
    },
    "class_type": "CheckpointLoaderSimple"
  },
  "9": {
    "inputs": {
      "images": ["8", 0],
      "filename_prefix": "Flux2-Klein"
    },
    "class_type": "SaveImage"
  }
}
```

### Key Patterns
- **Node IDs:** String numbers ("1", "2", "9")
- **Links:** `["source_node_id", output_index]`
- **class_type:** Must match registered node class
- **filename_prefix:** Determines output filename

---

## 🔐 Security Patterns

### User Isolation (Filesystem)
```python
# ComfyUI validates paths within user directory
user_root = folder_paths.get_public_user_directory(user_id)
path = os.path.abspath(os.path.join(user_root, file))

# Prevent directory traversal
if os.path.commonpath((user_root, path)) != user_root:
    return web.Response(status=403)
```

### HTTP Basic Auth (Nginx)
```nginx
location /user001/ {
    auth_basic "User 001 Workspace";
    auth_basic_user_file /etc/nginx/comfyui-users.htpasswd;
    proxy_pass http://127.0.0.1:8188/;
}
```

---

## 🎨 Frontend Integration Patterns

### Workflow Load via JavaScript
```javascript
// List workflows
const response = await fetch('/api/userdata?dir=workflows');
const workflows = await response.json();
// → ["flux2_klein_9b_text_to_image.json", ...]

// Load specific workflow (URL-encode path!)
const workflowPath = 'workflows/flux2_klein_9b_text_to_image.json';
const encodedPath = workflowPath.replace(/\//g, '%2F');
const workflowResp = await fetch(`/api/userdata/${encodedPath}`);
const workflowData = await workflowResp.json();

// Load into app
if (window.app && window.app.loadGraphData) {
    await window.app.loadGraphData(workflowData);
}
```

### Save Workflow
```javascript
const workflowData = window.app.graph.serialize();
const filename = 'my_workflow.json';
const encodedPath = `workflows%2F${filename}`;

await fetch(`/api/userdata/${encodedPath}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(workflowData)
});
```

---

## 🔄 Migration-Friendly Architecture

### Keep ComfyUI Vanilla (Don't Modify Core)
```
/comfyui/                    ← Official ComfyUI (unmodified)
/comfyui/custom_nodes/       ← Our extensions ONLY
/comfyui/user/               ← User data (persistent volume)
```

**Benefit:** Easy to upgrade ComfyUI (just change git tag in Dockerfile)

### Separate User Data from App
```dockerfile
# Dockerfile (ComfyUI image)
WORKDIR /comfyui
RUN git clone --branch v0.9.2 https://github.com/comfyanonymous/ComfyUI.git .

# docker-compose.yml (User data volume)
volumes:
  - ./data/user_data/user001:/comfyui/user
```

**Benefit:** Upgrade app without losing user data

### Entrypoint Handles Initialization (Not Dockerfile)
```bash
# docker-entrypoint.sh (runs on every start)
cp -f /workflows/*.json /comfyui/user/default/workflows/
```

**Benefit:** Data refreshes on container restart (idempotent)

---

## 📊 Key Metrics

### Startup Times
- Single container: ~5-10s (CPU mode)
- 20 containers (batched): ~2-3min total
- Health check interval: 30s

### Storage
- ComfyUI image: ~500MB
- Models (shared): ~45GB
- User data (per user): ~10MB
- Workflows: ~70KB each

### Performance
- API latency: <50ms (local)
- Workflow load: <200ms (70KB JSON)
- Save workflow: <100ms

---

## ✅ Best Practices Summary

1. **Always URL-encode nested paths** in userdata API
2. **Use volume mounts** for user data (not COPY in Dockerfile)
3. **Symlink shared models** (read-only) to save space
4. **Entrypoint initializes** user directories (idempotent)
5. **Don't modify ComfyUI core** - use custom_nodes/
6. **Batched startup** prevents thundering herd
7. **Health checks** ensure reliable initialization
8. **CPU mode** for frontends, GPU mode for workers
9. **Queue manager** coordinates job distribution
10. **HTTP Basic Auth** per-user access control

---

## 🐛 Common Pitfalls

### ❌ Workflows not appearing in menu
**Cause:** Workflows not in `/comfyui/user/default/workflows/`
**Fix:** Check entrypoint copies workflows on startup

### ❌ 404 when loading workflow
**Cause:** Path not URL-encoded (`workflows/file.json` instead of `workflows%2Ffile.json`)
**Fix:** Use `encodeURIComponent()` in JavaScript or urllib.parse.quote() in Python

### ❌ Empty custom_nodes directory
**Cause:** Volume mount overwrites image contents
**Fix:** Entrypoint copies defaults if directory empty

### ❌ Models not found
**Cause:** Symlinks not created or wrong path
**Fix:** Check entrypoint symlinks `/models/shared/*` to `/comfyui/models/`

### ❌ Container unhealthy
**Cause:** ComfyUI not responding on port 8188
**Fix:** Check logs (`docker logs user001`), increase start_period

---

**End of Mini Guide**
