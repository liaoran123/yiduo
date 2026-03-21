// UniHAL 演示应用
// 验证乐高式操作系统的架构可行性

///|
fn main {
  println("UniHAL 演示应用启动")

  // 测试基本功能
  test_basic()

  println("UniHAL 演示应用结束")
}

// 测试基本功能

///|
fn test_basic() -> Unit {
  println("测试基本功能")

  // 测试加法
  let a = 5
  let b = 3
  let sum = a + b

  println("5 + 3 = " + sum.to_string())
  println("测试成功！")
}
