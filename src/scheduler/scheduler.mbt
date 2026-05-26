/// 一多 OS 高性能可编程调度系统（优化版）
/// 优化：Int ID 替代 String，FixedArray 替代 Map，哈希查找→索引访问

/// ==================== 系统契约常量 ====================
/// 调度核心的固定 ID（系统契约）
const SCHEDULER_CORE_ID: Int = 0
/// 调度核心的组件类型标识
const COMPONENT_TYPE_NATIVE_CORE: String = "native-core"

/// 组件状态
enum ComponentStatus {
  Created
  Initialized
  Running
  Paused
  Stopped
  Error
}

/// 组件信息（优化：Int ID 替代 String）
struct ComponentInfo {
  name: String
  component_type: String
  status: ComponentStatus
}

/// 调度器（优化版）
/// 组件表改用 FixedArray[Option[ComponentInfo]]，按 Int 索引访问，无哈希开销
struct Scheduler {
  high_queue: @core.RingBuffer[@core.Message]
  normal_queue: @core.RingBuffer[@core.Message]
  low_queue: @core.RingBuffer[@core.Message]
  pool: @core.MemoryPool
  components: FixedArray[Option[ComponentInfo]]
  max_components: Int
  is_running: Bool
}

/// 创建调度器
fn create() -> Scheduler {
  let dummy_msg = @core.Message::SmallMessage{
    from: "", to: "",
    payload: @core.SmallPayload{msg_type: 0, data: []}
  }
  let dummy_comp: Option[ComponentInfo] = None
  Scheduler::{
    high_queue: @core.RingBuffer::create(65, dummy_msg),
    normal_queue: @core.RingBuffer::create(257, dummy_msg),
    low_queue: @core.RingBuffer::create(129, dummy_msg),
    pool: @core.MemoryPool::create(@core.MemoryPoolConfig{block_size: 4096, block_count: 64}),
    components: FixedArray::make(32, dummy_comp),
    max_components: 32,
    is_running: false
  }
}

/// 注册组件（返回 Int ID，由分配器分配）
fn register(self: Scheduler, info: ComponentInfo) -> (Scheduler, Int) {
  let mut new_comps = self.components
  let mut assigned_id = -1
  let mut i = 0
  while i < self.max_components {
    match new_comps[i] {
      None => {
        new_comps[i] = Some(info)
        assigned_id = i
        i = self.max_components
      }
      Some(_) => {
        i = i + 1
      }
    }
  }
  let new_scheduler = Scheduler::{
    high_queue: self.high_queue, normal_queue: self.normal_queue, low_queue: self.low_queue,
    pool: self.pool, components: new_comps, max_components: self.max_components, is_running: self.is_running
  }
  (new_scheduler, assigned_id)
}

/// 发送小消息
fn send_small(self: Scheduler, from: Int, to: Int, payload: @core.SmallPayload, priority: @core.MessagePriority) -> (Scheduler, Bool) {
  let msg = @core.Message::SmallMessage{
    from: from.to_string(), to: to.to_string(), payload: payload
  }
  self.send_to_queue(msg, priority)
}

/// 发送中消息（句柄模式）
fn send_medium(self: Scheduler, from: Int, to: Int, handle: Int, priority: @core.MessagePriority) -> (Scheduler, Bool) {
  let new_pool = @core.MemoryPool::retain(self.pool, handle)
  let new_self = Scheduler::{
    high_queue: self.high_queue, normal_queue: self.normal_queue, low_queue: self.low_queue,
    pool: new_pool, components: self.components, max_components: self.max_components, is_running: self.is_running
  }
  let msg = @core.Message::MediumMessage{
    from: from.to_string(), to: to.to_string(), handle: handle.to_string()
  }
  new_self.send_to_queue(msg, priority)
}

/// 发送大消息（共享内存模式）
fn send_large(self: Scheduler, from: Int, to: Int, handle: Int, access_mode: @core.AccessMode, priority: @core.MessagePriority) -> (Scheduler, Bool) {
  let new_pool = @core.MemoryPool::retain(self.pool, handle)
  let new_self = Scheduler::{
    high_queue: self.high_queue, normal_queue: self.normal_queue, low_queue: self.low_queue,
    pool: new_pool, components: self.components, max_components: self.max_components, is_running: self.is_running
  }
  let msg = @core.Message::LargeMessage{
    from: from.to_string(), to: to.to_string(), handle: handle.to_string(), access_mode: access_mode
  }
  new_self.send_to_queue(msg, priority)
}

