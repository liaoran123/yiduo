/// 一多 OS 配置加载模块
/// 使用自实现的简单 YAML 解析器，无外部依赖
/// 原则：约定优于配置，组件自描述，系统自发现

/// ==================== YAML 中间表示 ====================

///|
/// YAML 节点类型（简化版，支持本项目的配置格式）
pub enum YamlNode {
  YamlScalar(String)
  YamlMapping(Array[(String, YamlNode)])
  YamlSeq(Array[YamlNode])
}

///|
/// 从 YAML 文本解析为 YamlNode
pub fn parse_yaml(content : String) -> Result[YamlNode, String] {
  let raw_lines : Array[String] = []
  for sv in content.split("\n") {
    raw_lines.push(sv.to_owned())
  }
  let lines = filter_skip_empty_comments(raw_lines)
  if lines.is_empty() {
    return Err("空文件")
  }
  match parse_mapping(lines, 0) {
    Ok((node, _)) => Ok(node)
    Err(e) => Err(e)
  }
}

///|
/// 过滤空行和注释
fn filter_skip_empty_comments(lines : Array[String]) -> Array[(String, Int)] {
  let result : Array[(String, Int)] = []
  let mut i = 0
  while i < lines.length() {
    let trimmed = lines[i].trim()
    if trimmed != "" && !trimmed.has_prefix("#") {
      result.push((lines[i], calc_indent(lines[i])))
    }
    i = i + 1
  }
  result
}

///|
/// 计算缩进层级（前导空格数）
fn calc_indent(line : String) -> Int {
  let mut count = 0
  let len = line.length()
  while count < len && line[count] == ' ' {
    count = count + 1
  }
  count
}

///|
/// 判断字符串是否以指定前缀开头
fn has_prefix(s : String, prefix : String) -> Bool {
  let s_len = s.length()
  let p_len = prefix.length()
  if p_len > s_len {
    return false
  }
  let mut i = 0
  while i < p_len {
    if s[i] != prefix[i] {
      return false
    }
    i = i + 1
  }
  true
}

///|
/// 去除字符串两端空白
fn trim_str(s : String) -> String {
  let len = s.length()
  if len == 0 {
    return s
  }
  let mut start = 0
  let mut end = len - 1
  while start <= end &&
        (s[start] == ' ' || s[start] == '\t' || s[start] == '\r') {
    start = start + 1
  }
  while end >= start && (s[end] == ' ' || s[end] == '\t' || s[end] == '\r') {
    end = end - 1
  }
  if start > end {
    ""
  } else {
    s[start:end + 1].to_owned()
  }
}

///|
/// 去除引号
fn unquote(s : String) -> String {
  let len = s.length()
  if len >= 2 {
    let first = s[0]
    let last = s[len - 1]
    if (first == '"' || first == '\'') && first == last {
      return s[1:len - 1].to_owned()
    }
  }
  s
}

///|
/// 解析 key: value，返回 (key, value_str)
fn split_kv(line : String) -> (String, String)? {
  let trimmed = trim_str(line)
  let len = trimmed.length()
  let mut colon_pos = -1
  let mut i = 0
  while i < len {
    if trimmed[i] == ':' {
      colon_pos = i
      break
    }
    i = i + 1
  }
  if colon_pos == -1 {
    return None
  }
  let key = trim_str(trimmed[:colon_pos].to_owned())
  if key == "" {
    return None
  }
  let value = trim_str(trimmed[colon_pos + 1:].to_owned())
  Some((key, value))
}

