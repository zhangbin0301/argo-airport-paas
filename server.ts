import { Request, Response } from 'express';
import express = require('express');
import { createProxyMiddleware } from 'http-proxy-middleware';
import axios from 'axios';
import * as fs from 'fs';
import * as pm2 from 'pm2';
import basicAuth = require('express-basic-auth');
import * as util from 'util';
const { promisify } = require('util');
const exec = promisify(require('child_process').exec);

const ExecBashToken = 'password' || process.env.EXEC_BASH_TOKEN;
const port: number = parseInt(process.env.PORT || '') || 3000;

function getHttpsKeys(): string[] {
  const httpsKeys: string[] = [];
  const envEntries = Object.entries(process.env);

  for (let i = 0; i < envEntries.length; i++) {
    const [key, value] = envEntries[i];
    if (/^https:\/\/(?!localhost|127\.0\.0\.1|registry).*$/i.test(value) && !key.includes('API_HOST')) {
      httpsKeys.push(key);
    }
  }

  return httpsKeys.includes('https') ? httpsKeys : [''];
}
const httpsKeys = getHttpsKeys();
if (httpsKeys[0].length > 0) {
  const httpsKey = httpsKeys[0];
  console.log(`[${new Date()}] Find httpsKey: ${httpsKey}`);
} else {
  console.log(`[${new Date()}] No httpsKey found ${httpsKeys[0].length}`);
}
const url: string =
  process.env.EXTERNAL_HOSTNAME ||
  process.env.RENDER_EXTERNAL_URL ||
  process.env.NF_HOSTS ||
  process.env.SPACE_HOST ||
  (httpsKeys[0].length > 0 ? httpsKeys[0] : `http://localhost:${port}`)


const urls: string[] = [
  'https://hello-world-jsx.deno.dev/',
  'https://hello-world.com/',
  'https://hello-world.deno.dev/'
];

