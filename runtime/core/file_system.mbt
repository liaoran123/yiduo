/// 文件系统函数表
/// 与 WasmRuntime 一致的函数表模式，兼容所有 MoonBit 后端
/// 支持：原生文件读取（native FFI）| 模拟文件系统（测试用）
///
/// CRUD 操作：read / write / delete / exists

///|
/// 文件系统函数表
pub struct FileSystem {
  read_to_string : (String) -> Result[String, String]
  list_dir : (String) -> Result[Array[String], String]
  write_to_string : (String, String) -> Result[Unit, String]
  delete_file : (String) -> Result[Unit, String]
  file_exists : (String) -> Bool
}

///|
/// 创建完整文件系统实例（所有 CRUD 操作）
pub fn FileSystem::from_fields_full(
  read_to_string : (String) -> Result[String, String],
  list_dir : (String) -> Result[Array[String], String],
  write_to_string : (String, String) -> Result[Unit, String],
  delete_file : (String) -> Result[Unit, String],
  file_exists : (String) -> Bool,
) -> FileSystem {
  FileSystem::{
    read_to_string,
    list_dir,
    write_to_string,
    delete_file,
    file_exists,
  }
}

///|
/// 创建只读文件系统实例（向后兼容，不支持的操作为 stub）
pub fn FileSystem::from_fields(
  read_to_string : (String) -> Result[String, String],
  list_dir : (String) -> Result[Array[String], String],
) -> FileSystem {
  let write_stub : (String, String) -> Result[Unit, String] = fn(_, _) {
    Err("write not supported")
  }
  let delete_stub : (String) -> Result[Unit, String] = fn(_) {
    Err("delete not supported")
  }
  let exists_stub : (String) -> Bool = fn(_) { false }
  FileSystem::{
    read_to_string,
    list_dir,
    write_to_string: write_stub,
    delete_file: delete_stub,
    file_exists: exists_stub,
  }
}
