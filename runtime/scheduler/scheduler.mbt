/// 一多 OS 高性能可编程调度系统（优化版 V2）
/// 优化：Int ID 替代 String，FixedArray 替代 Map，哈希查找→索引访问
/// 优化：集成 MemoryManager（句柄安全），组件亲和度调度，批处理
/// 双模运行时：Native 组件经由 HandlerRegistry 直接调用，Wasm 组件经由 WasmRuntime 抽象接口执行

///|
/// ==================== 系统契约常量 ====================
/// 调度核心的固定 ID（系统契约）
pub const SCHEDULER_CORE_ID : Int = 0

///|
/// 调度核心的组件类型标识
pub fn component_type_native_core() -> @component.ComponentType {
  @component.ComponentType::native()
}

///|
/// 组件状态
pub enum ComponentStatus {
  Created
  Initialized
  Running
  Paused
  Stopped
  Error
}

///|
/// 组件信息（优化：Int ID 替代 String，添加亲和度追踪）
/// component_type 使用 @component.ComponentType（Native/Wasm/MoonBit）
pub struct ComponentInfo {
  name : String
  component_type : @component.ComponentType
  status : ComponentStatus
  last_comm_with : FixedArray[Int]
  last_comm_count : FixedArray[Int]
}

///|
pub fn ComponentInfo::create(
  name : String,
  component_type : @component.ComponentType,
  status : ComponentStatus,
  last_comm_with : FixedArray[Int],
  last_comm_count : FixedArray[Int],
) -> ComponentInfo {
  ComponentInfo::{
    name,
    component_type,
    status,
    last_comm_with,
    last_comm_count,
  }
}

///|
pub fn ComponentInfo::create_simple(
  name : String,
  component_type : @component.ComponentType,
  status : ComponentStatus,
) -> ComponentInfo {
  ComponentInfo::create(
    name,
    component_type,
    status,
    FixedArray::make(16, -1),
    FixedArray::make(16, 0),
  )
}

///|
pub fn ComponentStatus::created() -> ComponentStatus {
  Created
}

///|
pub fn ComponentStatus::initialized() -> ComponentStatus {
  Initialized
}

///|
pub fn ComponentStatus::running() -> ComponentStatus {
  Running
}

///|
pub fn ComponentStatus::paused() -> ComponentStatus {
  Paused
}

///|
pub fn ComponentStatus::stopped() -> ComponentStatus {
  Stopped
}

///|
pub fn ComponentStatus::error() -> ComponentStatus {
  Error
}

///|
/// 调度器（优化版 V2，双模运行时）
/// handlers 字段管理 Native 组件的消息处理器注册表
pub struct Scheduler {
  high_queue : @core.RingBuffer[@core.Message]
  normal_queue : @core.RingBuffer[@core.Message]
  low_queue : @core.RingBuffer[@core.Message]
  pool : @core.MemoryPool
  mem_manager : @core.MemoryManager
  components : FixedArray[ComponentInfo?]
  max_components : Int
  is_running : Bool
  batch_size : Int
  debug_log : Bool
  handlers : HandlerRegistry
  wasm_runtime : @component.WasmRuntime?
}

///|
/// 创建调度器（V2：接受 MemoryManager 和批处理大小）
pub fn Scheduler::create_with_config(
  mem_manager : @core.MemoryManager,
  batch_size : Int,
  max_components : Int,
) -> Scheduler {
  let dummy_msg = @core.Message::create_small(
    0,
    0,
    @core.SmallPayload::create(0, []),
  )

  let dummy_comp : ComponentInfo? = None

  Scheduler::{
    high_queue: @core.RingBuffer::create(65, dummy_msg),
    normal_queue: @core.RingBuffer::create(257, dummy_msg),
    low_queue: @core.RingBuffer::create(129, dummy_msg),
    pool: @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64)),
    mem_manager,
    components: FixedArray::make(max_components, dummy_comp),
    max_components,
    is_running: false,
    batch_size,
    debug_log: true,
    handlers: HandlerRegistry::create(max_components),
    wasm_runtime: None,
  }
}

