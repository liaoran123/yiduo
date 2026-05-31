/// 一多 OS Native 组件处理器注册表
/// 管理 Native 组件的消息处理函数注册与调用

///|
/// ==================== 处理器注册表 ====================
pub struct HandlerRegistry {
  handlers : FixedArray[@component.NativeMessageHandler?]
  max_handlers : Int
}

///|
/// 创建处理器注册表
pub fn HandlerRegistry::create(max_handlers : Int) -> HandlerRegistry {
  HandlerRegistry::{
    handlers: FixedArray::make(max_handlers, None),
    max_handlers,
  }
}

///|
/// 注册组件处理器
pub fn HandlerRegistry::register_handler(
  self : HandlerRegistry,
  comp_id : Int,
  handler : @component.NativeMessageHandler,
) -> HandlerRegistry {
  if comp_id < 0 || comp_id >= self.max_handlers {
    return self
  }
  let new_handlers = self.handlers
  new_handlers[comp_id] = Some(handler)
  HandlerRegistry::{ handlers: new_handlers, max_handlers: self.max_handlers }
}

///|
/// 获取组件处理器
pub fn HandlerRegistry::get_handler(
  self : HandlerRegistry,
  comp_id : Int,
) -> @component.NativeMessageHandler? {
  if comp_id < 0 || comp_id >= self.max_handlers {
    return None
  }
  self.handlers[comp_id]
}

///|
/// 调用组件处理器
pub fn HandlerRegistry::invoke(
  self : HandlerRegistry,
  comp_id : Int,
  from_id : Int,
  payload : @core.SmallPayload,
) -> Bool {
  match self.get_handler(comp_id) {
    Some(handler) => {
      handler(comp_id, from_id, payload)
      true
    }
    None => false
  }
}

///|
/// 解注册组件处理器
pub fn HandlerRegistry::unregister(
  self : HandlerRegistry,
  comp_id : Int,
) -> HandlerRegistry {
  if comp_id < 0 || comp_id >= self.max_handlers {
    return self
  }
  let new_handlers = self.handlers
  new_handlers[comp_id] = None
  HandlerRegistry::{ handlers: new_handlers, max_handlers: self.max_handlers }
}
