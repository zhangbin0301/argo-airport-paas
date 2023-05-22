# argo-airport-paas

本项目是基于 [Argo-X-Container-PaaS](https://github.com/fscarmen2/Argo-X-Container-PaaS) 修改而来

1. 加入了 [v2board](https://github.com/v2board/v2board) 的支持，可以直接使用 v2board 的 API 来管理节点。
2. 加入了随机文件名的支持，可以防止被封号。
3. 使用K8S部署 For deploy: [https://github.com/3Kmfi6HP/paas-deploy](https://github.com/3Kmfi6HP/paas-deploy) 不需要自己编译镜像，直接使用已经编译好的镜像，缩短 paas deploy 的时间。

## 部署方法

1. 新建一个仓库 创建一个名为 `Dockerfile` 的文件 内容如下 然后到paas平台部署创建的仓库
```Dockerfile
FROM ghcr.io/3kmfi6hp/argo-airport-paas:main
```
2. fork 这个仓库部署 [https://github.com/3Kmfi6HP/paas-deploy](https://github.com/3Kmfi6HP/paas-deploy)

4. 直接使用本仓库部署 时间可能比较长

## 环境变量说明

Nezha 的端口设置为 443 就会自动加 --tls

```env
ARGO_AUTH      # Argo 项目的认证信息TOKEN
ARGO_DOMAIN    # Argo 访问项目的域名
NEZHA_KEY      # Nezha 的 key
NEZHA_PORT     # Nezha 的服务端口
NEZHA_SERVER   # Nezha 的服务地址
PORT           # 容器内服务的端口 一般设置 3000
TARGET_HOSTNAME_URL # 代理目标的网址 不使用 v2board 设置 http://127.0.0.1:8081
MAX_MEMORY_RESTART # PM2重启时的内存阈值
# 以下为 v2board 相关配置
API_HOST       # v2board API 服务的域名URL
API_KEY        # v2board API 的 access key
CERT_DOMAIN    # v2board 证书的域名
NODE_ID        # v2board 节点 ID
```

### 可选择添加

```env
SSH_PUB_KEY # 设置Public Key 用于ssh连接 一般不需要设置 除非你需要ssh连接 ssh-rsa AAAAB3NzaC1yc2EAAA...
TUNNEL_TRANSPORT_PROTOCOL # 设置cloudflared 传输协议 默认为 quic 可选 http2 对于某些网络不稳定的情况可以尝试 http2
```

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

打开浏览器访问 `https://argo.example.com/list` 即可查看节点信息 使用v2board 这个无效
**注意** 请将 argo.example.com 替换为你的容器域名，节点信息里的连接域名已经设置为优选 IP，不需要再另外做修改。

### 更多信息查看

浏览器访问 `https://argo.example.com/info` 查看系统信息

访问 `https://argo.example.com/env` 查看环境变量

访问 `https://argo.example.com/listen` 查看监听端口

(如果你的容器内服务是监听 3000 端口，那么这里就会显示 3000)， 也可以通过环境变量 PORT 来设置监听端口，这里还会显示容器内的网络连接信息，可以用来排查网络问题。
其他信息可以省略...
## K8S 部署
文件示例
[https://github.com/3Kmfi6HP/argo-airport-paas/blob/main/deploy.example.yaml](https://github.com/3Kmfi6HP/argo-airport-paas/blob/main/deploy.example.yaml)
