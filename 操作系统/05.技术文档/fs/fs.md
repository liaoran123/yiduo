# fs 包 — 原生文件系统 FFI

**路径**: `runtime/fs/`  
**依赖**: `core`  
**目标**: `native` 专用

## 概述

fs 包提供通过 **C FFI** 调用操作系统原生文件系统接口的能力，是所有从文件读取配置、加载组件等场景的底层依赖。

核心挑战：MoonBit 字符串为 **UTF-16** 编码，而 Windows 文件系统期望 **UTF-8** 路径，需要在 FFI 层做编码转换。

---

## 公开 API

### `create_native_fs() -> @core.FileSystem`

创建使用 C FFI 实现的文件系统实例，返回 `FileSystem` 函数表。

```moonbit
pub fn create_native_fs() -> @core.FileSystem {
  FileSystem::{
    read_file: read_file_native,
    list_dir: list_dir_native,
    write_file: write_file_native,
    delete_file: delete_file_native,
    file_exists: file_exists_native,
  }
}
```

### FFI 函数（C 侧实现）

| 函数 | 签名 | 说明 |
|------|------|------|
| `read_file_native` | `(String) -> Result[String, String]` | 读取文件全部内容 |
| `write_file_native` | `(String, String) -> Result[Unit, String]` | 写入文件 |
| `delete_file_native` | `(String) -> Result[Unit, String]` | 删除文件 |
| `list_dir_native` | `(String) -> Result[Array[String], String]` | 列出目录下所有条目 |
| `file_exists_native` | `(String) -> Bool` | 检查文件是否存在 |

---

## C FFI 适配层

### 编码转换

`c_src/fs_adapter.c` 实现 MoonBit UTF-16 字符串与 C UTF-8 字符串的互转：

```
MoonBit String (UTF-16)  ──→  utf16_to_utf8()  ──→  C UTF-8 char*  ──→  Win32 API
MoonBit String (UTF-16)  ←──  utf8_to_moonbit_string()  ←──  C UTF-8 char*  ←──  Win32 API
```

**关键函数**：

| C 函数 | 说明 |
|--------|------|
| `utf16_to_utf8(const uint16_t* utf16, int len)` | UTF-16 → UTF-8，用 `WideCharToMultiByte(CP_UTF8)` |
| `utf8_to_moonbit_string(const char* utf8)` | UTF-8 → MoonBit String，用 `MultiByteToWideChar(CP_UTF8)` |
| `read_file_impl(const uint16_t* path, int path_len)` | 调用 `CreateFileW` + `ReadFile` 读取文件 |
| `write_file_impl(...)` | 调用 `CreateFileW` + `WriteFile` 写入文件 |
| `list_dir_impl(...)` | 调用 `FindFirstFileW` / `FindNextFileW` 遍历目录 |
| `file_exists_impl(...)` | 调用 `GetFileAttributesW` 检查存在性 |

### 文件系统调用链路

```
MoonBit 代码
    │ 调用 read_file_native(path)
    ▼
FFI 边界（MoonBit FFI）
    │ path: UTF-16 String
    ▼
C fs_adapter.c
    │ utf16_to_utf8() 转换路径
    │ CreateFileW / ReadFile 读取
    │ 结果用 utf8_to_moonbit_string() 转回 UTF-16
    ▼
MoonBit 代码 ← Result[String, String]
```

---

## moon.pkg

```moonbit
import {
  "username/yiduo/runtime/core",
}

options(
  supported_targets: [ "native" ],
  deps: [ ],
  "native-stub": [ "c_src/fs_adapter.c" ],
)
```

- `"native-stub"`：仅在 native 目标编译 C 适配层
- `deps: [ ]`：对外无系统库依赖

---

## 设计决策

| 决策 | 选择 | 理由 |
|------|------|------|
| 编码方案 | UTF-16 ↔ UTF-8 转换 | MoonBit 字符串为 UTF-16，Windows API 的 `W` 后缀需要 UTF-16 |
| C 函数表注入 | `create_native_fs()` 返回 `FileSystem` | 保持包零状态，所有状态在返回的函数表中 |
| 错误处理 | `Result[String, String]` | MoonBit 标准错误传播方式，C 侧错误信息转为 MoonBit String |
| API 设计 | 无缓存、无状态 | 每个调用直接直达系统层，适合 008 组件配置规范的自举场景 |