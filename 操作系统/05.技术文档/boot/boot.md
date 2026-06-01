# boot 包 — 引导程序（配置驱动自举）

**路径**: `runtime/boot/`  
**依赖**: `core`、`config`、`scheduler`、`component`

## 概述

boot 包实现一多 OS 的**配置驱动自举流程**。它读取 YAML 配置，注册组件，初始化调度器，建立直连通道，然后启动消息分发循环。

核心原则：**所有行为由配置决定**，无硬编码路径和策略。

---

## 公开 API

### `run` — 主引导函数

```moonbit
pub fn run(
  config: @config.BootstrapConfig,
  component_descs: Array[ComponentDesc],
) -> Unit
```

**参数**：

| 参数 | 类型 | 说明 |
|------|------|------|
| `config` | `@config.BootstrapConfig` | 从 YAML 解析的引导配置 |
| `component_descs` | `Array[ComponentDesc]` | 组件描述列表 |

**执行流程**：

```
run(config, component_descs):
  │
  ├── 1. 创建调度器实例
  │      从 config.scheduler 读取 batch_size、hot_threshold 等参数
  │
  ├── 2. 注册所有组件
  │      遍历 component_descs，逐个注册到调度器
  │
  ├── 3. 注册消息处理器
  │      为每个组件注册对应的消息处理回调
  │
  ├── 4. 建立预配置的直连通道
  │      读取 config.components 中的 direct-channels 配置
  │
  ├── 5. 启动调度器
  │      调度器开始处理消息队列
  │
  └── 6. 消息分发循环
        SchedulerV3.run() 持续 drain 和 dispatch
```

### `ComponentDesc` — 组件描述

```moonbit
pub struct ComponentDesc {
  name: String
  component_type: @component.ComponentType
  handler: (Int, Array[Byte]) -> Unit
}
```

---

## 引导流程详解

### 1. 配置加载

从 bootstrap YAML 配置读取调度器参数：

```yaml
scheduler:
  batch_size: 32
  hot_threshold: 10
  max_components: 64
```

### 2. 组件注册

对每个 ComponentDesc：
1. 创建 `ComponentInfo`
2. 调用 `scheduler.register(info)` 获取组件 ID
3. 调用 `scheduler.register_handler(id, handler)` 注册处理器

### 3. 直连通道配置

从 YAML 中读取预配置的直连通道：

```yaml
direct-channels:
  - from: component-a
    to: component-b
    capacity: 128
```

遍历通道配置，查找对应组件 ID，调用 `create_direct_channel`。

### 4. 启动调度

调度器进入运行状态，开始 drain-dispatch 循环：

```
loop:
  drain_adaptive() → 收集所有消息
  dispatch_v3() → 将消息投递给对应处理器
```

---

## 自举原则

boot 包是自举编程的核心体现：

```
                    ┌───────────────────┐
                    │   YAML 配置文件    │
                    │   (008 规范)       │
                    └────────┬──────────┘
                             │ 解析
                             ▼
                    ┌───────────────────┐
                    │  config 包         │
                    │  YamlNode / JSON   │
                    └────────┬──────────┘
                             │ 读取
                             ▼
                    ┌───────────────────┐
                    │  boot.run()        │
                    │  配置驱动自举      │
                    ├───────────────────┤
                    │  • 创建调度器       │
                    │  • 注册组件         │
                    │  • 建直连通道       │
                    │  • 启动分发         │
                    └───────────────────┘
```

所有构建时和运行时的参数都从 YAML 组件定义派生。

---

## moon.pkg

```moonbit
import {
  "username/yiduo/runtime/core",
  "username/yiduo/runtime/config",
  "username/yiduo/runtime/scheduler",
  "username/yiduo/runtime/component",
}

options(
  deps: [ ],
)
```

---

## 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 组件描述方式 | `ComponentDesc` 结构体数组 | 适配不同入口（wasm-gc / native 文件系统） |
| 配置消费方式 | 运行时读取 `BootstrapConfig` | 配置与代码分离，支持热更新 |
| 引导流程 | 线性步骤无分支 | OS 启动需确定性，易于调试 |
| 调度器选择 | 当前使用 V3 | V3 提供直连通道和自适应排水 |