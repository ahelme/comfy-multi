**Doc Title:** Serverless GPU Research
**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-14
**Doc Updated:** 2026-01-14

---

# Serverless GPU Research (Phase 10)

Comparison of serverless GPU providers for ComfyUI video generation workshop.

---

## Requirements

- **GPU:** H100 80GB preferred (LTX-2 19B model needs ~40GB VRAM)
- **Users:** 20 professional filmmakers
- **Concurrency:** 10-15 simultaneous inference requests expected
- **Use case:** Bursty inference (everyone generates after demos/instructions)
- **Inference time:** 1-5 minutes per video generation
- **Cold start:** Acceptable up to 30-60 seconds for first request
- **Storage:** Need to mount model files (~45GB)

---

## Why Serverless Matters (Beyond Cost)

| Single H100 Instance | Serverless Containers |
|----------------------|----------------------|
| 1 job at a time | 10-15 concurrent jobs |
| Queue backlog during bursts | Parallel processing |
| Paying during breaks/lunch | Scale to zero |
| Frustrated filmmakers waiting | Everyone generating together |
| Fixed capacity | Auto-scale to demand |

**Critical insight:** After a demo, 15 filmmakers will all hit "generate" at once.

- **Single H100:** 15-job queue = 15-75 minute wait for the last person
- **Serverless:** Everyone gets results in ~5 minutes (parallel)

---

## Provider Comparison

### Verda Containers (Recommended)

| Feature | Details |
|---------|---------|
| **Billing** | 10-minute intervals |
| **H100 SXM5 80GB** | ~$2.29/hr on-demand, ~$1.15/hr spot (50% off) |
| **Cold Start** | ~10-20 seconds typical (can optimize) |
| **Storage** | Shared with GPU instances (SFS + Block) |
| **Scale to Zero** | Yes |
| **Autoscaling** | Queue-based with adjustable sensitivity |
| **Max Scale** | "Hundreds of GPUs" supported |
| **Multi-GPU** | 1x, 2x, 4x configurations |

**Available GPUs:**
- H100 SXM5 80GB (21 CPU, 175GB RAM)
- H200 SXM5 141GB
- A100 SXM4 80GB/40GB
- L40S 48GB
- RTX 6000 Ada 48GB

**Pros:**
- Already using Verda, familiar platform
- Shared storage with instances (models already there)
- EU data protection (GDPR) + 100% renewable energy
- Queue-based autoscaling perfect for workshop bursts
- Prometheus/Loki metrics for monitoring
- Python SDK + REST API

**Cons:**
- 10-minute billing granularity
- Need to build/test container deployment
- Cold start needs testing/optimization

**Best for:** Your workshop - EU compliance, green energy, shared storage

---

### RunPod Serverless

| Feature | Details |
|---------|---------|
| **Billing** | Per-second (rounded up) |
| **H100 SXM Price** | $2.69/hr |
| **H100 PCIe Price** | $2.39/hr |
| **Cold Start** | ~10-30 seconds (Flex workers) |
| **Storage** | Network volumes, $0.10/GB/month |
| **Scale to Zero** | Yes (Flex workers) |
| **Data Transfer** | Free ingress/egress |

**Pros:**
- Per-second billing (great for variable workloads)
- Competitive H100 pricing
- Free data transfer
- Good documentation for custom containers

**Cons:**
- Need to build/deploy custom container
- Different platform from current setup

**Best for:** Variable workloads with bursty usage

---

### Modal

| Feature | Details |
|---------|---------|
| **Billing** | Per-second |
| **H100 Price** | ~$3.95-4.76/hr |
| **A100 80GB Price** | ~$3.72/hr |
| **Cold Start** | Sub-second (Rust-based) |
| **Storage** | Modal volumes |
| **Scale to Zero** | Yes |

**Pros:**
- Fastest cold starts (sub-second)
- Excellent developer experience (Python decorators)
- Scales to thousands of GPUs instantly

**Cons:**
- Higher pricing than RunPod/Verda
- Python-native (may need wrapper for ComfyUI)
- Vendor lock-in

**Best for:** Developer experience, fast iteration

---

### Replicate

| Feature | Details |
|---------|---------|
| **Billing** | Per-second + boot time |
| **Pricing** | Model-specific (20-30% markup) |
| **Cold Start** | Varies by model |
| **Storage** | Managed by Replicate |

