// ==================== 可编程调度系统 - 后端管理器
// 像编译器一样：解析配置 -> 验证 -> 调度 -> 执行 -> 监控
// 借鉴 Kubernetes 风格的架构设计

// ========== 核心枚举类型

// 后端状态
enum BackendStatus {
  Unknown
  Healthy
  Degraded
  Unhealthy
}

// 选择策略
enum SelectionStrategy {
  PreferNative      // 优先原生实现
  PreferCompatible  // 优先兼容性
  PreferPerformance // 优先性能
  PreferFallback   // 优先降级选项
}

// ========== 核心数据结构

// 后端信息（K8s风格
struct BackendInfo {
  name: String
  capability: String
  priority: Int
  native: Bool
  fallback: Bool
  testOnly: Bool
  status: BackendStatus
  healthCheckCount: Int
  consecutiveFailures: Int
}

// 健康检查配置
struct HealthCheckConfig {
  enabled: Bool
  intervalSeconds: Int
  timeoutSeconds: Int
  failureThreshold: Int
  successThreshold: Int
}

// 容错配置
struct FaultToleranceConfig {
  autoFallback: Bool
  autoRecovery: Bool
  recoveryDelaySeconds: Int
}

// 后端配置
struct BackendConfig {
  primary: String
  fallbacks: Array[String]
  strategy: SelectionStrategy
  healthCheck: HealthCheckConfig
  faultTolerance: FaultToleranceConfig
}

// 能力规格
struct CapabilitySpec {
  name: String
  backend: BackendConfig
}

// 设备规格（K8s 风格）
struct DeviceSpec {
  apiVersion: String
  kind: String
  metadata: DeviceMetadata
  spec: DeviceSpecContent
}

struct DeviceMetadata {
  name: String
  deviceType: String
  vendor: String
  model: String
}

struct DeviceSpecContent {
  capabilities: Array[CapabilitySpec]
}

// ========== 后端管理器
struct BackendManager {
  // 注册的后端
  backends: Map[String, Array[BackendInfo]]
  // 当前活跃后端
  activeBackends: Map[String, String]
  // 配置
  spec: Option[DeviceSpec]
}

// ========== 后端管理器方法

fn BackendManager::new() -> BackendManager {
  BackendManager {
    backends: Map::empty(),
    activeBackends: Map::empty(),
    spec: None,
  }
}

// 注册后端
fn BackendManager::registerBackend(self, capability: String, name: String, priority: Int, native: Bool, fallback: Bool, testOnly: Bool) -> Unit {
  let info = BackendInfo {
    name: name,
    capability: capability,
    priority: priority,
    native: native,
    fallback: fallback,
    testOnly: testOnly,
    status: BackendStatus::Unknown,
    healthCheckCount: 0,
    consecutiveFailures: 0,
  }
  
  if let Some(mut existing) = self.backends.get(capability) {
    existing.push(info)
    self.backends[capability] = existing
  } else {
    let mut arr: Array[BackendInfo] = []
    arr.push(info)
    self.backends[capability] = arr
  }
}

// 加载配置
fn BackendManager::loadSpec(self, spec: DeviceSpec) -> Unit {
  self.spec = Some(spec)
}

// ========== 编译期：配置验证
fn BackendManager::validateSpec(self) -> Result[Unit, String] {
  let specOpt = self.spec
  if specOpt is None {
    return Err("No device spec loaded")
  }
  let spec = specOpt as DeviceSpec
  
  // 验证每个能力的后端配置
  for capSpec in spec.spec.capabilities {
    let capability = capSpec.name
    
    // 检查是否有该能力的后端注册
    if !self.backends.has(capability) {
      return Err("No backends registered for capability: " + capability)
    }
    
    // 检查 primary 后端是否存在
    let backends = self.backends[capability] as Array[BackendInfo]
    let primaryName = capSpec.backend.primary
    let mut found = false
    for info in backends {
      if info.name == primaryName {
        found = true
        break
      }
    }
    if !found {
      return Err("Primary backend '" + primaryName + "' not found for capability: " + capability)
    }
  }
  
  Ok(())
}

