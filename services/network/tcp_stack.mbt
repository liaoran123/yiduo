// services/network/tcp_stack.mbt
// 编译目标：Wasm (沙箱运行)

/// 导入 WASI 网络接口
import wasi:io
import wasi:sockets/tcp

/// 处理 TCP 连接
fn handle_connection(conn: tcp:Socket) -> Result[Unit, String] {
  let data = io:read(conn, 1024)
  match data {
    Ok(bytes) => {
      println("收到数据: " + bytes.to_string())
      io:write(conn, "HTTP/1.1 200 OK\r\nHello from Yiduo OS")
      Ok(())
    }
    Err(e) => Err("读取错误: " + e)
  }
}

/// 启动 TCP 服务器
fn start_server(port: Int) -> tcp:Socket {
  let sock = tcp:Socket::new_ipv4()
  tcp:bind(sock, "0.0.0.0", port)
  tcp:listen(sock, 10)
  println("TCP 服务已启动，端口: " + port.to_string())
  sock
}