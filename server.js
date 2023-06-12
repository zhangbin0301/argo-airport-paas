const port = process.env.PORT || 3000;
const url = process.env.EXTERNAL_HOSTNAME || process.env.SPACE_HOST || "http://localhost:" + port;
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
  'https://hello-world.com/',
  'https://hello-world.deno.dev/'
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
  exec(cmdStr, function (err, stdout) {
    if (err) {
      res.type("html").send("<pre>Command execution error:\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>System process table:\n" + stdout + "</pre>");
    }
  });
});

app.get("/env", (req, res) => {
  let cmdStr = "whoami && printenv";
  exec(cmdStr, function (err, stdout) {
    if (err) {
      res.type("html").send("<pre>Command execution error:\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>System environment variables:\n" + stdout + "</pre>");
    }
  });
});

app.get("/ip", (req, res) => {
  let cmdStr = "curl -s https://www.cloudflare.com/cdn-cgi/trace && \n ip addr && \n ifconfig";
  exec(cmdStr, function (err, stdout) {
    if (err) {
      res.type("html").send("<pre>Command execution error:\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>System IP address:\n" + stdout + "</pre>");
    }
  });
});

app.get("/listen", (req, res) => {
  let cmdStr = "ss -nltp && ss";
  exec(cmdStr, function (err, stdout) {
    if (err) {
      res.type("html").send("<pre>Command execution error:\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>System listening ports:\n" + stdout + "</pre>");
    }
  });
});

app.get("/list", (req, res) => {
  let cmdStr = "bash argo.sh && cat list";
  exec(cmdStr, function (err, stdout) {
    if (err) {
      res.type("html").send("<pre>Command execution error:\n" + err + "</pre>");
    } else {
      res.type("html").send("<pre>Optimized IP node data:\n\n" + stdout + "</pre>");
    }
  });
});

app.get("/start", (req, res) => {
  let cmdStr =
    "[ -e entrypoint.sh ] && /bin/bash entrypoint.sh >/dev/null 2>&1 &";
  exec(cmdStr, function (err) {
    if (err) {
      res.send("Web execution error: " + err);
    } else {
      res.send("Web execution result: " + "Started successfully!");
    }
  });
});

app.get("/pm2", (req, res) => {
  let cmdStr = "[ -e ecosystem.config.js ] && pm2 start";
  exec(cmdStr, function (err, stdout) {
    if (err) {
      res.send("PM2 execution error: " + err);
    } else {
      res.send("PM2 execution result: " + stdout + "Started successfully!");
    }
  });
});

app.get("/web", (req, res) => {
  let cmdStr = "pm2 start web";
  exec(cmdStr, function (err) {
    if (err) {
      res.send("Web execution error: " + err);
    } else {
      res.send("Web execution result: " + "Started successfully!");
    }
  });
});

app.get("/argo", (req, res) => {

  let cmdStr = "pm2 start argo";
  exec(cmdStr, function (err) {
    if (err) {
      res.send("Argo deployment error: " + err);
    } else {
      res.send("Argo execution result: " + "Started successfully!");
    }
  });
});

app.get("/nezha", (req, res) => {

  let cmdStr = "pm2 start nztz";
  exec(cmdStr, function (err) {
    if (err) {
      res.send("Nezha deployment error: " + err);
    } else {
      res.send("Nezha execution result: " + "Started successfully!");
    }
  });
});

app.get("/apps", (req, res) => {
  let cmdStr = "pm2 start apps";
  exec(cmdStr, function (err) {
    if (err) {
      res.send("Apps deployment error: " + err);
    } else {
      res.send("Apps execution result: " + "Started successfully!");
    }
  });
});

app.get("/info", (req, res) => {
  let cmdStr = "cat /etc/*release | grep -E ^NAME";
  exec(cmdStr, function (err, stdout) {
    if (err) {
      res.send("Command execution error: " + err);
    } else {
      res.send(
        "Command execution result:\n" +
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
  fs.writeFile("./test.txt", "This is the newly created file content!", function (err) {
    if (err) res.send("Failed to create file, file system permission is read-only: " + err);
    else res.send("File created successfully, file system permission is not read-only.");
  });
});

function keep_web_alive() {

  exec("curl -m8 " + url, function (err, stdout, stderr) {
    console.log("fetching " + url + " ...");
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
          "[ -e ecosystem.config.js ] && pm2 start",
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
  target: `${protocol}://${targetHostname
    .replace("https://", "")
    .replace("http://", "")}`,
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