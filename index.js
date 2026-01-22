const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const logDir = '/home/container/logs';
const linkDir = '/home/container/links';
fs.mkdirSync(logDir, { recursive: true });
fs.mkdirSync(linkDir, { recursive: true });

const scriptPath = './init-service.sh';
exec(`bash ${scriptPath} 2>&1`, (error, stdout, stderr) => {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const logFile = path.join(logDir, `deploy-${timestamp}.log`);
  let content = `Deploy started at ${timestamp}\n\n`;

  if (error) content += `EXEC ERROR: ${error.message}\n`;
  if (stdout) content += `STDOUT:\n${stdout}\n`;
  if (stderr) content += `STDERR:\n${stderr}\n`;

  const fixedDomain = 'gerat.gerat.cc.cd';
  const nodeLink = `vless://be970f7d-5f86-4aee-bffc-0c60eec9e58f@${fixedDomain}:443?type=tcp&security=reality&fp=chrome&sni=www.google.com&flow=xtls-rprx-vision#Katabump-${timestamp}`;

  content += `Generated Node Link: ${nodeLink}\n`;
  console.log('YOUR NODE LINK: ' + nodeLink);

  const linkFile = path.join(linkDir, `node-${timestamp}.txt`);
  fs.writeFileSync(linkFile, nodeLink + '\n');
  content += `Link saved to ${linkFile}\n`;

  fs.writeFileSync(logFile, content);
});

setInterval(() => {}, 60000);