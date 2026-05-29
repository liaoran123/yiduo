/// 🧬 一多 OS 组件管理器
/// 功能：组件注册/查找、Int ID动态分配、基础生命周期管理
/// 优化：支持批量注册、快速查找、组件状态追踪

use @component.ComponentConfig
use @component.ComponentInstance
use @component.ComponentState
use @scheduler.Scheduler
use @scheduler.ComponentInfo
use @scheduler.ComponentStatus

/// ==================== 组件管理器 ====================
struct ComponentManager {
  max_components: Int,
  component_table: FixedArray[Option[ComponentInstance]],
  id_allocator: Int, // 下一个可用的 ID
  free_ids: List[Int], // 可复用的 ID 列表
  active_count: Int,
}

/// ==================== 创建组件管理器 ====================
fn create(max_components: Int) -> ComponentManager {
  let dummy_inst: Option[ComponentInstance] = None
  ComponentManager{
    max_components: max_components,
    component_table: FixedArray::make(max_components, dummy_inst),
    id_allocator: 1, // 0 保留给调度核心
    free_ids: [],
    active_count: 0,
  }
}

/// ==================== 分配组件 ID ====================
/// 优先复用已释放的 ID，没有则分配新 ID
fn allocate_id(self: ComponentManager) -> (ComponentManager, Int) {
  if !self.free_ids.is_empty() {
    let id = self.free_ids.head()
    let new_free = self.free_ids.tail()
    let new_self = ComponentManager{
      max_components: self.max_components,
      component_table: self.component_table,
      id_allocator: self.id_allocator,
      free_ids: new_free,
      active_count: self.active_count,
    }
    (new_self, id)
  } else if self.id_allocator < self.max_components {
    let new_id = self.id_allocator
    let new_self = ComponentManager{
      max_components: self.max_components,
      component_table: self.component_table,
      id_allocator: self.id_allocator + 1,
      free_ids: self.free_ids,
      active_count: self.active_count,
    }
    (new_self, new_id)
  } else {
    (self, -1) // 没有可用 ID
  }
}

/// ==================== 注册组件 ====================
fn register_component(self: ComponentManager, config: ComponentConfig) -> (ComponentManager, Int) {
  let (new_self1, id) = self.allocate_id()
  if id == -1 {
    return (self, -1)
  }
  
  let instance = ComponentInstance{
    id: id,
    state: ComponentState.Created,
    config: config,
    handle: 0, // 初始句柄
  }
  
  let mut new_table = new_self1.component_table
  new_table[id] = Some(instance)
  
  let new_self2 = ComponentManager{
    max_components: new_self1.max_components,
    component_table: new_table,
    id_allocator: new_self1.id_allocator,
    free_ids: new_self1.free_ids,
    active_count: new_self1.active_count + 1,
  }
  
  println("[Component-Manager] ✅ 注册成功: " + config.name + " [ID:" + id.to_string() + "]")
  (new_self2, id)
}

/// ==================== 批量注册组件 ====================
fn register_batch(self: ComponentManager, configs: List[ComponentConfig]) -> (ComponentManager, List[(String, Int)]) {
  let mut cm = self
  let mut results: List[(String, Int)] = []
  let mut cfgs = configs
  
  while !cfgs.is_empty() {
    let config = cfgs.head()
    let (new_cm, id) = cm.register_component(config)
    cm = new_cm
    if id != -1 {
      results = (config.name, id) :: results
    }
    cfgs = cfgs.tail()
  }
  
  (cm, results.reverse())
}

/// ==================== 查找组件 ====================
fn find_component(self: ComponentManager, id: Int) -> Option[ComponentInstance] {
  if id >= 0 && id < self.max_components {
    self.component_table[id]
  } else {
    None
  }
}

/// ==================== 按名称查找组件 ====================
fn find_by_name(self: ComponentManager, name: String) -> Option[Int] {
  let mut i = 0
  while i < self.max_components {
    match self.component_table[i] {
      Some(inst) => {
        if inst.config.name == name {
          return Some(i)
        }
      }
      None => ()
    }
    i = i + 1
  }
  None
}

/// ==================== 释放组件 ====================
fn release_component(self: ComponentManager, id: Int) -> (ComponentManager, Bool) {
  if id <= 0 || id >= self.max_components {
    return (self, false)
  }
  
  match self.component_table[id] {
    Some(_) => {
      let mut new_table = self.component_table
      new_table[id] = None
      
      let new_self = ComponentManager{
        max_components: self.max_components,
        component_table: new_table,
        id_allocator: self.id_allocator,
        free_ids: id :: self.free_ids, // 添加到可复用列表
        active_count: self.active_count - 1,
      }
      
      println("[Component-Manager] 🗑️  释放组件 ID:" + id.to_string())
      (new_self, true)
    }
    None => (self, false)
  }
}

/// ==================== 更新组件状态 ====================
fn update_state(self: ComponentManager, id: Int, new_state: ComponentState) -> (ComponentManager, Bool) {
  if id < 0 || id >= self.max_components {
    return (self, false)
  }
  
  match self.component_table[id] {
    Some(inst) => {
      let new_inst = ComponentInstance{
        id: inst.id,
        state: new_state,
        config: inst.config,
        handle: inst.handle,
      }
      
      let mut new_table = self.component_table
      new_table[id] = Some(new_inst)
      
      let new_self = ComponentManager{
        max_components: self.max_components,
        component_table: new_table,
        id_allocator: self.id_allocator,
        free_ids: self.free_ids,
        active_count: self.active_count,
      }
      
      println("[Component-Manager] 🔄 状态更新: ID " + id.to_string() + " → " + state_str(new_state))
      (new_self, true)
    }
    None => (self, false)
  }
}

/// ==================== 转换为调度器的 ComponentInfo ====================
fn to_component_info(instance: ComponentInstance) -> ComponentInfo {
  let status = match instance.state {
    ComponentState.Created => ComponentStatus.Created
    ComponentState.Initialized => ComponentStatus.Initialized
    ComponentState.Running => ComponentStatus.Running
    ComponentState.Paused => ComponentStatus.Paused
    ComponentState.Stopped => ComponentStatus.Stopped
    ComponentState.Failed => ComponentStatus.Error
  }
  
  ComponentInfo{
    name: instance.config.name,
    component_type: instance.config.component_type,
    status: status,
  }
}

/// ==================== 获取调度器需要的组件表 ====================
fn get_scheduler_table(self: ComponentManager) -> FixedArray[Option[ComponentInfo]] {
  let mut result = self.component_table
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

/// ==================== 获取统计信息 ====================
fn get_stats(self: ComponentManager) -> (Int, Int, Int) {
  (self.active_count, self.free_ids.length(), self.max_components - self.id_allocator + 1)
}

/// ==================== 打印管理器状态 ====================
fn print_status(self: ComponentManager) {
  println("")
  println("══════════════════════════════════════════════")
  println("║   一多 OS 组件管理器状态   ║")
  println("══════════════════════════════════════════════")
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
      Some(inst) => {
        println("  ID " + i.to_string() + ": " + inst.config.name + 
               " [" + inst.config.component_type + "] " + state_str(inst.state))
      }
      None => ()
    }
    i = i + 1
  }
  println("")
}

/// ==================== 状态字符串转换 ====================
fn state_str(state: ComponentState) -> String {
  match state {
    ComponentState.Created => "已创建"
    ComponentState.Initialized => "已初始化"
    ComponentState.Running => "运行中"
    ComponentState.Paused => "已暂停"
    ComponentState.Stopped => "已停止"
    ComponentState.Failed => "失败"
  }
}