/// 发送消息到对应优先级队列
fn send_to_queue(self: Scheduler, msg: @core.Message, priority: @core.MessagePriority) -> (Scheduler, Bool) {
  match priority {
    @core.MessagePriority::High => {
      let (q, ok) = @core.RingBuffer::enqueue(self.high_queue, msg)
      (Scheduler::{
        high_queue: q, normal_queue: self.normal_queue, low_queue: self.low_queue,
        pool: self.pool, components: self.components, max_components: self.max_components, is_running: self.is_running
      }, ok)
    }
    @core.MessagePriority::Normal => {
      let (q, ok) = @core.RingBuffer::enqueue(self.normal_queue, msg)
      (Scheduler::{
        high_queue: self.high_queue, normal_queue: q, low_queue: self.low_queue,
        pool: self.pool, components: self.components, max_components: self.max_components, is_running: self.is_running
      }, ok)
    }
    @core.MessagePriority::Low => {
      let (q, ok) = @core.RingBuffer::enqueue(self.low_queue, msg)
      (Scheduler::{
        high_queue: self.high_queue, normal_queue: self.normal_queue, low_queue: q,
        pool: self.pool, components: self.components, max_components: self.max_components, is_running: self.is_running
      }, ok)
    }
  }
}

/// 处理一条消息（优先级顺序：高 > 普通 > 低）
fn process_one(self: Scheduler) -> Scheduler {
  let (hq, opt_msg) = @core.RingBuffer::dequeue(self.high_queue)
  let s1 = Scheduler::{
    high_queue: hq, normal_queue: self.normal_queue, low_queue: self.low_queue,
    pool: self.pool, components: self.components, max_components: self.max_components, is_running: self.is_running
  }
  match opt_msg {
    Some(m) => s1.dispatch(m)
    None => {
      let (nq, opt_msg2) = @core.RingBuffer::dequeue(s1.normal_queue)
      let s2 = Scheduler::{
        high_queue: s1.high_queue, normal_queue: nq, low_queue: s1.low_queue,
        pool: s1.pool, components: s1.components, max_components: self.max_components, is_running: s1.is_running
      }
      match opt_msg2 {
        Some(m) => s2.dispatch(m)
        None => {
          let (lq, opt_msg3) = @core.RingBuffer::dequeue(s2.low_queue)
          let s3 = Scheduler::{
            high_queue: s2.high_queue, normal_queue: s2.normal_queue, low_queue: lq,
            pool: s2.pool, components: s2.components, max_components: self.max_components, is_running: s2.is_running
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

/// 解析消息中的 to_id（Int 格式）
fn parse_to_id(msg: @core.Message) -> (Int, Bool) {
  let to_str = match msg {
    @core.Message::SmallMessage{to, ..} => to
    @core.Message::MediumMessage{to, ..} => to
    @core.Message::LargeMessage{to, ..} => to
  }
  (parse_int(to_str), match msg {
    @core.Message::SmallMessage{..} => false
    _ => true
  })
}

/// 简单字符串转整数
fn parse_int(s: String) -> Int {
  // 简化实现，实际可以使用标准库
  // 消息中存储的已经是数字字符串，如 "1", "2"
  if s.length() <= 0 { return -1 }
  let bytes = s.to_bytes()
  let mut result = 0
  let mut i = 0
  while i < bytes.length() {
    let byte = bytes[i]
    if byte.to_int() >= 48 && byte.to_int() <= 57 {
      result = result * 10 + (byte.to_int() - 48)
    }
    i = i + 1
  }
  result
}

/// 分发消息给目标组件（使用 Int 索引直接访问 FixedArray）
fn dispatch(self: Scheduler, msg: @core.Message) -> Scheduler {
  let (to_id, need_release) = match msg {
    @core.Message::SmallMessage{to, ..} => (parse_int(to), false)
    @core.Message::MediumMessage{to, ..} => (parse_int(to), true)
    @core.Message::LargeMessage{to, ..} => (parse_int(to), true)
  }
  
  // 检查是否是发给调度核心自己的消息（系统契约）
  if to_id == SCHEDULER_CORE_ID {
    println("[Scheduler] 收到给自己的消息（核心处理）")
    return self.handle_core_message(msg)
  }
  
  if to_id >= 0 && to_id < self.max_components {
    match self.components[to_id] {
      Some(comp) => {
        println("[Scheduler] 分发消息 → " + comp.name + " (ID:" + to_id.to_string() + ")")
        if need_release {
          let handle = match msg {
            @core.Message::MediumMessage{handle, ..} => parse_int(handle)
            @core.Message::LargeMessage{handle, ..} => parse_int(handle)
            _ => -1
          }
          Scheduler::{
            high_queue: self.high_queue, normal_queue: self.normal_queue, low_queue: self.low_queue,
            pool: @core.MemoryPool::release(self.pool, handle),
            components: self.components, max_components: self.max_components, is_running: self.is_running
          }
        } else {
          self
        }
      }
      None => {
        println("[Scheduler] ⚠ 组件未注册: ID " + to_id.to_string())
        self
      }
    }
  } else {
    println("[Scheduler] ⚠ 无效组件ID: " + to_id.to_string())
    self
  }
}

/// 运行调度循环
fn run_loop(self: Scheduler, max_iter: Int) -> Scheduler {
  let mut s = Scheduler::{
    high_queue: self.high_queue, normal_queue: self.normal_queue, low_queue: self.low_queue,
    pool: self.pool, components: self.components, max_components: self.max_components, is_running: true
  }
  let mut i = 0
  while i < max_iter {
    s = s.process_one()
    i = i + 1
  }，
  Scheduler::{
    high_queue: s.high_queue, normal_queue: s.normal_queue, low_queue: s.low_queue,
    pool: s.pool, components: s.components, max_components: self.max_components, is_running: false
  }
}

/// 获取组件名称
fn component_name(self: Scheduler, id: Int) -> String {
  if id >= 0 && id < self.max_components {
    match self.components[id] {
      Some(comp) => comp.name
      None => "<空>"
    }
  } else {
    "<无效>"
  }
}

/// 获取组件数量
fn component_count(self: Scheduler) -> Int {
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

/// 获取队列长度
fn high_queue_length(self: Scheduler) -> Int { @core.RingBuffer::length(self.high_queue) }
fn normal_queue_length(self: Scheduler) -> Int { @core.RingBuffer::length(self.normal_queue) }
fn low_queue_length(self: Scheduler) -> Int { @core.RingBuffer::length(self.low_queue) }

/// 内存池状态
fn pool_status(self: Scheduler) -> (Int, Int) {
  (@core.MemoryPool::free_count(self.pool), @core.MemoryPool::allocated_count(self.pool))
}

/// 打印调度器状态
fn print_status(self: Scheduler) {
  let (free, alloced) = self.pool_status()
  println("")
  println("══════════════════════════════════════════════")
  println("║    一多 OS 调度系统状态（简化版）   ║")
  println("══════════════════════════════════════════════")
  println("组件数量: " + self.component_count().to_string())
  println("高优队列: " + self.high_queue_length().to_string() + " 待处理")
  println("普通队列: " + self.normal_queue_length().to_string() + " 待处理")
  println("低优队列: " + self.low_queue_length().to_string() + " 待处理")
  println("内存池: " + free.to_string() + " 空闲 / " + alloced.to_string() + " 已分配")
  println("运行状态: " + (if self.is_running { "运行中" } else { "已停止" }))
  println("")
  println("已注册组件:")
  let mut j = 0
  while j < self.max_components {
    match self.components[j] {
      Some(comp) => {
        println("  ID " + j.to_string() + ": " + comp.name + " [" + comp.component_type + "] " + status_str(comp.status))
      }
      None => ()
    }
    j = j + 1
  }
  println("")
}

fn status_str(status: ComponentStatus) -> String {
  match status {
    Created => "已创建"
    Initialized => "已初始化"
    Running => "运行中"
    Paused => "已暂停"
    Stopped => "已停止"
    Error => "错误"
  }
}

/// 获取组件信息字符串
fn get_component_info(self: Scheduler, id: Int) -> String {
  if id >= 0 && id < self.max_components {
    match self.components[id] {
      Some(comp) => comp.name + " [" + comp.component_type + "] " + status_str(comp.status)
      None => "<空>"
    }
  } else {
    "<无效>"
  }
}

// ==================== 辅助函数 ====================

/// 辅助函数：解析 Int（简单版本）
fn parse_int(s: String) -> Int {
  if s.length() <= 0 { return -1 }
  let bytes = s.to_bytes()
  let mut result = 0
  let mut i = 0
  while i < bytes.length() {
    let byte = bytes[i]
    if byte.to_int() >= 48 && byte.to_int() <= 57 {
      result = result * 10 + (byte.to_int() - 48)
    }
    i = i + 1
  }
  result
}

/// 调度核心消息处理（处理发给自己的消息）
fn handle_core_message(self: Scheduler, msg: @core.Message) -> Scheduler {
  println("[Scheduler] 调度核心处理消息")
  // 未来可以在这里添加具体的核心消息处理逻辑
  // 比如：组件管理、调度配置、系统查询等
  self
}

/// 发送通用消息
fn send_message(
  self: Scheduler,
  from: Int,
  to: Int,
  msg: @core.Message,
  priority: @core.MessagePriority
) -> (Scheduler, Bool) {
  match msg {
    @core.Message::SmallMessage{payload, ..} => self.send_small(from, to, payload, priority),
    @core.Message::MediumMessage{handle, ..} => self.send_medium(from, to, parse_int(handle), priority),
    @core.Message::LargeMessage{handle, access_mode, ..} => self.send_large(from, to, parse_int(handle), access_mode, priority)
  }
}
