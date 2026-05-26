/// 一多 OS 自举入口（简化版）
/// 移除了能力发现，直接使用 ID 通信

/// 主入口
pub fn main() {
  println("══════════════════════════════════════════════")
  println("║ 一多 OS - 自举验证 (简化版) ║")
  println("══════════════════════════════════════════════")
  
  // 1. 极小启动器初始化
  println("\n[Step 1] 初始化调度器...")
  let mut scheduler = @scheduler.create()
  println("[OK] 调度器初始化完成")
  
  // 2. 调度核心自注册 (ID 0)
  println("\n[Step 2] 注册调度核心 (ID 0)...")
  let scheduler_core_info = @scheduler.ComponentInfo::{
    name: "scheduler-core",
    component_type: @scheduler.COMPONENT_TYPE_NATIVE_CORE,
    status: @scheduler.ComponentStatus.Running
  }
  let (mut s0, core_id) = @scheduler.register(scheduler, scheduler_core_info)
  println("[OK] 调度核心注册成功，ID: " + core_id.to_string())
  scheduler = s0
  
  // 3. 加载配置
  println("\n[Step 3] 加载自举配置...")
  match @config.load_bootstrap() {
    Ok(config) => {
      println("[OK] 配置加载成功: " + config.metadata.name)
      
      // 4. 配置驱动组件注册
      println("\n[Step 4] 配置驱动注册组件...")
      let mut component_ids: List[Int] = []
      let mut index = 1
      
      for comp_config in config.spec.components {
        let comp_info = @scheduler.ComponentInfo::{
          name: comp_config.name,
          component_type: comp_config.component_type,
          status: @scheduler.ComponentStatus.Created
        }
        
        let (s_updated, comp_id) = @scheduler.register(scheduler, comp_info)
        println("- 注册组件: " + comp_config.name + " (ID: " + comp_id.to_string() + ")")
        scheduler = s_updated
        component_ids = comp_id :: component_ids
        index = index + 1
      }
      
      // 5. 测试消息分发
      println("\n[Step 5] 测试消息分发...")
      
      // 测试：发送消息给自己
      let test_payload = @core.SmallPayload{msg_type: 1, data: []}
      println("- 发送测试消息给调度核心 (ID 0)...")
      let (s1, ok) = @scheduler.send_small(scheduler, @scheduler.SCHEDULER_CORE_ID, @scheduler.SCHEDULER_CORE_ID, test_payload, @core.MessagePriority.Normal)
      if ok {
        println("[OK] 消息发送成功")
      } else {
        println("[ERR] 消息发送失败")
      }
      scheduler = s1
      
      // 6. 运行调度循环
      println("\n[Step 6] 运行调度循环 (迭代 5 次)...")
      let s_final = @scheduler.run_loop(scheduler, 5)
      scheduler = s_final
      
      // 7. 打印状态
      println("\n[Final] 自举验证完成！")
      @scheduler.print_status(scheduler)
      
    },
    Err(msg) => {
      println("[ERR] 配置加载失败: " + msg)
    }
  }
  
  println("\n══════════════════════════════════════════════")
  println("║ 自举闭环验证完成！ ║")
  println("══════════════════════════════════════════════")
}
