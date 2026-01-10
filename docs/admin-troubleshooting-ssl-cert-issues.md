**Project:** ComfyUI Multi-User Workshop Platform
**Project Started:** 2026-01-02
**Repository:** github.com/ahelme/comfy-multi
**Domain:** comfy.ahelme.net
**Doc Created:** 2026-01-10
**Doc Updated:** 2026-01-10

---

# Troubleshooting: SSL Certificate Errors

## Quick Diagnosis

HTTPS connection fails or browser shows certificate warnings. Users see "Not Secure" or "Certificate not trusted" errors.

## Symptoms

- Browser shows "Not Secure" warning or red lock
- "This site's certificate is not trusted" error
- Mixed content warnings (some resources http, some https)
- Connection refused on port 443
- `curl` fails with certificate verification error
- Certificate expired message

## Diagnosis Steps

```bash
# 1. Verify certificate files exist
ls -la /etc/ssl/certs/fullchain.pem
ls -la /etc/ssl/private/privkey.pem

# 2. Check certificate expiry date
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -enddate

# 3. Check certificate is valid for correct domain
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -text | grep -A1 "Subject:"

# 4. Verify certificate chain is complete
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -text | grep -A5 "X509v3"

# 5. Check file permissions are correct
stat /etc/ssl/certs/fullchain.pem
stat /etc/ssl/private/privkey.pem

# 6. Test SSL handshake
openssl s_client -connect localhost:443 -servername comfy.ahelme.net

# 7. Check nginx error logs
docker-compose logs nginx | grep -i "ssl\|certificate\|error"

# 8. Test with curl
curl -v https://comfy.ahelme.net/health
```

## Solutions (Try in Order)

### Solution 1: Verify Certificate Path Configuration

Ensure `.env` has correct paths to certificate files.

**Check current configuration:**

```bash
grep SSL .env
# Should show:
# SSL_CERT_PATH=/etc/ssl/certs/fullchain.pem
# SSL_KEY_PATH=/etc/ssl/private/privkey.pem
```

**Verify files actually exist at those paths:**

```bash
ls -la /etc/ssl/certs/fullchain.pem
ls -la /etc/ssl/private/privkey.pem
```

If paths are wrong:
1. Find the correct paths: `find / -name "fullchain.pem" 2>/dev/null`
2. Update `.env` with correct paths
3. Restart nginx: `docker-compose restart nginx`

### Solution 2: Fix Certificate Permissions

Nginx must be able to read both certificate files.

```bash
# Set correct permissions
chmod 644 /etc/ssl/certs/fullchain.pem
chmod 600 /etc/ssl/private/privkey.pem

# Set directory permissions
chmod 755 /etc/ssl/certs
chmod 700 /etc/ssl/private

# Verify
ls -la /etc/ssl/certs/ | grep fullchain
ls -la /etc/ssl/private/ | grep privkey
```

Then restart nginx:

```bash
docker-compose restart nginx
```

### Solution 3: Check Certificate Expiry

Certificates expire and must be renewed before they stop working.

```bash
# Check expiry date
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -enddate

# Example output:
# notAfter=Jan 15 2027 23:59:59 GMT

# Check how many days until expiry
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -enddate | \
  awk -F= '{print $2}' | \
  xargs -I {} date -d "{}" +%s | \
  xargs -I {} expr {} - $(date +%s) | \
  xargs -I {} expr {} / 86400
```

**If expired or expiring soon:**

1. Get new certificate from Namecheap (or certificate provider)
2. Download both files: fullchain.pem and privkey.pem
3. Copy to correct locations:
   ```bash
   sudo cp /path/to/new/fullchain.pem /etc/ssl/certs/
   sudo cp /path/to/new/privkey.pem /etc/ssl/private/
   ```
4. Fix permissions (see Solution 2)
5. Restart nginx: `docker-compose restart nginx`
6. Verify: `openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -enddate`

### Solution 4: Verify Certificate is for Correct Domain

Certificate must match the domain being accessed.

```bash
# Extract subject from certificate
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -subject

# Example output:
# subject=CN = comfy.ahelme.net

# Check alternative names (SubjectAltName)
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -text | grep -A1 "Subject Alternative Name"

# Should include: comfy.ahelme.net, www.comfy.ahelme.net, etc.
```

If certificate doesn't match domain:
- You have the wrong certificate file
- Get the correct certificate for comfy.ahelme.net from your provider

### Solution 5: Verify Certificate Chain is Valid

Certificate must have complete chain (root, intermediate, domain).

