/// 一多 OS 零拷贝环形队列（优化版）
/// 优化：去掉 Option[T] 装箱，用 read/write 指针判断空满，消除每个槽位的标记位开销

/// 环形队列（无 Option 装箱，高性能！）
struct RingBuffer[T] {
  buffer: FixedArray[T]
  capacity: Int
  read_idx: Int
  write_idx: Int
}

/// 创建环形队列（用户提供默认值填充）
fn create[T](capacity: Int, default: T) -> RingBuffer[T] {
  RingBuffer[T]::{
    buffer: FixedArray::make(capacity, default),
    capacity: capacity,
    read_idx: 0,
    write_idx: 0
  }
}

/// 入队（零拷贝，无装箱开销）
fn enqueue[T](self: RingBuffer[T], item: T) -> (RingBuffer[T], Bool) {
  let next_write = (self.write_idx + 1) % self.capacity
  if next_write == self.read_idx {
    (self, false)
  } else {
    let mut buf = self.buffer
    buf[self.write_idx] = item
    (RingBuffer[T]::{
      buffer: buf,
      capacity: self.capacity,
      read_idx: self.read_idx,
      write_idx: next_write
    }, true)
  }
}

/// 出队（零拷贝，无 Option 检查开销）
fn dequeue[T](self: RingBuffer[T]) -> (RingBuffer[T], Option[T]) {
  if self.read_idx == self.write_idx {
    (self, None)
  } else {
    let item = self.buffer[self.read_idx]
    let new_read = (self.read_idx + 1) % self.capacity
    (RingBuffer[T]::{
      buffer: self.buffer,
      capacity: self.capacity,
      read_idx: new_read,
      write_idx: self.write_idx
    }, Some(item))
  }
}

/// 查看队首
fn peek[T](self: RingBuffer[T]) -> Option[T] {
  if self.read_idx == self.write_idx {
    None
  } else {
    Some(self.buffer[self.read_idx])
  }
}

/// 当前队列长度
fn length[T](self: RingBuffer[T]) -> Int {
  if self.write_idx >= self.read_idx {
    self.write_idx - self.read_idx
  } else {
    self.capacity - self.read_idx + self.write_idx
  }
}

/// 队列是否为空
fn is_empty[T](self: RingBuffer[T]) -> Bool {
  self.read_idx == self.write_idx
}

/// 队列容量
fn capacity[T](self: RingBuffer[T]) -> Int {
  self.capacity - 1
}