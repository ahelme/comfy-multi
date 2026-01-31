---
name: context-warning-periodic
enabled: true
event: stop
---

## 📊 Context Management Reminder

**Before stopping, check token count in status bar!**

### If approaching 80% context (~160k/200k tokens):

1. Run `/CLAUDE-HANDOVER` skill to update:
   - GitHub issues (current work + related issues)
   - progress-verda-dev.md
   - Collaboration issue #7: https://github.com/ahelme/comfyume/issues/7
   - Top of CLAUDE.md (HANDOVER section)
   - Commit and push all changes

2. Run `/compact` to compress context

### SessionStart Hook Active ✅
The `/resume-context-verda` skill runs automatically at session start!
