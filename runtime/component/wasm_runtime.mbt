/// 🏗️ 一多 OS Wasm 运行时抽象接口
/// 函数表模式——兼容 MoonBit 无 trait 约束的类型系统
/// 支持：L0 模拟模式（测试/开发）| L2 WAMR 外部运行时

///|
/// Wasm 运行时函数表
/// invoke    : 调用 Wasm 组件消息处理器
/// register  : 注册消息处理函数（L0 模拟模式用，L2 为 no-op）
/// load      : 加载 Wasm 二进制字节码并实例化（L2 用，L0 为 no-op）
/// deallocate: 释放 Wasm 组件资源
pub struct WasmRuntime {
  invoke : (Int, Int, @core.SmallPayload) -> Unit
  register : (Int, NativeMessageHandler) -> Unit
  load : (Int, Bytes) -> Result[Unit, String]
  deallocate : (Int) -> Unit
}

///|
/// 创建模拟 Wasm 运行时（L0 兼容模式）
/// 使用同进程 NativeMessageHandler 模拟 Wasm 组件执行
/// 参数 max_handlers：最大支持的 Wasm 组件数量
pub fn WasmRuntime::create_simulated(max_handlers : Int) -> WasmRuntime {
  let handlers = FixedArray::make(max_handlers, None)

  let invoke = fn(comp_id : Int, from_id : Int, payload : @core.SmallPayload) {
    match handlers[comp_id] {
      Some(handler) => handler(comp_id, from_id, payload)
      None => ()
    }
  }

  let register = fn(comp_id : Int, handler : NativeMessageHandler) {
    handlers[comp_id] = Some(handler)
  }

  let load = fn(_comp_id : Int, _wasm_bytes : Bytes) -> Result[Unit, String] {
    Ok(())
  }

  let deallocate = fn(comp_id : Int) { handlers[comp_id] = None }

  WasmRuntime::{ invoke, register, load, deallocate }
}

///|
/// 从函数表构造 WasmRuntime（供外部包创建实例）
pub fn WasmRuntime::from_fields(
  invoke : (Int, Int, @core.SmallPayload) -> Unit,
  register : (Int, NativeMessageHandler) -> Unit,
  load : (Int, Bytes) -> Result[Unit, String],
  deallocate : (Int) -> Unit,
) -> WasmRuntime {
  WasmRuntime::{ invoke, register, load, deallocate }
}
