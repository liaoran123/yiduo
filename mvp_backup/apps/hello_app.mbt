// Hello World MVP 应用
// 演示配置驱动 + 能力积木组合

///| 主函数
fn main() -> Unit {
  println("═══════════════════════════════════════════════════════════════")
  println("    一多操作系统 - MVP 演示")
  println("    配置驱动 + 计算细胞 + 组合式设计")
  println("═══════════════════════════════════════════════════════════════")
  
  // ================== 1. 初始化组件注册表 ==================
  println("\n📦 阶段 1: 初始化组件注册表")
  println("   注册能力积木...")
  
  let registry = ComponentRegistry::new()
  
  // 注册所有可用的能力积木（树形器官）
  registry.register_capability(Greeter::new("Hello"))
  registry.register_capability(Logger::new("info"))
  registry.register_capability(Formatter::new("uppercase"))
  registry.register_capability(ImageProcessor::new("grayscale"))
  
  println("\n✨ 已注册的能力积木:")
  for name in registry.list_capabilities() {
    println("   - " + name)
  }
  
  // ================== 2. 加载配置（DNA） ==================
  println("\n📄 阶段 2: 加载应用配置")
  
  // Hello 配置
  let hello_config_yaml = """
app_name: "Hello MVP"
enabled_capabilities:
  - "logger"
  - "greeter"
  - "formatter"
capability_order:
  - "logger"
  - "greeter"
  - "formatter"
custom_settings:
  greeter.greeting: "Hello"
  formatter.format: "uppercase"
  logger.level: "info"
"""
  
  let hello_config = load_config_from_string(hello_config_yaml)?
  print_config(hello_config)
  
  // ================== 3. 验证配置 ==================
  println("\n🔍 阶段 3: 验证配置")
  match validate_config(hello_config, registry) {
    | Ok(_) => println("   ✓ 配置验证通过!"),
    | Err(e) => {
      println("   ✗ 配置验证失败: " + e)
      return
    }
  }
  
  // ================== 4. 执行流水线 ==================
  println("\n🎯 演示 1: Hello World (默认配置)")
  match execute_pipeline(hello_config, registry, "World") {
    | Ok(result) => println("\n🎊 最终结果: " + result),
    | Err(e) => println("\n✗ 执行失败: " + e),
  }
  
  // ================== 5. 演示：修改配置改变行为 ==================
  println("\n" + "═".repeat(60))
  println("🎯 演示 2: 修改配置 - 改变问候语和格式")
  println("   (无需改代码，只需改配置!)")
  
  let hello_config_yaml_v2 = """
app_name: "Hello MVP v2"
enabled_capabilities:
  - "logger"
  - "greeter"
  - "formatter"
capability_order:
  - "logger"
  - "greeter"
  - "formatter"
custom_settings:
  greeter.greeting: "Hi"
  formatter.format: "lowercase"
  logger.level: "warn"
"""
  
  let hello_config_v2 = load_config_from_string(hello_config_yaml_v2)?
  print_config(hello_config_v2)
  
  match execute_pipeline(hello_config_v2, registry, "MoonBit") {
    | Ok(result) => println("\n🎊 最终结果: " + result),
    | Err(e) => println("\n✗ 执行失败: " + e),
  }
  
  // ================== 6. 演示：智能摄像头配置 ==================
  println("\n" + "═".repeat(60))
  println("🎯 演示 3: 智能摄像头 - 图像处理流水线")
  
  let camera_config_yaml = """
app_name: "Smart Camera MVP"
enabled_capabilities:
  - "logger"
  - "image_processor"
  - "formatter"
capability_order:
  - "logger"
  - "image_processor"
  - "formatter"
custom_settings:
  image_processor.operation: "edge_detect"
  formatter.format: "titlecase"
  logger.level: "info"
"""
  
  let camera_config = load_config_from_string(camera_config_yaml)?
  print_config(camera_config)
  
  match execute_pipeline(camera_config, registry, "raw_image_001.jpg") {
    | Ok(result) => println("\n🎊 最终结果: " + result),
    | Err(e) => println("\n✗ 执行失败: " + e),
  }
  
  // ================== 完成 ==================
  println("\n" + "═".repeat(60))
  println("✅ MVP 演示完成!")
  println("\n📝 核心要点:")
  println("   1. 链式骨架: 固定的 Component/Capability trait 接口")
  println("   2. 树形器官: 可插拔的能力积木 (greeter, logger, formatter, etc.)")
  println("   3. 配置即编程: YAML 文件定义能力组合和执行顺序")
  println("   4. 计算细胞: 每个能力都是独立的功能单元")
  println("\n🚀 下一步: 加入 Wasm 组件支持、真实硬件接口...")
  println("═══════════════════════════════════════════════════════════════")
}
