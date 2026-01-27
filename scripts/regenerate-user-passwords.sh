#!/bin/bash
#
# Regenerate user passwords for ComfyUI Workshop Platform
# Creates new credentials and updates nginx htpasswd file
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CREDENTIALS_FILE="$PROJECT_DIR/USER_CREDENTIALS.txt"
HTPASSWD_FILE="/etc/nginx/comfyui-users.htpasswd"

echo "=================================================="
echo "  ComfyUI - Regenerate User Passwords"
echo "=================================================="
echo ""

# Confirm action
read -p "This will generate new passwords for all 20 users. Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo "🔐 Generating secure passwords..."

# Generate credentials using Python
python3 << 'EOF'
import secrets
import string

def generate_password(length=24):
    """Generate a secure random password"""
    alphabet = string.ascii_letters + string.digits + "!@#$%^&*-_=+"
    password = [
        secrets.choice(string.ascii_lowercase),
        secrets.choice(string.ascii_uppercase),
        secrets.choice(string.digits),
        secrets.choice("!@#$%^&*-_=+")
    ]
    password += [secrets.choice(alphabet) for _ in range(length - 4)]
    secrets.SystemRandom().shuffle(password)
    return ''.join(password)

# Generate credentials
credentials = []
for i in range(1, 21):
    username = f"user{i:03d}"
    password = generate_password()
    credentials.append((username, password))

# Save to file
with open('USER_CREDENTIALS.txt', 'w') as f:
    f.write("# ComfyUI Workshop - User Credentials\n")
    f.write("# Generated: 2026-01-28\n")
    f.write("# Format: username:password\n")
    f.write("# \n")
    f.write("# IMPORTANT: Keep this file secure and private!\n")
    f.write("# This file is gitignored and should NOT be committed to public repo.\n")
    f.write("# \n\n")
    for username, password in credentials:
        f.write(f"{username}:{password}\n")

print("✅ Credentials generated")
EOF

# Move to project root
mv USER_CREDENTIALS.txt "$CREDENTIALS_FILE"

echo "📝 Updating nginx htpasswd file..."

# Recreate htpasswd file
sudo rm -f "$HTPASSWD_FILE"
sudo touch "$HTPASSWD_FILE"
sudo chown root:www-data "$HTPASSWD_FILE"
sudo chmod 640 "$HTPASSWD_FILE"

# Add all users
while IFS=: read -r username password; do
  # Skip comments and empty lines
  [[ "$username" =~ ^#.*$ ]] && continue
  [[ -z "$username" ]] && continue
  # Add user with bcrypt cost 10
  echo "$password" | sudo htpasswd -iB -C 10 "$HTPASSWD_FILE" "$username" 2>/dev/null
done < "$CREDENTIALS_FILE"

echo "✅ htpasswd file updated"

# Test first user
echo ""
echo "🧪 Testing user001 authentication..."
FIRST_USER=$(grep "^user001:" "$CREDENTIALS_FILE" | cut -d: -f1)
FIRST_PASS=$(grep "^user001:" "$CREDENTIALS_FILE" | cut -d: -f2)

if echo "$FIRST_PASS" | sudo htpasswd -v "$HTPASSWD_FILE" "$FIRST_USER" 2>&1 | grep -q "correct"; then
    echo "✅ Authentication test passed"
else
    echo "❌ Authentication test failed"
    exit 1
fi

echo ""
echo "=================================================="
echo "  ✅ Password regeneration complete!"
echo "=================================================="
echo ""
echo "Credentials saved to: $CREDENTIALS_FILE"
echo "Nginx htpasswd updated: $HTPASSWD_FILE"
echo ""
echo "Next steps:"
echo "  1. Reload nginx: sudo systemctl reload nginx"
echo "  2. Copy credentials to private repo"
echo "  3. Distribute credentials to workshop participants"
echo ""
