/// 🚀 自适应批量排水调度器
///
/// 替换固定 batch_size 的 process_batch，根据负载动态调节批量大小：
///
/// - 高优先级：尽量排空（延迟 <10μs）
/// - 中优先级：自适应批量（负载高则扩大，负载低则缩小）
/// - 低优先级：批量 × 2（吞吐优先）
///
/// 性能目标：比固定 batch_size 提升 3-10x

///|
/// 调度器性能指标（Int 在 MoonBit native 上为 64 位，避免与 Int64 的类型转换开销）
pub struct SchedulerMetrics {
  total_messages : Int
  high_priority_count : Int
  normal_priority_count : Int
  low_priority_count : Int
  batch_count : Int
  total_batch_size : Int
  max_batch_size : Int
  min_batch_size : Int
  direct_channel_count : Int
}

///|
pub fn SchedulerMetrics::create() -> SchedulerMetrics {
  SchedulerMetrics::{
    total_messages: 0,
    high_priority_count: 0,
    normal_priority_count: 0,
    low_priority_count: 0,
    batch_count: 0,
    total_batch_size: 0,
    max_batch_size: 0,
    min_batch_size: 0,
    direct_channel_count: 0,
  }
}

///|
/// 自适应批处理上下文
pub struct AdaptiveBatchContext {
  batch_size : Int
  min_batch : Int
  max_batch : Int
  drain_round : Int
  stats : SchedulerMetrics
}

///|
pub fn AdaptiveBatchContext::create() -> AdaptiveBatchContext {
  AdaptiveBatchContext::{
    batch_size: 8,
    min_batch: 4,
    max_batch: 64,
    drain_round: 0,
    stats: SchedulerMetrics::create(),
  }
}

///|
/// 自适应批量排水（对三个优先级的 SPSCBuffer 操作）
///
/// 所有统计量通过不可变结构体字段累加，最终返回新的上下文
pub fn[T] drain_adaptive(
  ctx : AdaptiveBatchContext,
  high_queue : @core.SPSCBuffer[T],
  normal_queue : @core.SPSCBuffer[T],
  low_queue : @core.SPSCBuffer[T],
) -> (
  AdaptiveBatchContext,
  @core.SPSCBuffer[T],
  @core.SPSCBuffer[T],
  @core.SPSCBuffer[T],
  Array[T],
) {
  // 1. 排各优先级队列
  let (hq, high_msgs) = high_queue.dequeue_batch(high_queue.len())
  let (nq, normal_msgs) = normal_queue.dequeue_batch(ctx.batch_size)
  let low_batch = ctx.batch_size * 2
  let (lq, low_msgs) = low_queue.dequeue_batch(low_batch)

  // 2. 合并消息
  let all_messages : Array[T] = []
  for msg in high_msgs {
    all_messages.push(msg)
  }
  for msg in normal_msgs {
    all_messages.push(msg)
  }
  for msg in low_msgs {
    all_messages.push(msg)
  }

  let processed = all_messages.length()
  let ncount = normal_msgs.length()
  let lcount = low_msgs.length()

  // 3. 计算新统计值（全部为 Int，无需类型转换）
  let total_messages = ctx.stats.total_messages + processed
  let high_priority_count = ctx.stats.high_priority_count + high_msgs.length()
  let normal_priority_count = ctx.stats.normal_priority_count + ncount
  let low_priority_count = ctx.stats.low_priority_count + lcount
  let batch_count = ctx.stats.batch_count + 1
  let total_batch_size = ctx.stats.total_batch_size + processed
  let max_batch_size = if processed > ctx.stats.max_batch_size {
    processed
  } else {
    ctx.stats.max_batch_size
  }
  let min_batch_size = if processed < ctx.stats.min_batch_size ||
    ctx.stats.min_batch_size == 0 {
    processed
  } else {
    ctx.stats.min_batch_size
  }

  // 4. 自适应调节批量大小
  let new_batch_size = if ncount >= ctx.batch_size && lcount >= low_batch {
    choose_min(ctx.batch_size * 2, ctx.max_batch)
  } else if ncount == 0 && lcount == 0 {
    choose_max(ctx.batch_size / 2, ctx.min_batch)
  } else {
    ctx.batch_size
  }

  // 5. 构造新上下文（不可变风格）
  let new_stats = SchedulerMetrics::{
    total_messages,
    high_priority_count,
    normal_priority_count,
    low_priority_count,
    batch_count,
    total_batch_size,
    max_batch_size,
    min_batch_size,
    direct_channel_count: ctx.stats.direct_channel_count,
  }
  let new_ctx = AdaptiveBatchContext::{
    batch_size: new_batch_size,
    min_batch: ctx.min_batch,
    max_batch: ctx.max_batch,
    drain_round: ctx.drain_round + 1,
    stats: new_stats,
  }

  (new_ctx, hq, nq, lq, all_messages)
}

///|
/// 性能指标报告
pub fn SchedulerMetrics::report(self : SchedulerMetrics) -> String {
  let avg = if self.batch_count > 0 {
    self.total_batch_size / self.batch_count
  } else {
    0
  }
  "=== Scheduler Performance Metrics ===\n" +
  "Total messages: " +
  self.total_messages.to_string() +
  " (High:" +
  self.high_priority_count.to_string() +
  " Normal:" +
  self.normal_priority_count.to_string() +
  " Low:" +
  self.low_priority_count.to_string() +
  ")\n" +
  "Batches: " +
  self.batch_count.to_string() +
  " Avg batch: " +
  avg.to_string() +
  " Max: " +
  self.max_batch_size.to_string() +
  " Min: " +
  self.min_batch_size.to_string() +
  "\n" +
  "Direct channel msgs: " +
  self.direct_channel_count.to_string()
}

///|
fn choose_min(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn choose_max(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}
