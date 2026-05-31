# 一多 OS 核心运行时（Yiduo Core Runtime）

可编程自举调度系统的核心运行时。

## 目录结构

```
runtime/                    主包 (is-main: true)
├── bootstrap.mbt       启动器入口
├── meta_kernel/        元内核（信任根 · 自举起点）
├── core/               核心基础包（链式血液系统）
├── scheduler/          调度系统（心脏）
├── component/          器官DNA定义
├── components/         Wasm组件实例（枝叶分叉）
├── config/             意志层（配置解析）
└── benchmark/          性能基准测试
```

## 模块说明

### bootstrap.mbt
系统入口，初始化调度器，加载配置，注册组件，启动调度循环

### meta_kernel/
系统中唯一硬编码的部分，自举的起点，提供最小的信任锚点

### core/
核心基础包（链式血液系统），提供所有高性能基础设施：
- **message.mbt**：三种消息模式（小复制/中句柄/大共享内存），三种优先级
- **ring_buffer.mbt**：零拷贝环形队列，入队/出队只移动指针
- **memory_pool.mbt**：预分配内存池，引用计数管理
- **memory_manager.mbt**：句柄安全系统（所有权追踪、防双重释放）
- **event_bus.mbt**：事件总线（发布-订阅模式）
- **local_balancer.mbt**：局部负载均衡（神经反射）
- **circuit_breaker.mbt**：熔断器（免疫系统）

### scheduler/
调度系统核心（高性能版），负责：
- 三个优先级独立队列（高/普通/低）
- 三种消息模式分发
- 组件亲和度追踪
- 批处理模式
- 句柄安全集成

### component/
器官DNA定义，提供组件基础接口：
- 组件配置（ComponentConfig）
- 能力声明（Capability）
- 组件状态管理（ComponentState）

### components/
Wasm 组件实例（树形架构的枝叶分叉）：
- **event_bus_component.mbt**：事件总线组件（血液系统Wasm版）
- **scheduler_component.mbt**：调度器组件
- **ai_brain_component.mbt**：AI大脑组件

### config/
意志层，配置解析模块，负责解析内置/外部配置文件

### benchmark/
性能基准测试，测试消息吞吐量、队列操作延迟、调度循环效率

## WAMR Wasm 运行时

**位置**: [runtime/wamr/](../runtime/wamr/)

WAMR (wasm-micro-runtime) 作为标准的操作系统组件集成，提供 Wasm 沙箱执行能力。

### 组件配置驱动

WAMR 遵循 008 组件配置格式规范，用户通过 `configs/bootstrap.yaml` 选择实现：

- **wamr-real**: 真实 WAMR 运行时，需预编译 `libvmlib.a`（高性能沙箱隔离）
- **wamr-stub**: 零依赖回退实现（功能受限，用于开发/测试）

### 编译期自检

C 适配层使用 `__has_include` 在编译期自动检测 WAMR 可用性：

```c
#if __has_include("../../../third_party/.../wasm_export.h")
  // 编译真实 WAMR 路径，需链接 libvmlib.a
#else
  // 编译 Stub 路径，零依赖
#endif
```

### 构建命令

```powershell
# 启用真实 WAMR（需 CMake + git + MinGW）
.\scripts\build_wamr.ps1

# 切换回 Stub 模式
.\scripts\build_wamr.ps1 -Stub

# 跳过 git clone（源码已存在时）
.\scripts\build_wamr.ps1 -SkipClone

# 验证
moon test --target native
```

### 架构理念

- **自举**: 构建脚本读取自身组件配置，决定如何构建
- **可编程**: 用户通过 YAML 配置选择运行时实现，无需改代码
- **零侵入**: Stub 模式无任何外部依赖，moon.pkg 保持干净

## 架构理念（树形 + 链式混合架构）

- **🩸 链式架构（血液系统）**：事件总线 + 消息系统 + 环形队列 + 调度器
- **🌳 树形架构（生长路径）**：元内核 → core → scheduler → component → components
- **🧬 DNA**：组件作为系统的基本单元
- **💭 意志**：配置文件表达用户意图
- **🔐 信任根**：meta_kernel 为不可变自举起点

## 构建和运行

```bash
moon fmt     # 格式化代码
moon info    # 更新接口信息
moon test    # 运行测试
moon build   # 构建项目
```