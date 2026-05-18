# 🌳 接口设计语言：链式架构是血液系统，树形架构是生长的器官

> **核心原则**：只要 `interfaces/` 目录设计得足够优雅、足够抽象，整个系统的复杂度就会被死死地锁在那个小小的目录里，而不会扩散到整个代码库！

***

## 核心思想：接口设计语言

我们需要的不是一套僵化的接口，而是一门**接口设计语言**：

- **编程语言**：少量关键字 + 语法规则 → 可以表达任意程序
- **接口设计语言**：少量能力积木 + 组合规则 → 可以解决任意业务需求

就像用中文表达思想，不是发明一套新词汇，而是用现有的词汇组合出无限可能。

***

## 🌳 混合架构：链式是血液系统，树形是生长的器官

### 人体模型类比

```
🔗 链式架构（血液系统）：
    心脏（第0层）
        ↓ 血液流通
    动脉（第1层）
        ↓ 血液流通
    血管（第2层）
        ↓ 血液流通
    毛细血管（第3层）
        ↓ 血液流通
    全身细胞（第4层）

🌳 树形架构（生长的器官）：
    心脏（第0层）
        ↓ 长出新器官
    手（camera）
        ├── 手指1（camera-capture-v1）
        ├── 手指2（camera-capture-with-config）
        └── 手指3（camera-stream）
        ↓ 长出新器官
    眼睛（display）
        ├── 眼球1（display-render）
        └── 眼球2（display-framebuffer）
```

### 详细架构图

```
┌─────────────────────────────────────────────────────────────┐
│  第4层：系统服务（大树枝） 🌳 链式 + 树形
│  ├── filesystem
│  ├── process
│  └── ipc
└───────────────┬─────────────────────────────────────────────┘
                │ 🔗 链式包含（根本）
┌───────────────▼─────────────────────────────────────────────┐
│  第3层：硬件抽象（树枝） 🌳 链式 + 树形
│  ├── camera（链节点）
│  │   ├── camera-capture-v1（树叶）
│  │   ├── camera-capture-with-config（枝叶分叉）
│  │   └── camera-stream（枝叶分叉）
│  ├── display（链节点）
│  └── storage（链节点）
└───────────────┬─────────────────────────────────────────────┘
                │ 🔗 链式包含（根本）
┌───────────────▼─────────────────────────────────────────────┐
│  第2层：通用能力（分枝） 🌳 链式 + 树形
│  ├── power（链节点）
│  ├── security（链节点）
│  └── diagnostics（链节点）
└───────────────┬─────────────────────────────────────────────┘
                │ 🔗 链式包含（根本）
┌───────────────▼─────────────────────────────────────────────┐
│  第1层：基础组件（小树枝） 🌳 链式 + 树形
│  └── configurable（链节点）
└───────────────┬─────────────────────────────────────────────┘
                │ 🔗 链式包含（根本）
┌───────────────▼─────────────────────────────────────────────┐
│  第0层：根接口（树干，🌱 完全冻结） ✅ 只有链式
│  └── resource（链起点）
└─────────────────────────────────────────────────────────────┘
```

### 混合架构总结表

| 方面 | 架构类型 | 角色定位 | 说明 |
|------|---------|--------|------|
| **🔗 链式架构** | 血液系统 | **根本** | 贯穿整个系统，从根到叶，保证血液（数据/调用）可以流通到任何地方，系统完整不会断裂 |
| **🌳 树形架构** | 生长的器官 | **应变** | 在链式骨架的基础上，生长出各种功能（像手脚、眼睛等），枝繁叶茂，灵活应对各种应用功能要求 |

***

## 🔗 链式架构：血液系统，贯穿整个系统

### 核心规则

```
第0层 → 第1层 → 第2层 → 第3层 → 第4层
    🔗       🔗       🔗       🔗
    包含    包含    包含    包含
```

### 特点

1. **贯穿整个系统**：从第0层到第4层，链式关系无处不在
2. **血液畅通**：保证数据/调用可以流通到任何地方
3. **系统完整**：整个系统完整不会断裂
4. **层级固定**：第0→1→2→3→4层，骨架永远不变
5. **上层必含下层**：每一层必须完整包含上一层
6. **只增不改**：永远稳定

***

## 🌳 树形架构：生长的器官，灵活应变

### 枝叶分叉示例

```
camera（链节点）
├── camera-capture-v1（树叶）
├── camera-capture-with-config（枝叶分叉，应对新需求）
├── camera-stream（继续分叉）
└── camera-power-saving（继续分叉）
```

### 特点

1. **枝叶分叉**：在每个链节点上可以灵活扩展
2. **灵活应变**：应对各种应用功能要求
3. **不破坏血液系统**：链式骨架永远稳定，血液畅通
4. **枝繁叶茂**：功能越丰富，树越茂盛

***

## 关键问题：如何避免"屎山"架构？

### ❌ 问题根源：版本化分叉

```
v1.0 → v1.1（分叉1）→ v2.0（分叉2）→ ...
结果：需要同时维护多个版本，最终变成"屎山"
```