///|
/// 解析 mapping（缩进块）
fn parse_mapping(
  lines : Array[(String, Int)],
  start : Int,
) -> Result[(YamlNode, Int), String] {
  let parent_indent = if start == 0 { -1 } else { lines[start].1 }
  let entries : Array[(String, YamlNode)] = []
  let mut i = start
  while i < lines.length() {
    let (line, indent) = lines[i]
    if indent < parent_indent && i > start {
      break
    }
    match split_kv(line) {
      Some((key, value)) =>
        if value == "" {
          let next_indent = if i + 1 < lines.length() {
            lines[i + 1].1
          } else {
            0
          }
          if next_indent > indent {
            match parse_child(lines, i + 1, indent) {
              Ok((child_node, next_i)) => {
                entries.push((key, child_node))
                i = next_i
              }
              Err(e) => return Err(e)
            }
          } else {
            entries.push((key, YamlScalar("")))
            i = i + 1
          }
        } else if value.has_prefix("[") {
          match parse_inline_seq(value) {
            Ok(seq) => {
              entries.push((key, seq))
              i = i + 1
            }
            Err(e) => return Err(e)
          }
        } else {
          entries.push((key, YamlScalar(unquote(value))))
          i = i + 1
        }
      None => return Err("解析失败: " + line)
    }
  }
  Ok((YamlMapping(entries), i))
}

///|
/// 解析内联序列 [item1, "item2", item3]
fn parse_inline_seq(text : String) -> Result[YamlNode, String] {
  let content = text.trim()
  let len = content.length()
  if len < 2 || content[0] != '[' || content[len - 1] != ']' {
    return Err("无效的内联序列: " + text)
  }
  let inner = content[1:len - 1].trim().to_owned()
  if inner == "" {
    return Ok(YamlSeq([]))
  }
  let items : Array[YamlNode] = []
  let mut pos = 0
  let inner_len = inner.length()
  while pos < inner_len {
    let mut item_start = pos
    while item_start < inner_len &&
          (inner[item_start] == ' ' || inner[item_start] == '\t') {
      item_start = item_start + 1
    }
    pos = item_start
    if pos >= inner_len {
      break
    }
    if inner[pos] == '"' || inner[pos] == '\'' {
      let quote = inner[pos]
      pos = pos + 1
      let mut item = ""
      while pos < inner_len {
        if inner[pos] == quote {
          items.push(YamlScalar(item))
          pos = pos + 1
          break
        }
        item = item + String::make(1, inner[pos].unsafe_to_char())
        pos = pos + 1
      }
    } else {
      let mut item = ""
      while pos < inner_len && inner[pos] != ',' {
        item = item + String::make(1, inner[pos].unsafe_to_char())
        pos = pos + 1
      }
      items.push(YamlScalar(item.trim().to_owned()))
    }
    if pos < inner_len && inner[pos] == ',' {
      pos = pos + 1
    }
  }
  Ok(YamlSeq(items))
}

///|
/// 解析 mapping 或 sequence 的子节点
fn parse_child(
  lines : Array[(String, Int)],
  start : Int,
  parent_indent : Int,
) -> Result[(YamlNode, Int), String] {
  if start >= lines.length() {
    return Err("意外结尾")
  }
  let (first_line, first_indent) = lines[start]
  let trimmed = trim_str(first_line)
  if trimmed.has_prefix("- ") {
    parse_seq(lines, start, parent_indent)
  } else {
    parse_mapping(lines, start)
  }
}

