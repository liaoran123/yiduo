/// 一多 OS 拓扑熔断器（容错机制）
/// 生物学比喻：免疫系统的淋巴节点，快速隔离感染区域，防止扩散
/// 技术实现：状态机 + 阈值熔断 + 自动恢复

/// ==================== 熔断器状态 ====================
enum CircuitState {
  Closed     // 正常：通路（绿灯）
  Open       // 熔断：断路（红灯）
  HalfOpen   // 半开：试探恢复（黄灯）
}

/// ==================== 熔断器配置 ====================
struct CircuitConfig {
  failure_threshold: Int    // 失败阈值（多少次失败后熔断）
  recovery_timeout: Int    // 恢复超时（毫秒）
  half_open_max_calls: Int // 半开状态最大允许调用
}

/// ==================== 熔断器实例 ====================
struct CircuitBreaker {
  component_id: Int
  state: CircuitState
  failure_count: Int
  last_failure_time: Int
  config: CircuitConfig
  half_open_calls: Int
}

/// ==================== 创建熔断器 ====================
fn create(component_id: Int, config: CircuitConfig) -> CircuitBreaker {
  CircuitBreaker {
    component_id: component_id,
    state: CircuitState::Closed,
    failure_count: 0,
    last_failure_time: 0,
    config: config,
    half_open_calls: 0
  }
}

/// ==================== 模拟时间（简化版，实际可以用系统时钟） ====================
fn current_time() -> Int {
  // 简化版本，实际应该使用真正的系统时间
  1000 // 模拟一个时间戳
}

/// ==================== 尝试调用前检查（快速失败） ====================
fn allow_call(self: CircuitBreaker) -> (CircuitBreaker, Bool) {
  match self.state {
    CircuitState::Closed => (self, true)
    CircuitState::Open => {
      // 检查是否到了恢复时间
      let now = current_time()
      if now - self.last_failure_time >= self.config.recovery_timeout {
        println("[CircuitBreaker] 🔶 组件" + self.component_id.to_string() + ": 超时恢复 → 半开状态")
        let new_circuit = CircuitBreaker {
          component_id: self.component_id,
          state: CircuitState::HalfOpen,
          failure_count: 0,
          last_failure_time: self.last_failure_time,
          config: self.config,
          half_open_calls: 0
        }
        (new_circuit, true)
      } else {
        (self, false)
      }
    }
    CircuitState::HalfOpen => {
      // 半开状态只允许少量试探调用
      if self.half_open_calls < self.config.half_open_max_calls {
        let new_circuit = CircuitBreaker {
          component_id: self.component_id,
          state: self.state,
          failure_count: self.failure_count,
          last_failure_time: self.last_failure_time,
          config: self.config,
          half_open_calls: self.half_open_calls + 1
        }
        (new_circuit, true)
      } else {
        (self, false)
      }
    }
  }
}

/// ==================== 成功调用记录 ====================
fn on_success(self: CircuitBreaker) -> CircuitBreaker {
  match self.state {
    CircuitState::Closed => {
      // 重置失败计数
      CircuitBreaker {
        component_id: self.component_id,
        state: self.state,
        failure_count: 0,
        last_failure_time: self.last_failure_time,
        config: self.config,
        half_open_calls: self.half_open_calls
      }
    }
    CircuitState::HalfOpen => {
      println("[CircuitBreaker] 🟢 组件" + self.component_id.to_string() + ": 半开成功 → 恢复正常")
      CircuitBreaker {
        component_id: self.component_id,
        state: CircuitState::Closed,
        failure_count: 0,
        last_failure_time: self.last_failure_time,
        config: self.config,
        half_open_calls: 0
      }
    }
    CircuitState::Open => self
  }
}

/// ==================== 失败调用记录 ====================
fn on_failure(self: CircuitBreaker) -> CircuitBreaker {
  let new_failure_count = self.failure_count + 1
  let now = current_time()
  
  match self.state {
    CircuitState::Closed => {
      if new_failure_count >= self.config.failure_threshold {
        println("[CircuitBreaker] 🔴 组件" + self.component_id.to_string() + ": 熔断触发！失败次数: " + new_failure_count.to_string())
        CircuitBreaker {
          component_id: self.component_id,
          state: CircuitState::Open,
          failure_count: new_failure_count,
          last_failure_time: now,
          config: self.config,
          half_open_calls: 0
        }
      } else {
        CircuitBreaker {
          component_id: self.component_id,
          state: self.state,
          failure_count: new_failure_count,
          last_failure_time: now,
          config: self.config,
          half_open_calls: self.half_open_calls
        }
      }
    }
    CircuitState::HalfOpen => {
      println("[CircuitBreaker] 🔴 组件" + self.component_id.to_string() + ": 半开失败 → 重新熔断")
      CircuitBreaker {
        component_id: self.component_id,
        state: CircuitState::Open,
        failure_count: self.config.failure_threshold,
        last_failure_time: now,
        config: self.config,
        half_open_calls: 0
      }
    }
    CircuitState::Open => {
      CircuitBreaker {
        component_id: self.component_id,
        state: self.state,
        failure_count: new_failure_count,
        last_failure_time: now,
        config: self.config,
        half_open_calls: self.half_open_calls
      }
    }
  }
}

/// ==================== 强制重置（用于管理员干预） ====================
fn force_reset(self: CircuitBreaker) -> CircuitBreaker {
  println("[CircuitBreaker] 🔄 组件" + self.component_id.to_string() + ": 强制重置")
  CircuitBreaker {
    component_id: self.component_id,
    state: CircuitState::Closed,
    failure_count: 0,
    last_failure_time: 0,
    config: self.config,
    half_open_calls: 0
  }
}

/// ==================== 获取状态字符串 ====================
fn state_str(state: CircuitState) -> String {
  match state {
    CircuitState::Closed => "🟢 正常"
    CircuitState::Open => "🔴 熔断"
    CircuitState::HalfOpen => "🔶 半开"
  }
}

/// ==================== 打印熔断器状态 ====================
fn print_status(self: CircuitBreaker) {
  println("")
  println("══════════════════════════════════════════════")
  println("║    一多 OS 拓扑熔断器（免疫系统） ║")
  println("══════════════════════════════════════════════")
  println("组件ID: " + self.component_id.to_string())
  println("状态: " + state_str(self.state))
  println("失败计数: " + self.failure_count.to_string() + " / " + self.config.failure_threshold.to_string())
  println("半开调用: " + self.half_open_calls.to_string() + " / " + self.config.half_open_max_calls.to_string())
  println("")
}
