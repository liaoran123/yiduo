// Device Loader - 配置文件即编程的 MoonBit 实现
// 实现声明式配置 + 命令式加载的混合方案

// ================== 配置数据结构 ==================

// 设备基本信息
struct DeviceInfo {
  id: String
  name: String
  type: String
  vendor: String
  model: String
}

// 能力规格
struct CapabilitySpec {
  name: String
  version: String
  required: Bool
}

// 链式骨架配置
struct ChainConfig {
  foundation: Array[String]
  core: Array[String]
}

// 完整设备配置
struct DeviceSpec {
  device: DeviceInfo
  chain: ChainConfig
  capabilities: Array[CapabilitySpec]
  combinations: Map[String, Array[String]]
}

// ================== 简单的 YAML 解析器（简化版） ==================
// 在真实项目中，可以使用更完整的 YAML 解析库

// 解析简单的 YAML 格式（为了演示，我们支持基本的键值对和列表）
fn parse_simple_yaml(yaml_str: String) -> Result[DeviceSpec, String] {
  let lines = yaml_str.split("\n").filter(|line| line.trim() != "" && !line.trim().starts_with("#"))
  
  // 初始化默认值
  let mut device = DeviceInfo {
    id: "unknown",
    name: "Unknown Device",
    type: "unknown",
    vendor: "Unknown",
    model: "Unknown",
  }
  
  let mut chain = ChainConfig {
    foundation: Array.empty(),
    core: Array.empty(),
  }
  
  let mut capabilities: Array[CapabilitySpec] = Array.empty()
  let mut combinations: Map[String, Array[String]] = Map.empty()
  
  let mut current_section: String = ""
  let mut current_capability: Option[CapabilitySpec] = None
  
  for line in lines {
    let trimmed = line.trim()
    
    if trimmed.ends_with(":") {
      current_section = trimmed.slice(0, trimmed.length() - 1)
    } else if trimmed.starts_with("- ") {
      // 列表项
      let value = trimmed.slice(2, trimmed.length())
      
      if current_section == "capabilities" {
        if value.starts_with("name:") {
          if let Some(cap) = current_capability {
            capabilities.push(cap)
          }
          current_capability = Some(CapabilitySpec {
            name: value.slice(5, value.length()).trim(),
            version: "1.0.0",
            required: false,
          })
        } else if let Some(ref mut cap) = current_capability {
          if value.starts_with("version:") {
            cap.version = value.slice(8, value.length()).trim()
          } else if value.starts_with("required:") {
            cap.required = value.slice(9, value.length()).trim() == "true"
          }
        }
      }
    } else if let Some(colon_pos) = trimmed.index_of(":") {
      let key = trimmed.slice(0, colon_pos).trim()
      let value = trimmed.slice(colon_pos + 1, trimmed.length()).trim()
      
      match key {
        | "id" => device.id = value
        | "name" => device.name = value
        | "type" => device.type = value
        | "vendor" => device.vendor = value
        | "model" => device.model = value
        | _ => ()
      }
    }
  }
  
  // 添加最后一个 capability
  if let Some(cap) = current_capability {
    capabilities.push(cap)
  }
  
  Ok(DeviceSpec {
    device: device,
    chain: chain,
    capabilities: capabilities,
    combinations: combinations,
  })
}

// ================== Device Loader 实现 ==================

// 从文件加载配置（简化版）
fn load_config_from_string(yaml_content: String) -> Result[DeviceSpec, String] {
  parse_simple_yaml(yaml_content)
}

// 验证配置正确性
fn validate_config(spec: DeviceSpec) -> Result[Unit, String] {
  // 检查设备 ID
  if spec.device.id == "" || spec.device.id == "unknown" {
    return Err("Invalid device ID")
  }
  
  // 检查必需的能力是否存在
  for cap in spec.capabilities {
    if cap.required && cap.name == "" {
      return Err("Invalid required capability")
    }
  }
  
  Ok(())
}

// 应用组合套餐
fn apply_combination(spec: DeviceSpec, combo_name: String) -> Result[Array[String], String] {
  match spec.combinations.get(combo_name) {
    | Some(capabilities) => Ok(capabilities),
    | None => Err("Combination not found: " + combo_name),
  }
}

// 列出所有可用设备（简化版）
fn list_available_devices() -> Array[DeviceInfo] {
  // 实际项目中，可以扫描 device-specs 目录
  [
    {
      id: "sony-imx327",
      name: "Sony IMX327 Camera",
      type: "camera",
      vendor: "Sony",
      model: "IMX327",
    },
  ]
}

// ================== 使用示例 ==================

fn main() -> Unit {
  // 示例 YAML 配置
  let sample_yaml = """
device:
  id: sony-imx327
  name: Sony IMX327 Camera
  type: camera
  vendor: Sony
  model: IMX327

capabilities:
  - name: camera-capture
    version: 1.0.0
    required: true
  - name: camera-info
    version: 1.0.0
    required: true
  - name: camera-config
    version: 1.0.0
    required: false
"""
  
  println("=== Loading Device Configuration ===")
  
  match load_config_from_string(sample_yaml) {
    | Ok(spec) => {
      println("✓ Config loaded successfully!")
      println("  Device: " + spec.device.name + " (" + spec.device.id + ")")
      println("  Type: " + spec.device.type)
      
      match validate_config(spec) {
        | Ok(_) => println("✓ Config validation passed!"),
        | Err(e) => println("✗ Config validation failed: " + e),
      }
    }
    | Err(e) => println("✗ Failed to load config: " + e),
  }
  
  println()
  println("=== Available Devices ===")
  for dev in list_available_devices() {
    println("- " + dev.name + " (" + dev.id + ")")
  }
}
