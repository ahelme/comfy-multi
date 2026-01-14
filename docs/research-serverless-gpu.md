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
- **Use case:** Bursty inference (20 users, ~8 hour workshop)
- **Inference time:** 1-5 minutes per video generation
- **Cold start:** Acceptable up to 30-60 seconds
- **Storage:** Need to mount model files (~45GB)

---

## Provider Comparison

### Verda Containers

| Feature | Details |
|---------|---------|
| **Billing** | 10-minute intervals |
| **H100 Price** | ~$2.29/hr (same as instances) |
| **Cold Start** | Not specified |
| **Storage** | SFS + Block volumes mountable |
| **Scale to Zero** | Yes |
| **Autoscaling** | Manual + queue-based |

**Pros:**
- Already using Verda, familiar platform
- Can share storage (SFS/Block) with containers
- Same models, same setup

**Cons:**
- 10-minute billing granularity (not ideal for short jobs)
- Limited cold start documentation

**Best for:** Long inference jobs (>3 min recommended)

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

Assuming 8-hour workshop, 20 users, average 3-minute inference per job:

### Scenario: Steady Usage (Instance)

| Provider | Cost |
|----------|------|
| Verda H100 Instance | $2.29 × 8 = **$18.32** |
| RunPod H100 Instance | $2.69 × 8 = **$21.52** |

### Scenario: Bursty Usage (Serverless)

Assuming 50% actual GPU utilization over 8 hours:

| Provider | Cost |
|----------|------|
| Verda Containers | $2.29 × 4 = **$9.16** |
| RunPod Serverless | $2.69 × 4 = **$10.76** |
| Modal | $4.76 × 4 = **$19.04** |

---

## Recommendation

### For Workshop (Simple)
**Verda H100 Instance** - $18.32 for 8 hours
- Already configured and tested
- No cold start concerns
- Models already in place
- Predictable cost

### For Future (Cost Optimization)
**Verda Containers** or **RunPod Serverless**
- Scale to zero when not in use
- Good for ongoing/recurring workshops
- Requires container setup and testing

---

## Next Steps

1. [ ] Test Verda Containers with ComfyUI
2. [ ] Measure actual cold start times
3. [ ] Build custom container if needed
4. [ ] Compare real-world costs

---

## Sources

- [Verda Containers Overview](https://docs.verda.com/containers/overview)
- [Verda Products & Pricing](https://verda.com/products)
- [RunPod Serverless Pricing](https://docs.runpod.io/serverless/pricing)
- [RunPod GPU Pricing](https://www.runpod.io/pricing)
- [Modal Pricing](https://modal.com/pricing)
- [Top Serverless GPU Clouds 2026](https://www.runpod.io/articles/guides/top-serverless-gpu-clouds)
- [Serverless GPU Platforms Comparison](https://introl.com/blog/serverless-gpu-platforms-runpod-modal-beam-comparison-guide-2025)
