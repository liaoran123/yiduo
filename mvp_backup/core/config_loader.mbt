// 配置加载器 - 配置即编程
// 从 YAML 配置加载应用设置

///| 应用配置结构
struct AppConfig {
  app_name: String
  enabled_capabilities: Array[String]
  capability_order: Array[String]
  custom_settings: Map[String, String]
}

///| 创建默认配置
fn AppConfig::default() -> AppConfig {
  {
    app_name: "MVP App",
    enabled_capabilities: Array::empty(),
    capability_order: Array::empty(),
    custom_settings: Map::empty(),
  }
}

///| 从字符串加载配置（简化版 YAML 解析）
fn load_config_from_string(yaml_content: String) -> Result[AppConfig, String] {
  let mut config = AppConfig::default()
  let lines = yaml_content.split("\n")
  
  let mut current_section = ""
  let mut in_list = false
  
  for line in lines {
    let trimmed = line.trim()
    
    if trimmed == "" || trimmed.starts_with("#") {
      continue
    }
    
    // 检测 section
    if trimmed.ends_with(":") && !trimmed.starts_with("-") {
      current_section = trimmed.slice(0, trimmed.length() - 1)
      in_list = false
      continue
    }
    
    // 检测列表项
    if trimmed.starts_with("- ") {
      in_list = true
      let value = trimmed.slice(2, trimmed.length())
      
      if current_section == "enabled_capabilities" {
        config.enabled_capabilities.push(value)
      } else if current_section == "capability_order" {
        config.capability_order.push(value)
      }
      continue
    }
    
    // 检测键值对
    if let Some(colon_pos) = trimmed.index_of(":") {
      let key = trimmed.slice(0, colon_pos).trim()
      let value = trimmed.slice(colon_pos + 1, trimmed.length()).trim()
      
      if value.starts_with("\"") && value.ends_with("\"") {
        value = value.slice(1, value.length() - 1)
      }
      
      match current_section {
        | "" => {
          // 顶层配置
          match key {
            | "app_name" => config.app_name = value,
            | _ => (),
          }
        }
        | "custom_settings" => {
          config.custom_settings.set(key, value)
        }
        | _ => (),
      }
    }
  }
  
  Ok(config)
}

///| 验证配置
fn validate_config(config: AppConfig, registry: ComponentRegistry) -> Result[Unit, String] {
  // 检查所有配置的能力是否已注册
  for cap_name in config.enabled_capabilities {
    if registry.get_capability(cap_name).is_none() {
      return Err("能力未注册: " + cap_name)
    }
  }
  
  for cap_name in config.capability_order {
    if registry.get_capability(cap_name).is_none() {
      return Err("能力未注册: " + cap_name)
    }
  }
  
  Ok(())
}

///| 打印配置信息
fn print_config(config: AppConfig) -> Unit {
  println("\n📋 应用配置: " + config.app_name)
  println("   启用能力: " + config.enabled_capabilities.join(", "))
  println("   执行顺序: " + config.capability_order.join(" → "))
  if config.custom_settings.size() > 0 {
    println("   自定义设置:")
    for (key, value) in config.custom_settings {
      println("     " + key + " = " + value)
    }
  }
}
