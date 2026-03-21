# 一多操作系统使用说明

## 1. 环境要求

- **MoonBit 编译器**：最新稳定版
- **WebAssembly 运行时 (Wasmtime)**：最新稳定版
- **构建工具**：bash (Windows 上可使用 Git Bash 或 WSL)
- **测试环境**：QEMU 模拟器（用于运行内核）

## 2. 快速开始

### 2.1 构建系统

```bash
# 进入项目根目录
cd yiduo

# 运行构建脚本
./build/build.sh
```

构建脚本会执行以下操作：
- 创建输出目录 `bin/{native,wasm}`
- 构建内核（Native 目标）
- 构建运行时（Native 目标）
- 构建应用（Wasm 目标）
- 运行测试

### 2.2 运行内核

```bash
# 使用 QEMU 运行内核
qemu-system-i386 -kernel bin/native/kernel -nographic
```

### 2.3 运行应用

```bash
# 使用 Wasmtime 运行 Wasm 应用
wasmtime bin/wasm/unihal_demo.wasm
```

## 3. 开发指南

### 3.1 目录结构

项目的主要目录结构如下：

- **kernel/**：内核层代码
- **runtime/**：运行时代码，包括 Wasm 运行时和适配器层
- **interfaces/**：WIT 接口定义
- **apps/**：应用层代码
- **build/**：构建脚本
- **docs/**：文档

### 3.2 编写应用

1. **创建应用目录**：在 `apps` 目录下创建一个新目录，例如 `myapp`

2. **创建应用文件**：在 `myapp` 目录下创建 `main.mbt` 文件

3. **编写应用代码**：

```moonbit
fn main() -> Unit {
  println("Hello from my app!")
}
```

4. **创建 moon.pkg 文件**：

```
// import {
//   "username/jiuzhang" @lib,
// }

options(
  "is-main": true,
)
```

5. **构建应用**：

```bash
moon build --target=wasm-gc apps/myapp/
```

### 3.3 编写内核模块

1. **创建模块文件**：在内核目录下创建一个新文件，例如 `kernel/my_module.mbt`

2. **编写模块代码**：

```moonbit
// 我的内核模块
fn my_function() -> Unit {
  println("Hello from my kernel module!")
}
```

3. **在 kernel.mbt 中导入模块**：

```moonbit
import "./my_module"

/// @main
fn main() -> Unit {
  my_module::my_function()
  println("Hello World from Yiduo Kernel!")
}
```

4. **构建内核**：

```bash
moon build --target=native kernel/
```

### 3.4 定义接口

1. **创建 WIT 文件**：在 `interfaces` 目录下创建一个新文件，例如 `my_interface.wit`

2. **编写接口定义**：

```wit
// 我的接口
interface my_interface {
  // 加法函数
  add: func(a: u32, b: u32) -> u32
}

world my_world {
  import my_interface
}
```

3. **在应用中使用接口**：

```moonbit
/// @component "my_interface" "add"
fn add(a: Int, b: Int) -> Int

fn main() -> Unit {
  let sum = add(5, 3)
  println("5 + 3 = " + sum.to_string())
}
```

## 4. 测试

### 4.1 运行测试

```bash
# 运行测试脚本
./build/test.sh
```

测试脚本会执行以下操作：
- 运行单元测试
- 运行集成测试（如果有）
- 运行性能测试（如果有）

### 4.2 编写测试

1. **创建测试文件**：在模块目录下创建一个 `_test.mbt` 文件，例如 `my_module_test.mbt`

2. **编写测试代码**：

```moonbit
// 测试模块

use "moonbitlang/test"

/// 测试加法函数
test "add" {
  let sum = add(5, 3)
  assert_eq(sum, 8)
}

// 加法函数
fn add(a: Int, b: Int) -> Int {
  a + b
}
```

3. **运行测试**：

```bash
moon test
```

## 5. 调试

### 5.1 内核调试

```bash
# 使用 QEMU 调试内核
qemu-system-i386 -kernel bin/native/kernel -s -S

# 在另一个终端中启动 GDB
gdb bin/native/kernel
(gdb) target remote localhost:1234
(gdb) break main
(gdb) continue
```

### 5.2 应用调试

```bash
# 使用 Wasmtime 调试 Wasm 应用
wasmtime --gdb bin/wasm/myapp.wasm

# 在另一个终端中启动 GDB
gdb
(gdb) target remote localhost:9000
(gdb) break main
(gdb) continue
```

## 6. 性能优化

### 6.1 内存管理优化

- 使用内存池减少内存分配和释放
- 优化内存访问模式，减少缓存 misses
- 使用适当的内存分配策略

### 6.2 计算优化

- 使用硬件加速器（如果可用）
- 优化算法，减少计算复杂度
- 使用并行计算，充分利用多核处理器

### 6.3 IO 优化

- 使用异步 IO，减少 IO 等待时间
- 优化 IO 缓冲区大小
- 使用 DMA 传输，减少 CPU 干预

## 7. 常见问题

### 7.1 构建失败

- 检查 MoonBit 编译器是否安装正确
- 检查依赖项是否完整
- 检查代码是否有语法错误

### 7.2 运行失败

- 检查硬件是否满足要求
- 检查内核是否正确编译
- 检查应用是否正确编译

### 7.3 性能问题

- 检查内存使用情况
- 检查 CPU 使用率
- 检查 IO 操作是否频繁

## 8. 贡献指南

1. **Fork 项目**：在 GitHub 上 fork 项目到自己的账户
2. **创建分支**：创建一个新的分支进行开发
3. **提交代码**：提交代码并编写清晰的 commit 信息
4. **创建 PR**：创建 Pull Request 到主分支
5. **代码审查**：等待代码审查和合并

### 8.1 代码风格

- 遵循 MoonBit 的代码风格指南
- 使用缩进和空格保持代码整洁
- 添加适当的注释说明代码功能

### 8.2 测试要求

- 为新功能编写单元测试
- 确保所有测试通过
- 测试边界情况和异常情况

### 8.3 文档要求

- 更新相关文档
- 添加新功能的使用说明
- 保持文档与代码同步

## 9. 联系方式

- 项目主页：[GitHub 仓库](https://github.com/username/yiduo)
- 问题反馈：[Issue 页面](https://github.com/username/yiduo/issues)
- 讨论社区：[Discord 频道](https://discord.gg/yiduo-os)

---

*一多，下一代跨语言原生操作系统，为未来计算而生。*
