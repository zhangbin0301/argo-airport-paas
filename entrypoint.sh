#!/usr/bin/env bash
# install sshd and generate host keys
if [ -n "$SSH_PUB_KEY" ]; then
    mkdir ${HOME}/custom_ssh
    cat > ${HOME}/custom_ssh/sshd_config << EOF
    Port 2222
    HostKey ${HOME}/custom_ssh/ssh_host_rsa_key
    HostKey ${HOME}/custom_ssh/ssh_host_dsa_key
    AuthorizedKeysFile  ${HOME}/.ssh/authorized_keys
    PasswordAuthentication no
    #PermitEmptyPasswords yes
    PermitRootLogin yes
    PubkeyAuthentication yes
    ## Enable DEBUG log.
    LogLevel DEBUG
    ChallengeResponseAuthentication no
    # UsePAM no
    X11Forwarding yes
    PrintMotd no
    AcceptEnv LANG LC_*
    Subsystem   sftp    /usr/lib/ssh/sftp-server
    PidFile ${HOME}/custom_ssh/sshd.pid
EOF
    ssh-keygen -f ${HOME}/custom_ssh/ssh_host_rsa_key -N '' -t rsa
    ssh-keygen -f ${HOME}/custom_ssh/ssh_host_dsa_key -N '' -t dsa
    mkdir ${HOME}/.ssh
    echo "${SSH_PUB_KEY}" >> ${HOME}/.ssh/authorized_keys
    cat ${HOME}/custom_ssh/ssh_host_rsa_key.pub >> ${HOME}/.ssh/authorized_keys
    cat ${HOME}/custom_ssh/ssh_host_dsa_key.pub >> ${HOME}/.ssh/authorized_keys
    chmod 600 ${HOME}/.ssh/authorized_keys
    chmod 700 ${HOME}/.ssh
    chmod 600 ${HOME}/custom_ssh/*
    chmod 644 ${HOME}/custom_ssh/sshd_config
    /usr/sbin/sshd -f ${HOME}/custom_ssh/sshd_config -D &
fi
# 设置各变量
WSPATH=${WSPATH:-'argo'}
UUID=${UUID:-'de04add9-5c68-8bab-950c-08cd5320df18'}
MAX_MEMORY_RESTART=${MAX_MEMORY_RESTART:-'128M'}
CERT_DOMAIN=${CERT_DOMAIN:-'example.com'}
PANEL_TYPE=${PANEL_TYPE:-'NewV2board'}
ARGO_DOMAIN=${ARGO_DOMAIN:-'example.com'}
NEZHA_RANDOMNAME=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c $(shuf -i 6-20 -n 1))
APPS_RANDOMNAME=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c $(shuf -i 6-20 -n 1))
WEBJS_RANDOMNAME=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c $(shuf -i 6-20 -n 1))
ARGO_RANDOMNAME=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c $(shuf -i 6-20 -n 1))
# change dns to cloudflare
echo -e "nameserver 1.1.1.2\nnameserver 1.0.0.2"> /etc/resolv.conf
generate_config() {
  cat > config.json << EOF
{
    "log":{
        "access":"NULL",
        "error":"NULL",
        "loglevel":"none"
    },
    "inbounds":[
        {
            "port":8081,
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "flow":"xtls-rprx-vision"
                    }
                ],
                "decryption":"none",
                "fallbacks":[
                    {
                        "dest":3001
                    },
                    {
                        "path":"/${WSPATH}-vless",
                        "dest":3002
                    },
                    {
                        "path":"/${WSPATH}-vmess",
                        "dest":3003
                    },
                    {
                        "path":"/${WSPATH}-trojan",
                        "dest":3004
                    },
                    {
                        "path":"/${WSPATH}-shadowsocks",
                        "dest":3005
                    },
                    {
                        "path":"/${WSPATH}-warp",
                        "dest":3006
                    }
                ]
            },
            "streamSettings":{
                "network":"tcp"
            }
        },
        {
            "port":3001,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none"
            }
        },
        {
            "port":3002,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "level":0
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"/${WSPATH}-vless"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3003,
            "listen":"127.0.0.1",
            "protocol":"vmess",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "alterId":0
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"/${WSPATH}-vmess"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3004,
            "listen":"127.0.0.1",
            "protocol":"trojan",
            "settings":{
                "clients":[
                    {
                        "password":"${UUID}"
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"/${WSPATH}-trojan"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3005,
            "listen":"127.0.0.1",
            "protocol":"shadowsocks",
            "settings":{
                "clients":[
                    {
                        "method":"chacha20-ietf-poly1305",
                        "password":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "path":"/${WSPATH}-shadowsocks"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        },
        {
            "port":3006,
            "tag":"WARP-PLUS",
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "level":0
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "path":"/${WSPATH}-warp"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls"
                ],
                "metadataOnly":false
            }
        }
    ],
    "dns":{
        "servers":[
            "https+local://8.8.8.8/dns-query"
        ]
    },
    "outbounds":[
        {
            "protocol":"freedom"
        },
        {
          "protocol": "blackhole",
          "tag": "blocked"
        },
        {
            "protocol": "wireguard",
            "settings": {
                "address": [
                    "172.16.0.2/32",
                    "2606:4700:110:86c2:d7ca:13d:b14a:e7bf/128"
                ],
                "peers": [
                    {
                        "allowedIPs": [
                            "0.0.0.0/0",
                            "::/0"
                        ],
                        "endpoint": "162.159.193.10:2408",
                        "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="
                    }
                ],
                "reserved": [
                    249,
                    159,
                    96
                ],
                "secretKey": "yG/Phr+fhiBR95b22GThzxGs/Fccyl0U9H4X0GwEeHs="
            },
            "tag": "WARP"
        }
    ],
    "routing":{
        "domainStrategy":"AsIs",
        "rules":[
            {
                "type":"field",
                "domain":[
                    "domain:openai.com",
                    "domain:ai.com"
                ],
                "outboundTag":"WARP"
            },
            {
                "type":"field",
                "inboundTag":[
                    "WARP-PLUS"
                ],
                "outboundTag":"WARP"
            }
        ]
    }
}
EOF
}
generate_config_yml() {
    rm -rf apps/config.yml
    rm -rf apps/custom_outbound.json
    rm -rf apps/dns.json
    rm -rf apps/route.json
    cat > apps/route.json << EOF
{
    "domainStrategy": "AsIs",
    "rules": [
        {
            "type": "field",
            "outboundTag": "WARP",
            "domain": [
                "domain:openai.com",
                "domain:ai.com"
            ]
        }
    ]
}
EOF
    cat > apps/dns.json << EOF
{
    "servers": [
        "https+local://1.0.0.1/dns-query",
        "https+local://8.8.4.4/dns-query",
        "https+local://8.8.8.8/dns-query",
        "https+local://9.9.9.9/dns-query",
        "1.1.1.2",
        "1.0.0.2"
    ]
}
EOF
    cat > apps/custom_outbound.json << EOF
[
    {
        "protocol": "wireguard",
        "settings": {
            "address": [
                "172.16.0.2/32",
                "2606:4700:110:86c2:d7ca:13d:b14a:e7bf/128"
            ],
            "peers": [
                {
                    "allowedIPs": [
                        "0.0.0.0/0",
                        "::/0"
                    ],
                    "endpoint": "162.159.193.10:2408",
                    "publicKey": "bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo="
                }
            ],
            "reserved": [
                249,
                159,
                96
            ],
            "secretKey": "yG/Phr+fhiBR95b22GThzxGs/Fccyl0U9H4X0GwEeHs="
        },
        "tag": "WARP"
    }
]
EOF
    cat > apps/config.yml << EOF
Log:
  Level: none # Log level: none, error, warning, info, debug
  AccessPath: # ${PWD}/apps/access.Log
  ErrorPath: # ${PWD}/apps/error.log
DnsConfigPath: ${PWD}/apps/dns.json # Path to dns config
RouteConfigPath: ${PWD}/apps/route.json # Path to route config
InboundConfigPath: # ${PWD}/apps/custom_inbound.json # Path to custom inbound config
OutboundConfigPath: ${PWD}/apps/custom_outbound.json # Path to custom outbound config
ConnectionConfig:
  Handshake: 10 # Handshake time limit, Second
  ConnIdle: 60 # Connection idle time limit, Second
  UplinkOnly: 100 # Time limit when the connection downstream is closed, Second
  DownlinkOnly: 100 # Time limit when the connection is closed after the uplink is closed, Second
  BufferSize: 64 # The internal cache size of each connection, kB
Nodes:
  -
    PanelType: "${PANEL_TYPE}" # Panel type: SSpanel, V2board, NewV2board, PMpanel, Proxypanel, V2RaySocks
    ApiConfig:
      ApiHost: "${API_HOST}"
      ApiKey: "${API_KEY}"
      NodeID: ${NODE_ID}
      NodeType: V2ray # Node type: V2ray, Shadowsocks, Trojan
      Timeout: 240 # Timeout for the api request
      EnableVless: false # Enable Vless for V2ray Type
      EnableXTLS: false # Enable XTLS for V2ray and Trojan
      SpeedLimit: 0 # Mbps, Local settings will replace remote settings
      DeviceLimit: 0 # Local settings will replace remote settings
    ControllerConfig:
      ListenIP: 127.0.0.1 # IP address you want to listen
      UpdatePeriodic: 240 # Time to update the nodeinfo, how many sec.
      EnableDNS: true # Use custom DNS config, Please ensure that you set the dns.json well
      CertConfig:
        CertMode: file # Option about how to get certificate: none, file, http, tls, dns. Choose "none" will forcedly disable the tls config.
        CertDomain: "${CERT_DOMAIN}" # Domain to cert
        CertFile: ${PWD}/ca.pem # Provided if the CertMode is file
        KeyFile: ${PWD}/ca.key
EOF
}
generate_ca() {
    rm -rf ca.pem
    rm -rf ca.pem
    cat > ca.key << EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAoGXGNMOZc+DONcimqNM2mU2Xt+cjSWeHRB0V3c2z9ks38ka7
yXQXUIp8L/4t0YcNNdlAT4KeK1zxaN1NqAfmdkFsZPI5kfd7dGa6+8JG7S3eCc32
cIxtcysQBF41WyASrglTp64xyLzqMLIMACRjaLm5v+s7+c/2Jn91ohjbeLv7L7fk
Eh2/xNmYQJm3eeqHN2tgZjP6RiAXjezCe4JD8LDzc8nGMfSvxwuWNNGTr0G27GfP
WZ4nJeK+FDO1vhkIKX+ENgRu9apnMZO8m37C+VprR1kfc7KGCfjzyTPHZ1/Z04aJ
peVK2e9xv5tqKmL0VspTEIDQcxVCyAkXr0hqowIDAQABAoIBABZyp+6ygUNqbvGw
B0MRbE7AQT+HpbScPJ4Xw/uq0kjh9g5+P8HN8YVgHElLNXZhhEPJB+sYyLIg69hV
QI0HrgVW2qi2DcCT9j8wMXMSmYKQLMcKgDb4MEkx+afi12zNbE/XFlIdWvJRHiV6
hZtvfEon1As8DMTFihmRNRFekTiwPLgWx8X9zaQq9/Rocn6qEjrLCC1Z4PbkRwu9
CcZeOUJuX8xiHb1NeFdfaADjZi4/cKu+4WNbjZcz0TlTx5UFDOHUz8GQH5Zdng8y
4bFAgmyn5maC9HZ+KytsFv4Vm/XJsML8JuNW6jVTF6mj+77r3XekrTD/bBbpH+SK
fiykYeECgYEA8cafnqxsBOKfaK9C6Yh3Ua45F5t3tUTEcGF2w7ttXM5Ufbmct4li
q36i3PvyQoKFG1pPFzF7AmnTfVGtU7bbR4ikbzCrMj7CSCr3tD37pgKUjp8rCxPt
bwHAHNS7HayGmVHITYOsguQ9WlGE0su7VEcunYiVoqp7vCReDhp/78UCgYEAqdWD
5l3VzSNpEqtXSBtNAHsYE6N9ryhJgzlMMq5xIZ4Stmdk7oVsroRB44btoi6ze6nH
E2tSHoRr59vzqDrqMIboNjl9YLTAecUMUmGxdFlKL8O34IfjaShlbg948N0wX/i6
8eeO7VqV7f1Wabzkrwj2HhhB5V+COcgb8gxk70cCgYEAuudIJ9q02oXyo3OxL2WO
j/c2LXjC7r+NeC7wJ9mxbmgWyuZ9LykmvNp1vo2KNz489es3bv+ST0hN9Pf6HNgj
5cXNECO4hGwdtrp4qL6t1iTygNqs5LBwATuCLweI6ySfHNErHjknWDxm7XZNTsOu
OjWY5LFcs9ZFNymKCC8WLd0CgYBQnSzSuE+348sINZRkgbD3PXacO8p4zeK3CweE
NxE0J9gyBLoADg0ceWLdITrC9O/1Dw2TxilgmvKtR9ZMUErBZgfrVTaSJLoIEuRa
ZkzZMVjpezlYtqfXTnl22JlLm3JO273A/Wz2dT0djlbqMeNKwjIw7sq4mbEyxC2f
owp2GQKBgQDi8/BC7GA3DWnBMqYdNBC7qZO0VSSosk8yYkcmzWdpwGhlsGBAdIoT
j3gFKdJxEtMC95Xw2hOFEkmntJJeSUSX39/aUmunSldzpOVhhKHYCfHXIFHa6f8j
HpTTb+23vPb2rj8+goBg9Rt18mBRSp9bk8wlxAGIwqHFUrics+i4pA==
-----END RSA PRIVATE KEY-----
EOF
cat > ca.pem << EOF
-----BEGIN CERTIFICATE-----
MIIDiTCCAnGgAwIBAgIELyBnuTANBgkqhkiG9w0BAQsFADBbMScwJQYDVQQDDB5SZWdlcnkgU2Vs
Zi1TaWduZWQgQ2VydGlmaWNhdGUxIzAhBgNVBAoMGlJlZ2VyeSwgaHR0cHM6Ly9yZWdlcnkuY29t
MQswCQYDVQQGEwJVQTAgFw0yMzAzMjgwMDAwMDBaGA8yMTIzMDMyODEwMjkxOVowSzEXMBUGA1UE
AwwOd3d3LnJlbmRlci5jb20xIzAhBgNVBAoMGlJlZ2VyeSwgaHR0cHM6Ly9yZWdlcnkuY29tMQsw
CQYDVQQGEwJVQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKBlxjTDmXPgzjXIpqjT
NplNl7fnI0lnh0QdFd3Ns/ZLN/JGu8l0F1CKfC/+LdGHDTXZQE+Cnitc8WjdTagH5nZBbGTyOZH3
e3RmuvvCRu0t3gnN9nCMbXMrEAReNVsgEq4JU6euMci86jCyDAAkY2i5ub/rO/nP9iZ/daIY23i7
+y+35BIdv8TZmECZt3nqhzdrYGYz+kYgF43swnuCQ/Cw83PJxjH0r8cLljTRk69Btuxnz1meJyXi
vhQztb4ZCCl/hDYEbvWqZzGTvJt+wvlaa0dZH3Oyhgn488kzx2df2dOGiaXlStnvcb+baipi9FbK
UxCA0HMVQsgJF69IaqMCAwEAAaNjMGEwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAYYw
HQYDVR0OBBYEFHx6uTS/jOqVr7PCuBNhIiCNY0gQMB8GA1UdIwQYMBaAFHx6uTS/jOqVr7PCuBNh
IiCNY0gQMA0GCSqGSIb3DQEBCwUAA4IBAQB1B4JpJmybk8cfHZr/rng6SGs+pUUUxTEUalVTq9j2
L39v4d3M/KCNaMLtO4UTWIZ2nqprB0NP2/3ZCiy4fUx9T0xButQjj0YFe00pDgegEDp+NiJ38MBi
MyFkbXEqJd6ctBM/Qd3jus6DaEsEOvNU/coxViLopntenOdCUfPF31eH5B+myV8XmZxg3tKw2FU9
1EIiTl3gYrnFvY0kMQcp9MWYv/Njl7MSPGvunllNRjeMt/iVq+4X2t3p1ANAURQqKmL/fy79JSDS
TYehJJQC3B5VipbnQNtykE6TQJZrKv2vBVzcFfli9W8gBpD6JN0kc3OMf3txev6BNv3s7S1r
-----END CERTIFICATE-----
EOF
}

generate_argo() {
  cat > argo.sh << ABC
#!/usr/bin/env bash

argo_type() {
  if [[ -n "\${ARGO_AUTH}" && -n "\${ARGO_DOMAIN}" ]]; then
    [[ \$ARGO_AUTH =~ TunnelSecret ]] && echo \$ARGO_AUTH > tunnel.json && echo -e "tunnel: \$(cut -d\" -f12 <<< \$ARGO_AUTH)\ncredentials-file: ${PWD}/tunnel.json" > tunnel.yml
  else
    ARGO_DOMAIN=\$(cat argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
  fi
}

export_list() {
  VMESS="{ \"v\": \"2\", \"ps\": \"Argo-Vmess\", \"add\": \"cdn.chigua.tk\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\${ARGO_DOMAIN}\", \"path\": \"/${WSPATH}-vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"\${ARGO_DOMAIN}\", \"alpn\": \"\" }"

  cat > list << EOF
*******************************************
V2rayN:
----------------------------
vless://${UUID}@cdn.chigua.tk:443?encryption=none&security=tls&sni=\${ARGO_DOMAIN}&type=ws&host=\${ARGO_DOMAIN}&path=%2F${WSPATH}-vless?ed=2048#Argo-Vless
----------------------------
vless://${UUID}@cdn.chigua.tk:443?encryption=none&security=tls&sni=\${ARGO_DOMAIN}&type=ws&host=\${ARGO_DOMAIN}&path=%2F${WSPATH}-warp?ed=2048#Argo-Warp-Plus
----------------------------
vmess://\$(echo \$VMESS | base64 -w0)
----------------------------
trojan://${UUID}@cdn.chigua.tk:443?security=tls&sni=\${ARGO_DOMAIN}&type=ws&host=\${ARGO_DOMAIN}&path=%2F${WSPATH}-trojan?ed=2048#Argo-Trojan
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@cdn.chigua.tk:443" | base64 -w0)@cdn.chigua.tk:443#Argo-Shadowsocks
由于该软件导出的链接不全，请自行处理如下: 传输协议: WS ， 伪装域名: \${ARGO_DOMAIN} ，路径: /${WSPATH}-shadowsocks?ed=2048 ， 传输层安全: tls ， sni: \${ARGO_DOMAIN}
*******************************************
小火箭:
----------------------------
vless://${UUID}@cdn.chigua.tk:443?encryption=none&security=tls&type=ws&host=\${ARGO_DOMAIN}&path=/${WSPATH}-vless?ed=2048&sni=\${ARGO_DOMAIN}#Argo-Vless
----------------------------
vmess://$(echo "none:${UUID}@cdn.chigua.tk:443" | base64 -w0)?remarks=Argo-Vmess&obfsParam=\${ARGO_DOMAIN}&path=/${WSPATH}-vmess?ed=2048&obfs=websocket&tls=1&peer=\${ARGO_DOMAIN}&alterId=0
----------------------------
trojan://${UUID}@cdn.chigua.tk:443?peer=\${ARGO_DOMAIN}&plugin=obfs-local;obfs=websocket;obfs-host=\${ARGO_DOMAIN};obfs-uri=/${WSPATH}-trojan?ed=2048#Argo-Trojan
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@cdn.chigua.tk:443" | base64 -w0)?obfs=wss&obfsParam=\${ARGO_DOMAIN}&path=/${WSPATH}-shadowsocks?ed=2048#Argo-Shadowsocks
*******************************************
Clash:
----------------------------
- {name: Argo-Vless, type: vless, server: cdn.chigua.tk, port: 443, uuid: ${UUID}, tls: true, servername: \${ARGO_DOMAIN}, skip-cert-verify: false, network: ws, ws-opts: {path: /${WSPATH}-vless?ed=2048, headers: { Host: \${ARGO_DOMAIN}}}, udp: true}
----------------------------
- {name: Argo-Vmess, type: vmess, server: cdn.chigua.tk, port: 443, uuid: ${UUID}, alterId: 0, cipher: none, tls: true, skip-cert-verify: true, network: ws, ws-opts: {path: /${WSPATH}-vmess?ed=2048, headers: {Host: \${ARGO_DOMAIN}}}, udp: true}
----------------------------
- {name: Argo-Trojan, type: trojan, server: cdn.chigua.tk, port: 443, password: ${UUID}, udp: true, tls: true, sni: \${ARGO_DOMAIN}, skip-cert-verify: false, network: ws, ws-opts: { path: /${WSPATH}-trojan?ed=2048, headers: { Host: \${ARGO_DOMAIN} } } }
----------------------------
- {name: Argo-Shadowsocks, type: ss, server: cdn.chigua.tk, port: 443, cipher: chacha20-ietf-poly1305, password: ${UUID}, plugin: v2ray-plugin, plugin-opts: { mode: websocket, host: \${ARGO_DOMAIN}, path: /${WSPATH}-shadowsocks?ed=2048, tls: true, skip-cert-verify: false, mux: false } }
*******************************************
EOF
  cat list
}

argo_type
export_list
ABC
}

generate_nezha() {
  cat > nezha.sh << EOF
#!/usr/bin/env bash

# 检测是否已运行
check_run() {
  [[ \$(pgrep -laf ${NEZHA_RANDOMNAME}) ]] && echo "哪吒客户端正在运行中" && exit
}

# 三个变量不全则不安装哪吒客户端
check_variable() {
  [[ -z "\${NEZHA_SERVER}" || -z "\${NEZHA_PORT}" || -z "\${NEZHA_KEY}" ]] && exit
}

# 下载最新版本 Nezha Agent
download_agent() {
  if [ ! -e ${NEZHA_RANDOMNAME} ]; then
    URL="https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_linux_amd64.zip"
    wget -t 2 -T 10 -N \${URL}
    unzip -qod ./ nezha-agent_linux_amd64.zip && rm -f nezha-agent_linux_amd64.zip
  fi
}

check_run
check_variable
download_agent
EOF
}

generate_pm2_file() {
    if [[ -n "${ARGO_AUTH}" && -n "${ARGO_DOMAIN}" ]]; then
        [[ $ARGO_AUTH =~ TunnelSecret ]] && ARGO_ARGS="tunnel --edge-ip-version auto --config tunnel.yml --url http://localhost:8081 run"
        [[ $ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]] && ARGO_ARGS="tunnel --edge-ip-version auto run"
    else
        ARGO_ARGS="tunnel --edge-ip-version auto --no-autoupdate --logfile argo.log --loglevel info --url http://localhost:8081"
    fi
    
    if [ -f "ecosystem.config.js" ]; then
        echo "ecosystem.config.js 文件存在,跳过移动命令"
    else
        nezha_agent_file=${PWD}/nezha-agent
        nezha_agent_new_location=${PWD}/${NEZHA_RANDOMNAME}
        app_binary_name_file=${PWD}/apps/myapps.js
        app_binary_name_new_location=${PWD}/apps/${APPS_RANDOMNAME}.js
        web_js_file=${PWD}/web.js
        web_js_new_location=${PWD}/${WEBJS_RANDOMNAME}.js
        cloudflare_tunnel_file=/usr/local/bin/cloudflared
        cloudflare_tunnel_new_location=/usr/local/bin/${ARGO_RANDOMNAME}
        mv "$nezha_agent_file" "$nezha_agent_new_location"
        mv "$app_binary_name_file" "$app_binary_name_new_location"
        mv "$web_js_file" "$web_js_new_location"
        mv "$cloudflare_tunnel_file" "$cloudflare_tunnel_new_location"
        chmod +x "$app_binary_name_new_location"
        chmod +x "$nezha_agent_new_location"
        chmod +x "$web_js_new_location"
        chmod +x "$cloudflare_tunnel_new_location"
    fi
    [[ $NEZHA_PORT -eq 443 ]] && NEZHA_PORT_TLS='--tls'
    if [[ -z "${API_HOST}" || -z "${API_KEY}" ]]; then
        rm -rf ${PWD}/apps
    cat > ecosystem.config.js << EOF
module.exports = {
"apps":[
    {
        "name":"web",
        "script":"${web_js_new_location} run",
        "error_file": "NULL",
        "out_file": "NULL",
        "autorestart": true,
        "restart_delay": 1000
    },
    {
        "name":"argo",
        "script":"${cloudflare_tunnel_new_location}",
        "args":"${ARGO_ARGS}",
        "error_file": "NULL",
        "out_file": "NULL",
        "env": {
            "TUNNEL_TOKEN": "${ARGO_AUTH}",
        },
        "autorestart": true,
        "restart_delay": 5000
EOF
  [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_PORT}" && -n "${NEZHA_KEY}" ]] && cat >> ecosystem.config.js << EOF
    },
    {
        "name":"nztz",
        "script": "${nezha_agent_new_location}",
        "args":"-s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_PORT_TLS} --report-delay 3",
        "autorestart": true,
        "restart_delay": 1000
EOF
  cat >> ecosystem.config.js << EOF
    }
  ],
   "max_memory_restart": "${MAX_MEMORY_RESTART}"
}
EOF
    else
        rm -rf ${web_js_new_location} config.json
    cat > ecosystem.config.js << EOF
module.exports = {
  "apps": [
    {
        "name": "apps",
        "script": "${app_binary_name_new_location} run",
        "out_file": "NULL",
        "error_file": "NULL",
        "cwd": "${PWD}/apps",
        "autorestart": true,
        "instances": 1,
        "restart_delay": 1000
    },
    {
        "name": "argo",
        "script": "${cloudflare_tunnel_new_location}",
        "args": "${ARGO_ARGS}",
        "out_file": "NULL",
        "error_file": "NULL",
        "env": {
            "TUNNEL_TOKEN": "${ARGO_AUTH}",
        },
        "autorestart": true,
        "instance": 1,
        "restart_delay": 1000
EOF
  [[ -n "${NEZHA_SERVER}" && -n "${NEZHA_PORT}" && -n "${NEZHA_KEY}" ]] && cat >> ecosystem.config.js << EOF
    },
    {
        "name": "nztz",
        "script": "${nezha_agent_new_location}",
        "args": "-s ${NEZHA_SERVER}:${NEZHA_PORT} -p ${NEZHA_KEY} ${NEZHA_PORT_TLS} --report-delay 3",
        "autorestart": true,
        "instance": 1,
        "restart_delay": 1000
EOF
  cat >> ecosystem.config.js << EOF
    }
  ],
   "max_memory_restart": "${MAX_MEMORY_RESTART}"
}
EOF
    fi
}

generate_config
generate_config_yml
generate_ca
generate_argo

if [ -f "ecosystem.config.js" ]; then
    echo "ecosystem.config.js 文件存在,跳过生成命令"
else
    generate_nezha
    generate_pm2_file
fi
[ -e nezha.sh ] && bash nezha.sh
[ -e argo.sh ] && bash argo.sh
[ -e ecosystem.config.js ] && pm2 start
