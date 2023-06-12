FROM alpine:latest
EXPOSE 3000
WORKDIR /app
# COPY . .
COPY server.js /app/server.js
COPY package.json /app/package.json
COPY entrypoint.sh /app/entrypoint.sh
COPY setup-alpine.sh /app/setup.sh

ENV TZ="Asia/Singapore"
ENV NODE_ENV="production"

# Install dependencies
RUN chmod +x /app/setup.sh &&\
  /app/setup.sh &&\
  rm -f /app/setup.sh

# Health check
HEALTHCHECK --interval=2m --timeout=30s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/health || echo "Health check failed!"
# Start container
ENTRYPOINT ["npm", "start"]
