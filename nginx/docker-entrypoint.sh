#!/bin/sh
set -e

# Generate user frontend routing configuration
echo "Generating nginx configuration for ${NUM_USERS:-20} users..."

# Create upstream configuration for user frontends
cat > /etc/nginx/conf.d/user-upstreams.conf <<EOF
# User frontend upstreams (generated at runtime)
EOF

# Create location blocks for user routing
cat > /etc/nginx/conf.d/user-locations.conf <<EOF
# User frontend locations (generated at runtime)
EOF

# Generate configuration for each user
for i in $(seq 1 ${NUM_USERS:-20}); do
    USER_ID=$(printf "user%03d" $i)
    PORT=$((8000 + i))

    # Add upstream
    cat >> /etc/nginx/conf.d/user-upstreams.conf <<EOF

upstream ${USER_ID} {
    server ${USER_ID}:8188;
}
EOF

    # Add location
    cat >> /etc/nginx/conf.d/user-locations.conf <<EOF

location /${USER_ID}/ {
    proxy_pass http://${USER_ID}/;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;

    # WebSocket support
    proxy_read_timeout 86400;
    proxy_send_timeout 86400;
}
EOF
done

echo "Nginx configuration generated successfully"

# Execute the original nginx entrypoint
exec "$@"
