**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-10

---

# Admin Checklist: Post-Workshop

## Immediate Actions (During Last Hour of Workshop)

Complete these tasks while workshop is still running.

### Stop New Job Submissions

- [ ] Inform participants no new jobs accepted
  ```
  "We're in the final hour - no new jobs will be accepted after X:XX PM
   but all current jobs will complete"
  ```

- [ ] Close job submission interface (if possible)
  ```bash
  # Or monitor and manually cancel new submissions
  curl https://comfy.ahelme.net/api/queue/status
  ```

### Clear Admin Priority Queue

- [ ] Allow all current jobs to complete
  ```bash
  # Monitor admin dashboard
  # Don't prioritize any new jobs
  # Let natural queue run out
  ```

### Monitor Remaining Jobs

- [ ] Watch queue depth decrease to zero
  ```bash
  watch -n 10 'curl -s https://comfy.ahelme.net/api/queue/status | jq ".queue_depth"'
  ```

- [ ] Note completion time and total jobs processed
  ```bash
  # Save for final report:
  FINAL_TIME=$(date)
  TOTAL_JOBS=$(curl -s https://comfy.ahelme.net/api/queue/status | jq '.completed_jobs')
  ```

## Short Term Actions (Within 1 Hour of Workshop End)

Complete before shutting down services.

### Export and Backup Data

- [ ] Export user outputs for participants
  ```bash
  cd /home/dev/projects/comfyui
  tar -czf outputs-backup-$(date +%Y%m%d-%H%M%S).tar.gz data/outputs/
  ls -lah outputs-backup-*.tar.gz
  ```

- [ ] Export complete system logs
  ```bash
  docker-compose logs > workshop-logs-$(date +%Y%m%d-%H%M%S).txt

  # Compress for storage
  gzip workshop-logs-*.txt
  ```

- [ ] Export database snapshot
  ```bash
  docker-compose exec redis redis-cli -a $REDIS_PASSWORD SAVE
  cp ./data/redis/dump.rdb ./redis-snapshot-$(date +%Y%m%d-%H%M%S).rdb
  ```

- [ ] Archive configuration
  ```bash
  cp .env .env-workshop-$(date +%Y%m%d)
  cp docker-compose.yml docker-compose-$(date +%Y%m%d).yml
  ```

### Create Full Backup

```bash
# Create comprehensive backup of all workshop data
tar -czf workshop-backup-$(date +%Y%m%d).tar.gz \
  data/outputs/ \
  data/redis/ \
  .env-workshop-* \
  docker-compose-*.yml \
  workshop-logs-*.txt \
  redis-snapshot-*.rdb

# Verify backup
tar -tzf workshop-backup-$(date +%Y%m%d).tar.gz | head -20

# List all backup files
ls -lah workshop-backup-*.tar.gz
```

### Optional: Graceful Shutdown

- [ ] Stop accepting any jobs
  ```bash
  # Already done in previous section
  ```

- [ ] Optional: Stop services (if preserving data)
  ```bash
  docker-compose stop
  # Services stopped but data preserved in volumes
  ```

- [ ] Optional: Full shutdown (if not using later)
  ```bash
  docker-compose down
  # Remove containers but keep volumes

  # To remove volumes too (CAUTION!):
  docker-compose down -v
  ```

## Medium Term Actions (Same Day, After Workshop)

Complete these tasks while data is still fresh.

### Collect Metrics and Statistics

```bash
# Total jobs processed
TOTAL_JOBS=$(docker-compose exec redis redis-cli -a $REDIS_PASSWORD ZCARD queue:completed)
echo "Total jobs completed: $TOTAL_JOBS"

# Failed jobs (if tracking)
FAILED=$(docker-compose logs worker-1 | grep -i "failed" | wc -l)
echo "Failed jobs: $FAILED"

# Calculate success rate
echo "Success rate: $(( ($TOTAL_JOBS - $FAILED) * 100 / $TOTAL_JOBS ))%"

# Average job duration (if logged)
docker-compose logs worker-1 | grep "completed in" | awk '{print $NF}' | \
  awk '{sum+=$1; count++} END {print "Average: " sum/count " seconds"}'
```

