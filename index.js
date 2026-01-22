const os = require('os');
const fs = require('fs');
const path = require('path');
const { EventEmitter } = require('events');
const { exec } = require('child_process');

// ============================================
# 日志系统 - 智能日志等级控制
// ============================================
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';
const LOG_LEVELS = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

class Logger {
  constructor(level = LOG_LEVEL) {
    this.level = LOG_LEVELS[level] || LOG_LEVELS.info;
  }

  debug(msg, data = '') {
    if (this.level <= LOG_LEVELS.debug) {
      console.log(`[${new Date().toISOString()}] [DEBUG]`, msg, data);
    }
  }

  info(msg, data = '') {
    if (this.level <= LOG_LEVELS.info) {
      console.log(`[${new Date().toISOString()}] [INFO]`, msg, data);
    }
  }

  warn(msg, data = '') {
    if (this.level <= LOG_LEVELS.warn) {
      console.warn(`[${new Date().toISOString()}] [WARN]`, msg, data);
    }
  }

  error(msg, error = '') {
    console.error(`[${new Date().toISOString()}] [ERROR]`, msg, error);
  }
}

const logger = new Logger();

// ============================================
# 内存管理系统 - 内存泄漏检测和垃圾回收
// ============================================
class MemoryManager extends EventEmitter {
  constructor(options = {}) {
    super();
    this.maxHeapSize = options.maxHeapSize || 300; // MB
    this.checkInterval = options.checkInterval || 30000; // 30秒
    this.warningThreshold = options.warningThreshold || 0.8; // 80%
    this.criticalThreshold = options.criticalThreshold || 0.95; // 95%
    
    this.start();
  }

  start() {
    this.monitor = setInterval(() => {
      this.checkMemory();
    }, this.checkInterval);
    
    logger.info('内存管理器已启动');
  }

  checkMemory() {
    const memUsage = process.memoryUsage();
    const heapUsedMB = Math.round(memUsage.heapUsed / 1024 / 1024);
    const heapTotalMB = Math.round(memUsage.heapTotal / 1024 / 1024);
    const externalMB = Math.round(memUsage.external / 1024 / 1024);
    
    const heapUsagePercent = heapUsedMB / this.maxHeapSize;
    
    logger.debug('内存统计', {
      heapUsed: `${heapUsedMB}MB`,
      heapTotal: `${heapTotalMB}MB`,
      external: `${externalMB}MB`,
      percentage: `${(heapUsagePercent * 100).toFixed(2)}%`,
    });

    // 警告阈值
    if (heapUsagePercent >= this.warningThreshold) {
      logger.warn(`内存使用率过高: ${(heapUsagePercent * 100).toFixed(2)}%`);
      this.emit('warning', heapUsagePercent);
    }

    // 临界阈值 - 触发垃圾回收
    if (heapUsagePercent >= this.criticalThreshold) {
      logger.error(`内存达到临界值: ${(heapUsagePercent * 100).toFixed(2)}%`);
      this.forceGarbageCollection();
      this.emit('critical', heapUsagePercent);
    }
  }

  forceGarbageCollection() {
    try {
      if (global.gc) {
        global.gc(false);
        logger.warn('手动触发垃圾回收完成');
        this.emit('gc', 'completed');
      } else {
        logger.warn('垃圾回收不可用，请使用 --expose-gc 启动');
      }
    } catch (error) {
      logger.error('垃圾回收失败', error);
    }
  }

  stop() {
    if (this.monitor) {
      clearInterval(this.monitor);
      logger.info('内存管理器已停止');
    }
  }

  getStatus() {
    const memUsage = process.memoryUsage();
    return {
      heapUsed: Math.round(memUsage.heapUsed / 1024 / 1024),
      heapTotal: Math.round(memUsage.heapTotal / 1024 / 1024),
      external: Math.round(memUsage.external / 1024 / 1024),
      rss: Math.round(memUsage.rss / 1024 / 1024),
      uptime: process.uptime(),
    };
  }
}

// ============================================
# CPU 优化 - 异步任务队列系统
// ============================================
class AsyncTaskQueue {
  constructor(options = {}) {
    this.maxConcurrent = options.maxConcurrent || 2;
    this.queue = [];
    this.running = 0;
    logger.info(`异步队列已初始化，最大并发数: ${this.maxConcurrent}`);
  }

