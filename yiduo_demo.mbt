/// 🧬 一多 OS 生物学架构演示
/// 澄清关键设计原则：AI大脑不介入高频数据流！

// 导入模块
use @scheduler.NeuralScheduler
use @core.HealthScore

fn main() {
  println("")
  println("══════════════════════════════════════════════")
  println("║  🧬 一多 OS 生物学架构演示 🧬    ║")
  println("══════════════════════════════════════════════")
  println("")
  println("📌 关键设计原则：")
  println("   1. 🩸 血液流动（高频数据）→ 内联核心，<1微秒")
  println("   2. ⚡ 神经反射（突发负载）→ 局部均衡，<1毫秒")
  println("   3. 🧠 AI大脑（宏观决策）→ 低频率，>10秒/次")
  println("")
  println("🎯 类比：")
  println("   - 血液流动（心跳）不需要大脑思考")
  println("   - 碰到烫东西，神经反射直接缩手")
  println("   - 大脑只决定『我要去哪里』")
  println("")

  // 创建中枢神经系统
  println("🚀 初始化一多 OS 中枢神经系统...")
  let mut scheduler = NeuralScheduler.create()
  println("✅ 神经系统就绪！")
  println("")

  // 注册三个组件（细胞）
  println("🧬 注册器官（组件）...")
  
  let (scheduler1, camera_id) = scheduler.register_component(@scheduler.ComponentInfo{
    name: "摄像头器官",
    component_type: "wasm",
    status: @scheduler.ComponentStatus.Created
  })
  scheduler = scheduler1
  
  let (scheduler2, ai_id) = scheduler.register_component(@scheduler.ComponentInfo{
    name: "AI检测器器官",
    component_type: "wasm",
    status: @scheduler.ComponentStatus.Created
  })
  scheduler = scheduler2
  
  let (scheduler3, display_id) = scheduler.register_component(@scheduler.ComponentInfo{
    name: "显示器器官",
    component_type: "wasm",
    status: @scheduler.ComponentStatus.Created
  })
  scheduler = scheduler3
  println("✅ 所有器官注册完成！")
  println("")

  // 建立血管连接（订阅频道）
  println("🩸 建立血管连接（事件订阅）...")
  
  // AI检测器订阅摄像头视频流
  let (scheduler4, sub1) = scheduler.subscribe_channel(0, ai_id, fn(pub_id: Int, data: Int) {
    println("[AI检测器] 🔍 收到视频帧，处理中...")
  })
  scheduler = scheduler4
  
  // 显示器订阅AI检测结果
  let (scheduler5, sub2) = scheduler.subscribe_channel(1, display_id, fn(pub_id: Int, data: Int) {
    println("[显示器] 🖼️  显示检测结果...")
  })
  scheduler = scheduler5
  println("✅ 血管连接完成！")
  println("")

  // 演示血液流动（高频数据，无AI介入）
  println("🩸 ========== 开始血液流动（高频数据流）==========")
  println("📌 注意：AI大脑完全不介入！只有内联核心处理！")
  println("")
  
  // 模拟30帧视频流（高频）
  let mut frame = 0
  while frame < 30 {
    let (new_scheduler, notified) = scheduler.publish_event(0, camera_id, frame)
    scheduler = new_scheduler
    
    if frame % 5 == 4 {
      let (new_scheduler2, _) = scheduler.publish_event(1, ai_id, frame)
      scheduler = new_scheduler2
    }
    
    frame = frame + 1
  }
  println("")
  println("✅ 30帧视频流处理完成！")
  println("")

  // 模拟神经反射（突发负载）
  println("⚡ ========== 触发神经反射（负载突增）==========")
  println("📌 神经反射：局部响应，毫秒级，不经过AI大脑")
  println("")
  
  let mut scheduler6 = scheduler.update_health(HealthScore{
    memory_used: 90,
    cpu_load: 95,
    active_cells: 3,
    total_cells: 3
  })
  scheduler = scheduler6
  
  let mut scheduler7 = scheduler.check_neural_reflex()
  scheduler = scheduler7
  println("")

  // 模拟AI心跳（低频宏观决策）
  println("🧠 ========== AI大脑心跳（低频宏观决策）==========")
  println("📌 注意：AI大脑每10秒才工作一次！不影响高频数据流！")
  println("")
  
  let mut scheduler8 = scheduler.heartbeat()
  scheduler = scheduler8
  println("")

  // 打印最终状态
  println("📊 ========== 系统最终状态 ==========")
  scheduler.print_status()

  println("")
  println("🎉 ========== 演示完成！ ==========")
  println("")
  println("🎯 总结：")
  println("   - 高频数据：内联核心（<1微秒）")
  println("   - 突发负载：神经反射（<1毫秒）")
  println("   - 宏观决策：AI大脑（>10秒）")
  println("")
  println("✅ 一多 OS：既高性能又智能！")
  println("")
}
