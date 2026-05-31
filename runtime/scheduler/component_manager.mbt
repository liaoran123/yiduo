/// 🧬 一多 OS 组件管理器
/// 功能：组件注册/查找、Int ID动态分配、基础生命周期管理、内存优先级管理
/// 优化：支持批量注册、快速查找、组件状态追踪
/// 优先级2：组件优先级标记

///|
/// ==================== 组件状态常量 ====================
const COMP_STATE_CREATED : Int = 0

///|
const COMP_STATE_INITIALIZED : Int = 1

///|
const COMP_STATE_RUNNING : Int = 2

///|
const COMP_STATE_PAUSED : Int = 3

///|
const COMP_STATE_STOPPED : Int = 4

///|
const COMP_STATE_FAILED : Int = 5

///|
/// ==================== 本地组件数据 ====================
struct ComponentData {
  id : Int
  state : Int
  config : @component.ComponentConfig
  handle : Int
}

///|
/// ==================== 组件管理器 ====================
struct ComponentManager {
  max_components : Int
  component_table : FixedArray[ComponentData?]
  id_allocator : Int
  free_stack : FixedArray[Int]
  free_top : Int
  active_count : Int
}

///|
/// ==================== 创建组件管理器 ====================
fn ComponentManager::create(max_components : Int) -> ComponentManager {
  let dummy_inst : ComponentData? = None
  ComponentManager::{
    max_components,
    component_table: FixedArray::make(max_components, dummy_inst),
    id_allocator: 1,
    free_stack: FixedArray::make(max_components, 0),
    free_top: 0,
    active_count: 0,
  }
}

///|
/// ==================== 分配组件 ID ====================
fn ComponentManager::allocate_id(
  self : ComponentManager,
) -> (ComponentManager, Int) {
  if self.free_top > 0 {
    let new_top = self.free_top - 1
    let id = self.free_stack[new_top]
    let new_self = ComponentManager::{
      max_components: self.max_components,
      component_table: self.component_table,
      id_allocator: self.id_allocator,
      free_stack: self.free_stack,
      free_top: new_top,
      active_count: self.active_count,
    }
    (new_self, id)
  } else if self.id_allocator < self.max_components {
    let new_id = self.id_allocator
    let new_self = ComponentManager::{
      max_components: self.max_components,
      component_table: self.component_table,
      id_allocator: self.id_allocator + 1,
      free_stack: self.free_stack,
      free_top: self.free_top,
      active_count: self.active_count,
    }
    (new_self, new_id)
  } else {
    (self, -1)
  }
}

///|
/// ==================== 注册组件 ====================
fn ComponentManager::register_component(
  self : ComponentManager,
  config : @component.ComponentConfig,
) -> (ComponentManager, Int) {
  let (new_self1, id) = self.allocate_id()
  if id == -1 {
    return (self, -1)
  }

  let instance = ComponentData::{
    id,
    state: COMP_STATE_CREATED,
    config,
    handle: 0,
  }

  let new_table = new_self1.component_table
  new_table[id] = Some(instance)

  let new_self2 = ComponentManager::{
    max_components: new_self1.max_components,
    component_table: new_table,
    id_allocator: new_self1.id_allocator,
    free_stack: new_self1.free_stack,
    free_top: new_self1.free_top,
    active_count: new_self1.active_count + 1,
  }

  let priority_str = match config.memory_priority {
    @component.MemoryPriority::Critical => "Critical"
    @component.MemoryPriority::Normal => "Normal"
    @component.MemoryPriority::Low => "Low"
  }

  println(
    "[Component-Manager] 注册成功: " +
    config.name +
    " [ID:" +
    id.to_string() +
    " 优先级:" +
    priority_str +
    "]",
  )
  (new_self2, id)
}

///|
/// ==================== 处理内存压力（框架） ====================
pub fn ComponentManager::handle_memory_pressure(
  self : ComponentManager,
) -> ComponentManager {
  let mut new_manager = self
  let mut i = 0

  println(
    "[Component-Manager] 检测到内存压力，尝试回收 Low 优先级组件...",
  )

  while i < self.max_components {
    match self.component_table[i] {
      Some(instance) => {
        let is_low = match instance.config.memory_priority {
          @component.MemoryPriority::Low => true
          _ => false
        }
        if is_low {
          println(
            "[Component-Manager] 通知组件保存状态: " +
            instance.config.name +
            " [ID:" +
            i.to_string() +
            "]",
          )

          let (mgr, _) = new_manager.release_component(i)
          new_manager = mgr
        }
      }
      None => ()
    }
    i = i + 1
  }

  new_manager
}

///|
/// ==================== 批量注册组件 ====================
fn ComponentManager::register_batch(
  self : ComponentManager,
  configs : FixedArray[@component.ComponentConfig],
  count : Int,
) -> (ComponentManager, FixedArray[(String, Int)], Int) {
  let mut cm = self
  let results_arr : FixedArray[(String, Int)] = FixedArray::make(count, ("", 0))
  let mut result_count = 0
  let mut i = 0

  while i < count {
    let config = configs[i]
    let (new_cm, id) = cm.register_component(config)
    cm = new_cm
    if id != -1 {
      results_arr[result_count] = (config.name, id)
      result_count = result_count + 1
    }
    i = i + 1
  }

  (cm, results_arr, result_count)
}