// ========== 编译期：选择后端（策略驱动）
fn BackendManager::selectBackend(self, capability: String) -> Result[String, String] {
  if !self.backends.has(capability) {
    return Err("No backends registered for: " + capability)
  }
  
  let backends = self.backends[capability] as Array[BackendInfo]
  let strategy = self.getStrategy(capability)
  
  // 根据策略排序
  let mut sorted = sortBackendsByStrategy(backends, strategy)
  
  // 选择第一个健康的
  for info in sorted {
    if info.status == BackendStatus::Healthy || info.status == BackendStatus::Unknown {
      return Ok(info.name)
    }
  }
  
  // 如果都不行，尝试降级选项
  for info in sorted {
    if info.fallback && info.status != BackendStatus::Unhealthy {
      return Ok(info.name)
    }
  }
  
  Err("No available backend for: " + capability)
}

// 排序后端按策略
fn sortBackendsByStrategy(backends: Array[BackendInfo], strategy: SelectionStrategy) -> Array[BackendInfo] {
  let mut result = backends
  let n = result.length()
  
  // 简单冒泡排序
  let mut i = 0
  while i < n {
    let mut j = 0
    while j < n - i - 1 {
      if compareBackends(result[j], result[j+1], strategy) < 0 {
        let temp = result[j]
        result[j] = result[j+1]
        result[j+1] = temp
      }
      j = j + 1
    }
    i = i + 1
  }
  result
}

// 比较后端
fn compareBackends(a: BackendInfo, b: BackendInfo, strategy: SelectionStrategy) -> Int {
  match strategy {
    | SelectionStrategy::PreferNative => {
      if a.native && !b.native { 1 }
      else if !a.native && b.native { -1 }
      else { b.priority - a.priority }
    }
    | SelectionStrategy::PreferFallback => {
      if a.fallback && !b.fallback { 1 }
      else if !a.fallback && b.fallback { -1 }
      else { b.priority - a.priority }
    }
    | _ => b.priority - a.priority
  }
}

// 获取策略
fn BackendManager::getStrategy(self, capability: String) -> SelectionStrategy {
  let specOpt = self.spec
  if specOpt is None {
    return SelectionStrategy::PreferNative
  }
  let spec = specOpt as DeviceSpec
  
  for capSpec in spec.spec.capabilities {
    if capSpec.name == capability {
      return capSpec.backend.strategy
    }
  }
  
  SelectionStrategy::PreferNative
}

// ========== 运行期：激活后端
fn BackendManager::activateBackend(self, capability: String, backendName: String) -> Result[Unit, String] {
  if !self.backends.has(capability) {
    return Err("No backends registered for: " + capability)
  }
  
  let backends = self.backends[capability] as Array[BackendInfo]
  let mut found = false
  for info in backends {
    if info.name == backendName {
      if info.status == BackendStatus::Healthy || info.status == BackendStatus::Unknown {
        found = true
        break
      }
    }
  }
  if !found {
    return Err("Backend '" + backendName + "' not available for: " + capability)
  }
  
  self.activeBackends[capability] = backendName
  Ok(())
}

// ========== 运行期：健康检查成功
fn BackendManager::reportHealthSuccess(self, capability: String, backendName: String) -> Unit {
  updateBackendHealth(self, capability, backendName, true)
}

// ========== 运行期：健康检查失败
fn BackendManager::reportHealthFailure(self, capability: String, backendName: String) -> Unit {
  updateBackendHealth(self, capability, backendName, false)
}

// 更新后端健康状态
fn updateBackendHealth(manager: BackendManager, capability: String, backendName: String, success: Bool) -> Unit {
  if !manager.backends.has(capability) {
    return
  }
  
  let backends = manager.backends[capability] as Array[BackendInfo]
  let mut updated: Array[BackendInfo] = []
  for info in backends {
    if info.name == backendName {
      let mut newInfo = info
      newInfo.healthCheckCount = info.healthCheckCount + 1
      if success {
        newInfo.status = BackendStatus::Healthy
        newInfo.consecutiveFailures = 0
      } else {
        newInfo.consecutiveFailures = info.consecutiveFailures + 1
        if newInfo.consecutiveFailures >= 3 {
          newInfo.status = BackendStatus::Unhealthy
        } else {
          newInfo.status = BackendStatus::Degraded
        }
      }
      updated.push(newInfo)
    } else {
      updated.push(info)
    }
  }
  manager.backends[capability] = updated
}

