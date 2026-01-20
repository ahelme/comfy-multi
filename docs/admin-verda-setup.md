**Doc Title:** Verda Setup - Comfy Multi Workshop
**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-12
**Doc Updated:** 2026-01-15

---

# Verda GPU Setup

Quick reference for Verda infrastructure configuration.

---

## Storage Strategy

**Recommended:** SFS (Shared File System) for models + container

See [Admin Backup & Restore](./admin-backup-restore.md) for full storage strategy and costs.

**Key point:** SFS has no wipe-on-provision risk (unlike Block Storage)

---

## Quick Start (Daily GPU Instance)

**See [Admin Backup & Restore](./admin-backup-restore.md)** for complete provisioning and restore procedures.

Summary: Paste `quick-start.sh` into Verda startup script, SSH in, get MOUNT COMMAND from Verda Dashboard (Storage → SFS dropdown), run `bash /root/quick-start.sh "<MOUNT_COMMAND>"`.

---

## Verda Gotchas

### Block Storage Gets WIPED on Provisioning

**Critical:** If you attach block storage during instance creation, Verda WIPES it!

**Safe workflow (if using block storage):**
1. Create instance WITHOUT block storage
2. Boot the instance
3. Shut down instance (required for attachment)
4. Attach block storage via Verda Dashboard
5. Boot instance again
6. Mount: `mount /dev/vdc /mnt/models`

**Volume naming:**
- `OS-*` = OS disks (will have Ubuntu)
- `Volume-*` = Data volumes (your block storage)

### Other Notes

- Verda images have Docker pre-installed (don't install docker.io - conflicts)
- Ubuntu 24.04 uses `ssh` service name, not `sshd`
- Spot instances can be terminated anytime - use persistent storage (SFS)

---

## SFS Mount Instructions

```bash
# Install NFS client if needed
apt-get update && apt-get install -y nfs-common

# Mount SFS
mkdir -p /mnt/models
mount -t nfs <sfs-endpoint>:/share /mnt/models

# Add to fstab for persistence
echo "<sfs-endpoint>:/share /mnt/models nfs defaults 0 0" >> /etc/fstab
```

---

## GPU Options

| GPU | VRAM | Rate | Best For |
|-----|------|------|----------|
| **V100 16GB** | 16GB | ~$0.14/hr | Testing, validation |
| **A100 80GB** | 80GB | ~$0.39/hr | Development |
| **H100 80GB** | 80GB | ~$2.29/hr | Workshop production |

**Tip:** Test on V100 first ($0.14/hr), then use H100 for workshop.

---

## Workshop Cost Estimate

| Period | Compute | Storage | Total |
|--------|---------|---------|-------|
| **Setup (1 day)** | ~$2 (V100 spot) | $0.50 | ~$3 |
| **Workshop month** | Variable | ~$14 (SFS) + $1 (R2) | $15 + compute |
| **Off-season** | $0 | $1 (R2 only) | $1/month |

---

## Related Docs

- [Workshop Workflow](./admin-workflow-workshop.md) - Daily startup procedures
- [Backup & Restore](./admin-backup-restore.md) - Backup procedures
- [Budget Strategy](./admin-budget-strategy.md) - Cost optimization
- [Serverless Research](./research-serverless-gpu.md) - Container scaling options

---

**Last Updated:** 2026-01-15
