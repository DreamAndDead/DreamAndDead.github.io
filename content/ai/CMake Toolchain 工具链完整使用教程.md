---
title: CMake Toolchain 工具链完整使用教程
---

# CMake Toolchain 工具链完整使用教程

Toolchain 文件（`xxx.toolchain.cmake`）是**独立的编译器配置脚本**，专门用来指定编译器路径、目标架构、系统、库路径、交叉编译参数，和 `CMakePresets.json` 可以完美配合使用，常用于：
 本地指定 GCC/Clang、**Windows MinGW**、ARM 嵌入式交叉编译、Android/OpenWrt、指定静态运行库、32/64 位架构锁定。

## 一、核心原理

1. Toolchain 是提前执行的 CMake 脚本，**在项目 CMakeLists.txt 之前加载**；
2. 主要配置：`CMAKE_C_COMPILER`、`CMAKE_CXX_COMPILER`、目标系统、编译标志、搜索路径；
3. 调用方式两种：
   - 命令行参数：`-DCMAKE_TOOLCHAIN_FILE=xxx.toolchain.cmake`
   - CMake Presets 内直接配置 `toolchainFile`（最推荐）。

## 二、常用模板示例

### 模板 1：Windows MinGW GCC 工具链 mingw.toolchain.cmake

放在项目 `toolchain/mingw.toolchain.cmake`

```cmake
# mingw.toolchain.cmake
# 1. 指定编译器路径（根据自己mingw实际路径修改）
set(MINGW_ROOT "D:/mingw64")

# C/C++ 编译器
set(CMAKE_C_COMPILER    ${MINGW_ROOT}/bin/gcc.exe CACHE FILEPATH "")
set(CMAKE_CXX_COMPILER  ${MINGW_ROOT}/bin/g++.exe CACHE FILEPATH "")
set(CMAKE_AR            ${MINGW_ROOT}/bin/ar.exe CACHE FILEPATH "")
set(CMAKE_RC_COMPILER   ${MINGW_ROOT}/bin/windres.exe CACHE FILEPATH "")

# 目标系统
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

# 库、头文件搜索路径（优先mingw目录）
set(CMAKE_FIND_ROOT_PATH ${MINGW_ROOT})
# 搜索规则：优先工具链目录，再系统目录
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# 全局编译选项
add_compile_options(-Wall -Wextra)
# C++标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
```

### 模板 2：MSVC 专用工具链 msvc.toolchain.cmake

用来固定 MSVC 版本、静态运行库、x64 架构

```cmake
# msvc.toolchain.cmake
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR AMD64)

# 编译器 cl.exe
set(CMAKE_C_COMPILER cl.exe)
set(CMAKE_CXX_COMPILER cl.exe)

# 运行库：MT静态 / MD动态
# MTd(Debug静态) / MDd(Debug动态)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

# MSVC全局编译参数
add_compile_options(/utf-8 /W4)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
```

### 模板 3：Linux GCC 通用 toolchain

```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)
set(CMAKE_CXX_STANDARD 17)
```

### 模板 4：ARM 交叉编译（嵌入式常用）

```cmake
# arm-linux-gnueabihf-gcc 交叉编译器
set(TOOLCHAIN_ROOT "/opt/gcc-arm-linux-gnueabihf/bin")
set(CMAKE_C_COMPILER ${TOOLCHAIN_ROOT}/arm-linux-gnueabihf-gcc)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_ROOT}/arm-linux-gnueabihf-g++)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# 交叉编译查找规则（核心）
set(CMAKE_FIND_ROOT_PATH ${TOOLCHAIN_ROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
```

## 三、三种调用 Toolchain 的方式

### 方式 1：命令行直接指定（基础用法）

```bash
# 基础格式
cmake -DCMAKE_TOOLCHAIN_FILE=./toolchain/mingw.toolchain.cmake -S . -B build-mingw

# 后续构建
cmake --build build-mingw
```

### 方式 2：CMake Presets 集成（工程首选）

