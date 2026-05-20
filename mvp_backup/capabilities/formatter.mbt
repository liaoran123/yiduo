// 格式化能力积木
// 字符串格式化功能

struct Formatter {
  format: String
}

///| 创建格式化能力
fn Formatter::new(format: String) -> Formatter {
  { format: format }
}

///| 实现 Component trait
impl Component for Formatter {
  fn name(self) -> String { "formatter" }
  fn init(self) -> Result[Unit, String] { Ok(()) }
  fn cleanup(self) -> Unit {}
}

///| 辅助函数：首字母大写
fn to_titlecase(s: String) -> String {
  if s.length() == 0 {
    return s
  }
  let first = s.slice(0, 1).to_upper()
  let rest = s.slice(1, s.length()).to_lower()
  first + rest
}

///| 实现 Capability trait
impl Capability for Formatter {
  fn capability_name(self) -> String { "formatter" }
  
  fn execute(self, input: String) -> Result[String, String] {
    match self.format {
      | "uppercase" => Ok(input.to_upper()),
      | "lowercase" => Ok(input.to_lower()),
      | "titlecase" => Ok(to_titlecase(input)),
      | _ => Err("Unknown format: " + self.format),
    }
  }
}
