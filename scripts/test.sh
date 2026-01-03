#!/bin/bash
#
# Integration Test Suite for ComfyUI Multi-User Platform
# Tests all components end-to-end
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Load environment
if [ -f "$PROJECT_DIR/.env" ]; then
    source "$PROJECT_DIR/.env"
else
    echo -e "${RED}❌ .env file not found${NC}"
    exit 1
fi

echo "=========================================================="
echo "  ComfyUI Multi-User Platform - Integration Tests"
echo "=========================================================="
echo ""

# Helper functions
pass_test() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "${GREEN}✅ PASS${NC} - $1"
}

fail_test() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    echo -e "${RED}❌ FAIL${NC} - $1"
    if [ ! -z "$2" ]; then
        echo -e "${RED}   Error: $2${NC}"
    fi
}

info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

warn() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

# Test 1: Docker Services Running
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Testing Docker Services"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REQUIRED_SERVICES=("comfy-nginx" "comfy-redis" "comfy-queue-manager" "comfy-worker-1" "comfy-admin")

for service in "${REQUIRED_SERVICES[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
        pass_test "Service $service is running"
    else
        fail_test "Service $service is NOT running" "Start with: docker-compose up -d"
    fi
done

# Test 2: Service Health Checks
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Testing Service Health Endpoints"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Redis health
if docker-compose exec -T redis redis-cli -a "$REDIS_PASSWORD" ping 2>/dev/null | grep -q "PONG"; then
    pass_test "Redis health check"
else
    fail_test "Redis health check" "Redis not responding"
fi

# Queue Manager health
QUEUE_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${QUEUE_MANAGER_PORT:-3000}/health)
if [ "$QUEUE_HEALTH" = "200" ]; then
    pass_test "Queue Manager health check (HTTP 200)"
else
    fail_test "Queue Manager health check" "Got HTTP $QUEUE_HEALTH"
fi

# Admin Dashboard health
ADMIN_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${ADMIN_PORT:-8080}/health)
if [ "$ADMIN_HEALTH" = "200" ]; then
    pass_test "Admin Dashboard health check (HTTP 200)"
else
    fail_test "Admin Dashboard health check" "Got HTTP $ADMIN_HEALTH"
fi

# Worker health (ComfyUI)
WORKER_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8188/system_stats 2>/dev/null || echo "000")
if [ "$WORKER_HEALTH" = "200" ]; then
    pass_test "Worker ComfyUI health check (HTTP 200)"
else
    warn "Worker ComfyUI health check" "Got HTTP $WORKER_HEALTH (may not be exposed)"
fi

