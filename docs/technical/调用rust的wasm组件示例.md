没问题！为了让你能直接上手跑通这个 Rust 和 MoonBit 的跨语言调用实战，我把完整的配置文件（`Cargo.toml`、`moon.mod.json` 等）以及详细的操作步骤都整理好了。

在开始之前，请确保你的电脑里已经安装好了 **Rust**、**MoonBit** 命令行工具，以及 `wit-bindgen-cli` 和 `wasm-tools`。

### 📂 第一步：准备项目目录与 WIT 接口文件
先创建一个总文件夹（比如叫 `wasm-rust-moonbit`），在里面新建一个 `wit` 文件夹，并放入我们的“契约”文件 `math.wit`：

```wit
// wit/math.wit
package mycompany:math@1.0.0;

interface calculator {
    add: func(a: u32, b: u32) -> u32;
}

world math-world {
    export calculator;
}
```

---

### ⚙️ 第二步：配置并编译 Rust 提供方组件

在总目录下创建一个 `rust-math` 文件夹，进入该目录执行 `cargo init --lib` 初始化一个 Rust 库项目。

1. **修改 `Cargo.toml`** 
打开 `rust-math/Cargo.toml`，填入以下配置。我们需要添加 `wit-bindgen` 依赖，并指定 wasm 的编译目标：
```toml
# rust-math/Cargo.toml
[package]
name = "rust-math"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
wit-bindgen = "0.24.0" # 使用较新的 wit-bindgen 版本
```

2. **生成绑定并编写逻辑**
在 `rust-math` 目录下运行命令生成胶水代码：
`wit-bindgen rust ../wit/math.wit --out-dir src`
接着修改 `src/lib.rs`，补充加法逻辑：
```rust
// rust-math/src/lib.rs
mod bindings;
use bindings::exports::mycompany::math::calculator::Guest;

struct MathImpl;

impl Guest for MathImpl {
    fn add(a: u32, b: u32) -> u32 {
        a + b
    }
}

bindings::export!(MathImpl with_types_in bindings);
```

3. **编译为 Wasm 组件**
先在终端添加 wasm 编译目标，然后进行构建：
```bash
rustup target add wasm32-wasip1
cargo build --target wasm32-wasip1 --release
```
此时，`target/wasm32-wasip1/release/rust_math.wasm` 就生成了。我们需要用 `wasm-tools` 把它升级为标准的 Component：
```bash
wasm-tools component embed ../wit target/wasm32-wasip1/release/rust_math.wasm -o rust_math.embed.wasm
wasm-tools component new rust_math.embed.wasm -o rust_math.component.wasm
```

---

### 🌙 第三步：配置并编译 MoonBit 消费方组件

回到总目录，创建 `moonbit-app` 文件夹，并在里面新建 `moon.mod.json` 和 `moon.pkg.json`。

1. **配置文件内容**
*   `moonbit-app/moon.mod.json` (模块定义)：
```json
{
  "name": "username/moonbit-app",
  "version": "0.1.0"
}
```
*   `moonbit-app/moon.pkg.json` (包配置，用于关联生成的 FFI 导入)：
```json
{
  "import": [
    "ffi_import"
  ]
}
```

2. **生成绑定并编写逻辑**
在 `moonbit-app` 目录下运行命令生成 MoonBit 的胶水代码：
`wit-bindgen moonbit ../wit/math.wit --out-dir .`
这会生成一堆 `.mbt` 文件。我们只需要关注主逻辑，在根目录新建或修改 `main.mbt`：
```moonbit
// moonbit-app/main.mbt
// 这里的 ffi_import 对应 wit-bindgen 生成的导入接口
import "ffi_import" as math_import

pub fn main() {
  let a = 15
  let b = 27
  let result = math_import.add(a, b)
  
  println("Rust calculated: $a) + $b) = $result)")
}
```

3. **编译为 Wasm 组件**
在 `moonbit-app` 目录下执行构建和转换：
```bash
moon build --target wasm
# 将 MoonBit 编译出的普通 wasm 转换为 Component
wasm-tools component embed ../wit target/wasm/release/build/moonbit-app/moonbit-app.wasm -o moonbit_app.embed.wasm
wasm-tools component new moonbit_app.embed.wasm -o moonbit_app.component.wasm
```

---

### 🔗 第四步：组合（Compose）并运行

现在你手里有了两个核心文件：`rust_math.component.wasm`（提供加法能力）和 `moonbit_app.component.wasm`（需要加法能力）。最后一步就是把它们拼装起来。

在总目录下运行 `wasm-tools compose`：
```bash
wasm-tools compose moonbit_app.component.wasm -d rust_math.component.wasm -o final_app.wasm
```
这就生成了包含双方逻辑的最终 `final_app.wasm`。你可以使用支持组件模型的运行时（如最新版的 Wasmtime）来验证运行：
`wasmtime run final_app.wasm`

如果一切顺利，控制台将会打印出：`Rust calculated: 15 + 27 = 42`。

**💡 避坑小提示：**
*   **版本匹配**：Wasm 生态迭代极快，`wit-bindgen`、`wasm-tools` 和 `wasmtime` 最好保持最新版本，否则可能会遇到 ABI 不兼容的报错。
*   **路径问题**：在执行 `wit-bindgen` 和 `wasm-tools` 命令时，一定要注意 WIT 文件和输出/输入 wasm 文件的相对路径是否正确。

你可以直接复制这些配置去跑一遍，如果在某个环节遇到报错，随时把错误信息发给我！