### Analyze GPU Performance

```bash
# Peak memory usage recorded during workshop
# Check system logs or monitoring data if captured

# Check for thermal issues
grep -i "thermal" workshop-logs-*.txt
# Should find none

# Check for crash/recovery events
docker-compose logs | grep -i "restarted\|crashed" | wc -l
# Should be zero or very low
```

### Analyze Queue Behavior

```bash
# Find peak queue depth
grep "queue:pending" workshop-logs-*.txt | grep "LLEN" | tail -20

# Find longest job in queue
docker-compose logs worker-1 | grep "started\|completed" | tail -10

# Identify any stuck/requeued jobs
grep -i "requeue\|retry" workshop-logs-*.txt
```

### Review Error Logs

```bash
# All errors that occurred
docker-compose logs | grep -i "error" > errors-found.txt
wc -l errors-found.txt

# All warnings
docker-compose logs | grep -i "warning" > warnings-found.txt

# SSL issues
docker-compose logs | grep -i "ssl" > ssl-issues.txt

# Connection issues
docker-compose logs | grep -i "connection\|refused" > connection-issues.txt
```

## Analysis and Reporting

### Create Workshop Report

Use this template:

```markdown
# Workshop Report - [Date]

## Participants
- Total registered: 20
- Attended: [X]
- Dropouts: [X]
- Completion rate: [X]%

## System Performance Metrics
- Total jobs submitted: [X]
- Successfully completed: [X]
- Failed: [X]
- Success rate: [X]%
- Average job duration: [X] seconds
- Longest job: [X] minutes

## Timing Analysis
- Workshop duration: [X] hours
- Peak queue depth: [X] jobs
- Time to clear queue: [X] minutes
- Longest wait time: [X] minutes

## GPU Performance
- Hardware: H100 80GB
- Peak memory usage: [X]%
- Average memory usage: [X]%
- Temperature peak: [X]°C
- Thermal throttling: [Yes/No]
- Any GPU errors: [Yes/No]

## Network Performance
- Latency VPS ↔ GPU: [X]ms
- Connection stability: [Stable/Issues]
- Connection timeouts: [Count]
- Bandwidth issues: [None/Minor/Severe]

## Issues Encountered
1. [Issue and resolution]
2. [Issue and resolution]
3. [Issue and resolution]

## Successful Workflows
- Models that worked well: [List]
- Popular resolutions: [List]
- Most common batch sizes: [List]

## Participant Feedback
- [General themes from discussions]
- [Most popular features]
- [Most requested improvements]
- [Technical issues mentioned]

## System Stability Log
- Service restarts: [Count]
- Emergency procedures: [None/Count]
- SLA achievement: [X]%
- Uptime: [X]% (calculated as: working_time / total_time)

## Recommendations for Next Time
1. [Improvement 1]
2. [Improvement 2]
3. [Improvement 3]

## Files Generated
- Logs: workshop-logs-[date].txt.gz
- Outputs backup: outputs-backup-[date].tar.gz
- Full backup: workshop-backup-[date].tar.gz
- Database snapshot: redis-snapshot-[date].rdb
- Configuration: .env-workshop-[date]

## Notes
[Any additional context, decisions, or notable observations]
```

### Generate Automated Report

```bash
#!/bin/bash
# Create workshop report automatically

REPORT_FILE="workshop-report-$(date +%Y%m%d).md"

cat > "$REPORT_FILE" << 'EOF'
# Workshop Report - $(date +%Y-%m-%d)

## System Statistics
EOF

# Add statistics
echo "Total Jobs: $(docker-compose exec redis redis-cli ZCARD queue:completed)" >> "$REPORT_FILE"
echo "Report time: $(date)" >> "$REPORT_FILE"

echo "Report saved to: $REPORT_FILE"
```

