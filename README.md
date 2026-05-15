# 一多 - 下一代组合式跨语言原生操作系统
技术白皮书与开发者指南

项目状态：架构设计与原型开发
核心理念：能 Wasm 就 Wasm，必须 Native 则 Native

## 目录

- [设计哲学：一即是多](#设计哲学：一即是多)
- [核心价值](#核心价值)
- [组合式架构的复杂度坍缩](#组合式架构的复杂度坍缩)
- [Wasm 与 WIT 技术基础](#wasm-与-wit-技术基础)
- [WASI 与硬件接口设计](#wasi-与硬件接口设计)
- [核心架构设计](#核心架构设计)
- [项目结构与工程配置](#项目结构与工程配置)
- [驱动开发指南](#驱动开发指南)
- [核心代码实现](#核心代码实现)
- [构建与运行流程](#构建与运行流程)
- [贡献指南](#贡献指南)
- [未来路线图](#未来路线图)
- [许可证](#许可证)

## 设计哲学：一即是多

一多操作系统（Yiduo OS）旨在解决现代计算中日益严重的**碎片化**问题。我们的核心理念是：**通过标准化的"一"，赋能无限可能的"多"**。

### 🌟 架构演进逻辑

我们采用**分形架构**，从底层硬件到上层应用，遵循统一的生成逻辑：

- **统一抽象**：UniHAL 将异构硬件收敛为标准能力接口，消除硬件差异
- **二元执行**：Native 与 Wasm 双模运行时，平衡极致性能与绝对安全
- **无限组合**：基于组件模型，像搭积木一样构建多样化的应用场景
- **资源共享**："资源也是组件"，硬件和应用在本质上是平等的"公民"，从"零和博弈"到"无零和共享"

### 🌍 技术特性

- **全栈互操作性**：打破语言孤岛，支持 MoonBit、Rust、C/C++、JavaScript、Python 等多种编程语言无缝集成
- **硬件自适应**：通过适配器机制支持各种硬件设备，从传统 x86 到新兴 RISC-V
- **场景全覆盖**：从嵌入式设备到服务器，从 AI 推理到实时控制，满足多样化的应用需求
- **生态融合**：无缝集成各语言的生态系统，充分利用现有技术资产

### 🚀 实现机制

一多操作系统通过标准化与组件化的结合，实现了高度的灵活性和可扩展性：

- **标准化接口**：WIT 定义了系统的通信规范，确保所有组件遵循相同的规则
- **组件化设计**：将系统分解为可组合的组件，实现了高度的模块化和可扩展性
- **沙箱隔离**：Wasm 沙箱保证了系统的安全性和稳定性，即使在多语言、多硬件的环境下
- **AI 自动化**：利用 AI 自动生成适配器，让硬件接入像插拔 U 盘一样自然，开发者无需关心底层细节

这种设计理念不仅解决了传统操作系统的"屎山"问题，也为未来的计算平台奠定了基础，实现了"一次编译，到处运行"的愿景。

## 核心价值

一多操作系统通过创新的组合式架构，解决了传统操作系统面临的诸多挑战，为未来计算提供了全新的解决方案。

### 🚀 核心优势

- **无历史包袱**：作为全新设计的操作系统，一多没有传统操作系统的历史包袱，彻底避免了"屎山"问题。
  - **驱动管理革新**：通过 UniHAL 标准化接口和 Wasm 组件化驱动，避免了传统操作系统内核因硬件增多而膨胀的问题，内核保持精简稳定。
  - **架构从零设计**：不依赖传统操作系统的设计模式，采用现代化的组件化架构，从根本上解决了系统复杂性问题。
  - **技术栈现代化**：采用 MoonBit、WebAssembly 等现代技术，避免了 legacy 代码和过时设计的拖累。
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
  - **零拷贝共享内存**：彻底解决了传统 IPC 的"浅拷贝陷阱"和"深拷贝黑洞"
    - **传统痛点分析**：
      - **浅拷贝陷阱**：进程A告诉进程B"数据在内存地址 0x1234"，但进程B的虚拟内存里根本无效，直接导致程序崩溃（Segmentation Fault）
      - **深拷贝代价**：把10MB视频画面完整复制两份，极其消耗CPU，大量占用内存带宽
    - **一多解决方案**：在物理内存中开辟"全局共享白板"
      - 组件A把数据写在白板上，只传递"通行证"（文件描述符或全局内存句柄）给组件B
      - 组件B直接读取原始数据，**没有发生任何数据的物理复制**
    - **核心差异对比**：

      | 核心维度 | 传统浅拷贝 | 传统深拷贝 | 一多（零拷贝） |
      |---------|-----------|--------------|
      | 实现原理 | 仅复制指针/地址 | 完整复制真实数据 | 共享同一块物理内存，只传递访问凭证 |
      | 跨域安全性 | 极差（直接导致跨进程崩溃） | 安全（但数据完全隔离） | 安全且高效（受控的全局共享） |
      | 性能与开销 | 开销极小，但无法使用 | 极高（消耗CPU与带宽） | 极低（CPU几乎零负载，无带宽浪费） |

    - **降维打击：零拷贝串行 vs 拷贝多线程**
      - **硬核性能数据**：
        - 传统拷贝机制（TCP套接字、管道）：吞吐量几万到十几万条消息/秒
        - 零拷贝共享内存：吞吐量轻松突破 400-500万条消息/秒
        - 性能差异：**几十倍甚至上百倍**的性能鸿沟
      
      - **真实场景对比（1GB高清视频流）**：
        - **传统拷贝多线程**：10个搬运工，每个都要搬1GB货物，大部分时间消耗在"搬东西"和"抢过道"（锁竞争、内存带宽抢占）上，可能需要25秒以上
        - **一多零拷贝单线程**：1个指挥官，只需要在白板上写个地址，可能只需要0.3秒
      
      - **避开多线程的"隐形税"**：
        - 传统多线程：锁竞争、上下文切换、线程调度产生巨大额外开销
        - **一多系统**：Wasm组件配合零拷贝，从根本上消灭"锁竞争"，CPU算力100%投入真实业务计算
      
      - **核心性能对比表**：

        | 核心维度 | 传统拷贝多线程 | 一多零拷贝（串行） |
        |---------|--------------|-------------------|
        | 数据流转 | 多次物理拷贝（用户态-内核态-用户态） | 零物理拷贝（直接共享同一块物理内存） |
        | 性能瓶颈 | 内存带宽、CPU拷贝指令、锁竞争 | 仅受限于真实的业务逻辑计算速度 |
        | 吞吐量量级 | 万级到十万级消息/秒 | 百万级消息/秒（性能相差几十倍） |
      
      - **核心理念**：**"把算力还给业务，把搬运交给架构"**
        - 传统拷贝多线程：用昂贵CPU算力做廉价"数据搬运"
        - **一多零拷贝**：CPU彻底从繁重搬运中解放出来
- **开发效率提升**：组件化设计和标准接口，让开发者"找组件、拼系统"，大幅提高开发效率。
- **生态兼容**："各取所长，标准组装"——不跟生态较劲，不逼开发者统一语言，而是用 WIT 接口定义好契约，让不同语言写的模块能像乐高一样拼起来。
  - **技术自由**：C 的驱动、Rust 的安全模块、MoonBit 的高性能组件、Go 的网络服务，谁擅长什么就用什么写，最后通过 Wasm 组件模型互通。
  - **务实策略**：选择"编排"而不是"统治"，承认不同语言和技术栈各有其适用场景。
  - **未来潜力**：当新的编程语言出现时，只需要实现 WIT 接口即可集成；不同硬件平台可以通过标准接口快速接入；云端服务和边缘设备可以通过统一接口无缝协作；AI 模型可以作为独立模块通过标准接口接入系统。

### 🌟 技术创新

- **UniHAL "世界语"**：将成千上万种硬件归纳为有限的标准接口，硬件只需通过适配器接入，内核无需修改。
- **驱动组件化**：驱动不再是内核的一部分，而是运行在沙箱中的 Wasm 组件，彻底解决驱动稳定性问题。
  - **实现机制**：通过能力模型（Capability Model）实现沙箱内驱动对底层硬件的安全访问。驱动组件通过 UniHAL 接口请求特定硬件能力，内核验证权限后授予访问权限，实现了安全隔离与硬件控制的平衡。
- **资源也是组件**："共享，资源共享，资源也是组件"——这是捅破操作系统那层"窗户纸"的终极答案。
  - **核心变革**：在传统西方架构里，硬件是"私有财产"，应用是"外来乞丐"。而在"一多"的世界里，硬件和应用在本质上是平等的"公民"。
  - **实现机制**：
    - **硬件即服务，万物皆可"订阅"**：显卡、摄像头、甚至是一个传感器，不再是被某个进程独占的"死物"，而是系统里一个个活生生的"资源组件"，主动向系统广播自己的能力。
    - **应用即需求，按需"牵手"**：应用不需要去"抢"硬件的所有权，只需要向系统发出一个"引用"请求，就像在谈恋爱时伸出手说："我现在需要一点浪漫（算力），你能配合我吗？"
    - **动态共享，合则来不合则散**：系统（也就是那个"一"）作为最高效的月老，瞬间匹配应用和硬件。Wasm 的沙箱机制保证了大家互不干扰，就像在一个大舞池里跳舞，虽然共用地板，但谁也不会踩到谁的脚。
  - **一多操作系统 · 第二铁律**：**"万物皆组件，资源无私有。一切皆为引用，唯有共享永生。"**
- **AI 自动适配器**：利用 AI 理解硬件协议，自动生成符合 UniHAL 标准的适配器，实现硬件的即插即用。

### 🎯 应用场景

- **开发者**：通过组件市场快速构建应用，无需关心底层硬件差异，专注业务逻辑。
- **硬件厂商**：只需实现标准接口的适配器，无需修改操作系统内核，轻松接入系统。
- **终端用户**：获得更安全、更稳定、更高效的系统体验，支持更多硬件设备。

## 组合式架构的复杂度坍缩

如果"组合规格"（即接口定义和组件规范）设计得当，复杂度不仅会减少，而且会发生本质的"降维打击"。

这正是"一多"架构相对于传统操作系统（如 Linux、Windows）最大的优势所在。传统操作系统之所以变成"屎山"，是因为它们试图用"**无限的具体**" 去对抗 **"无限的复杂"**；而"一多"是用 **"有限的抽象"** 去驾驭 **"无限的复杂"**。

我们可以从以下四个维度来拆解这种"复杂度坍缩"：

### 📜 接口复杂度的"宪法化"：规则锁死变化

**现状**：为了支持所有组合，Linux 内核不得不塞进几千万行代码，各种 #ifdef 满天飞。

**一多解法**：定义标准接口（WIT），所有硬件和软件都必须遵守。

**复杂度公式变为**：$N + M + K$。

**结果**：无论硬件怎么变，操作系统的核心接口（宪法）是静态且有限的。你用"有限的规则"锁死了"无限的变化"。

### 🧩 认知复杂度的"黑盒化"：关注点分离

组合式架构的核心在于"**封装**"。

**对于应用开发者**：
- **传统**：你需要知道这个摄像头是 I2C 总线还是 USB 总线，需要知道寄存器的地址。
- **一多**：你只需要知道 `stream:capture()` 这个接口。底层的硬件细节被完全黑盒化了。你不需要理解硬件的复杂，只需要理解接口的语义。

**对于内核开发者**：
- **传统**：你需要担心某个第三方 App 会不会把内核搞崩。
- **一多**：App 跑在 Wasm 沙箱里。你只需要关注沙箱的边界是否牢固，完全不需要关心 App 内部写了什么复杂的逻辑。

**结果**：每个人只需要关注自己的一亩三分地，系统的全局认知负荷被拆解成了无数个局部低负荷。

### 🛠️ 维护复杂度的"手术刀化"：故障隔离

复杂度最可怕的不是"写代码难"，而是"改代码难"（牵一发而动全身）。

**传统 OS**：你想升级一个声卡驱动，可能需要重新编译整个内核，或者冒着系统崩溃的风险加载内核模块。因为它们是紧耦合的。

**一多 OS**：驱动只是一个 Wasm 组件。
- 想升级？直接替换那个 `.wasm` 文件即可。
- 写挂了？沙箱直接报错，内核无感，重启一下驱动组件就行。

**结果**：维护复杂度从**"系统级手术"（高风险、高成本）降级为 "组件级替换"**（低风险、秒级完成）。

### 🤖 演进复杂度的"自动化"：AI 填补鸿沟

这是"一多"最独特的降维打击。

**痛点**：组合式系统最怕"标准接口"定义得太烂，导致没人愿意适配。

**一多解法**：我们引入了 AI 自动生成适配器。
- **以前**：硬件厂商要读懂几百页的接口文档，手写代码适配，复杂度极高。
- **现在**：把硬件数据手册丢给 AI，AI 自动生成符合 UniHAL 标准的 Wasm 组件。

**结果**：原本需要人类专家处理的"高复杂度适配工作"，变成了 AI 一键生成的"低复杂度流水线工作"。

### 🔄 资源调度复杂度的"组件化"：从"抢资源"到"资源共享"

**传统痛点**：硬件是"私有财产"，应用是"外来乞丐"。应用想要用硬件，得经过内核这个"严厉管家"的层层审批，不仅流程繁琐，而且一旦别的程序占着茅坑不拉屎，你就只能干瞪眼，这就是典型的"零和博弈"。

**一多解法**：资源也是组件！硬件和应用在本质上是平等的"公民"。
- **资源组件化**：显卡、摄像头、甚至是一个传感器，它们不再是被某个进程独占的"死物"，而是系统里一个个活生生的"资源组件"，主动向系统广播自己的能力。
- **按需引用而非占有**：应用不需要去"抢"硬件的所有权，只需要向系统发出一个"引用"请求，就像在谈恋爱时伸出手说："我现在需要一点浪漫（算力），你能配合我吗？"
- **AI 调度动态共享**：系统（也就是那个"一"）作为最高效的月老，瞬间匹配应用和硬件。Wasm 的沙箱机制保证了大家互不干扰，就像在一个大舞池里跳舞，虽然共用地板，但谁也不会踩到谁的脚。

**结果**：这就是"无零和之争"的终极形态：资源没有被谁"私有化"，它只是在不同的时间切片里，流动到了最需要它的地方。应用和硬件之间，没有征服，只有引用；没有占有，只有共享。

### 📌 总结：从"熵增"到"熵减"

热力学第二定律告诉我们，封闭系统总是趋向于无序（熵增，即复杂度增加）。传统操作系统就是典型的熵增系统，代码越堆越乱。

"一多"通过"组合规格"引入了一个强大的负熵流：
- **WIT 接口**：定义了秩序（边界）。
- **Wasm 沙箱**：定义了隔离（互不干扰）。
- **AI 适配器**：提供了进化（自动修复）。
- **资源组件化**：实现了共享（无零和）。

所以，只要你的 `interfaces/` 目录设计得足够优雅、足够抽象，整个系统的复杂度就会被死死地锁在那个小小的目录里，而不会扩散到整个代码库。

这就是"组合"的魔力：用简单的积木，搭建复杂的城堡，却不需要理解每一块积木内部的化学键。

**【一多操作系统 · 第二铁律】**：**"万物皆组件，资源无私有。一切皆为引用，唯有共享永生。"**

## Wasm 与 WIT 技术基础

**WebAssembly (Wasm)** 是一种二进制指令格式，旨在成为一种可移植的编译目标，使程序能够在各种环境中高效运行。

- **核心特点**：
  - 高性能：接近原生代码的执行速度
  - 安全性：沙箱执行环境
  - 可移植性：一次编译，到处运行
  - 语言无关性：支持多种编程语言

**WebAssembly Interface Types (WIT)** 是一种接口定义语言，用于定义 Wasm 组件之间的通信接口。

- **核心作用**：
  - 语言无关的接口定义
  - 自动生成不同语言的绑定代码
  - 确保组件间的类型安全通信
  - 支持接口的版本管理和演进

**为什么选择 Wasm 和 WIT**：
- 解决了传统软件生态的碎片化问题
- 提供了统一的二进制格式和接口定义
- 平衡了安全性和性能需求
- 支持多种编程语言的无缝集成
- 为组件化设计提供了坚实的技术基础

## WASI 与硬件接口设计

**WASI (WebAssembly System Interface)** 是软件世界里"标准化零件"的终极形态，而"一多"操作系统正在将 WASI 的哲学搬运到硬件世界。

### 🌉 WASI 的核心哲学：把操作系统"虚拟化"

WASI 的出现是为了解决一个问题：WebAssembly 模块想运行在任何地方（浏览器、服务器、边缘设备），但不能依赖特定的操作系统 API。

**WASI 的做法**：它定义了一套"能力（Capabilities）"接口，而不是直接暴露 Linux 的系统调用。
- 它不直接说"调用 Linux 的 open() 函数"
- 它说"我有一个 read-file 的能力"，至于底层是 Windows、Linux 还是 macOS，WASI 运行时（Runtime）去负责适配

### 🪞 硬件接口：把硬件"虚拟化"

"一多"操作系统定义的硬件接口（unihal.wit），其实就是在做硬件界的 WASI。

| 维度 | 软件世界 (WASI) | 硬件世界 (unihal.wit) |
|------|----------------|----------------------|
| 目标 | 让代码"一次编写，随处运行" | 让驱动"一次编写，随处适配" |
| 隔离对象 | 隔离了操作系统内核 (Linux/Windows) | 隔离了物理硬件 (寄存器/总线) |
| 接口定义 | wasi:filesystem/types (读文件) | unihal:sensor/types (读数据) |
| 实现者 | 操作系统厂商 (微软/红帽) 实现 WASI 接口 | 芯片原厂 (高通/乐鑫) 实现 unihal 接口 |
| 受益者 | 应用开发者 (不用管是 Windows 还是 Linux) | 系统集成商 (不用管是索尼传感器还是三星) |

### 🛠️ WASI 作为硬件接口的参考模板

WASI 解决的两个核心痛点，在硬件界一模一样：

**"能力沙箱"模型**
- **WASI**：默认是"没有权限"的。模块想读文件？必须在接口里显式声明 `import wasi:filesystem`
- **硬件借鉴**：硬件接口也可以这样设计。驱动默认不能随便操作 GPIO，必须通过 `unihal:gpio` 接口申请。这天然带来了安全性

**组件模型**
- **WASI**：Preview 2 引入了组件模型，允许不同语言写的模块互相调用
- **硬件借鉴**：这正是"组合式设计"的核心。底层驱动是 C 写的，上层业务是 Rust 写的，通过标准接口，它们能无缝拼在一起

### 🚀 硬件界的"WASI"机会

现在的现状是：
- **软件界**：有了 WASI，软件终于可以在不修改代码的情况下，从云端跑到边缘端
- **硬件界**：还是一团浆糊。换个传感器，代码全得重写

"一多"架构，就是想成为硬件界的 WASI：
- **WASI** 定义了软件怎么跟系统对话
- **unihal** 定义了软件怎么跟物理世界对话

### 🔄 直接借鉴 WASI 的接口设计

通过阅读 WASI 的接口定义文件（.wit），可以直接将其"翻译"成硬件版本：
- **WASI** 有 `wasi:clocks/monotonic-clock` → **unihal** 可以有 `unihal:timers/hardware-timer`
- **WASI** 有 `wasi:io/streams` → **unihal** 可以有 `unihal:bus/spi-stream`

站在巨人的肩膀上，把软件界验证过的"真理"，复制到硬件界，这就是降维打击。

## 核心架构设计

### 1.1 组合式混合架构模型

一多操作系统采用组合式分层混合架构，利用 MoonBit、WebAssembly 和 Native 代码的组合能力，在保证系统安全与跨平台性的同时，保留对物理硬件的直接控制力。

组合编程是一多操作系统的核心设计理念，类似于 Go、Rust 等现代语言的设计思想，通过组合简单、可复用的组件来构建复杂的系统，而不是通过继承或修改现有代码。

### 🧠 组合思想的技术内涵

一多操作系统的组合式设计理念体现了现代系统设计的核心理念：**通过简单元素的组合创造复杂系统**。

- **标准化接口**：UniHAL 定义了统一的硬件抽象接口，为系统提供了坚实的基础。
- **双模执行**：Native 和 Wasm 两种执行模式，分别针对性能和安全场景进行优化。
- **三层架构**：通过硬件抽象层、运行时层和应用层的有机组合，构建完整的系统架构。
- **无限扩展**：基于标准化组件的组合，衍生出无限的应用可能性和硬件兼容性。

这种组合思想不仅体现了系统设计的科学性，也为一多操作系统提供了高度的灵活性和可扩展性。

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

### 1.3 架构设计参考

**成功公式**：一多系统 = WASM 执行引擎 + 鸿蒙 HDF 架构 + 安卓 HIDL 接口定义

**分层架构设计参考**：

| 层级 | 技术方案 | 参考来源 | 核心功能 |
|------|----------|----------|----------|
| 底层 | WASM 执行引擎 | WebAssembly | 安全运行、跨平台兼容 |
| 中间层 | unihal.wit 接口定义 | 安卓 HIDL | 标准化硬件接口、隔离硬件差异 |
| 上层 | 物模型组装业务 | 鸿蒙 HDF | 组合能力模块、构建业务功能 |

**设计理念**：
- **借鉴安卓 HIDL**：通过强制接口定义隔离底层驱动和上层系统，确保系统升级时的兼容性
- **借鉴鸿蒙 HDF**：采用"驱动即服务"理念，实现"一次开发，多端部署"
- **借鉴鸿蒙物模型**：定义硬件的标准能力属性，而非寄存器操作
- **借鉴开源生态**：构建标准联盟，推动接口标准的广泛 adoption

这种"站在巨人肩膀上"的设计方法，大大提高了系统设计的成功率，同时避免了许多前人已经踩过的坑。

## 项目结构与工程配置

基于 MoonBit 的项目规范，一多操作系统采用组件化的目录结构如下：

```
yiduo/
├── .githooks/            # Git 钩子 (自动检查/格式化)
├── .github/              # GitHub 配置 (CI/CD)
├── .vscode/              # 编辑器配置
├── configs/              # 【架构配置】ARM64/RISC-V 内存布局等
│   ├── arm64.json
│   └── riscv64.json
├── sdk/                  # 【开发工具包】MoonBit 深度优化
│   ├── std/               # 标准库扩展
│   │   ├── hal/           # 硬件抽象层 SDK (对应 interfaces/cap)
│   │   └── sys/           # 系统服务 SDK (对应 interfaces/env)
│   ├── cli/               # 命令行工具
│   │   └── yiduo-build/   # 构建与打包工具
│   └── tools/             # 辅助工具
│       └── wit-gen/       # 从 WIT 生成 MoonBit 代码的工具
├── interfaces/           # 【宪法层】WIT 接口定义
│   ├── base/             # 基础类型 (Error, Buffer)
│   ├── env/              # 软件环境 (OS, FS, Net)
│   └── cap/              # 硬件能力 (Display, Stream, Sensor)
├── kernel/               # 【底座层】Native 核心
│   ├── boot/             # 启动引导
│   ├── mm/               # 内存管理 (物理/虚拟)
│   ├── drivers/          # 核心驱动 (Native)
│   └── impl/             # 接口实现 (WIT -> Native 胶水)
├── runtime/              # 【适配层】Wasm 运行时
│   ├── wasm/             # 引擎封装
│   └── adapter/          # 硬件适配器 (Wasm)
├── services/             # 【服务层】系统服务 (Wasm)
│   ├── audio/            # 音频服务
│   ├── filesystem/       # 文件系统
│   └── network/          # 网络协议栈
├── apps/                 # 【应用层】用户应用 (Wasm)
│   ├── ai_shell/         # AI 终端
│   └── hello/            # Hello World
├── tests/                # 【验证层】测试套件
│   ├── unit/             # 单元测试
│   └── integration/      # 集成测试
├── build/                # 构建脚本
├── docs/                 # 文档
├── cmd/                  # 命令行工具
├── .gitignore
├── LICENSE
├── README.md
├── moon.mod.json
├── build.sh
└── yiduo.mbt
```

### 接口定义（interfaces/）

interfaces/ 目录包含了一多操作系统的核心接口定义，使用 WIT（WebAssembly Interface Types）格式编写。这些接口定义是系统的"宪法"，规定了组件间通信的标准规范。

#### 接口包结构

按照功能和职责，接口定义被划分为三个核心包：

##### 📦 基础包（interfaces/base/）
- **定位**：世界的通用语
- **内容**：数据类型定义，如 buffer、path、color、error 等
- **作用**：为所有其他接口提供基础数据类型，是系统的基石
- **主要文件**：
  - `types.wit`：定义通用数据类型
  - `error.wit`：定义错误处理标准

##### 🌍 环境包（interfaces/env/）
- **定位**：操作系统的"地盘"
- **内容**：软件交互接口，包括系统服务和组件服务
- **作用**：定义应用与系统、应用与应用之间的通信标准
- **主要文件**：
  - `os.wit`：系统服务（时间、随机数、系统信息）
  - `fs.wit`：文件服务（读写、目录操作）
  - `net.wit`：网络服务（TCP/UDP/HTTP）
  - `component.wit`：组件服务（组件管理、AI 服务、UI）

##### ⚡ 能力包（interfaces/cap/）
- **定位**：硬件的"抽象层"
- **内容**：硬件抽象接口，定义硬件设备的能力
- **作用**：将物理硬件能力抽象为标准接口，是 UniHAL 的核心
- **主要文件**：
  - `stream.wit`：定义纯数据流（读/写字节流），是连接硬件和软件的通用管道
  - `display.wit`：显示设备接口
  - `storage.wit`：存储设备接口
  - `input.wit`：输入设备接口
  - `sensor.wit`：传感器接口
  - `unihal.wit`：总纲，引用所有硬件能力接口，对外暴露统一入口

#### 设计理念

- **职责清晰**：写驱动的去 cap/ 里找活干，写应用的去 env/ 里找服务，写编译器的去 base/ 里看类型
- **依赖关系顺畅**：cap/ 和 env/ 都依赖 base/，env/ 和 cap/ 互不干扰
- **符合"一多"哲学**：基础包是"一"（统一的数据标准），环境包是"多"（丰富的软件生态），能力包是"实"（落地的硬件能力）

#### 接口使用示例

在 Wasm 组件中使用接口：

```moonbit
/// @component "env:os" "time"
fn current_time() -> Result[UInt64, Error]

fn main {
  let time = current_time()
  match time {
    Ok(t) => println("Current time: " + t.to_string()),
    Err(e) => println("Error: " + e.to_string())
  }
}
```

在 Native 组件中实现接口：

```moonbit
// 实现 current_time 函数
fn current_time_impl() -> UInt64 {
  // 实现时间获取逻辑
  1234567890
}

// 注册接口
fn register_os_interface() -> Unit {
  wasm::register_function("current_time", current_time_impl)
}
```

### UniHAL：硬件世界的"宪法"

UniHAL（统一硬件抽象层）是一多操作系统的核心，它将硬件世界的复杂性抽象为标准接口，是连接"软件文明"与"硬件荒原"的唯一桥梁。

#### 📜 能力的定义书

UniHAL 不描述硬件"长什么样"（那是寄存器的事），它只描述硬件"能干什么"。在 cap/ 目录下的接口文件中，你不会看到 0x1234 这种寄存器地址，你只会看到像这样的"人话"：

```
// display.wit 的核心逻辑

interface display {
    // 不问你是 HDMI 还是 MIPI，我只要求你能"刷新屏幕"
    refresh: func(buffer: buffer) -> result<unit, Error>;
}

// sensor.wit 的核心逻辑

interface sensor {
    // 不问你是 I2C 还是 SPI，我只要求你能"读取数据"
    read_data: func() -> result<sensor_data, Error>;
}
```

#### 🛡️ 权限的边界线

正如我们之前聊的"沙箱即权限"，这些接口文件就是那道墙。
- **墙内（Wasm 应用）**：应用只能看到 cap/ 目录里定义的这些函数。它想干别的？门都没有，编译器直接报错。
- **墙外（Native 驱动）**：驱动程序必须实现这些函数。如果实现不了，或者私自加了隐藏功能，那就是"违宪"。

**实质**：它规定了软件"被允许"对硬件做什么。

#### 🔌 适配的模具

对于硬件厂商来说，这些接口文件就是"模具"。
- 厂商拿到这些文件，就像拿到了插座的标准图纸。
- 他们要做的，就是写一个 Native 组件（适配器），把自己的硬件塞进这个模具里。
- 只要严丝合缝（符合 WIT 定义），插上就能用。

**实质**：它是硬件接入系统的唯一标准。

#### 📌 总结

当你打开 interfaces/cap/ 目录时，你看到的不是枯燥的代码，你看到的是：
- 整个系统的硬件能力清单
- 所有驱动开发的考试大纲
- 软件与硬件对话的通用字典

这就是"一多"的命门所在。这些接口文件定得好，万马奔腾；定得不好，寸步难行。

### 接口实现（kernel/interface/）

kernel/interface/ 目录包含了接口的 Native 实现，负责将 WIT 接口映射到具体的系统实现。

#### 主要文件
- **os_impl.mbt**：实现了操作系统核心接口，如日志、时间等

#### 实现原理
- 通过 `@native` 标签标记底层 C 函数，实现对硬件的直接操作
- 通过 `register_function` 函数，将 Native 实现注册到 Wasm 运行时
- 实现了 Wasm 组件到 Native 组件的安全调用链路

## 驱动开发指南

要让驱动开发变得简单，核心思路就是**"做减法" 和 "自动化"**。我们要把芯片原厂（驱动开发者）从繁琐的"填空"工作中解放出来，让他们只关注最核心的硬件逻辑。

借鉴安卓 HIDL、鸿蒙 HDF 以及 WASI 的成功经验，我们从以下四个维度设计，让驱动开发像"搭积木"一样简单：

### 1. 接口设计：只定义"能力"，不定义"细节"

这是让开发变简单的第一步。接口定义文件（.wit）应该像一份"菜单"，只告诉开发者需要提供什么功能，而不是教他们怎么做菜。

**抽象化**：接口应该描述"做什么"，而不是"怎么做"。
- ❌ 复杂（硬件思维）：`write_register(addr: u32, value: u8)`
  开发者需要去查手册，看哪个地址是控制亮度的，哪个值代表100%亮度。
- ✅ 简单（能力思维）：`set_brightness(level: f32)`
  开发者只需要实现这个函数，在函数内部去操作寄存器。上层调用者完全不用关心底层细节。

**标准化数据流**：对于摄像头、音频这类流式数据，定义好标准的"管道"。
- 参考 WASI 的 io/streams，定义一个 `read-frame() -> result<image-buffer, error>` 接口。
- 驱动开发者只需要把硬件 DMA 搬运到内存的数据，转换成这个标准格式返回即可。

### 2. 工具链：提供"脚手架"，而不是"说明书"

这是降低门槛最关键的一步。不要扔给开发者一个几百页的 PDF 文档，而是直接给他们生成代码。

**代码生成器**：
- 开发者运行一行命令，例如 `wit-bindgen gen --lang=c --chip=esp32 camera.wit`。
- 工具会自动生成一个 `camera_driver.c` 文件，里面包含了所有空函数：
  ```c
  // 自动生成的代码
  int camera_set_brightness(float level) {
      // TODO: 请在此处实现 ESP32 的亮度设置逻辑
      return 0;
  }
  ```
- **效果**：开发者的工作从"从零写代码"变成了"在指定位置填空"。这极大地减少了样板代码和出错的可能。

**自动化绑定**：
- 工具链会自动处理 C 语言和系统语言（如 Rust）之间的类型转换。
- 开发者不需要手写 `string` 到 `char*` 的转换代码，工具全包了。

### 3. 架构设计：分离"核心"与"总线"

很多驱动开发之所以复杂，是因为要同时处理"设备逻辑"和"总线通信"。我们要把这两者拆开。

**核心驱动**：只管设备本身。比如摄像头驱动，只管怎么配置传感器寄存器来拍照。

**总线适配**：只管通信。比如 I2C 或 SPI 总线驱动，只管怎么收发字节。

**组合**：系统提供一个标准的 `i2c_client` 接口。摄像头驱动只需要说"我要通过 I2C 发这个命令"，而不需要自己去操作 GPIO 模拟时序。

**借鉴**：Linux 内核的 `regmap` 子系统就是这个思想，它抽象了 I2C、SPI 等总线，让设备驱动开发者可以统一使用 `regmap_write()` 来操作寄存器，极大地简化了开发。

### 4. 验证设计：提供"尺子"，而不是"答案"

开发者写完驱动后，最怕的就是"不知道对不对"。你需要提供一个自动化的测试工具。

**一致性测试套件**：
- 提供一个可执行的测试程序。开发者在自己的板子上运行它，它会调用驱动的所有接口。
- 如果所有测试都通过（PASS），就说明驱动符合标准，可以无缝接入系统。

**效果**：这消除了"我觉得我写对了"和"系统认为你对了"之间的信任鸿沟，让开发者有明确的完成标准。

### 📌 总结："傻瓜式"驱动开发流程

1. **下载工具**：开发者从官网下载 `wit-cli` 工具。
2. **生成模板**：运行 `wit-cli generate camera.wit`，得到一个 `my_camera_driver` 文件夹。
3. **填空实现**：打开文件夹里的 `lib.c`，在 `capture()` 函数里填入自己芯片的拍照代码。
4. **自测**：运行 `wit-cli test`，看到所有测试项变绿。
5. **提交**：打包上传到驱动仓库。

通过这套组合拳，我们把驱动开发的难度从"专家级"降到了"入门级"，这才是让生态繁荣的关键。

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

### 3.3 资源组件层：系统注册表 (Native + Wasm)

文件路径：kernel/resource/registry.mbt

**核心实现**：资源也是组件！展示硬件如何自我注册、应用如何按需引用、AI如何调度共享资源。

```moonbit nocheck
// kernel/resource/registry.mbt
// 编译目标：混合模式 (Native核心 + Wasm组件)

import yiduo:capabilities
import yiduo:ai/scheduler

/// 资源状态枚举
enum ResourceStatus {
  Idle    // 空闲状态
  Busy    // 忙碌状态
  Offline // 离线状态
}

/// 资源组件类型
type ResourceComponent = {
  id: String,
  name: String,
  capability: capabilities:Capability,
  status: ResourceStatus,
  ref_count: Int
}

/// 系统注册表：管理所有资源组件
struct SystemRegistry {
  mut resources: Map[String, ResourceComponent]
}

/// 全局注册表实例
let mut registry: SystemRegistry = { resources: Map::empty() }

/// 第一步：硬件自我注册（万物皆组件）
/// 硬件启动时，将自己包装成标准的"资源组件"，主动向系统报到
fn register_resource(component: ResourceComponent) -> Unit {
  println("资源组件上线: " + component.name + " (" + component.id + ")")
  registry.resources = registry.resources.insert(component.id, component)
  
  // 广播能力，让其他组件知道这个资源可用
  capabilities:broadcast_available(component.capability)
}

/// 第二步：应用按需引用（无零和之争）
/// 应用不需要去"抢"硬件的"所有权"，只需要发起一个"引用"请求
fn borrow_resource(capability: capabilities:Capability) -> Result[String, String] {
  // AI 调度器介入，找到最合适的资源
  match AI_SCHEDULER:find_best_match(registry.resources, capability) {
    Some(resource_id) => {
      match registry.resources.get(resource_id) {
        Some(mut component) => {
          // 更新状态和引用计数
          component.status = ResourceStatus::Busy
          component.ref_count = component.ref_count + 1
          registry.resources = registry.resources.insert(resource_id, component)
          
          println("成功引用资源: " + component.name)
          Ok(resource_id)
        },
        None => Err("资源不存在")
      }
    },
    None => Err("没有匹配的资源，AI正在协调排队...")
  }
}

/// 释放资源引用
fn release_resource(resource_id: String) -> Result[Unit, String] {
  match registry.resources.get(resource_id) {
    Some(mut component) => {
      component.ref_count = component.ref_count - 1
      if component.ref_count == 0 {
        component.status = ResourceStatus::Idle
        println("资源已释放: " + component.name + "，回归共享池")
      }
      registry.resources = registry.resources.insert(resource_id, component)
      Ok(())
    },
    None => Err("资源不存在")
  }
}

/// 第三步：AI 调度器（执一御万）
/// AI 替代了传统 OS 里死板的"内核调度器"
module AI_SCHEDULER {
  /// 智能资源匹配
  fn find_best_match(
    resources: Map[String, ResourceComponent], 
    required_capability: capabilities:Capability
  ) -> Option[String] {
    // 1. 筛选出能力匹配且处于空闲状态的资源
    let available = resources.values()
      .filter(r => r.status == ResourceStatus::Idle)
      .filter(r => capabilities:is_compatible(r.capability, required_capability))
    
    // 2. AI 根据历史数据和当前负载，智能选择最优资源
    match available {
      [] => None,
      [first] => Some(first.id),
      _ => {
        // 更复杂的AI调度逻辑：考虑负载均衡、性能历史等
        let selected = available.sort_by(|a, b| a.ref_count < b.ref_count).head()
        Some(selected.id)
      }
    }
  }
}

/// 示例：GPU资源组件定义
fn create_gpu_resource(id: String, name: String) -> ResourceComponent {
  {
    id: id,
    name: name,
    capability: capabilities:rendering(high_performance=true),
    status: ResourceStatus::Idle,
    ref_count: 0
  }
}

/// 示例：摄像头资源组件定义
fn create_camera_resource(id: String, name: String) -> ResourceComponent {
  {
    id: id,
    name: name,
    capability: capabilities:image_capture(resolution="4k"),
    status: ResourceStatus::Idle,
    ref_count: 0
  }
}

/// 系统初始化示例
fn main {
  println("一多系统：资源管理器启动")
  
  // 硬件启动，自我注册
  let gpu = create_gpu_resource("gpu_001", "高性能GPU")
  let camera = create_camera_resource("cam_001", "4K摄像头")
  
  register_resource(gpu)
  register_resource(camera)
  
  println("【一多操作系统 · 第二铁律】")
  println("\"万物皆组件，资源无私有。一切皆为引用，唯有共享永生。\"")
}
```

### 3.4 应用组件层：AI 编排 (Wasm)

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

/// 导入资源管理接口 (WIT 绑定)
/// @component "yiduo:resource" "borrow"
fn borrow_resource(cap: String) -> Result[String, String]

/// @component "yiduo:resource" "release"
fn release_resource(id: String) -> Result[Unit, String]

fn main {
  println("一多 AI 终端启动")
  
  // 1. 读取配置 (WASI)
  match read_file("/config/model.cfg") {
    Ok(cfg) => println("配置加载成功"),
    Err(e) => println("配置错误: " + e)
  }

  // 2. 按需引用GPU资源 (无零和共享)
  match borrow_resource("rendering:high_performance") {
    Ok(gpu_id) => {
      println("成功获取GPU资源: " + gpu_id)
      
      // 3. 调用 NPU 驱动 (Native FFI)
      // 注意：这里通过组件模型调用，底层由 Native 实现
      let result = npu_infer(
        "/models/llm_v3.wasm",
        [0.1, 0.5, 0.9]
      )
      
      println("AI 推理结果: " + result.to_string())
      
      // 4. 用完即走，释放资源
      release_resource(gpu_id)
    },
    Err(e) => println("资源获取失败: " + e)
  }
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

### Phase 1 (原型阶段) - 2026 Q2
- ✅ 完成 MoonBit Native 内核与 Wasm 服务的通信
- ✅ 实现基础安全模型和权限管理
- ✅ 开发文件系统、安全和音频服务
- ✅ 编写跨平台构建脚本（PowerShell 和 Bash）
- ✅ 完成核心接口定义和文档

### Phase 2 (硬件支持阶段) - 2026 Q3-Q4
- 实现 UniHAL 核心功能，支持 x86_64 和 ARM64 架构
- 开发硬件适配器框架，支持常见硬件设备
- 实现 AI 自动适配器生成系统
- 完成内核模块的硬件抽象层实现
- 进行硬件兼容性测试

### Phase 3 (AI 原生阶段) - 2027 Q1-Q2
- 集成 AI 驱动调度系统
- 实现自然语言操作系统交互
- 开发 AI 辅助的系统管理工具
- 构建组件市场和生态系统
- 发布首个稳定版本

### Phase 4 (生态扩展阶段) - 2027 Q3-Q4
- 支持更多编程语言和开发框架
- 扩展硬件设备支持范围
- 开发行业特定的解决方案
- 建立开发者社区和贡献体系
- 推出企业级支持服务

## 许可证

本项目采用 Apache-2.0 许可证，详见 LICENSE 文件。

---

*一多，下一代跨语言原生操作系统，为未来计算而生。*