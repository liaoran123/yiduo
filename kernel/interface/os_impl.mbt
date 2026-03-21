// OS 接口实现
import "../drivers/uart"

// 实现 log 函数
fn log_impl(msg: String) -> Unit {
  uart::uart_puts(msg + "\n")
}

// 注册接口
fn register_os_interface() -> Unit {
  // 注册 log 函数到 Wasm 运行时
}