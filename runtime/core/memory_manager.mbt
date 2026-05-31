///|
// L2 层：组件间零拷贝传递（组件级内存管理新模型的 owned-buffer 层）
// 当前实现：全局句柄表 + 所有权追踪
// 未来演进方向：
//   L1（组件内 Arena）→ 每个 Wasm 组件的线性内存内部自治，由 dlmalloc/wee_alloc 实现
//   L2（组件间句柄）→ 当前 MemoryManager 简化为纯粹的句柄协调层 ← 现在在此
//   L3（组件销毁回收）→ component_manager 接管，MemoryManager 提供句柄泄漏检测
pub struct HandleInfo {
  owner_id : Int
  ref_count : Int
  size : Int
  is_valid : Bool
  mem_id : Int
}

///|
pub struct MemoryManager {
  pool : MemoryPool
  max_handles : Int
  handle_table : FixedArray[HandleInfo?]
  free_stack : FixedArray[Int]
  free_top : Int
  next_handle_id : Int
}

///|
pub fn MemoryManager::create(
  pool : MemoryPool,
  max_handles : Int,
) -> MemoryManager {
  let dummy_info : HandleInfo? = None
  let handle_table = FixedArray::make(max_handles, dummy_info)
  let free_stack = FixedArray::make(max_handles, 0)

  MemoryManager::{
    pool,
    max_handles,
    handle_table,
    free_stack,
    free_top: 0,
    next_handle_id: 1,
  }
}

///|
fn MemoryManager::allocate_handle_id(
  self : MemoryManager,
  _mem_id : Int,
) -> (MemoryManager, Int) {
  if self.free_top > 0 {
    let new_top = self.free_top - 1
    let id = self.free_stack[new_top]
    let new_self = MemoryManager::{
      pool: self.pool,
      max_handles: self.max_handles,
      handle_table: self.handle_table,
      free_stack: self.free_stack,
      free_top: new_top,
      next_handle_id: self.next_handle_id,
    }
    (new_self, id)
  } else if self.next_handle_id < self.max_handles {
    let new_id = self.next_handle_id
    let new_self = MemoryManager::{
      pool: self.pool,
      max_handles: self.max_handles,
      handle_table: self.handle_table,
      free_stack: self.free_stack,
      free_top: self.free_top,
      next_handle_id: self.next_handle_id + 1,
    }
    (new_self, new_id)
  } else {
    (self, -1)
  }
}

///|
pub fn MemoryManager::allocate_handle(
  self : MemoryManager,
  owner_id : Int,
  size : Int,
) -> (MemoryManager, Int?) {
  let (new_pool, mem_id_opt) = MemoryPool::allocate(self.pool)

  match mem_id_opt {
    None => (self, None)
    Some(mem_id) => {
      let (new_self1, handle_id) = self.allocate_handle_id(mem_id)
      if handle_id == -1 {
        let pool_released = MemoryPool::release(new_pool, mem_id)
        let new_self2 = MemoryManager::{
          pool: pool_released,
          max_handles: new_self1.max_handles,
          handle_table: new_self1.handle_table,
          free_stack: new_self1.free_stack,
          free_top: new_self1.free_top,
          next_handle_id: new_self1.next_handle_id,
        }
        return (new_self2, None)
      }

      let info = HandleInfo::{
        owner_id,
        ref_count: 1,
        size,
        is_valid: true,
        mem_id,
      }

      let new_table = new_self1.handle_table
      new_table[handle_id] = Some(info)

      let new_self3 = MemoryManager::{
        pool: new_pool,
        max_handles: new_self1.max_handles,
        handle_table: new_table,
        free_stack: new_self1.free_stack,
        free_top: new_self1.free_top,
        next_handle_id: new_self1.next_handle_id,
      }

      (new_self3, Some(handle_id))
    }
  }
}

