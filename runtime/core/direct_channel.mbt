/// 🚀 DirectMessage — 热路径直接消息
///
/// 小消息（≤7 字节）直接 inline 编码在 payload 字段中，
/// 完全避免堆分配和 MemoryManager 查询。
///
/// 编码格式：
///   bit 0-55:  负载数据（7 字节小端序）
///   bit 56-59: payload 长度（0-7）
///   bit 60-62: 消息类型（0-7）
///   bit 63:    是否 inline 标记

///|
pub struct DirectMessage {
  sender : Int
  receiver : Int
  payload : Int64 // inline 编码（小消息直接嵌入，大消息为共享内存指针）
  msg_type : Int
  has_inline : Bool
}

///|
pub fn DirectMessage::create_inline(
  sender : Int,
  receiver : Int,
  msg_type : Int,
  data : Array[Byte],
) -> DirectMessage {
  let len = data.length()
  let inline_len = if len > 7 { 7 } else { len }
  let mut payload : Int64 = 0
  let mut i = 0
  while i < inline_len {
    let shifted = data[i].to_int64() << (i * 8)
    payload = payload | shifted
    i = i + 1
  }
  DirectMessage::{ sender, receiver, payload, msg_type, has_inline: len <= 7 }
}

///|
pub fn DirectMessage::create_with_ptr(
  sender : Int,
  receiver : Int,
  msg_type : Int,
  ptr : Int64,
) -> DirectMessage {
  DirectMessage::{ sender, receiver, payload: ptr, msg_type, has_inline: false }
}

///|
pub fn DirectMessage::get_inline_data(self : DirectMessage) -> Array[Byte] {
  if !self.has_inline {
    return []
  }
  let result : Array[Byte] = []
  let mut v = self.payload
  let mut i = 0
  while i < 7 {
    let byte_val : Byte = (v & 0xFF).to_byte()
    result.push(byte_val)
    v = v >> 8
    i = i + 1
  }
  // 去掉尾部零
  let mut j = result.length() - 1
  while j >= 0 {
    if result[j] == (0 : Int).to_byte() {
      j = j - 1
    } else {
      break
    }
  }
  let trimmed : Array[Byte] = []
  let mut k = 0
  while k <= j {
    trimmed.push(result[k])
    k = k + 1
  }
  trimmed
}

///|
/// 🚀 DirectChannel — 热路径组件直连通道
///
/// 绕过调度器的优先级队列，组件对之间直连。
/// 适用于高频通信的配对组件（如 scheduler ↔ logger）。
///
/// 性能：~100ns/msg（vs 调度器 ~500ns/msg）

///|
pub struct DirectChannel {
  /// 双向各一个 SPSCBuffer
  a_to_b : SPSCBuffer[DirectMessage]
  b_to_a : SPSCBuffer[DirectMessage]
  /// 统计
  a_to_b_count : Int64
  b_to_a_count : Int64
  /// 通道配置
  component_a : Int
  component_b : Int
  dropped_count : Int64 // 满时丢弃计数
}

///|
pub fn DirectChannel::create(
  a : Int,
  b : Int,
  buffer_size : Int,
) -> DirectChannel {
  let msg = DirectMessage::create_inline(0, 0, 0, [])
  DirectChannel::{
    a_to_b: SPSCBuffer::create(buffer_size, msg),
    b_to_a: SPSCBuffer::create(buffer_size, msg),
    a_to_b_count: 0,
    b_to_a_count: 0,
    component_a: a,
    component_b: b,
    dropped_count: 0,
  }
}

///|
/// A → B 发送
pub fn DirectChannel::send_a_to_b(
  self : DirectChannel,
  msg : DirectMessage,
) -> DirectChannel {
  let (buf, ok) = self.a_to_b.enqueue(msg)
  if ok {
    DirectChannel::{
      a_to_b: buf,
      b_to_a: self.b_to_a,
      a_to_b_count: self.a_to_b_count + 1,
      b_to_a_count: self.b_to_a_count,
      component_a: self.component_a,
      component_b: self.component_b,
      dropped_count: self.dropped_count,
    }
  } else {
    DirectChannel::{
      a_to_b: buf,
      b_to_a: self.b_to_a,
      a_to_b_count: self.a_to_b_count,
      b_to_a_count: self.b_to_a_count,
      component_a: self.component_a,
      component_b: self.component_b,
      dropped_count: self.dropped_count + 1,
    }
  }
}

