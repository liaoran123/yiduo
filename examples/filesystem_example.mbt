// 文件系统服务示例
/// @component "services/filesystem" "read_file"
fn read_file(path: String) -> Result[String, String]

/// @component "services/filesystem" "write_file"
fn write_file(path: String, content: String) -> Result[Unit, String]

/// @component "services/filesystem" "list_dir"
fn list_dir(path: String) -> Result[List[String], String]

fn main {
  println("文件系统服务示例")
  
  // 写入文件
  let write_result = write_file("/tmp/example.txt", "Hello from Yiduo OS!")
  match write_result {
    Ok(_) => println("文件写入成功"),
    Err(e) => println("文件写入失败: " + e)
  }
  
  // 读取文件
  let read_result = read_file("/tmp/example.txt")
  match read_result {
    Ok(content) => println("文件内容: " + content),
    Err(e) => println("文件读取失败: " + e)
  }
  
  // 列出目录
  let list_result = list_dir("/tmp")
  match list_result {
    Ok(files) => println("目录内容: " + files.to_string()),
    Err(e) => println("目录列出失败: " + e)
  }
}