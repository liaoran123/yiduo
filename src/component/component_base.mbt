/// 🧬 一多 OS Wasm 组件基础
/// 一切皆组件！包括：
///   - 事件总线组件
///   - 调度器组件
///   - AI大脑组件
///   - ...所有东西...

/// ==================== WIT 接口（所有组件的契约）====================
/// 这个接口定义组件的基本行为

interface YiduoComponent {
  initialize(config: ComponentConfig) -> Result<(), Error>
  heartbeat() -> Result<(), Error>
  shutdown() -> Result<(), Error>
  get_capability() -> Capability
}

/// ==================== 组件配置 ====================
struct ComponentConfig {
  name: String,
  component_type: String,
  config_data: String, // YAML 配置
}

/// ==================== 组件能力声明 ====================
struct Capability {
  interface_name: String,
  version: String,
}

/// ==================== 组件状态 ====================
enum ComponentState {
  Created,
  Initialized,
  Running,
  Paused,
  Stopped,
  Failed,
}

/// ==================== 组件实例 ====================
struct ComponentInstance {
  id: ComponentId,
  state: ComponentState,
  config: ComponentConfig,
  handle: WasmComponentHandle,
}

type ComponentId = Int
type WasmComponentHandle = Int
