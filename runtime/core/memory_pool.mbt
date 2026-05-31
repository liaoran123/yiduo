///|
pub struct MemoryBlock {
  size : Int
  ref_count : Int
  is_free : Bool
}

///|
pub struct MemoryPoolConfig {
  block_size : Int
  block_count : Int
}

///|
pub fn MemoryPoolConfig::create(
  block_size : Int,
  block_count : Int,
) -> MemoryPoolConfig {
  MemoryPoolConfig::{ block_size, block_count }
}

///|
pub struct MemoryPool {
  blocks : FixedArray[MemoryBlock]
  free_stack : FixedArray[Int]
  free_top : Int
  config : MemoryPoolConfig
}

///|
pub fn MemoryPool::create(config : MemoryPoolConfig) -> MemoryPool {
  let default_block = MemoryBlock::{
    size: config.block_size,
    ref_count: 0,
    is_free: true,
  }
  let blocks = FixedArray::make(config.block_count, default_block)
  let free_stack = FixedArray::make(config.block_count, 0)
  let mut i = 0
  while i < config.block_count {
    free_stack[i] = config.block_count - 1 - i
    i = i + 1
  }
  MemoryPool::{ blocks, free_stack, free_top: config.block_count, config }
}

///|
pub fn MemoryPool::allocate(self : MemoryPool) -> (MemoryPool, Int?) {
  if self.free_top <= 0 {
    (self, None)
  } else {
    let new_top = self.free_top - 1
    let id = self.free_stack[new_top]
    let new_blocks = self.blocks
    new_blocks[id] = MemoryBlock::{
      size: new_blocks[id].size,
      ref_count: 1,
      is_free: false,
    }
    let new_pool = MemoryPool::{
      blocks: new_blocks,
      free_stack: self.free_stack,
      free_top: new_top,
      config: self.config,
    }
    (new_pool, Some(id))
  }
}

///|
pub fn MemoryPool::allocate_size(
  self : MemoryPool,
  _size : Int,
) -> (MemoryPool, Int?) {
  self.allocate()
}

///|
pub fn MemoryPool::retain(self : MemoryPool, id : Int) -> MemoryPool {
  let new_blocks = self.blocks
  let block = new_blocks[id]
  new_blocks[id] = MemoryBlock::{
    size: block.size,
    ref_count: block.ref_count + 1,
    is_free: block.is_free,
  }
  MemoryPool::{
    blocks: new_blocks,
    free_stack: self.free_stack,
    free_top: self.free_top,
    config: self.config,
  }
}

///|
pub fn MemoryPool::release(self : MemoryPool, id : Int) -> MemoryPool {
  let new_blocks = self.blocks
  let block = new_blocks[id]
  let new_ref_count = block.ref_count - 1
  if new_ref_count <= 0 {
    new_blocks[id] = MemoryBlock::{
      size: block.size,
      ref_count: 0,
      is_free: true,
    }
    let new_top = self.free_top
    let new_stack = self.free_stack
    new_stack[new_top] = id
    MemoryPool::{
      blocks: new_blocks,
      free_stack: new_stack,
      free_top: new_top + 1,
      config: self.config,
    }
  } else {
    new_blocks[id] = MemoryBlock::{
      size: block.size,
      ref_count: new_ref_count,
      is_free: false,
    }
    MemoryPool::{
      blocks: new_blocks,
      free_stack: self.free_stack,
      free_top: self.free_top,
      config: self.config,
    }
  }
}

///|
pub fn MemoryPool::free_count(self : MemoryPool) -> Int {
  self.free_top
}

///|
pub fn MemoryPool::allocated_count(self : MemoryPool) -> Int {
  self.free_stack.length() - self.free_top
}

///|
pub fn MemoryPool::total_blocks(self : MemoryPool) -> Int {
  self.blocks.length()
}