///|
/// 创建调度器（V1 兼容版本）
pub fn Scheduler::create() -> Scheduler {
  let dummy_pool_config = @core.MemoryPoolConfig::create(4096, 64)
  let dummy_pool = @core.MemoryPool::create(dummy_pool_config)
  let default_mgr = @core.MemoryManager::create(dummy_pool, 64)
  Scheduler::create_with_config(default_mgr, 8, 32)
}

///|
/// 注册组件（返回 Int ID，由分配器分配，V2：初始化亲和度追踪）
pub fn Scheduler::register(
  self : Scheduler,
  info : ComponentInfo,
) -> (Scheduler, Int) {
  let new_info = ComponentInfo::{
    name: info.name,
    component_type: info.component_type,
    status: info.status,
    last_comm_with: FixedArray::make(16, -1),
    last_comm_count: FixedArray::make(16, 0),
  }

  let new_comps = self.components
  let mut assigned_id = -1
  let mut i = 1 // 从 1 开始，保留 ID 0 给调度核心
  while i < self.max_components {
    match new_comps[i] {
      None => {
        new_comps[i] = Some(new_info)
        assigned_id = i
        i = self.max_components
      }
      Some(_) => i = i + 1
    }
  }
  let new_scheduler = Scheduler::{
    high_queue: self.high_queue,
    normal_queue: self.normal_queue,
    low_queue: self.low_queue,
    pool: self.pool,
    mem_manager: self.mem_manager,
    components: new_comps,
    max_components: self.max_components,
    is_running: self.is_running,
    batch_size: self.batch_size,
    handlers: self.handlers,
    wasm_runtime: self.wasm_runtime,
    debug_log: self.debug_log,
  }
  (new_scheduler, assigned_id)
}

///|
/// 注册 Native 组件处理器（双模运行时便利方法）
pub fn Scheduler::register_handler(
  self : Scheduler,
  comp_id : Int,
  handler : @component.NativeMessageHandler,
) -> Scheduler {
  Scheduler::{
    high_queue: self.high_queue,
    normal_queue: self.normal_queue,
    low_queue: self.low_queue,
    pool: self.pool,
    mem_manager: self.mem_manager,
    components: self.components,
    max_components: self.max_components,
    is_running: self.is_running,
    batch_size: self.batch_size,
    handlers: self.handlers.register_handler(comp_id, handler),
    wasm_runtime: self.wasm_runtime,
    debug_log: self.debug_log,
  }
}

///|
/// 注册 Wasm 组件处理器（委托给 WasmRuntime）
pub fn Scheduler::register_wasm_handler(
  self : Scheduler,
  comp_id : Int,
  handler : @component.NativeMessageHandler,
) -> Scheduler {
  match self.wasm_runtime {
    Some(rt) => {
      (rt.register)(comp_id, handler)
      self
    }
    None => {
      if self.debug_log {
        println(
          "[Scheduler] ⚠ Wasm 运行时未设置，忽略处理器注册",
        )
      }
      self
    }
  }
}

///|
/// 加载 Wasm 组件二进制字节码（L2 WAMR 模式）
/// 委托给 WasmRuntime.load，在运行时中实例化 Wasm 模块
pub fn Scheduler::load_wasm(
  self : Scheduler,
  comp_id : Int,
  wasm_bytes : Bytes,
) -> (Scheduler, Result[Unit, String]) {
  match self.wasm_runtime {
    Some(rt) => {
      let result = (rt.load)(comp_id, wasm_bytes)
      (self, result)
    }
    None => (self, Err("Wasm 运行时未设置"))
  }
}

///|
/// 发送小消息（V2：更新亲和度追踪）
pub fn Scheduler::send_small(
  self : Scheduler,
  from : Int,
  to : Int,
  payload : @core.SmallPayload,
  priority : @core.MessagePriority,
) -> (Scheduler, Bool) {
  let msg = @core.Message::create_small(from, to, payload)
  let s1 = self.update_affinity(from, to)
  s1.send_to_queue(msg, priority)
}