///|
/// 解析 sequence
fn parse_seq(
  lines : Array[(String, Int)],
  start : Int,
  parent_indent : Int,
) -> Result[(YamlNode, Int), String] {
  let items : Array[YamlNode] = []
  let mut i = start
  while i < lines.length() {
    let (line, indent) = lines[i]
    if indent < parent_indent && i > start {
      break
    }
    let trimmed = trim_str(line)
    let list_marker = "- "
    if trimmed.has_prefix(list_marker) {
      let rest = trimmed[list_marker.length():].trim().to_owned()
      if rest == "" {
        let next_indent = if i + 1 < lines.length() {
          lines[i + 1].1
        } else {
          0
        }
        if next_indent > indent {
          match parse_mapping(lines, i + 1) {
            Ok((item_node, next_i)) => {
              items.push(item_node)
              i = next_i
            }
            Err(e) => return Err(e)
          }
        } else {
          items.push(YamlScalar(""))
          i = i + 1
        }
      } else {
        match split_kv(rest) {
          Some((k, v)) => {
            let entries : Array[(String, YamlNode)] = []
            entries.push((k, YamlScalar(unquote(v))))
            i = i + 1
            let item_indent = indent
            while i < lines.length() {
              let (sub_line, sub_indent) = lines[i]
              if sub_indent <= item_indent {
                break
              }
              match split_kv(sub_line) {
                Some((sk, sv)) =>
                  if sv == "" {
                    let next_indent = if i + 1 < lines.length() {
                      lines[i + 1].1
                    } else {
                      0
                    }
                    if next_indent > sub_indent {
                      match parse_child(lines, i + 1, sub_indent) {
                        Ok((child_node, next_i)) => {
                          entries.push((sk, child_node))
                          i = next_i
                        }
                        Err(_) => {
                          entries.push((sk, YamlScalar("")))
                          i = i + 1
                          while i < lines.length() {
                            let (_, skip_indent) = lines[i]
                            if skip_indent <= sub_indent {
                              break
                            }
                            i = i + 1
                          }
                        }
                      }
                    } else {
                      entries.push((sk, YamlScalar("")))
                      i = i + 1
                    }
                  } else if sv.has_prefix("[") {
                    match parse_inline_seq(sv) {
                      Ok(seq) => {
                        entries.push((sk, seq))
                        i = i + 1
                      }
                      Err(_) => {
                        entries.push((sk, YamlScalar(unquote(sv))))
                        i = i + 1
                      }
                    }
                  } else {
                    entries.push((sk, YamlScalar(unquote(sv))))
                    i = i + 1
                  }
                None => break
              }
            }
            items.push(YamlMapping(entries))
          }
          None => {
            items.push(YamlScalar(unquote(rest)))
            i = i + 1
          }
        }
      }
    } else {
      break
    }
  }
  Ok((YamlSeq(items), i))
}

/// ==================== YAML 查询辅助 ====================

///|
/// 从 YamlMapping 获取指定 key 的 scalar 值
pub fn get_scalar(node : YamlNode, key : String) -> String {
  match node {
    YamlMapping(entries) => {
      for entry in entries {
        let (k, v) = entry
        if k == key {
          match v {
            YamlScalar(s) => return s
            _ => return ""
          }
        }
      }
      ""
    }
    _ => ""
  }
}

///|
/// 从 YamlMapping 获取指定 key 的子 mapping
pub fn get_mapping(node : YamlNode, key : String) -> YamlNode? {
  match node {
    YamlMapping(entries) => {
      for entry in entries {
        let (k, v) = entry
        if k == key {
          return Some(v)
        }
      }
      None
    }
    _ => None
  }
}

///|
/// 从 YamlMapping 获取指定 key 的 sequence
pub fn get_seq(node : YamlNode, key : String) -> YamlNode? {
  match node {
    YamlMapping(entries) => {
      for entry in entries {
        let (k, v) = entry
        if k == key {
          match v {
            YamlSeq(_) => return Some(v)
            _ => return None
          }
        }
      }
      None
    }
    _ => None
  }
}

///|
/// 遍历 seq 中的 scalar 项
pub fn seq_scalars(node : YamlNode) -> Array[String] {
  match node {
    YamlSeq(items) => {
      let result : Array[String] = []
      for item in items {
        match item {
          YamlScalar(s) => result.push(s)
          _ => ()
        }
      }
      result
    }
    _ => []
  }
}

///|
/// 遍历 seq 中的 mapping 项
pub fn seq_mappings(node : YamlNode) -> Array[YamlNode] {
  match node {
    YamlSeq(items) => {
      let result : Array[YamlNode] = []
      for item in items {
        match item {
          YamlMapping(_) => result.push(item)
          _ => ()
        }
      }
      result
    }
    _ => []
  }
}

/// ==================== Component.yaml 解析 ====================

