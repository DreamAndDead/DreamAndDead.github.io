---
title: SDL_GetAudioStreamFrequencyRatio 完整详解
---

# SDL_GetAudioStreamFrequencyRatio 完整详解

## 一、函数原型

```c
#include <SDL3/SDL_audio.h>

float SDL_GetAudioStreamFrequencyRatio(SDL_AudioStream *stream);
```

**配套写入函数**：`SDL_SetAudioStreamFrequencyRatio()`，二者成对使用，用于**获取 / 设置音频流的播放倍速（频率倍率）**，实现**时域重采样变速 + 同步变调**效果。

## 二、参数与返回值

1. **入参**`stream`：目标 `SDL_AudioStream` 音频流指针，不可为空。
2. **返回值**

- 正常：返回当前倍率值，**默认初始值 1.0f（原速原声）**
- 失败（stream 无效）：返回 `0.0f`，调用 `SDL_GetError()` 查看错误信息

3. **合法倍率区间**（Set 函数强制限制）：`0.01f ~ 100.0f`，超出范围设置会失败。

## 三、倍率数值含义（核心原理）

倍率本质是**重采样读取速度**，读取样本的快慢直接同时改变**播放速度 + 音调**（时域线性重采样）：

| 倍⁠率⁠值 | 播⁠放⁠效⁠果 | 音⁠调⁠变⁠化 |
| --- | --- | --- |
| `ratio > 1.0` | 倍⁠速⁠快⁠放（2.0=2 倍⁠速） | 音⁠调⁠同⁠步⁠升⁠高（尖⁠锐） |
| `ratio = 1.0` | 原⁠始⁠正⁠常⁠速⁠度 | 原⁠音⁠调 |
| `ratio < 1.0` | 慢⁠速⁠慢⁠放（0.5 = 半⁠速） | 音⁠调⁠同⁠步⁠降⁠低（低⁠沉） |

底层生效时机：在 `SDL_GetAudioStreamData` 内部重采样时计算生效，**运行中可以随时动态修改倍率**，实时生效。

## 四、线程安全

线程完全安全，函数内部会自动持有当前流的专属互斥锁，**主线程、音频回调后台线程都可以随时调用读写倍率**，无需手动加锁 `SDL_LockAudioDevice`。

## 五、完整使用示例

```c
#include <SDL3/SDL.h>

int main()
{
    SDL_Init(SDL_INIT_AUDIO);
    SDL_AudioSpec spec = {SDL_AUDIO_S16LE, 2, 44100};
    SDL_AudioStream* stream = SDL_OpenAudioDeviceStream(
        SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, NULL, NULL
    );
    SDL_ResumeAudioStreamDevice(stream);

    // 1. 设置为1.5倍速快放（音调升高）
    SDL_SetAudioStreamFrequencyRatio(stream, 1.5f);

    // 2. 读取当前倍率
    float cur_ratio = SDL_GetAudioStreamFrequencyRatio(stream);
    SDL_Log("当前播放倍率：%.2f", cur_ratio); // 输出 1.50

    // 3. 改回半速慢放
    SDL_SetAudioStreamFrequencyRatio(stream, 0.5f);
    cur_ratio = SDL_GetAudioStreamFrequencyRatio(stream);
    SDL_Log("当前播放倍率：%.2f", cur_ratio); // 输出 0.50

    SDL_DestroyAudioStream(stream);
    SDL_Quit();
    return 0;
}
```

## 六、关键注意事项

### 1. 倍率 = 变速 + 变调绑定（时域重采样短板）

该接口是**简单线性重采样**，必然速度和音调绑定。

- 想要**变速不变调**（语速快慢不变人声）：SDL 原生无内置算法，需要集成 `libsoundtouch`、`rubberband` 第三方库做频域处理；
- 游戏音效、BGM 快放慢放场景，原生接口完全够用。

### 2. 缓冲区与队列长度变化

- 倍率＞1（快放）：声卡消耗样本更快，`SDL_GetAudioStreamQueued()` 剩余数据下降更快，容易**缓冲区欠载（断音）**，需要提前预推送更多 PCM 数据；
- 倍率＜1（慢放）：样本消耗变慢，队列堆积速度快，长时间慢放注意控制缓冲大小，避免内存占用过高。

### 3. 多流独立控制

每个 `AudioStream` 拥有独立的倍率参数，绑定到同一个声卡设备时，**各路音频可以设置完全不同的倍速**，SDL 底层自动完成多流混合。

### 4. 与音量 Gain 区分

```c
SDL_SetAudioStreamGain(stream, 0.6f);        // 音量大小（0~1），只改响度，不改速度音调
SDL_SetAudioStreamFrequencyRatio(stream, 2.f);// 倍率，改速度+音调，和音量互不干扰
```

## 七、常见错误排查

1. Get 返回 0.0：stream 已经销毁、空指针、未正常创建；
2. Set 返回 false：倍率超出 `0.01~100` 区间、流已销毁；
3. 变速后音质变差：线性重采样算法本身特性，极高 / 极低倍率（如 0.1 倍、10 倍）会出现锯齿杂音，属于正常现象。