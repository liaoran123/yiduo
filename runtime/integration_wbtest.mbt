/// 一多 OS 全链路集成测试
/// 验证：配置解析 → 调度器初始化 → 组件注册 → 消息通信 → 句柄安全

///|
/// 模拟 bootstrap.yaml 完整配置（新格式：无 components 和 chain 段）
const BOOTSTRAP_YAML : String =
  #|system:
  #|  name: Yiduo OS MVP
  #|  version: 0.1.0
  #|  description: 一多操作系统最小启动器
  #|runtime:
  #|  max-components: 32
  #|  max-memory-per-instance: 64
  #|  runtime-type: simulated
  #|bootstrap:
  #|  mode: minimal
  #|  log-level: info
  #|  first-component: wasm-runtime

///|
/// 模拟 Component.yaml（scheduler）
const SCHEDULER_YAML : String =
  #|apiVersion: yiduo.dev/v1alpha1
  #|kind: Component
  #|metadata:
  #|  name: scheduler
  #|  namespace: yiduo.sys
  #|  version: "0.1.0"
  #|  description: 系统调度器
  #|spec:
  #|  type: native
  #|  source: builtin/scheduler
  #|  required: true
  #|  provides:
  #|    - interface: yiduo:sys/scheduler
  #|      description: 组件调度和消息路由
  #|  requires:
  #|    - name: memory
  #|      interface: yiduo:sys/memory
  #|      required: true
  #|      description: 内存管理能力

///|
/// 模拟 Component.yaml（counter）
const COUNTER_YAML : String =
  #|apiVersion: yiduo.dev/v1alpha1
  #|kind: Component
  #|metadata:
  #|  name: counter
  #|  namespace: yiduo.lib
  #|  version: "0.1.0"
  #|  description: 计数器组件
  #|spec:
  #|  type: wasm
  #|  source: builtin/counter
  #|  required: true
  #|  provides:
  #|    - interface: yiduo:lib/counter
  #|      description: 数值计数功能

///|
/// 集成测试 1：解析 bootstrap.yaml（新格式）
test "integration_parse_bootstrap" {
  let result = @config.parse_bootstrap_yaml(BOOTSTRAP_YAML)

  match result {
    Ok(config) => {
      assert_eq(
        config.system.name,
        "Yiduo OS MVP",
        msg="系统名称解析正确",
      )
      assert_eq(config.system.version, "0.1.0", msg="系统版本解析正确")
      assert_eq(
        config.bootstrap.mode.to_string(),
        "minimal",
        msg="启动模式解析正确",
      )
      assert_eq(
        config.bootstrap.log_level.to_string(),
        "info",
        msg="日志级别解析正确",
      )
      assert_eq(
        config.bootstrap.first_component,
        "wasm-runtime",
        msg="首组件正确",
      )
      match config.runtime {
        Some(rt) => {
          assert_eq(rt.max_components, 32, msg="最大组件数正确")
          assert_eq(rt.max_memory_per_instance, 64, msg="最大内存正确")
          assert_eq(rt.runtime_type, "simulated", msg="运行时类型正确")
        }
        None => assert_true(false, msg="运行时配置应存在")
      }
    }
    Err(e) => assert_true(false, msg="配置解析失败: " + e)
  }
}

