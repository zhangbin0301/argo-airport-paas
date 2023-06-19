# argo-airport-paas

本项目是基于 [Argo-X-Container-PaaS](https://github.com/fscarmen2/Argo-X-Container-PaaS) 修改而来

1. 加入了 [v2board](https://github.com/v2board/v2board) 的支持，可以直接使用 v2board 的 API 来管理节点。
2. 加入了随机文件名的支持，可以防止被封号。
3. 使用 K8S 部署 For deploy: [paas-deploy](https://github.com/3Kmfi6HP/paas-deploy) 不需要自己编译镜像，直接使用已经编译好的镜像，缩短 paas deploy 的时间。

## 部署方法

1. 新建一个仓库 创建一个名为 `Dockerfile` 的文件 内容如下 然后到 paas 平台部署创建的仓库

   ```Dockerfile
   FROM ghcr.io/3kmfi6hp/argo-airport-paas:main
   ```

2. fork 这个仓库部署 [paas-deploy](https://github.com/3Kmfi6HP/paas-deploy)
3. 直接使用本仓库部署 时间可能比较长

## 环境变量说明

**_Nezha 的端口设置为 443 就会自动加 --tls_**

| 变量名                     | 是否必须 | 默认值                                         | 备注                                                                                                        |
| -------------------------- | -------- | ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| UUID                       | 否       | de04add9-5c68-8bab-950c-08cd5320df18           | 可在线生成[https://www.zxgj.cn/g/uuid](https://www.zxgj.cn/g/uuid) 或者用 V2rayN                            |
| WSPATH                     | 否       | argo                                           | 勿以 / 开头，各协议路径为 `/WSPATH-协议`，如 `/argo-vless`,`/argo-vmess`,`/argo-trojan`,`/argo-shadowsocks` |
| PORT                       | 否       | 3000                                           | 容器默认 listen 0.0.0.0  的端口                                                                             |
| NEZHA_SERVER               | 否       |                                                | Nezha 的服务地址                                                                                            |
| NEZHA_PORT                 | 否       |                                                | Nezha 的服务端口                                                                                            |
| NEZHA_KEY                  | 否       |                                                | Nezha 的 key                                                                                                |
| ARGO_AUTH                  | 否       |                                                | Argo 项目的认证信息 TOKEN 值                                                                                |
| ARGO_DOMAIN                | 否       |                                                | Argo 的域名，须与 ARGO_DOMAIN 必需一起填了才能生效                                                          |
| TARGET_HOSTNAME_URL        | 否       | [http://127.0.0.1:8081](http://127.0.0.1:8081) | 使用 v2board 时候可以自定义设置                                                                             |
| MAX_MEMORY_RESTART         | 否       | 128MB                                          | PM2 重启时的内存阈值 限制内存使用                                                                           |
| SSH_PUB_KEY                | 否       |                                                | 设置 Public Key 用于 ssh 连接 一般不需要设置<br />除非你需要 ssh 连接 例如  ssh-rsa AAAAB3NzaC1yc2EAAA...   |
| TUNNEL_TRANSPORT_PROTOCOL  | 否       | quic                                           | 设置 cloudflared 传输协议<br />默认为 quic 可选 http2 <br />对于某些网络不稳定的情况可以尝试 http2          |
| **接入 v2bord 用到的变量** | -        | -                                              |                                                                                                             |
| API_HOST                   | 是       |                                                | v2board API 服务的域名 URL<br />格式是[https://example.com](https://example.com) \*必须                     |
| API_KEY                    | 是       |                                                | 在 v2board 获取\*必须                                                                                       |
| CERT_DOMAIN                | 否       |                                                | example.com 域名可以顺便填 或者不填                                                                         |
| NODE_ID                    | 是       |                                                | 节点 ID 在 v2board 获取\*必须                                                                               |

## 示例配置

假设有如下配置：

- UUID: `12345678-1234-5678-1234-567812345678`
- WSPATH: `argo`
- PORT: `3000`
- API_HOST: `https://example.com`
- API_KEY: `abcdefghijklmnopqrstuvwxyz`
- NODE_ID: `1`

则可以在部署时设置对应的环境变量，部署完成后，将会得到一个运行在 3000 端口的服务，支持 VLESS、VMess、Trojan 和 Shadowsocks 协议，并使用 `/argo-vless`, `/argo-vmess`, `/argo-trojan`, `/argo-shadowsocks` 作为各协议的路径。同时，该服务将接入 v2board 进行管理。

## 用到的路径 path

| 命令           | 说明                  |
| -------------- | --------------------- |
| `<URL>`/list   | 查看节点数据          |
| `<URL>`/status | 查看后台进程 目录权限 |
| `<URL>`/listen | 查看后台监听端口      |
| `<URL>`/test   | 测试是否为只读系统    |
| `<URL>`/ip     | 查看 IP 网络连接      |
| `<URL>`/env    | 查看系统所有环境变量  |
| `<URL>`/info   | 查看系统信息          |

## 使用 ssh 连接容器

在本地连接容器的 2222 端口的 ssh 需要连接对应容器的节点 IP。

```bash
ssh -p 2222 root@127.0.0.1
```

也可以使用 vscode 的 ssh 插件连接容器，实现远程开发。

```yaml
Host 127.0.0.1
  HostName 127.0.0.1
  Port 2222
  User root # 你的容器用户名
  IdentityFile "C:\Users\username\.ssh\id_rsa" # 你的私钥路径
```

需要在环境变量中设置 SSH_PUB_KEY 为你的公钥
公钥可以在 你的电脑中使用 xshell 生成, 也可以使用以下命令生成

```bash
ssh-keygen -t rsa -b 4096 -C "" -f id_rsa
```

路径一般为 /root/.ssh/id_rsa.pub

## 查看容器信息

打开浏览器访问 `https://argo.example.com/list` 即可查看节点信息 使用 v2board 这个无效
**注意** 请将 argo.example.com 替换为你的容器域名，节点信息里的连接域名已经设置为优选 IP，不需要再另外做修改。

## 注意事项

- 请确保使用支持 WebSocket 的 CDN 服务。
- 使用时，请根据实际情况修改相关配置。
- 请确保端口设置正确，以避免出现无法连接的问题。

## 贡献与支持

如果您在使用过程中遇到问题，请在 [GitHub Issues](https://github.com/3Kmfi6HP/argo-airport-paas/issues) 中提出，我们会尽快回复。同时，您的贡献和建议将帮助我们不断改进这个项目。
