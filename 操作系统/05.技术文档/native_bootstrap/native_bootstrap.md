# native_bootstrap 包 — 原生自举入口

**路径**: `runtime/native_bootstrap/`  
**依赖**: `boot`、`fs`、`config`  
**目标**: `main` 包（native 目标）

## 概述

native_bootstrap 包是 **native 目标**的系统入口点。它通过原生文件系统 FFI 加载配置文件，初始化运行时，然后调用 `boot.run()` 启动自举流程。

执行环境：Windows/Linux/macOS 原生进程。

---

## 公开 API

### `main` — 主入口函数

```moonbit
pub fn main {
  // 1. 创建原生文件系统
  let fs = @fs.create_native_fs()

  // 2. 读取 YAML 配置
  let config_content = match fs.read_file("config.yaml") {
    Ok(content) => content
    Err(e) => { println("读取配置失败: \{e}"); return }
  }

  // 3. 解析配置
  let parsed = @config.parse_yaml(config_content)

  // 4. 构造 BootstrapConfig
  let bootstrap_config = @config.BootstrapConfig::{
    scheduler: extract_or_default(parsed, "scheduler"),
    components: extract_or_default(parsed, "components"),
    log_level: "info",
  }

  // 5. 定义组件列表
  let component_descs = build_component_list(parsed)

  // 6. 启动自举
  @boot.run(bootstrap_config, component_descs)
}
```

---

## 数据流

```
磁盘文件
  │
  ▼
fs.read_file("config.yaml")
  │
  ▼  (UTF-16 → UTF-8 → Win32 API → UTF-8 → UTF-16)
  │
String (YAML 文本)
  │
  ▼
config.parse_yaml()
  │
  ▼
YamlNode (结构化配置树)
  │
  ▼
extract_or_default() / build_component_list()
  │
  ▼
BootstrapConfig + ComponentDesc[]
  │
  ▼
boot.run() → 调度器自举
```

---

## 组件列表构建

`build_component_list` 从 YAML 解析组件描述：

```moonbit
fn build_component_list(config: YamlNode) -> Array[ComponentDesc] {
  let components_node = get_node(config, ["components"])
  let descs: Array[ComponentDesc] = []
  // 遍历 components 下的每个条目，构造 ComponentDesc
  // 类型：native 或 wasm
  // 处理器：根据组件类型分配默认或自定义处理函数
  descs
}
```

---

## moon.pkg

```moonbit
import {
  "username/yiduo/runtime/boot",
  "username/yiduo/runtime/fs",
  "username/yiduo/runtime/config",
}

options(
  is_main: true,
  supported_targets: [ "native" ],
  deps: [ ],
  "native-stub": [ "../fs/c_src/fs_adapter.c" ],
)
```

- `is_main: true` — 标识为可执行入口包
- `supported_targets: [ "native" ]` — 仅 native 目标
- `"native-stub"` — 引入 C FFI 适配层

---

## 与 008 组件配置规范的关系

native_bootstrap 遵循 008 规范的首条原则：**组件配置 = 组件定义的完整描述**。所有运行时参数从 YAML 配置解析，零硬编码。

配置文件位置与环境变量无关，由入口函数接管：

```yaml
# config.yaml（默认路径，与可执行文件同目录）
bootstrap:
  scheduler:
    batch_size: 32
    hot_threshold: 10
  components:
    - name: component-a
      type: native
    - name: component-b
      type: wasm
```

---

## 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 入口形式 | `main` 函数 | MoonBit native 目标标准入口 |
| 配置来源 | 文件系统读 `config.yaml` | 最简单通用的配置加载方式 |
| 组件列表 | 从 YAML 动态构建 | 避免硬编码组件注册逻辑 |
| 错误处理 | 简单 print + return | 引导阶段宜早失败、早暴露 |