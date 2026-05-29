/// 🩸 事件总线组件（高性能优化版）
/// 一多 OS 的血液系统
/// 优化：零拷贝数据传递 + 批处理能力
/// 目标：事件端到端延迟 < 1μs，吞吐量 > 100万/秒

use @component.ComponentConfig
use @component.ComponentInstance
use @component.Capability
use @component.YiduoComponent
use @core.Message
use @core.SmallPayload
use @core.MediumPayload
use @core.LargePayload
use @core.MessagePriority
use @core.RingBuffer
use @core.MemoryPool

/// ==================== 通道订阅者结构 ====================
struct ChannelSubscriber {
  component_id: Int,
  priority: MessagePriority,
  is_active: Bool,
}

/// ==================== 通道结构 ====================
struct EventChannel {
  id: Int,
  name: String,
  subscribers: List[ChannelSubscriber],
  message_queue: RingBuffer[Message],
  max_queue_size: Int,
}

/// ==================== 事件总线实现（优化版） ====================
struct EventBusComponentImpl {
  state: @component.ComponentState,
  max_channels: Int,
  max_subs_per_channel: Int,
  channels: FixedArray[Option[EventChannel]],
  pool: MemoryPool,
  batch_size: Int, // 批处理大小
  total_events_processed: Int,
}

impl YiduoComponent for EventBusComponentImpl {
  initialize(self, config: ComponentConfig) -> Result<(), Error> {
    println("[EventBus-Component] 🩸 初始化...（批处理大小: " + self.batch_size.to_string() + "）")
    Ok(())
  }
  
  heartbeat(self) -> Result<(), Error> {
    // 定期检查通道状态，清理不活跃订阅者
    Ok(())
  }
  
  shutdown(self) -> Result<(), Error> {
    println("[EventBus-Component] 🩸 关闭...已处理 " + self.total_events_processed.to_string() + " 事件")
    Ok(())
  }
  
  get_capability(self) -> Capability {
    Capability{
      interface_name: "yiduo.event-bus",
      version: "1.0.0",
    }
  }
}

/// ==================== 创建优化版事件总线组件 ====================
fn create_event_bus_component(max_channels: Int, max_subs: Int, batch_size: Int) -> @component.ComponentInstance {
  println("[Component-Factory] 🩸 创建高性能事件总线Wasm组件...")
  let handle = 101 as @component.WasmComponentHandle
  @component.ComponentInstance{
    id: 101,
    state: @component.ComponentState.Created,
    config: @component.ComponentConfig{
      name: "event-bus",
      component_type: "wasm",
      config_data: "",
    },
    handle: handle,
  }
}

/// ==================== 零拷贝事件发布（批处理优化） ====================
/// 使用内存句柄而不是数据拷贝
fn publish_event_zero_copy(
  self: EventBusComponentImpl,
  channel_id: Int,
  publisher_id: Int,
  message: Message,
  priority: MessagePriority
) -> (EventBusComponentImpl, Bool) {
  // 查找通道
  if channel_id < 0 || channel_id >= self.max_channels {
    return (self, false)
  }
  
  match self.channels[channel_id] {
    Some(channel) => {
      // 将消息加入通道队列（零拷贝，直接传递Message）
      let (new_queue, ok) = RingBuffer::enqueue(channel.message_queue, message)
      let new_channel = EventChannel{
        id: channel.id,
        name: channel.name,
        subscribers: channel.subscribers,
        message_queue: new_queue,
        max_queue_size: channel.max_queue_size,
      }
      
      let mut new_channels = self.channels
      new_channels[channel_id] = Some(new_channel)
      
      // 如果队列达到批处理大小，立即触发分发
      let new_self = EventBusComponentImpl{
        state: self.state,
        max_channels: self.max_channels,
        max_subs_per_channel: self.max_subs_per_channel,
        channels: new_channels,
        pool: self.pool,
        batch_size: self.batch_size,
        total_events_processed: self.total_events_processed,
      }
      
      if RingBuffer::length(new_queue) >= self.batch_size {
        let (batched_self, _) = flush_batch(new_self, channel_id)
        (batched_self, ok)
      } else {
        (new_self, ok)
      }
    }
    None => (self, false)
  }
}

