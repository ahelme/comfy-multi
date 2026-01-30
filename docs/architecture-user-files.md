**Project:** ComfyUI Multi-User Workshop Platform
**Doc Created:** 2026-01-30
**Doc Purpose:** User Files Architecture & Storage Strategy

---

# User Files & Configuration Architecture

## Overview

This document defines where user files and configurations are stored in our split architecture (mello VPS + Verda GPU).

---

## User File Types

### 1. User Settings & Database (SMALL - Keep on Mello)

| File/Directory | Location | Size | Persistence | Backed Up |
|----------------|----------|------|-------------|-----------|
| `comfyui.db` | `/comfyui/user/` | ~140KB | Persistent | ✅ R2 |
| User preferences | `/comfyui/user/default/` | Small | Persistent | ✅ R2 |
| Workflow history | In comfyui.db | Small | Persistent | ✅ R2 |

**Storage:** `data/user_data/userXXX/` on mello
**Mounted to:** `/comfyui/user` in container
**Rationale:** Small files, permanent, need to persist between sessions

---

### 2. User Custom Workflows (SMALL - Keep on Mello)

| File/Directory | Location | Size | Persistence | Backed Up |
|----------------|----------|------|-------------|-----------|
| Saved workflows | `/comfyui/user/` | Small (JSON) | Persistent | ✅ R2 |
| Modified workflows | `/comfyui/user/` | Small (JSON) | Persistent | ✅ R2 |

**Storage:** `data/user_data/userXXX/` on mello
**Mounted to:** `/comfyui/user` in container
**Rationale:** Small JSON files, need to persist permanently

---

### 3. User Custom Nodes (MEDIUM - Keep on Mello)

| File/Directory | Location | Size | Persistence | Backed Up |
|----------------|----------|------|-------------|-----------|
| Custom node code | `/comfyui/custom_nodes/` | Varies | Persistent | ✅ R2 |
| Node dependencies | Python packages | Varies | Persistent | ✅ R2 |

**Storage:** `data/user_data/userXXX/comfyui/custom_nodes/` on mello
**Mounted to:** `/comfyui/custom_nodes/` in container (per-user mount)
**Rationale:**
- Users can install custom ComfyUI extensions themselves
- Each user has their own isolated custom_nodes directory
- Persistent across container restarts and image rebuilds
- Backed up to R2 for recovery

**Build Strategy:** Per-user Docker images built via `docker-compose.users.yml`
- Each user has own image: `comfyui-user001:latest` through `comfyui-user020:latest`
- Custom nodes volume-mounted from mello (not baked into image)
- Users can install nodes directly in their running container

---

### 4. User Uploads (LARGE - Ephemeral on Verda)

| File/Directory | Location | Size | Persistence | Backed Up |
|----------------|----------|------|-------------|-----------|
| Input images | `/comfyui/input/userXXX/` | Large | Ephemeral | ❌ No |
| Reference videos | `/comfyui/input/userXXX/` | Very Large | Ephemeral | ❌ No |
| Audio files | `/comfyui/input/userXXX/` | Medium | Ephemeral | ❌ No |

**Storage:** Verda block storage (`/mnt/scratch/inputs/`)
**Mounted to:** `/comfyui/input/` via symlink in container
**Rationale:**
- Large files don't need long-term persistence
- Ephemeral - deleted when Verda instance terminated
- Users re-upload each workshop day (cost optimization)
- No backup to R2 (saves bandwidth and storage costs)

**Architecture:**
- Block storage attached to Verda GPU instance only
- Mello frontends access via network (or users upload directly to running instance)
- Deleted when block storage volume deleted

---

### 5. User Outputs (LARGE - Ephemeral on Verda)

| File/Directory | Location | Size | Persistence | Backed Up |
|----------------|----------|------|-------------|-----------|
| Generated videos | `/comfyui/output/userXXX/` | Very Large | Ephemeral | ❌ No |
| Generated images | `/comfyui/output/userXXX/` | Large | Ephemeral | ❌ No |
| Intermediate files | `/comfyui/output/userXXX/` | Large | Ephemeral | ❌ No |

**Storage:** Verda block storage (`/mnt/scratch/outputs/`)
**Mounted to:** `/comfyui/output/` via symlink in container
**Rationale:**
- Very large files (videos especially)
- Ephemeral - workshop duration only
- Users download their outputs during workshop
- Deleted when Verda instance terminated
- No backup to R2 (massive bandwidth/storage savings)

**Architecture:**
- Block storage attached to Verda GPU instance only
- Users download via frontend during workshop
- Deleted when block storage volume deleted

---

### 6. Shared Template Workflows (SMALL - Keep on Mello)

| File/Directory | Location | Size | Persistence | Backed Up |
|----------------|----------|------|-------------|-----------|
| LTX-2 workflows | `/workflows/` | ~100KB each | Permanent | ✅ Git |
| Flux2 Klein workflows | `/workflows/` | ~70KB each | Permanent | ✅ Git |
| Example workflows | `/workflows/` | Small | Permanent | ✅ Git |

**Storage:** `data/workflows/` on mello
**Mounted to:** `/workflows:ro` (read-only) in all containers
**Rationale:** Instructor-provided templates, version-controlled, shared across all users

---

## Storage Decisions Summary

