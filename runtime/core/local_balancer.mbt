///|
/// 一多 OS 局部负载均衡器（神经反射系统）
struct HealthScore {
  memory_used : Int
  cpu_load : Int
  active_cells : Int
  total_cells : Int
}

///|
enum ComponentPriority {
  Critical
  High
  Normal
  Low
}

///|
struct LocalBalancer {
  node_id : Int
  health : HealthScore
  low_priority_components : FixedArray[Int]
  max_sleep_components : Int
}

///|
pub fn create_local_balancer(
  node_id : Int,
  max_sleep_components : Int,
) -> LocalBalancer {
  LocalBalancer::{
    node_id,
    health: HealthScore::{
      memory_used: 0,
      cpu_load: 0,
      active_cells: 0,
      total_cells: 0,
    },
    low_priority_components: FixedArray::make(max_sleep_components, -1),
    max_sleep_components,
  }
}

///|
fn LocalBalancer::update_health(
  self : LocalBalancer,
  new_health : HealthScore,
) -> LocalBalancer {
  LocalBalancer::{
    node_id: self.node_id,
    health: new_health,
    low_priority_components: self.low_priority_components,
    max_sleep_components: self.max_sleep_components,
  }
}

///|
fn LocalBalancer::register_low_priority(
  self : LocalBalancer,
  component_id : Int,
) -> LocalBalancer {
  let new_comps = self.low_priority_components
  let mut i = 0
  while i < self.max_sleep_components {
    if new_comps[i] == -1 {
      new_comps[i] = component_id
      i = self.max_sleep_components
    } else {
      i = i + 1
    }
  }
  LocalBalancer::{
    node_id: self.node_id,
    health: self.health,
    low_priority_components: new_comps,
    max_sleep_components: self.max_sleep_components,
  }
}

///|
fn LocalBalancer::should_adjust(self : LocalBalancer) -> Bool {
  self.health.memory_used > 80 || self.health.cpu_load > 90
}

///|
fn LocalBalancer::sleep_low_priority(
  self : LocalBalancer,
  callback : (Int) -> Unit,
) -> (LocalBalancer, Int) {
  println(
    "[LocalBalancer] 节点" + self.node_id.to_string() + ": 触发神经反射",
  )
  let mut slept_count = 0
  let mut i = 0
  while i < self.max_sleep_components {
    let comp_id = self.low_priority_components[i]
    if comp_id != -1 && slept_count < 3 {
      callback(comp_id)
      slept_count = slept_count + 1
      let new_comps = self.low_priority_components
      new_comps[i] = -2
      return (
        LocalBalancer::{
          node_id: self.node_id,
          health: self.health,
          low_priority_components: new_comps,
          max_sleep_components: self.max_sleep_components,
        },
        slept_count,
      )
    }
    i = i + 1
  }
  (self, slept_count)
}

///|
fn LocalBalancer::wakeup_components(
  self : LocalBalancer,
  callback : (Int) -> Unit,
) -> (LocalBalancer, Int) {
  println(
    "[LocalBalancer] 节点" + self.node_id.to_string() + ": 唤醒组件",
  )
  let mut woke_count = 0
  let new_comps = self.low_priority_components
  let mut i = 0
  while i < self.max_sleep_components {
    let comp_id = self.low_priority_components[i]
    if comp_id == -2 {
      let original_id = i + 100
      callback(original_id)
      new_comps[i] = original_id
      woke_count = woke_count + 1
      if woke_count >= 2 {
        i = self.max_sleep_components
      }
    }
    i = i + 1
  }
  (
    LocalBalancer::{
      node_id: self.node_id,
      health: self.health,
      low_priority_components: new_comps,
      max_sleep_components: self.max_sleep_components,
    },
    woke_count,
  )
}

///|
fn LocalBalancer::print_status(self : LocalBalancer) -> Unit {
  println("")
  println(
    "══════════════════════════════════════════════",
  )
  println("║  一多 OS 局部均衡器  ║")
  println(
    "══════════════════════════════════════════════",
  )
  println("节点ID: " + self.node_id.to_string())
  println("内存使用: " + self.health.memory_used.to_string() + "%")
  println("CPU负载: " + self.health.cpu_load.to_string() + "%")
  println("")
}
