#!/bin/bash
echo "构建一多操作系统..."

# 创建输出目录
mkdir -p bin/{native,wasm}

# 构建内核
echo "构建内核..."
moon build --target=native kernel/ -o bin/native/kernel

# 构建运行时
echo "构建运行时..."
moon build --target=native runtime/ -o bin/native/runtime

# 构建应用
echo "构建应用..."
moon build --target=wasm-gc apps/ -o bin/wasm/

# 运行测试
echo "运行测试..."
moon test

echo "构建完成！"
echo "可执行文件位置："
echo "  Native: bin/native/kernel"
echo "  Wasm: bin/wasm/"
