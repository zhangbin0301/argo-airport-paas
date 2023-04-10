FROM node:latest
EXPOSE 3000
WORKDIR /app
COPY . .
RUN apt-get update &&\
    apt-get install -y iproute2 coreutils systemd &&\
    npm install -r package.json &&\
    npm install -g pm2 &&\
    wget -nv -O cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb &&\
    dpkg -i cloudflared.deb &&\
    rm -f cloudflared.deb &&\
    chmod +x web.js &&\
    wget -nv -O /tmp/apps.zip https://github.com/XrayR-project/XrayR/releases/latest/download/XrayR-linux-64.zip && \
    mkdir /app/apps && \
    unzip -d /app/apps /tmp/apps.zip && \
    mv /app/apps/XrayR /app/apps/myapps && \
    rm -f /tmp/apps.zip && \
    chmod a+x /app/apps/myapps && \
    rm -rf /app/apps/config.yml

ENTRYPOINT [ "node", "server.js" ]