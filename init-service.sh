#!/bin/bash

set -e

# ====================== 配置部分 ======================
APP_NAME="little-sky-reality"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_USER="${APP_USER:-nobody}"
APP_PID_FILE="/var/run/${APP_NAME}.pid"
APP_LOG_FILE="/var/log/${APP_NAME}/app.log"
APP_ERROR_LOG="/var/log/${APP_NAME}/error.log"

# 环境变量
export NODE_ENV="production"
export LOG_LEVEL="warn"
export NODE_OPTIONS="--expose-gc --max-old-space-size=300"

# 节点配置
export CF_TOKEN="your-token-here"  # ← 替换你的真实 Token
export LOCAL_PORT=8080
export CONFIG_FILE="${APP_DIR}/config.json"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${APP_LOG_FILE}"
}

error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "${APP_ERROR_LOG}" >&2
}

# 初始化目录
init_directories() {
    log "初始化目录..."
    mkdir -p "$(dirname "${APP_LOG_FILE}")"
    mkdir -p "$(dirname "${APP_PID_FILE}")"
    chmod 755 "$(dirname "${APP_LOG_FILE}")"
    log "目录完成"
}

# 检查 Node 版本
check_node_version() {
    log "检查 Node..."
    NODE_VERSION=$(node -v)
    log "Node: ${NODE_VERSION}"
    MAJOR_VERSION=$(echo ${NODE_VERSION} | cut -d'v' -f2 | cut -d'.' -f1)
    if [ ${MAJOR_VERSION} -lt 18 ]; then
        error "Node 版本太低，需要 v18.0.0+"
        exit 1
    fi
}

# 检查依赖
check_dependencies() {
    log "检查依赖..."
    if [ ! -d "${APP_DIR}/node_modules" ]; then
        log "安装 npm 依赖..."
        cd "${APP_DIR}"
        npm install --production
    fi
    log "依赖完成"
}

# 验证文件
validate_app() {
    log "验证文件..."
    if [ ! -f "${APP_DIR}/index.js" ]; then
        error "找不到 index.js"
        exit 1
    fi
    log "验证通过"
}

# 启动服务
start_service() {
    log "启动 ${APP_NAME}..."
    
    if [ -f "${APP_PID_FILE}" ]; then
        OLD_PID=$(cat "${APP_PID_FILE}")
        if kill -0 "${OLD_PID}" 2>/dev/null; then
            error "已在运行 (PID: ${OLD_PID})"
            return 1
        else
            log "清理 PID"
            rm -f "${APP_PID_FILE}"
        fi
    fi
    
    nohup node ${NODE_OPTIONS} "${APP_DIR}/index.js" > "${APP_LOG_FILE}" 2> "${APP_ERROR_LOG}" &
    
    NEW_PID=$!
    echo ${NEW_PID} > "${APP_PID_FILE}"
    
    log "启动 (PID: ${NEW_PID})"
    sleep 2
    
    if ! kill -0 "${NEW_PID}" 2>/dev/null; then
        error "启动失败"
        tail -20 "${APP_ERROR_LOG}"
        exit 1
    fi
    
    log "验证成功"
}

# 停止服务
stop_service() {
    log "停止 ${APP_NAME}..."
    
    if [ ! -f "${APP_PID_FILE}" ]; then
        log "未运行"
        return 0
    fi
    
    PID=$(cat "${APP_PID_FILE}")
    
    if ! kill -0 "${PID}" 2>/dev/null; then
        log "进程不存在，清理 PID"
        rm -f "${APP_PID_FILE}"
        return 0
    fi
    
    log "发送 SIGTERM ${PID}"
    kill -TERM "${PID}"
    
    for i in {1..30}; do
        if ! kill -0 "${PID}" 2>/dev/null; then
            log "优雅关闭"
            rm -f "${APP_PID_FILE}"
            return 0
        fi
        sleep 1
    done
    
    log "发送 SIGKILL"
    kill -KILL "${PID}"
    rm -f "${APP_PID_FILE}"
    log "已停止"
}

# 重启
restart_service() {
    log "重启 ${APP_NAME}..."
    stop_service
    sleep 2
    start_service
}

# 状态
status_service() {
    if [ ! -f "${APP_PID_FILE}" ]; then
        echo "${APP_NAME} 未运行"
        return 1
    fi
    
    PID=$(cat "${APP_PID_FILE}")
    
    if kill -0 "${PID}" 2>/dev/null; then
        echo "${APP_NAME} 运行中 (PID: ${PID})"
        
        if command -v ps &> /dev/null; then
            MEM=$(ps aux | grep "[${PID:0:1}]${PID:1}" | awk '{print $6}')
            echo "内存: ${MEM}KB"
        fi
        return 0
    else
        echo "${APP_NAME} 未运行 (PID 存在但进程退出)"
        return 1
    fi
}

# 日志
show_logs() {
    if [ -f "${APP_LOG_FILE}" ]; then
        echo "=== 应用日志 (最后50行) ==="
        tail -50 "${APP_LOG_FILE}"
    else
        echo "日志不存在"
    fi
}

show_errors() {
    if [ -f "${APP_ERROR_LOG}" ]; then
        echo "=== 错误日志 (最后50行) === "
        tail -50 "${APP_ERROR_LOG}"
    else
        echo "错误日志不存在"
    fi
}

# 主入口
usage() {
    cat << EOF
用法: $0 {命令}

命令:
  init      初始化
  start     启动
  stop      停止
  restart   重启
  status    状态
  logs      查看日志
  errors    查看错误
  help      帮助

EOF
}

main() {
    case "${1:-help}" in
        init)
            init_directories
            check_node_version
            check_dependencies
            validate_app
            log "初始化完成！用 '$0 start' 启动"
            ;;
        start)
            init_directories
            validate_app
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            restart_service
            ;;
        status)
            status_service
            ;;
        logs)
            show_logs
            ;;
        errors)
            show_errors
            ;;
        help|*)
            usage
            ;;
    esac
}

main "$@"