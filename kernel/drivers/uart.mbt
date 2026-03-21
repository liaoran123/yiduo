// 串口驱动
type UART = {
  base: UInt16
}

// 初始化串口
fn uart_init(port: UInt16) -> Unit {
  // 设置波特率
  let divisor = 115200 / 9600
  outb(port + 3, 0x80)  // 设置 DLAB
  outb(port, divisor & 0xFF)
  outb(port + 1, (divisor >> 8) & 0xFF)
  outb(port + 3, 0x03)  // 8位数据，1位停止位，无校验
  outb(port + 1, 0x00)  // 禁用中断
  outb(port + 2, 0xC7)  // 启用 FIFO，清空，设置触发级别
  outb(port + 4, 0x0B)  // IRQs 启用，RTS/DSR 设置
}

// 输出字符到串口
fn uart_putc(c: Char) -> Unit {
  let port = 0x3F8  // COM1
  // 等待发送缓冲区为空
  while (inb(port + 5) & 0x20) == 0 {}
  // 发送字符
  outb(port, c.to_int())
}

// 输出字符串到串口
fn uart_puts(s: String) -> Unit {
  for c in s.chars() {
    uart_putc(c)
  }
}

// 底层 I/O 函数
@native c "outb"
fn outb(port: UInt16, value: UInt8) -> Unit

@native c "inb"
fn inb(port: UInt16) -> UInt8