# bootstrap 包 — 主入口（wasm-gc 自举）

**路径**: `runtime/bootstrap.mbt`（单文件，归入 `runtime/` 包）  
**依赖**: `boot`、`config`、`scheduler`、`component`、`meta_kernel`

## 概述

bootstrap 包是 **wasm-gc 目标**的系统入口点。与 `native_bootstrap` 不同，它无法依赖文件系统 FFI，因此使用**内联 YAML 配置**和**硬编码组件描述**，通过 `boot.run()` 启动自举流程。

---

## 公开 API

### `main` — 主入口函数

```moonbit
pub fn main {
  // 1. 内联 YAML 配置（wasm-gc 环境无法读取文件系统）
  let config_yaml = #|bootstrap:
  |  scheduler:
  |    batch_size: 32
  |    hot_threshold: 10
  |    max_components: 64
  |  components:
  |    component-a:
  |      type: native
  |      priority: high
  |    component-b:
  |      type: native
  |      priority: normal
  |#

  // 2. 解析内联配置
  let parsed = @config.parse_yaml(config_yaml)

  // 3. 构造 BootstrapConfig
  let bootstrap_config = @config.BootstrapConfig::{
    scheduler: extract_or_default(parsed, "scheduler"),
    components: extract_or_default(parsed, "components"),
    log_level: "debug",
  }

  // 4. 硬编码组件描述
  let component_descs = [
    ComponentDesc::{
      name: "component-a",
      component_type: @component.ComponentType::native(),
      handler: component_a_handler,
    },
    ComponentDesc::{
      name: "component-b",
      component_type: @component.ComponentType::native(),
      handler: component_b_handler,
    },
  ]

  // 5. 启动自举
  @boot.run(bootstrap_config, component_descs)
}

fn component_a_handler(id: Int, data: Array[Byte]) {
  println("[component-a] 收到消息 #\{id}: \{data.length()} 字节")
}

fn component_b_handler(id: Int, data: Array[Byte]) {
  println("[component-b] 处理消息 #\{id}")
}
```

---

## wasm-gc vs native 数据流对比

| 方面 | wasm-gc（bootstrap.mbt） | native（native_bootstrap） |
|------|--------------------------|---------------------------|
| 配置来源 | 内联 YAML 字符串 | 文件系统 `config.yaml` |
| 组件列表 | 硬编码 `Array[ComponentDesc]` | 从 YAML 动态构建 |
| 文件系统 | 不可用 | 通过 `fs` FFI |
| 启动方式 | `wasm-runtime` 加载 | 原生进程入口 |
| 适用阶段 | 开发 / 测试 | 生产部署 |

---

## **对应关系**

```
bootstrap.mbt（wasm-gc）        native_bootstrap（native 文件系统）
─────────────────               ──────────────────────────────────
main():                         main():
  let config = #|..."#             fs.read_file("config.yaml")
  let parsed = parse_yaml(config)  let parsed = parse_yaml(content)
  let descs = [...]                let descs = build_from_yaml(parsed)
  boot.run(config, descs)          boot.run(config, descs)
```

**关键区别**：配置来源不同，`boot.run()` 的调用方式**完全一致**。

---

## bootstrap 包归属

```moonbit
import {
  "username/yiduo/runtime/boot",
  "username/yiduo/runtime/config",
  "username/yiduo/runtime/scheduler",
  "username/yiduo/runtime/component",
  "username/yiduo/runtime/meta_kernel",
}
```

bootstrap.mbt 归属于 `runtime/` 这个根包（由 `runtime/moon.pkg` 管理），而非独立子包。

---

## 与 008 组件配置规范的关系

内联 YAML 遵循与文件配置完全相同的格式规范：

```yaml
bootstrap:
  scheduler:
    batch_size: 32        # 同 008 规范
    hot_threshold: 10
  components:
    component-a:
      type: native        # ComponentType 枚举
      priority: high      # MemoryPriority 枚举
```

**迁移路径**：wasm-gc → native 时，只需将内联 YAML 写入文件系统，无需修改 `boot.run()` 调用。

---

## 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 配置方式 | 内联 YAML | wasm-gc 无文件系统访问能力 |
| 组件列表 | 硬编码数组 | wasm-gc 无法运行时动态发现组件 |
| 处理器定义 | 内联函数 | 最小化外部依赖，便于测试 |
| 测试策略 | 通过 `moon test` 验证 | 与 native 目标共享同一套测试 |