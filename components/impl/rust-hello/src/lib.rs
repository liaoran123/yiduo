// 一多 OS Hello World Wasm 组件的 Rust 实现
// 执行步骤：
// 1. 运行 wit-bindgen 生成绑定代码: wit-bindgen rust ../../../interfaces/base/hello.wit --out-dir src
// 2. 编译: rustup target add wasm32-wasip1 && cargo build --target wasm32-wasip1 --release
// 3. 转换为 Component: wasm-tools component embed ../../../interfaces/base/hello.wit target/wasm32-wasip1/release/rust_hello.wasm -o hello_world.embed.wasm && wasm-tools component new hello_world.embed.wasm -o ../../hello-world.wasm
// 4. 测试: wasmtime run ../../hello-world.wasm

mod bindings;
use bindings::exports::yiduo::base::hello::hello_world::Guest;

struct HelloImpl;

impl Guest for HelloImpl {
    fn say_hello(name: String) -> String {
        format!("Hello, {}! 欢迎来到一多 OS！", name)
    }
}

bindings::export!(HelloImpl with_types_in bindings);
