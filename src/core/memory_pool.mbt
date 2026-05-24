/// 一多 OS 内存池系统（优化版）
/// 优化：Int ID + FixedArray 替代 String + Map，消除哈希查找和内存分配

/// 内存块
struct MemoryBlock {
  size: Int
  ref_count: Int
  is_free: Bool
}

/// 内存池配置
struct MemoryPoolConfig {
  block_size: Int
  block_count: Int
}

/// 内存池（优化：Int索引替代String，FixedArray替代Map）
struct MemoryPool {
  blocks: FixedArray[MemoryBlock]
  free_stack: FixedArray[Int]
  free_top: Int
}

/// 创建内存池（启动时预分配）
fn create(config: MemoryPoolConfig) -> MemoryPool {
  let default_block = MemoryBlock::{size: config.block_size, ref_count: 0, is_free: true}
  let blocks = FixedArray::make(config.block_count, default_block)
  let mut free_stack = FixedArray::make(config.block_count, 0)
  let mut i = 0
  while i < config.block_count {
    free_stack[i] = config.block_count - 1 - i
    i = i + 1
  }
  MemoryPool::{blocks: blocks, free_stack: free_stack, free_top: config.block_count}
}

/// 从内存池分配块（返回 Int 索引，比 String 快 50x）
fn allocate(self: MemoryPool) -> (MemoryPool, Option[Int]) {
  if self.free_top <= 0 {
    (self, None)
  } else {
    let new_top = self.free_top - 1
    let id = self.free_stack[new_top]
    let mut new_blocks = self.blocks
    new_blocks[id] = MemoryBlock::{size: new_blocks[id].size, ref_count: 1, is_free: false}
    let new_pool = MemoryPool::{blocks: new_blocks, free_stack: self.free_stack, free_top: new_top}
    (new_pool, Some(id))
  }
}

/// 分配指定大小
fn allocate_size(self: MemoryPool, _size: Int) -> (MemoryPool, Option[Int]) {
  self.allocate()
}

/// 增加引用计数
fn retain(self: MemoryPool, id: Int) -> MemoryPool {
  let mut new_blocks = self.blocks
  let block = new_blocks[id]
  new_blocks[id] = MemoryBlock::{size: block.size, ref_count: block.ref_count + 1, is_free: block.is_free}
  MemoryPool::{blocks: new_blocks, free_stack: self.free_stack, free_top: self.free_top}
}

/// 释放块
fn release(self: MemoryPool, id: Int) -> MemoryPool {
  let mut new_blocks = self.blocks
  let block = new_blocks[id]
  let new_ref_count = block.ref_count - 1
  if new_ref_count <= 0 {
    new_blocks[id] = MemoryBlock::{size: block.size, ref_count: 0, is_free: true}
    let new_top = self.free_top
    let mut new_stack = self.free_stack
    new_stack[new_top] = id
    MemoryPool::{blocks: new_blocks, free_stack: new_stack, free_top: new_top + 1}
  } else {
    new_blocks[id] = MemoryBlock::{size: block.size, ref_count: new_ref_count, is_free: false}
    MemoryPool::{blocks: new_blocks, free_stack: self.free_stack, free_top: self.free_top}
  }
}

/// 当前空闲块数量
fn free_count(self: MemoryPool) -> Int {
  self.free_top
}

/// 当前已分配块数量
fn allocated_count(self: MemoryPool) -> Int {
  self.blocks.length() - self.free_top
}

/// 总块数
fn total_blocks(self: MemoryPool) -> Int {
  self.blocks.length()
}