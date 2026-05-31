/// 🏗️ 一多 OS WAMR 外部运行时（L2）
/// 通过 MoonBit C-FFI 调用 WAMR（wasm-micro-runtime）的 C 胶水代码
/// 需要 WAMR 库 (libvmlib) 正确链接后才能正常运行
/// ⚠ 本包仅支持 native 目标（wasm-gc 不支持 C FFI）

///|
/// WAMR 运行时句柄封装
/// 持有 C 侧 WAMR runtime 句柄和 comp_id→instance 的映射
priv struct WAMRState {
  runtime_handle : Int
  instances : FixedArray[Int]
  total : Int
}

///|
/// WAMR 运行时全局状态初始化
extern "C" fn _wamr_runtime_init() -> Int = "wamr_runtime_init"

///|
/// 加载并实例化 Wasm 模块
#borrow(wasm)
extern "C" fn _wamr_module_load(
  runtime : Int,
  wasm : Bytes,
  wasm_size : Int,
  comp_id : Int,
) -> Int = "wamr_module_load"

///|
/// 调用 Wasm 组件消息处理函数
extern "C" fn _wamr_module_call(
  instance : Int,
  from_id : Int,
  msg_type : Int,
) -> Int = "wamr_module_call"

///|
/// 写入数据到 WAMR 线性内存
#borrow(data)
extern "C" fn _wamr_write_memory(
  instance : Int,
  offset : Int,
  data : Bytes,
  size : Int,
) -> Int = "wamr_write_memory"

///|
/// 从 WAMR 线性内存读取数据
#borrow(data)
extern "C" fn _wamr_read_memory(
  instance : Int,
  offset : Int,
  data : Bytes,
  size : Int,
) -> Int = "wamr_read_memory"

///|
/// 销毁 Wasm 实例
extern "C" fn _wamr_module_destroy(instance : Int) -> Unit = "wamr_module_destroy"

///|
/// 销毁 WAMR 运行时
extern "C" fn _wamr_runtime_destroy(runtime : Int) -> Unit = "wamr_runtime_destroy"

///|
/// 获取 WAMR 错误信息
extern "C" fn _wamr_last_error() -> String = "wamr_last_error"

///|
/// 创建 WAMR 外部运行时实例（L2 模式）
/// 参数 max_components：最大支持的 Wasm 组件数量
///
/// stub 模式：WAMR 库未链接时返回模拟实现
/// 真实模式：WAMR 库已链接时调用真实的 WAMR runtime
pub fn create_wamr(max_components : Int) -> @component.WasmRuntime {
  let runtime_handle = _wamr_runtime_init()
  let instances = FixedArray::make(max_components, -1)
  let state = WAMRState::{ runtime_handle, instances, total: max_components }

  let invoke = fn(comp_id : Int, from_id : Int, payload : @core.SmallPayload) {
    let instance = state.instances[comp_id]
    if instance < 0 {
      return
    }
    let _ret = _wamr_module_call(instance, from_id, payload.msg_type)
  }

  let register = fn(
    _comp_id : Int,
    _handler : @component.NativeMessageHandler,
  ) {

  }

  let load = fn(comp_id : Int, wasm_bytes : Bytes) -> Result[Unit, String] {
    if comp_id < 0 || comp_id >= state.total {
      return Err("WAMR: comp_id 超出范围")
    }
    let instance = _wamr_module_load(
      state.runtime_handle,
      wasm_bytes,
      wasm_bytes.length(),
      comp_id,
    )
    if instance < 0 {
      let err = _wamr_last_error()
      return Err("WAMR 加载失败: " + err)
    }
    state.instances[comp_id] = instance
    Ok(())
  }

  let deallocate = fn(comp_id : Int) {
    let instance = state.instances[comp_id]
    if instance >= 0 {
      _wamr_module_destroy(instance)
      state.instances[comp_id] = -1
    }
  }

  @component.WasmRuntime::from_fields(invoke, register, load, deallocate)
}
