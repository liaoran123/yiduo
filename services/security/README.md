# 安全服务

## 概述

安全服务是一多操作系统中的核心服务之一，负责提供权限管理和安全上下文相关功能，确保系统的安全性和稳定性。

## 功能特性

- 支持安全上下文的创建和管理
- 支持权限检查和验证
- 运行在 Wasm 沙箱中，确保安全隔离
- 可扩展的权限模型

## 接口定义

### `SecurityContext`

```moonbit
record SecurityContext {
  user_id: String
  permissions: List[String]
}
```

安全上下文记录，包含用户 ID 和权限列表。

### `check_permission`

```moonbit
fn check_permission(ctx: SecurityContext, permission: String) -> Bool
```

检查安全上下文中是否包含指定的权限，返回布尔值表示检查结果。

### `create_context`

```moonbit
fn create_context(user_id: String) -> SecurityContext
```

创建一个新的安全上下文，初始权限列表为空。

### `add_permission`

```moonbit
fn add_permission(ctx: SecurityContext, permission: String) -> SecurityContext
```

向安全上下文中添加指定的权限，返回更新后的安全上下文。

## 使用示例

```moonbit
/// @component "services/security" "create_context"
fn create_context(user_id: String) -> SecurityContext

/// @component "services/security" "add_permission"
fn add_permission(ctx: SecurityContext, permission: String) -> SecurityContext

/// @component "services/security" "check_permission"
fn check_permission(ctx: SecurityContext, permission: String) -> Bool

fn main {
  // 创建安全上下文
  let ctx = create_context("user123")
  
  // 添加权限
  let ctx_with_perm = add_permission(ctx, "read_file")
  
  // 检查权限
  let has_perm = check_permission(ctx_with_perm, "read_file")
  println("是否有读取文件权限: " + has_perm.to_string())
  
  let has_write_perm = check_permission(ctx_with_perm, "write_file")
  println("是否有写入文件权限: " + has_write_perm.to_string())
}
```