// ========== 运行期：检查并自动降级
fn BackendManager::checkAndFallback(self, capability: String) -> Bool {
  let activeOpt = self.activeBackends.get(capability)
  if activeOpt is None {
    return false
  }
  
  let activeName = activeOpt as String
  
  // 检查当前后端是否不健康
  if !self.backends.has(capability) {
    return false
  }
  
  let backends = self.backends[capability] as Array[BackendInfo]
  let mut needsFallback = false
  for info in backends {
    if info.name == activeName {
      needsFallback = info.status == BackendStatus::Unhealthy
      break
    }
  }
  
  if needsFallback {
    match self.selectBackend(capability) {
      | Ok(newBackend) => {
        if newBackend != activeName {
          println("[Scheduler] Fallback: " + activeName + " -> " + newBackend)
          match self.activateBackend(capability, newBackend) {
            | Ok(_) => return true,
            | Err(_) => return false,
          }
        }
        false
      }
      | Err(_) => false
    }
  } else {
    false
  }
}

// ========== 状态查询
fn BackendManager::getStatusString(self) -> String {
  let mut result = "=== Backend Manager Status ===\n"
  
  result += "Active Backends:\n"
  for (capability, backendName) in self.activeBackends {
    let status = self.getBackendStatusString(capability, backendName)
    result += "  " + capability + ": " + backendName + " " + status + "\n"
  }
  
  result += "\nRegistered Backends:\n"
  for (capability, backends) in self.backends {
    result += "  " + capability + ":\n"
    for info in backends {
      let status = backendStatusToString(info.status)
      let native = if info.native { "native" } else { "compat" }
      let fallback = if info.fallback { "fallback" } else { "primary" }
      result += "    [" + status + "] " + info.name + " (p:" + info.priority.toString() + " " + native + " " + fallback + ")\n"
    }
  }
  
  result
}

fn BackendManager::getBackendStatusString(self, capability: String, backendName: String) -> String {
  if !self.backends.has(capability) {
    return "[?]"
  }
  let backends = self.backends[capability] as Array[BackendInfo]
  for info in backends {
    if info.name == backendName {
      let status = backendStatusToString(info.status)
      return "[" + status + "]"
    }
  }
  "[?]"
}

fn backendStatusToString(status: BackendStatus) -> String {
  match status {
    | BackendStatus::Healthy => "✓ Healthy",
    | BackendStatus::Degraded => "⚠ Degraded",
    | BackendStatus::Unhealthy => "✗ Unhealthy",
    | BackendStatus::Unknown => "? Unknown",
  }
}

// ========== 工具函数：创建模拟配置
fn createSampleDeviceSpec() -> DeviceSpec {
  DeviceSpec {
    apiVersion: "yiduo.dev/v1alpha1",
    kind: "DeviceSpec",
    metadata: DeviceMetadata {
      name: "smart-camera",
      deviceType: "camera",
      vendor: "sony",
      model: "imx327",
    },
    spec: DeviceSpecContent {
      capabilities: [
        CapabilitySpec {
        name: "camera",
        backend: BackendConfig {
          primary: "libcamera",
          fallbacks: ["opencv", "mock"],
          strategy: SelectionStrategy::PreferNative,
          healthCheck: HealthCheckConfig {
            enabled: true,
            intervalSeconds: 10,
            timeoutSeconds: 3,
            failureThreshold: 3,
            successThreshold: 2,
          },
          faultTolerance: FaultToleranceConfig {
            autoFallback: true,
            autoRecovery: true,
            recoveryDelaySeconds: 60,
          },
        },
      },
      CapabilitySpec {
        name: "audio",
        backend: BackendConfig {
          primary: "pulseaudio",
          fallbacks: ["alsa", "mock"],
          strategy: SelectionStrategy::PreferCompatible,
          healthCheck: HealthCheckConfig {
            enabled: true,
            intervalSeconds: 10,
            timeoutSeconds: 3,
            failureThreshold: 3,
            successThreshold: 2,
          },
          faultTolerance: FaultToleranceConfig {
            autoFallback: true,
            autoRecovery: true,
            recoveryDelaySeconds: 60,
          },
        },
      },
      CapabilitySpec {
        name: "storage",
        backend: BackendConfig {
          primary: "posix",
          fallbacks: ["inmemory", "mock"],
          strategy: SelectionStrategy::PreferPerformance,
          healthCheck: HealthCheckConfig {
            enabled: true,
            intervalSeconds: 10,
            timeoutSeconds: 3,
            failureThreshold: 3,
            successThreshold: 2,
          },
          faultTolerance: FaultToleranceConfig {
            autoFallback: true,
            autoRecovery: true,
            recoveryDelaySeconds: 60,
          },
        },
      },
      ],
    },
  }
}
