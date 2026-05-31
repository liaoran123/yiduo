/// 一多 OS 自举逻辑
/// 从 fn main 中提取，供 wasm-gc（硬编码配置）和 native（文件系统配置）复用

///|
/// 运行自举流程
/// 接收已解析的 YiduoBootstrapConfig + 发现的组件描述列表，执行完整的自举闭环
pub fn run(
  config : @config.YiduoBootstrapConfig,
  components : Array[@config.ComponentDescriptor],
) -> Unit {
  println(
    "══════════════════════════════════════════════",
  )
  println("║ 一多 OS - 自举验证 ║")
  println(
    "══════════════════════════════════════════════",
  )
  println("")
  println("[System] " + config.system.name)
  let version = config.system.version
  if version != "" {
    println("[Version] " + version)
  }
  let description = config.system.description
  match description {
    Some(d) => println("[Description] " + d)
    None => ()
  }
  println("[Mode] " + config.bootstrap.mode.to_string())

  // 1. 极小启动器初始化
  println("\n[Step 1] 初始化调度器...")
  let mut scheduler = @scheduler.create()
  println("[OK] 调度器初始化完成")

  // 2. 调度核心自注册 (ID 0)
  println("\n[Step 2] 注册调度核心 (ID 0)...")
  let scheduler_core_info = @scheduler.ComponentInfo::create_simple(
    "scheduler-core",
    @scheduler.component_type_native_core(),
    @scheduler.ComponentStatus::running(),
  )
  let (s0, core_id) = @scheduler.register(scheduler, scheduler_core_info)
  println("[OK] 调度核心注册成功，ID: " + core_id.to_string())
  scheduler = s0

  // 3. 运行时初始化
  println("\n[Step 3] 运行时初始化...")
  let rt_config = match config.runtime {
    Some(rc) => rc
    None => @config.RuntimeConfig::default()
  }
  println("- 运行时类型: " + rt_config.runtime_type)
  println("- 最大组件数: " + rt_config.max_components.to_string())

  let wasm_rt = @component.WasmRuntime::create_simulated(
    rt_config.max_components,
  )
  scheduler = scheduler.set_wasm_runtime(wasm_rt)
  println("[OK] 运行时初始化完成 (" + rt_config.runtime_type + ")")

  // 4. 配置驱动组件注册
  println(
    "\n[Step 4] 配置驱动注册组件 (" +
    components.length().to_string() +
    " 个)...",
  )
  let mut index = 1

  for desc in components {
    let ct = match @component.ComponentType::from_string(desc.component_type) {
      Some(t) => t
      None => @component.ComponentType::wasm()
    }
    let comp_info = @scheduler.ComponentInfo::create_simple(
      desc.name,
      ct,
      @scheduler.ComponentStatus::created(),
    )

    let (s_updated, comp_id) = @scheduler.register(scheduler, comp_info)
    println(
      "- 注册组件: " + desc.name + " (ID: " + comp_id.to_string() + ")",
    )
    scheduler = s_updated
    index = index + 1
  }

  // 5. 测试消息分发
  println("\n[Step 5] 测试消息分发...")

  let test_payload = @core.SmallPayload::create(1, [])
  println("- 发送测试消息给调度核心 (ID 0)...")
  let (s1, ok) = @scheduler.send_small(
    scheduler,
    @scheduler.SCHEDULER_CORE_ID,
    @scheduler.SCHEDULER_CORE_ID,
    test_payload,
    @core.MessagePriority::normal(),
  )
  if ok {
    println("[OK] 消息发送成功")
  } else {
    println("[ERR] 消息发送失败")
  }
  scheduler = s1

  // 6. 运行调度循环
  println("\n[Step 6] 运行调度循环 (迭代 5 次)...")
  let s_final = @scheduler.run_loop(scheduler, 5)
  scheduler = s_final

  // 7. 打印状态
  println("\n[Final] 自举验证完成！")
  @scheduler.print_status(scheduler)

  println(
    "\n══════════════════════════════════════════════",
  )
  println("║ 自举闭环验证完成！ ║")
  println(
    "══════════════════════════════════════════════",
  )
}
