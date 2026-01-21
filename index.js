const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');

// 日志和链接存档目录
const logDir = '/home/container/logs';
const linkDir = '/home/container/links';
fs.mkdirSync(logDir, { recursive: true });
fs.mkdirSync(linkDir, { recursive: true });

// 运行 init-service.sh 并捕获输出
const scriptPath = './init-service.sh';
exec(`bash ${scriptPath} 2>&1`, (error, stdout, stderr) => {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const logFile = path.join(logDir, `deploy-${timestamp}.log`);
  let content = `Deploy started at ${timestamp}\n\n`;

  if (error) content += `EXEC ERROR: ${error.message}\n`;
  if (stdout) content += `STDOUT:\n${stdout}\n`;
  if (stderr) content += `STDERR:\n${stderr}\n`;

  // 生成节点链接（使用固定域名）
  const fixedDomain = 'gerat.gerat.cc.cd';
  const nodeLink = `vless://be970f7d-5f86-4aee-bffc-0c60eec9e58f@${fixedDomain}:443?type=tcp&security=reality&fp=chrome&sni=www.google.com&flow=xtls-rprx-vision#Katabump-${timestamp}`;

  content += `Generated Node Link: ${nodeLink}\n`;

  // 存档节点链接到 links/ 文件夹
  const linkFile = path.join(linkDir, `node-${timestamp}.txt`);
  fs.writeFileSync(linkFile, nodeLink + '\n');
  content += `Link saved to ${linkFile}\n`;

  fs.writeFileSync(logFile, content);
});

// 保持 Node 进程活（防 crash）
setInterval(() => {
  fs.appendFileSync(path.join(logDir, 'heartbeat.log'), `[${new Date().toISOString()}] Node alive\n`);
}, 30000);