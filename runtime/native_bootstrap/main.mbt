/// 一多 OS 原生入口（native 目标）
/// 从磁盘读取 configs/bootstrap.yaml，扫描 configs/components/ 发现组件

///|
/// 原生主入口
fn main {
  println("[NativeBootstrap] 从磁盘加载配置...")
  let fs = @fs.create_native_fs()
  match @config.load_bootstrap_from_fs(fs, "configs/bootstrap.yaml") {
    Ok(config) => {
      println("[NativeBootstrap] 配置加载成功，扫描组件目录...")
      match @config.scan_component_dir(fs, "configs/components") {
        Ok(components) => {
          println(
            "[NativeBootstrap] 发现 " +
            components.length().to_string() +
            " 个组件，启动自举流程",
          )
          @boot.run(config, components)
        }
        Err(msg) => println("[ERR] 组件扫描失败: " + msg)
      }
    }
    Err(msg) => println("[ERR] 配置加载失败: " + msg)
  }
}
