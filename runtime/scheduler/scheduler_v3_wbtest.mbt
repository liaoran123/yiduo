///|
/// 端到端验证测试：基础消息流（V3）
test "v3_e2e_basic_message_flow" {
  let s = SchedulerV3::create()
  let info_a = ComponentInfo::create_simple(
    "comp-a",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let info_b = ComponentInfo::create_simple(
    "comp-b",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let (s1, _id_a) = s.register(info_a)
  let (s2, id_b) = s1.register(info_b)

  let payload = @core.SmallPayload::create(42, [])
  let (s3, ok) = s2.send_small(0, id_b, payload, @core.MessagePriority::high())

  assert_eq(ok, true, msg="V3 消息应成功入队")
  assert_eq(s3.high_queue_length(), 1, msg="V3 高优队列应有 1 条消息")

  let s4 = s3.process_one()
  assert_eq(s4.high_queue_length(), 0, msg="V3 处理后高优队列应为空")
}

///|
/// 端到端验证：优先级顺序（V3）
test "v3_e2e_priority_ordering" {
  let s = SchedulerV3::create()
  let info = ComponentInfo::create_simple(
    "target",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let (s1, target_id) = s.register(info)

  let payload = @core.SmallPayload::create(0, [])
  let (s2, _) = s1.send_small(
    0,
    target_id,
    payload,
    @core.MessagePriority::low(),
  )
  let (s3, _) = s2.send_small(
    0,
    target_id,
    payload,
    @core.MessagePriority::normal(),
  )
  let (s4, _) = s3.send_small(
    0,
    target_id,
    payload,
    @core.MessagePriority::high(),
  )

  assert_eq(s4.low_queue_length(), 1, msg="V3 低优队列应有 1 条")
  assert_eq(s4.normal_queue_length(), 1, msg="V3 普通队列应有 1 条")
  assert_eq(s4.high_queue_length(), 1, msg="V3 高优队列应有 1 条")

  let s5 = s4.process_one()
  assert_eq(s5.high_queue_length(), 0, msg="V3 高优先被处理")
  assert_eq(s5.normal_queue_length(), 1, msg="V3 普通队列不变")
  assert_eq(s5.low_queue_length(), 1, msg="V3 低优队列不变")
}

///|
/// 端到端验证：组件亲和度追踪（V3）
test "v3_e2e_affinity_tracking" {
  let s = SchedulerV3::create()
  let info_a = ComponentInfo::create_simple(
    "comp-a",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let (s1, id_a) = s.register(info_a)
  assert_eq(id_a, 1, msg="第一个组件应获得 ID 1")
  match s1.components[id_a] {
    Some(c) => assert_eq(c.name, "comp-a", msg="组件名称应正确")
    None => assert_eq(0, 1, msg="组件应存在")
  }
}

///|
/// 端到端验证：批处理（V3 自适应）
test "v3_e2e_batch_processing" {
  let s = SchedulerV3::create_with_config(
    @core.MemoryManager::create(
      @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64)),
      64,
    ),
    4,
    32,
  )
  let info = ComponentInfo::create_simple(
    "target",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let (s1, target_id) = s.register(info)
  let s1 = s1.set_debug_log(false)

  let payload = @core.SmallPayload::create(0, [])
  let mut s2 = s1
  let mut i = 0
  while i < 4 {
    let (s_new, _) = s2.send_small(
      0,
      target_id,
      payload,
      @core.MessagePriority::high(),
    )
    s2 = s_new
    i = i + 1
  }

  assert_eq(s2.high_queue_length(), 4, msg="V3 高优队列应有 4 条消息")

  let s3 = s2.process_batch()
  assert_eq(
    s3.high_queue_length(),
    0,
    msg="V3 批处理后高优队列应清空",
  )
  assert_eq(s3.get_adaptive_stats() != "", true, msg="V3 应产生统计报告")
}

///|
/// 端到端验证：完整调度循环（V3）
test "v3_e2e_run_loop" {
  let s = SchedulerV3::create_with_config(
    @core.MemoryManager::create(
      @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64)),
      64,
    ),
    2,
    32,
  )
  let info = ComponentInfo::create_simple(
    "target",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let (s1, target_id) = s.register(info)
  let s1 = s1.set_debug_log(false)

  let payload = @core.SmallPayload::create(0, [])
  let mut s2 = s1
  let mut i = 0
  while i < 4 {
    let (s_new, _) = s2.send_small(
      0,
      target_id,
      payload,
      @core.MessagePriority::normal(),
    )
    s2 = s_new
    i = i + 1
  }

  assert_eq(
    s2.normal_queue_length(),
    4,
    msg="V3 普通队列应有 4 条消息",
  )

  let s3 = s2.run_loop(2)
  assert_eq(s3.normal_queue_length(), 0, msg="V3 所有消息应被处理")
}

///|
/// 端到端验证：直连通道通信
test "v3_e2e_direct_channel" {
  let s = SchedulerV3::create()
  let info_a = ComponentInfo::create_simple(
    "comp-a",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let info_b = ComponentInfo::create_simple(
    "comp-b",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let (s1, id_a) = s.register(info_a)
  let (s2, id_b) = s1.register(info_b)

  // 手动建立直连通道
  let (s3, ch_id) = s2.create_direct_channel(id_a, id_b, 64)

  // 通过直连通道发送
  let payload = @core.SmallPayload::create(1, [])
  let (s4, ok) = s3.send_small(
    id_a,
    id_b,
    payload,
    @core.MessagePriority::high(),
  )

  assert_eq(ok, true, msg="直连通道消息应发送成功")
  // 直连通道消息应绕开队列
  assert_eq(
    s4.high_queue_length(),
    0,
    msg="直连消息不应出现在队列中",
  )

  // 查找通道
  let found = s4.find_channel(id_a, id_b)
  let found_valid = match found {
    Some(_) => true
    None => false
  }
  assert_eq(found_valid, true, msg="应能查找到直连通道")

  // 获取通道统计
  let (a_count, b_count, _dropped) = s4.get_channel_stats(ch_id)
  assert_eq(a_count + b_count, 1, msg="直连通道应统计到 1 条消息")
}

///|
/// 端到端验证：热路径自动检测
test "v3_e2e_hot_path_detection" {
  let s = SchedulerV3::create()
  let s = s.set_debug_log(false)
  let info_a = ComponentInfo::create_simple(
    "comp-a",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let info_b = ComponentInfo::create_simple(
    "comp-b",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let (s1, id_a) = s.register(info_a)
  let (s2, id_b) = s1.register(info_b)

  // 设置低阈值，快速触发
  let s2 = SchedulerV3::{
    high_queue: s2.high_queue,
    normal_queue: s2.normal_queue,
    low_queue: s2.low_queue,
    pool: s2.pool,
    mem_manager: s2.mem_manager,
    components: s2.components,
    max_components: s2.max_components,
    is_running: s2.is_running,
    batch_size: s2.batch_size,
    handlers: s2.handlers,
    wasm_runtime: s2.wasm_runtime,
    channel_mgr: s2.channel_mgr,
    adaptive_ctx: s2.adaptive_ctx,
    hot_threshold: 3,
    debug_log: s2.debug_log,
  }

  let payload = @core.SmallPayload::create(0, [])
  let mut s3 = s2
  let mut i = 0
  while i < 5 {
    let (s_new, _) = s3.send_small(
      id_a,
      id_b,
      payload,
      @core.MessagePriority::normal(),
    )
    s3 = s_new
    i = i + 1
  }

  // 前 3 次触发阈值：第 3 次触发时通道立即创建，该消息走直连
  // 所以队列中应有 2 条（第 1~2 次发送走队列）
  assert_eq(
    s3.normal_queue_length(),
    2,
    msg="热路径前 2 条消息走队列",
  )

  let found = s3.find_channel(id_a, id_b)
  let has_channel = match found {
    Some(_) => true
    None => false
  }
  assert_eq(has_channel, true, msg="热路径自动检测应建立直连通道")
}

///|
/// SPSCBuffer 批量入队出队性能验证
test "spsc_batch_operations" {
  let buf = @core.SPSCBuffer::create(64, 0)
  // 入队 10 个元素
  let mut s = buf
  let mut i = 0
  while i < 10 {
    let (new_s, _ok) = s.enqueue(i)
    s = new_s
    i = i + 1
  }
  assert_eq(s.len(), 10, msg="SPSCBuffer 应有 10 个元素")

  // 批量出队 5 个
  let (s2, items) = s.dequeue_batch(5)
  assert_eq(items.length(), 5, msg="应出队 5 个元素")
  assert_eq(s2.len(), 5, msg="剩余 5 个元素")

  // 再全部出队
  let (s3, items2) = s2.dequeue_batch(10)
  assert_eq(items2.length(), 5, msg="应出队剩余 5 个元素")
  assert_eq(s3.is_empty(), true, msg="SPSCBuffer 应为空")
}

///|
/// 容量自动对齐到 2^n
test "spsc_capacity_alignment" {
  let buf = @core.SPSCBuffer::create(10, 0)
  // 10 应对齐到 16
  assert_eq(buf.capacity(), 16, msg="SPSCBuffer 容量应为 16（2^4）")
  assert_eq(buf.mask, 15, msg="mask 应为 capacity-1")
}