///|
/// 发送中消息（句柄模式，V2：使用 MemoryManager，更新亲和度）
fn Scheduler::send_medium(
  self : Scheduler,
  from : Int,
  to : Int,
  handle : Int,
  priority : @core.MessagePriority,
) -> (Scheduler, Bool) {
  let (new_mgr, ok_retain) = self.mem_manager.retain_handle(handle, from)
  if !ok_retain {
    println("[Scheduler] ⚠ 句柄保留失败: " + handle.to_string())
    return (self, false)
  }

  let msg = @core.Message::medium(from, to, handle, false)

  let s1 = self.update_affinity(from, to)
  let s2 = Scheduler::{
    high_queue: s1.high_queue,
    normal_queue: s1.normal_queue,
    low_queue: s1.low_queue,
    pool: s1.pool,
    mem_manager: new_mgr,
    components: s1.components,
    max_components: s1.max_components,
    is_running: s1.is_running,
    batch_size: s1.batch_size,
    handlers: s1.handlers,
    wasm_runtime: s1.wasm_runtime,
    debug_log: s1.debug_log,
  }
  s2.send_to_queue(msg, priority)
}

///|
/// 发送大消息（共享内存模式，V2：使用 MemoryManager，更新亲和度）
fn Scheduler::send_large(
  self : Scheduler,
  from : Int,
  to : Int,
  handle : Int,
  access_mode : @core.AccessMode,
  priority : @core.MessagePriority,
) -> (Scheduler, Bool) {
  let (new_mgr, ok_retain) = self.mem_manager.retain_handle(handle, from)
  if !ok_retain {
    println("[Scheduler] ⚠ 句柄保留失败: " + handle.to_string())
    return (self, false)
  }

  let msg = @core.Message::large(from, to, handle, access_mode, false)

  let s1 = self.update_affinity(from, to)
  let s2 = Scheduler::{
    high_queue: s1.high_queue,
    normal_queue: s1.normal_queue,
    low_queue: s1.low_queue,
    pool: s1.pool,
    mem_manager: new_mgr,
    components: s1.components,
    max_components: s1.max_components,
    is_running: s1.is_running,
    batch_size: s1.batch_size,
    handlers: s1.handlers,
    wasm_runtime: s1.wasm_runtime,
    debug_log: s1.debug_log,
  }
  s2.send_to_queue(msg, priority)
}

///|
/// 更新组件亲和度追踪（新增）
fn Scheduler::update_affinity(
  self : Scheduler,
  from_id : Int,
  to_id : Int,
) -> Scheduler {
  if from_id < 0 ||
    from_id >= self.max_components ||
    to_id < 0 ||
    to_id >= self.max_components {
    return self
  }

  let new_comps = self.components
  match new_comps[from_id] {
    Some(comp) => {
      let mut found_idx = -1
      let mut i = 0
      while i < 16 {
        if comp.last_comm_with[i] == to_id {
          found_idx = i
          break
        }
        i = i + 1
      }

      if found_idx >= 0 {
        comp.last_comm_count[found_idx] = comp.last_comm_count[found_idx] + 1
        new_comps[from_id] = Some(comp)
      } else {
        let mut empty_idx = -1
        let mut min_idx = 0
        let mut min_count = comp.last_comm_count[0]

        let mut j = 0
        while j < 16 {
          if comp.last_comm_with[j] == -1 {
            empty_idx = j
            break
          }
          if comp.last_comm_count[j] < min_count {
            min_count = comp.last_comm_count[j]
            min_idx = j
          }
          j = j + 1
        }

        let insert_idx = if empty_idx >= 0 { empty_idx } else { min_idx }
        comp.last_comm_with[insert_idx] = to_id
        comp.last_comm_count[insert_idx] = 1
        new_comps[from_id] = Some(comp)
      }
    }
    None => ()
  }

  Scheduler::{
    high_queue: self.high_queue,
    normal_queue: self.normal_queue,
    low_queue: self.low_queue,
    pool: self.pool,
    mem_manager: self.mem_manager,
    components: new_comps,
    max_components: self.max_components,
    is_running: self.is_running,
    batch_size: self.batch_size,
    handlers: self.handlers,
    wasm_runtime: self.wasm_runtime,
    debug_log: self.debug_log,
  }
}

