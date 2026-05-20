// 组件注册表 - 管理所有可用的能力积木
// 树形器官的容器

///| 组件注册表结构
struct ComponentRegistry {
  mut capabilities: Map[String, Capability]
  mut custom_settings: Map[String, String]
}

///| 创建新的注册表
fn ComponentRegistry::new() -> ComponentRegistry {
  {
    capabilities: Map::empty(),
    custom_settings: Map::empty(),
  }
}

///| 注册能力积木
fn ComponentRegistry::register_capability(self, cap: Capability) -> Unit {
  self.capabilities.set(cap.capability_name(), cap)
  println("✓ 注册能力: " + cap.capability_name())
}

///| 获取能力积木
fn ComponentRegistry::get_capability(self, name: String) -> Option[Capability] {
  self.capabilities.get(name)
}

///| 列出所有已注册的能力
fn ComponentRegistry::list_capabilities(self) -> Array[String] {
  self.capabilities.keys()
}

///| 设置自定义配置
fn ComponentRegistry::set_setting(self, key: String, value: String) -> Unit {
  self.custom_settings.set(key, value)
}

///| 获取自定义配置
fn ComponentRegistry::get_setting(self, key: String) -> Option[String] {
  self.custom_settings.get(key)
}
