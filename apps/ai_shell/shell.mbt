// apps/ai_shell/shell.mbt
// 编译目标：Wasm (安全沙箱)

/// 定义 NPU 推理接口 (WIT 绑定)
/// @component "npu" "infer"
fn npu_infer(model_path: String, input_data: List[Float]) -> List[Float]

/// 定义文件系统接口 (WASI)
/// @component "wasi:filesystem" "read"
fn read_file(path: String) -> Result[String, String]

fn main {
  println("一多 AI 终端启动")
  
  // 1. 读取配置 (WASI)
  match read_file("/config/model.cfg") {
    Ok(cfg) => println("配置加载成功"),
    Err(e) => println("配置错误: " + e)
  }

  // 2. 调用 NPU 驱动 (Native FFI)
  // 注意：这里通过组件模型调用，底层由 Native 实现
  let result = npu_infer(
    "/models/llm_v3.wasm",
    [0.1, 0.5, 0.9]
  )
  
  println("AI 推理结果: " + result.to_string())
}