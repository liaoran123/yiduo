/// 一多 OS 配置管理器
/// 提供组件配置文件的 CRUD（增删改查）和热更新协调功能
///
/// 设计原则：
/// - 配置即代码（Configuration as Code）：YAML 文件是组件 DNA 的唯一真实来源
/// - 变化可追溯：每次配置变更记录版本号
/// - 热更新协调：配置变更 → 验证 → 通知调度器重新加载

///|
/// 配置变更记录
pub struct ConfigChange {
  file_path : String
  component_name : String
  change_type : ChangeType
  previous_hash : Int
  new_hash : Int
}

///|
/// 变更类型
pub enum ChangeType {
  Created
  Updated
  Deleted
}

///|
/// 配置变更类型转字符串
pub fn ChangeType::to_string(self : ChangeType) -> String {
  match self {
    Created => "created"
    Updated => "updated"
    Deleted => "deleted"
  }
}

///|
/// 配置管理器
pub struct ConfigManager {
  config_dir : String
  listener_next_id : Int
  listeners : Array[(Int, (ConfigChange) -> Unit)]
  change_history : Array[ConfigChange]
}

///|
pub fn ConfigManager::create(config_dir : String) -> ConfigManager {
  ConfigManager::{
    config_dir,
    listener_next_id: 1,
    listeners: [],
    change_history: [],
  }
}

/// ==================== CRUD 操作 ====================

///|
/// 读取配置文件内容（返回原始 YAML 字符串）
pub fn ConfigManager::read_config(
  self : ConfigManager,
  fs : @core.FileSystem,
  file_name : String,
) -> Result[String, String] {
  let file_path = self.config_dir + "/" + file_name
  (fs.read_to_string)(file_path)
}

///|
/// 读取并解析组件配置文件
pub fn ConfigManager::read_and_parse(
  self : ConfigManager,
  fs : @core.FileSystem,
  file_name : String,
) -> Result[ComponentDescriptor, String] {
  let file_path = self.config_dir + "/" + file_name
  load_component_descriptor_from_fs(fs, file_path)
}

///|
/// 写入配置文件
pub fn ConfigManager::write_config(
  self : ConfigManager,
  fs : @core.FileSystem,
  file_name : String,
  content : String,
) -> Result[ConfigChange, String] {
  let file_path = self.config_dir + "/" + file_name
  let old_hash = read_file_hash(fs, file_path)
  match (fs.write_to_string)(file_path, content) {
    Ok(_) => {
      let new_hash = hash_string(content)
      let change = ConfigChange::{
        file_path,
        component_name: file_name,
        change_type: Updated,
        previous_hash: old_hash,
        new_hash,
      }
      Ok(change)
    }
    Err(e) => Err(e)
  }
}

///|
/// 创建新配置文件
pub fn ConfigManager::create_config(
  self : ConfigManager,
  fs : @core.FileSystem,
  file_name : String,
  content : String,
) -> Result[ConfigChange, String] {
  let file_path = self.config_dir + "/" + file_name
  if (fs.file_exists)(file_path) {
    return Err("文件已存在: " + file_path)
  }
  match (fs.write_to_string)(file_path, content) {
    Ok(_) => {
      let change = ConfigChange::{
        file_path,
        component_name: file_name,
        change_type: Created,
        previous_hash: 0,
        new_hash: hash_string(content),
      }
      Ok(change)
    }
    Err(e) => Err(e)
  }
}

///|
/// 删除配置文件
pub fn ConfigManager::delete_config(
  self : ConfigManager,
  fs : @core.FileSystem,
  file_name : String,
) -> Result[ConfigChange, String] {
  let file_path = self.config_dir + "/" + file_name
  let old_hash = read_file_hash(fs, file_path)
  match (fs.delete_file)(file_path) {
    Ok(_) => {
      let change = ConfigChange::{
        file_path,
        component_name: file_name,
        change_type: Deleted,
        previous_hash: old_hash,
        new_hash: 0,
      }
      Ok(change)
    }
    Err(e) => Err(e)
  }
}

///|
/// 列出所有配置文件
pub fn ConfigManager::list_configs(
  self : ConfigManager,
  fs : @core.FileSystem,
) -> Result[Array[String], String] {
  match (fs.list_dir)(self.config_dir) {
    Ok(entries) => {
      let yaml_files : Array[String] = []
      for entry in entries {
        let lower = entry.to_lower()
        if lower.has_suffix(".yaml") || lower.has_suffix(".yml") {
          yaml_files.push(entry)
        }
      }
      Ok(yaml_files)
    }
    Err(e) => Err(e)
  }
}

/// ==================== 变更监听 ====================

///|
/// 注册配置变更监听器
pub fn ConfigManager::on_change(
  self : ConfigManager,
  callback : (ConfigChange) -> Unit,
) -> (ConfigManager, Int) {
  let id = self.listener_next_id
  let new_listeners = self.listeners
  new_listeners.push((id, callback))
  (
    ConfigManager::{
      config_dir: self.config_dir,
      listener_next_id: id + 1,
      listeners: new_listeners,
      change_history: self.change_history,
    },
    id,
  )
}

///|
/// 移除配置变更监听器
pub fn ConfigManager::remove_listener(
  self : ConfigManager,
  id : Int,
) -> ConfigManager {
  let new_listeners : Array[(Int, (ConfigChange) -> Unit)] = []
  for listener in self.listeners {
    let (lid, _) = listener
    if lid != id {
      new_listeners.push(listener)
    }
  }
  ConfigManager::{
    config_dir: self.config_dir,
    listener_next_id: self.listener_next_id,
    listeners: new_listeners,
    change_history: self.change_history,
  }
}

///|
/// 通知所有监听器某个配置变更
pub fn ConfigManager::notify_listeners(
  self : ConfigManager,
  change : ConfigChange,
) -> ConfigManager {
  let new_history = self.change_history
  new_history.push(change)
  for listener in self.listeners {
    let (_, callback) = listener
    callback(change)
  }
  ConfigManager::{
    config_dir: self.config_dir,
    listener_next_id: self.listener_next_id,
    listeners: self.listeners,
    change_history: new_history,
  }
}

///|
/// 获取变更历史
pub fn ConfigManager::change_history(
  self : ConfigManager,
) -> Array[ConfigChange] {
  self.change_history
}

/// ==================== 辅助函数 ====================

///|
/// 读取文件的哈希值（用于检测变更）
fn read_file_hash(fs : @core.FileSystem, path : String) -> Int {
  match (fs.read_to_string)(path) {
    Ok(content) => hash_string(content)
    Err(_) => 0
  }
}

///|
/// 字符串简单哈希
fn hash_string(s : String) -> Int {
  let len = s.length()
  let mut h = 0
  let mut i = 0
  while i < len {
    let c = s[i].to_int()
    h = h * 31 + c
    i = i + 1
  }
  h
}
