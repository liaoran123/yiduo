# component 包 — 组件基础与 WASM 运行时抽象

**路径**: `runtime/component/`  
**依赖**: `core`

## 概述

component 包定义了一多 OS 的**组件模型**，包括组件类型、能力、配置、状态以及 WASM 运行时接口。它是整个运行时组件化架构的**类型基础**。

遵循 008 组件配置规范，组件的元信息、多实现策略、默认选择等均由外部 YAML 配置驱动。

---

## 核心类型

### `ComponentType` — 组件类型枚举

```moonbit
pub enum ComponentType {
  wasm()    // WebAssembly 组件（可跨平台）
  native()  // 原生组件（平台特定，最高性能）
}
```

| 变体 | 说明 |
|------|------|
| `wasm` | WASM 字节码组件，通过 WAMR 运行时加载 |
| `native` | 直接编译进内核的原生组件，无需运行时 |

### `MemoryPriority` — 内存优先级

```moonbit
pub enum MemoryPriority {
  low()
  normal()
  high()
  critical()
}
```

用于内存紧张时决定回收顺序。

### `ComponentConfig` — 组件配置

```moonbit
pub struct ComponentConfig {
  name: String
  component_type: ComponentType
  priority: MemoryPriority
  max_memory: Int
  capabilities: Array[Capability]
}
```

### `Capability` — 能力标识

```moonbit
pub enum Capability {
  file_io()     // 文件读写
  network()     // 网络访问
  hardware()    // 硬件直通
  scheduling()  // 调度权限
  custom(String) // 自定义能力
}
```

### `ComponentState` — 组件状态

```moonbit
pub enum ComponentState {
  /// 初始状态
  unloaded()
  /// 已加载，不可用
  loaded()
  /// 已激活，可被调度
  active()
  /// 已挂起（资源回收候选）
  suspended()
  /// 因错误终止
  error(String)
}
```

状态机转换规则：
```
unloaded → loaded → active ⇄ suspended → loaded
                ↘ error
```

### `ComponentInstance` — 组件运行时实例

```moonbit
pub struct ComponentInstance {
  id: Int
  name: String
  component_type: ComponentType
  state: ComponentState
  config: ComponentConfig
}
```

### `ComponentLoader` — 组件加载器

负责从 WASM 字节码或原生二进制实例化组件。

```moonbit
pub struct ComponentLoader {
  registry: Array[ComponentInstance?]
}
```

**方法**：

| 函数 | 签名 | 说明 |
|------|------|------|
| `create` | `() -> ComponentLoader` | 创建加载器 |
| `load` | `(self, config: ComponentConfig, bytes: Array[Byte]) -> (ComponentLoader, ComponentInstance?)` | 加载组件 |
| `unload` | `(self, id: Int) -> ComponentLoader` | 卸载组件 |
| `get` | `(self, id: Int) -> ComponentInstance?` | 查组件实例 |
| `list_active` | `(self) -> Array[ComponentInstance]` | 列出活跃组件 |

---

## WASM 运行时接口

### `WasmRuntime` — 运行时函数表

```moonbit
pub struct WasmRuntime {
  invoke: (Int, Array[Byte]) -> Array[Byte]?
  register: (String, Array[Byte]) -> Int
  load: (String) -> Int
  deallocate: (Int) -> Unit
}
```

函数表模式，支持多后端注入：

| 字段 | 签名 | 说明 |
|------|------|------|
| `invoke` | `(func_idx: Int, args: Array[Byte]) -> Array[Byte]?` | 调用 WASM 函数 |
| `register` | `(name: String, wasm_bytes: Array[Byte]) -> Int` | 注册 WASM 模块 |
| `load` | `(name: String) -> Int` | 加载模块到实例 |
| `deallocate` | `(slot: Int) -> Unit` | 释放模块 |

**工厂函数**：
- `create_simulated() -> WasmRuntime` — 创建模拟运行时（stub 模式，用于测试）
- `from_fields(invoke, register, load, deallocate) -> WasmRuntime` — 从字段创建

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

component 包的类型直接对应于 YAML 组件配置的各个字段：

```yaml
components:
  my-component:
    type: wasm           # → ComponentType::wasm()
    priority: high       # → MemoryPriority::high()
    capabilities:        # → Array[Capability]
      - file_io
    max_memory: 65536
```

---

## 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 组件状态机 | 五态模型 | 覆盖从加载到错误恢复的全生命周期 |
| WasmRuntime 抽象 | 函数表模式 | 支持 stub/simulated 和真实 WAMR 双模切换 |
| Capability 枚举 | 预定义 + custom | 满足已知场景同时可扩展 |
| ComponentLoader | 无状态 API | 所有状态变更返回新实例，符合 MoonBit 不可变风格 |