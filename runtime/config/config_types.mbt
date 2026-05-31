/// 一多 OS 配置类型定义
/// 对应 bootstrap.yaml 和 configs/components/*.yaml 的结构

///|
/// 系统元信息
pub struct SystemMeta {
  name : String
  version : String
  description : String?
}

///|
/// 启动模式
pub enum BootstrapMode {
  Minimal
  Standard
  Full
}

///|
/// 日志级别
pub enum LogLevel {
  Debug
  Info
  Warn
  Error
}

///|
/// 启动配置
pub struct BootstrapConfig {
  mode : BootstrapMode
  log_level : LogLevel
  first_component : String
}

///|
/// Wasm 运行时配置
pub struct RuntimeConfig {
  max_components : Int
  max_memory_per_instance : Int
  runtime_type : String
}

///|
/// 完整引导配置（对应 bootstrap.yaml）
pub struct YiduoBootstrapConfig {
  system : SystemMeta
  bootstrap : BootstrapConfig
  runtime : RuntimeConfig?
}

///|
/// 接口条目（对应提供了 provides 中的一项）
pub struct InterfaceEntry {
  interface_name : String
  wit_file : String?
  description : String?
}

///|
/// 依赖条目（对应 requires 中的一项）
pub struct DependencyEntry {
  name : String
  interface_name : String
  required : Bool
  version : String?
  description : String?
}

///|
/// 组件描述（对应 configs/components/*.yaml）
pub struct ComponentDescriptor {
  name : String
  ns : String?
  version : String?
  component_type : String
  source : String?
  required : Bool
  description : String?
  provides : Array[InterfaceEntry]
  requires_interfaces : Array[DependencyEntry]
}

/// ==================== 构造器 ====================

///|
pub fn SystemMeta::create(
  name : String,
  version : String,
  description : String?,
) -> SystemMeta {
  SystemMeta::{ name, version, description }
}

///|
pub fn BootstrapConfig::create(
  mode : BootstrapMode,
  log_level : LogLevel,
  first_component : String,
) -> BootstrapConfig {
  BootstrapConfig::{ mode, log_level, first_component }
}

///|
pub fn RuntimeConfig::default() -> RuntimeConfig {
  RuntimeConfig::{
    max_components: 32,
    max_memory_per_instance: 64,
    runtime_type: "simulated",
  }
}

///|
pub fn InterfaceEntry::create(
  interface_name : String,
  wit_file : String?,
  description : String?,
) -> InterfaceEntry {
  InterfaceEntry::{ interface_name, wit_file, description }
}

///|
pub fn DependencyEntry::create(
  name : String,
  interface_name : String,
  required : Bool,
  version : String?,
  description : String?,
) -> DependencyEntry {
  DependencyEntry::{ name, interface_name, required, version, description }
}

///|
pub fn ComponentDescriptor::create(
  name : String,
  ns : String?,
  version : String?,
  component_type : String,
  source : String?,
  required : Bool,
  description : String?,
  provides : Array[InterfaceEntry],
  requires_interfaces : Array[DependencyEntry],
) -> ComponentDescriptor {
  ComponentDescriptor::{
    name,
    ns,
    version,
    component_type,
    source,
    required,
    description,
    provides,
    requires_interfaces,
  }
}

/// ==================== 格式转换 ====================

///|
/// 转换 BootstrapMode 为字符串
pub fn BootstrapMode::to_string(self : BootstrapMode) -> String {
  match self {
    Minimal => "minimal"
    Standard => "standard"
    Full => "full"
  }
}

///|
/// 从字符串解析 BootstrapMode
pub fn BootstrapMode::from_string(s : String) -> BootstrapMode? {
  match s {
    "minimal" => Some(Minimal)
    "standard" => Some(Standard)
    "full" => Some(Full)
    _ => None
  }
}

///|
/// 转换 LogLevel 为字符串
pub fn LogLevel::to_string(self : LogLevel) -> String {
  match self {
    Debug => "debug"
    Info => "info"
    Warn => "warn"
    Error => "error"
  }
}

///|
/// 从字符串解析 LogLevel
pub fn LogLevel::from_string(s : String) -> LogLevel? {
  match s {
    "debug" => Some(Debug)
    "info" => Some(Info)
    "warn" => Some(Warn)
    "error" => Some(Error)
    _ => None
  }
}
