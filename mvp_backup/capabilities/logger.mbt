// 日志能力积木
// 记录输入信息

struct Logger {
  level: String
}

///| 创建日志能力
fn Logger::new(level: String) -> Logger {
  { level: level }
}

///| 实现 Component trait
impl Component for Logger {
  fn name(self) -> String { "logger" }
  fn init(self) -> Result[Unit, String] { Ok(()) }
  fn cleanup(self) -> Unit {}
}

///| 实现 Capability trait
impl Capability for Logger {
  fn capability_name(self) -> String { "logger" }
  
  fn execute(self, input: String) -> Result[String, String] {
    let level_str = match self.level {
      | "info" => "INFO",
      | "warn" => "WARN",
      | "error" => "ERROR",
      | _ => "INFO",
    }
    println("[" + level_str + "] " + input)
    Ok(input)
  }
}