**Pros:**
- Easiest to get started (pre-built models)
- No infrastructure management

**Cons:**
- 20-30% markup over raw compute
- Less control over custom workflows
- Expensive at scale

**Best for:** Quick prototyping, not production

---

## Price Comparison (H100 80GB)

| Provider | Per-Hour | Per-Minute | Billing Granularity |
|----------|----------|------------|---------------------|
| **Verda Containers** | $2.29 | $0.038 | 10-minute |
| **Verda Instance** | $2.29 | $0.038 | Per-minute |
| **RunPod Serverless** | $2.39-2.69 | $0.040-0.045 | Per-second |
| **Modal** | $3.95-4.76 | $0.066-0.079 | Per-second |

---

## Workshop Cost Estimate

**Assumptions:**
- 8-hour workshop
- 20 filmmakers
- ~5 generation rounds per person
- 3-5 minute inference per video
- Peak: 15 concurrent requests after demos

### Scenario A: Single H100 Instance

| Metric | Value |
|--------|-------|
| Cost | $2.29 × 8 = **$18.32** |
| Throughput | 1 job at a time |
| Wait time (15 jobs queued) | 45-75 minutes for last person |
| User experience | Frustrating during bursts |

### Scenario B: Verda Serverless (Recommended)

| Metric | Value |
|--------|-------|
| Base cost | $2.29/hr per active container |
| Peak replicas | 10-15 containers during bursts |
| Idle periods | Scale to zero (lunch, explanations) |
| Wait time | ~5 min (everyone parallel) |
| User experience | Excellent |

**Estimated cost breakdown:**
- 4 demo rounds × 15 containers × 10 min = 600 container-minutes = **$22.90**
- Individual work (spread out) × ~3 containers × 2 hrs = **$13.74**
- **Total estimate: ~$35-50** (vs $18 for frustrated users)

**Value:** Happy filmmakers > slightly lower cost

---

## Recommendation

### Primary: Verda Containers (Serverless)

**Why:**
- **Concurrency:** Handle 10-15 simultaneous requests
- **User experience:** No one waits 45+ minutes
- **EU compliance:** GDPR, data stays in EU
- **Green energy:** 100% renewable (good for filmmaker values)
- **Shared storage:** Models already on Verda block storage
- **Familiar platform:** Already using Verda

**Trade-offs:**
- Higher cost (~$35-50 vs $18)
- Need to test container deployment
- 10-minute billing granularity

### Fallback: Single H100 Instance
**Only if:**
- Container deployment fails
- Budget absolutely critical
- Accept queue delays during bursts

---

## Next Steps (Phase 11-12)

### Phase 11: Container Development
1. [ ] Build ComfyUI Docker container for Verda
2. [ ] Configure model loading from shared storage
3. [ ] Test cold start times
4. [ ] Optimize startup (consider memory snapshots)

### Phase 12: Integration & Testing
1. [ ] Deploy container to Verda Containers
2. [ ] Configure autoscaling (queue-based)
3. [ ] Test with 10-15 concurrent requests
4. [ ] Integrate with queue-manager API
5. [ ] Load test before workshop

### Cold Start Optimization Research
From Modal's ComfyUI experience:
- Baseline cold start: 10-20 seconds
- With memory snapshots: <3 seconds
- Key factors: Python deps (~1s), PyTorch/CUDA init (~7s), custom nodes (~2-5s)
- Consider: Warm pool of 2-3 replicas during workshop

---

## Sources

- [Verda Containers Overview](https://docs.verda.com/containers/overview)
- [Verda Serverless Containers](https://verda.com/serverless-containers)
- [Verda Products & Pricing](https://verda.com/products)
- [RunPod Serverless Pricing](https://docs.runpod.io/serverless/pricing)
- [RunPod GPU Pricing](https://www.runpod.io/pricing)
- [Modal Pricing](https://modal.com/pricing)
- [Modal: Scaling ComfyUI](https://modal.com/blog/scaling-comfyui)
- [Modal: Cold Start ComfyUI <3 seconds](https://modal.com/blog/comfyui-mem-snapshots)
- [Top Serverless GPU Clouds 2026](https://www.runpod.io/articles/guides/top-serverless-gpu-clouds)
- [Serverless GPU Platforms Comparison](https://introl.com/blog/serverless-gpu-platforms-runpod-modal-beam-comparison-guide-2025)