///|
/// 集成测试 2：解析 Component.yaml（scheduler）
test "integration_parse_scheduler_yaml" {
  match parse_component_yaml_for_test(SCHEDULER_YAML) {
    Ok(desc) => {
      assert_eq(desc.name, "scheduler", msg="组件名称正确")
      assert_eq(desc.ns, Some("yiduo.sys"), msg="命名空间正确")
      assert_eq(desc.version, Some("0.1.0"), msg="版本正确")
      assert_eq(desc.component_type, "native", msg="组件类型正确")
      assert_eq(desc.source, Some("builtin/scheduler"), msg="来源正确")
      assert_eq(desc.required, true, msg="必需属性正确")
      assert_eq(desc.description, Some("系统调度器"), msg="描述正确")
      assert_eq(desc.provides.length(), 1, msg="provides 数量正确")
      if desc.provides.length() > 0 {
        assert_eq(
          desc.provides[0].interface_name,
          "yiduo:sys/scheduler",
          msg="提供的接口正确",
        )
      }
      assert_eq(
        desc.requires_interfaces.length(),
        1,
        msg="requires 数量正确",
      )
      if desc.requires_interfaces.length() > 0 {
        assert_eq(
          desc.requires_interfaces[0].name,
          "memory",
          msg="依赖名称正确",
        )
        assert_eq(
          desc.requires_interfaces[0].interface_name,
          "yiduo:sys/memory",
          msg="依赖接口正确",
        )
        assert_eq(
          desc.requires_interfaces[0].required,
          true,
          msg="依赖必需正确",
        )
      }
    }
    Err(e) => assert_true(false, msg="组件解析失败: " + e)
  }
}

///|
/// 集成测试 3：解析 Component.yaml（counter - 无依赖）
test "integration_parse_counter_yaml" {
  match parse_component_yaml_for_test(COUNTER_YAML) {
    Ok(desc) => {
      assert_eq(desc.name, "counter", msg="组件名称正确")
      assert_eq(desc.component_type, "wasm", msg="组件类型正确")
      assert_eq(desc.required, true, msg="必需属性正确")
      assert_eq(desc.provides.length(), 1, msg="provides 数量正确")
      if desc.provides.length() > 0 {
        assert_eq(
          desc.provides[0].interface_name,
          "yiduo:lib/counter",
          msg="提供的接口正确",
        )
      }
      assert_eq(desc.requires_interfaces.length(), 0, msg="counter 无依赖")
    }
    Err(e) => assert_true(false, msg="组件解析失败: " + e)
  }
}

///|
/// 帮助函数：绕过配置模块内部的 parser
fn parse_component_yaml_for_test(
  yaml_text : String,
) -> Result[@config.ComponentDescriptor, String] {
  // 用配置模块的公共 API 间接测试
  // 模拟一个只读 configs/components/test.yaml 的文件系统
  let fs = create_test_fs(yaml_text)
  @config.load_component_descriptor_from_fs(fs, "test.yaml")
}

///|
/// 创建测试用文件系统（只返回固定内容）
fn create_test_fs(content : String) -> @core.FileSystem {
  @core.FileSystem::from_fields(
    fn(_path : String) -> Result[String, String] { Ok(content) },
    fn(_dir : String) -> Result[Array[String], String] { Ok([]) },
  )
}

///|
/// 集成测试 4：完整 bootstrap 流程
test "integration_full_bootstrap_flow" {
  let pool = @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64))
  let mgr = @core.MemoryManager::create(pool, 64)

  let mut scheduler = @scheduler.Scheduler::create_with_config(mgr, 8, 32)
  scheduler = @scheduler.Scheduler::set_debug_log(scheduler, false)

  let core_info = @scheduler.ComponentInfo::create_simple(
    "scheduler-core",
    @component.ComponentType::native(),
    @scheduler.ComponentStatus::running(),
  )
  let wasm_info = @scheduler.ComponentInfo::create_simple(
    "wasm-runtime",
    @component.ComponentType::native(),
    @scheduler.ComponentStatus::created(),
  )
  let config_info = @scheduler.ComponentInfo::create_simple(
    "config-parser",
    @component.ComponentType::native(),
    @scheduler.ComponentStatus::created(),
  )

  let (s1, _core_id) = scheduler.register(core_info)
  let (s2, wasm_id) = s1.register(wasm_info)
  let (s3, config_id) = s2.register(config_info)
  scheduler = s3

  // wasm-runtime → config-parser 发送高优消息
  let (s4, ok1) = scheduler.send_small(
    wasm_id,
    config_id,
    @core.SmallPayload::create(1, []),
    @core.MessagePriority::high(),
  )
  assert_eq(ok1, true, msg="高优先消息发送成功")

  // config-parser → scheduler-core 发送普通消息
  let (s5, ok2) = s4.send_small(
    config_id,
    _core_id,
    @core.SmallPayload::create(2, []),
    @core.MessagePriority::normal(),
  )
  assert_eq(ok2, true, msg="普通消息发送成功")

  // 运行调度循环处理所有消息
  scheduler = s5.run_loop(5)

  // 再次发送消息测试处理完后的状态
  let (s6, ok3) = scheduler.send_small(
    wasm_id,
    config_id,
    @core.SmallPayload::create(3, []),
    @core.MessagePriority::low(),
  )
  assert_eq(ok3, true, msg="处理后发送新消息成功")
  scheduler = s6

  // 处理这条新消息
  scheduler = scheduler.process_one()
}

