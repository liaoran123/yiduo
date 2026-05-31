/// 🧪 一多 OS WAMR 外部运行时单元测试
/// 验证 WAMR 运行时的创建、加载、调用等核心接口
/// 当前为 stub 模式（WAMR 库未链接），测试验证接口正确性和不崩溃

///|
test "wamr_runtime_create" {
  let rt = create_wamr(16)

  let _invoke = rt.invoke
  let _register = rt.register
  let _load = rt.load
  let _deallocate = rt.deallocate

  assert_eq(true, true, msg="WAMR 运行时创建成功")
}

///|
test "wamr_load_stub_returns_error" {
  let rt = create_wamr(16)

  let wasm_bytes : Bytes = Bytes::new(8)
  let result = (rt.load)(0, wasm_bytes)

  match result {
    Err(msg) =>
      assert_eq(
        msg.contains("WAMR"),
        true,
        msg="stub 模式应返回 WAMR 相关错误",
      )
    Ok(_) => assert_true(false, msg="stub 模式不应加载成功")
  }
}

///|
test "wamr_invoke_unloaded_no_crash" {
  let rt = create_wamr(16)
  let payload = @core.SmallPayload::create(0, [])
  (rt.invoke)(0, 1, payload)
  assert_eq(true, true, msg="未加载组件时 invoke 不应崩溃")
}

///|
test "wamr_deallocate_unloaded_no_crash" {
  let rt = create_wamr(16)
  (rt.deallocate)(0)
  assert_eq(true, true, msg="未加载组件时 deallocate 不应崩溃")
}

///|
test "wamr_load_out_of_bounds_error" {
  let rt = create_wamr(4)
  let wasm_bytes : Bytes = Bytes::new(4)

  let result_neg = (rt.load)(-1, wasm_bytes)
  match result_neg {
    Err(msg) =>
      assert_eq(
        msg.contains("超出范围"),
        true,
        msg="负数 comp_id 应提示超出范围",
      )
    Ok(_) => assert_true(false, msg="负数 comp_id 不应加载成功")
  }

  let result_overflow = (rt.load)(10, Bytes::new(4))
  match result_overflow {
    Err(msg) =>
      assert_eq(
        msg.contains("超出范围"),
        true,
        msg="越界 comp_id 应提示超出范围",
      )
    Ok(_) => assert_true(false, msg="越界 comp_id 不应加载成功")
  }
}
