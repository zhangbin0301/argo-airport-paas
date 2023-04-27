FROM node:latest
EXPOSE 3000
WORKDIR /app
COPY . .
ENV APP_BINARY_NAME="myapps"
ENV TZ="Asia/Shanghai"
ENV NODE_ENV="production"
RUN apt-get update &&\
    apt-get install -y iproute2 coreutils systemd wget sudo supervisor openssh-server &&\
    # Clean up
    apt-get clean &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* &&\
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
    chmod +x /app/entrypoint.sh
# Set root password and enable password login  
RUN echo 'root:password' | chpasswd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
# 启用 systemd init 系统
ENV init /lib/systemd/systemd
CMD ["/lib/systemd/systemd"]
CMD ["/usr/sbin/sshd", "-D"]
ENTRYPOINT ["node", "server.js"]
