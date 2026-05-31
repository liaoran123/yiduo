/// 双模运行时白盒测试
/// 验证 Native/Wasm 组件的注册、调度、消息处理全链路

///|
/// 测试：HandlerRegistry 处理器注册与调用
test "dual_native_handler_registration" {
  let reg = HandlerRegistry::create(32)

  let mut call_count = 0
  let handler : @component.NativeMessageHandler = fn(
    _comp_id : Int,
    _from_id : Int,
    _payload : @core.SmallPayload,
  ) {
    call_count = call_count + 1
  }

  let reg1 = reg.register_handler(5, handler)
  let invoked = reg1.invoke(5, 0, @core.SmallPayload::create(0, []))
  assert_eq(invoked, true, msg="处理器应被成功调用")
  assert_eq(call_count, 1, msg="处理器应被执行一次")

  let invoked2 = reg1.invoke(99, 0, @core.SmallPayload::create(0, []))
  assert_eq(invoked2, false, msg="未注册的组件应返回 false")
}

///|
/// 测试：Native 组件通过 Scheduler 注册处理器并调度
test "dual_native_scheduler_handler" {
  let s = Scheduler::create()
  let info = ComponentInfo::create_simple(
    "native-handler",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let (s1, comp_id) = s.register(info)
  assert_true(comp_id >= 0, msg="组件注册应成功")

  let mut msg_count = 0
  let handler : @component.NativeMessageHandler = fn(
    _comp_id : Int,
    _from_id : Int,
    _payload : @core.SmallPayload,
  ) {
    msg_count = msg_count + 1
  }

  // 注册处理器
  let s2 = s1.register_handler(comp_id, handler)

  // 直接验证处理器已存储
  let stored_handler = s2.handlers.get_handler(comp_id)
  assert_true(stored_handler is Some(_), msg="处理器应被存储")

  // 直接通过 HandlerRegistry 调用（验证基础功能）
  let direct_invoked = s2.handlers.invoke(
    comp_id,
    0,
    @core.SmallPayload::create(0, []),
  )
  assert_eq(direct_invoked, true, msg="直接调用应成功")
  assert_eq(msg_count, 1, msg="直接调用应执行")

  // 发送消息到 Native 组件
  let payload = @core.SmallPayload::create(42, [1, 2, 3])
  let (s3, ok) = s2.send_small(
    0,
    comp_id,
    payload,
    @core.MessagePriority::high(),
  )
  assert_eq(ok, true, msg="消息发送应成功")
  assert_eq(s3.high_queue_length(), 1, msg="高优队列应有 1 条消息")

  // 验证 s3 的 handlers 链式传递
  let handler_after_send = s3.handlers.get_handler(comp_id)
  assert_true(
    handler_after_send is Some(_),
    msg="发送后处理器仍应存在",
  )

  // 处理消息（dispatch 应调用 Native 处理器）
  let s4 = s3.process_one()
  assert_eq(msg_count, 2, msg="Native 处理器应被调用（直接+调度）")
  assert_eq(s4.high_queue_length(), 0, msg="处理后队列应为空")
}

///|
/// 测试：Wasm 组件调度路径（预留接口，验证 dispatch 不会崩溃）
test "dual_wasm_component_scheduling" {
  let rt = @component.WasmRuntime::create_simulated(32)
  let s = Scheduler::create()
  let s = s.set_debug_log(false).set_wasm_runtime(rt)
  let info = ComponentInfo::create_simple(
    "wasm-worker",
    @component.ComponentType::wasm(),
    ComponentStatus::created(),
  )
  let (s1, comp_id) = s.register(info)
  assert_true(comp_id >= 0, msg="Wasm 组件注册应成功")

  // Wasm 组件不应有 Native 处理器
  let handler_check = s1.handlers.get_handler(comp_id)
  assert_true(
    handler_check is None,
    msg="Wasm 组件不应有预注册的处理器",
  )

  // 发送消息到 Wasm 组件
  let payload = @core.SmallPayload::create(0, [])
  let (s2, ok) = s1.send_small(
    0,
    comp_id,
    payload,
    @core.MessagePriority::normal(),
  )
  assert_eq(ok, true, msg="Wasm 消息发送应成功")

  // 处理消息（Wasm 路径不应崩溃）
  let _s3 = s2.process_one()
  assert_true(true, msg="Wasm 组件调度不应崩溃")
}

///|
/// 测试：混合调度（Native + Wasm 组件共存）
test "dual_hybrid_scheduling" {
  let rt = @component.WasmRuntime::create_simulated(32)
  let s = Scheduler::create()
  let s = s.set_debug_log(false).set_wasm_runtime(rt)

  // 注册 Native 组件
  let native_info = ComponentInfo::create_simple(
    "native-logger",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let (s1, native_id) = s.register(native_info)
  assert_true(native_id >= 0, msg="Native 组件注册应成功")

  // 注册 Wasm 组件
  let wasm_info = ComponentInfo::create_simple(
    "wasm-calc",
    @component.ComponentType::wasm(),
    ComponentStatus::created(),
  )
  let (s2, wasm_id) = s1.register(wasm_info)
  assert_true(wasm_id >= 0, msg="Wasm 组件注册应成功")

  // 注册 Native 处理器
  let mut native_called = false
  let handler : @component.NativeMessageHandler = fn(
    _comp_id : Int,
    _from_id : Int,
    _payload : @core.SmallPayload,
  ) {
    native_called = true
  }
  let s3 = s2.register_handler(native_id, handler)

  // 发送消息到 Native 组件
  let p1 = @core.SmallPayload::create(1, [])
  let (s4, _) = s3.send_small(0, native_id, p1, @core.MessagePriority::high())

  // 发送消息到 Wasm 组件
  let p2 = @core.SmallPayload::create(2, [])
  let (s5, _) = s4.send_small(0, wasm_id, p2, @core.MessagePriority::normal())

  assert_eq(
    s5.high_queue_length(),
    1,
    msg="高优队列应有 1 条 Native 消息",
  )
  assert_eq(
    s5.normal_queue_length(),
    1,
    msg="普通队列应有 1 条 Wasm 消息",
  )

  // 处理 Native 消息
  let s6 = s5.process_one()
  assert_eq(native_called, true, msg="Native 处理器应被调用")
  assert_eq(s6.high_queue_length(), 0, msg="Native 消息应被处理")

  // 处理 Wasm 消息
  let s7 = s6.process_one()
  assert_eq(s7.normal_queue_length(), 0, msg="Wasm 消息应被处理")
  assert_eq(s7.low_queue_length(), 0, msg="低优队列应为空")
}

///|
/// 测试：组件类型枚举正确性
test "dual_component_type_enum" {
  let native_type = @component.ComponentType::native()
  let wasm_type = @component.ComponentType::wasm()
  let moonbit_type = @component.ComponentType::moonbit()

  assert_eq(
    native_type.to_string(),
    "native",
    msg="Native 类型字符串应正确",
  )
  assert_eq(wasm_type.to_string(), "wasm", msg="Wasm 类型字符串应正确")
  assert_eq(
    moonbit_type.to_string(),
    "moonbit",
    msg="MoonBit 类型字符串应正确",
  )

  assert_eq(
    native_type == @component.ComponentType::native(),
    true,
    msg="相等比较应正确",
  )
  assert_eq(native_type == wasm_type, false, msg="不同类型不相等")
}

///|
/// 测试：处理器注册表边界条件
test "dual_handler_registry_boundary" {
  let reg = HandlerRegistry::create(16)

  // 越界操作应安全返回
  let reg1 = reg.register_handler(-1, fn(_c, _f, _p) { () })
  let reg2 = reg1.register_handler(99, fn(_c, _f, _p) { () })

  let invoked_neg = reg2.invoke(-1, 0, @core.SmallPayload::create(0, []))
  assert_eq(invoked_neg, false, msg="负数 ID 应返回 false")

  let invoked_overflow = reg2.invoke(99, 0, @core.SmallPayload::create(0, []))
  assert_eq(invoked_overflow, false, msg="越界 ID 应返回 false")

  // 注册后解注册
  let handler : @component.NativeMessageHandler = fn(
    _c : Int,
    _f : Int,
    _p : @core.SmallPayload,
  ) {
    ()
  }
  let reg_a = reg.register_handler(0, handler)
  let invoked_a = reg_a.invoke(0, 0, @core.SmallPayload::create(0, []))
  assert_eq(invoked_a, true, msg="注册后应可调用")

  let reg_b = reg_a.unregister(0)
  let invoked_b = reg_b.invoke(0, 0, @core.SmallPayload::create(0, []))
  assert_eq(invoked_b, false, msg="解注册后应返回 false")
}

///|
/// 测试：Native 组件的多消息处理
test "dual_native_multiple_messages" {
  let s = Scheduler::create()
  let s = s.set_debug_log(false)
  let info = ComponentInfo::create_simple(
    "native-worker",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let (s1, comp_id) = s.register(info)

  let mut msg_count = 0
  let handler : @component.NativeMessageHandler = fn(
    _comp_id : Int,
    _from_id : Int,
    _payload : @core.SmallPayload,
  ) {
    msg_count = msg_count + 1
  }
  let s2 = s1.register_handler(comp_id, handler)

  // 发送 5 条消息
  let payload = @core.SmallPayload::create(0, [])
  let mut s3 = s2
  let mut i = 0
  while i < 5 {
    let (s_new, ok) = s3.send_small(
      0,
      comp_id,
      payload,
      @core.MessagePriority::high(),
    )
    assert_eq(
      ok,
      true,
      msg="第 " + i.to_string() + " 条消息发送应成功",
    )
    s3 = s_new
    i = i + 1
  }
  assert_eq(s3.high_queue_length(), 5, msg="高优队列应有 5 条消息")

  // 批处理所有消息
  let s4 = s3.process_batch()
  assert_eq(msg_count, 5, msg="所有 5 条消息的处理器应被调用")
  assert_eq(s4.high_queue_length(), 0, msg="处理后队列应为空")
}

///|
/// 真实 Wasm 组件测试 1：计数器（通过模拟运行时接口）
test "real_wasm_counter_component" {
  let rt = @component.WasmRuntime::create_simulated(32)
  let s = Scheduler::create()
  let s = s.set_debug_log(false).set_wasm_runtime(rt)

  // 创建 Wasm 计数器组件
  let info = ComponentInfo::create_simple(
    "wasm-counter",
    @component.ComponentType::wasm(),
    ComponentStatus::created(),
  )
  let (s1, comp_id) = s.register(info)

  let mut count = 0
  let handler : @component.NativeMessageHandler = fn(
    _comp_id : Int,
    _from_id : Int,
    _payload : @core.SmallPayload,
  ) {
    count = count + 1
  }
  let s2 = s1.register_wasm_handler(comp_id, handler)

  let payload = @core.SmallPayload::create(42, [])
  let (s3, ok1) = s2.send_small(
    0,
    comp_id,
    payload,
    @core.MessagePriority::high(),
  )
  assert_eq(ok1, true, msg="第 1 条消息发送成功")
  let (s4, ok2) = s3.send_small(
    0,
    comp_id,
    payload,
    @core.MessagePriority::high(),
  )
  assert_eq(ok2, true, msg="第 2 条消息发送成功")

  let s5 = s4.process_one()
  assert_eq(count, 1, msg="Wasm 计数器处理 1 条后计数=1")

  let s6 = s5.process_one()
  assert_eq(count, 2, msg="Wasm 计数器处理 2 条后计数=2")

  // 验证队列为空
  assert_eq(s6.high_queue_length(), 0, msg="高优队列应清空")
}

///|
/// 真实 Wasm 组件测试 2：累加器（通过模拟运行时接口）
test "real_wasm_accumulator_component" {
  let rt = @component.WasmRuntime::create_simulated(32)
  let s = Scheduler::create()
  let s = s.set_debug_log(false).set_wasm_runtime(rt)

  let info = ComponentInfo::create_simple(
    "wasm-accumulator",
    @component.ComponentType::wasm(),
    ComponentStatus::created(),
  )
  let (s1, comp_id) = s.register(info)

  let mut total = 0
  let handler : @component.NativeMessageHandler = fn(
    _comp_id : Int,
    _from_id : Int,
    payload : @core.SmallPayload,
  ) {
    total = total + payload.msg_type
  }
  let s2 = s1.register_wasm_handler(comp_id, handler)

  // 发送 3 条带不同值的消息
  let p1 = @core.SmallPayload::create(10, [])
  let (s3, ok1) = s2.send_small(0, comp_id, p1, @core.MessagePriority::normal())
  assert_eq(ok1, true, msg="消息 1 发送成功")

  let p2 = @core.SmallPayload::create(20, [])
  let (s4, ok2) = s3.send_small(0, comp_id, p2, @core.MessagePriority::normal())
  assert_eq(ok2, true, msg="消息 2 发送成功")

  let p3 = @core.SmallPayload::create(30, [])
  let (s5, ok3) = s4.send_small(0, comp_id, p3, @core.MessagePriority::normal())
  assert_eq(ok3, true, msg="消息 3 发送成功")

  // 处理所有消息
  let s6 = s5.process_batch()
  assert_eq(total, 60, msg="Wasm 累加器总和应为 10+20+30=60")
  assert_eq(s6.normal_queue_length(), 0, msg="普通队列应清空")
}

///|
/// 真实 Wasm 组件测试 3：多 Wasm 组件独立状态
test "real_wasm_multiple_components" {
  let rt = @component.WasmRuntime::create_simulated(32)
  let s = Scheduler::create()
  let s = s.set_debug_log(false).set_wasm_runtime(rt)

  let info1 = ComponentInfo::create_simple(
    "wasm-1",
    @component.ComponentType::wasm(),
    ComponentStatus::created(),
  )
  let info2 = ComponentInfo::create_simple(
    "wasm-2",
    @component.ComponentType::wasm(),
    ComponentStatus::created(),
  )
  let (s1, id1) = s.register(info1)
  let (s2, id2) = s1.register(info2)

  let mut count1 = 0
  let mut count2 = 0
  let h1 : @component.NativeMessageHandler = fn(_c, _f, _p) {
    count1 = count1 + 1
  }
  let h2 : @component.NativeMessageHandler = fn(_c, _f, _p) {
    count2 = count2 + 2
  }

  let s3 = s2.register_wasm_handler(id1, h1)
  let s4 = s3.register_wasm_handler(id2, h2)

  let payload = @core.SmallPayload::create(0, [])
  let (s5, _) = s4.send_small(0, id1, payload, @core.MessagePriority::high())
  let (s6, _) = s5.send_small(0, id2, payload, @core.MessagePriority::high())
  let (s7, _) = s6.send_small(0, id1, payload, @core.MessagePriority::high())

  let s8 = s7.process_batch()
  assert_eq(count1, 2, msg="wasm-1 收到 2 条消息")
  assert_eq(count2, 2, msg="wasm-2 收到 1 条消息，每次+2 → 总+2")
}

///|
/// 真实 Wasm 组件测试 4：混合调度 Native + Wasm 分立处理
test "real_wasm_native_hybrid" {
  let rt = @component.WasmRuntime::create_simulated(32)
  let s = Scheduler::create()
  let s = s.set_debug_log(false).set_wasm_runtime(rt)

  let native_info = ComponentInfo::create_simple(
    "native-acc",
    @component.ComponentType::native(),
    ComponentStatus::created(),
  )
  let wasm_info = ComponentInfo::create_simple(
    "wasm-acc",
    @component.ComponentType::wasm(),
    ComponentStatus::created(),
  )
  let (s1, native_id) = s.register(native_info)
  let (s2, wasm_id) = s1.register(wasm_info)

  let mut native_total = 0
  let mut wasm_total = 0
  let native_handler : @component.NativeMessageHandler = fn(_c, _f, p) {
    native_total = native_total + p.msg_type
  }
  let wasm_handler : @component.NativeMessageHandler = fn(_c, _f, p) {
    wasm_total = wasm_total + p.msg_type
  }

  let s3 = s2.register_handler(native_id, native_handler)
  let s4 = s3.register_wasm_handler(wasm_id, wasm_handler)

  // Native 组件发 2 条消息，Wasm 组件发 3 条消息
  let p5 = @core.SmallPayload::create(5, [])
  let p10 = @core.SmallPayload::create(10, [])

  let (s5, _) = s4.send_small(0, native_id, p5, @core.MessagePriority::high())
  let (s6, _) = s5.send_small(0, native_id, p10, @core.MessagePriority::high())
  let (s7, _) = s6.send_small(0, wasm_id, p5, @core.MessagePriority::normal())
  let (s8, _) = s7.send_small(0, wasm_id, p10, @core.MessagePriority::normal())
  let (s9, _) = s8.send_small(0, wasm_id, p5, @core.MessagePriority::normal())

  // 逐条处理，验证优先级：高优（Native）优先于普通（Wasm）
  // 处理第 1 条高优 Native 消息
  let s10 = s9.process_one()
  assert_eq(native_total, 5, msg="Native 累加 5")
  assert_eq(wasm_total, 0, msg="Wasm 消息尚未处理")

  // 处理第 2 条高优 Native 消息
  let s11 = s10.process_one()
  assert_eq(native_total, 15, msg="Native 累加 5+10=15")
  assert_eq(wasm_total, 0, msg="Wasm 消息仍未处理")

  // 高优队列已空，处理普通优先级（3 条 Wasm）
  let s12 = s11.process_batch()
  assert_eq(native_total, 15, msg="Native 不再增加")
  assert_eq(wasm_total, 20, msg="Wasm 累加 5+10+5=20")
}