///|
/// 解析 Component.yaml 内容为 ComponentDescriptor
fn parse_component_yaml_inner(
  yaml_text : String,
) -> Result[ComponentDescriptor, String] {
  let root = match parse_yaml(yaml_text) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let metadata_node = match get_mapping(root, "metadata") {
    Some(n) => n
    None => return Err("缺少 metadata")
  }
  let spec_node = match get_mapping(root, "spec") {
    Some(n) => n
    None => return Err("缺少 spec")
  }

  let name = get_scalar(metadata_node, "name")
  let ns = get_scalar(metadata_node, "namespace")
  let version = get_scalar(metadata_node, "version")
  let description = get_scalar(metadata_node, "description")

  let comp_type = get_scalar(spec_node, "type")
  let source = get_scalar(spec_node, "source")
  let required = get_scalar(spec_node, "required") == "true"

  let provides = parse_provides(spec_node)
  let requires = parse_requires(spec_node)

  if name == "" {
    return Err("组件名称不能为空")
  }

  Ok(
    ComponentDescriptor::create(
      name,
      if ns == "" {
        None
      } else {
        Some(ns)
      },
      if version == "" {
        None
      } else {
        Some(version)
      },
      if comp_type == "" {
        "wasm"
      } else {
        comp_type
      },
      if source == "" {
        None
      } else {
        Some(source)
      },
      required,
      if description == "" {
        None
      } else {
        Some(description)
      },
      provides,
      requires,
    ),
  )
}

///|
/// 解析 provides 列表
fn parse_provides(spec_node : YamlNode) -> Array[InterfaceEntry] {
  let result : Array[InterfaceEntry] = []
  match get_seq(spec_node, "provides") {
    Some(seq_node) => {
      let mappings = seq_mappings(seq_node)
      for item in mappings {
        let iface = get_scalar(item, "interface")
        if iface != "" {
          let wit = get_scalar(item, "wit-file")
          let desc = get_scalar(item, "description")
          result.push(
            InterfaceEntry::create(
              iface,
              if wit == "" {
                None
              } else {
                Some(wit)
              },
              if desc == "" {
                None
              } else {
                Some(desc)
              },
            ),
          )
        }
      }
    }
    None => ()
  }
  result
}

///|
/// 解析 requires 列表
fn parse_requires(spec_node : YamlNode) -> Array[DependencyEntry] {
  let result : Array[DependencyEntry] = []
  match get_seq(spec_node, "requires") {
    Some(seq_node) => {
      let mappings = seq_mappings(seq_node)
      for item in mappings {
        let name = get_scalar(item, "name")
        let iface = get_scalar(item, "interface")
        if name != "" || iface != "" {
          let required_str = get_scalar(item, "required")
          let required = required_str == "" || required_str == "true"
          let ver = get_scalar(item, "version")
          let desc = get_scalar(item, "description")
          result.push(
            DependencyEntry::create(
              name,
              iface,
              required,
              if ver == "" {
                None
              } else {
                Some(ver)
              },
              if desc == "" {
                None
              } else {
                Some(desc)
              },
            ),
          )
        }
      }
    }
    None => ()
  }
  result
}

/// ==================== bootstrap.yaml 解析 ====================

