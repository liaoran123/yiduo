# 设计原则：树形接口架构（链式包含，永不断裂）

> **核心原则**：只要 `interfaces/` 目录设计得足够优雅、足够抽象，整个系统的复杂度就会被死死地锁在那个小小的目录里，而不会扩散到整个代码库！

***

## 核心理念：🔗 链式架构是血液系统，🌳 树形架构是生长的器官

### 混合架构的完美结合

这个架构的设计灵感来自软件行业最成熟的实践，采用**混合架构**：

| 方面          | 架构类型  | 角色定位   | 说明                                           |
| ----------- | ----- | ------ | -------------------------------------------- |
| **🔗 链式架构** | 血液系统  | **根本** | 贯穿整个系统，从根到叶，保证血液（数据/调用）可以流通到任何地方，系统完整不会断裂    |
| **🌳 树形架构** | 生长的器官 | **应变** | 在链式骨架的基础上，生长出各种功能（像手脚、眼睛等），枝繁叶茂，灵活应对各种应用功能要求 |

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
    ├── 手指1（camera-core-v1）
    ├── 手指2（camera-core-v2）
    └── 手指3（camera-core-v3）
        ↓ 长出新器官
    眼睛（display）
    ├── 眼球1（display-core-v1）
    └── 眼球2（display-core-v2）
        ↓ 长出新器官
    脚（storage）
    └── ...
```

### 详细架构图

```
┌─────────────────────────────────────────────────────────────┐
│  第4层：系统服务（大树枝） 🌳 链式 + 树形                    │
│  ├── filesystem                                            │
│  ├── process                                               │
│  └── ipc                                                   │
└───────────────┬─────────────────────────────────────────────┘
                │ 🔗 链式包含（根本）
┌───────────────▼─────────────────────────────────────────────┐
│  第3层：硬件抽象（树枝） 🌳 链式 + 树形                       │
│  ├── camera（链节点）                                        │
│  │   ├── camera-core-v1 （树叶）                             │
│  │   ├── camera-core-v2 （枝叶分叉）                          │
│  │   └── camera-core-v3 （继续分叉）                         │
│  ├── display（链节点）                                       │
│  ├── storage（链节点）                                       │
│  └── ...                                                    │
└───────────────┬─────────────────────────────────────────────┘
                │ 🔗 链式包含（根本）
┌───────────────▼─────────────────────────────────────────────┐
│  第2层：通用能力（分枝） 🌳 链式 + 树形                        │
│  ├── power（链节点）                                          │
│  ├── security（链节点）                                      │
│  └── ...                                                    │
└───────────────┬─────────────────────────────────────────────┘
                │ 🔗 链式包含（根本）
┌───────────────▼─────────────────────────────────────────────┐
│  第1层：基础组件（小树枝） 🌳 链式 + 树形                      │
│  └── configurable（链节点）                                  │
└───────────────┬─────────────────────────────────────────────┘
                │ 🔗 链式包含（根本）
┌───────────────▼─────────────────────────────────────────────┐
│  第0层：根接口（树干，🌱 完全冻结） ✅ 只有链式                 │
│  └── resource（链起点）                                      │
└─────────────────────────────────────────────────────────────┘
```

### 🔗 链式架构（根本，骨架）

这是整个系统的基础，必须严格遵守，永不变形：

```
第0层 → 第1层 → 第2层 → 第3层 → 第4层
  🔗       🔗       🔗       🔗
  包含    包含    包含    包含
```

**特点**：

- **层级固定**：5层结构永远不变
- **上层必含下层**：每一层必须完整包含上一层
- **骨架稳定**：整个系统的骨架像链条一样稳定
- **永不断裂**：保证向后兼容

***

### 🌳 树形架构（分支，应变所有变化）

在链的每个节点（比如第3层的camera），可以灵活地长出枝叶：

```
camera（链节点）
├── camera-core-v1（树叶）
├── camera-core-v2（枝叶分叉，应对新需求）
├── camera-core-v3（继续分叉）
└── ...（可以无限分叉）
```

**特点**：

- **枝叶分叉**：在每个链节点上可以灵活扩展
- **灵活应变**：应对所有变化和需求
- **不破坏骨架**：链式骨架永远稳定
- **枝繁叶茂**：功能越丰富，树越茂盛

***

### 混合架构的核心思想总结

| 方面          | 定位     | 作用        | 例子                         |
| ----------- | ------ | --------- | -------------------------- |
| **🔗 链式架构** | 根本（骨架） | 保证稳定性和兼容性 | 第0→1→2→3→4层的层级关系           |
| **🌳 树形架构** | 分支（应变） | 应对所有变化和需求 | camera-core-v1→v2→v3...的分叉 |

***

## 如何避免变成"屎山"架构

好问题！确实，如果没有良好的管理，"只增不改"容易变成**屎山**。但只要配合以下策略，就可以避免：

### ❌ 传统"屎山"陷阱的原因
- 代码越堆越多，没有清理策略
- 旧接口永远保留，新接口不断添加，接口越来越臃肿
- 没有"废弃标记"机制，大家不知道哪些是旧接口，继续误用
- 没有架构评审，随便添加新接口
- 最后变成谁都不想碰的"屎山"

---

### ✅ 我们的策略：防止屎山的 5 个关键措施

#### 1. **废弃标记机制**（明确告诉大家哪些旧了）
```wit
// 在注释中明确标记废弃接口
/// @deprecated 2025-05-18 建议使用 camera-core-v2 代替
interface camera-core-v1 {
    capture() -> result<image, error>;
}

