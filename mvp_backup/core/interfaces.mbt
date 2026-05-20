// MVP 核心接口定义
// 链式骨架 - 固定的接口规范

///| 计算细胞基础 trait - 所有组件都必须实现
trait Component {
  /// 获取组件名称
  fn name(self) -> String
  
  /// 初始化组件
  fn init(self) -> Result[Unit, String]
  
  /// 清理组件
  fn cleanup(self) -> Unit
}

///| 能力积木 trait - 可执行的功能模块
trait Capability {
  /// 能力名称（唯一标识）
  fn capability_name(self) -> String
  
  /// 执行能力，接收输入并返回输出
  fn execute(self, input: String) -> Result[String, String]
}
