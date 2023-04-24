#!/bin/bash

# 安装cloudflared
wget -nv -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
mv cloudflared /usr/local/bin 
rm -f cloudflared
chmod +x web.js

# 安装myapps 
wget -nv -O /tmp/apps.zip https://github.com/XrayR-project/XrayR/releases/latest/download/XrayR-linux-64.zip
mkdir /app/apps
unzip -d /app/apps /tmp/apps.zip 
mv /app/apps/XrayR /app/apps/myapps
rm -rf /app/apps/README.md 
rm -rf /app/apps/LICENSE
rm -rf /app/apps/config.yml
rm -f /tmp/apps.zip

# 安装node依赖
npm install -r package.json  
npm install -g pm2  

# 安装nezha代理
URL=$(wget -qO- -4 "https://api.github.com/repos/naiba/nezha/releases/latest" | grep -o "https.*linux_amd64.zip")
wget -t 2 -T 10 -N ${URL}
unzip -qod ./ nezha-agent_linux_amd64.zip
rm -f nezha-agent_linux_amd64.zip

# 添加执行权限
chmod +x /usr/local/bin/cloudflared  
chmod +x /app/apps/myapps
chmod +x /app/nezha-agent
chmod +x /app/entrypoint.sh


# 运行node服务器
node server.js