/// @since 2025-05-18 新增接口，推荐使用
interface camera-core-v2 {
    capture(config: CaptureConfig) -> result<image, error>;
}
```

**作用**：明确告诉大家哪些接口已经旧了，不要再用。

---

#### 2. **渐进式清理策略**（不要永远保留所有）
```
时间线：
2025-05-18：发布 camera-core-v1
2026-05-18：发布 camera-core-v2，标记 v1 为"废弃"
2028-05-18：发布 camera-core-v3，标记 v2 为"废弃"，**物理移除 v1**（前提是没有用户在用）
2030-05-18：发布 camera-core-v4，标记 v3 为"废弃"，**物理移除 v2**
```

**规则**：
- 废弃后保留 2 年过渡期
- 过渡期结束后，如果确认没有用户在用，可以物理移除
- 这样就不会无限堆积！

---

#### 3. **能力发现 + 回退机制**（让新应用只依赖新接口）
应用代码示例：
```moonbit
fn takePhoto(camera: CameraDevice) -> Result<Image, Error> {
    // 优先用新接口
    if let Some(v2) = camera.getCapability("camera-core-v2")? {
        return v2.capture(highQualityConfig);
    }
    
    // 回退到旧接口（但告诉大家这是暂时的）
    /// @deprecated 2025-05-18 建议尽快升级到 camera-core-v2
    if let Some(v1) = camera.getCapability("camera-core-v1")? {
        return v1.capture();
    }
    
    return Err(Error::Unsupported);
}
```

**作用**：新应用自然倾向于用新接口，旧接口使用量自然减少，为未来清理铺平道路。

---

#### 4. **严格的接口添加评审**（防止滥用）
- 不是随便什么功能都能加进接口
- 需要经过：
  - **设计评审**：这个功能是不是真的通用？能不能用现有功能组合实现？
  - **命名评审**：新接口命名是否清晰？版本号是否合适？
  - **架构评审**：是否真的需要新增接口？还是可以用其他方式实现？

---

#### 5. **最佳实践文档**（指导大家正确添加）
- **不要**：每个小需求就加一个新接口
- **要**：思考 5 年后这个接口是否还有意义
- **要**：尽量用可扩展类型（如 variant）代替新增接口
- **要**：优先用组合功能，而不是新增接口

---

### 📊 对比：传统屎山 vs 我们的架构

| 方面 | 传统屎山架构 | 我们的树形+链式架构 |
|------|------------|------------------|
| **管理混乱** | 没有策略，随便添加 | ✅ 废弃标记+渐进清理 |
| **无限堆积** | 接口无限添加，永远不删 | ✅ 2年过渡期+物理清理 |
| **误用严重** | 不知道哪些是旧接口 | ✅ 能力发现+回退机制 |
| **架构膨胀** | 没有评审，随便添加 | ✅ 严格的接口添加评审 |
| **最佳实践** | 没有指导 | ✅ 完善的最佳实践文档 |

---

### 🎯 总结

是的，如果没有良好的管理，**确实会变成屎山**！刚才的方案只是**治标不治本**！让我们重新设计一个从根本上避免屎山的架构：

---

## 🚀 根本解决方案：重新设计架构——功能组合模型（治标又治本）

刚才的"废弃标记+渐进清理"确实只是**治标不治本**！让我们设计一个从根本上避免屎山的架构：

### 问题根源分析
我们现在的问题：
1. 我们把**一组功能打包成一个大接口**（camera-core-v1）
2. 时间久了，就需要 camera-core-v2, camera-core-v3...
3. 每个版本都要保留，最终堆积成山

---

### ✨ 新架构：功能组合模型（接口设计语言）

**核心思想**：不要把功能打包成"大接口版本"，而是把功能拆成**小的、可组合的"能力积木"**，像编程语言一样，可以通过组合解决所有业务需求！

#### 为什么要像编程语言？
- 编程语言的特点：**少量关键字 + 语法规则 → 可以表达任意程序**
- 我们的目标：**少量能力积木 + 组合规则 → 可以解决任意业务需求**
- 这就是"**接口设计语言**"的概念！

---

### 🔍 类比：编程语言 vs 接口设计语言

| 方面 | 编程语言 | 接口设计语言（我们的方案） |
|------|---------|------------------------|
| **原子单元** | 关键字、类型、函数 | 能力积木 |
| **组合规则** | 函数调用、控制流、类型组合 | 能力发现、积木组合 |
| **表达能力** | 可以写任意程序 | 可以解决任意业务需求 |
| **设计原则** | 简单、正交、可组合 | 简单、正交、可组合 |
| **例子** | Rust、JavaScript、MoonBit | 我们的树形+链式架构 |

#### 新架构图
```
🔗 链式骨架（血液系统）
    ├── 第0层：根接口
    ├── 第1层：基础组件
    ├── 第2层：通用能力
    ├── 第3层：硬件抽象
    └── 第4层：系统服务

🌳 功能积木（不是版本化接口，而是独立的能力积木）
    ├── camera-capture-v1（积木1）
    ├── camera-capture-v2（积木2）
    ├── camera-config（积木3）
    ├── camera-stream（积木4）
    ├── camera-power-saving（积木5）
    └── ...（更多积木）

🎯 应用组合（应用选择自己需要的积木）
    ├── 应用A：选择 [camera-capture-v1, camera-config]
    ├── 应用B：选择 [camera-capture-v2, camera-stream, camera-power-saving]
    └── 应用C：只选择 [camera-capture-v1]
```

---

#### WIT 示例：功能积木架构

**不再设计**：
```wit
// ❌ 旧设计：把功能打包成大接口
interface camera-core-v1 {
    capture() -> result<image, error>;
}

interface camera-core-v2 {
    capture() -> result<image, error>;
    captureWithConfig(config: captureConfig) -> result<image, error>;
}

interface camera-core-v3 {
    ... // 继续堆积...
}
```

**新设计**：
```wit
// ✅ 新设计：拆成独立的能力积木

// 积木1：基础拍照功能（永远不变，简单稳定）
interface camera-capture-v1 {
    capture() -> result<image, error>;
}

// 积木2：带配置的拍照功能（独立积木）
interface camera-capture-with-config {
    captureWithConfig(config: CaptureConfig) -> result<image, error>;
}

