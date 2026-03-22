// 性能分析工具
// 编译目标：Native

/// 性能指标
record PerformanceMetrics {
  elapsed_time: UInt64  // 经过的时间（纳秒）
  memory_used: UInt64  // 使用的内存（字节）
  instructions: UInt64  // 执行的指令数
}

/// 性能计数器
record PerformanceCounter {
  start_time: UInt64
  start_memory: UInt64
  start_instructions: UInt64
}

/// 获取当前时间（纳秒）
@native c "get_nanos"
fn get_nanos() -> UInt64

/// 获取当前内存使用（字节）
@native c "get_memory_used"
fn get_memory_used() -> UInt64

/// 获取当前指令计数
@native c "get_instructions"
fn get_instructions() -> UInt64

/// 开始性能计数
fn start_counter() -> PerformanceCounter {
  {
    start_time: get_nanos()
    start_memory: get_memory_used()
    start_instructions: get_instructions()
  }
}

/// 停止性能计数并返回指标
fn stop_counter(counter: PerformanceCounter) -> PerformanceMetrics {
  {
    elapsed_time: get_nanos() - counter.start_time
    memory_used: get_memory_used() - counter.start_memory
    instructions: get_instructions() - counter.start_instructions
  }
}

/// 测量函数执行时间
fn measure<F>(f: F) -> (F::Output, PerformanceMetrics) where F: () -> Any {
  let counter = start_counter()
  let result = f()
  let metrics = stop_counter(counter)
  (result, metrics)
}

/// 打印性能指标
fn print_metrics(metrics: PerformanceMetrics, operation: String) {
  println("=== 性能分析: " + operation + " ===")
  println("执行时间: " + (metrics.elapsed_time / 1_000_000).to_string() + " ms")
  println("内存使用: " + (metrics.memory_used / 1024).to_string() + " KB")
  println("指令计数: " + metrics.instructions.to_string())
  println("===============================")
}

/// 性能分析示例
fn profile_example() {
  let (result, metrics) = measure(|| {
    // 模拟一些计算
    let mut sum = 0
    for i in 0..1000000 {
      sum = sum + i
    }
    sum
  })
  print_metrics(metrics, "计算求和")
  println("计算结果: " + result.to_string())
}