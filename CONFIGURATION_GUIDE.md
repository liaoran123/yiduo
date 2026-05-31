# 配置驱动的架构指南

## 🎯 核心理念

**不是重新发明技术，而是调度整合技术！**

通过声明式配置文件，我们可以：
1. 定义需要什么技术/设备
2. 选择预配置的组合套餐
3. 无需重新编译就能改变系统行为

---

## 📂 配置文件结构

```
d:\yiduo\
├── configs/
│   ├── tech-stacks/          # 技术栈配置
│   │   └── smart-camera-stack.yaml
│   └── app-scenarios/        # 应用场景配置
│       └── ai-security-camera.yaml
│
├── interfaces/
│   ├── device-specs/         # 设备配置
│   │   ├── sony-imx327.yaml
│   │   └── templates/
│   ├── cap/                  # 能力接口
│   │   ├── camera/           # 相机能力积木
│   │   │   ├── capture.wit
│   │   │   ├── config.wit
│   │   │   ├── stream.wit
│   │   │   └── info.wit
│   │   └── device-loader.wit
│   └── capabilities.wit
│
├── runtime/
│   ├── device_loader.mbt     # 设备配置加载器
│   └── tech_stack_loader.mbt # 技术栈加载器
│
└── apps/
    ├── smart_camera/         # 智能相机应用
    └── tech-stack-demo/      # 技术栈调度演示
```

---

## 🎮 两个配置层次

### 1️⃣ 设备配置层次

**位置**：`interfaces/device-specs/`

**用途**：配置硬件设备的能力组合

**示例**：
```yaml
# sony-imx327.yaml
device:
  name: "Sony IMX327 Camera"
  type: camera

capabilities:
  - camera-capture (必需)
  - camera-config (可选)
  - camera-stream (可选)

combinations:
  simple: [capture, info]
  professional: [capture, config, stream]
```

**相关文件**：
- 能力接口：`interfaces/cap/camera/*.wit`
- 加载器：`runtime/device_loader.mbt`

---

### 2️⃣ 技术栈配置层次

**位置**：`configs/tech-stacks/`

**用途**：配置软件技术栈的组合

**示例**：
```yaml
# smart-camera-stack.yaml
components:
  - "Rust 生态" (内存安全)
  - "FFmpeg" (视频处理)
  - "PyTorch" (AI 推理)
  - "OpenCV" (计算机视觉)

combinations:
  edge-device: [轻量级, 低功耗]
  professional: [全功能, GPU 加速]
  cloud-server: [高并发, 分布式]
```

**相关文件**：
- 配置：`configs/tech-stacks/*.yaml`
- 场景：`configs/app-scenarios/*.yaml`
- 加载器：`runtime/tech_stack_loader.mbt`

---

## 🚀 如何使用

### 场景 1：配置一台设备

1. 修改或创建设备配置：`interfaces/device-specs/my-device.yaml`
2. 选择套餐：`simple`, `professional`, 或 `security`
3. 系统自动加载配置，无需重新编译！

### 场景 2：配置一个应用的技术栈

1. 修改技术栈配置：`configs/tech-stacks/my-stack.yaml`
2. 选择套餐：`edge-device`, `professional`, 或 `cloud-server`
3. 系统自动组装技术栈，无需重新编译！

---

## 💡 优势总结

| 方面 | 传统方式 | 配置驱动方式 |
|------|---------|------------|
| **灵活性** | 需要改代码重新编译 | 只需改配置文件 |
| **清晰度** | 代码分散，难以理解 | 配置即文档，一目了然 |
| **复用性** | 复制粘贴代码 | 共享配置文件 |
| **演进性** | 容易变成屎山 | 独立积木，按需组合 |

---

## 🧩 组件配置层次（008 规范）

WAMR 等系统组件遵循 [008.组件配置格式规范](操作系统/01.核心调度系统/008.组件配置格式规范.md) 定义。

### 组件定义

每个组件通过 YAML 声明自己的规格（`provides`）、多种实现（`implementations`）和默认策略（`default-strategy`）：

```yaml
# configs/components/wamr-runtime.yaml
apiVersion: yiduo.dev/v1alpha1
kind: Component
metadata:
  name: wasm-runtime
spec:
  provides:
    - interface: yiduo:sys/wasm-runtime

  implementations:
    - name: wamr-real        # 真实 WAMR
      type: native
      default: true
    - name: wamr-stub        # 零依赖回退
      type: native
      platforms: [all]

  default-strategy:
    preferred: wamr-real
    fallbacks: [wamr-stub]
```

### 用户选择

用户在自举配置中选择具体实现：

```yaml
# configs/bootstrap.yaml
runtime:
  implementation: wamr-real   # 用户在此决定
```

### 构建自举

构建脚本读取配置，自动执行对应的构建流程：

```powershell
.\scripts\build_wamr.ps1  # 读取 bootstrap.yaml → 构建 WAMR → 配置 moon.pkg
```

### 配置即意志

上述机制遵循**四元架构**的"意志"层：用户通过声明式配置文件表达意图，系统自行解读并执行，无需修改代码。

---

## 📚 相关文档

- 设计原则：`interfaces/技术文档/设计原则：如何做到足够优雅、足够抽象.md`
- README：`README.md`
- 组件配置规范：`操作系统/01.核心调度系统/008.组件配置格式规范.md`