// 积木3：视频流功能（独立积木）
interface camera-stream {
    startStream() -> result<stream<frame>, error>;
    stopStream() -> result<unit, error>;
}

// 积木4：电源管理功能（独立积木）
interface camera-power-saving {
    setLowPowerMode(enabled: bool) -> result<unit, error>;
}

// 🎯 核心：不再有 camera-core-v1/v2/v3！
```

---

#### 应用代码示例

应用选择自己需要的积木，而不是被迫使用某个"大接口版本"：

```moonbit
fn useCamera(camera: CameraDevice) -> Result<unit, Error> {
    // 应用选择自己需要的积木，不是被迫使用某个版本
    let capture = camera.getCapability("camera-capture-v1")?;
    let stream = camera.getCapability("camera-stream")?;
    let powerSaving = camera.getCapability("camera-power-saving")?;
    
    // 自由组合！
    powerSaving.setLowPowerMode(false)?;
    let image = capture.capture()?;
    let videoStream = stream.startStream()?;
    
    // ...
    
    return Ok(unit);
}
```

---

### 🎯 接口设计语言的设计原则：简单、正交、可组合

为了让能力积木像编程语言一样强大，我们需要遵循以下设计原则：

---

#### 原则1：简单性——积木要小而专一，不要大而全

**反例（不要这样）**：
```wit
// ❌ 大而全的积木，什么都做
interface camera-all-in-one-v1 {
    capture() -> result<image, error>;
    captureWithConfig(config: CaptureConfig) -> result<image, error>;
    startStream() -> result<stream<frame>, error>;
    stopStream() -> result<unit, error>;
    setLowPowerMode(enabled: bool) -> result<unit, error>;
    getPowerConsumption() -> result<u32, error>;
    setExposure(ev: f32) -> result<unit, error>;
    // 继续堆积...
}
```

**正例（要这样）**：
```wit
// ✅ 小而专一的积木，每个只做一件事
interface camera-capture-v1 {
    capture() -> result<image, error>;
}

interface camera-capture-with-config {
    captureWithConfig(config: CaptureConfig) -> result<image, error>;
}

interface camera-stream {
    startStream() -> result<stream<frame>, error>;
    stopStream() -> result<unit, error>;
}

interface camera-power-saving {
    setLowPowerMode(enabled: bool) -> result<unit, error>;
    getPowerConsumption() -> result<u32, error>;
}

interface camera-auto-exposure {
    setExposure(ev: f32) -> result<unit, error>;
}
```

---

#### 原则2：正交性——积木之间要独立，不要有依赖

**反例（不要这样）**：
```wit
// ❌ 积木之间有依赖，不是正交的
interface camera-capture-v1 {
    capture() -> result<image, error>;
    // 这个积木依赖 power-saving，不是正交的！
    setLowPowerMode(enabled: bool) -> result<unit, error>;
}
```

**正例（要这样）**：
```wit
// ✅ 积木之间正交，互不依赖
interface camera-capture-v1 {
    capture() -> result<image, error>;
}

interface camera-power-saving {
    setLowPowerMode(enabled: bool) -> result<unit, error>;
}

