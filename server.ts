import { Request, Response } from 'express';
import express = require('express');
import { createProxyMiddleware } from 'http-proxy-middleware';
import axios from 'axios';
import { exec } from 'child_process';
import * as fs from 'fs';
import * as pm2 from 'pm2';
import basicAuth = require('express-basic-auth');
const ExecBashToken = 'password' || process.env.EXEC_BASH_TOKEN;
const port: number = parseInt(process.env.PORT || '') || 3000;

function getHttpsKeys(): string[] {
  const httpsKeys: string[] = [];
  Object.keys(process.env).forEach(key => {
    if (process.env[key].startsWith('https://') && !process.env[key].includes('localhost') && !process.env[key].includes('registry')) {
      httpsKeys.push(key);
    }
  });
  if (httpsKeys.length > 0) {
    return httpsKeys;
  }
  return [];
}
const url: string =
  process.env.EXTERNAL_HOSTNAME ||
  process.env.RENDER_EXTERNAL_URL ||
  process.env.NF_HOSTS ||
  process.env.SPACE_HOST ||
  getHttpsKeys()[0] ||
  `http://localhost:${port}`;

const urls: string[] = [
  'https://hello-world-jsx.deno.dev/',
  'https://hello-world.com/',
  'https://hello-world.deno.dev/',
  'https://hello-world-go.deno.dev/'
];

const app = express();

const execRoute = (cmdStr: string, res: Response) => {
  exec(cmdStr, function (err, stdout) {
    if (err) {
      res.type('html').send(`<pre>Command execution error:\n${err}</pre>`);
    } else {
      res.type('html').send(`<pre>Command execution result:\n${stdout}</pre>`);
    }
  });
};

app.get('/', async (_req: Request, res: Response) => {
  const url = process.env.FAKE_URL || urls[Math.floor(Math.random() * urls.length)];
  try {
    const { data } = await axios.get(url);
    res.send(data.replace(/Deno Land!/g, 'Hello World!'));
  } catch (err) {
    // console.log(err);
    res.send('Hello World!');
  }
});
app.get('/favicon.ico', (_req: Request, res: Response) => {
  res.type('html').send('');
});
app.get('/favicon.png', (_req: Request, res: Response) => {
  res.type('html').send('');
});
app.get(['/index.html', '/index.php', '/index.htm'], (_req: Request, res: Response) => {
  res.type('html').send('');
});

app.get('/robots.txt', (_req: Request, res: Response) => {
  res.type('text').send(`User-agent: *\nDisallow: /`);
});
app.get('/logs', (_req: Request, res: Response) => {
  execRoute('pm2 logs --time 1h', res);
});
app.get('/logs/:id', (req: Request, res: Response) => {
  execRoute(`pm2 logs --time 1h ${req.params.id}`, res);
});
app.get('/logs/:id/:lines', (req: Request, res: Response) => {
  execRoute(`pm2 logs --time 1h ${req.params.id} --lines ${req.params.lines}`, res);
});
app.get('/logs/:id/:lines/:format', (req: Request, res: Response) => {
  execRoute(`pm2 logs --time 1h ${req.params.id} --lines ${req.params.lines} --format ${req.params.format}`, res);
});

app.post('/bash', (req: Request, res: Response) => {
  const query_cmd = JSON.stringify(req.body.cmd);
  const headers = { Authorization: `Bearer ${ExecBashToken}`, 'Content-Type': 'application/json' };
  axios.post(url, query_cmd, { headers })
    .then(() => {
      execRoute(query_cmd, res);
    })
    .catch((err) => {
      console.log(err);
      res.send('Error executing command');
    });
});

app.get('/health', async (_req: Request, res: Response) => {
  res.send('ok');
  if (!url.startsWith('http://')) {
    await axios.request({ url: `${url}`, method: 'GET', timeout: 5000 });
  }
  console.log(`[${new Date()}] Health Check!`);
});

app.get('/status', (_req: Request, res: Response) => {
  execRoute('pm2 ls && ps -ef | grep -v \'defunct\' && ls -l / && ls -l', res);
});

app.use('/env', basicAuth({
  users: { 'admin': 'password' },
  challenge: true,
}));

app.get('/env', (_req: Request, res: Response) => {
  execRoute('whoami && printenv', res);
});

app.get('/ip', (_req: Request, res: Response) => {
  execRoute('curl -s https://www.cloudflare.com/cdn-cgi/trace & ip addr & ifconfig', res);
});

app.get('/listen', (_req: Request, res: Response) => {
  execRoute('ss -nltp && ss', res);
});

app.get('/list', (_req: Request, res: Response) => {
  execRoute('bash argo.sh && cat list', res);
});

app.get('/start', (_req: Request, res: Response) => {
  execRoute('[ -e entrypoint.sh ] && /bin/bash entrypoint.sh >/dev/null 2>&1 &', res);
});

