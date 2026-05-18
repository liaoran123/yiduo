// Hello World 应用

///|
/// @component "base" "log"
fn log(msg : String) -> Unit {
  // 简化实现，实际会调用 Native 实现
}

///|
/// @component "base" "time"
fn current_time() -> UInt64 {
  // 简化实现，实际会调用 Native 实现
  0
}

///|
fn main {
  log("Hello World from Wasm!")
  let time = current_time()
  log("Current time: " + time.to_string())
  log("Hello from Native!")
}
