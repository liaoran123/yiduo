// Hello World 应用
/// @component "base" "log"
fn log(msg: String) -> Result[Unit, Error]

/// @component "base" "time"
fn current_time() -> Result[UInt64, Error]

fn main {
  log("Hello World from Wasm!")
  let time = current_time()
  log("Current time: " + time.to_string())
  log("Hello from Native!")
}