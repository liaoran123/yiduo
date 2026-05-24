/// 一多 OS 组件加载器（高性能版本）
/// 支持：Native / Wasm / MoonBit 三种组件类型

/// 组件类型
enum ComponentType {
  WasmComponent
  NativeComponent
  MoonBitComponent
}

/// 组件实例
struct ComponentInstance {
  name: String
  component_type: ComponentType
  path: String
  loaded: Bool
  version: String
}

/// 组件加载器
struct ComponentLoader {
  registered: List[ComponentInstance]
  search_paths: List[String]
}

/// 创建组件加载器
fn create() -> ComponentLoader {
  ComponentLoader::{
    registered: [],
    search_paths: ["./components/", "/flash/components/"]
  }
}

/// 发现可用组件
fn discover(self: ComponentLoader, path: String) -> List[String] {
  println("[Loader] 搜索路径: " + path)
  ["hello_world", "logger", "display"]
}

/// 加载组件
fn load(self: ComponentLoader, name: String, comp_type: ComponentType, path: String) -> Result[ComponentInstance, String] {
  let type_name = match comp_type {
    WasmComponent => "Wasm"
    NativeComponent => "Native"
    MoonBitComponent => "MoonBit"
  }
  println("[Loader] 加载 " + type_name + " 组件: " + name)
  Ok(ComponentInstance::{
    name: name,
    component_type: comp_type,
    path: path,
    loaded: true,
    version: "1.0.0"
  })
}

/// 根据配置信息加载组件
fn load_from_config(self: ComponentLoader, name: String, type_name: String, path: String) -> Result[ComponentInstance, String] {
  let comp_type = match type_name {
    "wasm" => WasmComponent
    "native" => NativeComponent
    "moonbit" => MoonBitComponent
    _ => WasmComponent
  }
  self.load(name, comp_type, path)
}

/// 卸载组件
fn unload(self: ComponentLoader, name: String) -> ComponentLoader {
  println("[Loader] 卸载组件: " + name)
  let mut new_list: List[ComponentInstance] = []
  for inst in self.registered {
    if inst.name != name {
      new_list = inst :: new_list
    }
  }
  ComponentLoader::{registered: new_list, search_paths: self.search_paths}
}

/// 获取已加载组件列表
fn loaded_list(self: ComponentLoader) -> List[String] {
  let mut names: List[String] = []
  for inst in self.registered {
    names = inst.name :: names
  }
  names
}