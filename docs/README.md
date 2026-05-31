# 一多 OS 技术文档

## 概述

一多 OS 是一个高性能可编程调度系统，采用 **MoonBit** 语言开发。核心设计围绕**四元架构**（意志、DNA、树形、链式），通过配置驱动的方式，实现组件化、可编程的系统调度。

## 文档目录

| 文档 | 说明 |
|------|------|
| [004.快速开始.md](./004.快速开始.md) | 快速上手，环境准备，开发命令 |
| [001.架构设计.md](./001.架构设计.md) | 系统整体架构、四元哲学、数据流、系统契约 |
| [002.模块参考.md](./002.模块参考.md) | 五个核心模块详解（core/scheduler/config/bootstrap） |
| [005.API参考.md](./005.API参考.md) | 所有API完整文档 |
| [003.性能优化.md](./003.性能优化.md) | 高性能优化策略（Int ID、FixedArray、无装箱） |
| [006.测试文档.md](./006.测试文档.md) | 12 个测试用例详解（白盒+集成+基准） |

## 源代码结构

```
runtime/                    主包 (is-main: true)
├── bootstrap.mbt       启动器入口
├── meta_kernel/        元内核（信任根 · 自举起点）
├── core/               核心基础包（链式血液系统）
├── scheduler/          调度系统（心脏）
├── component/          器官DNA定义
├── components/         Wasm组件实例（枝叶分叉）
├── config/             意志层（配置解析 · 递归 YAML 解析器）
└── benchmark/          性能基准测试

configs/                    组件配置（008 规范）
├── bootstrap.yaml          自举配置（用户选择实现）
├── app.yaml                应用配置
└── components/             组件定义
    ├── wamr-runtime.yaml   WAMR 微运行时（两种实现）
    ├── display.yaml        显示组件
    ├── counter.yaml        计数器组件
    └── scheduler.yaml      调度器组件

runtime/wamr/               WAMR 运行时集成
├── moon.pkg              动态构建（由 build_wamr.ps1 从 YAML 自动生成）
├── c_src/                 C FFI 适配层
│   ├── wamr_adapter.c    WAMR API 适配（__has_include 自检）
│   ├── wamr_config.h     构建时自动生成（强制 stub 模式）
│   └── native_imports.c  Native 函数注册
└── wasm_runtime_wamr.mbt MoonBit 绑定

tools/                      自举工具集
└── yaml_query/             递归 YAML 查询工具
    ├── moon.pkg           依赖 config/fs/core 包
    └── main.mbt           从组件 YAML 提取构建元数据输出 JSON

scripts/
└── build_wamr.ps1       自举构建脚本
                          ├── 读取 bootstrap.yaml -> 确定实现
                          ├── 递归调用 yaml_query 解析组件 YAML
                          ├── 从 YAML 派生所有构建参数（零硬编码）
                          └── 动态生成 moon.pkg
```

## WAMR 组件配置架构（自举构建）

WAMR (wasm-micro-runtime) 作为标准的**操作系统组件**，遵循 008 组件配置格式规范。
所有构建参数从组件 YAML 配置文件**递归派生**，实现零硬编码的自举构建。

### 配置层次

```
用户选择 → bootstrap.yaml: runtime.implementation (wamr-real / wamr-stub)
                 │
                 ▼
组件定义 → configs/components/wamr-runtime.yaml
    ├── implementations:
    │   ├── wamr-real  (真实 WAMR，需预编译 liblibiwasm.a)
    │   │   ├── build.native-library: "third_party/.../liblibiwasm.a"
    │   │   ├── build.include-paths: ["third_party/.../include"]
    │   │   ├── build.system-libs: {windows: [ws2_32, ntdll], ...}
    │   │   └── build.linker-opts: "-Wl,--whole-archive ..."
    │   └── wamr-stub  (零依赖回退)
    └── default-strategy:
        ├── preferred: wamr-real
        └── fallbacks: [wamr-stub]
                 │
                 ▼
递归 YAML 解析 → tools/yaml_query (MoonBit 自举工具)
    ├── 使用 config 包的 YamlNode 递归解析器
    ├── 提取匹配实现的 build 节点
    └── 输出 JSON 供构建脚本消费
                 │
                 ▼
构建脚本 → scripts/build_wamr.ps1
    ├── 调用 yaml_query 工具 → 获取构建元数据 JSON
    ├── 从 JSON 派生：include-paths, native-library, system-libs, linker-opts
    ├── 动态生成 runtime/wamr/moon.pkg（cc-flags + cc-link-flags）
    └── 生成 wamr_config.h（WAMR_FORCE_STUB 控制编译期模式）
                 │
                 ▼
编译期 → C 代码 __has_include 自检 + WAMR_AVAILABLE 宏
    ├── WAMR_AVAILABLE=1 → 编译真实 WAMR 路径（链接 liblibiwasm.a）
    └── WAMR_AVAILABLE=0 → 编译 Stub 路径（零依赖回退）
```