///|
/// 集成测试 5：多组件 + 多优先级消息流
test "integration_multi_component_flow" {
  let pool = @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64))
  let mgr = @core.MemoryManager::create(pool, 64)
  let mut scheduler = @scheduler.Scheduler::create_with_config(mgr, 4, 32)
  scheduler = @scheduler.Scheduler::set_debug_log(scheduler, false)

  let comps = [
    @scheduler.ComponentInfo::create_simple(
      "gateway",
      @component.ComponentType::wasm(),
      @scheduler.ComponentStatus::created(),
    ),
    @scheduler.ComponentInfo::create_simple(
      "auth",
      @component.ComponentType::wasm(),
      @scheduler.ComponentStatus::created(),
    ),
    @scheduler.ComponentInfo::create_simple(
      "processor",
      @component.ComponentType::wasm(),
      @scheduler.ComponentStatus::created(),
    ),
    @scheduler.ComponentInfo::create_simple(
      "storage",
      @component.ComponentType::wasm(),
      @scheduler.ComponentStatus::created(),
    ),
  ]

  let ids : Array[Int] = []
  let mut s = scheduler
  for comp in comps {
    let (s_new, id) = s.register(comp)
    s = s_new
    ids.push(id)
  }
  scheduler = s

  let payload = @core.SmallPayload::create(0, [])

  // gateway → auth (高优), gateway → processor (普通), processor → storage (低优)
  let (s1, _) = scheduler.send_small(
    ids[0],
    ids[1],
    payload,
    @core.MessagePriority::high(),
  )
  assert_eq(
    scheduler.send_small(
      ids[0],
      ids[2],
      payload,
      @core.MessagePriority::normal(),
    ).1,
    true,
    msg="普通消息发送成功",
  )
  let (s3, _) = s1.send_small(
    ids[2],
    ids[3],
    payload,
    @core.MessagePriority::low(),
  )

  // 处理3条消息
  let s4 = s3.process_one()
  let s5 = s4.process_one()
  let s6 = s5.process_one()

  // 验证可以继续发送和接收
  let (_s7, ok) = s6.send_small(
    ids[0],
    ids[1],
    payload,
    @core.MessagePriority::high(),
  )
  assert_eq(ok, true, msg="处理后消息发送仍正常")
}

///|
/// 集成测试 6：句柄安全全生命周期
test "integration_handle_safe_lifecycle" {
  let pool = @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64))
  let mgr = @core.MemoryManager::create(pool, 64)

  let (mgr1, handle_opt) = mgr.allocate_handle(1, 256)
  match handle_opt {
    Some(handle) => {
      let (mgr2, transfer_ok) = mgr1.transfer_ownership(handle, 1, 2)
      assert_eq(transfer_ok, true, msg="所有权转移应成功")

      let (_, free_a_fail) = mgr2.free_handle(handle, 1)
      assert_eq(
        free_a_fail,
        false,
        msg="原所有者不能释放已转移句柄",
      )

      let (mgr3, free_b_ok) = mgr2.free_handle(handle, 2)
      assert_eq(free_b_ok, true, msg="新所有者应能释放句柄")

      let (_, double_free) = mgr3.free_handle(handle, 2)
      assert_eq(double_free, false, msg="二次释放应拒绝")
    }
    None => assert_true(false, msg="句柄分配应成功")
  }
}

