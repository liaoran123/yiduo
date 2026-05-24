# 一多 OS 技术文档

## 概述

一多 OS 是一个高性能可编程调度系统，采用 **MoonBit** 语言开发。核心设计围绕**四元架构**（意志、DNA、树形、链式），通过配置驱动的方式，实现组件化、可编程的系统调度。

## 文档目录

| 文档 | 说明 |
|------|------|
| [001.架构设计.md](./001.架构设计.md) | 系统整体架构、四元哲学、数据流 |
| [002.模块参考.md](./002.模块参考.md) | 五个核心模块详解（core/scheduler/config/component/bootstrap） |
| [003.性能优化.md](./003.性能优化.md) | 高性能优化策略、优化前后对比、接近 C 的路径 |

## 源代码结构

```
src/
├── moon.pkg              # 主包配置（is-main: true）
├── bootstrap.mbt         # 最小启动器（主入口）
├── core/                 # 核心基础包
│   ├── moon.pkg
│   ├── message.mbt       # 消息系统（三种模式）
│   ├── ring_buffer.mbt   # 零拷贝环形队列
│   └── memory_pool.mbt   # 预分配内存池
├── scheduler/            # 调度系统核心
│   ├── moon.pkg
│   └── scheduler.mbt     # 高性能调度器
├── config/               # 配置解析模块
│   ├── moon.pkg
│   └── config_loader.mbt # YAML/JSON 配置解析
└── component/            # 组件管理模块
    ├── moon.pkg
    └── loader.mbt        # Wasm/Native 组件加载
```

## 相关文档

- [操作系统/目录](../操作系统/核心调度系统/目录结构说明.md) - 完整文档索引
- [020.自举愿景文档](../操作系统/核心调度系统/020.一多%20OS%20自举愿景文档.md) - 裸机自举路线图
- [021.高性能调度架构设计](../操作系统/核心调度系统/021.高性能调度架构设计.md) - 调度架构详细设计

## 技术栈

- **语言**: MoonBit（调度核心）+ Rust/C（硬件抽象层，未来）
- **编译目标**: Native（直接编译为机器码）
- **运行时**: 无依赖（自主调度核心）
- **组件模型**: Wasm 组件 + Native 组件

## 快速开始

```bash
# 格式化代码
moon fmt

# 更新接口
moon info

# 运行测试
moon test

# 构建
moon build
```