// 🎯 应用自己组合，积木之间独立！
fn useCamera(camera: CameraDevice) -> Result<unit, Error> {
    let capture = camera.getCapability("camera-capture-v1")?;
    let power = camera.getCapability("camera-power-saving")?;
    
    power.setLowPowerMode(false)?;
    let image = capture.capture()?;
    
    return Ok(unit);
}
```

---

#### 原则3：可组合性——积木可以自由组合，解决任意业务需求

**组合示例1：简单拍照应用**
```moonbit
// 只需要 1 个积木
fn simpleApp(camera: CameraDevice) -> Result<unit, Error> {
    let capture = camera.getCapability("camera-capture-v1")?;
    let image = capture.capture()?;
    saveImage(image);
    return Ok(unit);
}
```

**组合示例2：专业相机应用**
```moonbit
// 需要 4 个积木组合
fn professionalApp(camera: CameraDevice) -> Result<unit, Error> {
    let capture = camera.getCapability("camera-capture-with-config")?;
    let stream = camera.getCapability("camera-stream")?;
    let power = camera.getCapability("camera-power-saving")?;
    let exposure = camera.getCapability("camera-auto-exposure")?;
    
    power.setLowPowerMode(false)?;
    exposure.setExposure(1.0)?;
    let image = capture.captureWithConfig(highQualityConfig)?;
    let video = stream.startStream()?;
    
    return Ok(unit);
}
```

**组合示例3：安全监控应用**
```moonbit
// 需要 3 个积木 + 其他能力
fn securityCameraApp(camera: CameraDevice, storage: StorageDevice, network: NetworkDevice) -> Result<unit, Error> {
    let stream = camera.getCapability("camera-stream")?;
    let power = camera.getCapability("camera-power-saving")?;
    let encrypt = storage.getCapability("storage-encrypt")?;
    let upload = network.getCapability("network-upload")?;
    
    // 任意组合！
    power.setLowPowerMode(true)?;
    let video = stream.startStream()?;
    let encrypted = encrypt.encryptStream(video)?;
    upload.uploadStream(encrypted, "security-feed")?;
    
    return Ok(unit);
}
```

---

### 🎯 功能组合模型的优势

| 方面 | 旧设计（版本化接口） | 新设计（功能积木） |
|------|---------------------|-----------------|
| **接口堆积** | 版本越来越多，最终堆积成山 | ✅ 积木独立，不会堆积 |
| **废弃问题** | 旧版本必须保留，最终成为负担 | ✅ 积木可以独立废弃，不需要保留整棵树 |
| **灵活性** | 应用被迫使用整个版本 | ✅ 应用可以只选择自己需要的积木 |
| **向前兼容** | 新版本必须包含旧版本，越来越臃肿 | ✅ 积木独立，可以按需添加 |
| **清理策略** | 难清理，因为一个版本包含太多东西 | ✅ 容易清理，积木独立，可以逐个清理 |
| **表达能力** | 固定的大接口，扩展性差 | ✅ 像编程语言一样，可以任意组合，解决任意业务需求 |
| **设计原则** | 没有明确原则 | ✅ 简单、正交、可组合 |

---

### 🔄 功能组合模型的进化策略

**时间线**：
```
2025-05-18：发布 [camera-capture-v1]
2026-05-18：发布 [camera-capture-with-config]（新增积木）
2027-05-18：发布 [camera-stream]（新增积木）
2028-05-18：发布 [camera-power-saving]（新增积木）
2029-05-18：发布 [camera-auto-exposure]（新增积木）
2030-05-18：确定没有应用在用 [camera-capture-v1]，**物理移除**（容易！）
```

**优势**：
- 新增功能 = 新增积木，**不影响**旧积木
- 旧积木可以独立废弃、独立清理
- 不需要保留"整个版本"，只保留真正需要的积木
- 永远不会堆积成山！

---

### 📊 两种方案对比

| 方面 | 方案A：废弃标记（治标不治本） | 方案B：功能组合模型（治本） |
|------|---------------------|------------------------|
| **根本问题解决** | ❌ 只是延缓问题，最终还是会堆积 | ✅ 从根源上避免堆积 |
| **复杂度** | ✅ 简单，沿用现有设计 | 🟡 需要重新设计架构 |
| **灵活性** | ❌ 应用被迫用整个版本 | ✅ 应用可以自由选择积木 |
| **清理难度** | 🟡 需要过渡期+确认使用情况 | ✅ 积木独立，容易清理 |
| **推荐程度** | ⭐⭐（短期可用） | ⭐⭐⭐⭐⭐（强烈推荐，长期方案） |

---

### 🎯 最终建议

**短期**（现在）：
- 先用"废弃标记+渐进清理"方案作为过渡
- 同时规划向功能组合模型迁移

**长期**（未来）：
- 迁移到功能组合模型（积木式架构）
- 从根本上避免"屎山"

---

### 🎯 回到文档开头的总结

是的，如果没有良好的管理，**确实会变成屎山**！但我们有两个选择：

1. **方案A（治标）**：废弃标记+渐进清理（适合短期，文档前面已讲）
2. **方案B（治本）**：功能组合模型（积木式架构，上面详细讲了，强烈推荐长期）

选择方案B，我们的树形+链式架构就可以**既保持稳定，又永远不会变成屎山！**

---

## 🛠️ 如何实现方案B：功能组合模型（积木式架构）—完整落地指南

好！方案B是根本方案！现在让我们看看如何把它**落地实现**！

---

### 步骤1：接口拆分设计——把大接口拆成小积木

#### 从旧设计到新设计的迁移

**旧设计（有问题）**：
```wit
// ❌ 旧设计：把功能打包成大接口
interface camera-core-v1 {
    capture() -> result<image, error>;
}

interface camera-core-v2 {
    capture() -> result<image, error>;
    captureWithConfig(config: captureConfig) -> result<image, error>;
    startStream() -> result<stream<frame>, error>;
    stopStream() -> result<unit, error>;
}

interface camera-core-v3 {
    capture() -> result<image, error>;
    captureWithConfig(config: captureConfig) -> result<image, error>;
    startStream() -> result<stream<frame>, error>;
    stopStream() -> result<unit, error>;
    setLowPowerMode(enabled: bool) -> result<unit, error>;
    getPowerConsumption() -> result<u32, error>;
}
```

**新设计（拆成积木）**：
```wit
// ✅ 新设计：拆成独立的能力积木

// --------------------------
// 第0层：根接口（链式骨架，永远不变）
// --------------------------
interface resource {
    resource resource {
        close() -> result<unit, error>;
        getId() -> result<string, error>;
    }
}

// --------------------------
// 第1-2层：通用能力（链式骨架，稳定）
// --------------------------
interface capability-discovery {
    hasCapability(name: string) -> result<bool, error>;
    getCapability<T>(name: string) -> result<option<T>, error>;
}

// --------------------------
// 第3层：硬件抽象（链式骨架，稳定）
// --------------------------
interface hardware-device {
    resource device {
        getInfo() -> result<deviceInfo, error>;
    }
    
    open(id: string) -> result<device, error>;
}

// --------------------------
// 🌳 功能积木（树形分叉，灵活生长）
// --------------------------

// 积木1：基础拍照功能
interface camera-capture-v1 {
    capture() -> result<image, error>;
}

// 积木2：带配置的拍照功能
interface camera-capture-with-config {
    captureWithConfig(config: captureConfig) -> result<image, error>;
}

// 积木3：视频流功能
interface camera-stream {
    startStream() -> result<stream<frame>, error>;
    stopStream() -> result<unit, error>;
}

// 积木4：电源管理功能
interface camera-power-saving {
    setLowPowerMode(enabled: bool) -> result<unit, error>;
    getPowerConsumption() -> result<u32, error>;
}

// 积木5：自动曝光功能
interface camera-auto-exposure {
    enableAutoExposure(enabled: bool) -> result<unit, error>;
    setExposure(ev: f32) -> result<unit, error>;
}

// 🎯 核心：不再有 camera-core-v1/v2/v3！
```

---

### 步骤2：设备实现——硬件驱动如何实现功能积木

#### 设备驱动代码示例（MoonBit）

```moonbit
// 硬件驱动实现：Sony IMX327 Camera

struct SonyIMX327Device {
    // 底层硬件状态
    isOpened: bool,
    isStreaming: bool,
    lowPowerMode: bool,
    exposure: f32,
}

// --------------------------
// 第0层：根接口（必须实现，链式骨架）
// --------------------------
impl resource for SonyIMX327Device {
    fn close(self) -> Result<unit, Error> {
        self.isOpened = false;
        Ok(unit)
    }
    
    fn getId(self) -> Result<string, Error> {
        Ok("sony-imx327-001")
    }
}

