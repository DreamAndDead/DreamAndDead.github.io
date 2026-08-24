---
title: How to Debug CMakeLists.txt 完整调试方案（Windows Ninja + Presets 环境）
---

# How to Debug CMakeLists.txt 完整调试方案（Windows Ninja + Presets 环境）

下面分 **日志打印、变量查看、断点调试、缓存检查、Preset/toolchain 排查、Ninja 命令追踪** 全套实操方法，适配你当前 Clang/MSVC Multi-Config 工程。

## 1. 基础：message () 打印日志（最常用）

### 语法

```cmake
# 普通信息
message(STATUS "变量值: ${变量名}")
# 警告
message(WARNING "警告内容")
# 错误，直接终止CMake
message(FATAL_ERROR "致命错误，停止配置")
# 详细TRACE日志（需要开启日志等级）
message(TRACE "细节日志")
```

### 常用调试打印示例

```cmake
# 查看路径、编译器、目录
message(STATUS "CMAKE_BINARY_DIR = ${CMAKE_BINARY_DIR}")
message(STATUS "CXX编译器: ${CMAKE_CXX_COMPILER}")
message(STATUS "Preset路径: ${sourceDir}")
message(STATUS "当前构建配置: $<CONFIG>") # 生成器表达式只能构建阶段看
```

### 控制日志级别（Preset 缓存变量）

在 `cacheVariables` 开启 TRACE，看到完整执行流程：

```json
"cacheVariables": {
  "CMAKE_MESSAGE_LOG_LEVEL": "TRACE"
}
```

改完执行 `cmake --preset xxx --fresh`，会输出完整脚本执行流程。

## 2. 查看所有缓存变量（CMakeCache.txt）

所有 `cacheVariables`、toolchain 配置全部存在构建目录：
`out/build/xxx/CMakeCache.txt`

- 可以直接打开文本搜索变量名，确认预设的值有没有真正写入缓存
- 排查问题：改了 preset 不生效，大概率缓存旧值没更新，必须 `--fresh`

### 命令行查看缓存

```bash
# 列出全部缓存变量
cmake -L out/build/clang-multi
# 只看带CXX的变量
cmake -L out/build/clang-multi | findstr CXX
```

## 3. 开启完整编译命令输出，查看真实编译参数

### 方式 1：Preset 缓存变量开启

```json
"cacheVariables": {
  "CMAKE_VERBOSE_MAKEFILE": "ON"
}
```

重新 configure + build，Ninja 会打印每一条完整 `clang++.exe/cl.exe` 编译命令，可以核对：
 头文件路径、模块参数、SDL/ImGui 链接参数、运行库 MT/MD 是否符合预期。

### 方式 2：构建时临时加参数

```bash
cmake --build --preset build-debug --verbose
```

## 4. 追踪 target 属性（查看头文件、链接库、编译选项）

CMake 内置命令查看目标完整属性（Debug ImGui/SDL/App 目标神器）

```bash
# 格式：cmake -L -N -D CMAKE_BUILD_TYPE=Debug --trace-expand -S . -B out/build/xxx
# 查看目标所有属性（include目录、link库、compile options）
cmake --trace-expand -S . -B out/build/clang-multi
cmake -E show-target-properties out/build/clang-multi App
cmake -E show-target-properties out/build/clang-multi imgui
```

常用需要核对的属性：

- `INTERFACE_INCLUDE_DIRECTORIES` 头文件目录
- `COMPILE_OPTIONS` 编译参数
- `LINK_LIBRARIES` 链接的库（SDL、系统库）

## 5. --trace /--trace-expand 脚本逐行执行追踪（终极脚本调试）

### 作用

逐行打印 CMake 脚本执行顺序、变量展开全过程，可以精准定位：
 变量在哪里被覆盖、toolchain 是否优先加载、子目录 add_subdirectory 执行顺序、GLOB 扫描时机。

### 命令（替换成你的构建目录）

```bash
# 完整追踪（变量展开）
cmake --trace-expand --preset clang-multi-win64 --fresh
# 精简追踪，只看当前项目，过滤系统CMake脚本
cmake --trace --preset clang-multi-win64 --fresh 2>&1 | findstr /v "Program Files/CMake"
```