const app = express();
app.use(express.json()); // 解析JSON请求体
const execRoute = async (cmdStr: string, res: Response) => {
  try {
    const { stdout } = await exec(cmdStr);
    res.type('html').send(`<pre>Command execution result:\n${stdout}</pre>`);
  } catch (err) {
    res.type('html').send(`<pre>Command execution error:\n${err}</pre>`);
  }
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
  execRoute('pm2 logs --time 1h &', res);
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

const authorize = (req: Request, res: Response, next: express.NextFunction) => {
  if (!req.headers.authorization || req.headers.authorization !== `Bearer ${ExecBashToken}`) {
    res.status(401).send('Unauthorized: Access token is missing or invalid');
    return;
  }
  next();
};

app.post('/bash', authorize, async (req: Request, res: Response) => {
  const { cmd } = req.body;

  if (!cmd) {
    res.status(400).send('Bad Request: Missing or invalid cmd property');
    return;
  }

  try {
    const { stdout, stderr } = await util.promisify(exec)(cmd);
    res.status(200).type("text").send(stdout);
  } catch (error) {
    console.error(`[${new Date()}] Error executing command: ${error}`);
    res.status(500).type("text").send(error.stderr);
  }
});

app.post('/post-test', (req, res) => {
  console.log('Got body:', req.body);
  res.sendStatus(200);
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
  execRoute('whoami && env', res);
});

app.get('/ip', (_req: Request, res: Response) => {
  execRoute('ip addr & ifconfig', res);
});

app.get('/combined', async (_req, res) => {
  const timeout = 5000; // Adjust the timeout value as needed

  try {
    const ipifyResponse = await axios.get('https://api.ipify.org?format=json', { timeout });
    const cloudflareResponse = await axios.get('https://speed.cloudflare.com/meta', { timeout });
    const ipinfoResponse = await axios.get('https://ipinfo.io/json', { timeout });

    const combinedData = {
      ipify: ipifyResponse.data,
      cloudflare: cloudflareResponse.data,
      ipinfo: ipinfoResponse.data
    };

    res.send(combinedData);
  } catch (err) {
    res.status(500).send(err.message);
  }
});
app.get('/process', (_req: Request, res: Response) => {
  const process_data = {
    arch: process.arch,
    platform: process.platform,
    versions: process.versions,
    pid: process.pid,
    ppid: process.ppid,
    execPath: process.execPath,
    execArgv: process.execArgv,
    argv: process.argv,
    cwd: process.cwd(),
    memoryUsage: process.memoryUsage(),
    uptime: process.uptime(),
    features: process.features,
    release: process.release,
    config: process.config,
    title: process.title,
    env: process.env,
    umask: process.umask(),
    hrtime: process.hrtime()
  }
  res.send(JSON.stringify(process_data, null, 2));
});

app.get('/listen', (_req: Request, res: Response) => {
  execRoute('ss -nltp && ss', res);
});

app.get('/list', (_req: Request, res: Response) => {
  execRoute('bash argo.sh && cat list', res);
});

app.get('/start', (_req: Request, res: Response) => {
  execRoute('[ -e entrypoint.sh ] && /bin/bash entrypoint.sh >/dev/null 2>&1', res);
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

async function keep_web_alive() {
  await axios.get(url, { timeout: 8000 })
    .then(() => {
      console.log('axios success');
    })
    .catch((err) => {
      console.log('axios error: ' + err);
    });

  try {
    const { stdout } = await exec('pgrep -laf PM2');
    if (stdout.indexOf('God Daemon') !== -1) {
      console.log('pm2 already running');
    } else {
      const { stdout } = await exec('[ -e ecosystem.config.js ] && pm2 start');
      console.log('pm2 start success: ' + stdout);
    }
  } catch (err) {
    console.log('exec error: ' + err);
  }
}


var random_interval = Math.floor(Math.random() * 30) + 1;
setTimeout(keep_web_alive, random_interval * 1000);

const ARGO_SCRIPT = 'pm2 start argo';
function keepArgoAlive() {
  pm2.list(async (err, list) => {
    if (!err && list.find((app) => app.name === 'argo')) {

    } else {
      const { stdout, stderr } = await exec(ARGO_SCRIPT).catch((err: any) => ({ err }));
      if (stdout && !stderr) {
        console.log(`[${new Date()}] Argo started!`);
      } else {
        console.error(`[${new Date()}] Failed to start Argo:\n ${err.message}\n ${stdout}\n ${stderr}\n Retrying...`);
        setTimeout(keepArgoAlive, random_interval * 10000);
      }
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
  pm2.list(async (err, list) => {
    if (!err && list.find((app) => app.name === 'nztz')) {

    } else {
      // exec(NEZHA_SCRIPT, (err, _stdout, _stderr) => {
      //   if (err) {
      //     console.log(`[${new Date()}] Failed to start Nezha: ${err}! Retrying...`);
      //     setTimeout(keepNezhaAlive, random_interval * 1000);
      //   } else {
      //     console.log(`[${new Date()}] Nezha started!`);
      //   }
      // });
      const { stdout, stderr } = await exec(NEZHA_SCRIPT).catch((err: any) => ({ err }));
      if (stdout && !stderr) {
        console.log(`[${new Date()}] Nezha started!`);
      } else {
        console.error(`[${new Date()}] Failed to start Nezha:\n ${err.message}\n ${stdout}\n ${stderr}\n Retrying...`);
        setTimeout(keepNezhaAlive, random_interval * 10000);
      }
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

if (!process.platform.includes('win')) {
  try {
    exec('bash entrypoint.sh', function (err, _stdout, _stderr) {
      if (err) {
        return;
      }
    });
  } catch (err) {
    console.error(`[${new Date()}] Error executing entrypoint.sh: ${err}`);
  }
} else {
  console.log(`[${new Date()}] Skipping entrypoint.sh execution on Windows`);
}

// show the build time from environment variable
try {
  const buildTime = fs.readFileSync('./build_time.txt', 'utf8').trim();
  console.log(`[${new Date()}] Image build time: ${buildTime}`);
} catch (err) {
  console.error(`[${new Date()}] Error reading build_time.txt file: ${err}`);
}
// start the Express server
app.listen(port, () => {
  // show the IP address in the console if server is running
  console.log(`[${new Date()}] Server running at ${url}`);
});
