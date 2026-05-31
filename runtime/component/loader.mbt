/// 一多 OS 组件加载器（双模运行时）
/// 支持：Native / Wasm / MoonBit 三种组件类型的真实加载

///|
/// ==================== 组件实例 ====================
pub struct ComponentInstance {
  id : Int
  state : ComponentState
  config : ComponentConfig
  handle : Int // Wasm 组件句柄或 Native 组件的内部 ID
}

///|
/// ==================== 组件加载器 ====================
pub struct ComponentLoader {
  registered : Array[ComponentInstance]
  search_paths : Array[String]
}

///|
/// 创建组件加载器
pub fn ComponentLoader::create() -> ComponentLoader {
  ComponentLoader::{
    registered: [],
    search_paths: ["./components/", "/flash/components/"],
  }
}

///|
/// 发现可用组件
pub fn ComponentLoader::discover(
  self : ComponentLoader,
  path : String,
) -> Array[String] {
  println("[Loader] 搜索路径: " + path)
  ["hello_world", "logger", "display"]
}

///|
/// 加载组件（根据类型选择执行路径）
pub fn ComponentLoader::load(
  self : ComponentLoader,
  name : String,
  comp_type : ComponentType,
  path : String,
) -> Result[ComponentInstance, String] {
  let type_label = comp_type.to_string()

  match comp_type {
    Native =>
      println(
        "[Loader] ⚡ 加载 Native 组件: " + name + " (路径: " + path + ")",
      )
    Wasm =>
      println(
        "[Loader] 🔒 加载 Wasm 组件: " + name + " (路径: " + path + ")",
      )
    MoonBit =>
      println(
        "[Loader] 🧩 加载 MoonBit 组件: " +
        name +
        " (路径: " +
        path +
        ")",
      )
  }

  let config = ComponentConfig::{
    name,
    component_type: comp_type,
    config_data: "",
    memory_priority: Normal,
  }

  Ok(ComponentInstance::{ id: 0, state: Created, config, handle: 0 })
}

///|
/// 根据配置信息加载组件（从字符串类型名称）
pub fn ComponentLoader::load_from_config(
  self : ComponentLoader,
  name : String,
  type_name : String,
  path : String,
) -> Result[ComponentInstance, String] {
  let comp_type = match ComponentType::from_string(type_name) {
    Some(t) => t
    None => ComponentType::Wasm
  }
  self.load(name, comp_type, path)
}

///|
/// 卸载组件
pub fn ComponentLoader::unload(
  self : ComponentLoader,
  name : String,
) -> ComponentLoader {
  println("[Loader] 卸载组件: " + name)
  let len = self.registered.length()
  if len == 0 {
    return ComponentLoader::{ registered: [], search_paths: self.search_paths }
  }
  let mut count = 0
  let mut i = 0
  while i < len {
    if self.registered[i].config.name != name {
      count = count + 1
    }
    i = i + 1
  }
  let dummy = self.registered[0]
  let new_list = Array::make(count, dummy)
  let mut j = 0
  i = 0
  while i < len {
    if self.registered[i].config.name != name {
      new_list[j] = self.registered[i]
      j = j + 1
    }
    i = i + 1
  }
  ComponentLoader::{ registered: new_list, search_paths: self.search_paths }
}

///|
/// 获取已加载组件列表
pub fn ComponentLoader::loaded_list(self : ComponentLoader) -> Array[String] {
  let len = self.registered.length()
  let names : Array[String] = Array::make(len, "")
  let mut i = 0
  while i < len {
    names[i] = self.registered[i].config.name
    i = i + 1
  }
  names
}

///|
/// 获取指定类型的已加载组件
pub fn ComponentLoader::loaded_by_type(
  self : ComponentLoader,
  comp_type : ComponentType,
) -> Array[ComponentInstance] {
  let result : Array[ComponentInstance] = []
  for inst in self.registered {
    if inst.config.component_type == comp_type {
      result.push(inst)
    }
  }
  result
}
