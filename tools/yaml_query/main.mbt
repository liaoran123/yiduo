/// 一多 OS 自举 YAML 查询工具
/// 使用 config 包中的递归 YAML 解析器读取组件配置
/// 参数通过 _build/yq_input.txt 文件传递（两行：YAML路径 + 实现名称）
/// 输出构建元数据为 JSON，供 PowerShell 构建脚本消费

///|
fn main {
  let fs = @fs.create_native_fs()

  let input_path = "_build/yq_input.txt"
  let input_content = match (fs.read_to_string)(input_path) {
    Ok(c) => c
    Err(_) => {
      println("{}")
      abort("读取参数文件失败: " + input_path)
    }
  }

  let lines = input_content
    .split("\n")
    .map(fn(sv) { sv.trim().to_owned() })
    .to_array()
  if lines.length() < 2 {
    println("{}")
    abort(
      "参数文件格式错误: 需要两行（YAML路径 + 实现名称）",
    )
  }

  let file_path = lines[0]
  let impl_name = lines[1]

  if file_path == "" || impl_name == "" {
    println("{}")
    abort(
      "参数文件格式错误: 需要两行（YAML路径 + 实现名称）",
    )
  }

  match (fs.read_to_string)(file_path) {
    Ok(content) =>
      match @config.parse_yaml(content) {
        Ok(root) => {
          let result = extract_build_metadata(root, impl_name)
          println(result)
        }
        Err(e) => {
          println("{}")
          abort("YAML 解析失败: " + e)
        }
      }
    Err(e) => {
      println("{}")
      abort("读取文件失败: " + e)
    }
  }
}

///|
/// 从 YAML 树中提取指定实现的构建元数据，返回 JSON 字符串
fn extract_build_metadata(
  root : @config.YamlNode,
  impl_name : String,
) -> String {
  let spec_node = @config.get_mapping(root, "spec")
  let spec_node = match spec_node {
    Some(n) => n
    None => return json_error("spec not found")
  }

  let impls = @config.get_seq(spec_node, "implementations")
  let impls = match impls {
    Some(@config.YamlSeq(items)) => items
    _ => return json_error("implementations seq not found")
  }

  let impl_list = impls
  let mut target_impl : @config.YamlNode? = None
  for item in impl_list {
    match item {
      @config.YamlMapping(entries) => {
        let mut is_match = false
        for entry in entries {
          let (k, v) = entry
          if k == "name" {
            match v {
              @config.YamlScalar(n) => if n == impl_name { is_match = true }
              _ => ()
            }
          }
        }
        if is_match {
          target_impl = Some(item)
        }
      }
      _ => ()
    }
  }

  let impl_node = match target_impl {
    Some(n) => n
    None => return json_error("impl '" + impl_name + "' not found")
  }

  let build_node = @config.get_mapping(impl_node, "build")
  let build_node = match build_node {
    Some(n) => n
    None => return json_error("build not found in impl '" + impl_name + "'")
  }

  build_to_json(build_node)
}

///|
fn json_error(msg : String) -> String {
  "{\"error\":" + quote_str(msg) + "}"
}

///|
/// 将 build 节点序列化为 JSON
fn build_to_json(build_node : @config.YamlNode) -> String {
  let native_lib = get_build_scalar(build_node, "native-library")
  let inc_paths = get_build_include_paths(build_node)
  let sys_libs = get_build_system_libs(build_node)
  let linker_opts = get_build_scalar(build_node, "linker-opts")
  let cflags = get_build_scalar(build_node, "cflags")
  "{\n" +
  "  \"nativeLibrary\": " +
  quote_str(native_lib) +
  ",\n" +
  "  \"includePaths\": " +
  inc_paths +
  ",\n" +
  "  \"systemLibs\": " +
  sys_libs +
  ",\n" +
  "  \"linkerOpts\": " +
  quote_str(linker_opts) +
  ",\n" +
  "  \"cflags\": " +
  quote_str(cflags) +
  "\n" +
  "}"
}

///|
/// 从 build mapping 中获取指定 key 的 scalar 值
fn get_build_scalar(build_node : @config.YamlNode, key : String) -> String {
  match build_node {
    @config.YamlMapping(entries) => {
      for entry in entries {
        let (k, v) = entry
        if k == key {
          match v {
            @config.YamlScalar(s) => return s
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
/// 获取 include-paths（string[]），输出 JSON 数组
fn get_build_include_paths(build_node : @config.YamlNode) -> String {
  match @config.get_seq(build_node, "include-paths") {
    Some(seq) => {
      let items = @config.seq_scalars(seq)
      let quoted : Array[String] = []
      for item in items {
        quoted.push(quote_str(item))
      }
      "[" + quoted.join(", ") + "]"
    }
    None => "[]"
  }
}

///|
/// 获取 system-libs（{os: [libs]}），输出 JSON 对象
fn get_build_system_libs(build_node : @config.YamlNode) -> String {
  let sys_node = @config.get_mapping(build_node, "system-libs")
  let sys_node = match sys_node {
    Some(n) => n
    None => return "{}"
  }

  match sys_node {
    @config.YamlMapping(entries) => {
      let os_parts : Array[String] = []
      for entry in entries {
        let (os_name, libs_node) = entry
        let libs = @config.seq_scalars(libs_node)
        let quoted : Array[String] = []
        for lib in libs {
          quoted.push(quote_str(lib))
        }
        os_parts.push("\"" + os_name + "\": [" + quoted.join(", ") + "]")
      }
      "{" + os_parts.join(", ") + "}"
    }
    _ => "{}"
  }
}

///|
/// JSON 字符串转义
fn json_escape(s : String) -> String {
  let len = s.length()
  let mut result = ""
  let mut i = 0
  while i < len {
    let c = s[i]
    let ch = c.unsafe_to_char()
    if ch == '"' {
      result = result + "\\\""
    } else if ch == '\\' {
      result = result + "\\\\"
    } else if ch == '\n' {
      result = result + "\\n"
    } else if ch == '\r' {
      result = result + "\\r"
    } else if ch == '\t' {
      result = result + "\\t"
    } else {
      result = result + String::make(1, ch)
    }
    i = i + 1
  }
  result
}

///|
/// 引用的 JSON 字符串值
fn quote_str(s : String) -> String {
  "\"" + json_escape(s) + "\""
}
