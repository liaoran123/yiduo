# 音频服务

## 概述

音频服务是一多操作系统中的核心服务之一，负责提供音频设备管理和音频流操作功能，支持音频的播放和录制。

## 功能特性

- 支持音频设备的枚举和管理
- 支持音频流的创建和控制
- 支持音频数据的播放
- 运行在 Wasm 沙箱中，确保安全隔离

## 接口定义

### `AudioDevice`

```moonbit
record AudioDevice {
  id: String
  name: String
  supported_formats: List[String]
}
```

音频设备记录，包含设备 ID、名称和支持的音频格式。

### `AudioStream`

```moonbit
record AudioStream {
  device_id: String
  format: String
  sample_rate: Int
  channels: Int
}
```

音频流记录，包含设备 ID、音频格式、采样率和声道数。

### `get_audio_devices`

```moonbit
fn get_audio_devices() -> List[AudioDevice]
```

获取系统中所有可用的音频设备列表。

### `open_audio_stream`

```moonbit
fn open_audio_stream(device_id: String, format: String, sample_rate: Int, channels: Int) -> Result[AudioStream, String]
```

打开指定设备的音频流，返回音频流对象或错误信息。

### `play_audio`

```moonbit
fn play_audio(stream: AudioStream, data: Array[UInt8]) -> Result[Unit, String]
```

通过指定的音频流播放音频数据，返回成功或错误信息。

## 使用示例

```moonbit
/// @component "services/audio" "get_audio_devices"
fn get_audio_devices() -> List[AudioDevice]

/// @component "services/audio" "open_audio_stream"
fn open_audio_stream(device_id: String, format: String, sample_rate: Int, channels: Int) -> Result[AudioStream, String]

/// @component "services/audio" "play_audio"
fn play_audio(stream: AudioStream, data: Array[UInt8]) -> Result[Unit, String]

fn main {
  // 获取音频设备列表
  let devices = get_audio_devices()
  println("音频设备列表: " + devices.to_string())
  
  // 打开音频流
  let stream_result = open_audio_stream("default", "PCM", 44100, 2)
  match stream_result {
    Ok(stream) => {
      println("音频流打开成功")
      // 播放音频数据（这里使用空数据作为示例）
      let play_result = play_audio(stream, Array.empty())
      match play_result {
        Ok(_) => println("音频播放成功"),
        Err(e) => println("音频播放失败: " + e)
      }
    },
    Err(e) => println("音频流打开失败: " + e)
  }
}
```