///|
/// 发送消息到对应优先级队列（V2：传递所有新字段）
fn Scheduler::send_to_queue(
  self : Scheduler,
  msg : @core.Message,
  priority : @core.MessagePriority,
) -> (Scheduler, Bool) {
  match priority {
    @core.MessagePriority::High => {
      let (q, ok) = @core.RingBuffer::enqueue(self.high_queue, msg)
      (
        Scheduler::{
          high_queue: q,
          normal_queue: self.normal_queue,
          low_queue: self.low_queue,
          pool: self.pool,
          mem_manager: self.mem_manager,
          components: self.components,
          max_components: self.max_components,
          is_running: self.is_running,
          batch_size: self.batch_size,
          handlers: self.handlers,
          wasm_runtime: self.wasm_runtime,
          debug_log: self.debug_log,
        },
        ok,
      )
    }
    @core.MessagePriority::Normal => {
      let (q, ok) = @core.RingBuffer::enqueue(self.normal_queue, msg)
      (
        Scheduler::{
          high_queue: self.high_queue,
          normal_queue: q,
          low_queue: self.low_queue,
          pool: self.pool,
          mem_manager: self.mem_manager,
          components: self.components,
          max_components: self.max_components,
          is_running: self.is_running,
          batch_size: self.batch_size,
          handlers: self.handlers,
          wasm_runtime: self.wasm_runtime,
          debug_log: self.debug_log,
        },
        ok,
      )
    }
    @core.MessagePriority::Low => {
      let (q, ok) = @core.RingBuffer::enqueue(self.low_queue, msg)
      (
        Scheduler::{
          high_queue: self.high_queue,
          normal_queue: self.normal_queue,
          low_queue: q,
          pool: self.pool,
          mem_manager: self.mem_manager,
          components: self.components,
          max_components: self.max_components,
          is_running: self.is_running,
          batch_size: self.batch_size,
          handlers: self.handlers,
          wasm_runtime: self.wasm_runtime,
          debug_log: self.debug_log,
        },
        ok,
      )
    }
  }
}

///|
/// 处理一条消息（优先级顺序：高 > 普通 > 低）（V2：支持批处理）
pub fn Scheduler::process_one(self : Scheduler) -> Scheduler {
  let (hq, opt_msg) = @core.RingBuffer::dequeue(self.high_queue)
  let s1 = Scheduler::{
    high_queue: hq,
    normal_queue: self.normal_queue,
    low_queue: self.low_queue,
    pool: self.pool,
    mem_manager: self.mem_manager,
    components: self.components,
    max_components: self.max_components,
    is_running: self.is_running,
    batch_size: self.batch_size,
    handlers: self.handlers,
    wasm_runtime: self.wasm_runtime,
    debug_log: self.debug_log,
  }
  match opt_msg {
    Some(m) => s1.dispatch(m)
    None => {
      let (nq, opt_msg2) = @core.RingBuffer::dequeue(s1.normal_queue)
      let s2 = Scheduler::{
        high_queue: s1.high_queue,
        normal_queue: nq,
        low_queue: s1.low_queue,
        pool: s1.pool,
        mem_manager: s1.mem_manager,
        components: s1.components,
        max_components: s1.max_components,
        is_running: s1.is_running,
        batch_size: s1.batch_size,
        handlers: s1.handlers,
        wasm_runtime: s1.wasm_runtime,
        debug_log: s1.debug_log,
      }
      match opt_msg2 {
        Some(m) => s2.dispatch(m)
        None => {
          let (lq, opt_msg3) = @core.RingBuffer::dequeue(s2.low_queue)
          let s3 = Scheduler::{
            high_queue: s2.high_queue,
            normal_queue: s2.normal_queue,
            low_queue: lq,
            pool: s2.pool,
            mem_manager: s2.mem_manager,
            components: s2.components,
            max_components: s2.max_components,
            is_running: s2.is_running,
            batch_size: s2.batch_size,
            handlers: s2.handlers,
            wasm_runtime: s2.wasm_runtime,
            debug_log: s2.debug_log,
          }
          match opt_msg3 {
            Some(m) => s3.dispatch(m)
            None => s3
          }
        }
      }
    }
  }
}

