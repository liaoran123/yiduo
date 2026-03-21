# 一多 - 下一代跨语言原生操作系统

## 项目简介

一多（Yiduo）是一个基于混合架构的下一代跨语言原生操作系统，旨在通过 WebAssembly 组件模型实现语言的统一，同时在必要时使用 Native 代码突破性能和硬件访问的限制。

### 核心特性

- **跨语言统一**：通过 WebAssembly 组件模型，支持多种编程语言无缝集成
- **高性能**：在关键路径使用 Native 代码，确保系统性能
- **安全性**：基于能力模型的安全隔离，保护系统和用户数据
- **可扩展性**：模块化设计，支持动态加载和卸载组件
- **跨平台**：一次编译，到处运行，支持多种硬件架构
- **生态兼容性**：支持现有的系统库和第三方库的集成

## 技术架构

### 1. 混合架构理念

"能 Wasm 就 Wasm，必须 Native 则 Native"：
- **能 Wasm 就 Wasm**：为了开发效率和生态兼容
- **必须 Native 则 Native**：为了突破物理硬件的限制

### 2. 分层架构

| 层级 | 推荐技术 | 原因 | 示例功能 |
|------|---------|------|----------|
| 应用层 | Wasm (MoonBit) | 90% 的业务逻辑、UI、AI 编排。追求安全、跨平台、热更新。 | 办公软件、浏览器、AI 应用 |
| 系统服务层 | Wasm (WASI) | 网络服务、日志、配置管理。利用 WASI 标准接口。 | 网络协议栈、日志服务、配置管理 |
| 内核/驱动层 | Native (MoonBit/Rust) | 这是 Wasm 的禁区。内存管理、中断处理、硬件驱动、文件系统底层。 | 内存管理、中断处理、硬件驱动 |
| 高性能计算层 | Native + FFI | 这是 Wasm 的性能洼地。GPU 驱动、NPU 推理核心、视频编解码。 | GPU 加速、视频编解码、AI 推理 |

### 3. 系统架构

```
一多操作系统
├── 应用层
│   ├── Wasm 应用组件
│   ├── UI 框架
│   └── AI 编排服务
├── 系统服务层
│   ├── WASI 系统服务
│   ├── 网络服务
│   ├── 日志服务
│   └── 配置管理
├── 内核/驱动层
│   ├── 内核核心
│   ├── 内存管理
│   ├── 中断处理
│   └── 硬件驱动
├── 高性能计算层
│   ├── GPU 驱动
│   ├── NPU 推理核心
│   └── 视频编解码
└── 运行时
    ├── MoonBit 运行时
    ├── WebAssembly 运行时 (Wasmtime)
    └── 组件管理器
```

## 项目结构

```
d:\yiduo\
├── cmd/                # 命令行工具
│   └── main/           # 主程序
├── 操作系统/           # 操作系统相关文档
│   └── 技术方案/       # 技术方案文档
├── .vscode/            # VS Code 配置
├── yiduo.mbt           # 核心模块
├── yiduo_test.mbt      # 测试文件
├── yiduo_wbtest.mbt    # 白盒测试文件
├── moon.mod.json       # MoonBit 模块配置
├── moon.pkg            # MoonBit 包配置
└── README.md           # 项目说明
```

## 快速开始

### 1. 环境要求

- MoonBit 编译器
- WebAssembly 运行时 (Wasmtime)
- C/C++ 编译器 (用于编译 Native 代码)
- Rust 编译器 (用于内核/驱动开发)

### 2. 构建与运行

#### 运行 MoonBit 应用

```bash
# 运行主程序
moon run --target=wasm-gc cmd/main

# 或使用 Native 目标
moon run --target=native cmd/main
```

### 3. 开发流程

1. **定义 WIT 接口**：在 `components/interface.wit` 中定义组件接口
2. **实现组件**：使用 MoonBit、C/C++、Rust 等语言实现组件
3. **编译**：将组件编译成 Wasm 或 Native 代码
4. **在 MoonBit 中使用**：通过导入接口使用组件功能

## 开发指南

### 1. MoonBit 接口定义

```moonbit nocheck
// cmd/main/main.mbt
///|
fn add(a : Int, b : Int) -> Int = "math" "add"

///|
fn main {
  let sum = add(5, 3)
  println("5 + 3 = " + sum.to_string())
  println("Hello，一多，下一代跨语言原生操作系统")
}
```

### 2. 组件间通信

```moonbit nocheck
// 导入其他组件的接口
///|
fn add(a : Int, b : Int) -> Int = "math" "add"

///|
fn read_file(path : String) -> String = "filesystem" "read"

// 调用其他组件的函数

///|
fn main {
  let sum = add(5, 3)
  println("5 + 3 = " + sum.to_string())

  let content = read_file("/etc/config")
  println("Config content: " + content)

  println("Hello，一多，下一代跨语言原生操作系统")
}
```

## 贡献指南

1. **Fork 项目**：在 GitHub 上 fork 项目到自己的账户
2. **创建分支**：创建一个新的分支进行开发
3. **提交代码**：提交代码并编写清晰的 commit 信息
4. **创建 PR**：创建 Pull Request 到主分支
5. **代码审查**：等待代码审查和合并

### 开发规范

- 代码风格：遵循项目的代码风格指南
- 测试：为新功能编写测试
- 文档：更新相关文档
- 性能：考虑代码性能影响

## 技术栈

### 主要语言

| 语言 | 应用场景 | 优势 |
|------|----------|------|
| MoonBit | 全栈开发（应用层、系统服务层、内核/驱动层、高性能计算层） | 安全、高效、跨平台、支持 Wasm 和 Native 编译 |

### 核心技术

| 技术 | 用途 | 版本 |
|------|------|------|
| WebAssembly | 跨语言组件模型 | WebAssembly 2.0 + 组件模型 |
| WASI | 系统接口标准 | WASI Preview 2 |
| Wasmtime | WebAssembly 运行时 | 最新稳定版 |
| MoonBit | 系统级语言 | 最新稳定版 |
| Rust | 系统编程 | 1.70+ |
| Emscripten | C/C++ 到 Wasm 编译 | 最新稳定版 |

## 未来规划

### 短期目标（1-2 年）

- 完成核心架构实现
- 支持基本硬件平台
- 构建基础系统服务
- 开发示例应用

### 中期目标（2-3 年）

- 完善生态系统
- 支持更多硬件平台
- 优化性能和安全性
- 吸引第三方开发者

### 长期目标（3+ 年）

- 成为主流操作系统选择
- 构建完整的应用生态
- 推动 WebAssembly 标准发展
- 引领下一代操作系统技术

## 许可证

本项目采用 Apache-2.0 许可证，详见 LICENSE 文件。

## 联系方式

- 项目主页：[GitHub 仓库](https://github.com/username/yiduo)
- 问题反馈：[Issue 页面](https://github.com/username/yiduo/issues)
- 讨论社区：[Discord 频道](https://discord.gg/yiduo-os)

---

*一多，下一代跨语言原生操作系统，为未来计算而生。*