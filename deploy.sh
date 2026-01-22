#!/bin/bash

echo "开始一键部署..."

# 替换 Token 和域名（手动改这里）
CF_TOKEN="your-token-here"  # ← 替换成你的 Token
DOMAIN="gerat.gerat.cc.cd"  # ← 替换成你的域名

# 更新 init-service.sh 的 Token
sed -i "s/your-token-here/$CF_TOKEN/g" init-service.sh

# 更新 index.js 的域名
sed -i "s/'gerat.gerat.cc.cd'/'$DOMAIN'/g" index.js

# 赋予权限
chmod +x init-service.sh

# 启动
node index.js &

echo "部署完成！"
echo "查看链接: ls /home/container/links/"
echo "查看隧道日志: tail -f /tmp/.logs/t.log"