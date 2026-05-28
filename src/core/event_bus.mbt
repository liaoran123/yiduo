/// 一多 OS 事件总线（链式血液系统核心）
/// 生物学比喻：血液在血管中循环，携带信息和养分（数据）到各个器官（组件）
/// 技术实现：发布-订阅模式 + 零拷贝共享内存

/// ==================== 订阅ID类型 ====================
type SubscriptionId = Int

/// ==================== 事件频道类型 ====================
enum ChannelType {
  HighThroughput     // 高吞吐量（如视频流、高频数据）
  Normal           // 普通（如AI结果、状态更新）
  ControlSignal    // 控制信号（如配置变更、命令）
}

/// ==================== 订阅信息 ====================
struct Subscription {
  subscriber_id: Int           // 订阅者的组件ID
  callback: (Int, Int) -> Unit // 回调：(发布者ID, 数据句柄)
}

/// ==================== 事件总线（链式血液系统） ====================
struct EventBus {
  subscriptions: FixedArray[FixedArray[Option[Subscription]]]  // 频道ID -> [订阅列表]
  max_channels: Int
  max_subs_per_channel: Int
}

/// ==================== 创建事件总线 ====================
fn create(max_channels: Int, max_subs_per_channel: Int) -> EventBus {
  let dummy_sub: Option[Subscription] = None
  let mut channels: FixedArray[FixedArray[Option[Subscription]]] = FixedArray::make(max_channels, FixedArray::make(max_subs_per_channel, dummy_sub))
  EventBus {
    subscriptions: channels,
    max_channels: max_channels,
    max_subs_per_channel: max_subs_per_channel
  }
}

/// ==================== 订阅频道 ====================
fn subscribe(self: EventBus, channel_id: Int, subscriber_id: Int, callback: (Int, Int) -> Unit) -> (EventBus, SubscriptionId) {
  if channel_id < 0 || channel_id >= self.max_channels {
    println("[EventBus] ⚠ 无效频道ID: " + channel_id.to_string())
    return (self, -1)
  }
  
  let mut new_subs = self.subscriptions
  let mut channel_subs = new_subs[channel_id]
  let mut assigned_slot = -1
  let mut i = 0
  while i < self.max_subs_per_channel {
    match channel_subs[i] {
      None => {
        assigned_slot = i
        channel_subs[i] = Some(Subscription {
          subscriber_id: subscriber_id,
          callback: callback
        })
        i = self.max_subs_per_channel
      }
      Some(_) => {
        i = i + 1
      }
    }
  }
  
  new_subs[channel_id] = channel_subs
  
  let new_bus = EventBus {
    subscriptions: new_subs,
    max_channels: self.max_channels,
    max_subs_per_channel: self.max_subs_per_channel
  }
  
  (new_bus, if assigned_slot >= 0 { channel_id * 1000 + assigned_slot } else { -1 })
}

/// ==================== 取消订阅 ====================
fn unsubscribe(self: EventBus, subscription_id: SubscriptionId) -> EventBus {
  let channel_id = subscription_id / 1000
  let slot_id = subscription_id % 1000
  
  if channel_id < 0 || channel_id >= self.max_channels {
    return self
  }
  if slot_id < 0 || slot_id >= self.max_subs_per_channel {
    return self
  }
  
  let mut new_subs = self.subscriptions
  let mut channel_subs = new_subs[channel_id]
  channel_subs[slot_id] = None
  new_subs[channel_id] = channel_subs
  
  EventBus {
    subscriptions: new_subs,
    max_channels: self.max_channels,
    max_subs_per_channel: self.max_subs_per_channel
  }
}

/// ==================== 发布事件（数据流动） ====================
fn publish(self: EventBus, channel_id: Int, publisher_id: Int, data_handle: Int) -> (EventBus, Int) {
  if channel_id < 0 || channel_id >= self.max_channels {
    println("[EventBus] ⚠ 无效频道ID: " + channel_id.to_string())
    return (self, 0)
  }
  
  let channel_subs = self.subscriptions[channel_id]
  let mut notified_count = 0
  let mut i = 0
  while i < self.max_subs_per_channel {
    match channel_subs[i] {
      Some(sub) => {
        println("[EventBus] 🩸 流动通知: 组件" + publisher_id.to_string() + " → 组件" + sub.subscriber_id.to_string())
        sub.callback(publisher_id, data_handle)
        notified_count = notified_count + 1
      }
      None => ()
    }
    i = i + 1
  }
  
  (self, notified_count)
}

/// ==================== 获取频道订阅数 ====================
fn channel_sub_count(self: EventBus, channel_id: Int) -> Int {
  if channel_id < 0 || channel_id >= self.max_channels {
    return 0
  }
  
  let channel_subs = self.subscriptions[channel_id]
  let mut count = 0
  let mut i = 0
  while i < self.max_subs_per_channel {
    match channel_subs[i] {
      Some(_) => count = count + 1,
      None => ()
    }
    i = i + 1
  }
  count
}

/// ==================== 打印事件总线状态 ====================
fn print_status(self: EventBus) {
  println("")
  println("══════════════════════════════════════════════")
  println("║    一多 OS 事件总线（链式血液系统） ║")
  println("══════════════════════════════════════════════")
  let mut total_subs = 0
  let mut i = 0
  while i < self.max_channels {
    let count = self.channel_sub_count(i)
    total_subs = total_subs + count
    if count > 0 {
      println("频道 " + i.to_string() + ": " + count.to_string() + " 订阅者")
    }
    i = i + 1
  }
  println("总订阅数: " + total_subs.to_string())
  println("")
}
