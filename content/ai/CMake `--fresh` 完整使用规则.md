---
title: CMake `--fresh` 完整使用规则
---

# CMake `--fresh` 完整使用规则

一句话总结：
**改配置、改工具链、改 Preset、改全局变量、切换编译环境 → 必须加 `--fresh`**
**只改源码 .cpp/.cppm/.ixx，不改 CMake 配置 → 完全不需要，直接 build 即可**

## 一、必须加 `--fresh` 的场景（不清缓存一定会异常）

`--fresh` = **清空构建目录内全部 CMake 缓存（CMakeCache.txt）、旧生成文件，完整重新 configure**。

1. **修改了 CMakePresets.json**
   改工具链 `toolchainFile`、改生成器 (Ninja/VS)、改 `cacheVariables`（开关、路径、CXX 标准、`CMAKE_EXPORT_COMPILE_COMMANDS`、`CMAKE_CXX_SCAN_FOR_MODULES`）、改架构 x64/x86。
   例：新增 `/translateInclude`、切换 MSVC/Clang toolchain、开启模块开关。
   ✅ 必须：`cmake --preset xxx --fresh`
2. **修改 toolchain.cmake 工具链文件**
   编译器更换、增减全局编译参数（`-fmodules`、`/translateInclude`）、SDK 路径、链接器配置。缓存里还存着旧编译器旧参数，不 fresh 不会生效。
3. **顶层 CMakeLists.txt 全局配置改动**
   `cmake_minimum_required`、`project`、全局 `set()`、`option()`、全局编译选项、`CMAKE_CXX_STANDARD` 全局标准。
4. **切换 Debug / Release / 不同架构预设**
   两套预设缓存会互相污染，切换预设建议带 `--fresh`。
5. **编译产物异常、参数不生效、LSP 的 compile_commands.json 不更新**
   改了参数，json 文件内容没变，就是旧缓存锁定，`--fresh` 强制重新生成编译数据库。
6. **删增第三方库、子模块、依赖路径变更**
   find_package、库路径改动，旧缓存会缓存库的旧路径。

## 二、完全不需要 `--fresh`，直接 build 就行

只改**源代码文件**，CMake 规则完全没变：

1. 修改 `.cpp`、`.h`、`.cppm`、`.ixx` 业务代码，新增删除源码文件（正规用 CMake `target_sources` 管理的除外）
2. 调整函数逻辑、头文件引用、`import` 模块代码 执行构建命令即可：

```bash
cmake --build --preset build-xxx
```

CMake/Ninja 会自动检测源码变更，增量编译，速度快。

### 补充：新增源码文件两种情况

1. **只是新建文件，没写到 CMake 的 target_sources 里** CMake 不知道这个文件，必须改 CMakeLists，然后 `--fresh` 重配。
2. 用 `file(GLOB)` 自动扫描文件：新增文件后，**依然需要重新 configure**，建议加 `--fresh`。 现代 CMake 不推荐 GLOB，手动写 `FILE_SET` 则改文件不用重配。

## 三、容易混淆的边界场景

1. **只改目标局部编译选项（target_compile_options）** 改完 CMakeLists，需要重新 configure，建议 `--fresh`。
2. **修改 .clangd、编辑器配置、VSCode 配置** 和 CMake 完全无关，不需要执行 cmake 命令。
3. 清理产物（只删 exe/obj）≠ 清 CMake 缓存

```bash
cmake --build --preset xxx --target clean
```

只删编译中间文件，**不会清空 CMakeCache 缓存**，参数配置依旧是旧的。想要彻底重置，还是 `--fresh`。

## 四、极简日常使用习惯（适配你的模块开发）

1. 日常写代码：改 cpp/ixx → 直接 `:LspRestart` + 执行 build
2. 改 Preset/toolchain/CMake 开关（模块参数、`/translateInclude`、Clang 模块参数）→ 固定命令： ```bash
   cmake --preset 你的预设 --fresh
   cmake --build --preset 构建预设
   ```
3. 切换 MSVC/Clang 两套工具链预设，必加 `--fresh`，避免编译器缓存残留。

## 五、`--fresh` 底层原理

1. 自动删除构建目录下：`CMakeCache.txt`、`CMakeFiles/` 缓存目录；
2. 重新完整运行一遍 CMake 解析流程，读取最新 Preset、toolchain、CMakeLists；
3. 重新生成构建规则 + 最新的 `compile_commands.json`。 缺点：会重新完整解析所有 CMake 逻辑，速度慢一点，只在改配置时使用即可。