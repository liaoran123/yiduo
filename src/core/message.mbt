/// 一多 OS 消息系统（三种模式）
/// 设计：小消息复制模式、中消息句柄模式、大消息共享内存模式

/// 访问模式
enum AccessMode {
  ReadOnly
  ReadWrite
}

/// 消息优先级
enum MessagePriority {
  High
  Normal
  Low
}

/// 小消息载荷（< 256 字节，内联复制）
struct SmallPayload {
  msg_type: Int
  data: List[Byte]
}

/// 消息类型（核心数据结构）
enum Message {
  /// 小消息：直接复制模式（安全优先）
  SmallMessage {
    from: String
    to: String
    payload: SmallPayload
  }
  /// 中消息：句柄模式（平衡，零拷贝）
  MediumMessage {
    from: String
    to: String
    handle: String
  }
  /// 大消息：共享内存模式（性能优先）
  LargeMessage {
    from: String
    to: String
    handle: String
    access_mode: AccessMode
  }
}