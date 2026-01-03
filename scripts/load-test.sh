#!/bin/bash
#
# Load Testing Script - Simulate 20 Concurrent Users
# Tests queue performance and system stability
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load environment
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
fi

QUEUE_MANAGER_URL="http://localhost:${QUEUE_MANAGER_PORT:-3000}"
NUM_USERS=${1:-20}
JOBS_PER_USER=${2:-1}

echo "=========================================================="
echo "  ComfyUI Load Test - Concurrent User Simulation"
echo "=========================================================="
echo ""
echo "Configuration:"
echo "  Users: $NUM_USERS"
echo "  Jobs per user: $JOBS_PER_USER"
echo "  Total jobs: $((NUM_USERS * JOBS_PER_USER))"
echo "  Queue Manager: $QUEUE_MANAGER_URL"
echo ""
read -p "Start load test? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Load test cancelled"
    exit 0
fi

# Simple test workflow (minimal to avoid actual GPU processing)
TEST_WORKFLOW='{
  "3": {
    "inputs": {
      "seed": 42,
      "steps": 5,
      "cfg": 7,
      "sampler_name": "euler",
      "scheduler": "normal",
      "denoise": 1
    },
    "class_type": "KSampler"
  }
}'

echo "Starting load test..."
echo ""

START_TIME=$(date +%s)
JOB_IDS=()

# Submit jobs for all users
for i in $(seq 1 $NUM_USERS); do
    USER_ID=$(printf "user%03d" $i)

    for j in $(seq 1 $JOBS_PER_USER); do
        JOB_DATA=$(cat <<EOF
{
  "user_id": "$USER_ID",
  "workflow": $TEST_WORKFLOW,
  "priority": 2,
  "metadata": {
    "test": "load_test",
    "user_num": $i,
    "job_num": $j
  }
}
EOF
)

        # Submit job
        RESPONSE=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$JOB_DATA" \
            "$QUEUE_MANAGER_URL/api/jobs")

        JOB_ID=$(echo "$RESPONSE" | jq -r '.id // empty')

        if [ ! -z "$JOB_ID" ]; then
            JOB_IDS+=("$JOB_ID")
            echo -e "${GREEN}✅${NC} Submitted job $((i * JOBS_PER_USER - JOBS_PER_USER + j))/$((NUM_USERS * JOBS_PER_USER)) for $USER_ID (ID: ${JOB_ID:0:8})"
        else
            echo -e "${YELLOW}⚠${NC}  Failed to submit job for $USER_ID"
        fi

        # Small delay to avoid overwhelming the API
        sleep 0.1
    done
done

SUBMIT_TIME=$(date +%s)
SUBMIT_DURATION=$((SUBMIT_TIME - START_TIME))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Job Submission Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Jobs submitted: ${#JOB_IDS[@]}"
echo "  Time taken: ${SUBMIT_DURATION}s"
echo "  Rate: $(echo "scale=2; ${#JOB_IDS[@]} / $SUBMIT_DURATION" | bc) jobs/sec"
echo ""

# Monitor queue status
echo "Monitoring queue status..."
echo ""

COMPLETED=0
FAILED=0
MONITOR_START=$(date +%s)
MAX_WAIT=300  # 5 minutes max

while [ $COMPLETED -lt ${#JOB_IDS[@]} ]; do
    # Get queue status
    QUEUE_STATUS=$(curl -s "$QUEUE_MANAGER_URL/api/queue/status")

    PENDING=$(echo "$QUEUE_STATUS" | jq -r '.pending_jobs // 0')
    RUNNING=$(echo "$QUEUE_STATUS" | jq -r '.running_jobs // 0')
    COMPLETED_TOTAL=$(echo "$QUEUE_STATUS" | jq -r '.completed_jobs // 0')
    FAILED_TOTAL=$(echo "$QUEUE_STATUS" | jq -r '.failed_jobs // 0')

    COMPLETED=0
    FAILED=0

    # Check individual job statuses
    for job_id in "${JOB_IDS[@]}"; do
        JOB_STATUS=$(curl -s "$QUEUE_MANAGER_URL/api/jobs/$job_id" | jq -r '.status // empty')

        if [ "$JOB_STATUS" = "completed" ]; then
            ((COMPLETED++)) || true
        elif [ "$JOB_STATUS" = "failed" ]; then
            ((FAILED++)) || true
        fi
    done

    ELAPSED=$(($(date +%s) - MONITOR_START))

    echo -ne "\r${BLUE}Queue:${NC} Pending: $PENDING | Running: $RUNNING | Completed: $COMPLETED/${#JOB_IDS[@]} | Failed: $FAILED | Time: ${ELAPSED}s   "

    # Check timeout
    if [ $ELAPSED -gt $MAX_WAIT ]; then
        echo ""
        echo ""
        echo -e "${YELLOW}⚠ Timeout reached (${MAX_WAIT}s)${NC}"
        echo "Not all jobs completed within the timeout period."
        break
    fi

    # All jobs done?
    if [ $((COMPLETED + FAILED)) -ge ${#JOB_IDS[@]} ]; then
        break
    fi

    sleep 2
done

echo ""
echo ""

END_TIME=$(date +%s)
TOTAL_DURATION=$((END_TIME - START_TIME))
PROCESSING_DURATION=$((END_TIME - SUBMIT_TIME))

# Cleanup - cancel any remaining jobs
echo "Cleaning up test jobs..."
for job_id in "${JOB_IDS[@]}"; do
    curl -s -X DELETE "$QUEUE_MANAGER_URL/api/jobs/$job_id" >/dev/null 2>&1 || true
done

echo ""
echo "=========================================================="
echo "  Load Test Results"
echo "=========================================================="
echo ""
echo "Jobs:"
echo "  Total submitted: ${#JOB_IDS[@]}"
echo "  Completed: $COMPLETED"
echo "  Failed: $FAILED"
echo "  Success rate: $(echo "scale=1; 100 * $COMPLETED / ${#JOB_IDS[@]}" | bc)%"
echo ""
echo "Timing:"
echo "  Job submission: ${SUBMIT_DURATION}s"
echo "  Job processing: ${PROCESSING_DURATION}s"
echo "  Total duration: ${TOTAL_DURATION}s"
echo ""
echo "Performance:"
echo "  Submission rate: $(echo "scale=2; ${#JOB_IDS[@]} / $SUBMIT_DURATION" | bc) jobs/sec"
if [ $COMPLETED -gt 0 ] && [ $PROCESSING_DURATION -gt 0 ]; then
    echo "  Processing rate: $(echo "scale=2; $COMPLETED / $PROCESSING_DURATION" | bc) jobs/sec"
    echo "  Avg time per job: $(echo "scale=2; $PROCESSING_DURATION / $COMPLETED" | bc)s"
fi
echo ""

if [ $FAILED -eq 0 ] && [ $COMPLETED -eq ${#JOB_IDS[@]} ]; then
    echo -e "${GREEN}✅ Load test PASSED!${NC}"
    echo "System handled $NUM_USERS concurrent users successfully."
    exit 0
else
    echo -e "${YELLOW}⚠ Load test completed with issues${NC}"
    echo "Some jobs failed or did not complete."
    exit 1
fi
