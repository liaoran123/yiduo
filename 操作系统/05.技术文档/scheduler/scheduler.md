# scheduler 包 — 消息总线与组件调度系统

**路径**: `runtime/scheduler/`  
**依赖**: `core`、`component`

## 概述

scheduler 包是一多 OS 的**核心消息总线**，负责调度器中所有组件间的消息传递与生命周期管理。它是整个操作系统的**通信中枢**，类比 PCIe 总线在硬件中的作用。

设计目标：
- **极致性能**：直连通道（DirectChannel）绕开队列实现零拷贝通信
- **自适应**：热路径自动检测，动态建立直连通道
- **多优先级**：高/普通/低三级优先队列，确保关键消息实时性
- **双模运行时**：支持 V2（经典）和 V3（高性能）两代调度器

---

## 架构概览

```
组件 A ──→ send_small() ──→ 亲和度追踪
                                │
                      ┌─────────┴─────────┐
                      ▼                   ▼
              直连通道已存在？        直连通道不存在
                      │                   │
                      ▼                   ▼
              DirectChannel       SPSCBuffer 优先级队列
              (零拷贝，无锁)         │
                                    ▼
                            自适应批量排水
                              (drain_adaptive)
                                    │
                                    ▼
                              dispatch_v3()
                                    │
                                    ▼
                              组件 B 处理器
```

---

## V3 调度器（高性能版）

### `SchedulerV3` — 新一代调度器

```moonbit
pub struct SchedulerV3 {
  high_queue: SPSCBuffer[Message]      // 高优先级队列
  normal_queue: SPSCBuffer[Message]    // 普通优先级队列
  low_queue: SPSCBuffer[Message]       // 低优先级队列
  pool: MemoryPool                     // 内存池
  components: FixedArray[ComponentInfo?] // 组件注册表
  is_running: Bool                     // 运行标志
  batch_size: Int                      // 批量排水大小
  handlers: HandlerRegistry            // 消息处理器注册表
  wasm_runtime: WasmRuntime?           // WASM 运行时
  channel_mgr: ChannelManager          // 直连通道管理器
  adaptive_ctx: AdaptiveBatchContext   // 自适应上下文
  hot_threshold: Int                   // 热路径阈值
}
```

**核心方法**：

| 函数 | 签名 | 说明 |
|------|------|------|
| `create` | `() -> SchedulerV3` | 创建实例 |
| `register` | `(self, info: ComponentInfo) -> (SchedulerV3, Int)` | 注册组件 |
| `register_handler` | `(self, comp_id: Int, handler) -> SchedulerV3` | 注册消息处理器 |
| `send_small` | `(self, from, to: Int, payload, priority) -> (SchedulerV3, Bool)` | 发送小消息 |
| `create_direct_channel` | `(self, a, b: Int, cap: Int) -> (SchedulerV3, Int)` | 建立直连通道 |
| `run` | `(self) -> SchedulerV3` | 运行调度循环 |
| `drain` | `(self) -> (SchedulerV3, Array[Message])` | 一次排水 |
| `stop` | `(self) -> SchedulerV3` | 停止调度 |

### `ComponentInfo` — 组件注册信息

```moonbit
pub struct ComponentInfo {
  name: String
  component_type: ComponentType
  status: ComponentStatus
  last_comm_with: FixedArray[Int]      // 最后 16 个通信对象
  last_comm_count: FixedArray[Int]     // 各通信对象计数
  affinity_scores: FixedArray[Int]     // 亲和度分数
}
```

### `ComponentStatus` — 组件状态枚举

```moonbit
pub enum ComponentStatus {
  created()
  ready()
  running()
  suspended()
  error(String)
}
```

---

## 消息发送流程（`send_small`）

```
send_small(from, to, payload, priority)
  │
  ├── 1. update_affinity_v3(from, to)
  │      ├── 查找 to_id 在 from 组件的通信记录中
  │      ├── 存在 → 增加计数
  │      └── 不存在 → 插入新记录，计数 = 1
  │      └── 自动热路径检测：
  │           若计数 ≥ hot_threshold 且无直连通道 → 建立直连通道
  │
  ├── 2. 查找直连通道
  │      ├── 有直连通道 → DirectChannel.send()，绕开队列
  │      └── 无直连通道 → 进入优先级队列
  │
  └── 3. 入队（如需）
         ├── high() → high_queue
         ├── normal() → normal_queue
         └── low() → low_queue
```

