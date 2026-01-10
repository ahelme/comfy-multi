# Admin Security Guide

## Security Principles

The ComfyUI Multi-User Platform has 20 isolated user workspaces. Security focuses on:

1. **User Isolation**: Participants cannot access each other's work
2. **Data Protection**: All traffic encrypted with HTTPS
3. **Access Control**: Strong authentication and authorization
4. **System Stability**: Prevent denial of service and resource exhaustion
5. **Audit Trail**: Log suspicious activity for review

---

## Authentication & Access Control

### Admin Access

**Admin Dashboard Password:**
- Set in `.env`: `ADMIN_PASSWORD=<strong-password>`
- Generate strong password (32+ characters):
  ```bash
  openssl rand -base64 32
  ```
- Change before workshop:
  ```bash
  # In .env
  ADMIN_PASSWORD=NewSecurePassword123!@#

  # Restart queue manager
  docker-compose restart queue-manager
  ```

### User Access

**Participant Workspace URLs:**
- Each participant gets unique URL: `https://comfy.ahelme.net/user001` through `user020`
- URLs are not secret (not meant to be)
- Participants may watch each other's work in real-time
- But storage is completely isolated per user

### SSH Access

**Hetzner VPS:**
- Restrict SSH to your IP only (via Hetzner console)
- Use SSH keys, not passwords
- Document: `ssh desk` alias in ~/.ssh/config

**GPU Instance (Verda/RunPod):**
- Restrict SSH to your IP only
- Use SSH keys when possible
- Keep instance credentials secure

---

## Password Management

### Redis Password

**Critical: Protects job queue and user data**

```bash
# Generate strong password
REDIS_PASSWORD=$(openssl rand -base64 32)
echo "REDIS_PASSWORD=$REDIS_PASSWORD" >> .env

# Set in Redis container
docker-compose exec redis redis-cli CONFIG SET requirepass "$REDIS_PASSWORD"

# Verify
docker-compose exec redis redis-cli -a "$REDIS_PASSWORD" ping
```

### Admin Password

**Critical: Protects admin dashboard**

```bash
# Set in .env
ADMIN_PASSWORD=<new-secure-password>

# Restart to apply
docker-compose restart queue-manager
```

### User Passwords (if implementing authentication)

If you add user authentication:
- Hash passwords with bcrypt or Argon2 (never plaintext)
- Salt each password individually
- Use strong password requirements (12+ characters, mixed case, numbers, symbols)

---

## SSL/TLS Configuration

### Certificate Security

**SSL Certificate on Hetzner VPS:**

```bash
# Verify certificate location
ls -la /etc/ssl/certs/fullchain.pem
ls -la /etc/ssl/private/privkey.pem

# Check certificate details
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -text

# Verify certificate matches domain
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -text | grep -A1 "Subject:"
# Should match: CN=*.ahelme.net or CN=ahelme.net
```

### Certificate Permissions

**Restrict access to private key:**

```bash
# Private key readable only by root/docker
chmod 600 /etc/ssl/private/privkey.pem

# Public cert readable by all
chmod 644 /etc/ssl/certs/fullchain.pem

# Directory permissions
chmod 755 /etc/ssl/certs
chmod 700 /etc/ssl/private
```

### Certificate Renewal

**Before certificate expires:**

