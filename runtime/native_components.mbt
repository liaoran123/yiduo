///|
/// 真实 Native 组件：计数器
/// 统计收到的消息数量，支持查询
pub struct CounterComponent {
  handler : @component.NativeMessageHandler
  get_count : () -> Int
  label : String
}

///|
pub fn CounterComponent::create(label : String) -> CounterComponent {
  let mut count = 0
  let handler : @component.NativeMessageHandler = fn(
    _comp_id : Int,
    _from_id : Int,
    _payload : @core.SmallPayload,
  ) {
    count = count + 1
  }
  let get_count = fn() -> Int { count }
  CounterComponent::{ handler, get_count, label }
}

///|
/// 真实 Native 组件：累加器
/// 从消息 payload 中提取值并累加
pub struct AccumulatorComponent {
  handler : @component.NativeMessageHandler
  get_total : () -> Int
  label : String
}

///|
pub fn AccumulatorComponent::create(label : String) -> AccumulatorComponent {
  let mut total = 0
  let handler : @component.NativeMessageHandler = fn(
    _comp_id : Int,
    _from_id : Int,
    payload : @core.SmallPayload,
  ) {
    total = total + payload.msg_type
  }
  let get_total = fn() -> Int { total }
  AccumulatorComponent::{ handler, get_total, label }
}

///|
/// 创建计数器组件的 ComponentInfo
pub fn CounterComponent::create_component_info(
  self : CounterComponent,
  comp_type : @component.ComponentType,
) -> @scheduler.ComponentInfo {
  @scheduler.ComponentInfo::create_simple(
    self.label,
    comp_type,
    @scheduler.ComponentStatus::created(),
  )
}

///|
/// 创建累加器组件的 ComponentInfo
pub fn AccumulatorComponent::create_component_info(
  self : AccumulatorComponent,
  comp_type : @component.ComponentType,
) -> @scheduler.ComponentInfo {
  @scheduler.ComponentInfo::create_simple(
    self.label,
    comp_type,
    @scheduler.ComponentStatus::created(),
  )
}