// --------------------------
// 第1-2层：通用能力（必须实现，链式骨架）
// --------------------------
impl capability-discovery for SonyIMX327Device {
    fn hasCapability(self, name: string) -> Result<bool, Error> {
        // 🔑 核心：返回这个硬件支持哪些积木
        match name {
            "camera-capture-v1" => Ok(true),
            "camera-capture-with-config" => Ok(true),
            "camera-stream" => Ok(true),
            "camera-power-saving" => Ok(true),
            "camera-auto-exposure" => Ok(true),
            _ => Ok(false),
        }
    }
    
    fn getCapability<T>(self, name: string) -> Result<option<T>, Error> {
        // 🔑 核心：返回对应的功能积木实现
        match name {
            "camera-capture-v1" => Ok(Some(Self::asCameraCaptureV1(self))),
            "camera-capture-with-config" => Ok(Some(Self::asCameraCaptureWithConfig(self))),
            "camera-stream" => Ok(Some(Self::asCameraStream(self))),
            "camera-power-saving" => Ok(Some(Self::asCameraPowerSaving(self))),
            "camera-auto-exposure" => Ok(Some(Self::asCameraAutoExposure(self))),
            _ => Ok(None),
        }
    }
}

// --------------------------
// 🌳 功能积木实现（树形分叉，可以按需实现）
// --------------------------
impl camera-capture-v1 for SonyIMX327Device {
    fn capture(self) -> Result<image, Error> {
        // 底层硬件调用
        let rawImage = self.hardwareCapture();
        Ok(decodeImage(rawImage))
    }
}

impl camera-capture-with-config for SonyIMX327Device {
    fn captureWithConfig(self, config: CaptureConfig) -> Result<image, Error> {
        self.setHardwareConfig(config);
        let rawImage = self.hardwareCapture();
        Ok(decodeImage(rawImage))
    }
}

impl camera-stream for SonyIMX327Device {
    fn startStream(self) -> Result<stream<frame>, Error> {
        self.isStreaming = true;
        self.hardwareStartStream();
        Ok(createFrameStream(self))
    }
    
    fn stopStream(self) -> Result<unit, Error> {
        self.isStreaming = false;
        self.hardwareStopStream();
        Ok(unit)
    }
}

impl camera-power-saving for SonyIMX327Device {
    fn setLowPowerMode(self, enabled: bool) -> Result<unit, Error> {
        self.lowPowerMode = enabled;
        self.hardwareSetPowerMode(enabled);
        Ok(unit)
    }
    
    fn getPowerConsumption(self) -> Result<u32, Error> {
        Ok(self.hardwareReadPowerConsumption())
    }
}

impl camera-auto-exposure for SonyIMX327Device {
    fn enableAutoExposure(self, enabled: bool) -> Result<unit, Error> {
        self.hardwareSetAutoExposure(enabled);
        Ok(unit)
    }
    
    fn setExposure(self, ev: f32) -> Result<unit, Error> {
        self.exposure = ev;
        self.hardwareSetExposure(ev);
        Ok(unit)
    }
}
```

---

### 步骤3：应用使用——应用如何自由选择功能积木

#### 应用代码示例

```moonbit
// 应用1：只需要基础拍照功能
fn simpleApp(camera: SonyIMX327Device) -> Result<unit, Error> {
    // 只选择自己需要的积木，不需要的不用
    let capture = camera.getCapability("camera-capture-v1")?
        .okOr(Error::Unsupported)?;
    
    let image = capture.capture()?;
    saveImage(image);
    
    return Ok(unit);
}

// 应用2：需要拍照 + 视频流 + 电源管理
fn professionalApp(camera: SonyIMX327Device) -> Result<unit, Error> {
    // 自由组合！
    let capture = camera.getCapability("camera-capture-with-config")?
        .okOr(Error::Unsupported)?;
    let stream = camera.getCapability("camera-stream")?
        .okOr(Error::Unsupported)?;
    let power = camera.getCapability("camera-power-saving")?
        .okOr(Error::Unsupported)?;
    
    power.setLowPowerMode(false)?;
    
    let image = capture.captureWithConfig(highQualityConfig)?;
    let videoStream = stream.startStream()?;
    
    // ...
    
    return Ok(unit);
}

// 应用3：只需要视频流功能
fn streamingApp(camera: SonyIMX327Device) -> Result<unit, Error> {
    let stream = camera.getCapability("camera-stream")?
        .okOr(Error::Unsupported)?;
    
    let videoStream = stream.startStream()?;
    broadcastStream(videoStream);
    
    return Ok(unit);
}
```

---

### 步骤4：演进策略——如何添加新功能而不变成屎山

#### 时间线示例

```
2025-05-18：
- 发布 [camera-capture-v1] 积木
- 硬件驱动实现它
- 简单App使用它

2026-05-18：
- 新增 [camera-capture-with-config] 积木（不影响 v1）
- 新增 [camera-stream] 积木（独立）
- 硬件驱动可以选择实现或不实现
- 专业App可以选择使用这些新积木
- 简单App继续用 [camera-capture-v1]，不受影响

2027-05-18：
- 新增 [camera-power-saving] 积木（独立）
- 新增 [camera-auto-exposure] 积木（独立）
- 硬件驱动可以选择性实现
- App可以按需选择
- 不影响旧积木