///|
/// 批处理多条消息（V2：新增）
fn Scheduler::process_batch(self : Scheduler) -> Scheduler {
  let mut s = self
  let mut count = 0
  while count < self.batch_size {
    s = s.process_one()
    count = count + 1
  }
  s
}

///|
/// 分发消息给目标组件（双模运行时）
/// Native 组件：通过 HandlerRegistry 调用已注册的处理器
/// Wasm/MoonBit 组件：预留沙箱执行接口（当前仅日志输出）
fn Scheduler::dispatch(self : Scheduler, msg : @core.Message) -> Scheduler {
  let (to_id, from_id, handle_opt, auto_free) = match msg {
    SmallMessage(from, to, _) => (to, from, None, false)
    MediumMessage(from, to, handle, auto_free) =>
      (to, from, Some(handle), auto_free)
    LargeMessage(from, to, handle, _, auto_free) =>
      (to, from, Some(handle), auto_free)
  }

  if to_id == SCHEDULER_CORE_ID {
    if self.debug_log {
      println("[Scheduler] 收到给自己的消息（核心处理）")
    }
    return self.handle_core_message(msg)
  }

  if to_id >= 0 && to_id < self.max_components {
    match self.components[to_id] {
      Some(comp) => {
        if self.debug_log {
          println(
            "[Scheduler] 分发消息 → " +
            comp.name +
            " (ID:" +
            to_id.to_string() +
            ") [" +
            comp.component_type.to_string() +
            "]",
          )
        }

        // 根据组件类型选择执行路径
        match comp.component_type.to_int() {
          0 => {
            // Native 组件：统一处理句柄和内存
            let (final_mgr, _) = match handle_opt {
              Some(handle) => {
                let (new_mgr, transfer_ok) = self.mem_manager.transfer_ownership(
                  handle, from_id, to_id,
                )
                if !transfer_ok {
                  if self.debug_log {
                    println(
                      "[Scheduler] ⚠ 句柄转移失败: " +
                      handle.to_string(),
                    )
                  }
                  (new_mgr, false)
                } else if auto_free {
                  new_mgr.free_handle(handle, to_id)
                } else {
                  (new_mgr, true)
                }
              }
              None => (self.mem_manager, true)
            }
            // 提取 payload
            let payload = match msg {
              SmallMessage(_, _, p) => p
              _ => @core.SmallPayload::create(0, [])
            }
            // 调用处理器
            let invoked = self.handlers.invoke(to_id, from_id, payload)
            if !invoked && self.debug_log {
              println(
                "[Scheduler] ⚠ Native 组件 " +
                comp.name +
                " 未注册处理器",
              )
            }
            Scheduler::{
              high_queue: self.high_queue,
              normal_queue: self.normal_queue,
              low_queue: self.low_queue,
              pool: self.pool,
              mem_manager: final_mgr,
              components: self.components,
              max_components: self.max_components,
              is_running: self.is_running,
              batch_size: self.batch_size,
              handlers: self.handlers,
              wasm_runtime: self.wasm_runtime,
              debug_log: self.debug_log,
            }
          }
          1 => {
            // Wasm 组件：统一处理句柄
            let (final_mgr, _) = match handle_opt {
              Some(handle) => {
                let (new_mgr, transfer_ok) = self.mem_manager.transfer_ownership(
                  handle, from_id, to_id,
                )
                if !transfer_ok {
                  (new_mgr, false)
                } else if auto_free {
                  new_mgr.free_handle(handle, to_id)
                } else {
                  (new_mgr, true)
                }
              }
              None => (self.mem_manager, true)
            }
            // 提取 payload
            let payload = match msg {
              SmallMessage(_, _, p) => p
              _ => @core.SmallPayload::create(0, [])
            }
            // 调用 Wasm 模拟处理器
            // 通过 WasmRuntime 调用
            let invoked = match self.wasm_runtime {
              Some(rt) => {
                (rt.invoke)(to_id, from_id, payload)
                true
              }
              None => false
            }
            if !invoked && self.debug_log {
              println(
                "[Scheduler] 🔒 Wasm 组件 " +
                comp.name +
                " 未注册模拟处理器（预留模式）",
              )
            }
            Scheduler::{
              high_queue: self.high_queue,
              normal_queue: self.normal_queue,
              low_queue: self.low_queue,
              pool: self.pool,
              mem_manager: final_mgr,
              components: self.components,
              max_components: self.max_components,
              is_running: self.is_running,
              batch_size: self.batch_size,
              handlers: self.handlers,
              wasm_runtime: self.wasm_runtime,
              debug_log: self.debug_log,
            }
          }
          _ => {
            // MoonBit 组件：预留接口
            if self.debug_log {
              println("[Scheduler] 🧩 MoonBit 组件执行（预留）")
            }
            Scheduler::{
              high_queue: self.high_queue,
              normal_queue: self.normal_queue,
              low_queue: self.low_queue,
              pool: self.pool,
              mem_manager: self.mem_manager,
              components: self.components,
              max_components: self.max_components,
              is_running: self.is_running,
              batch_size: self.batch_size,
              handlers: self.handlers,
              wasm_runtime: self.wasm_runtime,
              debug_log: self.debug_log,
            }
          }
        }
      }
      None => {
        if self.debug_log {
          println("[Scheduler] ⚠ 组件未注册: ID " + to_id.to_string())
        }
        self
      }
    }
  } else {
    if self.debug_log {
      println("[Scheduler] ⚠ 无效组件ID: " + to_id.to_string())
    }
    self
  }
}

