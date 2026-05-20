# 一多操作系统 - MVP 执行计划

## 🎯 MVP 目标

**在 1-2 周内，验证核心架构理念：配置驱动 + 计算细胞 + 组合式设计**

- 不涉及内核、Wasm 运行时等复杂技术
- 仅验证"配置文件即编程"和"能力积木组合"理念
- 用纯 MoonBit 实现，能跑起来看到效果

---

## 📋 MVP 范围（做什么，不做什么）

### ✅ 做（核心验证）
1. **配置驱动加载器**：从 YAML 配置加载能力模块
2. **计算细胞注册机制**：简单的组件注册和发现
3. **能力积木组合演示**：展示如何通过配置组合不同功能
4. **Hello World 示例应用**：可配置的问候应用
5. **智能摄像头简化版**：可配置的图像处理流程

### ❌ 不做（下一阶段）
- ❌ Wasm 组件模型
- ❌ 真实硬件驱动
- ❌ 内核/bootloader
- ❌ 网络/文件系统
- ❌ AI 自动适配器

---

## 🏗️ MVP 技术架构

### 目录结构
```
d:\yiduo\
├── mvp/                          # MVP 专用目录（新建）
│   ├── core/                     # MVP 核心
│   │   ├── component_registry.mbt    # 组件注册表
│   │   ├── config_loader.mbt         # 配置加载器（简化版）
│   │   └── capability_loader.mbt     # 能力加载器
│   ├── capabilities/             # 能力积木（可插拔）
│   │   ├── greeter.mbt              # 问候能力
│   │   ├── logger.mbt               # 日志能力
│   │   ├── formatter.mbt            # 格式化能力
│   │   └── image_processor.mbt      # 图像处理能力
│   ├── apps/                     # MVP 应用
│   │   ├── hello_app.mbt            # Hello World 应用
│   │   └── camera_app.mbt           # 智能摄像头应用
│   └── configs/                  # 配置文件
│       ├── hello_config.yaml        # Hello 应用配置
│       └── camera_config.yaml       # 摄像头应用配置
└── docs/mvp/                    # MVP 文档
```

### 核心概念简化
| 概念 | MVP 实现 |
|------|---------|
| **计算细胞** | MoonBit struct + trait |
| **能力积木** | 独立的 MoonBit 模块 |
| **配置即编程** | YAML 文件定义组合 |
| **链式骨架** | 固定的接口 trait |
| **树形器官** | 可插拔的能力实现 |

---

## 🚀 阶段 1：MVP 核心框架（2-3 天）

### 任务 1.1：定义基础接口 Trait

**文件**：`mvp/core/interfaces.mbt`

```moonbit
/// 计算细胞基础 trait
trait Component {
  /// 获取组件名称
  fn name(self) -> String
  
  /// 初始化组件
  fn init(self) -> Result[Unit, String]
  
  /// 清理组件
  fn cleanup(self) -> Unit
}

/// 能力积木 trait - 可执行的功能
trait Capability {
  /// 能力名称
  fn capability_name(self) -> String
  
  /// 执行能力
  fn execute(self, input: String) -> Result[String, String]
}
```

### 任务 1.2：实现组件注册表

**文件**：`mvp/core/component_registry.mbt`

```moonbit
/// 组件注册表 - 管理所有可用的能力积木
struct ComponentRegistry {
  components: Map[String, Component]
  capabilities: Map[String, Capability]
}

/// 注册组件
fn register_component(reg: ComponentRegistry, comp: Component) -> Unit

/// 注册能力
fn register_capability(reg: ComponentRegistry, cap: Capability) -> Unit

/// 获取能力
fn get_capability(reg: ComponentRegistry, name: String) -> Option[Capability]

/// 列出所有能力
fn list_capabilities(reg: ComponentRegistry) -> Array[String]
```

### 任务 1.3：实现简化配置加载器

**文件**：`mvp/core/config_loader.mbt`

```moonbit
/// 应用配置结构
struct AppConfig {
  app_name: String
  enabled_capabilities: Array[String]
  capability_order: Array[String]  // 执行顺序
  custom_settings: Map[String, String]
}

/// 从 YAML 加载配置
fn load_config(yaml_path: String) -> Result[AppConfig, String]

/// 验证配置
fn validate_config(config: AppConfig, registry: ComponentRegistry) -> Result[Unit, String]
```

---

## 🧩 阶段 2：实现能力积木（2-3 天）

### 能力 1：问候能力

**文件**：`mvp/capabilities/greeter.mbt`

```moonbit
struct Greeter {
  greeting: String
}

impl Component for Greeter {
  fn name(self) -> String { "greeter" }
  fn init(self) -> Result[Unit, String] { Ok(()) }
  fn cleanup(self) -> Unit {}
}

impl Capability for Greeter {
  fn capability_name(self) -> String { "greeter" }
  fn execute(self, input: String) -> Result[String, String] {
    Ok(self.greeting + ", " + input + "!")
  }
}
```

### 能力 2：日志能力

**文件**：`mvp/capabilities/logger.mbt`

```moonbit
struct Logger {
  level: String  // "info", "warn", "error"
}

impl Component for Logger { ... }
impl Capability for Logger {
  fn execute(self, input: String) -> Result[String, String] {
    println("[" + self.level.to_upper() + "] " + input)
    Ok(input)
  }
}
```

### 能力 3：格式化能力

