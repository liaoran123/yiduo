// 智能摄像头应用实现
// 演示"一多"架构的"搭积木"理念 + "配置文件即编程"

// 引入 device_loader
// (在真实项目中，这应该是一个模块导入)

///| 第一阶段：底层驱动（模拟芯片厂实现）
// 模拟传感器核心驱动
struct SensorCoreDriver {
    vendor: String
    model: String
}

///| 底层驱动方法
fn read_frame(driver : SensorCoreDriver) -> String {
    // 模拟从硬件读取原始数据
    "原始图像数据: " + driver.vendor + " " + driver.model
}

///| 第二阶段：能力模块（系统通用模块）
// 电源管理模块
struct PowerManager {
    name: String
}

///| 电源管理方法
fn set_power_mode(pm : PowerManager, mode : String) -> Unit {
    println("电源管理: 设置模式为 " + mode)
}

// 加密模块
struct CryptoEngine {
    name: String
}

///| 加密方法
fn encrypt_data(crypto : CryptoEngine, data : String) -> String {
    // 模拟加密过程
    "加密后数据: " + data
}

///| 第三阶段：能力组装（智能摄像头实现）
// 智能摄像头结构体
struct MySmartCamera {
    driver: SensorCoreDriver      // 底层驱动（芯片厂提供）
    pm: PowerManager              // 组合模块：电源管理
    crypto: CryptoEngine          // 组合模块：加密
    name: String
    model: String
    capabilities: Array[String]   // 从配置加载的能力列表
}

///| 智能摄像头方法 - 捕获图像
fn capture(camera : MySmartCamera) -> String {
    // 1. 调用组合能力：设置高性能模式
    set_power_mode(camera.pm, "高性能模式")
    
    // 2. 调用核心驱动：获取原始数据
    let raw_data = read_frame(camera.driver)
    
    // 3. 调用组合能力：安全加密
    let secure_data = encrypt_data(camera.crypto, raw_data)
    
    // 4. 返回处理后的数据
    secure_data
}

///| 智能摄像头方法 - 开始录制
fn start_recording(camera : MySmartCamera) -> Unit {
    set_power_mode(camera.pm, "录制模式")
    println("开始录制")
}

///| 智能摄像头方法 - 停止录制
fn stop_recording(camera : MySmartCamera) -> Unit {
    set_power_mode(camera.pm, "低功耗模式")
    println("停止录制")
}

///| 智能摄像头方法 - 获取设备信息
fn get_info(camera : MySmartCamera) -> String {
    "Smart Camera: " + camera.name + " " + camera.model + " (基于 " + camera.driver.vendor + " " + camera.driver.model + ")"
}

///| 🆕 从配置创建摄像头
fn create_camera_from_config() -> MySmartCamera {
    println("📋 从配置文件加载设备规格...")
    
    // 在真实项目中，这里会调用 device_loader.load_config_from_file()
    // 现在我们使用内联配置演示
    let device_id = "sony-imx327"
    let device_name = "Sony IMX327 Camera"
    let vendor = "Sony"
    let model = "IMX327"
    
    // 模拟从配置加载的能力列表
    let capabilities = ["camera-capture", "camera-info", "camera-config"]
    
    println("✓ 加载配置成功: " + device_name)
    println("  能力列表: " + capabilities.join(", "))
    
    // 1. 引入底层驱动
    let sensor_driver = SensorCoreDriver::{ vendor: vendor, model: model }
    
    // 2. 引入能力模块
    let power_manager = PowerManager::{ name: "系统电源管理" }
    let crypto_engine = CryptoEngine::{ name: "AES-256加密" }
    
    // 3. 组装智能摄像头
    MySmartCamera::{ 
        driver: sensor_driver,
        pm: power_manager,
        crypto: crypto_engine,
        name: "一多",
        model: "v1.0",
        capabilities: capabilities
    }
}

///| 主函数（应用层调用）
fn main {
    println("智能摄像头应用启动")
    println("==================================")
    
    println("\n[🆕 配置驱动模式]")
    println("演示：配置文件即编程 + 声明式配置")
    
    // 🆕 从配置创建摄像头
    let camera = create_camera_from_config()
    
    println("\n[测试智能摄像头]")
    // 测试获取设备信息
    let info = get_info(camera)
    println("设备信息: " + info)
    
    // 测试捕获图像
    println("\n测试捕获图像:")
    let image = capture(camera)
    println("捕获图像成功: " + image)
    
    // 测试开始/停止录制
    println("\n测试录制功能:")
    start_recording(camera)
    stop_recording(camera)
    
    println("\n==================================")
    println("智能摄像头应用结束")
    println("\n📌 新的开发流程总结:")
    println("📝  第0步：编写 YAML 配置文件（设备规格）")
    println("   - 声明设备需要哪些能力")
    println("   - 定义预配置的组合套餐")
    println("   - 配置即文档，人人可读")
    println("\n🏗️  第1阶段：底层驱动实现（芯片厂）")
    println("   - 操作寄存器、配置硬件")
    println("   - 实现单个能力接口，不是大而全的接口")
    println("\n🧩  第2阶段：配置加载（自动化）")
    println("   - DeviceLoader 自动解析 YAML 配置")
    println("   - 按需加载能力积木，动态组合")
    println("   - 零手写胶水代码！")
    println("\n📱  第3阶段：应用调用（开发者）")
    println("   - 修改配置文件 = 改变设备能力组合")
    println("   - 不需要重新编译代码！")
    println("\n💡 这就是'配置文件即编程'的强大之处！")
}
