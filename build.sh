#!/bin/bash
echo "构建一多操作系统..."

# 创建输出目录
mkdir -p bin

# 编译启动代码
echo "编译启动代码..."
# 注意：在 Windows 环境下，需要确保 nasm 命令可用
nasm -f elf32 kernel/boot/start.s -o bin/start.o

# 编译 MoonBit 内核
echo "编译 MoonBit 内核..."
moon build --target=native kernel/ -o bin/kernel.o

# 链接内核
echo "链接内核..."
# 注意：在 Windows 环境下，需要确保 ld 命令可用
ld -m elf_i386 -Ttext 0x100000 bin/start.o bin/kernel.o -o bin/yiduo_kernel

# 编译 Wasm 应用
echo "编译 Wasm 应用..."
moon build --target=wasm apps/hello/ -o bin/app.wasm

# 创建磁盘镜像
echo "创建磁盘镜像..."
# 注意：在 Windows 环境下，需要确保 dd 命令可用
dd if=/dev/zero of=bin/boot.img bs=512 count=2880
dd if=bin/yiduo_kernel of=bin/boot.img conv=notrunc

echo "构建完成！"
echo "可以使用以下命令运行："
echo "qemu-system-i386 -fda bin/boot.img -nographic"
echo "Wasm 应用已编译为：bin/app.wasm"