///|
pub fn MemoryManager::retain_handle(
  self : MemoryManager,
  handle_id : Int,
  caller_id : Int,
) -> (MemoryManager, Bool) {
  match self.handle_table[handle_id] {
    None => (self, false)
    Some(info) =>
      if !info.is_valid {
        (self, false)
      } else {
        let new_info = HandleInfo::{
          owner_id: info.owner_id,
          ref_count: info.ref_count + 1,
          size: info.size,
          is_valid: info.is_valid,
          mem_id: info.mem_id,
        }

        let new_table = self.handle_table
        new_table[handle_id] = Some(new_info)

        let new_self = MemoryManager::{
          pool: self.pool,
          max_handles: self.max_handles,
          handle_table: new_table,
          free_stack: self.free_stack,
          free_top: self.free_top,
          next_handle_id: self.next_handle_id,
        }

        (new_self, true)
      }
  }
}

///|
pub fn MemoryManager::free_handle(
  self : MemoryManager,
  handle_id : Int,
  caller_id : Int,
) -> (MemoryManager, Bool) {
  match self.handle_table[handle_id] {
    None => (self, false)
    Some(info) =>
      if !info.is_valid {
        (self, false)
      } else if info.owner_id != caller_id {
        (self, false)
      } else {
        let new_ref_count = info.ref_count - 1

        if new_ref_count <= 0 {
          let new_info = HandleInfo::{
            owner_id: info.owner_id,
            ref_count: 0,
            size: info.size,
            is_valid: false,
            mem_id: info.mem_id,
          }

          let new_table = self.handle_table
          new_table[handle_id] = Some(new_info)

          let new_pool = MemoryPool::release(self.pool, info.mem_id)

          let new_stack = self.free_stack
          let new_top = self.free_top
          new_stack[new_top] = handle_id

          let new_self1 = MemoryManager::{
            pool: new_pool,
            max_handles: self.max_handles,
            handle_table: new_table,
            free_stack: new_stack,
            free_top: new_top + 1,
            next_handle_id: self.next_handle_id,
          }

          (new_self1, true)
        } else {
          let new_info = HandleInfo::{
            owner_id: info.owner_id,
            ref_count: new_ref_count,
            size: info.size,
            is_valid: info.is_valid,
            mem_id: info.mem_id,
          }

          let new_table = self.handle_table
          new_table[handle_id] = Some(new_info)

          let new_self = MemoryManager::{
            pool: self.pool,
            max_handles: self.max_handles,
            handle_table: new_table,
            free_stack: self.free_stack,
            free_top: self.free_top,
            next_handle_id: self.next_handle_id,
          }

          (new_self, true)
        }
      }
  }
}

///|
pub fn MemoryManager::transfer_ownership(
  self : MemoryManager,
  handle_id : Int,
  from_id : Int,
  to_id : Int,
) -> (MemoryManager, Bool) {
  match self.handle_table[handle_id] {
    None => (self, false)
    Some(info) =>
      if !info.is_valid {
        (self, false)
      } else if info.owner_id != from_id {
        (self, false)
      } else {
        let new_info = HandleInfo::{
          owner_id: to_id,
          ref_count: info.ref_count,
          size: info.size,
          is_valid: info.is_valid,
          mem_id: info.mem_id,
        }

        let new_table = self.handle_table
        new_table[handle_id] = Some(new_info)

        let new_self = MemoryManager::{
          pool: self.pool,
          max_handles: self.max_handles,
          handle_table: new_table,
          free_stack: self.free_stack,
          free_top: self.free_top,
          next_handle_id: self.next_handle_id,
        }

        (new_self, true)
      }
  }
}

///|
pub fn MemoryManager::get_handle_info(
  self : MemoryManager,
  handle_id : Int,
) -> HandleInfo? {
  self.handle_table[handle_id]
}

///|
pub fn MemoryManager::get_stats(self : MemoryManager) -> (Int, Int, Int) {
  let mut active_handles = 0
  let mut i = 0
  while i < self.max_handles {
    match self.handle_table[i] {
      Some(info) => if info.is_valid { active_handles = active_handles + 1 }
      None => ()
    }
    i = i + 1
  }

  (MemoryPool::allocated_count(self.pool), active_handles, self.free_top)
}

///|
pub fn MemoryManager::print_status(self : MemoryManager) -> Unit {
  let (allocated_mem, active_handles, free_cnt) = self.get_stats()
  println("")
  println("=== 内存管理器状态 ===")
  println("已分配内存块: " + allocated_mem.to_string())
  println("活跃句柄数: " + active_handles.to_string())
  println("可复用句柄ID: " + free_cnt.to_string())
  println("")
}