2030-05-18：
- 确定没有任何应用在用 [camera-capture-v1]
- 硬件驱动可以选择删除 [camera-capture-v1] 的实现（安全！因为没人用）
- ✅ 清理完成，不会堆积！
```

---

### 步骤5：目录结构设计——项目文件如何组织

#### 推荐的项目结构

```
interfaces/
├── 00-foundation/          # 第0层：根接口（链式骨架，永远不变）
│   ├── resource.wit
│   └── types.wit
│
├── 01-core/               # 第1-2层：通用能力（链式骨架，稳定）
│   ├── capability-discovery.wit
│   ├── configurable.wit
│   └── ...
│
├── 02-hardware/           # 第3层：硬件抽象（链式骨架，稳定）
│   ├── hardware-device.wit
│   └── ...
│
├── 03-capabilities/       # 🌳 功能积木（树形分叉，灵活生长）
│   ├── camera/            # camera相关积木
│   │   ├── camera-capture-v1.wit
│   │   ├── camera-capture-with-config.wit
│   │   ├── camera-stream.wit
│   │   ├── camera-power-saving.wit
│   │   ├── camera-auto-exposure.wit
│   │   └── ...（未来可以继续加）
│   │
│   ├── display/           # display相关积木
│   │   ├── display-render.wit
│   │   ├── display-framebuffer.wit
│   │   └── ...
│   │
│   ├── storage/           # storage相关积木
│   │   ├── storage-read.wit
│   │   ├── storage-write.wit
│   │   └── ...
│   │
│   └── ...（更多硬件积木）
│
└── 04-system/             # 第4层：系统服务（链式骨架，稳定）
    ├── filesystem.wit
    ├── network.wit
    └── ...
```

**目录设计原则**：
- `00-04层`：链式骨架，目录结构稳定，很少变化
- `03-capabilities/`：树形分叉，每个硬件类型下的积木可以自由生长，灵活添加

---

### 🎯 实现方案B的关键技术点总结

| 技术点 | 具体内容 |
|-------|---------|
| **接口拆分** | 把大接口拆成独立、小的功能积木 |
| **能力发现** | hardware驱动通过 `capability-discovery` 接口返回支持的积木 |
| **按需实现** | 硬件驱动可以选择性实现功能积木，不需要全实现 |
| **按需使用** | 应用只选择自己需要的积木，不被迫使用大而全的接口 |
| **独立进化** | 每个积木可以独立添加、废弃、清理，不影响其他积木 |
| **目录组织** | 链式骨架目录（00-04）稳定，功能积木目录（03）灵活生长 |

---

### 🚀 迁移策略：从旧设计到新设计

**第1阶段（现在）**：
- 继续用旧设计，但规划向新设计迁移
- 同时实现"废弃标记+渐进清理"作为过渡

**第2阶段（6个月后）**：
- 为新硬件类型直接用新设计
- 为新功能直接加新的功能积木
- 不再创建新的 camera-core-v4 这种大接口

**第3阶段（1-2年后）**：
- 把现有旧接口迁移到功能积木模型
- 逐步废弃旧的大接口

**第4阶段（长期）**：
- 完全迁移到功能组合模型
- 永远不会再变成屎山！

---

### 🎯 总结

方案B（**接口设计语言**）是完全可实现的！只要按照：

#### 技术实现步骤：
1. **接口拆分**：把大接口拆成小积木
2. **能力发现**：硬件通过 `capability-discovery` 返回支持的积木
3. **按需实现/使用**：硬件和应用都可以自由选择
4. **独立进化**：每个积木可以独立添加、废弃、清理
5. **合理的目录结构**：链式骨架稳定，功能积木灵活生长

#### 设计原则（像编程语言一样）：
1. **简单性**：积木要小而专一，不要大而全
2. **正交性**：积木之间要独立，不要有依赖
3. **可组合性**：积木可以自由组合，解决任意业务需求

我们就可以**从根本上避免屎山，既保持稳定，又灵活进化，像编程语言一样强大！**

---

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

## 链式架构可视化

```
第0层（根接口）resource
    ↑ 包含
第1层（基础组件）configurable
    ↑ 包含
第2层（通用能力）power, security, diagnostics
    ↑ 包含
第3层（硬件抽象）camera, display, storage, network
    ↑ 包含
第4层（系统服务）filesystem, process, ipc
```

### 核心规则

1. **根接口永不改变**：第0层定义后完全冻结
2. **上层必须包含下层**：每一层必须完整包含上一层的所有接口
3. **只增不改**：只能添加新接口，不能修改或删除现有接口
4. **前一个衔接上一个**：永不断裂

***

## 接口组织方式

```
interfaces/
├── 0️⃣ root/              # 第0层：根接口（完全冻结，永不改变）
│   └── resource.wit      # 一切的起点
│
├── 1️⃣ foundation/        # 第1层：基础组件（稳定，只增不改）
│   ├── types.wit         # 基础类型
│   ├── error.wit         # 错误类型
│   └── component.wit     # 基础组件接口
│
├── 2️⃣ capabilities/      # 第2层：通用能力（稳定，只增不改）
│   ├── power.wit         # 电源管理能力
│   ├── security.wit      # 安全加密能力
│   ├── diagnostics.wit   # 诊断能力
│   └── lifecycle.wit     # 生命周期管理能力
│
├── 3️⃣ cap/               # 第3层：硬件抽象（稳定，只增不改）
│   ├── camera.wit        # 摄像头接口
│   ├── display.wit       # 显示接口
│   ├── storage.wit       # 存储接口
│   ├── network.wit       # 网络接口
│   └── sensor.wit        # 传感器接口
│
└── 4️⃣ env/               # 第4层：系统服务（可扩展，只增不改）
    ├── filesystem.wit    # 文件系统
    ├── process.wit       # 进程管理
    └── ipc.wit           # 进程间通信
```

***

## 重要警告：版本化分叉 vs 链式演进

### ❌ 错误方式：版本化分叉

```
v1.0 → v1.1 (分叉1) → v2.0 (分叉2) → ...
结果：需要同时维护多个版本，最终变成"森林债务"
```

### ✅ 正确方式：链式演进

```
初始 → 只添加新接口（不改旧的）→ 继续添加...
结果：永远只有一条链，简洁清晰
```

### 接口演进原则

1. 只能添加新的接口/方法，不能修改或删除现有
2. 新方法使用新的名字，不覆盖旧方法
3. 用能力发现来检测新功能是否可用
4. 根接口永远冻结

***

## 链式演进示例

### ❌ 错误示例

```wit
// 旧代码
interface camera {
    capture() -> image;
}

