---
title: CMake 引入非 CMake 构建的第三方库（Make/VS 工程 / 纯源码 / 现成 DLL/Lib）
---

# CMake 引入非 CMake 构建的第三方库（Make/VS 工程 / 纯源码 / 现成 DLL/Lib）

非 CMake 项目分为两大类场景：

1. **已有编译成品**：已经编译好 `.lib/.a/.dll/.so` + 头文件（最常用）
2. **有源文件但构建系统不是 CMake**：原生 Makefile、VS sln、qmake、自定义脚本，需要 CMake 调用外部命令编译

下面按场景给完整方案，兼容 Presets / Toolchain。

## 场景一：只有成品头文件 + 静态库 / 动态库（无需编译源码）

### 目录结构

```plaintext
3rd/xxx/
├─ include/  *.h 头文件
├─ lib/
│  ├─ xxx.lib （Windows导入库）
│  └─ xxx.dll
```

核心做法：**CMake 导入预编译库目标 `IMPORTED`**，是标准规范写法。

### 完整 CMakeLists.txt

```cmake
# 导入动态DLL库
add_library(xxx SHARED IMPORTED GLOBAL)

# 1. 设置头文件路径，对外暴露
target_include_directories(xxx INTERFACE ${CMAKE_SOURCE_DIR}/3rd/xxx/include)

# 2. 设置库文件路径（区分Debug/Release、平台）
set_target_properties(xxx PROPERTIES
    # Release DLL本体
    IMPORTED_LOCATION_RELEASE  "${CMAKE_SOURCE_DIR}/3rd/xxx/lib/xxx.dll"
    # Release lib导入库
    IMPORTED_IMPLIB_RELEASE   "${CMAKE_SOURCE_DIR}/3rd/xxx/lib/xxx.lib"

    # Debug 库（带d后缀）
    IMPORTED_LOCATION_DEBUG   "${CMAKE_SOURCE_DIR}/3rd/xxx/lib/xxxd.dll"
    IMPORTED_IMPLIB_DEBUG     "${CMAKE_SOURCE_DIR}/3rd/xxx/lib/xxxd.lib"
)

# 如果是 静态库(.lib/.a)，改为 STATIC IMPORTED
# add_library(xxx STATIC IMPORTED GLOBAL)
# set_target_properties(xxx PROPERTIES
#     IMPORTED_LOCATION_RELEASE "${CMAKE_SOURCE_DIR}/3rd/xxx/lib/xxx.lib"
# )

# 主程序直接链接目标
add_executable(main main.cpp)
target_link_libraries(main PRIVATE xxx)
```

### 配套：自动复制 DLL 到 exe 目录（Windows 必做）

```cmake
# 编译完成后自动把dll复制到exe同目录
add_custom_command(TARGET main POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        $<TARGET_FILE:xxx>
        $<TARGET_FILE_DIR:main>
)
```

## 场景二：源码是 Makefile / VS 工程，需要 CMake 调用外部命令编译源码

使用 **`ExternalProject_Add`**，单独拉起外部构建流程（make /msbuild/bash 脚本），和当前 CMake 环境隔离，可以指定独立编译器。

### 示例 1：调用 Linux Makefile 项目

```cmake
include(ExternalProject)

ExternalProject_Add(
    lib_make
    SOURCE_DIR        ${CMAKE_SOURCE_DIR}/3rd/xxx_make  # Makefile源码目录
    BINARY_DIR        ${CMAKE_BINARY_DIR}/build_xxx
    INSTALL_DIR       ${CMAKE_BINARY_DIR}/install_xxx
    # 编译命令
    BUILD_COMMAND     make -j$(nproc)
    # 安装命令
    INSTALL_COMMAND   make install PREFIX=<INSTALL_DIR>
    # 可选：传入环境变量、工具链路径
    ENV PATH=$ENV{PATH}
)

# 获取安装目录
ExternalProject_Get_Property(lib_make INSTALL_DIR)
set(LIB_INC ${INSTALL_DIR}/include)
set(LIB_FILE ${INSTALL_DIR}/lib/libxxx.a)

# 导入静态库
add_library(xxx STATIC IMPORTED)
set_target_properties(xxx PROPERTIES IMPORTED_LOCATION ${LIB_FILE})
target_include_directories(xxx INTERFACE ${LIB_INC})

# 主程序依赖并链接
add_executable(main main.cpp)
add_dependencies(main lib_make) # 必须先编译第三方库
target_link_libraries(main PRIVATE xxx)
```

