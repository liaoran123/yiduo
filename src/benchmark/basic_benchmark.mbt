/// 🧪 一多 OS 调度系统基准测试
/// 测试目标：
/// 1. 消息吞吐性能
/// 2. 组件注册性能
/// 3. 调度延迟

use @scheduler.Scheduler
use @core.Message
use @core.MessagePriority
use @core.SmallPayload

fn main() {
  println("");
  println("══════════════════════════════════════════════");
  println("║    一多 OS 调度系统基准测试    ║");
  println("══════════════════════════════════════════════");
  println("");

  // === 测试 1: 组件注册性能 ===
  println("【测试 1】组件注册性能");
  let s1 = Scheduler::create();
  let comp1 = @scheduler.ComponentInfo{ name: "Comp1", component_type: "test", status: @scheduler.ComponentStatus::Running };
  let comp2 = @scheduler.ComponentInfo{ name: "Comp2", component_type: "test", status: @scheduler.ComponentStatus::Running };
  
  let start1 = get_tick_count();
  let (s1a, id1) = Scheduler::register(s1, comp1);
  let (s1b, id2) = Scheduler::register(s1a, comp2);
  let end1 = get_tick_count();
  
  println("  注册 2 个组件: " + (end1 - start1).to_string() + " ticks");
  println("  组件 ID: " + id1.to_string() + ", " + id2.to_string());
  println("");

  // === 测试 2: 小消息吞吐性能 ===
  println("【测试 2】小消息吞吐性能");
  let msg_count = 10000; // 测试 1 万条消息
  let payload = SmallPayload{ msg_type: 1, data: [] };
  
  let start2 = get_tick_count();
  let mut s2 = s1b;
  let mut i = 0;
  while i < msg_count {
    let (s2a, ok) = Scheduler::send_small(s2, 1, 2, payload, MessagePriority::Normal);
    s2 = s2a;
    i = i + 1;
  }
  let end2 = get_tick_count();
  
  println("  发送 " + msg_count.to_string() + " 条小消息: " + (end2 - start2).to_string() + " ticks");
  let throughput = if (end2 - start1) > 0 { msg_count * 1000 / (end2 - start2) } else { 0 };
  println("  估算吞吐: " + throughput.to_string() + " msg/s (仅供参考)");
  println("  队列长度: " + Scheduler::normal_queue_length(s2).to_string());
  println("");

  // === 测试 3: 消息处理性能 ===
  println("【测试 3】消息处理性能");
  let start3 = get_tick_count();
  let s3 = Scheduler::run_loop(s2, msg_count);
  let end3 = get_tick_count();
  
  println("  处理 " + msg_count.to_string() + " 条消息: " + (end3 - start3).to_string() + " ticks");
  println("  队列剩余: " + Scheduler::normal_queue_length(s3).to_string());
  println("");

  // === 基准测试完成 ===
  println("══════════════════════════════════════════════");
  println("║        基准测试完成！       ║");
  println("══════════════════════════════════════════════");
  println("");
  println("🎯 接下来可以:");
  println("   1. 找出性能瓶颈");
  println("   2. 针对性优化");
  println("   3. 对比优化前后的结果");
  println("");
}

/// 简单的计时函数（模拟）
fn get_tick_count() -> Int {
  // 这里应该使用系统时钟
  // 临时用简单的实现，实际需要接入 MoonBit 的时间 API
  123456 // 占位
}
