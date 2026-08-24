---
title: CMake FASTBuild 后端完整教程
---

# CMake FASTBuild 后端完整教程

FASTBuild 是**企业级高性能构建后端**，CMake **4.2 及以上版本原生内置 FASTBuild Generator**，用于生成 `fbuild.bff` 构建脚本，底层调用 `FBuild.exe` 执行编译。
 核心优势：**本地极速增量缓存 + 多机器分布式远程编译**，是大型游戏 / 超大型 C++ 项目（百万行代码）的终极方案，普通小项目速度和 Ninja 接近，大工程碾压 Ninja/MSBuild。

## 一、硬性前置环境

1. **CMake ≥ 4.2**（必须，低版本无 FASTBuild 生成器）
2. **FASTBuild 程序 ≥ v1.17**，编译解压后把 `FBuild.exe` 加入系统 PATH 开源地址：[https://github.com/fastbuild/fastbuild](https://link.wtturl.cn/?target=https%3A%2F%2Fgithub.com%2Ffastbuild%2Ffastbuild&scene=im&aid=497858&lang=zh)
3. 编译器：MSVC/MinGW/GCC/Clang 全平台兼容（Windows 生态最成熟）

## 二、基础启用方式（命令行 + Presets）

### 1. 命令行快速使用

```bash
# 配置阶段指定生成器 FASTBuild
cmake -G FASTBuild -S . -B out/fastbuild-debug -DCMAKE_BUILD_TYPE=Debug

# 执行构建（自动调用FBuild.exe）
cmake --build out/fastbuild-debug

# 开启本地编译缓存（核心特性，大幅提速二次编译）
cmake --build out/fastbuild-debug -- -cache
```

配置完成后，构建目录会生成核心文件：`fbuild.bff`（FASTBuild 规则文件）。

### 2. CMakePresets.json 集成（工程标准用法）

直接修改`generator: "FASTBuild"`，完美搭配 Toolchain 工具链：

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "fastbuild-msvc-x64",
      "displayName": "FASTBuild MSVC x64 Debug",
      "hidden": false,
      "generator": "FASTBuild",
      "binaryDir": "${sourceDir}/out/build/${presetName}",
      "architecture": {"value": "x64", "strategy": "external"},
      "toolchainFile": "${sourceDir}/toolchain/msvc.toolchain.cmake",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        // 全局缓存目录（所有项目共用缓存）
        "CMAKE_FASTBUILD_CACHE_PATH": "D:/FASTBuild/Cache"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "build-fastdebug",
      "configurePreset": "fastbuild-msvc-x64",
      "targets": ["all"],
      // 默认带缓存构建
      "buildCommandArgs": ["-cache"]
    }
  ]
}
```

一键执行：

```bash
cmake --preset fastbuild-msvc-x64
cmake --build --preset build-fastdebug
```

## 三、核心两大王牌特性

### 1. 目标文件本地缓存（单机提速）

编译后的 `.obj/.o` 目标文件会存入缓存目录，**源码未修改、编译参数不变时，直接复用缓存，完全跳过编译**。

- 环境变量方式配置缓存路径：`FASTBUILD_CACHE_PATH=D:/fb_cache`
- 可跨分支、跨项目共享缓存，重装系统只要缓存目录保留即可复用。
- 单独关闭单个目标缓存（CMake 脚本）：

```cmake
set_target_properties(mylib PROPERTIES FASTBUILD_CACHING OFF)
```

### 2. 分布式网络编译（多机器集群）

可以把编译任务分发到局域网多台 Windows/Linux 主机，多核并行上限突破本机 CPU，超大工程编译时间成倍缩短。
 只需启动远端 FASTBuild Slave 节点，本机 Master 自动调度，CMake 侧无需修改脚本，在构建命令追加参数即可启用分布式：

```bash
cmake --build build -- -cache -dist
```

## 四、配套 IDE 支持

1. **Visual Studio** FASTBuild 生成器会自动在构建目录产出 `VisualStudio/xxx.sln` 解决方案，打开 VS 后，编译后端自动走 FASTBuild，调试不受影响。 手动生成 VS 工程：

```bash
cmake --build build --target solution
```

2. **VSCode(CMake Tools)/CLion** 直接读取 Presets 的 FASTBuild 预设，配置、构建流程完全兼容，日志正常输出。

## 五、FASTBuild VS Ninja / MSBuild 横向对比

| 特⁠性 | FASTBuild | Ninja | MSBuild(VS) |
| --- | --- | --- | --- |
| 单⁠机⁠增⁠量⁠速⁠度 | 大⁠项⁠目⁠更⁠快，缓⁠存⁠无⁠敌 | 小⁠项⁠目⁠最⁠优，无⁠全⁠局⁠缓⁠存 | 最⁠慢 |
| 分⁠布⁠式⁠远⁠程⁠编⁠译 | ✅ 原⁠生⁠支⁠持 | ❌ 不⁠支⁠持 | ❌ 不⁠原⁠生⁠支⁠持 |
| 全⁠局⁠目⁠标⁠文⁠件⁠缓⁠存 | ✅ 跨⁠项⁠目 / 跨⁠机⁠器⁠缓⁠存 | 仅⁠本⁠次⁠构⁠建⁠内⁠存⁠缓⁠存 | 无 |
| 多⁠配⁠置 Debug/Release | 单⁠配⁠置（同 Ninja） | 单⁠配⁠置 | 原⁠生⁠多⁠配⁠置 |
| 适⁠用⁠场⁠景 | 百⁠万⁠行⁠大⁠型⁠引⁠擎、团⁠队⁠集⁠群⁠编⁠译 | 中⁠小⁠型⁠日⁠常⁠开⁠发、CI | VS 图⁠形⁠开⁠发、简⁠单⁠项⁠目 |
| 额⁠外⁠依⁠赖 | 必⁠须⁠安⁠装 FBuild.exe | 必⁠须⁠安⁠装 ninja.exe | VS 自⁠带 |

## 六、常用高级配置变量（CMake Cache）

写入 Presets 的`cacheVariables`全局生效：

```cmake
# 1. 缓存目录
CMAKE_FASTBUILD_CACHE_PATH = "D:/fb_global_cache"
# 2. 捕获系统环境变量给FASTBuild
CMAKE_FASTBUILD_CAPTURE_SYSTEM_ENV = ON
# 3. 开启详细日志
CMAKE_FASTBUILD_VERBOSE_GENERATOR = ON
# 4. 禁用指定目标的分布式编译
set_target_properties(app PROPERTIES FASTBUILD_DISTRIBUTION OFF)
```

## 七、常见坑点与解决方案

1. **报错找不到 FBuild.exe** 检查 FASTBuild 程序路径加入系统 PATH，重启终端 / IDE 生效。
2. **Clang-Cl/GCC 出现额外编译警告（对比 Ninja）** FASTBuild 会预生成`.ii`预处理中间文件编译，部分编译器规则变化，添加编译参数屏蔽警告：

```cmake
add_compile_options(-Wno-gnu-line-marker)
```

3. **缓存不生效** 必须构建命令携带 `-- -cache` 参数；架构、运行库 (MD/MT)、编译器版本必须完全一致。
4. **和 ExternalProject、自定义命令兼容性一般** 自定义命令建议单输出文件，多输出会增加额外校验开销，尽量精简 POST_BUILD 脚本。
5. **CMake 版本不够无 FASTBuild 生成器** 升级 CMake 至 4.2+，执行 `cmake -G` 可以查看本机所有可用 Generator。

## 八、选型建议

1. **中小型项目（万行代码内）**：继续用 Ninja 足够，FASTBuild 收益不明显；
2. **大型 C++ 引擎、百万行源码、团队多开发机**：优先 FASTBuild，分布式 + 缓存可以解决编译耗时痛点；
3. **日常 VS 图形调试**：平时用 VS 后端，打包 / 全量编译切换 FASTBuild 后端。