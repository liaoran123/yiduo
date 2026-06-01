# core 包 — 操作系统基础类型与并发原语

**路径**: `runtime/core/`  
**依赖**: 无（纯 MoonBit 实现）

## 概述

core 包是一多 OS 运行时的**基础类型层**，提供所有上层包（scheduler、component、fs 等）共同依赖的核心数据结构。涵盖消息传递、内存管理、并发队列、文件系统抽象、熔断器、直连通道、事件总线等子系统。

设计原则：
- **零依赖**：仅使用 MoonBit 标准库
- **值语义优先**：所有状态变更通过返回新实例实现
- **极致性能**：SPSCBuffer 用 `& mask` 替代 `% capacity` 实现 5-10x 模运算加速

---

## 核心类型

### `MemoryPool` — 内存池

固定容量对象池，用于高频消息分配场景。

```moonbit
pub struct MemoryPool {
  total_bytes: Int
  used_bytes: Int
  max_bytes: Int
}
```

**方法**:

| 函数 | 签名 | 说明 |
|------|------|------|
| `create` | `(max: Int) -> MemoryPool` | 创建最大 `max` 字节的池 |
| `allocate` | `(self, size: Int) -> (MemoryPool, Int)` | 分配 `size` 字节，返回偏移量 |
| `deallocate` | `(self, size: Int) -> MemoryPool` | 释放 `size` 字节 |
| `available` | `(self) -> Int` | 查询剩余字节数 |

### `MemoryManager` — 内存管理器

封装 MemoryPool 的高层分配接口。

### `SPSCBuffer[T]` — 单生产者单消费者无锁队列

高性能环形缓冲区，供调度器作为**消息队列核心**使用。

```moonbit
pub struct SPSCBuffer[T] {
  buffer: FixedArray[T?]
  capacity: Int
  mask: Int
  head: Int
  tail: Int
}
```

**方法**:

| 函数 | 签名 | 说明 |
|------|------|------|
| `create` | `(capacity: Int) -> SPSCBuffer[T]` | 创建缓冲区（容量向上对齐到 2^n） |
| `enqueue` | `(self, item: T) -> SPSCBuffer[T]` | 入队单元素 |
| `dequeue` | `(self) -> (SPSCBuffer[T], T?)` | 出队单元素 |
| `enqueue_batch` | `(self, items: Array[T]) -> SPSCBuffer[T]` | 批量入队 |
| `dequeue_batch` | `(self, max: Int) -> (SPSCBuffer[T], Array[T])` | 批量出队 |
| `len` | `(self) -> Int` | 当前元素数 |
| `is_empty` | `(self) -> Bool` | 判空 |
| `is_full` | `(self) -> Bool` | 判满 |

**性能特性**：
- 容量必须为 2^n（内部自动对齐），使用 `& mask` 替代 `% capacity` 取模
- 无锁设计：head 仅由消费者写入，tail 仅由生产者写入
- 批量操作减少函数调用次数

### `RingBuffer[T]` — 通用环形缓冲区

通用多读写环形缓冲区。

### `Message` — 调度消息

调度器组件间传递的消息单元。

```moonbit
pub enum MessagePriority {
  high()
  normal()
  low()
}

pub struct Message {
  from: Int
  to: Int
  priority: MessagePriority
  payload: SmallPayload
}
```

**方法**:
- `create_small(from, to, payload) -> Message`
- `create_with_priority(from, to, payload, priority) -> Message`

### `SmallPayload` — 小负载（内联优化）

针对高频小消息的负载类型，支持内联存储以避免堆分配。

### `DirectChannel` — 直连通道

热路径组件间**绕开消息队列**的直连通信通道。

```moonbit
pub struct DirectChannel {
  component_a: Int
  component_b: Int
  a_to_b_count: Int
  b_to_a_count: Int
  dropped_count: Int
  capacity: Int
  max_inline_size: Int
}
```

**方法**:

