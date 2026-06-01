# config 包 — 递归 YAML 配置解析与管理

**路径**: `runtime/config/`  
**依赖**: `core`、`fs`

## 概述

config 包实现一多 OS 的**配置管理子系统**，核心是**递归 YAML 解析器**。它从文件系统读取 YAML 配置（遵循 008 组件配置格式规范），将配置数据解析为结构化的 `YamlNode` 树，供调度器和引导程序消费。

自举原则：系统通过读取自身的配置文件来决定行为，所有构建参数从组件 YAML 定义派生，杜绝硬编码。

---

## 核心类型

### `YamlNode` — 递归 YAML 节点

```moonbit
pub enum YamlNode {
  scalar(String)
  sequence(Array[YamlNode])
  mapping(Array[(String, YamlNode)])
}
```

递归定义，支持任意嵌套深度的 YAML 结构：

| 变体 | YAML 示例 | 说明 |
|------|-----------|------|
| `scalar("hello")` | `key: hello` | 标量值 |
| `sequence([...])` | `items: [a, b, c]` | 有序序列 |
| `mapping([("k","v"),...])` | `k1: v1\nk2: v2` | 键值映射 |

### `SystemMeta` — 系统元信息

```moonbit
pub struct SystemMeta {
  os_name: String
  os_version: String
  arch: String
  boot_time: String
}
```

系统启动时自动采集，用于配置决策。

### `BootstrapConfig` — 引导配置

```moonbit
pub struct BootstrapConfig {
  scheduler: YamlNode
  components: YamlNode
  log_level: String
}
```

### `YiduoBootstrapConfig` — 一多 OS 引导配置包装

```moonbit
pub struct YiduoBootstrapConfig {
  config: BootstrapConfig
}
```

### `ConfigChange` — 配置变更事件

```moonbit
pub struct ConfigChange {
  path: String
  old_value: String
  new_value: String
  timestamp: Int
}
```

### `ConfigManager` — 配置管理器

支持 CRUD 操作和热更新。

```moonbit
pub struct ConfigManager {
  raw: YamlNode
  changes: Array[ConfigChange]
  version: Int
}
```

**方法**：

| 函数 | 签名 | 说明 |
|------|------|------|
| `load` | `(path: String) -> ConfigManager` | 从文件加载配置 |
| `get` | `(self, key: String) -> YamlNode?` | 按路径读取 |
| `set` | `(self, key: String, value: YamlNode) -> ConfigManager` | 写入配置 |
| `delete` | `(self, key: String) -> ConfigManager` | 删除键 |
| `subscribe` | `(self, key: String, callback: (ConfigChange) -> Unit) -> ConfigManager` | 订阅变更 |
| `version` | `(self) -> Int` | 当前版本号 |

### `HotUpdateResult` — 热更新结果

```moonbit
pub enum HotUpdateResult {
  success()
  failure(String)
  no_change()
}
```

---

## 递归 YAML 解析器

### `parse_yaml(content: String) -> YamlNode`

递归解析 YAML 文本为 `YamlNode` 树：

```moonbit
pub fn parse_yaml(content: String) -> YamlNode
```

**解析规则**：

| YAML 模式 | 对应 `YamlNode` | 示例 |
|-----------|-----------------|------|
| `key: value` | `mapping([("key", scalar("value"))])` | 简单键值对 |
| `- item1\n- item2` | `sequence([scalar("item1"), scalar("item2")])` | 序列 |
| 嵌套映射 | 递归 `mapping` | 多级缩进 |
| 内联序列 | `sequence` | `{key: [a, b]}` |

**递归入口**：`config_loader.mbt` 中的 `parse_line` → `parse_value` → `parse_mapping` / `parse_sequence`。

### 查询函数

| 函数 | 说明 |
|------|------|
| `get_value(node, key) -> String?` | 从映射中提取标量值 |
| `get_node(node, path: Array[String]) -> YamlNode?` | 按路径链查询 |
| `yaml_to_json(node) -> String` | YAML → JSON 转换（供 `yaml_query` 工具使用） |

---

## `yaml_query` 工具链

tools/yaml_query 基于 config 包的解析器，将 YAML 配置转为 JSON 输出，供 PowerShell 构建脚本消费：

```
YAML 配置文件 → parse_yaml() → yaml_to_json() → JSON → build_wamr.ps1
```

解决 PowerShell 正则平扫 YAML 的脆弱性问题。

---

## moon.pkg

```moonbit
import {
  "username/yiduo/runtime/core",
  "username/yiduo/runtime/fs",
}

options(
  deps: [ ],
)
```

---

## 与 008 组件配置规范的关系

config 包是 008 规范的具体实现：

```yaml
# 008 规范定义的组件配置（YAML）
components:
  wamr-runtime:
    type: native
    properties:
      lib-path: runtime/wamr/lib
    source:
      native-library: target/liblibiwasm.a
    system-libs:
      windows: [ws2_32, ntdll]
```

config 包将其解析为 `YamlNode`，构建脚本通过 `yaml_query` 提取各字段驱动构建。

---

## 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 解析策略 | 递归下降，手写解析器 | 无第三方依赖，完全自举 |
| 节点类型 | 三元枚举（scalar/sequence/mapping） | 覆盖完整 YAML 子集 |
| 配置存储 | 不可变树结构 | 热更新返回新版本，版本号追踪变更 |
| JSON 互转 | `yaml_to_json()` | 构建脚本（PowerShell）消费 JSON 更方便 |