```bash
# Check certificate chain
openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -text | head -20

# Verify chain can be validated
openssl verify /etc/ssl/certs/fullchain.pem

# Should output:
# /etc/ssl/certs/fullchain.pem: OK
```

If chain validation fails:
- fullchain.pem may be corrupted
- Try re-downloading certificate from provider

### Solution 6: Test SSL Connection

Verify nginx can actually use the certificates.

```bash
# Test SSL handshake on localhost
openssl s_client -connect localhost:443 -servername comfy.ahelme.net

# Should complete successfully and show certificate details
# Type 'quit' to exit
```

If this fails:
- Check nginx error logs: `docker-compose logs nginx`
- Ensure nginx container can access certificate files
- Restart nginx: `docker-compose restart nginx`

### Solution 7: Restart Nginx to Reload Certificates

Changes to certificate files don't take effect until nginx restarts.

```bash
# Restart nginx container
docker-compose restart nginx

# Wait 5 seconds for startup
sleep 5

# Verify it started
docker-compose ps nginx | grep "Up"

# Check nginx logs
docker-compose logs nginx | tail -20
```

### Solution 8: Test HTTPS from Client

Once fixes applied, test from client machine.

```bash
# Using curl
curl -v https://comfy.ahelme.net/health

# Should show certificate details without SSL errors
# Should return 200 OK

# Using OpenSSL
openssl s_client -connect comfy.ahelme.net:443 -servername comfy.ahelme.net

# Should show "Verify return code: 0 (ok)"
```

## Nginx SSL Configuration

Verify nginx is configured correctly for SSL.

**In `nginx/conf.d/comfyui.conf`:**

```nginx
server {
  listen 443 ssl http2;
  server_name comfy.ahelme.net;

  # Certificate files
  ssl_certificate /etc/ssl/certs/fullchain.pem;
  ssl_certificate_key /etc/ssl/private/privkey.pem;

  # Security settings
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers HIGH:!aNULL:!MD5;
  ssl_prefer_server_ciphers on;
}

# Redirect HTTP to HTTPS
server {
  listen 80;
  server_name comfy.ahelme.net;
  return 301 https://$server_name$request_uri;
}
```

Verify this configuration:

```bash
# Check nginx config syntax
docker-compose exec nginx nginx -t

# Should output: OK
```

## Certificate Renewal Timeline

**Typical certificate expiry:**
- Purchased: Usually valid for 1-3 years
- Check expiry: `openssl x509 -in /etc/ssl/certs/fullchain.pem -noout -dates`

**Pre-expiry checklist (30 days before):**
- [ ] Check when certificate expires
- [ ] Contact certificate provider for renewal
- [ ] Order renewal (if not auto-renewing)
- [ ] Test renewal process before certificate actually expires

**At renewal time:**
- [ ] Download new certificate files
- [ ] Copy to correct locations
- [ ] Fix permissions
- [ ] Restart nginx
- [ ] Verify with curl

## Common Certificate Errors

| Error | Cause | Solution |
|-------|-------|----------|
| "certificate not yet valid" | System clock wrong | Fix system time: `date` |
| "certificate has expired" | Cert needs renewal | Renew certificate |
| "CN mismatch" | Wrong cert for domain | Use correct cert file |
| "untrusted root" | Missing intermediate cert | Ensure fullchain.pem used |
| "no such file or directory" | Wrong file path | Verify paths in .env |
| "permission denied" | Wrong file permissions | Fix with chmod (Solution 2) |

## Testing Mixed Content Issues

Some resources loading over HTTP when accessed via HTTPS.

```bash
# Check nginx is redirecting all HTTP to HTTPS
curl -v http://comfy.ahelme.net/health
# Should redirect to https://

# Check all links in pages use https://
curl https://comfy.ahelme.net/user001/ | grep "http://"
# Should return nothing (no http:// links)
```

If mixed content found:
- Update frontend configuration to use https:// links
- Update worker URLs to use https://
- Restart affected services

## Prevention Tips

1. **Document certificate expiry** - Set calendar reminder
2. **Use `fullchain.pem` not just cert.pem** - Ensures complete chain
3. **Test before workshop** - Always verify SSL working before users connect
4. **Monitor certificate health** - Check expiry monthly
5. **Keep certificate files safe** - Private key should be readable only by nginx

## Related Issues

- **Connection refused on port 443** → May be firewall, not certificate
- **Mixed content warnings** → Some content loading over HTTP
- **Users can't access** → Could be certificate or other routing issue, see admin-troubleshooting.md