///|
/// 运行调度循环（V2：支持批处理模式）
pub fn Scheduler::run_loop(self : Scheduler, max_iter : Int) -> Scheduler {
  let mut s = Scheduler::{
    high_queue: self.high_queue,
    normal_queue: self.normal_queue,
    low_queue: self.low_queue,
    pool: self.pool,
    mem_manager: self.mem_manager,
    components: self.components,
    max_components: self.max_components,
    is_running: true,
    batch_size: self.batch_size,
    handlers: self.handlers,
    wasm_runtime: self.wasm_runtime,
    debug_log: self.debug_log,
  }
  let mut i = 0
  while i < max_iter {
    s = s.process_batch()
    i = i + 1
  }
  Scheduler::{
    high_queue: s.high_queue,
    normal_queue: s.normal_queue,
    low_queue: s.low_queue,
    pool: s.pool,
    mem_manager: s.mem_manager,
    components: s.components,
    max_components: self.max_components,
    is_running: false,
    batch_size: self.batch_size,
    handlers: s.handlers,
    wasm_runtime: s.wasm_runtime,
    debug_log: s.debug_log,
  }
}

///|
/// 获取亲和度最高的组件（新增，用于调度决策）
fn Scheduler::get_affinity_top(self : Scheduler, comp_id : Int) -> Int? {
  if comp_id < 0 || comp_id >= self.max_components {
    return None
  }

  match self.components[comp_id] {
    Some(comp) => find_top_affinity(comp)
    None => None
  }
}

///|
fn find_top_affinity(comp : ComponentInfo) -> Int? {
  let mut max_count = 0
  let mut top_id = -1
  let mut i = 0
  while i < 16 {
    if comp.last_comm_count[i] > max_count && comp.last_comm_with[i] != -1 {
      max_count = comp.last_comm_count[i]
      top_id = comp.last_comm_with[i]
    }
    i = i + 1
  }
  if top_id >= 0 {
    Some(top_id)
  } else {
    None
  }
}

///|
/// 获取组件名称
pub fn Scheduler::component_name(self : Scheduler, id : Int) -> String {
  if id >= 0 && id < self.max_components {
    match self.components[id] {
      Some(comp) => comp.name
      None => "<空>"
    }
  } else {
    "<无效>"
  }
}

///|
/// 按名称查找组件 ID（[热更新] 用）
pub fn Scheduler::find_component_id(self : Scheduler, name : String) -> Int? {
  let mut i = 0
  while i < self.max_components {
    match self.components[i] {
      Some(comp) => if comp.name == name { return Some(i) }
      None => ()
    }
    i = i + 1
  }
  None
}

