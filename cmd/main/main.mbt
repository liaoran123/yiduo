///|
/// Entry point for the CLI or runnable program in this template.
/// Keep main focused; move logic into the library package.
/// Run with `moon run cmd/main` from the project root.
extern "C" fn add(a: Int, b: Int) -> Int = "add"

fn main {
  let sum = add(5, 3)
  println("5 + 3 = " + sum.to_string())
  println("Hello，九章，下一代跨语言原生操作系统")
}
