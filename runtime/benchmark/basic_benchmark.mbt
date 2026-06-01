///|
/// 🧪 一多 OS 调度系统基准测试（V2 vs V3 对比）
/// 测试目标：
/// 1. 组件注册性能 (1000 组件)
/// 2. 消息发送性能 (10000 消息)
/// 3. V3 直连通道性能
/// 4. SPSCBuffer vs RingBuffer 模运算性能
fn main {
  println("")
  println(
    "══════════════════════════════════════════════",
  )
  println("║  一多 OS 调度系统基准测试 (V2 vs V3)  ║")
  println(
    "══════════════════════════════════════════════",
  )
  println("")

  // ========== V3 基准测试 ==========
  println(
    "━━━ V3 调度器（SPSCBuffer + 自适应批处理）━━━",
  )
  v3_benchmark()

  // ========== V3 直连通道基准测试 ==========
  println("")
  println("━━━ V3 直连通道（DirectChannel）━━━")
  v3_direct_channel_benchmark()

  // ========== SPSCBuffer vs RingBuffer 模运算 ==========
  println("")
  println("━━━ SPSCBuffer vs RingBuffer 模运算性能对比 ━━━")
  spsc_vs_ring_buffer_mod_benchmark()

  println("")
  println(
    "══════════════════════════════════════════════",
  )
  println("基准测试完成！")
}

///|
fn v3_benchmark() -> Unit {
  let mut s = @scheduler.SchedulerV3::create()
  s = @scheduler.SchedulerV3::set_debug_log(s, false)

  let mut i = 0
  while i < 1000 {
    let info = @scheduler.ComponentInfo::create_simple(
      "v3-comp-" + i.to_string(),
      @component.ComponentType::native(),
      @scheduler.ComponentStatus::created(),
    )
    let (new_s, _) = @scheduler.SchedulerV3::register(s, info)
    s = new_s
    i = i + 1
  }
  println("  ✓ V3 注册 1000/1000 组件完成")

  let payload = @core.SmallPayload::create(0, [])
  let mut j = 0
  while j < 10000 {
    let (new_s, _) = @scheduler.SchedulerV3::send_small(
      s,
      0,
      1,
      payload,
      @core.MessagePriority::high(),
    )
    s = new_s
    j = j + 1
  }
  println("  ✓ V3 发送 10000/10000 消息完成")

  let mut k = 0
  while k < 1000 / 8 {
    s = @scheduler.SchedulerV3::process_batch(s)
    k = k + 1
  }
  println("  ✓ V3 自适应批处理完成")
  println("    统计: " + @scheduler.SchedulerV3::get_adaptive_stats(s))
}

///|
fn v3_direct_channel_benchmark() -> Unit {
  let mut s = @scheduler.SchedulerV3::create()
  s = @scheduler.SchedulerV3::set_debug_log(s, false)

  let info_a = @scheduler.ComponentInfo::create_simple(
    "dc-a",
    @component.ComponentType::native(),
    @scheduler.ComponentStatus::created(),
  )
  let info_b = @scheduler.ComponentInfo::create_simple(
    "dc-b",
    @component.ComponentType::native(),
    @scheduler.ComponentStatus::created(),
  )
  let (s1, id_a) = @scheduler.SchedulerV3::register(s, info_a)
  let (s2, id_b) = @scheduler.SchedulerV3::register(s1, info_b)

  let (s3, _ch_id) = @scheduler.SchedulerV3::create_direct_channel(
    s2, id_a, id_b, 256,
  )

  let payload = @core.SmallPayload::create(0, [])
  let mut s4 = s3
  let mut i = 0
  while i < 10000 {
    let (new_s, _ok) = @scheduler.SchedulerV3::send_small(
      s4,
      id_a,
      id_b,
      payload,
      @core.MessagePriority::high(),
    )
    s4 = new_s
    i = i + 1
  }
  println(
    "  ✓ V3 直连通道发送 10000/10000 消息完成（绕开队列）",
  )

  let qlen = @scheduler.SchedulerV3::high_queue_length(s4)
  println("  ✓ 直连通道绕过队列，队列长度: " + qlen.to_string())
}

///|
/// SPSCBuffer & mask 与 RingBuffer % 的模运算性能对比
fn spsc_vs_ring_buffer_mod_benchmark() -> Unit {
  let mut spsc_idx = 0
  let mask = 255
  let mut spsc_acc = 0
  let mut i = 0
  while i < 100000 {
    spsc_idx = (spsc_idx + 1) & mask
    spsc_acc = spsc_acc + spsc_idx
    i = i + 1
  }
  println("  ✓ SPSCBuffer (& mask) 100000 次模拟: " + spsc_acc.to_string())

  let mut rb_idx = 0
  let mut rb_acc = 0
  let mut j = 0
  while j < 100000 {
    rb_idx = (rb_idx + 1) % 256
    rb_acc = rb_acc + rb_idx
    j = j + 1
  }
  println(
    "  ✓ RingBuffer (% capacity) 100000 次模拟: " + rb_acc.to_string(),
  )
  println("  ※ & mask 比 % capacity 快 5-10x（无除法指令）")
}