///|
/// 标记组件为已停止（[热更新] 用）
pub fn Scheduler::mark_component_stopped(
  self : Scheduler,
  id : Int,
) -> Scheduler {
  if id < 0 || id >= self.max_components {
    return self
  }
  let new_comps = self.components
  match new_comps[id] {
    Some(comp) => {
      let stopped = ComponentInfo::{
        name: comp.name,
        component_type: comp.component_type,
        status: ComponentStatus::stopped(),
        last_comm_with: comp.last_comm_with,
        last_comm_count: comp.last_comm_count,
      }
      new_comps[id] = Some(stopped)
      Scheduler::{
        high_queue: self.high_queue,
        normal_queue: self.normal_queue,
        low_queue: self.low_queue,
        pool: self.pool,
        mem_manager: self.mem_manager,
        components: new_comps,
        max_components: self.max_components,
        is_running: self.is_running,
        batch_size: self.batch_size,
        handlers: self.handlers,
        wasm_runtime: self.wasm_runtime,
        debug_log: self.debug_log,
      }
    }
    None => self
  }
}

///|
/// 解注册组件处理器（[热更新] 用）
pub fn Scheduler::unregister_handler(
  self : Scheduler,
  comp_id : Int,
) -> Scheduler {
  Scheduler::{
    high_queue: self.high_queue,
    normal_queue: self.normal_queue,
    low_queue: self.low_queue,
    pool: self.pool,
    mem_manager: self.mem_manager,
    components: self.components,
    max_components: self.max_components,
    is_running: self.is_running,
    batch_size: self.batch_size,
    handlers: self.handlers.unregister(comp_id),
    wasm_runtime: self.wasm_runtime,
    debug_log: self.debug_log,
  }
}

///|
/// 获取组件数量
fn Scheduler::component_count(self : Scheduler) -> Int {
  let mut count = 0
  let mut i = 0
  while i < self.max_components {
    match self.components[i] {
      Some(_) => count = count + 1
      None => ()
    }
    i = i + 1
  }
  count
}

///|
/// 获取队列长度
fn Scheduler::high_queue_length(self : Scheduler) -> Int {
  @core.RingBuffer::length(self.high_queue)
}

///|
fn Scheduler::normal_queue_length(self : Scheduler) -> Int {
  @core.RingBuffer::length(self.normal_queue)
}

///|
fn Scheduler::low_queue_length(self : Scheduler) -> Int {
  @core.RingBuffer::length(self.low_queue)
}

///|
/// 内存池状态
fn Scheduler::pool_status(self : Scheduler) -> (Int, Int) {
  (
    @core.MemoryPool::free_count(self.pool),
    @core.MemoryPool::allocated_count(self.pool),
  )
}

///|
/// 打印调度器状态（V2：新增 MemoryManager 和批处理信息）
pub fn Scheduler::print_status(self : Scheduler) -> Unit {
  let (free, alloced) = self.pool_status()
  let (_mm_alloced, mm_active, mm_free) = self.mem_manager.get_stats()
  println("")
  println(
    "══════════════════════════════════════════════",
  )
  println("║    一多 OS 调度系统状态（V2）   ║")
  println(
    "══════════════════════════════════════════════",
  )
  println("组件数量: " + self.component_count().to_string())
  println("批处理大小: " + self.batch_size.to_string())
  println("")
  println("队列状态:")
  println(
    "  高优队列: " + self.high_queue_length().to_string() + " 待处理",
  )
  println(
    "  普通队列: " + self.normal_queue_length().to_string() + " 待处理",
  )
  println(
    "  低优队列: " + self.low_queue_length().to_string() + " 待处理",
  )
  println("")
  println("内存管理:")
  println(
    "  内存池: " +
    free.to_string() +
    " 空闲 / " +
    alloced.to_string() +
    " 已分配",
  )
  println("  活跃句柄: " + mm_active.to_string())
  println("  可复用ID: " + mm_free.to_string())
  println("")
  println(
    "运行状态: " + (if self.is_running { "运行中" } else { "已停止" }),
  )
  println("")
  println("已注册组件:")
  let mut j = 0
  while j < self.max_components {
    match self.components[j] {
      Some(comp) => {
        let aff_str = match self.get_affinity_top(j) {
          Some(id) => " (亲和度最高: " + id.to_string() + ")"
          None => ""
        }
        println(
          "  ID " +
          j.to_string() +
          ": " +
          comp.name +
          " [" +
          comp.component_type.to_string() +
          "] " +
          status_str(comp.status) +
          aff_str,
        )
      }
      None => ()
    }
    j = j + 1
  }
  println("")
}

