---
title: SDL3 Channel Map（声道映射）完整讲解
---

# SDL3 Channel Map（声道映射）完整讲解

**Channel Map 本质：声道重排数组**，用来重新排列**交错 PCM 声道顺序**、静音声道、复制声道。
 SDL3 把映射分成**输入映射 Input**、**输出映射 Output**两套独立规则，作用在音频流的不同阶段，是多声道音频处理的核心机制。

## 一、基础概念

### 1. SDL 默认标准声道顺序（必须牢记）

SDL 规定了内存里交错 PCM 的固定索引编号，数组下标 = 声道索引：

| 声⁠道⁠索⁠引 | 名⁠称 | 全⁠称 | 含⁠义 |
| --- | --- | --- | --- |
| 0 | FL | Front Left | 前⁠置⁠左⁠声⁠道 |
| 1 | FR | Front Right | 前⁠置⁠右⁠声⁠道 |
| 2 | FC | Front Center | 前⁠置⁠中⁠置 |
| 3 | LFE | Low Frequency | 低⁠音⁠炮⁠低⁠频⁠声⁠道 |
| 4 | BL / SL | Back Left / Surround Left | 后⁠置⁠左 / 环⁠绕⁠左 |
| 5 | BR / SR | Back Right / Surround Right | 后⁠置⁠右 / 环⁠绕⁠右 |

常用声道默认排布：

- 立体声 (2 声道)：`[0:FL, 1:FR]`
- 5.1 (6 声道)：`0 FL,1 FR,2 FC,3 LFE,4 SL,5 SR`

### 2. 映射数组的读取规则（重中之重）

`int chmap[]` 数组长度 = 当前声道总数，**数组下标 = 目标声道，数组值 = 原始声道索引**

```c
int stereo_reverse[2] = {1, 0};
```

解读：

- 目标声道 0（左声道）→ 取原始声道 1 的数据
- 目标声道 1（右声道）→ 取原始声道 0 的数据 效果：**立体声左右声道互换**。

特殊值规则：

1. **值 = -1**：该目标声道静音，填充静音值；
2. 允许多个目标声道指向同一个原始声道（复制声道）；
3. **不能修改声道总数**，只能重排、静音、复制，无法 2 声道转 5.1 声道。

## 二、Input / Output 两套映射区别

### 1. SDL_SetAudioStreamInputChannelMap 输入映射

作用时机：**调用 SDL_PutAudioStreamData 写入 PCM 时立刻生效**

- 对你**送入的原始 PCM 数据**做声道重排；
- 适用于：第三方解码器（FFmpeg）导出的 PCM 声道顺序和 SDL 标准不一致，送入前矫正顺序。

举例：FFmpeg 输出立体声顺序为 `[FR, FL]`（右在前左在后），送入 SDL 前矫正：

```c
int input_map[2] = {1, 0};
SDL_SetAudioStreamInputChannelMap(stream, input_map, 2);
```

### 2. SDL_SetAudioStreamOutputChannelMap 输出映射

作用时机：**音频流读出、送给声卡硬件混音前生效**

- 对流内部缓存好的数据重排，输出到硬件；
- 适用场景：声卡硬件声道顺序奇葩、运行中实时左右翻转、动态静音某声道、3D 音效声道定位。

### 简单流程

PCM 数据 → **Input 映射重排** → 流缓冲区 → 格式 / 倍率转换 → **Output 映射重排** → 声卡播放

## 三、常用实战示例（立体声为例）

### 示例 1：左右声道互换（反向立体声）

```c
SDL_AudioSpec spec = {SDL_AUDIO_S16LE, 2, 44100};
SDL_AudioStream* stream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, NULL, NULL);

// 输出映射：左右翻转
int swap_lr[2] = {1, 0};
SDL_SetAudioStreamOutputChannelMap(stream, swap_lr, 2);

// 恢复默认（关闭映射）传NULL即可
SDL_SetAudioStreamOutputChannelMap(stream, NULL, 2);
```

### 示例 2：只保留右声道，左声道静音

```c
int map[2] = { -1, 1 };
// 目标0(左)：-1静音；目标1(右)：原始右声道
SDL_SetAudioStreamOutputChannelMap(stream, map, 2);
```

### 示例 3：单声道复制成双声道（单声道转立体声）

原始只有 0 号单声道，把左右声道都填充原始 0 声道数据：

```c
int mono_to_stereo[2] = {0, 0};
SDL_SetAudioStreamInputChannelMap(stream, mono_to_stereo, 2);
```

## 四、配套查询 API

```c
// 获取当前输入映射数组，用完需要SDL_free释放
int* GetInputMap = SDL_GetAudioStreamInputChannelMap(stream, NULL);
// 获取当前输出映射数组
int* GetOutputMap = SDL_GetAudioStreamOutputChannelMap(stream, NULL);
```

默认无自定义映射时，函数返回`NULL`，代表使用 SDL 原生默认声道顺序。

## 五、关键特性与注意事项

1. **线程安全**
   读写 ChannelMap 自带流互斥锁，音频回调线程、主线程均可随时动态修改，实时生效。
2. 新旧缓冲数据隔离
   修改映射规则**只对后续新写入的数据生效**，流内已经排队的旧 PCM，依旧沿用写入时的旧映射规则，不会乱序。
3. 和重采样、音量 Gain 互不干扰

- `FrequencyRatio`：变速变调；
- `Gain`：全局音量；
- `ChannelMap`：只改声道顺序，完全独立。

4. 多 Stream 独立映射
   多个音频流绑定同一个声卡设备时，**每个流可以配置完全不同的声道映射**，SDL 自动完成混音。
5. 录制设备同样支持
   录音输入设备的 AudioStream，Input/Output 映射逻辑完全一致，可用来矫正麦克风多声道采集顺序。

## 六、常见使用场景

1. **兼容第三方解码 PCM**：FFmpeg、各类音频库声道排布和 SDL 标准不同，用 Input 映射对齐；
2. **音效左右平移 / 翻转**：游戏音效左右声道切换、耳机反向测试；
3. **强制单声道播放**：静音右声道，只用左声道发声；
4. **环绕声设备适配**：5.1/7.1 音响硬件声道序号不标准，Output 映射适配硬件排布；
5. **简易 3D 空间音频**：动态修改声道权重，实现声音左右方位移动。