// OS 接口实现
import "../drivers/uart"
import "../../runtime/wasm/loader"

// 实现 log 函数
fn log_impl(msg: String) -> Unit {
  uart::uart_puts(msg + "\n")
}

// 注册接口
fn register_os_interface() -> Unit {
  // 注册 log 函数到 Wasm 运行时
  wasm::register_function("log", log_impl)
}

// 实现时间接口
fn current_time_impl() -> UInt64 {
  // 简单返回 0，实际实现需要读取硬件时钟
  0
}

// 注册时间接口
fn register_time_interface() -> Unit {
  wasm::register_function("current_time", current_time_impl)
}