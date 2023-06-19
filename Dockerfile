# Use the latest Alpine Linux image
FROM alpine:latest as builder

# Expose the default port
EXPOSE 3000

# Set the working directory
WORKDIR /app

# Copy required files into the working directory
COPY server.ts package.json tsconfig.json entrypoint.sh setup-alpine.sh /app/

# Install dependencies and clean up
RUN chmod +x /app/setup-alpine.sh && \
  /app/setup-alpine.sh && \
  rm -f /app/setup-alpine.sh

FROM alpine:latest
WORKDIR /app
# Set environment variables
ENV TZ=UTC \
  NODE_PATH=/app/node_modules \
  PATH=/app/node_modules/.bin:$PATH \
  TERM=xterm-256color \
  NODE_ENV="production"

COPY --from=builder /app/ /app/

RUN rm -rf node_modules && apk add --no-cache nodejs npm iproute2 coreutils curl wget openssh-server bash openssh-sftp-server && \
  npm ci --only=production && \
  rm -rf /tmp/* /var/tmp/* /var/cache/apk/* /var/cache/distfiles/* && \
  chmod +x /app/entrypoint.sh


# Health check
HEALTHCHECK --interval=2m --timeout=30s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/health || exit 1

# Start container
ENTRYPOINT ["npm", "start"]
