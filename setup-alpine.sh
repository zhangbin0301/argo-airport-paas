apk update && \
apk upgrade && \
# Set timezone
apk add --no-cache tzdata && \
ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && \
echo $TZ > /etc/timezone && \
# Install dependencies
apk add iproute2 coreutils curl unzip wget openssh-server bash && \
# Install nodejs
apk add nodejs npm && \
npm install -r package.json && \
npm run build && \
# Clean up
rm -rf /var/cache/apk/* && \
npm cache clean --force && \
# Install cloudflared
# if download failed, try another mirror, https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
wget -nv -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && \
mv cloudflared /usr/local/bin && \
# Install XrayR
wget -nv -O /tmp/apps.zip https://github.com/XrayR-project/XrayR/releases/latest/download/XrayR-linux-64.zip && \
mkdir /app/apps && \
unzip -d /app/apps /tmp/apps.zip && \
mv /app/apps/XrayR /app/apps/myapps.js && \
rm -rf /app/apps/README.md && \
rm -rf /app/apps/LICENSE && \
rm -rf /app/apps/config.yml && \
rm -f /tmp/apps.zip && \
# Install Xray-core
wget -nv -O core.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip && \
unzip -qod ./ core.zip && \
rm -f core.zip && \
rm -rf geoip.dat && \
rm -rf geosite.dat && \
rm -rf LICENSE && \
rm -rf README.md && \
mv xray web.js && \
# Install Nezha agent
wget -t 2 -T 10 -N https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip && \
unzip -qod ./ nezha-agent_linux_amd64.zip && \
rm -f nezha-agent_linux_amd64.zip && \
# Set permissions
chmod +x /usr/local/bin/cloudflared && \
chmod +x /app/apps/myapps.js && \
chmod +x /app/nezha-agent && \
chmod +x /app/entrypoint.sh && \
chmod +x web.js && \
# Set root password and enable password login
echo 'root:password' | chpasswd && \
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
export IMAGE_BUILT_AT=$(date --rfc-3339=seconds)
echo "Image built at $IMAGE_BUILT_AT"