// 新代码：直接修改！
interface camera {
    capture(config: CaptureConfig) -> image;  // 破坏性修改！
}
```

### ✅ 正确示例

```wit
// 旧代码：永远保留！
interface camera-core {
    resource device {
        capture() -> result<image, error>;
    }
}

// 新代码：只添加新方法！
interface camera-core {
    resource device {
        capture() -> result<image, error>;           // 保留旧方法！
        capture-with-config(config: CaptureConfig) -> result<image, error>;  // 新方法！
    }
}
```

***

## 能力发现机制：支持完全局部更新

### 核心设计思想

- **接口稳定**：现有接口永不修改
- **能力可选**：新功能作为可选能力添加
- **完全解耦**：硬件、服务、应用可以独立更新

***

### 方案 1：链式包含的能力接口（强烈推荐）✨

#### 你的方案：新接口包含旧接口

```wit
// 第0层：根接口（树干，永远冻结）
interface camera-core-v1 {
    resource device {
        capture() -> result<image, error>;
        start-recording() -> result<stream<frame>, error>;
        stop-recording() -> result<unit, error>;
        close() -> result<unit, error>;
    }
}

// 第4层：新接口（枝叶，包含旧接口的所有方法）
interface camera-core-v2 {
    resource device {
        // 🎯 关键：必须包含 v1 的所有方法（链式包含）
        capture() -> result<image, error>;
        start-recording() -> result<stream<frame>, error>;
        stop-recording() -> result<unit, error>;
        close() -> result<unit, error>;
        
        // v2 的新方法（枝叶分叉）
        capture-with-config(config: capture-config) -> result<image, error>;
        set-ai-mode(mode: ai-mode) -> result<unit, error>;
    }
}

// 设备可以选择性地实现多个能力
world smart-camera {
    export yiduo:foundation/base-component;
    export power-capability;
    export diagnostic-capability;
    export camera-core-v1;     // 旧功能，必须实现
    export camera-core-v2?;    // 新功能，可选实现（标记 ?）
}
```

#### 树形可视化

```
camera-core-v1 (树干，第0层)
    ↑ 必须包含
camera-core-v2 (枝叶，第4层，可选)
```

#### 驱动实现

```moonbit
// 方式1：只想支持 v1 的驱动
struct SimpleCameraDriver {
    // 只实现 v1 接口
    // ...
}

// 方式2：想支持 v2 的驱动
struct AdvancedCameraDriver {
    // 完整实现 v2 接口（自然包含 v1 的所有方法）
    // ...
}
```

#### 应用使用

```moonbit
fn take-photo(camera: camera) -> result<image, error> {
    // 方式1：只知道 v1，永远能用
    let v1 = camera.get-interface("camera-core-v1") as camera-core-v1;
    return v1.capture();
    
    // 方式2：知道 v2，尝试用更优的
    if (camera.has-interface("camera-core-v2")) {
        let v2 = camera.get-interface("camera-core-v2") as camera-core-v2;
        return v2.capture-with-config(high-quality-config);
    }
    
    // 回退到 v1（总能工作）
    let v1 = camera.get-interface("camera-core-v1") as camera-core-v1;
    return v1.capture();
}
```

***

### 方案 2：纯能力接口（备选）

```wit
// 核心设计：每个功能是独立的接口
interface camera-core-v1 {
    resource device {
        capture() -> result<image, error>;
    }
}

interface image-capture-advanced {
    capture-with-config(config: capture-config) -> result<image, error>;
}

// 设备可以选择性地实现多个能力
world smart-camera {
    export yiduo:foundation/base-component;
    export power-capability;
    export diagnostic-capability;
    export camera-core-v1;               // 旧功能，必须实现
    export image-capture-advanced?;      // 新功能，可选实现
}

// 能力发现
interface capability-discovery {
    // 检测是否支持某个能力接口
    has-interface(interface-name: string) -> result<bool, error>;
    
    // 获取能力对象（类型安全）
    get-interface(interface-name: string) -> result<resource, error>;
    
    // 列出所有可用接口
    list-interfaces() -> result<list<string>, error>;
}
```

### 使用示例（完全解耦）

```moonbit
fn take-photo(camera: camera) -> result<image, error> {
    // 方式 1：尝试使用 v2，失败就用 v1（推荐）
    if (camera.has-interface("camera-core-v2")) {
        let v2 = camera.get-interface("camera-core-v2") as camera-core-v2;
        return v2.capture-with-config(high-quality-config);
    }
    
    // 回退到 v1（保证兼容）
    let v1 = camera.get-interface("camera-core-v1") as camera-core-v1;
    return v1.capture();
}

// 方式 2：更优雅的版本感知（最佳）
fn take-photo-auto(camera: camera) -> result<image, error> {
    // 应用完全不知道硬件版本！
    // 通过能力管理器自动选择最佳实现
    capability-manager.get-best-capturer(camera)?.capture()
}
```

***

### 方案 2：版本化命名空间（可选）

```wit
// 不同版本作为不同包
package yiduo:camera-v1@1.0.0;  // 第 0 层，稳定
interface camera {
    capture() -> result<image, error>;
}

package yiduo:camera-v2@2.0.0;  // 第 4 层，新增
interface camera {
    capture-with-config(config: capture-config) -> result<image, error>;
}

// 能力发现时可以查询版本
interface capability-discovery {
    get-supported-versions(interface-name: string) -> result<list<string>, error>;
}
```

***

## 局部更新场景演示

### 场景 1：只更新硬件驱动，不更新应用

```
时间 t0：
├── 应用：只知道 v1 接口
└── 硬件驱动：实现 v1

时间 t1（只更新驱动）：
├── 应用：不变，继续用 v1
└── 硬件驱动：新增 v2 能力（可选）
└── 结果：旧代码继续工作，新应用可以用 v2！ ✅
```

### 场景 2：只更新应用，不更新驱动

```
时间 t0：
├── 应用：支持 v1 和 v2
└── 硬件驱动：实现 v1