///|
/// 集成测试 7：高吞吐消息处理
test "integration_high_throughput_messaging" {
  let pool = @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64))
  let mgr = @core.MemoryManager::create(pool, 64)
  let mut scheduler = @scheduler.Scheduler::create_with_config(mgr, 8, 32)
  scheduler = @scheduler.Scheduler::set_debug_log(scheduler, false)

  let info = @scheduler.ComponentInfo::create_simple(
    "worker",
    @component.ComponentType::wasm(),
    @scheduler.ComponentStatus::created(),
  )
  let (s1, worker_id) = scheduler.register(info)

  // 批量发送 20 条消息
  let payload = @core.SmallPayload::create(0, [])
  let mut s2 = s1
  let mut i = 0
  while i < 20 {
    let (s_new, ok) = s2.send_small(
      0,
      worker_id,
      payload,
      @core.MessagePriority::normal(),
    )
    assert_eq(ok, true, msg="第 " + i.to_string() + " 条消息发送成功")
    s2 = s_new
    i = i + 1
  }

  // 用 run_loop 处理全部
  let s3 = s2.run_loop(10)

  // 处理后仍能正常发送
  let (_s4, ok) = s3.send_small(
    0,
    worker_id,
    payload,
    @core.MessagePriority::high(),
  )
  assert_eq(ok, true, msg="处理后发送消息正常")
}

///|
/// 真实组件测试 1：计数器组件接收消息
test "real_counter_component_flow" {
  let pool = @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64))
  let mgr = @core.MemoryManager::create(pool, 64)
  let mut scheduler = @scheduler.Scheduler::create_with_config(mgr, 8, 32)
  scheduler = @scheduler.Scheduler::set_debug_log(scheduler, false)

  let counter = CounterComponent::create("my-counter")
  let info = counter.create_component_info(@component.ComponentType::native())
  let (s1, comp_id) = scheduler.register(info)
  scheduler = s1.register_handler(comp_id, counter.handler)

  assert_eq((counter.get_count)(), 0, msg="初始计数为 0")

  let payload = @core.SmallPayload::create(42, [])
  let (s2, ok1) = scheduler.send_small(
    0,
    comp_id,
    payload,
    @core.MessagePriority::high(),
  )
  assert_eq(ok1, true, msg="第 1 条消息发送成功")
  scheduler = s2

  let (s3, ok2) = scheduler.send_small(
    0,
    comp_id,
    payload,
    @core.MessagePriority::high(),
  )
  assert_eq(ok2, true, msg="第 2 条消息发送成功")
  scheduler = s3

  scheduler = scheduler.process_one()
  assert_eq((counter.get_count)(), 1, msg="处理 1 条后计数=1")

  scheduler = scheduler.process_one()
  assert_eq((counter.get_count)(), 2, msg="处理 2 条后计数=2")
}

///|
/// 真实组件测试 2：累加器组件
test "real_accumulator_component_flow" {
  let pool = @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64))
  let mgr = @core.MemoryManager::create(pool, 64)
  let mut scheduler = @scheduler.Scheduler::create_with_config(mgr, 8, 32)
  scheduler = @scheduler.Scheduler::set_debug_log(scheduler, false)

  let acc = AccumulatorComponent::create("my-accumulator")
  let info = acc.create_component_info(@component.ComponentType::native())
  let (s1, comp_id) = scheduler.register(info)
  scheduler = s1.register_handler(comp_id, acc.handler)

  assert_eq((acc.get_total)(), 0, msg="初始总和为 0")

  let (s2, _) = scheduler.send_small(
    0,
    comp_id,
    @core.SmallPayload::create(10, []),
    @core.MessagePriority::high(),
  )
  let (s3, _) = s2.send_small(
    0,
    comp_id,
    @core.SmallPayload::create(20, []),
    @core.MessagePriority::high(),
  )
  let (s4, _) = s3.send_small(
    0,
    comp_id,
    @core.SmallPayload::create(30, []),
    @core.MessagePriority::high(),
  )
  scheduler = s4

  scheduler = scheduler.process_one()
  scheduler = scheduler.process_one()
  scheduler = scheduler.process_one()
  assert_eq((acc.get_total)(), 60, msg="10+20+30=60")
}