1. Obtain new certificate from Namecheap (or Let's Encrypt if using)
2. Update certificate files on VPS
3. Verify paths in `.env` are correct
4. Restart nginx:
   ```bash
   docker-compose restart nginx
   ```
5. Test:
   ```bash
   curl -vI https://comfy.ahelme.net/health
   # Should show valid certificate
   ```

### Enforce HTTPS Only

**Nginx should redirect HTTP → HTTPS:**

```bash
# Verify nginx config
docker exec nginx cat /etc/nginx/conf.d/comfyui.conf | grep -A2 "server_name"
# Should have: return 301 https://$host$request_uri;

# Test redirect
curl -I http://comfy.ahelme.net/health
# Should get: 301 Moved Permanently → https://...
```

---

## Redis Security

### Redis Authentication

**Require password to access Redis:**

```bash
# Verify password is set
docker-compose exec redis redis-cli CONFIG GET requirepass

# If not set, set it
docker-compose exec redis redis-cli CONFIG SET requirepass "$REDIS_PASSWORD"

# Verify
docker-compose exec redis redis-cli -a "$REDIS_PASSWORD" ping
```

### Redis Network Security

**Restrict Redis access to containers and GPU instances only:**

```bash
# Redis should NOT be exposed publicly
# Verify Redis is listening only on internal interface
docker-compose exec redis redis-cli CONFIG GET bind

# If needed, set to only docker network
docker-compose exec redis redis-cli CONFIG SET bind "redis"
```

### Redis Firewall Rules

**On Hetzner VPS:**

```bash
# Allow GPU instance to connect to Redis
# Port 6379 should only be open to GPU instance IP
sudo ufw status
# Should show port 6379 is NOT open to 0.0.0.0

# Add firewall rule (if needed)
sudo ufw allow from [GPU_INSTANCE_IP] to any port 6379
```

**Monitor unauthorized access attempts:**

```bash
# Check for failed authentication attempts
docker-compose logs redis | grep -i "error\|auth\|wrong"
```

---

## User Isolation Verification

### Container Isolation

**Each user has isolated container:**

```bash
# Verify containers exist
docker-compose ps | grep frontend-user

# Each container runs as separate process
docker ps | grep frontend-user0XX | wc -l
# Should show 20 frontend containers
```

### Storage Isolation

**Each user has isolated volume:**

```bash
# Verify volumes exist
docker volume ls | grep comfy

# Each user's data in separate directory
ls -la data/outputs/user001/
ls -la data/outputs/user002/
# user001 cannot access user002's files (file permissions)

# Verify permissions
stat data/outputs/user001/
# Should show user001 directory only
```

### Network Isolation

**Each container on isolated network:**

```bash
# Verify docker networks
docker network ls | grep comfy

# Containers cannot access each other's ports directly
# They communicate through Redis (job queue only)
docker inspect frontend-user001 | grep -A10 "Networks"
```

### Verify User Cannot Access Others' Data

```bash
# From user001 container, try to access user002's data
docker-compose exec frontend-user001 \
  ls /outputs/user002/
# Should get: Permission Denied

# Or try HTTP access
curl -s https://localhost/user002/outputs
# Should get 403 Forbidden or 404 Not Found
```

---

## Network Security

### Firewall Rules

**Hetzner VPS Firewall (Inbound):**

```bash
# SSH (admin only)
sudo ufw allow from [YOUR_IP] to any port 22

# HTTPS (public)
sudo ufw allow 443/tcp

# HTTP (redirect to HTTPS)
sudo ufw allow 80/tcp

# Redis (GPU instance only)
sudo ufw allow from [GPU_INSTANCE_IP] to any port 6379

# Deny all else
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

**GPU Instance Firewall (if available):**

```bash
# Only allow SSH from your IP
ssh 22 from [YOUR_IP]

# Allow outbound to VPS (Redis on 6379)
outbound 6379 to [VPS_IP]

# Deny unnecessary ports
```

### Network Segmentation

**Ideally use separate networks:**

```
┌─────────────────────────────────┐
│ Hetzner VPS Network             │
│ - Nginx (public HTTP/HTTPS)     │
│ - Queue Manager (internal)      │
│ - Frontend containers (internal)│
│ - Redis (port 6379 restricted)  │
└──────────────┬──────────────────┘
               │
               │ Internet (encrypted TLS)
               │
┌──────────────▼──────────────────┐
│ GPU Instance Network            │
│ - Worker containers (internal)  │
│ - Redis client (port 6379)      │
└─────────────────────────────────┘
```

---

## Access Control

### API Rate Limiting

**Prevent abuse/DoS:**

```bash
# Check if rate limiting is configured
docker-compose exec queue-manager \
  grep -i "rate_limit\|ratelimit" config/*

# Recommended: Limit API requests
# 100 requests per IP per minute
# 1000 requests per global per minute
```

### Admin Dashboard Rate Limiting

**Protect admin access:**

```bash
# Check nginx rate limiting config
docker exec nginx cat /etc/nginx/conf.d/comfyui.conf | grep -i "rate_limit"

# Should limit admin access
# Recommended: 10 requests per second per IP
```

### User Job Submission Limits

**Prevent resource exhaustion:**

```bash
# Check .env for job limits
grep -i "job_limit\|queue_limit" .env

# Recommended settings:
# - Max jobs per user: 5 concurrent
# - Max queue depth: 100 jobs
# - Job timeout: 3600 seconds (1 hour)
```

---

## Audit & Monitoring

### Access Logging

**Enable access logs:**

```bash
# Check nginx access logs
docker-compose logs nginx | grep -i "access"

# Export for analysis
docker-compose logs nginx > nginx-access.log

# Analyze for suspicious activity
grep "401\|403\|500" nginx-access.log  # Errors
grep "admin" nginx-access.log           # Admin access
grep -v "user00" nginx-access.log       # Non-user paths
```

### Failed Login Attempts

**Monitor authentication failures:**

```bash
# Check admin login attempts
docker-compose logs queue-manager | grep -i "failed\|unauthorized\|403"

# Count failed attempts per IP
docker-compose logs queue-manager | grep "403" | cut -d' ' -f1 | sort | uniq -c
```

### Anomalous Activity

**Watch for suspicious patterns:**

```bash
# Unusually high job submission
docker-compose exec redis redis-cli -a "$REDIS_PASSWORD" LLEN queue:pending

# Jobs from unusual users
docker-compose logs queue-manager | grep "user0" | sort | uniq -c | sort -rn

# Rapid user switching
docker-compose logs nginx | grep "user00" | wc -l
```

### System Audit Log

**Keep audit trail for compliance:**

```bash
# Export all logs regularly
docker-compose logs > audit-log-$(date +%Y%m%d-%H%M%S).txt

# Archive securely
tar -czf audit-$(date +%Y%m%d).tar.gz audit-log-*.txt

# Keep for minimum 30 days
```

---

## Data Protection

### Backup Security

**Ensure backups are encrypted:**

```bash
# Backup with encryption
tar -czf - data/outputs/ | \
  openssl enc -aes-256-cbc -salt > outputs-backup.tar.gz.enc

# Store in secure location with limited access
chmod 700 outputs-backup.tar.gz.enc
```

### Data Deletion After Workshop

**Remove sensitive data after workshop:**

```bash
# Delete user outputs (after exporting)
rm -rf data/outputs/user*/

# Securely wipe Redis
docker-compose exec redis redis-cli -a "$REDIS_PASSWORD" FLUSHALL

# Reset database
docker-compose down
docker volume rm comfyui_redis_data  # DANGER: permanent delete
docker-compose up -d
```

### Data Retention Policy

**Decide how long to keep data:**

- Workshop outputs: 30 days (for participant download)
- Logs: 90 days (for audit/compliance)
- User data: Delete after workshop
- Backups: Keep for 1 year (for legal compliance)

---

## Incident Response

### Security Incident Procedure

**If you suspect a security breach:**

1. **Isolate affected system:**
   ```bash
   docker-compose stop [affected_service]
   ```

2. **Collect evidence:**
   ```bash
   docker-compose logs > incident-logs-$(date +%Y%m%d-%H%M%S).txt
   ```

3. **Assess impact:**
   - What data was accessed?
   - Which users affected?
   - How long was system vulnerable?

4. **Notify affected users:** (if personal data exposed)
   - Email to all participants
   - Explain what happened
   - Steps taken to remediate
   - No further action needed from them

5. **Remediate:**
   - Change all passwords
   - Restart all services
   - Update configurations
   - Verify fix

6. **Post-incident review:**
   - What caused the breach?
   - How do we prevent it?
   - Update security procedures

### Malware Detection

**Watch for signs of compromise:**

```bash
# Check for unusual processes
docker top worker-1
docker top queue-manager

# Check for modified files
docker diff worker-1
docker diff queue-manager

# Check for unusual network connections
netstat -tlnp | grep ESTABLISHED

# Check container logs for suspicious activity
docker-compose logs worker-1 | grep -i "curl\|wget\|bash\|exec"
```

---

## Compliance & Best Practices

### Regular Security Updates

```bash
# Check for outdated packages
docker-compose exec queue-manager pip list --outdated
docker-compose exec worker-1 pip list --outdated

# Update base images regularly
docker pull python:3.12-slim
docker-compose build --no-cache
docker-compose up -d
```

### Security Checklist (Before Workshop)

- [ ] Admin password changed from default
- [ ] Redis password set and strong
- [ ] SSL certificate valid and not expired
- [ ] Firewall rules configured correctly
- [ ] SSH access restricted by IP
- [ ] Backups encrypted and stored securely
- [ ] All dependencies up to date
- [ ] Logs are being collected and archived
- [ ] User isolation verified
- [ ] HTTPS enforced (no HTTP access)
- [ ] Docker images are pulled from official sources
- [ ] No sensitive data in .env checked into git

### Post-Workshop Security Review

- [ ] Collect and archive all logs
- [ ] Review logs for suspicious activity
- [ ] Delete user data (unless keeping for legal reasons)
- [ ] Document any security incidents
- [ ] Update security procedures based on lessons learned
- [ ] Archive backups securely

---

## Security References

### External Resources

- **OWASP Top 10**: https://owasp.org/www-project-top-ten/
- **Docker Security**: https://docs.docker.com/engine/security/
- **Redis Security**: https://redis.io/docs/management/security/
- **Nginx Security**: https://nginx.org/en/docs/

### Internal References

- **admin-guide.md** - Quick reference and monitoring
- **admin-troubleshooting.md** - Problem solving
- **admin-workshop-checklist.md** - Workshop procedures
- **admin-setup-guide.md** - Initial configuration

---

## Quick Security Checklist

Before starting workshop, verify:

```bash
# 1. Passwords are strong
grep -E "REDIS_PASSWORD|ADMIN_PASSWORD" .env | grep -v "^#"

# 2. SSL certificate is valid
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -dates

# 3. HTTPS is enforced
curl -I http://comfy.ahelme.net/ | head -1

# 4. User isolation is working
docker-compose exec frontend-user001 ls /outputs/user002/ 2>&1

# 5. Firewall rules are correct
sudo ufw status | grep 6379

# 6. No sensitive data in git
git log -p | grep -i "password\|secret\|key" | head -10

# 7. All services are running
docker-compose ps | grep "Up"
```

If all checks pass, you're ready for the workshop!
