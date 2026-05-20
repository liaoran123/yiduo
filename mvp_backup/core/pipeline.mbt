// 能力执行流水线
// 将多个能力积木按顺序组合执行

///| 执行能力流水线
fn execute_pipeline(
  config: AppConfig,
  registry: ComponentRegistry,
  input: String
) -> Result[String, String] {
  println("\n🚀 开始执行流水线...")
  println("   输入: " + input)
  
  let mut current = input
  let mut step = 1
  
  for cap_name in config.capability_order {
    match registry.get_capability(cap_name) {
      | Some(cap) => {
        println("\n   步骤 " + step.to_string() + ": 执行 " + cap_name)
        match cap.execute(current) {
          | Ok(result) => {
            println("      输出: " + result)
            current = result
            step = step + 1
          }
          | Err(e) => {
            println("      ✗ 错误: " + e)
            return Err("能力执行失败 " + cap_name + ": " + e)
          }
        }
      }
      | None => {
        return Err("找不到能力: " + cap_name)
      }
    }
  }
  
  println("\n✅ 流水线执行完成!")
  Ok(current)
}
