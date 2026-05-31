/// 🔄 一多 OS 热更新协调器
/// 当组件配置文件发生变更时，自动触发组件的热更新流程
///
/// 热更新流程：
/// 1. ConfigManager 检测到配置变更（write/create/delete）
/// 2. HotUpdateCoordinator 监听变更事件
/// 3. 验证新配置的合法性
/// 4. 通知调度器执行热更新（停旧 → 注册新）

///|
/// 热更新结果
pub enum HotUpdateResult {
  Success(String)
  Skipped(String)
  Failed(String)
}

///|
pub fn HotUpdateResult::to_string(self : HotUpdateResult) -> String {
  match self {
    Success(name) => "[HotUpdate] 成功: " + name
    Skipped(reason) => "[HotUpdate] 跳过: " + reason
    Failed(err) => "[HotUpdate] 失败: " + err
  }
}

///|
/// 热更新协调器配置
pub struct HotUpdateConfig {
  enabled : Bool
  auto_register_on_create : Bool
  auto_unregister_on_delete : Bool
}

///|
pub fn HotUpdateConfig::default() -> HotUpdateConfig {
  HotUpdateConfig::{
    enabled: true,
    auto_register_on_create: true,
    auto_unregister_on_delete: true,
  }
}

///|
/// 执行热更新：配置变更 → 组件重新加载
pub fn apply_hot_update(
  change : ConfigChange,
  fs : @core.FileSystem,
  scheduler : @scheduler.Scheduler,
  _config_manager : ConfigManager,
  hot_config : HotUpdateConfig,
) -> (@scheduler.Scheduler, HotUpdateResult) {
  if !hot_config.enabled {
    return (scheduler, Skipped("热更新已禁用"))
  }

  match change.change_type {
    Updated =>
      if change.previous_hash == change.new_hash {
        (scheduler, Skipped("内容无变化: " + change.component_name))
      } else {
        handle_config_updated(change, scheduler)
      }
    Created =>
      if hot_config.auto_register_on_create {
        handle_config_created(change, scheduler)
      } else {
        (scheduler, Skipped("创建时自动注册已禁用"))
      }
    Deleted =>
      if hot_config.auto_unregister_on_delete {
        handle_config_deleted(change, scheduler)
      } else {
        (scheduler, Skipped("删除时自动停用已禁用"))
      }
  }
}

///|
/// 处理配置更新 → 热更新
fn handle_config_updated(
  change : ConfigChange,
  scheduler : @scheduler.Scheduler,
) -> (@scheduler.Scheduler, HotUpdateResult) {
  let component_name = change.component_name
  let old_id = scheduler.find_component_id(component_name)

  match old_id {
    Some(id) => {
      if scheduler.debug_log {
        println(
          "[HotUpdate] 热更新组件: " +
          component_name +
          " [旧ID:" +
          id.to_string() +
          "]",
        )
      }
      let scheduler1 = scheduler.unregister_handler(id)
      let scheduler2 = scheduler1.mark_component_stopped(id)
      let new_info = @scheduler.ComponentInfo::create_simple(
        component_name,
        @component.ComponentType::native(),
        @scheduler.ComponentStatus::running(),
      )
      let (scheduler3, _) = @scheduler.register(scheduler2, new_info)
      (scheduler3, Success(component_name))
    }
    None => {
      let new_info = @scheduler.ComponentInfo::create_simple(
        component_name,
        @component.ComponentType::native(),
        @scheduler.ComponentStatus::initialized(),
      )
      let (scheduler1, _) = @scheduler.register(scheduler, new_info)
      (scheduler1, Success(component_name))
    }
  }
}

///|
/// 处理配置创建 → 注册新组件
fn handle_config_created(
  change : ConfigChange,
  scheduler : @scheduler.Scheduler,
) -> (@scheduler.Scheduler, HotUpdateResult) {
  let component_name = change.component_name
  let new_info = @scheduler.ComponentInfo::create_simple(
    component_name,
    @component.ComponentType::native(),
    @scheduler.ComponentStatus::created(),
  )
  let (scheduler1, _) = @scheduler.register(scheduler, new_info)
  (scheduler1, Success(component_name))
}

///|
/// 处理配置删除 → 停用组件
fn handle_config_deleted(
  change : ConfigChange,
  scheduler : @scheduler.Scheduler,
) -> (@scheduler.Scheduler, HotUpdateResult) {
  let component_name = change.component_name
  match scheduler.find_component_id(component_name) {
    Some(id) => {
      if scheduler.debug_log {
        println("[HotUpdate] 删除配置，停用组件: " + component_name)
      }
      let scheduler1 = scheduler.unregister_handler(id)
      let scheduler2 = scheduler1.mark_component_stopped(id)
      (scheduler2, Success(component_name))
    }
    None => (scheduler, Skipped("组件未注册: " + component_name))
  }
}