app.get('/pm2', (_req: Request, res: Response) => {
  execRoute('[ -e ecosystem.config.js ] && pm2 start', res);
});

app.get('/web', (_req: Request, res: Response) => {
  execRoute('pm2 start web', res);
});

app.get('/argo', (_req: Request, res: Response) => {
  execRoute('pm2 start argo', res);
});

app.get('/nezha', (_req: Request, res: Response) => {
  execRoute('pm2 start nztz', res);
});

app.get('/apps', (_req: Request, res: Response) => {
  execRoute('pm2 start apps', res);
});

app.get('/info', (_req: Request, res: Response) => {
  execRoute('cat /etc/*release | grep -E ^NAME', res);
});

app.get('/test', (_req: Request, res: Response) => {
  fs.writeFile('./test.txt', 'This is the newly created file content!', function (err) {
    if (err) res.send('Failed to create file, file system permission is read-only: ' + err);
    else res.send('File created successfully, file system permission is not read-only.');
  });
});

function keep_web_alive() {
  exec('curl -m8 ' + url, function (err, _stdout, _stderr) {
    console.log('fetching ' + url + ' ...');
    if (err) {
      console.log('curl error: ' + err);
    } else {
      console.log('curl success');
    }
  });

  exec('pgrep -laf PM2', function (err, stdout, _stderr) {
    if (!err) {
      if (stdout.indexOf('God Daemon') !== -1) {
        console.log('pm2 already running');
      } else {
        exec('[ -e ecosystem.config.js ] && pm2 start', function (err, stdout, _stderr) {
          if (err) {
            console.log('pm2 start error: ' + err);
          } else {
            console.log('pm2 start success: ' + stdout);
          }
        });
      }
    } else {
      console.log('pgrep error: ' + err);
    }
  });
}

var random_interval = Math.floor(Math.random() * 30) + 1;
setTimeout(keep_web_alive, random_interval * 1000);

const ARGO_SCRIPT = 'pm2 start argo';
function keepArgoAlive() {
  pm2.list((err, list) => {
    if (!err && list.find((app) => app.name === 'argo')) {

    } else {
      exec(ARGO_SCRIPT, (err, stdout, stderr) => {
        if (err) {
          console.log(`[${new Date()}] Failed to start Argo:\n ${err}\n ${stdout}\n ${stderr}\n Retrying...`);
          setTimeout(keepArgoAlive, random_interval * 10000);
        } else {
          console.log(`[${new Date()}] Argo started!`);
        }
      });
    }
  });
}

if (process.env.ARGO_AUTH) {
  setInterval(keepArgoAlive, random_interval * 16000);
}

const NEZHA_SERVER = process.env.NEZHA_SERVER;
const NEZHA_PORT = process.env.NEZHA_PORT;
const NEZHA_KEY = process.env.NEZHA_KEY;
const NEZHA_SCRIPT = 'pm2 start nztz';

function keepNezhaAlive() {
  pm2.list((err, list) => {
    if (!err && list.find((app) => app.name === 'nztz')) {

    } else {
      exec(NEZHA_SCRIPT, (err, _stdout, _stderr) => {
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
if (NEZHA_SERVER && NEZHA_PORT && NEZHA_KEY) {
  setInterval(keepNezhaAlive, random_interval * 6000);
}

let targetHostname = process.env.TARGET_HOSTNAME_URL || 'http://127.0.0.1:8081';
const protocol = targetHostname.startsWith('https') ? 'https' : 'http';

const proxyMiddlewareOptions = {
  target: `${protocol}://${targetHostname.replace('https://', '').replace('http://', '')}`,
  changeOrigin: true,
  ws: true,
  secure: false,
  rejectUnauthorized: false,
  pathRewrite: {
    '^/': '/',
  },
  onProxyReq: function onProxyReq(_proxyReq: any, req: any, _res: any) {
    if (req.headers.upgrade && req.headers.upgrade.toLowerCase() === 'websocket') {
      console.log(`[${new Date()}] Incomming websocket request ${req.method} ${req.url} to ${targetHostname}`);
    } else {
      console.log(`[${new Date()}] Incomming non-websocket request ${req.method} ${req.url} to ${targetHostname}`);
    }
  },
  logLevel: 'silent' as const,
};

app.use('/', createProxyMiddleware(proxyMiddlewareOptions));

try {
  exec('bash entrypoint.sh', function (err, _stdout, _stderr) {
    if (err) {
      return;
    }
  });
} catch (err) {
  console.error(`[${new Date()}] Error executing entrypoint.sh: ${err}`);
}
// show the IP address in the console if server is running
console.log(`[${new Date()}] Server running at ${url}`);
// show the build time from environment variable
try {
  const buildTime = fs.readFileSync('./build_time.txt', 'utf8').trim();
  console.log(`[${new Date()}] Image build time: ${buildTime}`);
} catch (err) {
  console.error(`[${new Date()}] Error reading build_time.txt file: ${err}`);
}
// start the Express server
app.listen(port);
