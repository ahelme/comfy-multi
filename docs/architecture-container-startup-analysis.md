**Project:** ComfyUI Multi-User Workshop Platform
**Doc Created:** 2026-01-30
**Doc Purpose:** Analysis of Container Startup Strategies for 20 User Containers

---

# Container Startup Strategy Analysis

## Problem Statement

We have **20 per-user frontend containers** that need to be started in **batches** (NOT all at once) to avoid:
- Resource exhaustion (CPU/memory spike)
- Race conditions during initialization
- Network saturation
- Docker daemon overload

---

## Option 1: Native Docker Compose with `depends_on` + Health Checks

### How It Works

Use Docker Compose's built-in `depends_on` with `service_healthy` condition to create dependency chains.

**Example:**
```yaml
services:
  user001:
    image: comfy-multi-frontend:latest
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8188/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  user002:
    image: comfy-multi-frontend:latest
    depends_on:
      user001:
        condition: service_healthy

  user003:
    depends_on:
      user002:
        condition: service_healthy

  # ... continue chain for user004-user020
```

### Pros ✅

- **Native Docker Compose solution** - No external scripts needed
- **Built-in health check support** - Modern best practice as of 2026
- **Declarative configuration** - All logic in docker-compose.yml
- **Automatic retry logic** - Health checks retry automatically
- **Clear dependency visualization** - Easy to see startup order
- **Docker Compose manages state** - Respects dependencies on restart

### Cons ❌

- **Linear dependency chain** - Only starts one at a time (slow for 20 containers)
- **Cannot do parallel batches** - Can't start 5 at once, then next 5
- **Verbose YAML** - Lots of repetitive depends_on declarations
- **Inflexible batching** - Cannot easily adjust batch size
- **All-or-nothing** - If one fails, entire chain blocked

### Performance

- **Startup Time:** ~10-15 minutes (sequential, 30s per container)
- **Resource Usage:** Low (only 1 starting at a time)
- **Complexity:** Medium (verbose YAML)

### Best For

- Services with strict ordering requirements
- Smaller deployments (5-10 containers)
- When you need guaranteed sequential startup

### Current Best Practice (2026)