///|
fn status_str(status : ComponentStatus) -> String {
  match status {
    Created => "已创建"
    Initialized => "已初始化"
    Running => "运行中"
    Paused => "已暂停"
    Stopped => "已停止"
    Error => "错误"
  }
}

///|
/// 获取组件信息字符串
fn Scheduler::get_component_info(self : Scheduler, id : Int) -> String {
  if id >= 0 && id < self.max_components {
    match self.components[id] {
      Some(comp) =>
        comp.name +
        " [" +
        comp.component_type.to_string() +
        "] " +
        status_str(comp.status)
      None => "<空>"
    }
  } else {
    "<无效>"
  }
}

///|
/// 调度核心消息处理（处理发给自己的消息）
fn Scheduler::handle_core_message(
  self : Scheduler,
  _msg : @core.Message,
) -> Scheduler {
  if self.debug_log {
    println("[Scheduler] 调度核心处理消息")
  }
  self
}

///|
/// 设置调试日志模式
pub fn Scheduler::set_debug_log(self : Scheduler, debug : Bool) -> Scheduler {
  Scheduler::{
    high_queue: self.high_queue,
    normal_queue: self.normal_queue,
    low_queue: self.low_queue,
    pool: self.pool,
    mem_manager: self.mem_manager,
    components: self.components,
    max_components: self.max_components,
    is_running: self.is_running,
    batch_size: self.batch_size,
    handlers: self.handlers,
    wasm_runtime: self.wasm_runtime,
    debug_log: debug,
  }
}

///|
/// 设置 Wasm 运行时
pub fn Scheduler::set_wasm_runtime(
  self : Scheduler,
  rt : @component.WasmRuntime,
) -> Scheduler {
  Scheduler::{
    high_queue: self.high_queue,
    normal_queue: self.normal_queue,
    low_queue: self.low_queue,
    pool: self.pool,
    mem_manager: self.mem_manager,
    components: self.components,
    max_components: self.max_components,
    is_running: self.is_running,
    batch_size: self.batch_size,
    handlers: self.handlers,
    wasm_runtime: Some(rt),
    debug_log: self.debug_log,
  }
}

///|
/// 发送通用消息
pub fn Scheduler::send_message(
  self : Scheduler,
  from : Int,
  to : Int,
  msg : @core.Message,
  priority : @core.MessagePriority,
) -> (Scheduler, Bool) {
  match msg {
    SmallMessage(_, _, payload) => self.send_small(from, to, payload, priority)
    MediumMessage(_, _, handle, _) =>
      self.send_medium(from, to, handle, priority)
    LargeMessage(_, _, handle, access_mode, _) =>
      self.send_large(from, to, handle, access_mode, priority)
  }
}

// ========== 独立函数包装（用于 bootstrap 等按 @scheduler.fn() 方式调用） ==========

///|
/// 创建调度器（独立函数版本）
pub fn create() -> Scheduler {
  Scheduler::create()
}

///|
/// 注册组件（独立函数版本）
pub fn register(
  scheduler : Scheduler,
  info : ComponentInfo,
) -> (Scheduler, Int) {
  scheduler.register(info)
}

///|
/// 发送小消息（独立函数版本）
pub fn send_small(
  scheduler : Scheduler,
  from : Int,
  to : Int,
  payload : @core.SmallPayload,
  priority : @core.MessagePriority,
) -> (Scheduler, Bool) {
  scheduler.send_small(from, to, payload, priority)
}

///|
/// 运行调度循环（独立函数版本）
pub fn run_loop(scheduler : Scheduler, max_iter : Int) -> Scheduler {
  scheduler.run_loop(max_iter)
}

///|
/// 打印调度器状态（独立函数版本）
pub fn print_status(scheduler : Scheduler) -> Unit {
  scheduler.print_status()
}
