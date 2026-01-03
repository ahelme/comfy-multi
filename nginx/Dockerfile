FROM nginx:1.28.1-alpine

# Install envsubst for template processing
RUN apk add --no-cache gettext

# Copy configuration files
COPY nginx.conf /etc/nginx/nginx.conf

# Copy HTML files
COPY index.html /usr/share/nginx/html/index.html
COPY health.html /usr/share/nginx/html/health.html

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80 443

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
