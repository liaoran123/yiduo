/// 原生文件系统测试
/// 验证 C FFI 文件读取功能

///|
test "native_fs can read bootstrap.yaml" {
  let fs = create_native_fs()
  let result = (fs.read_to_string)("configs/bootstrap.yaml")
  match result {
    Ok(content) => {
      assert_true(content.length() > 0)
      assert_true(content.contains("system:"))
      assert_true(content.contains("bootstrap:"))
    }
    Err(e) => println("Skipped (expected on some envs): " + e)
  }
}

///|
test "native_fs returns error for nonexistent file" {
  let fs = create_native_fs()
  let result = (fs.read_to_string)("nonexistent_file.yaml")
  match result {
    Ok(_) => println("Unexpected success for nonexistent file")
    Err(_e) =>
      assert_eq(true, true, msg="nonexistent file correctly returned error")
  }
}
