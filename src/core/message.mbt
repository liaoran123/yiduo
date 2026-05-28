/// 一多 OS 消息系统（三种模式）
/// 设计：小消息复制模式、中消息句柄模式、大消息共享内存模式
/// 优化：使用 Int ID 替代 String，消除转换开销

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
    from: Int
    to: Int
    payload: SmallPayload
  }
  /// 中消息：句柄模式（平衡，零拷贝）
  MediumMessage {
    from: Int
    to: Int
    handle: Int
  }
  /// 大消息：共享内存模式（性能优先）
  LargeMessage {
    from: Int
    to: Int
    handle: Int
    access_mode: AccessMode
  }
}