### ✅ 根本解决方案：功能组合模型（接口设计语言）

把功能拆成独立、小的**能力积木**，像编程语言一样自由组合：

#### 旧设计（有问题）

```wit
// ❌ 把功能打包成大接口，导致版本堆积
interface camera-core-v1 {
    capture() -> result<image, error>;
}

interface camera-core-v2 {
    capture() -> result<image, error>;
    captureWithConfig(config: captureConfig) -> result<image, error>;
}

interface camera-core-v3 {
    // 继续堆积...
}
```

#### 新设计（拆成积木）

```wit
// ✅ 拆成独立的能力积木
interface camera-capture-v1 {
    capture() -> result<image, error>;
}

interface camera-capture-with-config {
    captureWithConfig(config: captureConfig) -> result<image, error>;
}

interface camera-stream {
    startStream() -> result<stream<frame>, error>;
    stopStream() -> result<unit, error>;
}

interface camera-power-saving {
    setLowPowerMode(enabled: bool) -> result<unit, error>;
}

// 🎯 核心：不再有 camera-core-v1/v2/v3！
```

#### 应用代码：自由组合

```moonbit
fn useCamera(camera: CameraDevice) -> Result<unit, Error> {
    let capture = camera.getCapability("camera-capture-with-config")?;
    let stream = camera.getCapability("camera-stream")?;
    let power = camera.getCapability("camera-power-saving")?;
    
    power.setLowPowerMode(false)?;
    let image = capture.captureWithConfig(highQualityConfig)?;
    let video = stream.startStream()?;
    
    return Ok(unit);
}
```

***

## 接口设计语言的三大设计原则

### 1. 简单性：积木要小而专一，不要大而全

```wit
// ❌ 大而全的积木
interface camera-all-in-one-v1 {
    capture() -> result<image, error>;
    captureWithConfig(config: captureConfig) -> result<image, error>;
    startStream() -> result<stream<frame>, error>;
    setLowPowerMode(enabled: bool) -> result<unit, error>;
    // 继续堆积...
}

// ✅ 小而专一的积木
interface camera-capture-v1 {
    capture() -> result<image, error>;
}

interface camera-stream {
    startStream() -> result<stream<frame>, error>;
    stopStream() -> result<unit, error>;
}
```

### 2. 正交性：积木之间要独立，不要有依赖

```wit
// ❌ 积木之间有依赖，不是正交的
interface camera-capture-v1 {
    capture() -> result<image, error>;
    setLowPowerMode(enabled: bool) -> result<unit, error>;
}

// ✅ 积木之间正交，互不依赖
interface camera-capture-v1 {
    capture() -> result<image, error>;
}

interface camera-power-saving {
    setLowPowerMode(enabled: bool) -> result<unit, error>;
}
```

### 3. 可组合性：积木可以自由组合，解决任意业务需求

```moonbit
// 组合1：简单拍照应用（只用1个积木）
fn simpleApp(camera: CameraDevice) -> Result<unit, Error> {
    let capture = camera.getCapability("camera-capture-v1")?;
    let image = capture.capture()?;
    return Ok(unit);
}

// 组合2：专业相机应用（用4个积木）
fn professionalApp(camera: CameraDevice) -> Result<unit, Error> {
    let capture = camera.getCapability("camera-capture-with-config")?;
    let stream = camera.getCapability("camera-stream")?;
    let power = camera.getCapability("camera-power-saving")?;
    let exposure = camera.getCapability("camera-auto-exposure")?;
    
    power.setLowPowerMode(false)?;
    exposure.setExposure(1.0)?;
    let image = capture.captureWithConfig(highQualityConfig)?;
    return Ok(unit);
}

// 组合3：安全监控应用（用多个积木跨设备）
fn securityCameraApp(camera: CameraDevice, storage: StorageDevice, network: NetworkDevice) -> Result<unit, Error> {
    let stream = camera.getCapability("camera-stream")?;
    let power = camera.getCapability("camera-power-saving")?;
    let encrypt = storage.getCapability("storage-encrypt")?;
    let upload = network.getCapability("network-upload")?;
    
    power.setLowPowerMode(true)?;
    let video = stream.startStream()?;
    let encrypted = encrypt.encryptStream(video)?;
    upload.uploadStream(encrypted, "security-feed")?;
    return Ok(unit);
}
```

***

## 🛠️ 完整落地指南

### 目录结构设计

```
interfaces/
├── 00-foundation/          # 第0层：根接口（链式骨架，永远不变）
│   ├── resource.wit
│   └── types.wit
│
├── 01-core/               # 第1-2层：通用能力（链式骨架，稳定）
│   ├── capability-discovery.wit
│   └── configurable.wit
│
├── 02-hardware/           # 第3层：硬件抽象（链式骨架，稳定）
│   └── hardware-device.wit
│
├── 03-capabilities/       # 🌳 功能积木（树形分叉，灵活生长）
│   ├── camera/            # camera相关积木
│   │   ├── camera-capture-v1.wit
│   │   ├── camera-capture-with-config.wit
│   │   ├── camera-stream.wit
│   │   ├── camera-power-saving.wit
│   │   └── ...（未来可以继续加）
│   │
│   ├── display/           # display相关积木
│   │   ├── display-render.wit
│   │   └── display-framebuffer.wit
│   │
│   └── storage/           # storage相关积木
│       ├── storage-read.wit
│       └── storage-write.wit
│
└── 04-system/             # 第4层：系统服务（链式骨架，稳定）
    ├── filesystem.wit
    └── network.wit
```