  async add(task) {
    return new Promise((resolve, reject) => {
      this.queue.push({ task, resolve, reject });
      this.process();
    });
  }

  async process() {
    if (this.running >= this.maxConcurrent || this.queue.length === 0) {
      return;
    }

    this.running++;
    const { task, resolve, reject } = this.queue.shift();

    try {
      const result = await task();
      resolve(result);
    } catch (error) {
      reject(error);
    } finally {
      this.running--;
      this.process();
    }
  }

  getStatus() {
    return {
      queued: this.queue.length,
      running: this.running,
      maxConcurrent: this.maxConcurrent,
    };
  }
}

// ============================================
# 主应用 - Little Sky + 节点部署逻辑
# ============================================
class LittleSkyApp {
  constructor() {
    this.memoryManager = new MemoryManager();

    this.taskQueue = new AsyncTaskQueue();

    this.setupEventHandlers();
    logger.info('Little Sky 应用已初始化');
  }

  setupEventHandlers() {
    this.memoryManager.on('warning', (usage) => {
      logger.warn(`内存警告: ${(usage * 100).toFixed(2)}%`);
    });

    this.memoryManager.on('critical', (usage) => {
      logger.error(`内存临界: ${(usage * 100).toFixed(2)}%`);
      this.handleMemoryCritical();
    });

    process.on('SIGTERM', () => {
      logger.info('SIGTERM 收到，开始关闭');
      this.shutdown();
    });

    process.on('SIGINT', () => {
      logger.info('SIGINT 收到，开始关闭');
      this.shutdown();
    });

    process.on('uncaughtException', (error) => {
      logger.error('未捕获异常', error);
      this.shutdown();
    });

    process.on('unhandledRejection', (reason) => {
      logger.error('未处理 Promise 拒绝', reason);
    });
  }

  handleMemoryCritical() {
    logger.warn('执行内存应急处理');
    // 加自定义清理
  }

  async start() {
    logger.info('========== Little Sky 启动 ==========');
    logger.info(`Node v: ${process.version}`);
    logger.info(`平台: ${process.platform}`);
    logger.info(`CPU 核心: ${os.cpus().length}`);
    logger.info(`总内存: ${Math.round(os.totalmem() / 1024 / 1024)}MB`);
    logger.info('=====================================');

    try {
      await this.deployNode();
      await this.mainLoop();
    } catch (error) {
      logger.error('启动失败', error);
      this.shutdown();
    }
  }

  async deployNode() {
    logger.info('启动节点部署...');
    // 用异步队列执行部署任务，避免阻塞
    await this.taskQueue.add(() => new Promise((resolve, reject) => {
      exec('bash ./init-service.sh', (error, stdout, stderr) => {
        if (error) reject(error);
        logger.info('部署输出:', stdout);
        resolve();
      });
    }));
    logger.info('节点部署完成');
  }

  async mainLoop() {
    let iteration = 0;

    while (true) {
      try {
        iteration++;
        logger.debug(`迭代 #${iteration}`);

        // 示例任务
        await this.taskQueue.add(async () => {
          logger.debug('执行任务');
          await new Promise(resolve => setTimeout(resolve, 100));
        });

        if (iteration % 60 === 0) {
          this.printStatus();
        }

        await new Promise(resolve => setTimeout(resolve, 1000));
      } catch (error) {
        logger.error('循环错误', error);
        await new Promise(resolve => setTimeout(resolve, 5000));
      }
    }
  }

  printStatus() {
    const memStatus = this.memoryManager.getStatus();
    const taskStatus = this.taskQueue.getStatus();
    
    logger.info('========== 系统状态 ==========');
    logger.info('内存:', JSON.stringify(memStatus));
    logger.info('任务队列:', JSON.stringify(taskStatus));
    logger.info('===============================');
  }

  shutdown() {
    logger.info('开始关闭...');
    this.memoryManager.stop();
    setTimeout(() => {
      logger.info('已关闭');
      process.exit(0);
    }, 5000);
  }
}

// 启动
if (require.main === module) {
  const app = new LittleSkyApp();
  app.start().catch((error) => {
    logger.error('启动失败', error);
    process.exit(1);
  });
}

module.exports = {
  Logger,
  MemoryManager,
  AsyncTaskQueue,
  LittleSkyApp,
};