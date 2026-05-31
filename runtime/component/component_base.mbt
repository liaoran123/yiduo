/// 🧬 一多 OS 组件基础

///|
/// ==================== 组件类型（双模运行时） ====================
/// Native: 直接在本进程中执行的 MoonBit 组件
/// Wasm: 通过 Wasm 运行时隔离执行的组件
pub enum ComponentType {
  Native
  Wasm
  MoonBit
}

///|
/// 创建 Native 类型
pub fn ComponentType::native() -> ComponentType {
  Native
}

///|
/// 创建 Wasm 类型
pub fn ComponentType::wasm() -> ComponentType {
  Wasm
}

///|
/// 创建 MoonBit 类型
pub fn ComponentType::moonbit() -> ComponentType {
  MoonBit
}

///|
pub impl Eq for ComponentType with fn equal(self, other) {
  self.to_string() == other.to_string()
}

///|
/// ComponentType 转字符串
pub fn ComponentType::to_string(self : ComponentType) -> String {
  match self {
    Native => "native"
    Wasm => "wasm"
    MoonBit => "moonbit"
  }
}

///|
/// ComponentType 转整数（用于跨包 match）
pub fn ComponentType::to_int(self : ComponentType) -> Int {
  match self {
    Native => 0
    Wasm => 1
    MoonBit => 2
  }
}

///|
/// 从字符串解析 ComponentType
pub fn ComponentType::from_string(s : String) -> ComponentType? {
  match s {
    "native" => Some(Native)
    "wasm" => Some(Wasm)
    "moonbit" => Some(MoonBit)
    _ => None
  }
}

///|
/// ==================== 消息处理器别名 ====================
/// Native 组件的消息处理函数签名
/// 参数：(接收组件ID, 发送组件ID, 消息负载)
pub type NativeMessageHandler = (Int, Int, @core.SmallPayload) -> Unit

///|
/// ==================== 内存优先级 ====================
pub enum MemoryPriority {
  Critical
  Normal
  Low
}

///|
/// ==================== 组件配置（扩展：使用 ComponentType） ====================
pub struct ComponentConfig {
  name : String
  component_type : ComponentType
  config_data : String
  memory_priority : MemoryPriority
}

///|
/// ==================== 组件能力声明 ====================
pub struct Capability {
  interface_name : String
  version : String
}

///|
/// ==================== 组件状态 ====================
pub enum ComponentState {
  Created
  Initialized
  Running
  Paused
  Stopped
  Failed
}

///|
type ComponentId = Int

///|
type WasmComponentHandle = Int
