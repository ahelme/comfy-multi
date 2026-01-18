**Doc Title:** Script Audit - Potential Issues
**Project:** ComfyUI Multi-User Workshop Platform
**Doc Created:** 2026-01-18
**Scripts Audited:** quick-start.sh, RESTORE-SFS.sh

---

# Script Audit - Potential Failure Points

Logical walkthrough of restore scripts to identify potential failure points.

---

## quick-start.sh Issues

### HIGH Priority

| Line | Issue | Risk | Recommendation |
|------|-------|------|----------------|
| 32-40 | **Hardcoded credentials** (GitHub PAT, R2 keys) | PAT expires = script fails | Document PAT expiry date; add reminder to CLAUDE.md |
| 332 | **Config extraction check** uses `/root/tailscale-ip.txt` | File might not exist in all backups | Use different indicator or check multiple files |
| 372 | **RESTORE-SFS.sh runs without flags** | User might expect --full behavior | Consider passing quick-start flags through |

### MEDIUM Priority

| Line | Issue | Risk | Recommendation |
|------|-------|------|----------------|
| 88 | **Glob pattern** `/mnt/SFS-*` in for loop | Might not expand as expected | Test on fresh instance |
| 299 | **Script validation** checks for `#!/bin/bash` | Would reject sh/zsh scripts | Currently fine (all scripts are bash) |
| 348-366 | **Background download** with `&` | Script could exit before download completes | Already handled with wait, but document |

### LOW Priority

| Line | Issue | Risk | Recommendation |
|------|-------|------|----------------|
| 197-198 | **AWS CLI install uses /tmp** | Could fail if /tmp is full | Low risk on fresh instances |
| 154 | **Hardcoded mello SSH key** | Key change requires script update | Add key to CLAUDE.md for reference |

---

## RESTORE-SFS.sh Issues

### HIGH Priority

| Line | Issue | Risk | Recommendation |
|------|-------|------|----------------|
| 188 | **`systemctl restart sshd`** | Ubuntu 24.04 uses `ssh` not `sshd`! | **FIX: Change to `ssh`** |
| 123 | **`apt-get install docker.io`** | Conflicts with Verda's containerd | Already has check at line 122 - verify it works |
| 30-33, 369-371, 425-427 | **Credential duplication** | Credentials in 3 places = maintenance burden | Consider sourcing from single file |

### MEDIUM Priority

| Line | Issue | Risk | Recommendation |
|------|-------|------|----------------|
| 97 | **Backup date detection** `home-dev-*.tar.gz` | Fragile if naming changes | Document backup naming convention |
| 231 | **`ufw --force reset`** | Wipes ALL existing rules | Intentional but aggressive; document |
| 24 | **Hardcoded `EXPECTED_TAILSCALE_IP`** | If IP changes, script fails | Document in CLAUDE.md |

### LOW Priority

| Line | Issue | Risk | Recommendation |
|------|-------|------|----------------|
| 20 | **`set -e`** exits on any error | Could leave system in partial state | Acceptable trade-off for visibility |
| 278 | **oh-my-zsh install** needs network | Could fail if GitHub is down | Low risk; oh-my-zsh is optional |

---

## Cross-Script Issues

| Issue | Risk | Recommendation |
|-------|------|----------------|
| **Credential duplication** | AWS keys in both scripts | Consider env file or secrets manager |
| **No backup validation** | Corrupted tarballs cause silent failures | Add checksum verification (low priority) |
| **No rollback mechanism** | Partial restore = inconsistent state | Document manual recovery steps |

---

## Immediate Fixes Needed

### 1. Fix `sshd` service name (RESTORE-SFS.sh:188)

```bash
# Change from:
systemctl restart sshd

# To:
systemctl restart ssh
```

**Reason:** Ubuntu 24.04 uses `ssh` as service name. `sshd` will silently fail.

---

## Testing Checklist

Before production use, test these scenarios:

- [ ] Fresh instance with no SFS attached (should show MOTD and exit)
- [ ] Fresh instance with SFS attached but empty (should download from R2)
- [ ] Instance with SFS containing cached models/container (should use SFS)
- [ ] PAT expiry scenario (what happens when GitHub auth fails?)
- [ ] R2 credentials wrong (what happens?)
- [ ] Corrupted/incomplete backup files
- [ ] Network failure mid-download

---

## Credential Expiry Tracking

| Credential | Location | Expires | Notes |
|------------|----------|---------|-------|
| GitHub PAT | quick-start.sh:32 | ? | Check GitHub settings |
| R2 Access Key | quick-start.sh:39, RESTORE-SFS.sh:370, 426 | Never (R2 keys don't expire) | But can be revoked |

---

**Last Updated:** 2026-01-18