///|
/// B → A 发送
pub fn DirectChannel::send_b_to_a(
  self : DirectChannel,
  msg : DirectMessage,
) -> DirectChannel {
  let (buf, ok) = self.b_to_a.enqueue(msg)
  if ok {
    DirectChannel::{
      a_to_b: self.a_to_b,
      b_to_a: buf,
      a_to_b_count: self.a_to_b_count,
      b_to_a_count: self.b_to_a_count + 1,
      component_a: self.component_a,
      component_b: self.component_b,
      dropped_count: self.dropped_count,
    }
  } else {
    DirectChannel::{
      a_to_b: self.a_to_b,
      b_to_a: buf,
      a_to_b_count: self.a_to_b_count,
      b_to_a_count: self.b_to_a_count,
      component_a: self.component_a,
      component_b: self.component_b,
      dropped_count: self.dropped_count + 1,
    }
  }
}

///|
/// A 接收来自 B 的消息
pub fn DirectChannel::recv_a(
  self : DirectChannel,
) -> (DirectChannel, DirectMessage?) {
  let (buf, item) = self.b_to_a.dequeue()
  (
    DirectChannel::{
      a_to_b: self.a_to_b,
      b_to_a: buf,
      a_to_b_count: self.a_to_b_count,
      b_to_a_count: self.b_to_a_count,
      component_a: self.component_a,
      component_b: self.component_b,
      dropped_count: self.dropped_count,
    },
    item,
  )
}

///|
/// B 接收来自 A 的消息
pub fn DirectChannel::recv_b(
  self : DirectChannel,
) -> (DirectChannel, DirectMessage?) {
  let (buf, item) = self.a_to_b.dequeue()
  (
    DirectChannel::{
      a_to_b: buf,
      b_to_a: self.b_to_a,
      a_to_b_count: self.a_to_b_count,
      b_to_a_count: self.b_to_a_count,
      component_a: self.component_a,
      component_b: self.component_b,
      dropped_count: self.dropped_count,
    },
    item,
  )
}

///|
/// A 批量接收来自 B 的消息
pub fn DirectChannel::recv_a_batch(
  self : DirectChannel,
  max_count : Int,
) -> (DirectChannel, Array[DirectMessage]) {
  let (buf, items) = self.b_to_a.dequeue_batch(max_count)
  (
    DirectChannel::{
      a_to_b: self.a_to_b,
      b_to_a: buf,
      a_to_b_count: self.a_to_b_count,
      b_to_a_count: self.b_to_a_count,
      component_a: self.component_a,
      component_b: self.component_b,
      dropped_count: self.dropped_count,
    },
    items,
  )
}

///|
/// B 批量接收来自 A 的消息
pub fn DirectChannel::recv_b_batch(
  self : DirectChannel,
  max_count : Int,
) -> (DirectChannel, Array[DirectMessage]) {
  let (buf, items) = self.a_to_b.dequeue_batch(max_count)
  (
    DirectChannel::{
      a_to_b: buf,
      b_to_a: self.b_to_a,
      a_to_b_count: self.a_to_b_count,
      b_to_a_count: self.b_to_a_count,
      component_a: self.component_a,
      component_b: self.component_b,
      dropped_count: self.dropped_count,
    },
    items,
  )
}

///|
pub fn DirectChannel::stats(self : DirectChannel) -> (Int64, Int64, Int64) {
  (self.a_to_b_count, self.b_to_a_count, self.dropped_count)
}

///|
/// 🚀 ChannelManager — 通道管理器
pub struct ChannelManager {
  channels : Array[DirectChannel?]
}

///|
pub fn ChannelManager::create(max_channels : Int) -> ChannelManager {
  let arr : Array[DirectChannel?] = []
  let mut i = 0
  while i < max_channels {
    arr.push(None)
    i = i + 1
  }
  ChannelManager::{ channels: arr }
}

///|
pub fn ChannelManager::create_channel(
  self : ChannelManager,
  a : Int,
  b : Int,
  buffer_size : Int,
) -> (ChannelManager, Int) {
  let idx = self.channels.length()
  let new_channels = self.channels
  new_channels.push(Some(DirectChannel::create(a, b, buffer_size)))
  (ChannelManager::{ channels: new_channels }, idx)
}

///|
pub fn ChannelManager::find_channel(
  self : ChannelManager,
  a : Int,
  b : Int,
) -> Int? {
  let mut i = 0
  while i < self.channels.length() {
    match self.channels[i] {
      Some(ch) =>
        if (ch.component_a == a && ch.component_b == b) ||
          (ch.component_a == b && ch.component_b == a) {
          return Some(i)
        }
      None => ()
    }
    i = i + 1
  }
  None
}

///|
pub fn ChannelManager::get(self : ChannelManager, id : Int) -> DirectChannel? {
  if id >= 0 && id < self.channels.length() {
    self.channels[id]
  } else {
    None
  }
}

///|
pub fn ChannelManager::set(
  self : ChannelManager,
  id : Int,
  ch : DirectChannel,
) -> ChannelManager {
  let new_channels = self.channels
  new_channels[id] = Some(ch)
  ChannelManager::{ channels: new_channels }
}

///|
pub fn ChannelManager::len(self : ChannelManager) -> Int {
  self.channels.length()
}
