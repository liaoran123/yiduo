# 一多 OS 接口文档索引

## 概述

本目录包含一多 OS 的接口设计文档和使用指南。

---

## 📂 文档目录

### 设计理念与架构
| 文档 | 说明 |
|------|------|
| [001.设计原则：如何做到足够优雅、足够抽象.md](./001.设计原则：如何做到足够优雅、足够抽象.md) | 一多 OS 的核心设计哲学 |
| [002.接口设计示例.md](./002.接口设计示例.md) | 具体的接口设计示例和最佳实践 |
| [004.架构符合性检测报告.md](./004.架构符合性检测报告.md) | 检查当前实现是否符合设计原则 |
| [005.操作系统接口完整性分析.md](./005.操作系统接口完整性分析.md) | 操作系统级别的接口完整性评估 |
| [006.商业项目路线图.md](./006.商业项目路线图.md) | 面向商业项目的开发路线图 |
| [026.Native-Wasm组件切换架构设计.md](./026.Native-Wasm组件切换架构设计.md) | Native 和 Wasm 组件动态切换的架构设计 |

---

## 🔗 接口定义（WIT 文件）

### Base 层（链式骨架）
| 接口文件 | 说明 | 详细文档 |
|---------|------|---------|
| [../base/types.wit](../base/types.wit) | 基础数据类型定义 | [base-types 接口文档](./101.base-types.md) |
| [../base/error.wit](../base/error.wit) | 错误处理和错误码定义 | [base-error 接口文档](./102.base-error.md) |

### Cap 层（能力器官）
| 接口文件 | 说明 | 详细文档 |
|---------|------|---------|
| [../cap/camera/capture.wit](../cap/camera/capture.wit) | 摄像头捕获能力 | [cap-camera-capture 接口文档](./201.cap-camera-capture.md) |
| [../cap/camera/config.wit](../cap/camera/config.wit) | 摄像头配置能力 | [cap-camera-config 接口文档](./202.cap-camera-config.md) |
| [../cap/camera/stream.wit](../cap/camera/stream.wit) | 摄像头视频流能力 | [cap-camera-stream 接口文档](./203.cap-camera-stream.md) |
| [../cap/camera/info.wit](../cap/camera/info.wit) | 摄像头信息获取能力 | [cap-camera-info 接口文档](./204.cap-camera-info.md) |
| [../cap/audio.wit](../cap/audio.wit) | 音频输入输出能力 | [cap-audio 接口文档](./205.cap-audio.md) |
| [../cap/display.wit](../cap/display.wit) | 显示输出能力 | [cap-display 接口文档](./206.cap-display.md) |
| [../cap/input.wit](../cap/input.wit) | 输入设备能力 | [cap-input 接口文档](./207.cap-input.md) |
| [../cap/storage.wit](../cap/storage.wit) | 存储能力 | [cap-storage 接口文档](./208.cap-storage.md) |
| [../cap/sensor.wit](../cap/sensor.wit) | 传感器能力 | [cap-sensor 接口文档](./209.cap-sensor.md) |
| [../cap/network.wit](../cap/network.wit) | 网络硬件能力 | [cap-network 接口文档](./210.cap-network.md) |
| [../cap/usb.wit](../cap/usb.wit) | USB 总线能力 | [cap-usb 接口文档](./211.cap-usb.md) |
| [../cap/power.wit](../cap/power.wit) | 电源管理能力 | [cap-power 接口文档](./212.cap-power.md) |
| [../cap/device-loader.wit](../cap/device-loader.wit) | 设备配置加载能力 | [cap-device-loader 接口文档](./213.cap-device-loader.md) |
| [../cap/component-manager.wit](../cap/component-manager.wit) | Native/Wasm 组件管理能力 | [cap-component-manager 接口文档](./214.cap-component-manager.md) |
| [../cap/unihal.wit](../cap/unihal.wit) | 统一硬件抽象层 | [cap-unihal 接口文档](./215.cap-unihal.md) |
| [../capabilities.wit](../capabilities.wit) | 能力定义根文件 | - |

### Env 层（系统服务）
| 接口文件 | 说明 | 详细文档 |
|---------|------|---------|
| [../env/fs.wit](../env/fs.wit) | 文件系统服务 | [env-fs 接口文档](./301.env-fs.md) |
| [../env/net.wit](../env/net.wit) | 网络通信服务 | [env-net 接口文档](./302.env-net.md) |
| [../env/os.wit](../env/os.wit) | 操作系统基础服务 | [env-os 接口文档](./303.env-os.md) |
| [../env/process.wit](../env/process.wit) | 进程管理服务 | [env-process 接口文档](./304.env-process.md) |
| [../env/memory.wit](../env/memory.wit) | 内存管理服务 | [env-memory 接口文档](./305.env-memory.md) |
| [../env/component.wit](../env/component.wit) | 组件管理服务 | [env-component 接口文档](./306.env-component.md) |

---

## 📖 接口文档分类

### 按优先级分类
| 优先级 | 说明 | 接口列表 |
|-------|------|---------|
| **高优先级** | 核心能力，必须文档化 | camera系列, audio, display, device-loader |
| **中优先级** | 重要能力，建议文档化 | storage, sensor, network, power |
| **低优先级** | 补充能力，按需文档化 | usb, 其他扩展能力 |

### 按层次分类
* **Base 层**：所有接口的基础类型和错误处理
* **Cap 层**：硬件抽象能力（Camera、Audio、Display...）
* **Env 层**：系统服务（FS、Net、Process...）

---

## 🎯 文档模板

新接口文档建议包含以下章节：

```markdown
# 接口名称

## 概述
简要描述这个接口的功能和用途。

## 核心类型
### 类型 1
说明类型的定义和用途。

## 接口函数
### 函数 1
#### 签名
函数的完整签名

#### 说明
函数的详细说明

#### 参数
参数列表和说明

#### 返回值
返回值的说明

#### 错误码
可能的错误码和含义

#### 示例代码
使用示例

## 使用示例
### 场景 1
完整的示例代码

## 最佳实践
- 实践 1
- 实践 2

## 相关接口
- 相关接口 1
- 相关接口 2
```

---

## 📝 文档规范

### 命名规范
* 文件名格式：`{编号}-{模块}-{功能}.md`
  * 例如：`101-base-types.md`, `201-cap-camera-capture.md`
* 编号规则：
  * `100-199`：Base 层
  * `200-299`：Cap 层
  * `300-399`：Env 层

### 内容规范
* 每个接口文档应该包含：概述、核心类型、接口函数、使用示例、最佳实践
* 每个函数应该包含：签名、说明、参数、返回值、错误码、示例代码

---

## 🚀 下一步

* [ ] 为所有高优先级接口创建详细文档
* [ ] 为所有中优先级接口创建详细文档
* [ ] 为所有低优先级接口创建简单文档
* [ ] 定期维护和更新文档
