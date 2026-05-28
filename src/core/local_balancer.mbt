/// 一多 OS 局部负载均衡器（神经反射系统）
/// 生物学比喻：神经网络的局部节点，快速响应局部压力
/// 技术实现：资源监控 + 自动休眠/激活

/// ==================== 健康状态 ====================
struct HealthScore {
  memory_used: Int   // 已用内存
  cpu_load: Int      // CPU负载（0-100）
  active_cells: Int  // 活跃组件数
  total_cells: Int   // 总组件数
}

/// ==================== 组件优先级 ====================
enum ComponentPriority {
  Critical    // 关键（永不禁用）
  High        // 高优先级
  Normal      // 普通
  Low         // 低（可休眠）
}

/// ==================== 局部均衡器 ====================
struct LocalBalancer {
  node_id: Int
  health: HealthScore
  low_priority_components: FixedArray[Int]  // 低优先级组件ID列表
  max_sleep_components: Int
}

/// ==================== 创建均衡器 ====================
fn create(node_id: Int, max_sleep_components: Int) -> LocalBalancer {
  LocalBalancer {
    node_id: node_id,
    health: HealthScore {
      memory_used: 0,
      cpu_load: 0,
      active_cells: 0,
      total_cells: 0
    },
    low_priority_components: FixedArray::make(max_sleep_components, -1),
    max_sleep_components: max_sleep_components
  }
}

/// ==================== 更新健康状态 ====================
fn update_health(self: LocalBalancer, new_health: HealthScore) -> LocalBalancer {
  LocalBalancer {
    node_id: self.node_id,
    health: new_health,
    low_priority_components: self.low_priority_components,
    max_sleep_components: self.max_sleep_components
  }
}

/// ==================== 注册低优先级组件 ====================
fn register_low_priority(self: LocalBalancer, component_id: Int) -> LocalBalancer {
  let mut new_comps = self.low_priority_components
  let mut i = 0
  while i < self.max_sleep_components {
    if new_comps[i] == -1 {
      new_comps[i] = component_id
      i = self.max_sleep_components
    } else {
      i = i + 1
    }
  }
  LocalBalancer {
    node_id: self.node_id,
    health: self.health,
    low_priority_components: new_comps,
    max_sleep_components: self.max_sleep_components
  }
}

/// ==================== 检查是否需要调整负载（神经反射） ====================
fn should_adjust(self: LocalBalancer) -> Bool {
  // 简单策略：内存 > 80% 或 CPU > 90% 就需要调整
  self.health.memory_used > 80 || self.health.cpu_load > 90
}

/// ==================== 快速休眠低优先级组件（神经反射） ====================
fn sleep_low_priority(self: LocalBalancer, callback: (Int) -> Unit) -> (LocalBalancer, Int) {
  println("[LocalBalancer] ⚡ 节点" + self.node_id.to_string() + ": 触发神经反射 → 休眠低优先级组件")
  
  let mut slept_count = 0
  let mut i = 0
  while i < self.max_sleep_components {
    let comp_id = self.low_priority_components[i]
    if comp_id != -1 && slept_count < 3 {  // 每次最多休眠3个
      callback(comp_id)
      slept_count = slept_count + 1
      // 标记已休眠（-2表示已休眠）
      let mut new_comps = self.low_priority_components
      new_comps[i] = -2
      let new_balancer = LocalBalancer {
        node_id: self.node_id,
        health: self.health,
        low_priority_components: new_comps,
        max_sleep_components: self.max_sleep_components
      }
      return (new_balancer, slept_count)
    }
    i = i + 1
  }
  
  (self, slept_count)
}

/// ==================== 唤醒组件（负载降低时） ====================
fn wakeup_components(self: LocalBalancer, callback: (Int) -> Unit) -> (LocalBalancer, Int) {
  println("[LocalBalancer] 🌱 节点" + self.node_id.to_string() + ": 负载降低 → 唤醒组件")
  
  let mut woke_count = 0
  let mut new_comps = self.low_priority_components
  let mut i = 0
  while i < self.max_sleep_components {
    let comp_id = self.low_priority_components[i]
    if comp_id == -2 {  // -2表示已休眠
      let original_id = i + 100  // 简化：用索引模拟原始ID（实际需要更复杂的逻辑）
      callback(original_id)
      new_comps[i] = original_id
      woke_count = woke_count + 1
      if woke_count >= 2 {  // 每次最多唤醒2个
        i = self.max_sleep_components
      }
    }
    i = i + 1
  }
  
  (LocalBalancer {
    node_id: self.node_id,
    health: self.health,
    low_priority_components: new_comps,
    max_sleep_components: self.max_sleep_components
  }, woke_count)
}

/// ==================== 打印均衡器状态 ====================
fn print_status(self: LocalBalancer) {
  println("")
  println("══════════════════════════════════════════════")
  println("║  一多 OS 局部均衡器（神经反射） ║")
  println("══════════════════════════════════════════════")
  println("节点ID: " + self.node_id.to_string())
  println("内存使用: " + self.health.memory_used.to_string() + "%")
  println("CPU负载: " + self.health.cpu_load.to_string() + "%")
  println("活跃细胞: " + self.health.active_cells.to_string() + " / " + self.health.total_cells.to_string())
  println("")
}
