#!/bin/bash

echo "Starting one-click deployment..."

CF_TOKEN="eyJhIjoiNmI5MGYyNWIzOGFlYTM3MzExODE3OTRjOTliYzgxOGYiLCJ0IjoiNTc4NzE2Y2UtMThjZS00ZDhjLTliMmItMDhhMTllMGYyZGVmIiwicyI6Ik5tTXdZakZpT1dVdE1EUTJPQzAwWldaaUxXRTFabUV0WVRjeE9ESmxOR1EyT1dOaiJ9"               # Replace with your Token
FIXED_DOMAIN="gerat.gerat.cc.cd"         # Replace with your domain

sed -i "s/your-token-here/$CF_TOKEN/g" init-service.sh
sed -i "s/'gerat.gerat.cc.cd'/'$FIXED_DOMAIN'/g" index.js

chmod +x init-service.sh

npm install --production

echo "Starting node index.js..."
nohup node index.js > output.log 2>&1 &

echo "Deployment complete!"
echo "Check links: ls /home/container/links/"
echo "Check tunnel log: tail -f /tmp/.logs/t.log"