---

## 自适应批量排水

### `SchedulerMetrics` — 调度统计

```moonbit
pub struct SchedulerMetrics {
  total_messages: Int
  high_priority_count: Int
  normal_priority_count: Int
  low_priority_count: Int
  batch_count: Int
  total_batch_size: Int
  max_batch_size: Int
  min_batch_size: Int
  direct_channel_count: Int
}
```

### `AdaptiveBatchContext` — 自适应批量上下文

```moonbit
pub struct AdaptiveBatchContext {
  batch_size: Int    // 当前批量大小
  min_batch: Int     // 最小批量
  max_batch: Int     // 最大批量
  drain_round: Int   // 排水轮次
  stats: SchedulerMetrics  // 历史统计
}
```

**自适应策略**：

```
排水后分析：
  ├── normal_queue 满额 + low_queue 满额 → batch_size × 2（加速）
  ├── normal_queue 为空 + low_queue 为空 → batch_size / 2（节流）
  └── 其他情况 → 保持当前 batch_size
    边界裁剪：min_batch ≤ batch_size ≤ max_batch
```

### `drain_adaptive` — 自适应排水函数

```moonbit
pub fn drain_adaptive[T](
  ctx: AdaptiveBatchContext,
  high_queue: SPSCBuffer[T],
  normal_queue: SPSCBuffer[T],
  low_queue: SPSCBuffer[T],
) -> (AdaptiveBatchContext, SPSCBuffer[T], SPSCBuffer[T], SPSCBuffer[T], Array[T])
```

1. 排高优队列：全部排空（len 条）
2. 排普通队列：取 `ctx.batch_size` 条
3. 排低优队列：取 `ctx.batch_size * 2` 条
4. 合并所有消息
5. 根据排水结果调节下次 batch_size

---

## V2 调度器（经典版）

### `Scheduler` — 经典调度器

```moonbit
pub struct Scheduler {
  components: Array[ComponentInfo?]
  handlers: HandlerRegistry
  debug_log: Bool
}
```

**方法**：

| 函数 | 说明 |
|------|------|
| `create()` | 创建 V2 调度器 |
| `register(info)` | 注册组件 |
| `register_handler(comp_id, handler)` | 注册处理器 |
| `send_message(from, to, data)` | 分发消息 |
| `start()` | 启动调度循环 |

---

## `HandlerRegistry` — 消息处理器注册表

```moonbit
pub struct HandlerRegistry {
  handlers: Array[(Int, Array[Byte]) -> Unit?]
}
```

**方法**：

| 函数 | 签名 | 说明 |
|------|------|------|
| `create` | `() -> HandlerRegistry` | 创建空注册表 |
| `register_handler` | `(self, comp_id, handler) -> HandlerRegistry` | 注册处理器 |
| `invoke` | `(self, comp_id, msg) -> Bool` | 调用处理器 |
| `get_handler` | `(self, comp_id) -> ((Int, Array[Byte]) -> Unit)?` | 查询处理器 |

---

## moon.pkg

```moonbit
import {
  "username/yiduo/runtime/core",
  "username/yiduo/runtime/component",
}

options(
  deps: [ ],
)
```

---

## 与 008 组件配置规范的关系

调度器配置通过组件 YAML 下发：

```yaml
scheduler:
  properties:
    batch_size: 32
    hot_threshold: 10
    max_components: 64
```

**性能配置项**：

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| `batch_size` | 32 | 单次排水的默认批量 |
| `hot_threshold` | 10 | 热路径自动检测阈值（通信次数） |
| `max_components` | 64 | 最大组件数 |
| `direct_channel_capacity` | 128 | 直连通道容量 |

---

## 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 消息队列 | SPSCBuffer × 3（三级优先级） | 无锁、高性能、优先级隔离 |
| 热路径策略 | 通信计数阈值自动触发 | 无人工干预，运行时自适应 |
| 直连通道 | 绕开队列直接通信 | 高频组件间零拷贝，极致性能 |
| 批量排水 | 自适应调节 batch_size | 负载高时吞吐优先，空闲时延迟优先 |
| 亲和度追踪 | FixedArray[16] 滑动窗口 | 固定内存开销 O(1)，最近 16 条通信记录 |
| V2/V3 共存 | 两代调度器独立实现 | 平滑迁移，V3 逐步替代 V2 |