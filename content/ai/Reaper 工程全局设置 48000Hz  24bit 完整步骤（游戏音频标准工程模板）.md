---
title: Reaper 工程全局设置 48000Hz / 24bit 完整步骤（游戏音频标准工程模板）
---

# Reaper 工程全局设置 48000Hz / 24bit 完整步骤（游戏音频标准工程模板）

快捷键：**Alt+Enter** 一键打开工程设置面板（File → Project Settings），全程分「采样率设置」「24bit 位深度设置」「混音内核」「录音 / 粘合默认格式」「保存为新建工程默认模板」五步，完全适配游戏 48kHz 行业标准。

## 一、【Project 标签页】锁定工程采样率 48000Hz

1. 勾选 **Project sample rate** 复选框（必须勾选，才能自定义工程采样率）
2. 输入框直接填写：`48000`（不要选 44100）
3. 重采样算法（游戏混音最优）：
   - Playback resample mode：`Sinc Interpolation: 192pt`
   - Render resample mode：`Sinc Interpolation: 192pt` 精度足够，CPU 开销适中，游戏音效、BGM 重采样音质完美。
4. 下方时间基准保持默认 **Time**（按时间轴，不要 Beat），做音效制作最合适。

## 二、【Media 标签页】设置 24bit 工作位深度（母版制作核心）

切换到 **Media** 选项卡，修改两处关键配置：

1. **WAV bit depth（录音 / Glue 粘合生成文件的默认位深）** 下拉选择：**24 bit PCM** 作用：录音、右键`Glue items粘合素材`、渲染新 Take 时，默认生成 24bit WAV 母版文件。
2. 可选勾选 **Allow large files to use Wave64**，超长 BGM 文件不会超限报错。

## 三、【Advanced 高级标签页】设置内部混音位深度（必看）

Reaper**内部混音永远用浮点运算**，和导出 24bit 整数互不冲突，推荐配置：

1. Track mixing bit depth（轨道混音内核）：**64-bit float** 最高动态余量，EQ、压缩、多层音效叠加不会内部爆音、产生量化噪声，24bit 母版混音的标配。
2. 其余参数保持默认即可。

## 四、声卡硬件采样率同步（避免声卡与工程速率不匹配）

1. 打开：`Options → Preferences（Ctrl+P）→ Audio → Device`
2. ASIO/WASAPI 声卡的采样率同样设置为 **48000Hz**
3. 应用保存，工程播放就不会强制实时重采样，减少 CPU 占用与音质损耗。

## 五、一键保存为默认工程模板（以后新建工程自动 48k/24bit）

在 Project Settings 窗口右下角，点击 **Save as default project settings**
 后续新建空白工程，自动继承 48000Hz 采样率 + 24bit 录音格式，不用重复设置。

## 六、导出对应位深度区分（对接 FMOD / SDL）

1. **留存母版（给 FMOD 分层制作）** Shift+R 渲染，格式 WAV、位深 **24 bit PCM**，48000Hz，无损存档。
2. **交付 SDL 游戏运行文件** SDL2 不支持硬件 24bit 输出，渲染改为 **16 bit PCM**，**务必开启 Dither 抖动**，24 转 16 音质无损。

## 七、右上角状态栏快速核对参数

设置完成后，Reaper 窗口右上角状态栏会显示：
`[48kHz 24bit WAV]`，代表工程参数完全生效。

## 常见误区

1. 工程内部 64bit 浮点混音 ≠ 导出文件位深：浮点是运算格式，最终成品的 24bit/16bit，由渲染窗口单独决定。
2. 旧素材是 44.1kHz：导入 48k 工程会出现蓝色小图标（实时重采样），批量转换可使用`Batch file converter`一键转 48k 原生采样。
3. 3D 游戏音效务必**单声道 Mono**，BGM 用立体声，声道在渲染窗口设置，不属于工程采样率配置。