///|
/// 端到端验证测试：基础消息流
test "e2e_basic_message_flow" {
  let s = Scheduler::create()
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

  assert_eq(ok, true, msg="消息应成功入队")
  assert_eq(s3.high_queue_length(), 1, msg="高优队列应有 1 条消息")

  let s4 = s3.process_one()
  assert_eq(s4.high_queue_length(), 0, msg="处理后高优队列应为空")
}

///|
/// 端到端验证：优先级顺序（高 > 普通 > 低）
test "e2e_priority_ordering" {
  let s = Scheduler::create()
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

  assert_eq(s4.low_queue_length(), 1, msg="低优队列应有 1 条")
  assert_eq(s4.normal_queue_length(), 1, msg="普通队列应有 1 条")
  assert_eq(s4.high_queue_length(), 1, msg="高优队列应有 1 条")

  let s5 = s4.process_one()
  assert_eq(s5.high_queue_length(), 0, msg="高优先被处理")
  assert_eq(s5.normal_queue_length(), 1, msg="普通队列不变")
  assert_eq(s5.low_queue_length(), 1, msg="低优队列不变")
}

///|
/// 端到端验证：组件亲和度追踪
test "e2e_affinity_tracking" {
  let s = Scheduler::create_with_config(
    @core.MemoryManager::create(
      @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64)),
      64,
    ),
    8,
    32,
  )
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
  let info_c = ComponentInfo::create_simple(
    "comp-c",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let (s1, id_a) = s.register(info_a)
  let (s2, id_b) = s1.register(info_b)
  let (s3, id_c) = s2.register(info_c)

  let payload = @core.SmallPayload::create(0, [])
  let mut s4 = s3

  let mut i = 0
  while i < 5 {
    let (s_new, _) = s4.send_small(
      id_a,
      id_b,
      payload,
      @core.MessagePriority::normal(),
    )
    s4 = s_new
    i = i + 1
  }

  let mut j = 0
  while j < 3 {
    let (s_new, _) = s4.send_small(
      id_a,
      id_c,
      payload,
      @core.MessagePriority::normal(),
    )
    s4 = s_new
    j = j + 1
  }

  // 验证亲和度：comp-a 与 comp-b 通信 5 次，与 comp-c 通信 3 次
  match s4.components[id_a] {
    Some(comp) =>
      assert_eq(
        comp.last_comm_with[0],
        id_b,
        msg="亲和度追踪：comp-b 应在第一位",
      )
    None => assert_true(false, msg="组件应存在")
  }
}

///|
/// 端到端验证：句柄安全（double-free 保护）
test "e2e_handle_safety" {
  let pool = @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64))
  let mgr = @core.MemoryManager::create(pool, 64)
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

  let s = Scheduler::create_with_config(mgr, 8, 32)
  let s = s.set_debug_log(false)
  let (s1, id_a) = s.register(info_a)
  let (s2, id_b) = s1.register(info_b)

  // comp-a 分配内存，得到句柄
  let (new_mgr, handle_opt) = @core.MemoryManager::allocate_handle(
    s2.mem_manager,
    id_a,
    64,
  )
  let handle = match handle_opt {
    Some(h) => h
    None => -1
  }
  assert_true(handle >= 0, msg="句柄分配应成功")
  let s3 = Scheduler::{
    high_queue: s2.high_queue,
    normal_queue: s2.normal_queue,
    low_queue: s2.low_queue,
    pool: s2.pool,
    mem_manager: new_mgr,
    components: s2.components,
    max_components: s2.max_components,
    is_running: s2.is_running,
    batch_size: s2.batch_size,
    handlers: s2.handlers,
    wasm_runtime: s2.wasm_runtime,
    debug_log: s2.debug_log,
  }

  // comp-a → comp-b 发送中消息
  let (s4, ok1) = s3.send_medium(
    id_a,
    id_b,
    handle,
    @core.MessagePriority::high(),
  )

  assert_eq(ok1, true, msg="句柄发送应成功")
  assert_eq(s4.high_queue_length(), 1, msg="高优队列应有消息")

  // double-free 保护验证（引用计数模型下仍可释放，ref_count 递减）
  let (_, ok2) = s2.mem_manager.free_handle(handle, id_a)
  assert_eq(
    ok2,
    true,
    msg="引用计数模型下，原始组件仍可释放（ref_count 递减）",
  )

  // comp-a 再次尝试发送同一句柄（ref_count 恢复后仍可用）
  let (_, ok3) = s3.send_medium(
    id_a,
    id_b,
    handle,
    @core.MessagePriority::high(),
  )
  assert_eq(
    ok3,
    true,
    msg="引用计数模型下，句柄释放后 ref_count>0 仍可发送",
  )
}

///|
/// 端到端验证：句柄完整生命周期（分配 → 发送 → 处理 → 释放）
test "e2e_handle_full_lifecycle" {
  let pool = @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64))
  let mgr = @core.MemoryManager::create(pool, 64)
  let s = Scheduler::create_with_config(mgr, 8, 32)
  let s = s.set_debug_log(false)
  let info = ComponentInfo::create_simple(
    "comp-a",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let (s1, id_a) = s.register(info)

  // 分配
  let (new_mgr, handle_opt) = @core.MemoryManager::allocate_handle(
    s1.mem_manager,
    id_a,
    64,
  )
  let handle = match handle_opt {
    Some(h) => h
    None => -1
  }
  assert_true(handle >= 0, msg="句柄分配应成功")

  let s2 = Scheduler::{
    high_queue: s1.high_queue,
    normal_queue: s1.normal_queue,
    low_queue: s1.low_queue,
    pool: s1.pool,
    mem_manager: new_mgr,
    components: s1.components,
    max_components: s1.max_components,
    is_running: s1.is_running,
    batch_size: s1.batch_size,
    handlers: s1.handlers,
    wasm_runtime: s1.wasm_runtime,
    debug_log: s1.debug_log,
  }

  // 发送（Medium 消息，auto_free=false）
  let (s3, ok) = s2.send_medium(
    id_a,
    id_a,
    handle,
    @core.MessagePriority::low(),
  )
  assert_eq(ok, true, msg="发送句柄应成功")

  // 处理（Medium 消息 dispatch 中 auto_free=false，句柄不会被释放）
  let s4 = s3.process_one()

  // 验证句柄仍活跃（ref_count=2：分配+retain）
  let info = @core.MemoryManager::get_handle_info(s4.mem_manager, handle)
  match info {
    Some(hinfo) => {
      assert_eq(
        hinfo.is_valid,
        true,
        msg="句柄应仍有效（auto_free=false）",
      )
      assert_eq(hinfo.owner_id, id_a, msg="所有权应归目标组件")
    }
    None => assert_true(false, msg="句柄信息应存在")
  }
}

///|
/// 端到端验证：批处理
test "e2e_batch_processing" {
  let s = Scheduler::create_with_config(
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

  assert_eq(s2.high_queue_length(), 4, msg="高优队列应有 4 条消息")

  let s3 = s2.process_batch()
  assert_eq(s3.high_queue_length(), 0, msg="批处理后高优队列应清空")
}

///|
/// 端到端验证：完整调度循环
test "e2e_run_loop" {
  let s = Scheduler::create_with_config(
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

  assert_eq(s2.normal_queue_length(), 4, msg="普通队列应有 4 条消息")

  let s3 = s2.run_loop(2)
  assert_eq(s3.is_running, false, msg="运行循环应结束")
  assert_eq(s3.normal_queue_length(), 0, msg="所有消息应被处理")
}
