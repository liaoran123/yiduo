// 一多操作系统 - MVP 演示
// 配置驱动 + 计算细胞 + 组合式设计

fn main() -> Unit {
  println("═══════════════════════════════════════════════════════════════")
  println("    一多操作系统 - MVP 演示")
  println("    配置驱动 + 计算细胞 + 组合式设计")
  println("═══════════════════════════════════════════════════════════════")

  // --- 演示 1: Hello World ---
  println("\n" + repeat_string("═", 60))
  println("🎯 演示 1: Hello World")
  println("   能力组合: Logger → Greeter → Formatter")
  
  let input1 = "World"
  println("\n🚀 开始执行...")
  println("   输入: " + input1)
  
  let out1 = log_info(input1)
  let out2 = greet(out1, "Hello")
  let final1 = to_uppercase(out2)
  
  println("\n🎊 最终结果: " + final1)

  // --- 演示 2: 修改配置改变行为 ---
  println("\n" + repeat_string("═", 60))
  println("🎯 演示 2: 修改配置改变行为")
  println("   (无需改代码,只需改变能力参数!)")
  
  let input2 = "MoonBit"
  println("\n🚀 开始执行...")
  println("   输入: " + input2)
  
  let out1_2 = log_warn(input2)
  let out2_2 = greet(out1_2, "Hi")
  let final2 = to_lowercase(out2_2)
  
  println("\n🎊 最终结果: " + final2)

  // --- 演示 3: 智能摄像头 ---
  println("\n" + repeat_string("═", 60))
  println("🎯 演示 3: 智能摄像头 - 图像处理流水线")
  println("   能力组合: Logger → ImageProcessor → Formatter")
  
  let input3 = "raw_image_001.jpg"
  println("\n🚀 开始执行...")
  println("   输入: " + input3)
  
  let out1_3 = log_info(input3)
  let out2_3 = process_image(out1_3, "edge_detect")
  let final3 = to_titlecase(out2_3)
  
  println("\n🎊 最终结果: " + final3)

  // --- 完成 ---
  println("\n" + repeat_string("═", 60))
  println("✅ MVP 演示完成!")
  println("\n📝 核心要点:")
  println("   1. 链式骨架: 固定的能力执行模式")
  println("   2. 树形器官: 可插拔的能力积木 (greeter, logger, formatter, etc.)")
  println("   3. 配置驱动: 通过不同能力组合和参数改变行为")
  println("   4. 计算细胞: 每个能力都是独立的功能单元")
  println("\n🚀 下一步: 加入 Wasm 组件支持、真实硬件接口...")
  println("═══════════════════════════════════════════════════════════════")
}

// --- 能力积木 ---

fn log_info(msg: String) -> String {
  println("[INFO] " + msg)
  msg
}

fn log_warn(msg: String) -> String {
  println("[WARN] " + msg)
  msg
}

fn greet(msg: String, greeting: String) -> String {
  greeting + ", " + msg + "!"
}

fn to_uppercase(msg: String) -> String {
  msg.to_upper()
}

fn to_lowercase(msg: String) -> String {
  msg.to_lower()
}

fn to_titlecase(msg: String) -> String {
  // 简化版本
  msg.to_upper()
}

fn process_image(img: String, op: String) -> String {
  if op == "edge_detect" {
    "EdgeDetect[" + img + "]"
  } else if op == "grayscale" {
    "Grayscale[" + img + "]"
  } else if op == "blur" {
    "Blur[" + img + "]"
  } else {
    "Process[" + op + "][" + img + "]"
  }
}

fn repeat_string(s: String, n: Int) -> String {
  let mut result = ""
  let mut i = 0
  while i < n {
    result = result + s
    i = i + 1
  }
  result
}
