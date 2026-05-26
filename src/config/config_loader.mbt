/// 一多 OS 配置加载模块（简化版）
/// 移除了 capabilities 相关字段，直接使用 ID 通信

/// 配置类型
enum ConfigType {
  YAML
  JSON
}

/// 组件配置（简化版，移除 capabilities）
struct ComponentConfig {
  name: String
  component_type: String
  description: Option[String]
  path: Option[String]
  required: Bool
}

/// 元数据
struct Metadata {
  name: String
  version: String
  description: Option[String]
}

/// 应用规格
struct Spec {
  components: List[ComponentConfig]
}

/// 完整应用配置
struct AppConfig {
  api_version: String
  kind: String
  metadata: Metadata
  spec: Spec
}

/// 解析配置文件
fn parse_file(path: String, config_type: ConfigType) -> Result[AppConfig, String] {
  println("[Config] 解析配置文件: " + path)
  println("[Config] 类型: " + match config_type {
    YAML => "YAML"
    JSON => "JSON"
  })
  Ok(AppConfig::{
    api_version: "yiduo.dev/v1alpha1",
    kind: "Application",
    metadata: Metadata::{name: "demo-app", version: "1.0.0", description: Some("演示应用")},
    spec: Spec::{
      components: [
        ComponentConfig::{name: "logger", component_type: "native", description: Some("日志服务"), path: Some("./components/logger"), required: true}
      ]
    }
  })
}

/// 从路径加载配置
fn load(path: String) -> Result[AppConfig, String] {
  let config_type = if path.ends_with(".yaml") || path.ends_with(".yml") {
    YAML
  } else {
    JSON
  }
  parse_file(path, config_type)
}

/// 一多 OS 自举配置（最小验证版本，简化）
const BOOTSTRAP_CONFIG_TEXT = """
yiduo.dev/v1alpha1
Application
demo-app
1.0.0
演示应用
logger
native
日志服务
./components/logger
true
counter
wasm
计数器
./components/counter
true
display
wasm
显示器
./components/display
true
"""

/// 从简化格式解析配置（自举验证阶段使用）
fn parse_from_string(config_text: String) -> Result[AppConfig, String] {
  println("[Config] 从字符串解析配置...")
  
  let lines = config_text.split("\n").filter(fn(s) { s.trim() != "" }).to_list()
  if lines.length() < 5 {
    return Err("配置格式错误")
  }
  
  let api_version = lines[0].trim()
  let kind = lines[1].trim()
  let name = lines[2].trim()
  let version = lines[3].trim()
  let desc = Some(lines[4].trim())
  
  let mut components: List[ComponentConfig] = []
  let mut i = 5
  while i < lines.length() {
    if i + 4 < lines.length() {
      let comp_name = lines[i].trim()
      let comp_type = lines[i + 1].trim()
      let comp_desc = Some(lines[i + 2].trim())
      let comp_path = Some(lines[i + 3].trim())
      let comp_required = if lines[i + 4].trim() == "true" { true } else { false }
      
      components = ComponentConfig::{
        name: comp_name,
        component_type: comp_type,
        description: comp_desc,
        path: comp_path,
        required: comp_required
      } :: components
      
      i += 5
    } else {
      i += 1
    }
  }
  
  components = components.reverse()
  
  Ok(AppConfig::{
    api_version: api_version,
    kind: kind,
    metadata: Metadata::{name: name, version: version, description: desc},
    spec: Spec::{components: components}
  })
}

/// 加载自举配置（验证阶段使用）
fn load_bootstrap() -> Result[AppConfig, String] {
  parse_from_string(BOOTSTRAP_CONFIG_TEXT)
}

/// 验证配置完整性
fn validate(config: AppConfig) -> Result[Unit, String] {
  if config.metadata.name == "" {
    return Err("应用名称不能为空")
  }
  if config.spec.components.is_empty() {
    return Err("至少需要一个组件")
  }
  println("[Config] ✓ 配置验证通过 (" + config.spec.components.length().to_string() + " 个组件)")
  Ok(())
}
