# Katabump Little Sky VLESS + Reality + Cloudflare Tunnel

基于 Little Sky 框架的低资源节点部署（300MB 内存优化），适用于 Katabump / wispbyte 免费容器，使用 Cloudflare Tunnel 固定域名 VLESS + Reality 节点。

## 特点
- 低资源优化（内存管理、垃圾回收、异步队列）
- VLESS + Reality（xtls-rprx-vision + chrome fp + sniff）
- 自动生成节点链接并存档到 links/ 文件夹
- 优雅关闭 + 异常捕获
- 开机自动运行（Node.js 入口 + 服务管理）

## 前提
1. Cloudflare Zero Trust 创建 Tunnel，复制 Token
2. 添加 Public Hostname：Subdomain = gerat, Domain = gerat.cc.cd, Service = HTTP, URL = http://localhost:8080
3. 容器 Startup Command 设为 `node index.js`

## 部署步骤
1. 上传所有文件到 /home/container/
2. 编辑 init-service.sh 第 5 行：替换 CF_TOKEN 为你的真实 Token
3. 编辑 index.js 第 45 行：替换 fixedDomain 为你的固定域名
4. 容器 Startup Command 设为 `node index.js`
5. 点 Start 启动
6. 等 1–2 分钟
7. 查看 /home/container/links/ 文件夹，生成的 node-时间戳.txt 就是节点链接
8. 浏览器打开 https://你的域名 验证（空白/拒绝正常）
9. 客户端导入链接测试 IP 变化

## 节点链接示例（自动生成）
vless://be970f7d-5f86-4aee-bffc-0c60eec9e58f@gerat.gerat.cc.cd:443?type=tcp&security=reality&fp=chrome&sni=www.google.com&flow=xtls-rprx-vision#Katabump-Node

## 注意
- Token 必须替换，域名必须匹配 Public Hostname
- 免费机资源低，进程可能被杀 → 多次 Stop/Start
- 管理员发现异常会停机 → 低调使用

更新日期：2026-01-22