### 关键技术点

| 技术点 | 具体内容 |
|------|---------|
| **接口拆分** | 把大接口拆成独立、小的功能积木 |
| **能力发现** | hardware驱动通过 `capability-discovery` 接口返回支持的积木 |
| **按需实现** | 硬件驱动可以选择性实现功能积木，不需要全实现 |
| **按需使用** | 应用只选择自己需要的积木，不被迫使用大而全的接口 |
| **独立进化** | 每个积木可以独立添加、废弃、清理，不影响其他积木 |
| **目录组织** | 链式骨架目录（00-04）稳定，功能积木目录（03）灵活生长 |

### 迁移策略

| 阶段 | 说明 |
|------|------|
| **第1阶段（现在）** | 先用"废弃标记+渐进清理"方案作为过渡，同时规划向功能组合模型迁移 |
| **第2阶段（6个月后）** | 为新硬件类型直接用新设计，为新功能直接加新的功能积木，不再创建新的大接口 |
| **第3阶段（1-2年后）** | 把现有旧接口迁移到功能积木模型，逐步废弃旧的大接口 |
| **第4阶段（长期）** | 完全迁移到功能组合模型，永远不会变成屎山！ |

***

## 成熟案例借鉴

### 1. HTML 演进

- **5个版本，30年历史**
- **核心思想**：旧网页在新浏览器上永远能运行
- **实践**：只会添加新标签，不会删除或修改旧标签

### 2. Android API 层级

- **35个层级，向后兼容**
- **核心思想**：旧应用在新 Android 上永远能运行
- **实践**：每层包含上一层的所有 API

### 3. Linux 系统调用

- **核心原则**："不要破坏用户空间"
- **实践**：系统调用定义后永远不变，只增不减

### 4. POSIX 标准

- **跨平台兼容典范**
- **核心思想**：树干相同，枝叶可以不同
- **实践**：标准定义后稳定不变，各系统可以有自己的扩展

***

## 黄金法则与安全操作指南

### 链式架构黄金法则

1. **根接口永不改**：第0层定义后完全冻结
2. **链式包含**：每一层必须包含上一层的所有接口
3. **只增不改**：只能添加新接口，不能修改或删除
4. **避免分叉**：不搞版本化，只在链上添加
5. **能力发现**：优雅检测新功能可用性
6. **接口隔离**：每个接口单一职责
7. **面向能力**：抽象本质，不绑定具体硬件
8. **组合优先**：接口组合而非继承
9. **类型安全**：强类型设计
10. **简洁为王**：KISS 原则

### 安全操作指南

| 操作 | 能否 | 说明 |
|------|-----|------|
| **添加新接口/新功能** | ✅ 完全可以 | 在链尾添加或树形分叉 |
| **修改现有接口** | ❌ 绝对不可以 | 破坏链式结构 |
| **删除现有接口** | ❌ 绝对不可以 | 破坏链式结构 |

***

## 总结

### 🔗 链式架构（血液系统）

- 就像人体的血液系统，从心脏到指尖，血液必须流通到全身
- **贯穿整个系统**：从第0层到第4层，链式关系无处不在
- **血液畅通**：保证数据/调用可以流通到任何地方
- **系统完整**：整个系统完整不会断裂
- **层级固定**：第0→1→2→3→4层，骨架永远不变
- **只增不改**：永远稳定

### 🌳 树形架构（生长的器官）

- 就像一棵树，树干稳固后，可以长出各种器官（手脚、眼睛等）
- **链节点上可以灵活生长**：camera-capture-v1 → camera-capture-with-config → ...
- **枝繁叶茂**：功能越丰富，系统越强大
- **灵活应变**：应对各种应用功能要求
- **不破坏血液系统**：链式骨架永远稳定，血液畅通

### 🎯 接口设计语言

- 就像编程语言，少量能力积木 + 组合规则 → 可以解决任意业务需求
- 简单性：积木要小而专一
- 正交性：积木之间要独立
- 可组合性：积木可以自由组合

**记住**：**链式架构是血液系统（贯穿整个系统）+ 树形架构是生长的器官（在链式骨架上长出各种功能）+ 功能组合模型（接口设计语言）**是经过软件行业50年验证的、最成熟的架构原则之一！

这样设计出来的 `interfaces/`，才能真正做到：**"只要这个目录设计得足够优雅、足够抽象，整个系统的复杂度就会被死死地锁在那个小小的目录里，而不会扩散到整个代码库！"**