### 自举编程原则

系统**读取自身配置文件决定行为**，所有构建参数从组件定义派生：

| 原则 | 实现 |
|------|------|
| **配置即代码** | `moon.pkg` 由 `build_wamr.ps1` 从 YAML 自动生成 |
| **递归解析** | `config` 包的 `YamlNode` 递归解析器替代 Powershell 正则平扫 |
| **零硬编码** | 库路径、系统库、编译选项全部从 `wamr-runtime.yaml` 读取 |
| **单源真理** | YAML 配置文件是构建参数的唯一真实来源 |
| **跨平台** | 配置中为不同平台定义不同的 `system-libs`，脚本自动适配 |

### 递归 YAML 解析器

`runtime/config/config_loader.mbt` 实现了纯 MoonBit 的递归 YAML 解析器：

```moonbit
pub enum YamlNode {
  YamlScalar(String)                    // 标量值
  YamlMapping(Array[(String, YamlNode)]) // 映射（递归）
  YamlSeq(Array[YamlNode])              // 序列（递归）
}

pub fn parse_yaml(content : String) -> Result[YamlNode, String]
```

`yaml_query` 工具使用此解析器读取组件 YAML，提取构建元数据输出 JSON：

```powershell
# 参数通过文件传递（避免 sandbox 拦截）
$inputFile = "_build/yq_input.txt"
Set-Content $inputFile -Value "$yamlPath`n$implName"

# 执行 yaml_query → 获取构建参数 JSON
$buildMetaJson = & $yamlQueryExe
$buildMeta = $buildMetaJson | ConvertFrom-Json

# 所有参数从 JSON 派生
$ccFlags = "-I" + $buildMeta.includePaths[0]
$linkerOpts = $buildMeta.linkerOpts
$linkerOpts = $linkerOpts.Replace('{native-library}', $absLibPath)
```

### 双模运行时对比

| 模式 | 命令 | 依赖 | 性能 |
|------|------|------|------|
| **真实 WAMR** | `.\scripts\build_wamr.ps1` → `moon test --target native` | CMake, git, MinGW | 完整沙箱隔离 |
| **Stub** | `.\scripts\build_wamr.ps1 -Stub` → `moon test --target native` | 无 | 功能受限，仅作回退 |

两种模式均 **36/36 测试通过**。

## 相关文档

- [操作系统/目录](../操作系统/核心调度系统/目录结构说明.md) - 完整文档索引
- [020.自举愿景文档](../操作系统/核心调度系统/020.一多%20OS%20自举愿景文档.md) - 裸机自举路线图
- [021.高性能调度架构设计](../操作系统/核心调度系统/021.高性能调度架构设计.md) - 调度架构详细设计
- [008.组件配置格式规范](../操作系统/01.核心调度系统/008.组件配置格式规范.md) - 组件配置 YAML 规范

## 技术栈

- **语言**: MoonBit（调度核心）+ Rust/C（硬件抽象层，未来）
- **编译目标**: Native（直接编译为机器码）
- **Wasm 运行时**: WAMR（组件配置驱动，用户可选）
- **组件模型**: Wasm 组件 + Native 组件

## 快速开始

```bash
# 格式化代码
moon fmt

# 更新接口
moon info

# Stub 模式测试（无需 WAMR 依赖）
moon test --target native

# 启用真实 WAMR（需 CMake + git）
.\scripts\build_wamr.ps1

# 真实 WAMR 测试
moon test --target native
```