时间 t1（只更新应用）：
├── 应用：用 v2 的代码，但检测到驱动没有 v2，自动回退 v1
└── 硬件驱动：不变
└── 结果：仍然完全正常！ ✅
```

### 场景 3：混合更新（最常见）

```
可以任意顺序更新：
1. 先更新驱动，后更新应用
2. 先更新应用，后更新驱动
3. 只更新一部分硬件驱动

结果：永远不破坏！ ✅
```

***

## 更新策略：渐进式部署

### 推荐的部署流程

```
阶段 1：只更新能力接口（可选）
├── 定义 v2 接口
└── 不修改任何代码

阶段 2：逐个更新硬件驱动
├── 驱动 1：新增 v2 实现
├── 驱动 2：新增 v2 实现
└── 驱动 3：暂时不动
└── 结果：驱动 1 和 2 有 v2，驱动 3 仍然用 v1

阶段 3：更新应用（可选）
├── 应用代码：优先用 v2，回退 v1
└── 结果：应用不知道哪些驱动有 v2，自动适配！
```

***

## 核心优势总结

| 特性         | 说明             |
| ---------- | -------------- |
| **完全解耦**   | 硬件、服务、应用可以独立更新 |
| **可选使用**   | 新功能是可选的，不强制更新  |
| **向后兼容**   | 旧代码永远工作        |
| **渐进式部署**  | 可以分批、局部更新      |
| **无需全量更新** | 不需要整个系统一起更新    |

***

### 与版本化分叉的对比

| 方式        | 耦合度       | 更新策略 | 推荐 |
| --------- | --------- | ---- | -- |
| **版本化分叉** | 高（需要同步更新） | 全量更新 | ❌  |
| **能力接口**  | 低（完全解耦）   | 局部更新 | ✅  |

***

## 完整示例：链式摄像头设计

```wit
// 1. 第0层（根接口）
package yiduo:root@1.0.0;

interface resource {
    resource resource {
        close() -> result<unit, error>;
        is-closed() -> result<bool, error>;
        get-id() -> result<string, error>;
        get-type() -> result<string, error>;
    }
}

// 2. 第1层（基础组件）
package yiduo:foundation@1.0.0;

world base-component {
    export yiduo:root/resource;
    export configurable;
}

interface configurable {
    set-config(key: string, value: string) -> result<unit, error>;
    get-config(key: string) -> result<string, error>;
}

// 3. 第2层（通用能力）
package yiduo:capabilities@1.0.0;

interface power-capability {
    set-low-power-mode(enabled: bool) -> result<unit, error>;
    get-power-consumption() -> result<u32, error>;
}

interface diagnostic-capability {
    get-temperature() -> result<f32, error>;
    run-self-test() -> result<bool, error>;
}

// 4. 第3层（摄像头接口）
package yiduo:camera@1.0.0;

world smart-camera {
    export yiduo:foundation/base-component;
    export power-capability;
    export diagnostic-capability;
    export camera-core;
}

interface camera-core {
    resource device {
        get-info() -> result<camera-info, error>;
        set-config(config: capture-config) -> result<unit, error>;
        get-config() -> result<capture-config, error>;
        capture() -> result<image, error>;
        start-recording() -> result<stream<frame>, error>;
        stop-recording() -> result<unit, error>;
        close() -> result<unit, error>;
        // 新增方法：只添加，不修改！
        capture-with-config(config: capture-config) -> result<image, error>;
    }
    open(id: string) -> result<device, error>;
    enumerate() -> result<list<string>, error>;
}
```

***

## 链式架构黄金法则

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

***

## 操作安全指南

| 操作            | 能否      | 说明     |
| ------------- | ------- | ------ |
| **添加新接口/新功能** | ✅ 完全可以  | 在链尾添加  |
| **修改现有接口**    | ❌ 绝对不可以 | 破坏链式结构 |
| **删除现有接口**    | ❌ 绝对不可以 | 破坏链式结构 |

***

## 总结：🔗 链式是血液系统，🌳 树形是生长的器官，混合架构的完美力量

这样设计出来的 `interfaces/`，才能真正做到：**"只要这个目录设计得足够优雅、足够抽象，整个系统的复杂度就会被死死地锁在那个小小的目录里，而不会扩散到整个代码库！"**

### 🔗 链式架构（血液系统）——贯穿整个系统，保证血液（数据/调用）可以流通到任何地方

- 就像人体的血液系统，从心脏到指尖，血液必须流通到全身
- 贯穿整个系统：从第0层到第4层，链式关系无处不在
- 血液畅通：保证数据/调用可以流通到任何地方
- 系统完整：整个系统完整不会断裂
- 层级固定：第0→1→2→3→4层，骨架永远不变
- 上层包含下层：永不断裂，保证兼容
- 只增不改：永远稳定

### 🌳 树形架构（生长的器官）——在链式骨架的基础上，生长出各种功能（像手脚、眼睛等）

- 就像一棵树，树干稳固后，可以长出各种器官（手脚、眼睛等）
- 链节点上可以灵活生长：camera-core-v1→v2→v3...
- 枝繁叶茂：功能越丰富，系统越强大
- 灵活应变：应对各种应用功能要求
- 不破坏血液系统：链式骨架永远稳定，血液畅通

**记住**：\*\*链式架构是血液系统（贯穿整个系统）+ 树形架构是生长的器官（在链式骨架上长出各种功能）\*\*的混合思想，是经过软件行业50年验证的、最成熟的架构原则之一！

**核心原则**：

- 🔗 链式（血液系统）：贯穿整个系统，链式包含，血液畅通，系统完整，永不变形，只增不改
- 🌳 树形（生长的器官）：链节点上灵活生长，枝繁叶茂，应对各种应用功能要求！

