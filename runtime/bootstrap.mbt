/// 一多 OS 自举入口（wasm-gc / 通用目标）
/// 使用硬编码配置字符串，适用于 wasm-gc 和快速验证场景
/// Native 环境使用 runtime/native_bootstrap（从磁盘读取 bootstrap.yaml + 扫描组件目录）

///|
/// 硬编码的 Bootstrap YAML 配置（wasm-gc 环境无法读取文件系统）
const HARDCODED_BOOTSTRAP_YAML : String =
  #|system:
  #|  name: Yiduo OS MVP
  #|  version: 0.1.0
  #|  description: 一多操作系统最小启动器
  #|runtime:
  #|  max-components: 32
  #|  max-memory-per-instance: 64
  #|  runtime-type: simulated
  #|bootstrap:
  #|  mode: minimal
  #|  log-level: info
  #|  first-component: wasm-runtime

///|
/// 硬编码的组件描述列表（wasm-gc 环境无法扫描目录）
fn hardcoded_components() -> Array[@config.ComponentDescriptor] {
  [
    @config.ComponentDescriptor::create(
      "scheduler",
      Some("yiduo.sys"),
      Some("0.1.0"),
      "native",
      Some("builtin/scheduler"),
      true,
      Some("系统调度器 - 核心调度单元"),
      [
        @config.InterfaceEntry::create(
          "yiduo:sys/scheduler",
          None,
          Some("组件调度和消息路由"),
        ),
      ],
      [
        @config.DependencyEntry::create(
          "memory",
          "yiduo:sys/memory",
          true,
          None,
          Some("内存管理能力"),
        ),
      ],
    ),
    @config.ComponentDescriptor::create(
      "logger",
      Some("yiduo.sys"),
      Some("0.1.0"),
      "native",
      Some("builtin/logger"),
      true,
      Some("日志服务组件 - 系统日志记录"),
      [
        @config.InterfaceEntry::create(
          "yiduo:sys/log",
          None,
          Some("日志记录能力"),
        ),
      ],
      [],
    ),
    @config.ComponentDescriptor::create(
      "counter",
      Some("yiduo.lib"),
      Some("0.1.0"),
      "wasm",
      Some("builtin/counter"),
      true,
      Some("计数器组件 - 演示用"),
      [
        @config.InterfaceEntry::create(
          "yiduo:lib/counter",
          None,
          Some("数值计数功能"),
        ),
      ],
      [],
    ),
    @config.ComponentDescriptor::create(
      "display",
      Some("yiduo.cap"),
      Some("0.1.0"),
      "wasm",
      Some("builtin/display"),
      true,
      Some("显示器组件 - 结果展示"),
      [
        @config.InterfaceEntry::create(
          "yiduo:cap/display",
          None,
          Some("数据展示能力"),
        ),
      ],
      [
        @config.DependencyEntry::create(
          "scheduler",
          "yiduo:sys/scheduler",
          true,
          None,
          Some("依赖调度器接收消息"),
        ),
      ],
    ),
  ]
}

///|
/// 主入口
fn main {
  println("[Bootstrap] 使用硬编码配置启动（wasm-gc/通用目标）")
  match @config.parse_bootstrap_yaml(HARDCODED_BOOTSTRAP_YAML) {
    Ok(config) => {
      let components = hardcoded_components()
      @boot.run(config, components)
    }
    Err(msg) => println("[ERR] 配置加载失败: " + msg)
  }
}