| 函数 | 签名 | 说明 |
|------|------|------|
| `create` | `(a, b: Int, capacity: Int) -> DirectChannel` | 创建通道 |
| `send_a_to_b` | `(self, dm: DirectMessage) -> DirectChannel` | A→B 发送 |
| `send_b_to_a` | `(self, dm: DirectMessage) -> DirectChannel` | B→A 发送 |
| `stats` | `(self) -> (Int, Int, Int)` | 返回 (a→b, b→a, 丢弃) 计数 |

### `DirectMessage` — 直连消息

针对直连通道优化的内联消息。支持 7 字节内联负载，无堆分配。

```moonbit
pub struct DirectMessage {
  from: Int
  to: Int
  msg_type: Int
  has_inline: Bool
  payload: Int64
}
```

**方法**:
- `create_inline(from, to, msg_type, data) -> DirectMessage`
- `get_inline_data(self) -> Array[Byte]`

### `ChannelManager` — 通道管理器

管理所有直连通道的注册、查找和更新。

```moonbit
pub struct ChannelManager {
  channels: Array[DirectChannel?]
}
```

**方法**:

| 函数 | 签名 | 说明 |
|------|------|------|
| `create` | `() -> ChannelManager` | 创建管理器 |
| `create_channel` | `(self, a, b: Int, capacity: Int) -> (ChannelManager, Int)` | 注册新通道 |
| `find_channel` | `(self, a, b: Int) -> Int?` | 查找两点间通道 |
| `get` | `(self, id: Int) -> DirectChannel?` | 按 ID 获取 |
| `set` | `(self, id: Int, ch: DirectChannel) -> ChannelManager` | 按 ID 更新 |

### `CircuitBreaker` — 熔断器

防止级联故障的熔断器实现。

```moonbit
pub enum CircuitBreakerState {
  closed()     // 正常通行
  open()       // 熔断开启
  half_open()  // 半开试探
}

pub struct CircuitBreaker {
  state: CircuitBreakerState
  failure_count: Int
  success_count: Int
  threshold: Int
  half_open_max_success: Int
}
```

**方法**:
- `create(threshold) -> CircuitBreaker`
- `record_failure(self) -> (CircuitBreaker, Bool)` — 记录失败，返回是否熔断
- `record_success(self) -> (CircuitBreaker, Bool)` — 记录成功，返回是否恢复
- `allow_request(self) -> Bool` — 是否允许请求通过
- `reset(self) -> CircuitBreaker`

### `EventBus` — 事件总线

组件间发布/订阅模式的事件总线。

### `LocalBalancer` — 本地负载均衡器

```moonbit
pub enum AccessMode {
  active_active()   // 双活
  active_standby()  // 主备
}

pub struct LocalBalancer {
  mode: AccessMode
  endpoints: Array[Int]
  current_index: Int
}
```

**方法**:
- `create(mode, endpoints) -> LocalBalancer`
- `next(self) -> Int` — 获取下一个端点
- `create_local_balancer(config_str: String) -> LocalBalancer` — 从配置创建

### `FileSystem` — 文件系统抽象

```moonbit
pub struct FileSystem {
  read_file: (String) -> Result[String, String]
  list_dir: (String) -> Result[Array[String], String]
  write_file: (String, String) -> Result[Unit, String]
  delete_file: (String) -> Result[Unit, String]
  file_exists: (String) -> Bool
}
```

函数表结构，支持注入不同后端实现（native FFI、WASM 等）。

---

## 与 008 组件配置规范的关系

core 包定义的类型被所有上层包使用，其行为通过组件配置（YAML）驱动：

```yaml
# 例如调度器的 SPSCBuffer 容量通过组件配置下发
scheduler:
  properties:
    batch_size: 32
    hot_threshold: 10
```

---

## 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| SPSCBuffer 容量对齐 | 2^n 向上对齐 | `& mask` 比 `% capacity` 快 5-10x |
| 直连通道消息 | 内联 Int64 负载 | 高频消息避免堆分配 |
| 熔断器状态机 | closed→open→half_open→closed | 标准熔断模式，避免级联故障 |
| FileSystem 结构 | 函数表模式 | 支持多后端注入，保持 API 稳定 |