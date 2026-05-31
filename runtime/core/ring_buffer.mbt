///|
pub struct RingBuffer[T] {
  buffer : FixedArray[T]
  capacity : Int
  read_idx : Int
  write_idx : Int
}

///|
pub fn[T] RingBuffer::create(capacity : Int, default : T) -> RingBuffer[T] {
  RingBuffer::{
    buffer: FixedArray::make(capacity, default),
    capacity,
    read_idx: 0,
    write_idx: 0,
  }
}

///|
pub fn[T] RingBuffer::enqueue(
  self : RingBuffer[T],
  item : T,
) -> (RingBuffer[T], Bool) {
  let next_write = (self.write_idx + 1) % self.capacity
  if next_write == self.read_idx {
    (self, false)
  } else {
    let buf = self.buffer
    buf[self.write_idx] = item
    (
      RingBuffer::{
        buffer: buf,
        capacity: self.capacity,
        read_idx: self.read_idx,
        write_idx: next_write,
      },
      true,
    )
  }
}

///|
pub fn[T] RingBuffer::dequeue(self : RingBuffer[T]) -> (RingBuffer[T], T?) {
  if self.read_idx == self.write_idx {
    (self, None)
  } else {
    let item = self.buffer[self.read_idx]
    let new_read = (self.read_idx + 1) % self.capacity
    (
      RingBuffer::{
        buffer: self.buffer,
        capacity: self.capacity,
        read_idx: new_read,
        write_idx: self.write_idx,
      },
      Some(item),
    )
  }
}

///|
pub fn[T] RingBuffer::peek(self : RingBuffer[T]) -> T? {
  if self.read_idx == self.write_idx {
    None
  } else {
    Some(self.buffer[self.read_idx])
  }
}

///|
pub fn[T] RingBuffer::length(self : RingBuffer[T]) -> Int {
  if self.write_idx >= self.read_idx {
    self.write_idx - self.read_idx
  } else {
    self.capacity - self.read_idx + self.write_idx
  }
}

///|
pub fn[T] RingBuffer::is_empty(self : RingBuffer[T]) -> Bool {
  self.read_idx == self.write_idx
}

///|
pub fn[T] RingBuffer::capacity(self : RingBuffer[T]) -> Int {
  self.capacity - 1
}
