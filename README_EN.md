# argo-airport-paas

This project is based on [Argo-X-Container-PaaS](https://github.com/fscarmen2/Argo-X-Container-PaaS) with the following modifications:

1. Added support for [v2board](https://github.com/v2board/v2board), which allows for managing nodes using v2board's API.
2. Added support for random file names to prevent account bans.
3. Uses K8S deployment. For deployment instructions, see [https://github.com/3Kmfi6HP/paas-deploy](https://github.com/3Kmfi6HP/paas-deploy). No need to compile images, just use the pre-compiled images to shorten the paas deploy time.

## Deployment

1. Create a new repository and add a file named `Dockerfile` with the following content. Then deploy the created repository on the paas platform.

```dockerfile
FROM ghcr.io/3kmfi6hp/argo-airport-paas:main
```

1. Fork this repository and deploy using [https://github.com/3Kmfi6HP/paas-deploy](https://github.com/3Kmfi6HP/paas-deploy).
2. Alternatively, you can deploy directly from this repository, but it may take longer.

## Environment Variable Description

**_If Nezha's port is set to 443, it will automatically add --tls_**

|       Variable Name       | Required |                 Default Value                  | Note                                                                                                                                      |
| :-----------------------: | :------: | :--------------------------------------------: | :---------------------------------------------------------------------------------------------------------------------------------------- |
|           UUID            |    No    |      de04add9-5c68-8bab-950c-08cd5320df18      | Can be generated online [https://www.zxgj.cn/g/uuid](https://www.zxgj.cn/g/uuid) or use V2rayN                                            |
|          WSPATH           |    No    |                      argo                      | Do not start with a '/', each protocol path is `/WSPATH-protocol`, such as `/argo-vless`,`/argo-vmess`,`/argo-trojan`,`/argo-shadowsocks` |
|           PORT            |    No    |                      3000                      | Container default listens to 0.0.0.0 port                                                                                                 |
|       NEZHA_SERVER        |    No    |                                                | Nezha's service address                                                                                                                   |
|        NEZHA_PORT         |    No    |                                                | Nezha's service port                                                                                                                      |
|         NEZHA_KEY         |    No    |                                                | Nezha's key                                                                                                                               |
|         ARGO_AUTH         |    No    |                                                | Argo project authentication TOKEN value                                                                                                   |
|        ARGO_DOMAIN        |    No    |                                                | Argo domain, must be filled together with ARGO_DOMAIN to take effect                                                                      |
|    TARGET_HOSTNAME_URL    |    No    | [http://127.0.0.1:8081](http://127.0.0.1:8081) | Can be customized when using v2board                                                                                                      |
|    MAX_MEMORY_RESTART     |    No    |                     128MB                      | PM2 memory threshold for restarting, limit memory usage                                                                                   |
|        SSH_PUB_KEY        |    No    |                                                | Set Public Key for ssh connection, generally not required<br />unless you need ssh connection e.g. ssh-rsa AAAAB3NzaC1yc2EAAA...          |
| TUNNEL_TRANSPORT_PROTOCOL |    No    |                      quic                      | Set cloudflared transport protocol<br />default is quic, alternative: http2 <br />try http2 for unstable networks                         |
| **Variables for v2bord**  |    -     |                       -                        |                                                                                                                                           |
|         API_HOST          |   Yes    |                                                | v2board API service domain URL<br />format [https://example.com](https://example.com) \* required                                         |
|          API_KEY          |   Yes    |                                                | Get from v2board\* required                                                                                                               |
|        CERT_DOMAIN        |    No    |                                                | example.com domain can be filled or left empty                                                                                            |
|          NODE_ID          |   Yes    |                                                | It is a number, get from v2board\* required                                                                                               |

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

To connect to the container's ssh on port 2222 locally, you need to connect to the corresponding container's node IP.

```bash
ssh -p 2222 root@127.0.0.1
```

You can also use the ssh plugin for vscode to connect to the container for remote development.

```yaml
Host 127.0.0.1
  HostName 127.0.0.1
  Port 2222
  User root # your container username
  IdentityFile "C:\Users\username\.ssh\id_rsa" # your private key path
```

Set SSH_PUB_KEY in environment variables to your public key
Public key can be generated on your computer using xshell, or you can use the following command

```bash
ssh-keygen -t rsa -b 4096 -C "" -f id_rsa
```

The path is usually /root/.ssh/id_rsa.pub

## View container information

Open your browser and visit `https://argo.example.com/list` to view node information. This is not valid when using v2board.
**Note** Please replace argo.example.com with your container domain. The connection domain inthe table is an example and should not be used directly.

## Troubleshooting

If you encounter issues or need assistance, follow these steps to troubleshoot and resolve common problems:

1. Check the environment variables to ensure they are set correctly.
2. Verify the domain and ports are properly configured.
3. Inspect the logs to identify any errors or issues.
4. Ensure the container is running, and all required processes are active.
5. Test the connection using a different client or device.
6. Consult the documentation or seek assistance from the community if the issue persists.

## Additional Resources

Here are some helpful resources to further assist you with the configuration and management of your container:

- [V2Ray Official Documentation](https://www.v2ray.com/en/)
- [Cloudflare Argo Tunnel Documentation](https://developers.cloudflare.com/argo-tunnel/)
- [Nezha Official Repository](https://github.com/naiba/nezha)
- [v2board Official Repository](https://github.com/v2board/v2board)

Feel free to consult these resources and forums if you need further assistance or have any questions.

### More Information

Visit `https://argo.example.com/info` in the browser to view system information

Visit `https://argo.example.com/env` to view environment variables

Visit `https://argo.example.com/listen` to view listening ports

(If your container's internal service is listening on port 3000, then it will display 3000 here). You can also set the listening port through the environment variable PORT. This will also display the network connection information inside the container, which can be used to troubleshoot network issues.
Other information can be omitted...

## K8S Deployment

File example:
[https://github.com/3Kmfi6HP/argo-airport-paas/blob/main/deploy.example.yaml](https://github.com/3Kmfi6HP/argo-airport-paas/blob/main/deploy.example.yaml)
