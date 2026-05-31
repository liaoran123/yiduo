/// 一多 OS 拓扑熔断器（容错机制）
/// 生物学比喻：免疫系统的淋巴节点，快速隔离感染区域，防止扩散
/// 技术实现：状态机 + 阈值熔断 + 自动恢复

///|
/// ==================== 熔断器状态 ====================
enum CircuitState {
  Closed
  Open
  HalfOpen
}

///|
/// ==================== 熔断器配置 ====================
struct CircuitConfig {
  failure_threshold : Int
  recovery_timeout : Int
  half_open_max_calls : Int
}

///|
/// ==================== 熔断器实例 ====================
struct CircuitBreaker {
  component_id : Int
  state : CircuitState
  failure_count : Int
  last_failure_time : Int
  circuit_config : CircuitConfig
  half_open_calls : Int
}

///|
/// ==================== 创建熔断器 ====================
pub fn CircuitBreaker::create(
  component_id : Int,
  circuit_config : CircuitConfig,
) -> CircuitBreaker {
  CircuitBreaker::{
    component_id,
    state: Closed,
    failure_count: 0,
    last_failure_time: 0,
    circuit_config,
    half_open_calls: 0,
  }
}

///|
/// ==================== 模拟时间（简化版） ====================
fn current_time() -> Int {
  1000
}

///|
/// ==================== 尝试调用前检查（快速失败） ====================
fn CircuitBreaker::allow_call(self : CircuitBreaker) -> (CircuitBreaker, Bool) {
  match self.state {
    Closed => (self, true)
    Open => {
      let now = current_time()
      if now - self.last_failure_time >= self.circuit_config.recovery_timeout {
        println(
          "[CircuitBreaker] 组件" +
          self.component_id.to_string() +
          ": 超时恢复 -> 半开状态",
        )
        let new_circuit = CircuitBreaker::{
          component_id: self.component_id,
          state: HalfOpen,
          failure_count: 0,
          last_failure_time: self.last_failure_time,
          circuit_config: self.circuit_config,
          half_open_calls: 0,
        }
        (new_circuit, true)
      } else {
        (self, false)
      }
    }
    HalfOpen =>
      if self.half_open_calls < self.circuit_config.half_open_max_calls {
        let new_circuit = CircuitBreaker::{
          component_id: self.component_id,
          state: self.state,
          failure_count: self.failure_count,
          last_failure_time: self.last_failure_time,
          circuit_config: self.circuit_config,
          half_open_calls: self.half_open_calls + 1,
        }
        (new_circuit, true)
      } else {
        (self, false)
      }
  }
}

///|
/// ==================== 成功调用记录 ====================
fn CircuitBreaker::on_success(self : CircuitBreaker) -> CircuitBreaker {
  match self.state {
    Closed =>
      CircuitBreaker::{
        component_id: self.component_id,
        state: self.state,
        failure_count: 0,
        last_failure_time: self.last_failure_time,
        circuit_config: self.circuit_config,
        half_open_calls: self.half_open_calls,
      }
    HalfOpen => {
      println(
        "[CircuitBreaker] 组件" +
        self.component_id.to_string() +
        ": 半开成功 -> 恢复正常",
      )
      CircuitBreaker::{
        component_id: self.component_id,
        state: Closed,
        failure_count: 0,
        last_failure_time: self.last_failure_time,
        circuit_config: self.circuit_config,
        half_open_calls: 0,
      }
    }
    Open => self
  }
}

///|
/// ==================== 失败调用记录 ====================
fn CircuitBreaker::on_failure(self : CircuitBreaker) -> CircuitBreaker {
  let new_failure_count = self.failure_count + 1
  let now = current_time()

  match self.state {
    Closed =>
      if new_failure_count >= self.circuit_config.failure_threshold {
        println(
          "[CircuitBreaker] 组件" +
          self.component_id.to_string() +
          ": 熔断触发！失败次数: " +
          new_failure_count.to_string(),
        )
        CircuitBreaker::{
          component_id: self.component_id,
          state: Open,
          failure_count: new_failure_count,
          last_failure_time: now,
          circuit_config: self.circuit_config,
          half_open_calls: 0,
        }
      } else {
        CircuitBreaker::{
          component_id: self.component_id,
          state: self.state,
          failure_count: new_failure_count,
          last_failure_time: now,
          circuit_config: self.circuit_config,
          half_open_calls: self.half_open_calls,
        }
      }
    HalfOpen => {
      println(
        "[CircuitBreaker] 组件" +
        self.component_id.to_string() +
        ": 半开失败 -> 重新熔断",
      )
      CircuitBreaker::{
        component_id: self.component_id,
        state: Open,
        failure_count: self.circuit_config.failure_threshold,
        last_failure_time: now,
        circuit_config: self.circuit_config,
        half_open_calls: 0,
      }
    }
    Open =>
      CircuitBreaker::{
        component_id: self.component_id,
        state: self.state,
        failure_count: new_failure_count,
        last_failure_time: now,
        circuit_config: self.circuit_config,
        half_open_calls: self.half_open_calls,
      }
  }
}

///|
/// ==================== 强制重置（用于管理员干预） ====================
fn CircuitBreaker::force_reset(self : CircuitBreaker) -> CircuitBreaker {
  println(
    "[CircuitBreaker] 组件" + self.component_id.to_string() + ": 强制重置",
  )
  CircuitBreaker::{
    component_id: self.component_id,
    state: Closed,
    failure_count: 0,
    last_failure_time: 0,
    circuit_config: self.circuit_config,
    half_open_calls: 0,
  }
}

///|
/// ==================== 获取状态字符串 ====================
fn state_str(state : CircuitState) -> String {
  match state {
    Closed => "正常"
    Open => "熔断"
    HalfOpen => "半开"
  }
}

///|
/// ==================== 打印熔断器状态 ====================
fn CircuitBreaker::print_status(self : CircuitBreaker) -> Unit {
  println("")
  println(
    "══════════════════════════════════════════════",
  )
  println("║    一多 OS 拓扑熔断器（免疫系统） ║")
  println(
    "══════════════════════════════════════════════",
  )
  println("组件ID: " + self.component_id.to_string())
  println("状态: " + state_str(self.state))
  println(
    "失败计数: " +
    self.failure_count.to_string() +
    " / " +
    self.circuit_config.failure_threshold.to_string(),
  )
  println(
    "半开调用: " +
    self.half_open_calls.to_string() +
    " / " +
    self.circuit_config.half_open_max_calls.to_string(),
  )
  println("")
}