**文件**：`mvp/capabilities/formatter.mbt`

```moonbit
struct Formatter {
  format: String  // "uppercase", "lowercase", "titlecase"
}

impl Component for Formatter { ... }
impl Capability for Formatter {
  fn execute(self, input: String) -> Result[String, String] {
    match self.format {
      | "uppercase" => Ok(input.to_upper()),
      | "lowercase" => Ok(input.to_lower()),
      | "titlecase" => Ok(to_titlecase(input)),
      | _ => Err("Unknown format: " + self.format),
    }
  }
}
```

### 能力 4：图像处理（简化版）

**文件**：`mvp/capabilities/image_processor.mbt`

```moonbit
struct ImageProcessor {
  operation: String  // "grayscale", "blur", "resize"
}

impl Component for ImageProcessor { ... }
impl Capability for ImageProcessor {
  fn execute(self, input: String) -> Result[String, String] {
    Ok("Image[" + self.operation + "]: " + input)
  }
}
```

---

## 📱 阶段 3：示例应用（1-2 天）

### 应用 1：可配置的 Hello World

**配置文件**：`mvp/configs/hello_config.yaml`

```yaml
app_name: "Hello MVP"
enabled_capabilities:
  - "logger"
  - "greeter"
  - "formatter"
capability_order:
  - "logger"       # 先记录
  - "greeter"      # 再加问候
  - "formatter"    # 最后格式化
custom_settings:
  greeter.greeting: "Hello"
  formatter.format: "uppercase"
  logger.level: "info"
```

**应用代码**：`mvp/apps/hello_app.mbt`

```moonbit
fn main {
  // 1. 初始化注册表，注册所有能力
  let registry = ComponentRegistry::new()
  registry.register_capability(Greeter::new("Hello"))
  registry.register_capability(Logger::new("info"))
  registry.register_capability(Formatter::new("uppercase"))
  
  // 2. 加载配置
  let config = load_config("mvp/configs/hello_config.yaml")?
  
  // 3. 根据配置组合能力并执行
  let result = execute_pipeline(config, registry, "World")
  
  println("Final result: " + result)
}
```

### 应用 2：可配置的智能摄像头

**配置文件**：`mvp/configs/camera_config.yaml`

```yaml
app_name: "Smart Camera MVP"
enabled_capabilities:
  - "logger"
  - "image_processor"
  - "formatter"
capability_order:
  - "logger"
  - "image_processor"
  - "formatter"
custom_settings:
  image_processor.operation: "grayscale"
  formatter.format: "titlecase"
  logger.level: "info"
```

**应用代码**：`mvp/apps/camera_app.mbt`

```moonbit
fn main {
  // 类似 hello_app，但使用图像处理能力
  let result = execute_pipeline(config, registry, "raw_image_data")
  println("Processed image: " + result)
}
```

---

## 🔧 阶段 4：能力执行流水线（1 天）

**文件**：`mvp/core/pipeline.mbt`

```moonbit
/// 执行能力流水线
fn execute_pipeline(
  config: AppConfig,
  registry: ComponentRegistry,
  input: String
) -> Result[String, String] {
  let mut current = input
  
  for cap_name in config.capability_order {
    match registry.get_capability(cap_name) {
      | Some(cap) => {
        current = cap.execute(current)?
      }
      | None => return Err("Capability not found: " + cap_name),
    }
  }
  
  Ok(current)
}
```

---

## ✅ 验收标准

### 功能验收
1. [ ] 能成功加载 YAML 配置
2. [ ] 能注册和发现能力积木
3. [ ] 能按配置顺序执行能力流水线
4. [ ] 修改配置文件能改变应用行为（无需改代码）
5. [ ] Hello 应用能正常运行并输出问候语
6. [ ] 摄像头应用能正常运行并输出处理结果

### 架构验收
1. [ ] 能力积木是独立的，可单独插拔
2. [ ] 配置驱动，修改配置不需要重新编译
3. [ ] 代码结构清晰，符合"链式骨架 + 树形器官"理念
4. [ ] 有完整的示例演示组合式设计的优势

---

## 📊 MVP 成功指标

| 指标 | 目标 |
|------|------|
| **开发时间** | ≤ 2 周 |
| **代码行数** | ≤ 1000 行 |
| **能力积木数** | ≥ 4 个 |
| **示例应用数** | ≥ 2 个 |
| **配置文件数** | ≥ 2 个 |
| **可演示的配置变化** | ≥ 3 种 |

---

## 🎬 MVP 演示脚本

### 演示 1：Hello World 配置变化

**步骤**：
1. 运行默认配置 → 输出 "HELLO, WORLD!"
2. 修改配置 `greeter.greeting: "Hi"`，`formatter.format: "lowercase"`
3. 重新运行 → 输出 "hi, world!"
4. 展示**无需改代码，只需改配置**

### 演示 2：能力积木组合

**步骤**：
1. 配置只启用 greeter → 简单问候
2. 配置启用 greeter + logger → 问候 + 日志
3. 配置启用全部 3 个能力 → 完整流水线
4. 展示**像搭积木一样组合功能**

---

## 📝 下一步（MVP 后）

MVP 验证成功后，逐步添加：
1. Wasm 组件支持
2. 真实硬件接口
3. 网络/文件系统
4. AI 适配器生成
5. 更多能力积木

---

**开始日期**：____/__/__  
**预计完成**：____/__/__  
**负责人**：一多团队