✅ **Recommended over wrapper scripts** like `wait-for-it` according to:
- [Docker Compose Health Checks Guide](https://last9.io/blog/docker-compose-health-checks/)
- [Forget wait-for-it, use healthcheck](https://www.denhox.com/posts/forget-wait-for-it-use-docker-compose-healthcheck-and-depends-on-instead/)
- [Docker Official Docs: Control Startup Order](https://docs.docker.com/compose/how-tos/startup-order/)

---

## Option 2: Wrapper Script with Parallel Batches

### How It Works

Use `scripts/start.sh` to orchestrate batched startup with parallel execution within batches.

**Example:**
```bash
#!/bin/bash
# scripts/start.sh - Start containers in batches

set -e

# Start core infrastructure first
echo "Starting core services..."
docker compose up -d nginx redis queue-manager admin

# Wait for core services to be healthy
echo "Waiting for core services..."
./scripts/wait-for-healthy.sh nginx redis queue-manager admin

# Start user containers in batches of 5
BATCH_SIZE=5
for batch in {0..3}; do
    start=$((batch * BATCH_SIZE + 1))
    end=$((start + BATCH_SIZE - 1))

    users=""
    for i in $(seq $start $end); do
        users="$users user$(printf "%03d" $i)"
    done

    echo "Starting batch $((batch + 1)): users $start-$end"
    docker compose up -d $users

    echo "Waiting 15 seconds for batch to stabilize..."
    sleep 15
done

echo "All services started!"
```

### Pros ✅

- **Parallel batches** - Start 5 containers simultaneously, then next 5
- **Flexible batch size** - Easy to adjust (change BATCH_SIZE variable)
- **Fast startup** - ~5 minutes total (vs 15 minutes sequential)
- **Resource-aware** - Can tune batch size based on server capacity
- **Clear progress** - Script outputs batch progress
- **Error handling** - Can add custom retry logic
- **Independent batches** - One batch failure doesn't block others

### Cons ❌

- **External script dependency** - Logic outside docker-compose.yml
- **Manual orchestration** - Have to remember to use script
- **Less declarative** - Startup logic split between YAML and script
- **No Docker Compose awareness** - Docker doesn't know about batching
- **Maintenance overhead** - Script needs updating if user count changes

### Performance

- **Startup Time:** ~5 minutes (4 batches × 15s wait + 2min startup)
- **Resource Usage:** Medium (5 containers starting simultaneously)
- **Complexity:** Low (simple bash script)

### Best For

- **Large deployments with identical services** (perfect for 20 user containers)
- When you need control over batch size and timing
- When startup time matters
- Production environments where you start/stop frequently

---

## Option 3: Docker Compose Profiles (Batch by Profile)

### How It Works

Use Docker Compose profiles to group containers into batches.

**Example:**
```yaml
services:
  user001:
    profiles: ["batch1"]
    image: comfy-multi-frontend:latest

  user002:
    profiles: ["batch1"]
    image: comfy-multi-frontend:latest

  user006:
    profiles: ["batch2"]
    image: comfy-multi-frontend:latest
```

**Startup:**
```bash
docker compose --profile batch1 up -d  # Start first 5
sleep 15
docker compose --profile batch2 up -d  # Start next 5
```

### Pros ✅

- **Native Docker Compose feature** - No external scripts
- **Logical grouping** - Services grouped by profile
- **Selective startup** - Can start specific batches on demand
- **Clear in YAML** - Easy to see which batch each user belongs to

### Cons ❌

- **Still requires scripting** - Need script to iterate profiles
- **Verbose YAML** - Profile tag on every service
- **Not designed for this** - Profiles meant for env differences (dev/prod)
- **Manual batch assignment** - Have to maintain profile assignments

### Performance

- **Startup Time:** ~5 minutes (similar to wrapper script)
- **Resource Usage:** Medium
- **Complexity:** Medium (profiles + script)

### Best For

- Different environments (dev/test/prod)
- Optional services (monitoring, logging)
- NOT ideal for batching identical services

---

## Option 4: Docker Compose Scale (Single Service with Replicas)

### How It Works

Define one user service and scale it to 20 replicas.

**Example:**
```yaml
services:
  user-frontend:
    image: comfy-multi-frontend:latest
    deploy:
      replicas: 20
```

**Startup:**
```bash
docker compose up -d --scale user-frontend=20
```

### Pros ✅

- **Minimal YAML** - Only one service definition
- **Built-in scaling** - Docker Compose handles replication
- **Easy to adjust** - Change replica count on fly

### Cons ❌

- **❌ BREAKS OUR ARCHITECTURE** - Cannot have per-user custom nodes
- **❌ NO per-user volumes** - All replicas share same mounts
- **❌ NO per-user isolation** - Cannot identify which user is which
- **❌ NO custom naming** - Containers named `user-frontend-1`, not `comfy-user001`
- **❌ Port conflicts** - Cannot assign specific ports per user
- **❌ All or nothing** - Cannot start subsets of replicas

### Performance

- **Startup Time:** Unknown (likely all at once - BAD)
- **Resource Usage:** High (all 20 start simultaneously)
- **Complexity:** Low (but doesn't meet requirements)

### Best For

- **Stateless services** (load-balanced web servers, API workers)
- Services that DON'T need per-instance customization
- **NOT suitable for our use case**

---

## Recommendation: Option 2 (Wrapper Script with Parallel Batches)

### Why This Is Best for ComfyMulti

✅ **Matches requirements:**
- Starts in batches (5 at a time) - NOT all at once
- Maintains per-user isolation and custom volumes
- Fast startup (~5 minutes vs 15 minutes)
- Flexible batch size (easy to tune based on server performance)

✅ **Balances modern practices with pragmatism:**
- Uses Docker Compose for service definition (declarative)
- Uses shell script for orchestration (procedural)
- Both are industry-standard approaches

✅ **Production-ready:**
- Clear error messages and progress indicators
- Easy to debug (see which batch is starting)
- Can add health check waits between batches
- Works with CI/CD pipelines

### Implementation Plan

1. **Keep `docker-compose.users.yml` as-is**
   - Generated by `scripts/generate-user-compose.sh`
   - Defines all 20 user services with per-user volumes

2. **Update `scripts/start.sh`**
   - Add batched startup logic
   - Start core services first (nginx, redis, queue-manager)
   - Then start user containers in batches of 5
   - Wait 15-30 seconds between batches

3. **Add health check validation (optional)**
   - Create `scripts/wait-for-healthy.sh`
   - Checks container health before proceeding
   - Can poll health check endpoint or use `docker inspect`

4. **Update documentation**
   - CLAUDE.md: Reference start.sh for batched startup
   - README.md: Explain why we batch (resource management)
   - Admin guide: Document tuning batch size

---

## Sources

### Docker Compose Best Practices (2026)

- [Multi-container applications | Docker Docs](https://docs.docker.com/get-started/docker-concepts/running-containers/multi-container-applications/)
- [Docker Compose | Docker Docs](https://docs.docker.com/compose)
- [Use multiple Compose files | Docker Docs](https://docs.docker.com/compose/how-tos/multiple-compose-files/)

### Health Checks & Startup Order

- [Control startup order - Docker Compose](https://docs.docker.com/compose/how-tos/startup-order/)
- [Docker Compose Health Checks: An Easy-to-follow Guide | Last9](https://last9.io/blog/docker-compose-health-checks/)
- [Forget wait-for-it, use docker-compose healthcheck and depends_on instead](https://www.denhox.com/posts/forget-wait-for-it-use-docker-compose-healthcheck-and-depends-on-instead/)
- [GitHub - docker-compose-healthcheck examples](https://github.com/peter-evans/docker-compose-healthcheck)

### Scaling Docker Compose

- [Scaling Services with Docker Compose](https://codesignal.com/learn/courses/multi-container-orchestration-with-docker-compose/lessons/scaling-services-with-docker-compose)
- [How to scale Docker Containers with Docker-Compose](https://brianchristner.io/how-to-scale-a-docker-container-with-docker-compose/)
- [Running multiple instances of a service with Docker Compose](https://pspdfkit.com/blog/2018/how-to-use-docker-compose-to-run-multiple-instances-of-a-service-in-development/)

---

## Next Steps

1. ✅ Document decision in GitHub Issue #15
2. ⏳ Implement batched startup in `scripts/start.sh`
3. ⏳ Test with different batch sizes (3, 5, 10)
4. ⏳ Add health check validation between batches
5. ⏳ Update CLAUDE.md and README.md with batching rationale
6. ⏳ Document batch size tuning guidelines (based on server specs)
