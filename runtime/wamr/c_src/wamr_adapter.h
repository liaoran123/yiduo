/**
 * @file wamr_adapter.h
 * @brief WAMR (WebAssembly Micro Runtime) adapter header for Yiduo OS
 *
 * 提供 MoonBit FFI 与 WAMR C API (wasm_export.h) 之间的桥接层。
 *
 * 编译模式：
 *   1. 真实 WAMR 模式：WAMR 库已下载并编译，通过 moon.pkg 配置 -I 和 -L 路径，
 *      本项目包含 wasm_export.h 并链接 libvmlib.a。
 *   2. Stub 回退模式：WAMR 库不可用，所有函数打印错误并返回失败码。
 *
 * 这 8 个函数是 MoonBit wasm_runtime_wamr.mbt 中 extern "C" 直接调用的接口。
 */

#ifndef YIDUO_WAMR_ADAPTER_H
#define YIDUO_WAMR_ADAPTER_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ─── 模块槽位状态 ─── */

#define MAX_WAMR_MODULES 32
#define WAMR_ERROR_BUF_SIZE 256

/** 单个 Wasm 模块槽位 */
typedef struct {
  int         loaded;     /* 0=空, 1=已加载 */
  void*       module;     /* wasm_module_t */
  void*       inst;       /* wasm_module_inst_t */
  void*       exec_env;   /* wasm_exec_env_t (per-instance exec env) */
  char        name[128];
} WamrModuleSlot;

/** 模块执行模式 */
typedef enum {
  WAMR_MODE_STUB = 0,    /* 回退模式：WAMR 库不可用 */
  WAMR_MODE_REAL = 1,    /* 真实模式：WAMR 库已链接 */
} WamrRunMode;

/* ─── 全局状态 ─── */

extern WamrModuleSlot g_wamr_modules[MAX_WAMR_MODULES];
extern int            g_wamr_max_components;
extern char           g_wamr_error_buf[WAMR_ERROR_BUF_SIZE];
extern bool           g_wamr_initialized;
extern WamrRunMode    g_wamr_run_mode;

/* ─── MoonBit FFI 接口（保持与 wasm_runtime_wamr.mbt 中 extern 声明一致） ─── */

/** 初始化 WAMR 运行时。返回运行时句柄（stub 模式返回 0） */
int32_t wamr_runtime_init(void);

/**
 * 加载 wasm 字节码并实例化。
 * @param runtime   运行时句柄（wamr_runtime_init 返回值）
 * @param wasm      wasm 字节码指针
 * @param wasm_size 字节码长度
 * @param comp_id   组件 ID（槽位索引）
 * @return 实例句柄（>=0 成功，<0 失败）
 */
int32_t wamr_module_load(int32_t runtime_handle, const uint8_t* wasm,
                          uint32_t wasm_size, int32_t comp_id);

/**
 * 调用 wasm 组件的消息处理函数。
 * @param instance  实例句柄
 * @param from_id   发送方组件 ID
 * @param msg_type  消息类型码
 * @return 0 成功，非 0 失败
 */
int32_t wamr_module_call(int32_t instance_handle, int32_t from_id,
                          int32_t msg_type);

/**
 * 写入数据到 wasm 实例的线性内存。
 * @param instance  实例句柄
 * @param offset    写入偏移
 * @param data      源数据
 * @param size      数据大小
 * @return 写入字节数（<=0 失败）
 */
int32_t wamr_write_memory(int32_t instance_handle, uint32_t offset,
                           const uint8_t* data, uint32_t size);

/**
 * 从 wasm 实例的线性内存读取数据。
 * @param instance  实例句柄
 * @param offset    读取偏移
 * @param data      目标缓冲区
 * @param size      读取大小
 * @return 读取字节数（<=0 失败）
 */
int32_t wamr_read_memory(int32_t instance_handle, uint32_t offset,
                          uint8_t* data, uint32_t size);

/** 销毁指定实例 */
void wamr_module_destroy(int32_t instance_handle);

/** 销毁整个 WAMR 运行时 */
void wamr_runtime_destroy(int32_t runtime_handle);

/** 获取最后一次错误消息 */
const char* wamr_last_error(void);

/* ─── Native 符号声明（native_imports.c 使用） ─── */

typedef struct {
  const char* module_name;
  const char* func_name;
  void*       func_ptr;
  const char* signature;
} YiduoNativeSymbol;

/** 获取暴露给 wasm 模块的 native 符号表 */
const YiduoNativeSymbol* get_native_symbols(int* count);

#ifdef __cplusplus
}
#endif

#endif /* YIDUO_WAMR_ADAPTER_H */