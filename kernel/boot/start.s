; 32位 x86 启动代码
global _start

section .text
_start:
    ; 初始化堆栈
    mov esp, 0x8000
    
    ; 调用 MoonBit 入口函数
    call kernel_main
    
    ; 无限循环
hang:
    jmp hang