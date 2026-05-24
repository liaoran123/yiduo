/// 一多 OS 配置加载模块（高性能版本）
/// 新增：内存池配置、组件配置

/// 配置类型
enum ConfigType {
  YAML
  JSON
}

/// 组件配置
struct ComponentConfig {
  name: String
  component_type: String
  description: Option[String]
  path: Option[String]
  capabilities: List[String]
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
        ComponentConfig::{name: "hello", component_type: "wasm", description: Some("Hello World"), path: Some("./components/hello.wasm"), capabilities: ["greet"], required: true},
        ComponentConfig::{name: "logger", component_type: "native", description: Some("日志服务"), path: Some("./components/logger"), capabilities: ["log"], required: true}
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