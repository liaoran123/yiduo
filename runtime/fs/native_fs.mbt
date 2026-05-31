/// 原生文件系统实现（native FFI）
/// 在 native 目标下从磁盘读取文件
/// 支持完整 CRUD：read / write / delete / exists

///|
#borrow(path)
extern "C" fn _fs_read_file(path : String) -> Int = "fs_read_file"

///|
extern "C" fn _fs_get_content() -> String = "fs_get_content"

///|
extern "C" fn _fs_last_error() -> String = "fs_last_error"

///|
#borrow(dir)
extern "C" fn _fs_list_dir(dir : String) -> Int = "fs_list_dir"

///|
extern "C" fn _fs_get_list_result() -> String = "fs_get_list_result"

///|
#borrow(path)
#borrow(content)
extern "C" fn _fs_write_file(path : String, content : String) -> Int = "fs_write_file"

///|
#borrow(path)
extern "C" fn _fs_delete_file(path : String) -> Int = "fs_delete_file"

///|
#borrow(path)
extern "C" fn _fs_file_exists(path : String) -> Int = "fs_file_exists"

///|
/// 读取文件内容（原生实现）
fn read_file_native(path : String) -> Result[String, String] {
  let ret = _fs_read_file(path)
  if ret == 0 {
    Ok(_fs_get_content())
  } else {
    Err(_fs_last_error())
  }
}

///|
/// 列出目录内容（原生实现）
fn list_dir_native(dir : String) -> Result[Array[String], String] {
  let ret = _fs_list_dir(dir)
  if ret == 0 {
    let content = _fs_get_list_result()
    let entries = content.split("\n")
    let result : Array[String] = []
    for entry in entries {
      let trimmed = entry.trim()
      if trimmed != "" {
        result.push(trimmed.to_owned())
      }
    }
    Ok(result)
  } else {
    Err(_fs_last_error())
  }
}

///|
/// 写入文件（原生实现）
fn write_file_native(path : String, content : String) -> Result[Unit, String] {
  let ret = _fs_write_file(path, content)
  if ret == 0 {
    Ok(())
  } else {
    Err(_fs_last_error())
  }
}

///|
/// 删除文件（原生实现）
fn delete_file_native(path : String) -> Result[Unit, String] {
  let ret = _fs_delete_file(path)
  if ret == 0 {
    Ok(())
  } else {
    Err(_fs_last_error())
  }
}

///|
/// 检查文件是否存在（原生实现）
fn file_exists_native(path : String) -> Bool {
  _fs_file_exists(path) != 0
}

///|
/// 创建原生文件系统实例
/// 返回一个 FileSystem 函数表，其所有 CRUD 操作使用 C FFI 访问磁盘
pub fn create_native_fs() -> @core.FileSystem {
  @core.FileSystem::from_fields_full(
    read_file_native, list_dir_native, write_file_native, delete_file_native, file_exists_native,
  )
}
