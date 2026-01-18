**Doc Title:** Admin Guide - Backup Routines
**Project:** ComfyUI Multi-User Workshop Platform
**Doc Created:** 2026-01-18
**Doc Updated:** 2026-01-18

---

# Backup Routines

Three backup routines protect data. For full details, see [admin-backup-restore.md](./admin-backup-restore.md).

---

## Quick Reference: End of Workshop Day

**Run from Mello VPS** before shutting down Verda:

```bash
cd ~/projects/comfymulti-scripts

# Step 1: Backup Verda → Mello + R2
./backup-verda.sh

# Step 2: Backup Mello user files → R2
./backup-mello.sh
```

---

## A. Manual: Before Verda Shutdown

**When:** Before deleting Verda instance or SFS (end of workshop day)
**Run from:** Mello VPS

### Step 1: Backup Verda → Mello + R2

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

### Step 2: Backup Mello User Files → R2

**Script:** `backup-mello.sh`

```bash
cd ~/projects/comfymulti-scripts
./backup-mello.sh           # Full backup (default)
./backup-mello.sh --quick   # Skip outputs (user_data + inputs only)
```

| Data | Destination | Notes |
|------|-------------|-------|
| User workflows | R2 | `user_data/userXXX/` |
| User settings | R2 | `user_data/userXXX/` |
| User outputs | R2 | `outputs/userXXX/` (checksum skip if unchanged) |
| User inputs | R2 | `inputs/` |

---

## B. Automatic: Cron Job (Hourly)

**When:** Every hour while Verda is running
**Run from:** Verda instance
**Script:** `backup-cron.sh` (installed by RESTORE-SFS.sh)

```bash
# Cron entry (installed automatically)
0 * * * * /usr/local/bin/backup-cron.sh
```

| Data | Destination | Notes |
|------|-------------|-------|
| Tailscale identity | SFS | /mnt/sfs/cache/backups/ |
| SSH host keys | SFS | |
| Fail2ban, UFW configs | SFS | |
| Project .env | SFS | |
| *Triggers* `backup-mello.sh` | R2 | Via SSH to mello |

---

## What's NOT Backed Up

| Data | Reason |
|------|--------|
| Models on Verda | Already in R2 (restored from there) |
| Block storage (`/mnt/scratch`) | Ephemeral scratch disk for temp files/outputs |

---

## Quick Reference

| Script | Location | Trigger | Backs Up |
|--------|----------|---------|----------|
| `backup-verda.sh` | Mello: `~/projects/comfymulti-scripts/` | Manual | Verda → Mello + R2 |
| `backup-mello.sh` | Mello: `~/projects/comfymulti-scripts/` | Manual/Cron | Mello → R2 |
| `backup-cron.sh` | Verda: `/usr/local/bin/` | Cron (hourly) | Verda → SFS + triggers mello |

For restore procedures, see [admin-backup-restore.md](./admin-backup-restore.md).
