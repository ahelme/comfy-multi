# Verda Restore Scripts

Quick reference for which restore script to use.

## Available Scripts

| Script | Purpose | When to Use |
|--------|---------|-------------|
| RESTORE-SFS.sh | Populate SFS with models + container | Fresh SFS, models missing |
| RESTORE-BLOCK-MELLO.sh | Full system restore from mello backups | Need Tailscale/security/user config |

## Scenarios

### A: Daily Startup (most common)
SFS already has models + container
```
bash /root/quick-start.sh <sfs-endpoint>
```

### B: Fresh SFS Setup (Jan 31 / first time)
Empty SFS, need models from R2
```
bash /root/quick-start.sh <sfs-endpoint>
bash /root/RESTORE-SFS.sh --full
```

### C: New Instance, Existing SFS
Need Tailscale + security configs
```
scp -r dev@comfy.ahelme.net:~/backups/verda/ ~/
cd ~/verda && bash RESTORE-BLOCK-MELLO.sh
bash /root/quick-start.sh <sfs-endpoint>
```

## RESTORE-SFS.sh Options

```
--with-models      Download models from R2 (~45GB, ~30 min)
--with-container   Copy container from mello (~2.6GB)
--full             Both (recommended for fresh SFS)
```

## Quick Reference

| Need | Script | Time |
|------|--------|------|
| Mount SFS + start worker | quick-start.sh | ~30 sec |
| Download models from R2 | RESTORE-SFS.sh --with-models | ~30 min |
| Copy container from mello | RESTORE-SFS.sh --with-container | ~2 min |
| Full system restore | RESTORE-BLOCK-MELLO.sh | ~5 min |

## R2 Model Storage

Models are backed up to Cloudflare R2:

| Location | Contents |
|----------|----------|
| Bucket | comfy-multi-model-vault-backup |
| Endpoint | https://f1d627b48ef7a4f687d6ac469c8f1dea.r2.cloudflarestorage.com |
| Region | Oceania (OC) |

Contents:
- checkpoints/ltx-2-19b-dev-fp8.safetensors (~27GB)
- text_encoders/gemma_3_12B_it.safetensors (~20GB)
- worker-image.tar.gz (~2.7GB)

View in Cloudflare Dashboard:
  R2 -> comfy-multi-model-vault-backup -> Objects
