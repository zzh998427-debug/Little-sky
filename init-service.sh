#!/bin/bash

export CF_TOKEN="eyJhIjoiNmI5MGYyNWIzOGFlYTM3MzExODE3OTRjOTliYzgxOGYiLCJ0IjoiNTc4NzE2Y2UtMThjZS00ZDhjLTliMmItMDhhMTllMGYyZGVmIiwicyI6Ik5tTXdZakZpT1dVdE1EUTJPQzAwWldaaUxXRTFabUV0WVRjeE9ESmxOR1EyT1dOaiJ9"  # Replace with your real Cloudflare Token

export LOCAL_PORT=8080
export LOG_DIR="/tmp/.logs"
export CONFIG_FILE="/home/container/config.json"

mkdir -p $LOG_DIR

if [ ! -f "./cloudflared" ]; then
  curl -sL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o cloudflared
  chmod +x cloudflared
fi

if [ ! -f "./sing-box" ]; then
  LATEST=$(curl -s https://api.github.com/repos/SagerNet/sing-box/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//')
  curl -sL -o sb.tar.gz https://github.com/SagerNet/sing-box/releases/download/v${LATEST}/sing-box-${LATEST}-linux-amd64.tar.gz
  tar xzf sb.tar.gz
  mv sing-box-*/sing-box sing-box
  chmod +x sing-box
  rm -rf sing-box-* sb.tar.gz
fi

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
      "users": [{"uuid": "be970f7d-5f86-4aee-bffc-0c60eec9e58f", "flow": "xtls-rprx-vision"}],
      "tls": {
        "enabled": true,
        "reality": {
          "enabled": true,
          "handshake": {"server": "www.google.com", "server_port": 443},
          "short_id": ["a1b2c3d4"]
        }
      }
    }
  ],
  "outbounds": [{"type": "direct"}]
}
EOF
fi

pkill -f cloudflared || true
pkill -f sing-box || true

nohup ./cloudflared tunnel run --token $CF_TOKEN > $LOG_DIR/t.log 2>&1 &

sleep 5

nohup ./sing-box run -c $CONFIG_FILE > $LOG_DIR/s.log 2>&1 &

while true; do sleep 5; done