# Little-sky
# Katabump SingBox VLESS + Reality + Cloudflare Tunnel 部署

免费容器（128MB+ 内存）使用 Cloudflare Tunnel + Token 模式，实现固定域名 VLESS + Reality 节点。

## 特点
- 使用真实 Token + Public Hostname（固定域名 gerat.gerat.cc.cd）
- VLESS + Reality（xtls-rprx-vision + chrome fp + sniff 防嗅探）
- 自动生成节点链接并存档到 links/ 文件夹（带时间戳）
- 自动下载最新 sing-box 和 cloudflared
- 开机自动运行（Node.js 入口 + 保活）

## 前提
1. Cloudflare Zero Trust 创建 Tunnel，复制 Token
2. 在 Cloudflare 添加 Public Hostname：
   - Subdomain: gerat
   - Domain: gerat.cc.cd
   - Service: HTTP
   - URL: http://localhost:8080
3. Katabump 容器启动命令设为 `node index.js`

## 部署步骤
1. 上传所有文件
2. 编辑 init-service.sh 第 5 行：把 `your-token-here` 替换成你的真实 Cloudflare Token
3. 容器设置 Startup Command 为 `node index.js`
4. 点 Start 启动容器
5. 等 1–2 分钟
6. 查看 /home/container/sing-log.txt 确认 sing-box 启动（有 "listening on 127.0.0.1:8080"）
7. 查看 /home/container/links/ 文件夹，里面有 node-时间戳.txt（节点链接）
8. 浏览器打开 https://gerat.gerat.cc.cd 应空白或连接拒绝（正常）
9. 用链接在客户端连接测试

## 节点链接示例（自动生成）
vless://be970f7d-5f86-4aee-bffc-0c60eec9e58f@gerat.gerat.cc.cd:443?type=tcp&security=reality&fp=chrome&sni=www.google.com&flow=xtls-rprx-vision#Katabump-Node

## 注意
- Token 必须替换（dashboard 生成）
- 免费机资源低，进程可能被杀 → 多次 Stop/Start 或换容器
- 管理员发现异常会停机 → 低调使用

更新日期：2026-01-21