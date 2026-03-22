# 一多 - 下一代组合式跨语言原生操作系统
技术白皮书与开发者指南

项目状态：架构设计与原型开发
核心理念：能 Wasm 就 Wasm，必须 Native 则 Native

## 大一统思想

"一多"操作系统的名称体现了其核心设计理念：**通过"一"的标准化实现"多"的可能性**。

### 🌟 "一"的统一

- **统一的硬件抽象**：UniHAL 定义了标准的硬件接口，将千差万别的硬件统一为有限的能力类别
- **统一的接口标准**：WIT 接口定义语言为所有组件提供了统一的通信规范
- **统一的运行时环境**：WebAssembly 运行时为不同语言的组件提供了统一的执行环境
- **统一的开发体验**：MoonBit 作为全栈语言，从内核到应用提供了统一的编程模型

### 🌍 "多"的包容

- **多语言支持**：支持 MoonBit、Rust、C/C++、JavaScript、Python 等多种编程语言
- **多硬件兼容**：通过适配器机制支持各种硬件设备，从传统 x86 到新兴 RISC-V
- **多应用场景**：从嵌入式设备到服务器，从 AI 推理到实时控制，满足多样化的应用需求
- **多生态集成**：无缝集成各语言的生态系统，充分利用现有技术资产

### 🚀 大一统的实现

一多操作系统通过"一即是多"与"多即是一"的智慧，实现了真正的大一统：

- **标准化接口**：定义了系统的"宪法"，确保所有组件遵循相同的规则
- **组件化设计**：将系统分解为可组合的组件，实现了高度的模块化和可扩展性
- **沙箱隔离**：保证了系统的安全性和稳定性，即使在多语言、多硬件的环境下
- **AI 赋能**：利用 AI 自动生成适配器，进一步降低了系统维护成本

这种大一统思想不仅解决了传统操作系统的"屎山"问题，也为未来的计算平台奠定了基础，实现了"一次编译，到处运行"的愿景。

## 核心价值

一多操作系统通过创新的组合式架构，解决了传统操作系统面临的诸多挑战，为未来计算提供了全新的解决方案。

### 🚀 核心价值

- **解决硬件驱动"屎山"问题**：通过 UniHAL 标准化接口和 Wasm 组件化驱动，避免了传统操作系统内核因硬件增多而膨胀的问题，内核保持精简稳定。
- **AI 原生设计**：内置 AI 能力，自动生成硬件适配器，从根本上消灭了维护旧硬件驱动的成本。
- **跨语言统一**：通过 WebAssembly 组件模型，支持多种编程语言无缝集成，打破语言壁垒。
  - **支持的语言**：MoonBit、Rust、C/C++、JavaScript、Python 等多种编程语言。
  - **实现方式**：通过 WIT（WebAssembly Interface Types）定义标准接口，不同语言编译为 Wasm 组件后可相互调用。
  - **具体优势**：
    - 开发者可以使用自己熟悉的语言开发组件
    - 充分利用各语言的生态优势（如 Python 的 AI 库、Rust 的安全性能）
    - 组件间通信无需语言特定的绑定或桥接代码
    - 一次编译，到处运行，跨平台兼容性好
- **安全隔离**：Wasm 沙箱提供天然的安全保障，驱动崩溃不影响系统，提高整体稳定性。
- **高性能与灵活性平衡**："能 Wasm 就 Wasm，必须 Native 则 Native"的混合架构，在安全和性能之间取得最佳平衡。
- **开发效率提升**：组件化设计和标准接口，让开发者"找组件、拼系统"，大幅提高开发效率。

### 🌟 技术创新

- **UniHAL "世界语"**：将成千上万种硬件归纳为有限的标准接口，硬件只需通过适配器接入，内核无需修改。
- **驱动组件化**：驱动不再是内核的一部分，而是运行在沙箱中的 Wasm 组件，彻底解决驱动稳定性问题。
  - **实现机制**：通过能力模型（Capability Model）实现沙箱内驱动对底层硬件的安全访问。驱动组件通过 UniHAL 接口请求特定硬件能力，内核验证权限后授予访问权限，实现了安全隔离与硬件控制的平衡。
- **AI 自动适配器**：利用 AI 理解硬件协议，自动生成符合 UniHAL 标准的适配器，实现硬件的即插即用。

### 🎯 应用场景

- **开发者**：通过组件市场快速构建应用，无需关心底层硬件差异，专注业务逻辑。
- **硬件厂商**：只需实现标准接口的适配器，无需修改操作系统内核，轻松接入系统。
- **终端用户**：获得更安全、更稳定、更高效的系统体验，支持更多硬件设备。

## 核心架构设计

### 1.1 组合式混合架构模型
一多操作系统采用组合式分层混合架构，利用 MoonBit、WebAssembly 和 Native 代码的组合能力，在保证系统安全与跨平台性的同时，保留对物理硬件的直接控制力。

