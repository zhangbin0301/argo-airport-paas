const port = process.env.PORT || 3000;
const url = process.env.RENDER_EXTERNAL_HOSTNAME || "localhost:" + port;
const express = require("express");
const app = express();
var exec = require("child_process").exec;
const os = require("os");
const { createProxyMiddleware } = require("http-proxy-middleware");
var fs = require("fs");
const https = require('https');
const pm2 = require('pm2');

const urls = [
  'https://hello-world-jsx.deno.dev/',
  'https://hello-world.com/'
];

app.get("/", function (req, res) {
  const url = process.env.FAKE_URL || urls[Math.floor(Math.random() * urls.length)];
  https.get(url, function (response) {
    let data = '';
    response.on('data', function (chunk) {
      data += chunk;
    });
    response.on('end', function () {
      res.send(data.replace(/Deno Land!/g, 'Hello World'));
    });
  })
    .on('error', function (err) {
      console.log(err);
      res.send('Hello World!');
    });
});

app.get("/health", function (req, res) {
  res.send("ok");
  console.log(`[${new Date()}] Health Check!`)
});

app.get("/status", (req, res) => {
  let cmdStr = "pm2 ls && ps -ef | grep  -v 'defunct' && ls -l / && ls -l";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>获取系统进程表：\n" + stdout + "</pre>");
    }
  });
});

app.get("/env", (req, res) => {
  let cmdStr = "whoami && printenv";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>获取系统环境变量：\n" + stdout + "</pre>");
    }
  });
});

app.get("/ip", (req, res) => {
  let cmdStr = "curl -s https://www.cloudflare.com/cdn-cgi/trace && \n ip addr && \n ifconfig";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>获取系统IP地址：\n" + stdout + "</pre>");
    }
  });
});

app.get("/listen", (req, res) => {
  let cmdStr = "ss -nltp && ss";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>获取系统监听端口：\n" + stdout + "</pre>");
    }
  });
});

app.get("/list", (req, res) => {
  let cmdStr = "bash argo.sh && cat list";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.type("html").send("<pre>命令行执行错误：\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>优选IP节点数据：\n\n" + stdout + "</pre>");
    }
  });
});

app.get("/start", (req, res) => {
  let cmdStr =
    "[ -e entrypoint.sh ] && /bin/bash entrypoint.sh >/dev/null 2>&1 &";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.send("Web 执行错误：" + err);
    } else {
      res.send("Web 执行结果：" + "启动成功!");
    }
  });
});

app.get("/pm2", (req, res) => {
  let cmdStr = "[ -e ecosystem.config.js ] && pm2 start";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.send("PM2 执行错误：" + err);
    } else {
      res.send("PM2 执行结果：" + stdout + "启动成功!");
    }
  });
});

app.get("/web", (req, res) => {
  let cmdStr = "pm2 start web";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.send("Web 执行错误：" + err);
    } else {
      res.send("Web 执行结果：" + "启动成功!");
    }
  });
});

app.get("/argo", (req, res) => {

  let cmdStr = "pm2 start argo";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.send("Argo 部署错误：" + err);
    } else {
      res.send("Argo 执行结果：" + "启动成功!");
    }
  });
});

app.get("/nezha", (req, res) => {

  let cmdStr = "pm2 start nztz";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.send("哪吒部署错误：" + err);
    } else {
      res.send("哪吒执行结果：" + "启动成功!");
    }
  });
});

app.get("/apps", (req, res) => {
  let cmdStr = "pm2 start apps";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.send("Apps 部署错误：" + err);
    } else {
      res.send("Apps 执行结果：" + "启动成功!");
    }
  });
});

app.get("/info", (req, res) => {
  let cmdStr = "cat /etc/*release | grep -E ^NAME";
  exec(cmdStr, function (err, stdout, stderr) {
    if (err) {
      res.send("命令行执行错误：" + err);
    } else {
      res.send(
        "命令行执行结果：\n" +
        "Linux System:" +
        stdout +
        "\nRAM:" +
        os.totalmem() / 1000 / 1000 +
        "MB"
      );
    }
  });
});

app.get("/test", (req, res) => {
  fs.writeFile("./test.txt", "这里是新创建的文件内容!", function (err) {
    if (err) res.send("创建文件失败，文件系统权限为只读：" + err);
    else res.send("创建文件成功，文件系统权限为非只读：");
  });
});

function keep_web_alive() {

  exec("curl -m8 http://" + url, function (err, stdout, stderr) {
    if (err) {
      console.log("curl error: " + err);
    } else {
      console.log("curl success: " + stdout);
    }
  });

  exec("pgrep -laf PM2", function (err, stdout, stderr) {
    if (!err) {
      if (stdout.indexOf("God Daemon") != -1) {
        console.log("pm2 already running");
      } else {
        exec(
          "[ -e ecosystem.config.js ] && pm2 start >/dev/null 2>&1",
          function (err, stdout, stderr) {
            if (err) {
              console.log("pm2 start error: " + err);
            } else {
              console.log("pm2 start success: " + stdout);
            }
          }
        );
      }
    } else {
      console.log("pgrep error: " + err);
    }
  });
}

var random_interval = Math.floor(Math.random() * 70) + 1;
setTimeout(keep_web_alive, random_interval * 1000);

const ARGO_SCRIPT = 'pm2 start argo'
function keepArgoAlive() {
  pm2.list((err, list) => {
    if (!err && list.find(app => app.name === 'argo')) {

    } else {
      exec(ARGO_SCRIPT, (err, stdout, stderr) => {
        if (err) {
          console.log(`[${new Date()}] Failed to start Argo: ${err}! Retrying...`)
          setTimeout(keepArgoAlive, random_interval * 1000)
        } else {
          console.log(`[${new Date()}] Argo started!`)
        }
      })
    }
  })
}

setInterval(keepArgoAlive, random_interval * 6000)

const NEZHA_SERVER = process.env.NEZHA_SERVER;
const NEZHA_PORT = process.env.NEZHA_PORT;
const NEZHA_KEY = process.env.NEZHA_KEY;

if (NEZHA_SERVER && NEZHA_PORT && NEZHA_KEY) {
  const NEZHA_SCRIPT = 'pm2 start nztz';
  function keepNezhaAlive() {
    pm2.list((err, list) => {
      if (!err && list.find(app => app.name === 'nztz')) {

      } else {
        exec(NEZHA_SCRIPT, (err, stdout, stderr) => {
          if (err) {
            console.log(`[${new Date()}] Failed to start Nezha: ${err}! Retrying...`);
            setTimeout(keepNezhaAlive, random_interval * 1000);
          } else {
            console.log(`[${new Date()}] Nezha started!`);
          }
        });
      }
    });
  }

  setInterval(keepNezhaAlive, random_interval * 6000);
}

const targetHostname = process.env.TARGET_HOSTNAME_URL || "http://127.0.0.1:8081";
const protocol = targetHostname.startsWith("https") ? "https" : "http";

const proxyMiddlewareOptions = {
  target: `${protocol}://${targetHostname.replace(/^https?:\/\//, "")}`,
  changeOrigin: true,
  ws: true,
  secure: false,
  rejectUnauthorized: false,
  pathRewrite: {
    "^/": "/",
  },
  onProxyReq: function onProxyReq(proxyReq, req, res) { },
  logLevel: "silent",
};

app.use("/", createProxyMiddleware(proxyMiddlewareOptions));

exec("bash entrypoint.sh", function (err, stdout, stderr) {
  if (err) {
    console.error(err);
    return;
  }
});

app.listen(port);