///|
/// 真实组件测试 3：多计数器组件共存
test "real_multiple_counters_independence" {
  let pool = @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64))
  let mgr = @core.MemoryManager::create(pool, 64)
  let mut scheduler = @scheduler.Scheduler::create_with_config(mgr, 8, 32)
  scheduler = @scheduler.Scheduler::set_debug_log(scheduler, false)

  let counter_a = CounterComponent::create("counter-a")
  let counter_b = CounterComponent::create("counter-b")

  let info_a = counter_a.create_component_info(
    @component.ComponentType::native(),
  )
  let info_b = counter_b.create_component_info(
    @component.ComponentType::native(),
  )

  let (s1, id_a) = scheduler.register(info_a)
  let (s2, id_b) = s1.register(info_b)

  scheduler = s2.register_handler(id_a, counter_a.handler)
  scheduler = scheduler.register_handler(id_b, counter_b.handler)

  let p = @core.SmallPayload::create(1, [])
  let (s3, _) = scheduler.send_small(0, id_a, p, @core.MessagePriority::high())
  let (s4, _) = s3.send_small(0, id_a, p, @core.MessagePriority::high())
  let (s5, _) = s4.send_small(0, id_b, p, @core.MessagePriority::high())
  scheduler = s5

  // 尚未处理
  assert_eq((counter_a.get_count)(), 0, msg="处理前计数 A=0")
  assert_eq((counter_b.get_count)(), 0, msg="处理前计数 B=0")

  scheduler = scheduler.process_one()
  scheduler = scheduler.process_one()
  scheduler = scheduler.process_one()

  assert_eq((counter_a.get_count)(), 2, msg="计数器 A 收到 2 条消息")
  assert_eq((counter_b.get_count)(), 1, msg="计数器 B 收到 1 条消息")
}

///|
/// 真实组件测试 4：计数器 + 累加器混合
test "real_counter_and_accumulator_hybrid" {
  let pool = @core.MemoryPool::create(@core.MemoryPoolConfig::create(4096, 64))
  let mgr = @core.MemoryManager::create(pool, 64)
  let mut scheduler = @scheduler.Scheduler::create_with_config(mgr, 8, 32)
  scheduler = @scheduler.Scheduler::set_debug_log(scheduler, false)

  let counter = CounterComponent::create("counter")
  let acc = AccumulatorComponent::create("accumulator")

  let (s1, cid) = scheduler.register(
    counter.create_component_info(@component.ComponentType::native()),
  )
  let (s2, aid) = s1.register(
    acc.create_component_info(@component.ComponentType::native()),
  )

  scheduler = s2.register_handler(cid, counter.handler)
  scheduler = scheduler.register_handler(aid, acc.handler)

  let (s3, _) = scheduler.send_small(
    0,
    cid,
    @core.SmallPayload::create(100, []),
    @core.MessagePriority::high(),
  )
  let (s4, _) = s3.send_small(
    0,
    aid,
    @core.SmallPayload::create(100, []),
    @core.MessagePriority::high(),
  )
  let (s5, _) = s4.send_small(
    0,
    aid,
    @core.SmallPayload::create(50, []),
    @core.MessagePriority::high(),
  )
  scheduler = s5

  scheduler = scheduler.process_one()
  scheduler = scheduler.process_one()
  scheduler = scheduler.process_one()

  assert_eq((counter.get_count)(), 1, msg="计数器收到 1 条")
  assert_eq((acc.get_total)(), 150, msg="累加器 100+50=150")
}