你可以清晰看到：

1. toolchain 文件最先执行
2. 顶层 CMakeLists 执行顺序
3. add_subdirectory (SDL)、ImGui 脚本执行时机
4. 变量被哪一行代码覆盖

## 6. 断点图形调试：CMake GUI / VSCode CMake Tools

### 方案 A：官方 CMake-gui.exe

1. 打开 `cmake-gui`，选择源码目录 + 构建目录
2. 加载后可以可视化浏览所有缓存变量，手动修改变量测试效果
3. 点击 Configure / Generate 分步执行，直观查看报错。

### 方案 B：VSCode CMake Tools 断点调试（最友好）

1. 安装扩展：**CMake Tools**
2. 在 `CMakeLists.txt` 行号左侧点击打上**断点**
3. 打开命令面板：`CMake: Debug Configure` 可以单步步入、步入子目录、查看局部变量，和调试 C++ 代码体验一致。

## 7. Presets 专属调试：校验 JSON + 环境变量

### 1）校验 CMakePresets.json 语法

```bash
# 校验preset文件语法是否合法，快速定位 Invalid macro expansion 这类JSON占位符错误
cmake --preset=clang-multi-win64 --list-presets
```

报错直接定位 JSON 占位符、`$penv{}`、`${}` 语法错误。

### 2）查看预设注入的环境变量

```bash
# 在VS开发者终端，执行下面命令，查看PATH是否成功追加SDL路径
cmake --preset clang-multi-win64 --fresh
echo %PATH%
```

用来排查：preset environment PATH 是否生效、SDL.dll 环境路径是否配置成功。

## 8. Toolchain 调试专属技巧

toolchain 加载**时机最早**，如果编译器、全局参数不生效：

1. 在 toolchain.cmake 顶部加打印：

```cmake
message(STATUS "==== Load Clang Toolchain ====")
message(STATUS "C compiler: ${CMAKE_C_COMPILER}")
```

执行 `--trace-expand`，看 toolchain 有没有被成功加载。
 2. 核对：preset 的 `toolchainFile` 路径大小写、相对路径是否正确。

## 9. Ninja Multi-Config 专属调试要点

1. `$<CONFIG>` 生成器表达式**configure 阶段无法打印**，只能在 build verbose 日志里看最终展开值；
2. Debug/Release 产物目录不对：打印 `CMAKE_RUNTIME_OUTPUT_DIRECTORY`，确认缓存值；
3. 多配置编译数据库异常：查看 `compile_commands.json`，检查是否同时包含 Debug/Release 命令。

## 10. 高频问题快速调试方案

1. **cacheVariables 修改不生效**
   现象：改了 Preset 变量，配置无变化
   排查：查看 `CMakeCache.txt` 旧值还在 → 解决方案：`--fresh` 清空缓存。
2. **头文件找不到 / ImGui/SDL 头路径异常**
   执行 `show-target-properties` 查看 `INTERFACE_INCLUDE_DIRECTORIES`，确认 include 目录是否被正确加入目标。
3. **Re-checking globbed directories 日志**
   `--trace` 搜索 `GLOB`，定位哪一行使用了 glob，直接替换为手写文件列表即可根治。
4. **找不到 SDL.dll（动态库）**
   1. verbose 编译日志确认链接的是 SDL 动态库；
   2. 检查预设 environment PATH；
   3. 核对输出 bin/$CONFIG 目录下是否自动生成 SDL2.dll。

## 最简日常调试流程（推荐你的工作流）

1. 简单问题：加 `message(STATUS)` 打印变量，重新 `--fresh` 配置
2. 参数异常：开启 `CMAKE_VERBOSE_MAKEFILE=ON`，查看完整编译命令
3. 脚本逻辑诡异：`cmake --trace-expand --preset xxx --fresh` 逐行追踪
4. Preset/JSON 报错：`--list-presets` 校验预设文件
5. 复杂断点调试：VSCode CMake Tools 图形断点调试