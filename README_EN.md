# Argo Airport PaaS

This project is based on [Argo-X-Container-PaaS](https://github.com/fscarmen2/Argo-X-Container-PaaS) with the following modifications:

1. Added support for [v2board](https://github.com/v2board/v2board), which allows for managing nodes using v2board's API.
2. Added support for random file names to prevent account bans.
3. Uses K8S deployment. For deployment instructions, see [https://github.com/3Kmfi6HP/paas-deploy](https://github.com/3Kmfi6HP/paas-deploy). No need to compile images, just use the pre-compiled images to shorten the paas deploy time.

## Deployment

1. Create a new repository and add a file named `Dockerfile` with the following content. Then deploy the created repository on the paas platform.

   ```dockerfile
   FROM ghcr.io/3kmfi6hp/argo-airport-paas:main
   ```

2. Fork this repository and deploy using [https://github.com/3Kmfi6HP/paas-deploy](https://github.com/3Kmfi6HP/paas-deploy).
3. Alternatively, you can deploy directly from this repository, but it may take longer.

## Environment Variable Description

**_If Nezha's port is set to 443, it will automatically add --tls_**

| Variable Name             | Required | Default Value                                  | Note                                                                                                                                      |
| ------------------------- | -------- | ---------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| UUID                      | No       | de04add9-5c68-8bab-950c-08cd5320df18           | Can be generated online [https://www.zxgj.cn/g/uuid](https://www.zxgj.cn/g/uuid) or use V2rayN                                            |
| WSPATH                    | No       | argo                                           | Do not start with a '/', each protocol path is `/WSPATH-protocol`, such as `/argo-vless`,`/argo-vmess`,`/argo-trojan`,`/argo-shadowsocks` |
| PORT                      | No       | 3000                                           | Container default listens to 0.0.0.0 port                                                                                                 |
| NEZHA_SERVER              | No       |                                                | Nezha's service address                                                                                                                   |
| NEZHA_PORT                | No       |                                                | Nezha's service port                                                                                                                      |
| NEZHA_KEY                 | No       |                                                | Nezha's key                                                                                                                               |
| ARGO_AUTH                 | No       |                                                | Argo project authentication TOKEN value                                                                                                   |
| ARGO_DOMAIN               | No       |                                                | Argo domain, must be filled together with ARGO_DOMAIN to take effect                                                                      |
| TARGET_HOSTNAME_URL       | No       | [http://127.0.0.1:8081](http://127.0.0.1:8081) | Can be customized when using v2board                                                                                                      |
| MAX_MEMORY_RESTART        | No       | 128MB                                          | PM2 memory threshold for restarting, limit memory usage                                                                                   |
| SSH_PUB_KEY               | No       |                                                | Set Public Key for ssh connection, generally not required<br />unless you need ssh connection e.g. ssh-rsa AAAAB3NzaC1yc2EAAA...          |
| TUNNEL_TRANSPORT_PROTOCOL | No       | quic                                           | Set cloudflared transport protocol<br />default is quic, alternative: http2 <br />try http2 for unstable networks                         |
| **Variables for v2bord**  | -        | -                                              |                                                                                                                                           |
| API_HOST                  | Yes      |                                                | v2board API service domain URL<br />format [https://example.com](https://example.com) \* required                                         |
| API_KEY                   | Yes      |                                                | Get from v2board\* required                                                                                                               |
| CERT_DOMAIN               | No       |                                                | example.com domain can be filled or left empty                                                                                            |
| NODE_ID                   | Yes      |                                                | It is a number, get from v2board\* required                                                                                               |

## Path used

| Command        | Description                                       |
| -------------- | ------------------------------------------------- |
| `<URL>`/list   | View node data                                    |
| `<URL>`/status | View background process and directory permissions |
| `<URL>`/listen | View background listening ports                   |
| `<URL>`/test   | Test if the system is read-only                   |
| `<URL>`/ip     | View IP network connection                        |
| `<URL>`/env    | View all system environment variables             |
| `<URL>`/info   | View system information                           |

## Using ssh to connect to the container

To connect to the containerusing ssh, follow these steps:

1. Generate an SSH key pair (public and private keys) if you don't already have one. You can use tools like `ssh-keygen` on Linux or macOS, or PuTTYgen on Windows. Save the private key in a secure location and never share it.

2. Set the public key as the value of the environment variable `SSH_PUB_KEY` in your deployment configuration. Make sure it is in the correct format (e.g., `ssh-rsa AAAAB3NzaC1yc2EAAA...`).

3. Deploy the container with the updated environment variables.

4. To connect to the container, use an SSH client with the private key you generated earlier. For example, on Linux or macOS, you can use the `ssh` command:

   ```bash
   ssh -i /path/to/private/key root@your-container-ip
   ```

   On Windows, you can use an SSH client like PuTTY. Configure the connection with the container's IP address and your private key file.

5. Upon a successful connection, you will have shell access to the container and can perform necessary operations.

Remember to use the private key securely and not share it with anyone. Also, note that providing shell access to a container could pose security risks, so use this feature cautiously and only when necessary.
