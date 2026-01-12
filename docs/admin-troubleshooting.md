**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-11

---

# Admin Troubleshooting Guide - Quick Reference

This is a quick reference guide to troubleshooting resources. For detailed solutions, see the problem-specific guides below.

## Quick Diagnosis Commands

```bash
# Complete system status
./scripts/status.sh

# Check all services are running
docker-compose ps

# View system resource usage
docker stats

# Queue status
curl https://comfy.ahelme.net/api/queue/status

# Redis connectivity
docker-compose exec redis redis-cli -a $REDIS_PASSWORD ping

# Worker logs
docker-compose logs worker-1 | tail -20

# Nginx errors
docker-compose logs nginx | grep ERROR
```

---

## Problem-Specific Troubleshooting Guides

### Queue and Job Processing Issues

- **[Queue Not Processing](./admin-troubleshooting-queue-stopped.md)** - Jobs stuck in pending state
  - Worker not running or not connected
  - Diagnosis commands and solutions
  - Prevention tips and monitoring

### GPU Memory and Performance

- **[Out of Memory (OOM) Errors](./admin-troubleshooting-out-of-memory.md)** - GPU runs out of VRAM
  - Batch size optimization
  - Model selection and memory management
  - GPU memory reference and monitoring
  - Adding additional workers

### Network and Connectivity

- **[Workers Can't Connect to Redis](./admin-troubleshooting-worker-not-connecting.md)** - Remote GPU connection issues
  - Network connectivity testing
  - Firewall configuration for Remote GPU (e.g. Verda, RunPod)
  - DNS resolution and verification
  - Password and authentication checks

- **[Redis Connection Issues](./admin-troubleshooting-redis-connection.md)** - Redis service problems
  - Redis startup and container health
  - Password configuration and verification
  - Container networking and port conflicts
  - Redis persistence and backups

### Certificates and HTTPS

- **[SSL Certificate Errors](./admin-troubleshooting-ssl-cert-issues.md)** - HTTPS connection failures
  - Certificate path verification
  - Permission fixes
  - Expiry and renewal
  - Domain verification

### Docker and Infrastructure

- **[Docker and Container Issues](./admin-troubleshooting-docker-issues.md)** - Container startup and crashes
  - Disk space and resource limits
  - Log analysis
  - Port conflicts
  - Volume mount issues
  - Container recreation and recovery

---

## Performance Metrics to Monitor

| Metric | Good | Warning | Critical |
|--------|------|---------|----------|
| **GPU Memory** | < 70% | 70-85% | > 85% |
| **Queue Depth** | < 5 | 5-20 | > 20 |
| **Job Time (simple)** | < 2 min | 2-5 min | > 5 min |
| **Failed Jobs** | 0% | < 1% | > 5% |
| **Uptime** | > 99% | 95-99% | < 95% |

---

## Emergency Procedures

### Complete System Restart

```bash
# Stop everything
docker-compose down

# Remove cache (if corrupted)
docker system prune -a

# Restart everything
docker-compose up -d

# Verify
docker-compose ps
curl https://comfy.ahelme.net/health
```

### Check Logs for Errors

```bash
# All errors
docker-compose logs | grep -i error

# Follow in real-time
docker-compose logs -f | grep -i error

# Export to file
docker-compose logs > full-logs.txt
grep -i "error\|warning" full-logs.txt
```

---

## Related Documentation

- **[Pre-Workshop Checklist](./admin-checklist-pre-workshop.md)** - Setup and preparation
- **[During-Workshop Checklist](./admin-checklist-during-workshop.md)** - Monitoring and support
- **[Post-Workshop Checklist](./admin-checklist-post-workshop.md)** - Backup and analysis
- **admin-guide.md** - General admin reference
- **admin-setup-guide.md** - Initial configuration
- **admin-dashboard.md** - Real-time monitoring interface