组合编程是一多操作系统的核心设计理念，类似于 Go、Rust 等现代语言的设计思想，通过组合简单、可复用的组件来构建复杂的系统，而不是通过继承或修改现有代码。

### 🧠 组合思想的哲学内涵

一多操作系统的组合式设计理念蕴含着道家的哲学思想：**道生一，一生二，二生三，三生万物**。

- **道生一**：UniHAL 定义了统一的硬件抽象接口，这是系统的"道"，是一切的基础。
- **一生二**：基于统一接口，分化出 Native 和 Wasm 两种执行模式，分别对应性能和安全。
- **二生三**：通过 Native、Wasm 和适配器三种核心元素，构建完整的系统架构。
- **三生万物**：基于这三种元素的组合，衍生出无限的应用可能性和硬件兼容性。

这种组合思想不仅体现了系统设计的科学性，也融合了东方哲学的智慧，为一多操作系统注入了深厚的文化底蕴。

| 组件层 | 技术栈 | 运行模式 | 核心职责 | 典型组件 |
|--------|--------|----------|----------|----------|
| 应用组件层 | MoonBit (Wasm) | 沙箱隔离 | 业务逻辑、UI、AI 编排 | 办公套件、AI 助手 |
| 服务组件层 | MoonBit (Wasm + WASI) | 标准化接口 | 网络、文件、配置管理 | Web 服务器、日志服务 |
| 基础底座层 | MoonBit (Native) | 特权模式 | 内存管理、进程调度、中断 | 内存管理单元 (MMU) |
| 驱动组件层 | MoonBit (Native) | 硬件直连 | 硬件驱动、GPU/NPU 接口 | 显卡驱动、NPU 推理引擎 |

### 1.2 关键技术栈
- **MoonBit**：全栈开发语言（应用到内核），支持组合式编程。
- **Wasmtime**：WebAssembly 运行时，负责执行 Wasm 组件。
- **WASI (Preview 2)**：定义系统服务的标准接口。
- **UniHAL (统一硬件抽象层)**：基于组合式设计的硬件抽象层，将硬件资源抽象为可组合的对象，屏蔽底层硬件差异。

## 项目结构与工程配置

基于 MoonBit 的项目规范，一多操作系统采用组件化的目录结构如下：

```
yiduo/
├── kernel/               # 基础底座层
│   ├── boot/             # 启动代码
│   ├── mm/               # 内存管理
│   ├── drivers/          # 驱动组件
│   └── kernel.mbt        # 内核主文件
├── runtime/              # 运行时与服务组件
│   ├── wasm/             # Wasm 运行时
│   └── adapter/          # 适配器组件
│       ├── compute/      # 计算适配器
│       ├── stream/       # 流适配器
│       └── adapter_manager.mbt   # 适配器管理器
├── interfaces/           # 接口定义（WIT）
│   ├── base.wit          # 基础接口
│   ├── memory.wit        # 内存接口
│   ├── stream.wit        # 流接口
│   └── unihal.wit        # 主接口
├── apps/                 # 应用组件
│   ├── unihal_demo/      # UniHAL 演示组件
│   └── hello/            # Hello World 组件
├── sdk/                  # 开发工具包
│   ├── moonbit-sdk/      # MoonBit 语言 bindings
│   ├── rust-sdk/         # Rust 语言 bindings
│   └── cli/              # 命令行工具
├── tests/                # 测试目录
│   ├── unit/             # 单元测试
│   ├── integration/      # 集成测试
│   └── ci/               # 持续集成脚本
├── configs/              # 配置文件
│   ├── arm64.json        # ARM64 配置
│   └── riscv64.json      # RISC-V 配置
├── build/                # 构建脚本
│   ├── build.sh          # 主构建脚本
│   └── test.sh           # 测试脚本
├── docs/                 # 文档
│   ├── architecture.md   # 架构设计
│   └── usage.md          # 使用说明
├── moon.mod.json         # 根模块配置
└── README.md             # 项目说明
```

## 核心代码实现

### 3.1 基础底座层：内存管理 (Native)
文件路径：kernel/mm/allocator.mbt
这是系统的核心，必须使用 Native 模式以获得直接操作物理内存的能力。

```moonbit nocheck
// kernel/mm/allocator.mbt
// 编译目标：Native (直接运行在物理机)

/// 物理内存分配器
type PhysAllocator

/// 初始化物理内存管理
/// @native c "init_phys_memory"
fn init() -> Unit

/// 分配指定大小的物理页
/// @native c "alloc_pages"
fn alloc_pages(count: Int) -> Option[UInt64]

/// 释放物理页
/// @native c "free_pages"
fn free_pages(addr: UInt64, count: Int) -> Bool

/// @main
fn kernel_main {
  init()
  println("一多内核：内存管理单元初始化完成")
}
```