修改 `CMakePresets.json` 的 `configurePresets`，增加 `toolchainFile` 字段，完美结合预设一键切换工具链。

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "base",
      "hidden": true,
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/out/build/${presetName}"
    },
    // MSVC 预设，绑定msvc工具链
    {
      "name": "msvc-x64-debug",
      "displayName": "MSVC x64 Debug",
      "inherits": "base",
      "toolchainFile": "${sourceDir}/toolchain/msvc.toolchain.cmake",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug"
      }
    },
    // MinGW GCC 预设，绑定mingw工具链
    {
      "name": "mingw-x64-release",
      "displayName": "MinGW GCC Release",
      "inherits": "base",
      "toolchainFile": "${sourceDir}/toolchain/mingw.toolchain.cmake",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release"
      }
    }
  ],
  "buildPresets": [
    {"name": "build-msvc", "configurePreset": "msvc-x64-debug"},
    {"name": "build-mingw", "configurePreset": "mingw-x64-release"}
  ]
}
```

使用命令：

```bash
# 加载mingw工具链配置
cmake --preset mingw-x64-release
# 编译
cmake --build --preset build-mingw
```

VS/VSCode/CLion 可以直接下拉切换预设，自动加载对应 toolchain。

### 方式 3：CMakeLists.txt 内部指定（不推荐）

**不建议在顶层 CMakeLists.txt 写 TOOLCHAIN**，必须放在文件最开头，且只能生效一次，不利于多编译器切换：

```cmake
# 必须放在最顶部
set(CMAKE_TOOLCHAIN_FILE "${CMAKE_SOURCE_DIR}/toolchain/mingw.toolchain.cmake" CACHE STRING "")
cmake_minimum_required(VERSION 3.19)
project(xxx)
```

## 四、Toolchain 常用进阶配置

### 1. 在 toolchain 里预设第三方库路径（对应链接 DLL）

可以直接在工具链写入全局库搜索路径，后续 `find_library` 全局生效，不用每个项目写路径：

```cmake
# mingw.toolchain.cmake 末尾追加
set(THIRD_PARTY ${CMAKE_SOURCE_DIR}/thirdparty)
# 头文件全局路径
include_directories(${THIRD_PARTY}/include)
# 库搜索路径
link_directories(${THIRD_PARTY}/lib/Release)
```

### 2. 区分 Debug / Release 编译参数

```cmake
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  add_compile_options(-g -O0)
else()
  add_compile_options(-O2)
endif()
```

### 3. 全局统一静态链接 libgcc/libstdc++（MinGW 打包必备）

在 mingw toolchain 添加链接参数，打包 exe 无需附带 gcc 运行 dll：

```cmake
add_link_options(-static -static-libgcc -static-libstdc++)
```

## 五、Toolchain + Presets 完整目录结构

```plaintext
项目根目录
├─ CMakePresets.json
├─ CMakeLists.txt
├─ toolchain/
│  ├─ msvc.toolchain.cmake
│  └─ mingw.toolchain.cmake
├─ thirdparty/          # 第三方dll/lib头文件
│  ├─ include
│  └─ lib
└─ out/                 # preset编译输出目录
```

## 六、高频坑点与排查

1. **toolchain 路径报错找不到文件**
   路径使用 `${sourceDir}`（Presets）或 `${CMAKE_SOURCE_DIR}`（原生 cmake），用**正斜杠 `/`**，不要 Windows 反斜杠 `\`。
2. **交叉编译找不到头 / 库**
   务必配置好 `CMAKE_FIND_ROOT_PATH` 和三组 `CMAKE_FIND_ROOT_PATH_MODE_*`，交叉编译必须开启 `ONLY`。
3. Presets 修改 toolchainFile 后不生效
   需要执行**重载 CMake**，命令行加 `--fresh` 清空缓存重新配置：```bash
   cmake --preset mingw-x64-release --fresh
   ```
4. MSVC toolchain cl.exe 找不到
   Ninja 搭配 MSVC 时，需要在 **x64 Native Tools Command Prompt for VS2022** 运行命令行，或者在 Presets 的`environment`里配置 VS 的 PATH 环境。
5. 工具链和项目标准冲突
   toolchain 的 `CMAKE_CXX_STANDARD` 优先级高于 `CMakeLists.txt`，以 toolchain 为准。

## 七、Toolchain 和 Presets 的分工区别

| 组⁠件 | 职⁠责 |
| --- | --- |
| Toolchain.cmake | 锁⁠定**编⁠译⁠器、架⁠构、编⁠译⁠标⁠志、系⁠统⁠类⁠型**，偏⁠向⁠底⁠层⁠编⁠译⁠环⁠境，可⁠跨⁠项⁠目⁠复⁠用 |
| CMakePresets.json | 管⁠理**生⁠成⁠器、输⁠出⁠目⁠录、环⁠境⁠变⁠量、缓⁠存⁠变⁠量、一⁠键⁠执⁠行⁠命⁠令**，偏⁠向⁠项⁠目⁠构⁠建⁠流⁠程 |

最佳实践：**通用编译器配置放进 toolchain，项目专属配置放在 Presets**。