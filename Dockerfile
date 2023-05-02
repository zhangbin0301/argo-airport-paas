FROM node:alpine
EXPOSE 3000
WORKDIR /app
# COPY . .
COPY web.js /app/web.js
COPY server.js /app/server.js
COPY package.json /app/package.json
COPY entrypoint.sh /app/entrypoint.sh
# ENV APP_BINARY_NAME="myapps"
ENV TZ="Asia/Shanghai"
ENV NODE_ENV="production"
RUN apk update && \
    apk upgrade && \
    # Set timezone
    apk add --no-cache tzdata && \
    ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone &&\
    # Install dependencies
    apk add iproute2 coreutils curl wget sudo supervisor openssh-server bash &&\ 
    # Clean up
    rm -rf /var/cache/apk/* &&\
    wget -nv -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 &&\
    mv cloudflared /usr/local/bin &&\
    rm -f cloudflared &&\
    chmod +x web.js &&\
    wget -nv -O /tmp/apps.zip https://github.com/XrayR-project/XrayR/releases/latest/download/XrayR-linux-64.zip && \
    mkdir /app/apps && \
    unzip -d /app/apps /tmp/apps.zip && \
    mv /app/apps/XrayR /app/apps/myapps && \
    rm -rf /app/apps/README.md && \
    rm -rf /app/apps/LICENSE && \
    rm -rf /app/apps/config.yml && \
    rm -f /tmp/apps.zip && \
    npm install -r package.json &&\
    npm install -g pm2 &&\
    URL=$(wget -qO- -4 "https://api.github.com/repos/naiba/nezha/releases/latest" | grep -o "https.*linux_amd64.zip") &&\
    wget -t 2 -T 10 -N ${URL} &&\
    unzip -qod ./ nezha-agent_linux_amd64.zip &&\
    rm -f nezha-agent_linux_amd64.zip &&\
    chmod +x /usr/local/bin/cloudflared &&\
    chmod +x /app/apps/myapps &&\
    chmod +x /app/nezha-agent &&\
    chmod +x /app/entrypoint.sh &&\
    # Set root password and enable password login  
    echo 'root:password' | chpasswd &&\
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config &&\
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
# 启用 systemd init 系统
ENV init /lib/systemd/systemd
# CMD ["/lib/systemd/systemd"]
# CMD ["/usr/sbin/sshd", "-D"]
ENTRYPOINT ["node", "server.js"]