### Share Outputs with Participants

- [ ] Create download link or transfer mechanism for outputs
  ```bash
  # Option 1: Copy to public location
  cp -r data/outputs/* /public/share/workshop-outputs/

  # Option 2: Create password-protected zip
  zip -r -P password workshop-outputs.zip data/outputs/

  # Option 3: Upload to cloud storage
  # aws s3 cp outputs-backup-*.tar.gz s3://bucket/workshops/
  ```

- [ ] Send download instructions to participants
  ```
  "Your outputs are available at: [URL]
   Download expires: [DATE]
   Password: [IF APPLICABLE]
  ```

- [ ] Include feedback form/survey link
  ```
  "Please share your feedback: [SURVEY_LINK]
   What worked well?
   What could improve?
   Technical issues you encountered?
  ```

- [ ] Send thank you message
  ```
  "Thanks for attending! We hope you enjoyed the workshop.
   Please share your feedback to help us improve.
   See you next time!"
  ```

## Long Term Actions (Next Few Days)

### Clean Up and Optimize

- [ ] Delete temporary files
  ```bash
  # Keep backups but delete workshop log extracts
  rm -f errors-found.txt warnings-found.txt ssl-issues.txt

  # Optional: clean old outputs (if not needed)
  # find data/outputs -mtime +30 -delete
  ```

- [ ] Compress old logs for long-term storage
  ```bash
  gzip workshop-logs-*.txt
  tar -czf workshop-logs-$(date +%Y).tar.gz workshop-logs-*.txt.gz
  ```

- [ ] Update system for next workshop
  ```bash
  # Download any new model versions if available
  # Update ComfyUI if new features/fixes
  # Clear any test data
  ```

### Documentation Updates

- [ ] Update README if any processes changed
- [ ] Document any issues discovered for future reference
- [ ] Update troubleshooting guide with new issues found
- [ ] Note configuration changes made during workshop

### Team Debrief

- [ ] Collect feedback from co-administrators
- [ ] Discuss what went well
- [ ] Discuss what needs improvement
- [ ] Plan changes for next workshop
- [ ] Document lessons learned

## Archive Strategy

### Short Term (Keep Live)
- Last 7 days of logs
- Latest outputs
- Most recent backups

### Medium Term (Archive)
- Logs older than 7 days
- Backups older than 30 days
- Move to secondary storage

### Long Term (Deep Archive)
- Aggregate yearly reports
- Compress old backups
- Move to cold storage if needed

## Data Retention Schedule

```
Workshop data:
- Active logs: 7 days
- Output files: 30 days (or until participant downloads)
- Database snapshots: 90 days
- Full backups: 1 year
- Reports: Keep forever
- Configuration snapshots: Keep forever
```

## Verification Checklist

- [ ] All participant outputs backed up
- [ ] All logs exported and compressed
- [ ] Database snapshot created
- [ ] Configuration documented
- [ ] Report generated
- [ ] Backups verified (test restore one)
- [ ] Participants notified of output availability
- [ ] Feedback collected
- [ ] Cleanup completed
- [ ] System documented for next use

## Next Workshop Preparation

Within 1 week of completion:

- [ ] Review lessons learned document
- [ ] Update procedures based on feedback
- [ ] Plan improvements for next workshop
- [ ] Update documentation
- [ ] Verify all backups are still accessible
- [ ] Check certificates won't expire before next workshop
- [ ] Plan resource upgrades if needed

## Emergency Recovery Test

Within 1 month, test that backups can be restored:

```bash
# Test restore from backup
tar -xzf workshop-backup-[date].tar.gz -C /tmp/test/

# Verify key files are present
ls -la /tmp/test/data/outputs/
ls -la /tmp/test/data/redis/
```

---

**Report completed:** [DATE]
**Completed by:** [ADMIN NAME]
**Status:** [READY FOR STORAGE / NEEDS FOLLOW-UP]
