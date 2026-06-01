# 技术文档目录

本目录按 `runtime/` 包结构组织，每个包对应一份技术文档。

## 包层级与文档索引

```
runtime/                     ← bootstrap.md
├── meta_kernel/             ← meta_kernel.md（信任根）
├── core/                    ← core.md（基础类型）
├── fs/                      ← fs.md（文件系统 FFI）
├── component/               ← component.md（组件类型）
├── config/                  ← config.md（配置解析）
├── scheduler/               ← scheduler.md（调度系统）
├── wamr/                    ← wamr.md（WAMR 运行时）
├── boot/                    ← boot.md（引导程序）
└── native_bootstrap/        ← native_bootstrap.md（原生入口）
```

## 文档内容约定

每个包的技术文档包含：

| 章节 | 内容 |
|------|------|
| **功能概述** | 该包的核心职责和设计哲学 |
| **接口定义** | 所有公开类型、结构体、函数的签名和说明 |
| **使用方法** | 代码示例，展示常见使用场景 |
| **包配置** | moon.pkg 配置、依赖关系、目标支持 |
| **（可选）测试** | 测试文件位置和覆盖场景 |

## 包依赖图

```
core (无依赖)
  ├── fs      (依赖 core)
  ├── component (依赖 core)
  │     ├── scheduler (依赖 core + component)
  │     │     ├── config (依赖 core + scheduler + component)
  │     │     └── boot   (依赖 core + config + scheduler + component)
  │     └── wamr (依赖 core + component)
  └── native_bootstrap (依赖 fs + config + boot)
```

---

## 文件清单

```
05.技术文档/
├── readme.md                 ← 索引（包层级 + 依赖图）
├── core.md                   ← 核心基础包（内存/消息/文件系统/熔断器/负载均衡）
├── fs.md                     ← 文件系统 FFI（UTF-16/UTF-8 转换，CRUD）
├── config.md                 ← 配置管理（递归 YAML 解析器、ConfigManager CRUD、热更新）
├── component.md              ← 组件基础类型（ComponentType/WasmRuntime/ComponentInfo）
├── scheduler.md              ← 调度系统（三优先级队列、组件生命周期、热更新方法）
├── wamr.md                   ← WAMR 运行时集成（双模架构、模式切换机制）
├── meta_kernel.md            ← 元内核（信任根、启动验证、心跳监控）
├── boot.md                   ← 引导程序（配置驱动组件注册）
├── native_bootstrap.md       ← 原生自举入口（文件系统版）
└── bootstrap.md              ← 主入口（wasm-gc 版）
```

## 每份文档包含

| 内容 | 说明 |
|------|------|
| 功能概述 | 核心职责和设计哲学 |
| 接口定义 | 所有 `pub` 类型、结构体、函数的签名 |
| 使用方法 | MoonBit 代码示例 |
| 包配置 | `moon.pkg` 依赖关系、目标支持 |
| 测试 | 测试文件位置和覆盖场景（wamr 等包） |