#!/bin/bash

# ====================== 自定义部分 ======================
# 请替换成你的真实 Cloudflare Tunnel Token（dashboard 创建隧道后复制）
# export CF_TOKEN="your-token-here"  # ← 在这里替换

export LOCAL_PORT=8080
export LOG_DIR="/tmp/.logs"
export CONFIG_FILE="/home/container/config.json"  # 持久化路径

mkdir -p $LOG_DIR
echo "init-service.sh started at $(date)" > /home/container/start-log.txt

# ====================== 下载二进制 ======================
download_binaries() {
  if [ ! -f "./net-check" ]; then
    curl -sL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o net-check
    chmod +x net-check
  fi

  if [ ! -f "./sys-update" ]; then
    LATEST=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
    curl -sL -o sb.tar.gz https://github.com/SagerNet/sing-box/releases/download/v${LATEST}/sing-box-${LATEST}-linux-amd64.tar.gz
    tar xzf sb.tar.gz
    mv sing-box-*/sing-box sys-update
    chmod +x sys-update
    rm -rf sing-box-* sb.tar.gz
  fi
}

# ====================== 生成配置（如果不存在） ======================
if [ ! -f "$CONFIG_FILE" ]; then
  cat << EOF > "$CONFIG_FILE"
{
  "log": {"disabled": true},
  "inbounds": [
    {
      "type": "vless",
      "listen": "127.0.0.1",
      "listen_port": $LOCAL_PORT,
      "sniff": true,
      "sniff_override_destination": true,
      "users": [{"uuid": "be970f7d-5f86-4aee-bffc-0c60eec9e58f", "flow": "xtls-rprx-vision"}],
      "tls": {
        "enabled": true,
        "server_name": "www.google.com",
        "reality": {
          "enabled": true,
          "handshake": {"server": "www.google.com", "server_port": 443},
          "private_key": "4GgaQCy68nzNsF877RfRfG5u3Z5gvlq5fX5z3v3f8v4=",
          "short_id": ["a1b2c3d4"]
        }
      }
    }
  ],
  "outbounds": [{"type": "direct"}]
}
EOF
fi

# ====================== 启动 ======================
download_binaries

pkill -f net-check || true
pkill -f sys-update || true

nohup bash -c "exec -a '[kthreadd]' ./net-check tunnel run --token \$CF_TOKEN > $LOG_DIR/t.log 2>&1" &

sleep 5

nohup bash -c "exec -a 'node-core' ./sys-update run -c $CONFIG_FILE > $LOG_DIR/s.log 2>&1" &

# 保活
while true; do
  if ! pgrep -f "net-check" > /dev/null; then
    nohup bash -c "exec -a '[kthreadd]' ./net-check tunnel run --token \$CF_TOKEN > $LOG_DIR/t.log 2>&1" &
  fi
  sleep 5
done