### 3.2 服务组件层：网络服务 (Wasm)
文件路径：runtime/network/tcp_stack.mbt
利用 Wasm 的沙箱特性保证网络服务的安全性。

```moonbit nocheck
// runtime/network/tcp_stack.mbt
// 编译目标：Wasm (沙箱运行)

/// 导入 WASI 网络接口
import wasi:io
import wasi:sockets/tcp

/// 处理 TCP 连接
fn handle_connection(conn: tcp:Socket) -> Result[Unit, String] {
  let data = io:read(conn, 1024)
  match data {
    Ok(bytes) => {
      println("收到数据: " + bytes.to_string())
      io:write(conn, "HTTP/1.1 200 OK\r\nHello from Yiduo OS")
      Ok(())
    }
    Err(e) => Err("读取错误: " + e)
  }
}

/// 启动 TCP 服务器
fn start_server(port: Int) -> tcp:Socket {
  let sock = tcp:Socket::new_ipv4()
  tcp:bind(sock, "0.0.0.0", port)
  tcp:listen(sock, 10)
  println("TCP 服务已启动，端口: " + port.to_string())
  sock
}
```

### 3.3 应用组件层：AI 编排 (Wasm)
文件路径：apps/ai_shell/shell.mbt
展示如何调用底层 Native 驱动进行高性能 AI 推理。

```moonbit nocheck
// apps/ai_shell/shell.mbt
// 编译目标：Wasm (安全沙箱)

/// 定义 NPU 推理接口 (WIT 绑定)
/// @component "npu" "infer"
fn npu_infer(model_path: String, input_data: List[Float]) -> List[Float]

/// 定义文件系统接口 (WASI)
/// @component "wasi:filesystem" "read"
fn read_file(path: String) -> Result[String, String]

fn main {
  println("一多 AI 终端启动")
  
  // 1. 读取配置 (WASI)
  match read_file("/config/model.cfg") {
    Ok(cfg) => println("配置加载成功"),
    Err(e) => println("配置错误: " + e)
  }

  // 2. 调用 NPU 驱动 (Native FFI)
  // 注意：这里通过组件模型调用，底层由 Native 实现
  let result = npu_infer(
    "/models/llm_v3.wasm",
    [0.1, 0.5, 0.9]
  )
  
  println("AI 推理结果: " + result.to_string())
}
```

## 构建与运行流程

### 4.1 构建脚本 (build.sh)

```bash
#!/bin/bash
echo "开始构建 一多操作系统..."

# 创建输出目录
mkdir -p bin/services bin/apps

# 构建内核 (Native)
echo "构建内核..."
moon build --target=native kernel/ -o bin/yiduo_kernel

# 构建系统服务 (Wasm)
echo "构建系统服务..."
moon build --target=wasm-gc runtime/ -o bin/services/

# 构建应用 (Wasm)
echo "构建应用..."
moon build --target=wasm-gc apps/ -o bin/apps/

echo "构建完成！"
```

### 4.2 运行时启动流程
1. Bootloader 加载 yiduo_kernel (Native)。
2. 内核初始化硬件，启动 Wasmtime 运行时。
3. 运行时加载 bin/services/ 中的核心服务。
4. 用户空间启动，加载 bin/apps/ 中的应用。

## 贡献指南

### 5.1 开发规范
- **命名规范**：
  - Native 组件：snake_case (C 风格兼容)
  - Wasm 组件：camelCase (MoonBit 风格)
- **接口定义**：
  - 所有组件间通信必须通过 interfaces/ 目录下的 .wit 文件定义。
  - 组件接口应遵循单一职责原则，保持简洁明了。
- **组件开发**：
  - 每个组件应有明确的职责和边界
  - 组件应通过标准接口与其他组件通信
  - 避免组件间的直接依赖，通过接口进行解耦
- **代码审查**：
  - Native 组件必须进行内存安全审查。
  - Wasm 组件必须进行接口兼容性审查。

### 5.2 测试策略
- **单元测试**：所有组件必须包含 _test 文件，测试组件的独立功能。
- **集成测试**：测试组件间的交互和组合。
- **组件市场验证**：发布到组件市场的组件必须通过安全和兼容性测试。

## 未来路线图

- **Phase 1 (原型)**：完成 MoonBit Native 内核与 Wasm 服务的通信。
- **Phase 2 (硬件支持)**：实现 UniHAL，支持 x86_64 和 ARM64 架构。
- **Phase 3 (AI 原生)**：集成 AI 驱动调度，实现自然语言操作系统交互。

## 许可证

本项目采用 Apache-2.0 许可证，详见 LICENSE 文件。


---

*一多，下一代跨语言原生操作系统，为未来计算而生。*