### 示例 2：Windows 调用 MSBuild 编译 VS sln 工程

```cmake
ExternalProject_Add(
    lib_vs
    SOURCE_DIR    ${CMAKE_SOURCE_DIR}/3rd/xxx_vs
    BINARY_DIR    ${CMAKE_BINARY_DIR}/build_vs
    # MSBuild 编译解决方案，指定x64 Release
    BUILD_COMMAND msbuild xxx.sln /m /p:Platform=x64;Configuration=Release
    INSTALL_COMMAND "" # 无install步骤可以置空
)
```

### 示例 3：调用自定义 bat/sh 脚本编译

```cmake
BUILD_COMMAND cmd /c build.bat
# Linux/macOS
BUILD_COMMAND sh build.sh
```

## 场景三：零散 C/C++ 源码，无构建系统，直接纳入 CMake 编译

一堆 `.c/.cpp` 源码，没有 Make/VS 工程，直接把源码加到当前 CMake，当成普通源码编译。

```cmake
# 收集第三方源码文件
file(GLOB XXX_SOURCES
    ${CMAKE_SOURCE_DIR}/3rd/xxx/src/*.c
    ${CMAKE_SOURCE_DIR}/3rd/xxx/src/*.cpp
)

# 创建静态库
add_library(xxx STATIC ${XXX_SOURCES})
target_include_directories(xxx PUBLIC ${CMAKE_SOURCE_DIR}/3rd/xxx/include)

# 链接使用
target_link_libraries(main PRIVATE xxx)
```

## 结合 CMake Presets 统一配置路径

把第三方库根目录、环境 PATH 写进预设，全局生效，不用硬编码路径：

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "msvc-x64",
      "hidden": false,
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/out/build/${presetName}",
      "environment": {
        "PATH": "${sourceDir}/3rd/xxx/lib;$penv{PATH}"
      },
      "cacheVariables": {
        "XXX_ROOT": "${sourceDir}/3rd/xxx"
      }
    }
  ]
}
```

CMake 内读取变量：`$ENV{XXX_ROOT}`。

## 关键问题与避坑

### 1. 架构、运行库必须严格匹配

MSVC：主项目 MD/MT 运行库，必须和第三方预编译库完全一致；32 位 / 64 位、Debug/Release 不能混用。

### 2. ExternalProject 看不到当前 CMake 变量

子构建进程是独立的，需要参数必须手动通过 `CMAKE_ARGS`、`ENV` 传入工具链、编译器路径。

### 3. 无法断点调试第三方源码

`IMPORTED` 预编译库只有二进制，没有 PDB 调试符号，想要调试只能拿到源码，要么改成直接编译源码，要么用 ExternalProject 编译时开启调试符号。

### 4. Linux .so 动态库

导入写法和 Windows DLL 一致：

```cmake
add_library(xxx SHARED IMPORTED)
set_target_properties(xxx PROPERTIES IMPORTED_LOCATION "/path/libxxx.so")
```

运行时需要配置 `LD_LIBRARY_PATH`。

## 四种引入方式快速选型

1. **已有编译好的 lib/dll** → `IMPORTED` 导入目标（首选）
2. **一堆零散源码** → 直接 `file(GLOB)+add_library`
3. **自带 Make/VS 工程** → `ExternalProject_Add` 调用外部构建命令
4. **需要自动下载二进制包**：配合 `file(DOWNLOAD)` 下载库包，解压后用 IMPORTED 导入。