### On Mello (Persistent, Backed Up to R2)
- ✅ User settings & database (`data/user_data/userXXX/comfyui.db`)
- ✅ User custom workflows (`data/user_data/userXXX/`)
- ✅ User custom nodes (`data/user_data/userXXX/comfyui/custom_nodes/`)
- ✅ Shared template workflows (`data/workflows/`)

### On Verda Block Storage (Ephemeral, NOT Backed Up)
- ✅ User uploads (`/mnt/scratch/inputs/userXXX/`)
- ✅ User outputs (`/mnt/scratch/outputs/userXXX/`)

### In Per-User Docker Images
- ✅ Base ComfyUI v0.9.2 installation
- ✅ Python dependencies from requirements.txt
- ✅ System-level packages
- ❌ NOT custom nodes (volume-mounted from mello instead)

---

## Per-User Docker Image Build Strategy

**Generated File:** `docker-compose.users.yml`
- Auto-generated by `scripts/generate-user-compose.sh`
- Creates 20 separate services: `user001` through `user020`
- Each builds from same Dockerfile: `comfyui-frontend/Dockerfile`
- Each creates separate image: `comfyui-user001:latest` through `comfyui-user020:latest`

**Purpose:**
- Allow per-user isolation (separate containers, resource limits)
- Enable user-specific custom node installation
- Each user has independent ComfyUI instance

**Volume Mounts (per user):**
```yaml
volumes:
  - ${OUTPUTS_PATH}:/outputs                              # Verda block storage (ephemeral)
  - ${INPUTS_PATH}:/inputs                                # Verda block storage (ephemeral)
  - ${WORKFLOWS_PATH}:/workflows:ro                       # Shared templates (read-only)
  - ${MODELS_PATH}:/models:ro                             # Shared models (read-only)
  - ./data/user_data/user001:/comfyui/user                # User settings (persistent)
  - ./data/user_data/user001/comfyui/custom_nodes:/comfyui/custom_nodes  # User custom nodes (persistent)
```

**Custom Node Installation:**
1. Users can install custom nodes via ComfyUI Manager (web UI)
2. Custom nodes install to `/comfyui/custom_nodes/` (volume-mounted from mello)
3. Python dependencies install to container (may require container restart)
4. Custom nodes persist across container restarts (stored on mello)

**Image Rebuild Process:**
```bash
# Rebuild all user images (do in batches to avoid overwhelming system)
docker compose -f docker-compose.yml -f docker-compose.users.yml build

# Rebuild specific user
docker compose -f docker-compose.yml -f docker-compose.users.yml build user001

# Recreate containers with new image (IN BATCHES!)
docker compose -f docker-compose.yml -f docker-compose.users.yml up -d --force-recreate user001 user002 user003 user004 user005
docker compose -f docker-compose.yml -f docker-compose.users.yml up -d --force-recreate user006 user007 user008 user009 user010
# ... continue in batches of 5
```

**⚠️ IMPORTANT: Build and Start in Batches**
- **DO NOT** start all 20 containers at once
- Start in batches of 5 users at a time
- Prevents resource exhaustion and race conditions
- Allows health checks to complete before starting next batch
- Example: user001-005, then user006-010, then user011-015, then user016-020

---

## Implementation Details

### 1. Custom Nodes Volume Mount

**Current Issue:** Custom nodes are NOT being volume-mounted per-user yet.

**Required Changes:**

1. **Update `scripts/generate-user-compose.sh`:**
   Add per-user custom_nodes mount:
   ```yaml
   - ./data/user_data/user001/comfyui/custom_nodes:/comfyui/custom_nodes
   ```

2. **Update `backup-mello.sh` (private repo):**
   Add custom nodes to backup script to ensure they're backed up to R2:
   ```bash
   # Back up user custom nodes
   for user in user001 user002 ... user020; do
     aws s3 sync data/user_data/$user/comfyui/custom_nodes/ \
       s3://comfy-multi-user-files/user_data/$user/comfyui/custom_nodes/
   done
   ```

**Directory Structure:**
```
data/user_data/user001/
├── comfyui.db                          # ComfyUI database
├── default/                            # User preferences
└── comfyui/
    └── custom_nodes/                   # User custom nodes (NEW)
        ├── ComfyUI-Manager/            # Example: ComfyUI Manager
        └── my-custom-node/             # Example: User's custom node
```

### 2. Verda Block Storage Symlinks

**Implementation:** Handled by `setup-verda-solo-script.sh` during provisioning.

**How it works:**
1. Block storage attached to Verda GPU instance: `/mnt/scratch/`
2. Setup script creates symlinks on Verda:
   - `/mnt/scratch/inputs/` → `/comfyui/input/`
   - `/mnt/scratch/outputs/` → `/comfyui/output/`
3. Worker containers on Verda access via symlinks
4. When instance deleted, block storage (and all inputs/outputs) deleted

**Architecture:**
- Frontends on mello queue jobs with workflow data
- Workers on Verda process jobs, read inputs, write outputs to block storage
- Users download outputs via frontend during workshop
- No network mount needed from mello to Verda (handled via job queue)

### 3. Storage Quotas

**Future Enhancement:**
- Set per-user disk quotas for mello storage
- Monitor block storage usage on Verda
- Alert users when approaching limits

---

## Next Steps

1. Update GitHub Issue #15 with this architecture
2. Document per-user image build process
3. Decide on user uploads (ephemeral vs persistent)
4. Test default workflow loading with current architecture
5. Document custom node installation workflow for users