///|
/// ==================== 查找组件 ====================
fn ComponentManager::find_component(
  self : ComponentManager,
  id : Int,
) -> ComponentData? {
  if id >= 0 && id < self.max_components {
    self.component_table[id]
  } else {
    None
  }
}

///|
/// ==================== 按名称查找组件 ====================
fn ComponentManager::find_by_name(
  self : ComponentManager,
  name : String,
) -> Int? {
  let mut i = 0
  while i < self.max_components {
    match self.component_table[i] {
      Some(inst) => if inst.config.name == name { return Some(i) }
      None => ()
    }
    i = i + 1
  }
  None
}

///|
/// ==================== 释放组件 ====================
fn ComponentManager::release_component(
  self : ComponentManager,
  id : Int,
) -> (ComponentManager, Bool) {
  if id <= 0 || id >= self.max_components {
    return (self, false)
  }

  match self.component_table[id] {
    Some(_) => {
      let new_table = self.component_table
      new_table[id] = None

      let new_top = self.free_top
      let new_stack = self.free_stack
      new_stack[new_top] = id

      let new_self = ComponentManager::{
        max_components: self.max_components,
        component_table: new_table,
        id_allocator: self.id_allocator,
        free_stack: new_stack,
        free_top: new_top + 1,
        active_count: self.active_count - 1,
      }

      println("[Component-Manager] 释放组件 ID:" + id.to_string())
      (new_self, true)
    }
    None => (self, false)
  }
}

///|
/// ==================== 更新组件状态 ====================
fn ComponentManager::update_state(
  self : ComponentManager,
  id : Int,
  new_state : Int,
) -> (ComponentManager, Bool) {
  if id < 0 || id >= self.max_components {
    return (self, false)
  }

  match self.component_table[id] {
    Some(inst) => {
      let new_inst = ComponentData::{
        id: inst.id,
        state: new_state,
        config: inst.config,
        handle: inst.handle,
      }

      let new_table = self.component_table
      new_table[id] = Some(new_inst)

      let new_self = ComponentManager::{
        max_components: self.max_components,
        component_table: new_table,
        id_allocator: self.id_allocator,
        free_stack: self.free_stack,
        free_top: self.free_top,
        active_count: self.active_count,
      }

      println(
        "[Component-Manager] 状态更新: ID " +
        id.to_string() +
        " -> " +
        state_str(new_state),
      )
      (new_self, true)
    }
    None => (self, false)
  }
}

///|
/// ==================== 转换为调度器的 ComponentInfo ====================
fn to_component_info(instance : ComponentData) -> ComponentInfo {
  let status = match instance.state {
    COMP_STATE_CREATED => ComponentStatus::Created
    COMP_STATE_INITIALIZED => ComponentStatus::Initialized
    COMP_STATE_RUNNING => ComponentStatus::Running
    COMP_STATE_PAUSED => ComponentStatus::Paused
    COMP_STATE_STOPPED => ComponentStatus::Stopped
    _ => ComponentStatus::Error
  }

  ComponentInfo::{
    name: instance.config.name,
    component_type: instance.config.component_type,
    status,
    last_comm_with: FixedArray::make(16, -1),
    last_comm_count: FixedArray::make(16, 0),
  }
}

///|
/// ==================== 获取调度器需要的组件表 ====================
fn ComponentManager::get_scheduler_table(
  self : ComponentManager,
) -> FixedArray[ComponentInfo?] {
  let dummy_info : ComponentInfo? = None
  let result = FixedArray::make(self.max_components, dummy_info)
  let mut i = 0
  while i < self.max_components {
    match self.component_table[i] {
      Some(inst) => result[i] = Some(to_component_info(inst))
      None => result[i] = None
    }
    i = i + 1
  }
  result
}

///|
/// ==================== 获取统计信息 ====================
fn ComponentManager::get_stats(self : ComponentManager) -> (Int, Int, Int) {
  (
    self.active_count,
    self.free_top,
    self.max_components - self.id_allocator + 1,
  )
}

///|
/// ==================== 打印管理器状态 ====================
fn ComponentManager::print_status(self : ComponentManager) -> Unit {
  println("")
  println(
    "══════════════════════════════════════════════",
  )
  println("║   一多 OS 组件管理器状态   ║")
  println(
    "══════════════════════════════════════════════",
  )
  let (active, free_reuse, available_new) = self.get_stats()
  println("活跃组件: " + active.to_string())
  println("可复用ID: " + free_reuse.to_string())
  println("新ID可用: " + available_new.to_string())
  println("最大容量: " + self.max_components.to_string())
  println("")
  println("组件列表:")
  let mut i = 0
  while i < self.max_components {
    match self.component_table[i] {
      Some(inst) =>
        println(
          "  ID " +
          i.to_string() +
          ": " +
          inst.config.name +
          " [" +
          inst.config.component_type.to_string() +
          "] " +
          state_str(inst.state),
        )
      None => ()
    }
    i = i + 1
  }
  println("")
}

///|
/// ==================== 状态字符串转换 ====================
fn state_str(state : Int) -> String {
  match state {
    COMP_STATE_CREATED => "已创建"
    COMP_STATE_INITIALIZED => "已初始化"
    COMP_STATE_RUNNING => "运行中"
    COMP_STATE_PAUSED => "已暂停"
    COMP_STATE_STOPPED => "已停止"
    _ => "失败"
  }
}