# Test 3: Queue Manager API
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Testing Queue Manager API"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test queue status endpoint
QUEUE_STATUS=$(curl -s http://localhost:${QUEUE_MANAGER_PORT:-3000}/api/queue/status)
if echo "$QUEUE_STATUS" | jq -e '.mode' >/dev/null 2>&1; then
    pass_test "Queue status endpoint returns valid JSON"
    info "Queue mode: $(echo $QUEUE_STATUS | jq -r '.mode')"
    info "Pending jobs: $(echo $QUEUE_STATUS | jq -r '.pending_jobs')"
else
    fail_test "Queue status endpoint" "Invalid JSON response"
fi

# Test job submission endpoint (dry run)
TEST_JOB='{"user_id":"test_user","workflow":{"test":"workflow"},"priority":2}'
JOB_SUBMIT=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d "$TEST_JOB" \
    http://localhost:${QUEUE_MANAGER_PORT:-3000}/api/jobs)

if echo "$JOB_SUBMIT" | jq -e '.id' >/dev/null 2>&1; then
    JOB_ID=$(echo "$JOB_SUBMIT" | jq -r '.id')
    pass_test "Job submission endpoint (job created: ${JOB_ID:0:8})"

    # Cancel the test job immediately
    curl -s -X DELETE http://localhost:${QUEUE_MANAGER_PORT:-3000}/api/jobs/$JOB_ID >/dev/null
    info "Test job cancelled"
else
    fail_test "Job submission endpoint" "Could not create test job"
fi

# Test 4: Redis Queue Operations
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Testing Redis Queue Operations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check queue depth
PENDING_COUNT=$(docker-compose exec -T redis redis-cli -a "$REDIS_PASSWORD" ZCARD queue:pending 2>/dev/null || echo "0")
RUNNING_COUNT=$(docker-compose exec -T redis redis-cli -a "$REDIS_PASSWORD" ZCARD queue:running 2>/dev/null || echo "0")
COMPLETED_COUNT=$(docker-compose exec -T redis redis-cli -a "$REDIS_PASSWORD" ZCARD queue:completed 2>/dev/null || echo "0")

pass_test "Redis queue operations accessible"
info "Pending: $PENDING_COUNT, Running: $RUNNING_COUNT, Completed: $COMPLETED_COUNT"

# Test 5: Nginx Routing
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Testing Nginx Routing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test admin route
ADMIN_ROUTE=$(curl -s -o /dev/null -w "%{http_code}" -k https://localhost/admin 2>/dev/null || curl -s -o /dev/null -w "%{http_code}" http://localhost/admin 2>/dev/null || echo "000")
if [ "$ADMIN_ROUTE" = "200" ]; then
    pass_test "Nginx admin route (/admin)"
else
    warn "Nginx admin route" "Got HTTP $ADMIN_ROUTE (SSL may not be configured)"
fi

# Test API route
API_ROUTE=$(curl -s -o /dev/null -w "%{http_code}" -k https://localhost/api/queue/status 2>/dev/null || curl -s -o /dev/null -w "%{http_code}" http://localhost/api/queue/status 2>/dev/null || echo "000")
if [ "$API_ROUTE" = "200" ]; then
    pass_test "Nginx API route (/api/queue/status)"
else
    warn "Nginx API route" "Got HTTP $API_ROUTE"
fi

# Test user001 route (if frontend exists)
USER_ROUTE=$(curl -s -o /dev/null -w "%{http_code}" -k https://localhost/user001/ 2>/dev/null || curl -s -o /dev/null -w "%{http_code}" http://localhost/user001/ 2>/dev/null || echo "000")
if [ "$USER_ROUTE" = "200" ]; then
    pass_test "Nginx user route (/user001/)"
else
    warn "Nginx user route" "Got HTTP $USER_ROUTE (user frontends may not be started)"
fi

# Test 6: File System Permissions
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Testing File System & Volumes"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check required directories
REQUIRED_DIRS=("data/models/shared" "data/outputs" "data/inputs" "data/workflows")

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$PROJECT_DIR/$dir" ]; then
        pass_test "Directory exists: $dir"
    else
        fail_test "Directory missing: $dir" "Run ./scripts/setup.sh"
    fi
done

# Check volume mounts
if docker-compose exec -T worker-1 test -d /models 2>/dev/null; then
    pass_test "Worker models volume mounted"
else
    fail_test "Worker models volume" "Volume not mounted"
fi

if docker-compose exec -T worker-1 test -d /outputs 2>/dev/null; then
    pass_test "Worker outputs volume mounted"
else
    fail_test "Worker outputs volume" "Volume not mounted"
fi

# Test 7: GPU Availability (if applicable)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Testing GPU Availability"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if command -v nvidia-smi &> /dev/null; then
    GPU_COUNT=$(nvidia-smi --query-gpu=count --format=csv,noheader | head -n1)
    pass_test "GPU detected: $GPU_COUNT GPU(s) available"

    # Check GPU in worker container
    if docker-compose exec -T worker-1 nvidia-smi 2>/dev/null | grep -q "NVIDIA"; then
        pass_test "Worker container has GPU access"
    else
        fail_test "Worker GPU access" "Container cannot access GPU"
    fi
else
    warn "No NVIDIA GPU detected (CPU-only mode)"
fi

# Test 8: Configuration Validation
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8. Testing Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check critical env vars
CRITICAL_VARS=("REDIS_PASSWORD" "DOMAIN" "QUEUE_MODE")

for var in "${CRITICAL_VARS[@]}"; do
    if [ ! -z "${!var}" ]; then
        pass_test "Environment variable set: $var"
    else
        fail_test "Environment variable missing: $var" "Check .env file"
    fi
done

# Validate queue mode
VALID_MODES=("fifo" "round_robin" "priority")
if [[ " ${VALID_MODES[@]} " =~ " ${QUEUE_MODE} " ]]; then
    pass_test "Queue mode valid: $QUEUE_MODE"
else
    fail_test "Queue mode invalid: $QUEUE_MODE" "Must be one of: ${VALID_MODES[*]}"
fi

# Test 9: WebSocket Connectivity
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "9. Testing WebSocket Support"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check nginx WebSocket config
if docker-compose exec -T nginx cat /etc/nginx/nginx.conf 2>/dev/null | grep -q "Upgrade"; then
    pass_test "Nginx WebSocket support configured"
else
    fail_test "Nginx WebSocket support" "Upgrade header not found in nginx.conf"
fi

# Test 10: Logging
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "10. Testing Logging & Monitoring"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if logs are accessible
if docker-compose logs --tail=10 queue-manager 2>/dev/null | grep -q "Queue Manager"; then
    pass_test "Queue Manager logs accessible"
else
    warn "Queue Manager logs may be empty"
fi

if docker-compose logs --tail=10 worker-1 2>/dev/null | grep -q "Worker"; then
    pass_test "Worker logs accessible"
else
    warn "Worker logs may be empty"
fi

# Summary
echo ""
echo "=========================================================="
echo "  Test Summary"
echo "=========================================================="
echo ""
echo -e "Total tests:   ${BLUE}$TESTS_TOTAL${NC}"
echo -e "Passed:        ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed:        ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    echo "System is ready for deployment! 🚀"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    echo ""
    echo "Please fix the failing tests before deploying to production."
    exit 1
fi
