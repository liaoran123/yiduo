# 文件系统服务

## 概述

文件系统服务是一多操作系统中的核心服务之一，负责提供文件操作功能，包括文件的读取、写入、目录列出等操作。

## 功能特性

- 支持基本的文件读写操作
- 支持目录列出功能
- 基于 WASI 文件系统接口实现
- 运行在 Wasm 沙箱中，确保安全隔离

## 接口定义

### `read_file`

```moonbit
fn read_file(path: String) -> Result[String, String]
```

读取指定路径的文件内容，返回文件内容字符串或错误信息。

### `write_file`

```moonbit
fn write_file(path: String, content: String) -> Result[Unit, String]
```

将内容写入指定路径的文件，返回成功或错误信息。

### `list_dir`

```moonbit
fn list_dir(path: String) -> Result[List[String], String]
```

列出指定目录下的所有文件和子目录，返回文件列表或错误信息。

## 使用示例

```moonbit
/// @component "services/filesystem" "read_file"
fn read_file(path: String) -> Result[String, String]

/// @component "services/filesystem" "write_file"
fn write_file(path: String, content: String) -> Result[Unit, String]

fn main {
  // 写入文件
  let write_result = write_file("/tmp/example.txt", "Hello from Yiduo OS!")
  match write_result {
    Ok(_) => println("文件写入成功"),
    Err(e) => println("文件写入失败: " + e)
  }
  
  // 读取文件
  let read_result = read_file("/tmp/example.txt")
  match read_result {
    Ok(content) => println("文件内容: " + content),
    Err(e) => println("文件读取失败: " + e)
  }
}
```