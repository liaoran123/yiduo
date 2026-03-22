// 安全服务
// 编译目标：Wasm (沙箱运行)

/// 安全上下文
record SecurityContext {
  user_id: String
  permissions: List[String]
}

/// 检查权限
fn check_permission(ctx: SecurityContext, permission: String) -> Bool {
  ctx.permissions.contains(permission)
}

/// 生成安全上下文
fn create_context(user_id: String) -> SecurityContext {
  {
    user_id: user_id
    permissions: List.empty()
  }
}

/// 添加权限
fn add_permission(ctx: SecurityContext, permission: String) -> SecurityContext {
  {
    user_id: ctx.user_id
    permissions: ctx.permissions.append(permission)
  }
}