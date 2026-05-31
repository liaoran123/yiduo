///|
pub enum AccessMode {
  ReadOnly
  ReadWrite
}

///|
pub enum MessagePriority {
  High
  Normal
  Low
}

///|
pub fn MessagePriority::high() -> MessagePriority {
  High
}

///|
pub fn MessagePriority::normal() -> MessagePriority {
  Normal
}

///|
pub fn MessagePriority::low() -> MessagePriority {
  Low
}

///|
pub struct SmallPayload {
  msg_type : Int
  data : Array[Byte]
}

///|
pub enum Message {
  SmallMessage(Int, Int, SmallPayload)
  MediumMessage(Int, Int, Int, Bool)
  LargeMessage(Int, Int, Int, AccessMode, Bool)
}

///|
pub fn SmallPayload::create(msg_type : Int, data : Array[Byte]) -> SmallPayload {
  SmallPayload::{ msg_type, data }
}

///|
pub fn Message::create_small(
  from : Int,
  to : Int,
  payload : SmallPayload,
) -> Message {
  SmallMessage(from, to, payload)
}

///|
pub fn Message::medium(
  from : Int,
  to : Int,
  handle : Int,
  auto_free : Bool,
) -> Message {
  MediumMessage(from, to, handle, auto_free)
}

///|
pub fn Message::large(
  from : Int,
  to : Int,
  handle : Int,
  access_mode : AccessMode,
  auto_free : Bool,
) -> Message {
  LargeMessage(from, to, handle, access_mode, auto_free)
}

///|
pub fn Message::create_medium(
  from : Int,
  to : Int,
  handle : Int,
  auto_free : Bool,
  mem_manager : MemoryManager,
) -> (MemoryManager, Message?) {
  let info_opt = MemoryManager::get_handle_info(mem_manager, handle)
  match info_opt {
    None => (mem_manager, None)
    Some(info) =>
      if info.owner_id != from {
        (mem_manager, None)
      } else {
        (mem_manager, Some(MediumMessage(from, to, handle, auto_free)))
      }
  }
}

///|
pub fn Message::create_large(
  from : Int,
  to : Int,
  handle : Int,
  access_mode : AccessMode,
  auto_free : Bool,
  mem_manager : MemoryManager,
) -> (MemoryManager, Message?) {
  let info_opt = MemoryManager::get_handle_info(mem_manager, handle)
  match info_opt {
    None => (mem_manager, None)
    Some(info) =>
      if info.owner_id != from {
        (mem_manager, None)
      } else {
        (
          mem_manager,
          Some(LargeMessage(from, to, handle, access_mode, auto_free)),
        )
      }
  }
}

///|
pub fn Message::on_processed(
  self : Message,
  receiver_id : Int,
  mem_manager : MemoryManager,
) -> MemoryManager {
  match self {
    MediumMessage(_, to, handle, auto_free) =>
      if auto_free {
        let (new_mgr2, _) = MemoryManager::free_handle(mem_manager, handle, to)
        new_mgr2
      } else {
        mem_manager
      }
    LargeMessage(_, to, handle, _, auto_free) =>
      if auto_free {
        let (new_mgr2, _) = MemoryManager::free_handle(mem_manager, handle, to)
        new_mgr2
      } else {
        mem_manager
      }
    SmallMessage(_, _, _) => mem_manager
  }
}
