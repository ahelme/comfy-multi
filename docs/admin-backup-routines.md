**Doc Title:** Admin Guide - Backup Routines
**Project:** ComfyUI Multi-User Workshop Platform
**Doc Created:** 2026-01-18
**Doc Updated:** 2026-01-18

---

# Backup Routines

Two backup routines protect Verda data. For full details, see [admin-backup-restore.md](./admin-backup-restore.md).

---

## A. Manual: Before Verda Shutdown

**When:** Before deleting Verda instance or SFS
**Run from:** Mello VPS
**Script:** `backup-verda.sh`

```bash
cd ~/projects/comfymulti-scripts
./backup-verda.sh           # Full backup (default)
./backup-verda.sh --quick   # Skip models/container (config only)
```

| Data | Destination | Notes |
|------|-------------|-------|
| Tailscale identity | Mello | Preserves IP 100.89.38.43 |
| SSH host keys | Mello | |
| Fail2ban, UFW configs | Mello | |
| Project .env | Mello | |
| /home/dev/ | Mello | Excludes .cache |
| ComfyUI project | Mello | |
| oh-my-zsh custom | Mello | |
| Container image | Mello + R2 | ~2.5GB |
| Models (.safetensors) | R2 | ~45GB (checksum skip if unchanged) |

---

## B. Automatic: Cron Job (Hourly)

**When:** Every hour while Verda is running
**Run from:** Verda instance
**Script:** `backup-local.sh` (installed by RESTORE-SFS.sh)

```bash
# Cron entry (installed automatically)
0 * * * * /usr/local/bin/backup-local.sh
```

| Data | Destination | Notes |
|------|-------------|-------|
| Tailscale identity | SFS | /mnt/sfs/cache/backups/ |
| SSH host keys | SFS | |
| Fail2ban, UFW configs | SFS | |
| Project .env | SFS | |

---

## What's NOT Backed Up

| Data | Reason | Issue |
|------|--------|-------|
| User workflows | Pending implementation | [#4](https://github.com/ahelme/comfymulti-scripts/issues/4) |
| User outputs | Ephemeral (scratch disk) | By design |

---

## Quick Reference

| Script | Location | Trigger |
|--------|----------|---------|
| `backup-verda.sh` | Mello: `~/projects/comfymulti-scripts/` | Manual |
| `backup-local.sh` | Verda: `/usr/local/bin/` | Cron (hourly) |

For restore procedures, see [admin-backup-restore.md](./admin-backup-restore.md).
