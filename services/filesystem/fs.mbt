// 文件系统服务
// 编译目标：Wasm (沙箱运行)

/// 导入 WASI 文件系统接口
import wasi:filesystem

/// 读取文件
fn read_file(path: String) -> Result[String, String] {
  match filesystem::read(path) {
    Ok(bytes) => Ok(bytes.to_string()),
    Err(e) => Err("读取错误: " + e)
  }
}

/// 写入文件
fn write_file(path: String, content: String) -> Result[Unit, String] {
  filesystem::write(path, content.to_bytes())
}

/// 列出目录
fn list_dir(path: String) -> Result[List[String], String] {
  filesystem::readdir(path)
}