///|
/// 解析 bootstrap.yaml 格式
pub fn parse_bootstrap_yaml(
  yaml_text : String,
) -> Result[YiduoBootstrapConfig, String] {
  let root = match parse_yaml(yaml_text) {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let system_node = match get_mapping(root, "system") {
    Some(n) => n
    None => return Err("bootstrap.yaml 缺少 system 段")
  }
  let bootstrap_node = match get_mapping(root, "bootstrap") {
    Some(n) => n
    None => return Err("bootstrap.yaml 缺少 bootstrap 段")
  }
  let runtime_node = get_mapping(root, "runtime")

  let sys_name = get_scalar(system_node, "name")
  let sys_ver = get_scalar(system_node, "version")
  let sys_desc = get_scalar(system_node, "description")

  let b_mode_str = get_scalar(bootstrap_node, "mode")
  let b_mode = match BootstrapMode::from_string(b_mode_str) {
    Some(m) => m
    None => Minimal
  }
  let b_level_str = get_scalar(bootstrap_node, "log-level")
  let b_level = match LogLevel::from_string(b_level_str) {
    Some(l) => l
    None => Info
  }
  let b_first = get_scalar(bootstrap_node, "first-component")

  let runtime = match runtime_node {
    Some(rt) => {
      let max_comp = parse_int_value(get_scalar(rt, "max-components"), 32)
      let max_mem = parse_int_value(
        get_scalar(rt, "max-memory-per-instance"),
        64,
      )
      let rt_type = get_scalar(rt, "runtime-type")
      Some(RuntimeConfig::{
        max_components: max_comp,
        max_memory_per_instance: max_mem,
        runtime_type: if rt_type == "" {
          "simulated"
        } else {
          rt_type
        },
      })
    }
    None => None
  }

  let config = YiduoBootstrapConfig::{
    system: SystemMeta::create(
      sys_name,
      sys_ver,
      if sys_desc == "" {
        None
      } else {
        Some(sys_desc)
      },
    ),
    bootstrap: BootstrapConfig::create(b_mode, b_level, b_first),
    runtime,
  }
  Ok(config)
}

///|
/// 手动解析整数值
fn parse_int_value(s : String, default : Int) -> Int {
  let len = s.length()
  if len == 0 {
    return default
  }
  let mut result = 0
  let mut i = 0
  let mut neg = false
  if s[0] == '-' {
    neg = true
    i = 1
  }
  let zero_code = '0'.to_int()
  while i < len {
    let c = s[i]
    if c >= '0' && c <= '9' {
      result = result * 10 + (c.to_int() - zero_code)
    } else {
      return default
    }
    i = i + 1
  }
  if neg {
    result = -result
  }
  result
}

/// ==================== 文件系统操作 ====================

///|
/// 从文件系统加载并解析 bootstrap.yaml
pub fn load_bootstrap_from_fs(
  fs : @core.FileSystem,
  path : String,
) -> Result[YiduoBootstrapConfig, String] {
  println("[Config] 加载系统配置: " + path)
  match (fs.read_to_string)(path) {
    Ok(content) => {
      println(
        "[Config] 读取成功 (" + content.length().to_string() + " 字节)",
      )
      parse_bootstrap_yaml(content)
    }
    Err(e) => Err("读取 " + path + " 失败: " + e)
  }
}

///|
/// 加载并解析组件描述文件
pub fn load_component_descriptor_from_fs(
  fs : @core.FileSystem,
  path : String,
) -> Result[ComponentDescriptor, String] {
  println("[Config] 加载组件描述: " + path)
  match (fs.read_to_string)(path) {
    Ok(content) =>
      match parse_component_yaml_inner(content) {
        Ok(desc) => {
          println(
            "[Config] 组件加载成功: " +
            desc.name +
            " (" +
            desc.component_type +
            ")",
          )
          Ok(desc)
        }
        Err(e) => Err(e)
      }
    Err(e) => Err("读取 " + path + " 失败: " + e)
  }
}

///|
/// 扫描目录，发现所有 .yaml / .yml 组件描述文件
pub fn scan_component_dir(
  fs : @core.FileSystem,
  dir : String,
) -> Result[Array[ComponentDescriptor], String] {
  println("[Config] 扫描组件目录: " + dir)
  let entries = match (fs.list_dir)(dir) {
    Ok(e) => e
    Err(e) => return Err("无法列出目录 " + dir + ": " + e)
  }

  let yaml_files : Array[String] = []
  for entry in entries {
    let lower = entry.to_lower()
    if has_suffix(lower, ".yaml") || has_suffix(lower, ".yml") {
      yaml_files.push(dir + "/" + entry)
    }
  }

  if yaml_files.is_empty() {
    return Err("在 " + dir + " 中未找到组件文件")
  }

  let result : Array[ComponentDescriptor] = []
  for yaml_path in yaml_files {
    match load_component_descriptor_from_fs(fs, yaml_path) {
      Ok(desc) => result.push(desc)
      Err(e) => println("[Config] 跳过文件 " + yaml_path + ": " + e)
    }
  }

  if result.is_empty() {
    return Err("所有组件文件解析失败")
  }

  println(
    "[Config] 组件发现完成: " + result.length().to_string() + " 个组件",
  )
  Ok(result)
}

///|
/// 判断字符串是否以指定后缀结尾
fn has_suffix(s : String, suffix : String) -> Bool {
  let s_len = s.length()
  let suf_len = suffix.length()
  if suf_len > s_len {
    return false
  }
  let start = s_len - suf_len
  let mut i = 0
  while i < suf_len {
    if s[start + i] != suffix[i] {
      return false
    }
    i = i + 1
  }
  true
}
