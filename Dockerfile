# Use the latest Alpine Linux image
FROM alpine:latest

# Expose the default port
EXPOSE 3000

# Set the working directory
WORKDIR /app

# Copy required files into the working directory
COPY server.ts package.json tsconfig.json entrypoint.sh setup-alpine.sh /app/

# Set environment variables
ENV TZ="Asia/Singapore"

# Install dependencies and clean up
RUN chmod +x /app/setup-alpine.sh && \
  /app/setup-alpine.sh && \
  rm -f /app/setup-alpine.sh

# set up nodejs production environment
ENV NODE_ENV="production"

# Health check
HEALTHCHECK --interval=2m --timeout=30s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/health || exit 1

# Start container
ENTRYPOINT ["npm", "start"]
