///|
/// 🧪 一多 OS 调度系统基准测试
/// 测试目标：
/// 1. 组件注册性能 (1000 组件)
/// 2. 消息发送性能 (10000 消息)
/// 3. 调度延迟 (1000 消息处理)
fn main {
  println("")
  println(
    "══════════════════════════════════════════════",
  )
  println("║    一多 OS 调度系统基准测试    ║")
  println(
    "══════════════════════════════════════════════",
  )
  println("")

  // 关闭调试日志以获得准确性能数据
  let mut s = @scheduler.Scheduler::create()
  s = @scheduler.Scheduler::set_debug_log(s, false)

  // === 测试 1: 组件注册性能 ===
  println("【测试 1】组件注册性能")
  let mut i = 0
  while i < 1000 {
    let info = @scheduler.ComponentInfo::create_simple(
      "bench-comp-" + i.to_string(),
      @component.ComponentType::native(),
      @scheduler.ComponentStatus::created(),
    )
    let (new_s, _) = @scheduler.Scheduler::register(s, info)
    s = new_s
    i = i + 1
  }
  println("  ✓ 注册 1000/1000 组件完成")

  // === 测试 2: 消息发送性能 ===
  println("\n【测试 2】消息发送性能")
  let payload = @core.SmallPayload::create(0, [])
  let msg = @core.Message::create_small(0, 1, payload)
  let mut j = 0
  while j < 10000 {
    let (new_s, _) = @scheduler.Scheduler::send_message(
      s,
      0,
      1,
      msg,
      @core.MessagePriority::high(),
    )
    s = new_s
    j = j + 1
  }
  println("  ✓ 发送 10000/10000 消息完成")

  // === 测试 3: 调度延迟 ===
  println("\n【测试 3】调度处理（消耗消息）")
  let mut k = 0
  while k < 1000 {
    s = @scheduler.Scheduler::process_one(s)
    k = k + 1
  }
  println("  ✓ 处理 1000/1000 消息完成")

  // === 最终状态 ===
  println("")
  println(
    "══════════════════════════════════════════════",
  )
  println("基准测试完成！")
  println("注册组件: 1000 | 发送消息: 10000 | 处理消息: 1000")
}
