// 问候能力积木
// 简单的问候功能

struct Greeter {
  greeting: String
}

///| 创建问候能力
fn Greeter::new(greeting: String) -> Greeter {
  { greeting: greeting }
}

///| 实现 Component trait
impl Component for Greeter {
  fn name(self) -> String { "greeter" }
  fn init(self) -> Result[Unit, String] { Ok(()) }
  fn cleanup(self) -> Unit {}
}

///| 实现 Capability trait
impl Capability for Greeter {
  fn capability_name(self) -> String { "greeter" }
  
  fn execute(self, input: String) -> Result[String, String] {
    Ok(self.greeting + ", " + input + "!")
  }
}