/// ==================== 批处理刷新 ====================
fn flush_batch(self: EventBusComponentImpl, channel_id: Int) -> (EventBusComponentImpl, Int) {
  if channel_id < 0 || channel_id >= self.max_channels {
    return (self, 0)
  }
  
  match self.channels[channel_id] {
    Some(channel) => {
      let mut processed = 0
      let mut queue = channel.message_queue
      
      // 批量处理队列中的消息
      while processed < self.batch_size {
        let (new_queue, opt_msg) = RingBuffer::dequeue(queue)
        queue = new_queue
        match opt_msg {
          Some(msg) => {
            // 分发消息给所有订阅者（零拷贝传递句柄）
            let _ = dispatch_to_subscribers(self, channel, msg)
            processed = processed + 1
          }
          None => break
        }
      }
      
      let new_channel = EventChannel{
        id: channel.id,
        name: channel.name,
        subscribers: channel.subscribers,
        message_queue: queue,
        max_queue_size: channel.max_queue_size,
      }
      
      let mut new_channels = self.channels
      new_channels[channel_id] = Some(new_channel)
      
      let new_self = EventBusComponentImpl{
        state: self.state,
        max_channels: self.max_channels,
        max_subs_per_channel: self.max_subs_per_channel,
        channels: new_channels,
        pool: self.pool,
        batch_size: self.batch_size,
        total_events_processed: self.total_events_processed + processed,
      }
      
      (new_self, processed)
    }
    None => (self, 0)
  }
}

/// ==================== 分发消息给订阅者（内部函数） ====================
fn dispatch_to_subscribers(self: EventBusComponentImpl, channel: EventChannel, msg: Message) -> Int {
  let mut dispatched = 0
  let mut subs = channel.subscribers
  while !subs.is_empty() {
    let sub = subs.head()
    if sub.is_active {
      // 这里实际上会通过调度器发送消息给订阅者组件
      // 使用组件的 Int ID 直接通信
      dispatched = dispatched + 1
    }
    subs = subs.tail()
  }
  dispatched
}

/// ==================== 订阅通道 ====================
fn subscribe_channel(self: EventBusComponentImpl, channel_id: Int, subscriber_id: Int, priority: MessagePriority) -> (EventBusComponentImpl, Bool) {
  if channel_id < 0 || channel_id >= self.max_channels {
    return (self, false)
  }
  
  let mut new_channels = self.channels
  let new_channel_opt = match new_channels[channel_id] {
    Some(channel) => {
      let sub = ChannelSubscriber{
        component_id: subscriber_id,
        priority: priority,
        is_active: true,
      }
      // 检查是否已订阅
      let already_subscribed = channel.subscribers.exists(|s| s.component_id == subscriber_id)
      if already_subscribed {
        Some(channel)
      } else {
        Some(EventChannel{
          id: channel.id,
          name: channel.name,
          subscribers: sub :: channel.subscribers,
          message_queue: channel.message_queue,
          max_queue_size: channel.max_queue_size,
        })
      }
    }
    None => None
  }
  
  if new_channel_opt.is_some() {
    new_channels[channel_id] = new_channel_opt
  }
  
  let new_self = EventBusComponentImpl{
    state: self.state,
    max_channels: self.max_channels,
    max_subs_per_channel: self.max_subs_per_channel,
    channels: new_channels,
    pool: self.pool,
    batch_size: self.batch_size,
    total_events_processed: self.total_events_processed,
  }
  
  (new_self, new_channel_opt.is_some())
}

/// ==================== 创建通道 ====================
fn create_channel(self: EventBusComponentImpl, channel_id: Int, name: String, max_queue: Int) -> (EventBusComponentImpl, Bool) {
  if channel_id < 0 || channel_id >= self.max_channels {
    return (self, false)
  }
  
  // 检查通道是否已存在
  match self.channels[channel_id] {
    Some(_) => (self, false),
    None => {
      let dummy_msg = Message::SmallMessage{
        from: 0, to: 0,
        payload: SmallPayload{msg_type: 0, data: []}
      }
      let new_channel = EventChannel{
        id: channel_id,
        name: name,
        subscribers: [],
        message_queue: RingBuffer::create(max_queue, dummy_msg),
        max_queue_size: max_queue,
      }
      
      let mut new_channels = self.channels
      new_channels[channel_id] = Some(new_channel)
      
      let new_self = EventBusComponentImpl{
        state: self.state,
        max_channels: self.max_channels,
        max_subs_per_channel: self.max_subs_per_channel,
        channels: new_channels,
        pool: self.pool,
        batch_size: self.batch_size,
        total_events_processed: self.total_events_processed,
      }
      
      println("[EventBus-Component] 🩸 通道创建: " + name + " [ID:" + channel_id.to_string() + "]")
      (new_self, true)
    }
  }
}

/// ==================== 统计信息 ====================
fn get_stats(self: EventBusComponentImpl) -> (Int, Int, Int) {
  let mut channel_count = 0
  let mut subscriber_count = 0
  let mut i = 0
  while i < self.max_channels {
    match self.channels[i] {
      Some(channel) => {
        channel_count = channel_count + 1
        subscriber_count = subscriber_count + channel.subscribers.length()
      }
      None => ()
    }
    i = i + 1
  }
  (channel_count, subscriber_count, self.total_events_processed)
}
