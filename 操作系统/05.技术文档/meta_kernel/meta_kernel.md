# meta_kernel 包 — 元内核（信任根）

**路径**: `runtime/meta_kernel/`  
**依赖**: `core`

## 概述

meta_kernel 包是一多 OS 的**信任根**，在调度器启动前和运行期间提供最底层的核心服务。包括身份验证、启动完整性校验、系统心跳监控等功能。

设计定位：**内核中的微内核**——只包含不可精简的最基础服务。

---

## 核心类型

### `MetaKernel` — 元内核实例

```moonbit
pub struct MetaKernel {
  /// 内核身份标识
  identity: String
  /// 启动时间戳
  boot_timestamp: Int
  /// 心跳间隔（毫秒）
  heartbeat_interval: Int
  /// 最后心跳时间
  last_heartbeat: Int
  /// 组件健康状态表
  component_health: Array[HealthStatus?]
  /// 主动验证策略
  verification_strategy: String
}
```

### `HealthStatus` — 组件健康状态

```moonbit
pub enum HealthStatus {
  healthy()
  degraded(String)
  unhealthy(String)
  unknown()
}
```

### `VerificationResult` — 验证结果

```moonbit
pub enum VerificationResult {
  verified()
  failed(String)
  skipped(String)
}
```

---

## 公开 API

### 创建与初始化

| 函数 | 签名 | 说明 |
|------|------|------|
| `create` | `(identity: String) -> MetaKernel` | 创建元内核实例 |
| `create_with_config` | `(identity: String, heartbeat_interval: Int) -> MetaKernel` | 带心跳配置创建 |

### 心跳与健康监控

| 函数 | 签名 | 说明 |
|------|------|------|
| `beat` | `(self) -> MetaKernel` | 发送心跳脉冲 |
| `health_check` | `(self) -> (MetaKernel, Array[(Int, HealthStatus)])` | 全量健康检查 |
| `report_health` | `(self, comp_id: Int, status: HealthStatus) -> MetaKernel` | 上报组件健康状态 |
| `get_health` | `(self, comp_id: Int) -> HealthStatus` | 查询组件健康状态 |

### 启动验证

| 函数 | 签名 | 说明 |
|------|------|------|
| `verify_boot` | `(self, manifest: String) -> (MetaKernel, VerificationResult)` | 验证启动清单完整性 |
| `verify_component` | `(self, comp_name: String, hash: String) -> (MetaKernel, VerificationResult)` | 验证单个组件 |

### 安全与策略

| 函数 | 签名 | 说明 |
|------|------|------|
| `set_verification_strategy` | `(self, strategy: String) -> MetaKernel` | 设置验证策略 |
| `get_identity` | `(self) -> String` | 获取元内核标识 |

### 查询

| 函数 | 签名 | 说明 |
|------|------|------|
| `uptime` | `(self) -> Int` | 系统运行时长 |
| `component_count` | `(self) -> Int` | 注册组件数 |
| `is_healthy` | `(self) -> Bool` | 整体健康状态 |

---

## 状态管理

meta_kernel 采用不可变状态模式，所有变更操作返回新实例：

```
create("kernel-1")
  → beat() → 新 MetaKernel（更新时间戳）
  → report_health(1, healthy()) → 新 MetaKernel（更新健康表）
  → verify_boot(manifest) → 新 MetaKernel（记录验证结果）
  → beat() → ...
```

---

## 心跳机制

定时（默认 1000ms）心跳脉冲：

```
beat() 调用：
  1. 更新 last_heartbeat = 当前时间戳
  2. 检查所有组件最后上报时间
  3. 超过 3×heartbeat_interval 未上报 → 标记 unhealthy
  4. 返回新的 MetaKernel
```

---

## moon.pkg

```moonbit
import {
  "username/yiduo/runtime/core",
}

options(
  deps: [ ],
)
```

---

## 与 008 组件配置规范的关系

meta_kernel 的行为通过配置驱动：

```yaml
meta_kernel:
  identity: yiduo-os-v1
  properties:
    heartbeat_interval: 1000
    verification_strategy: sha256
```

---

## 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 信任模型 | 自验证启动 | 无外部依赖，适合嵌入式/OS 场景 |
| 健康监控 | 心跳超时检测 | 简单可靠，O(1) 复杂度 |
| 状态变更 | 不可变实例 | 符合 MoonBit 风格，线程安全 |
| 验证策略 | 可插拔策略名 | 适应不同安全等级场景 |