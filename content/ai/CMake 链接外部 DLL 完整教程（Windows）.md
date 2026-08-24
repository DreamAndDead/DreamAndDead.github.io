---
title: CMake 链接外部 DLL 完整教程（Windows）
---

# CMake 链接外部 DLL 完整教程（Windows）

Windows 链接 DLL 分为三步：**引入头文件目录 → 链接 .lib 导入库 → 运行时放置 dll 文件**，CMake 主流两种写法：`find_library` 自动查找、`target_link_libraries` 直接指定路径。

## 一、核心原理

1. **编译链接阶段**：CMake 链接的是 DLL 配套的 **`.lib` 导入库文件**，不是 dll 本体；
2. **运行阶段**：程序运行时必须能找到 **`.dll` 文件**（同目录、系统目录、PATH 环境变量）；
3. 必备文件：`xxx.h`（头文件）、`xxx.lib`（导入库）、`xxx.dll`（动态库本体）。

## 二、写法 1：硬编码路径（简单，已知库位置）

### 目录结构示例

```plaintext
项目根目录
├─ main.cpp
├─ CMakeLists.txt
└─ thirdparty/
   ├─ include/   # .h头文件
   └─ lib/
      ├─ Release/xxx.lib
      └─ Release/xxx.dll
```

### CMakeLists.txt 完整示例

```cmake
cmake_minimum_required(VERSION 3.16)
project(DllTest)

# 1. 设置C++标准
set(CMAKE_CXX_STANDARD 17)

# 2. 头文件目录
include_directories(${PROJECT_SOURCE_DIR}/thirdparty/include)
# 新版推荐写法（目标级，更规范）
# target_include_directories(你的目标 PRIVATE ${PROJECT_SOURCE_DIR}/thirdparty/include)

# 3. 生成可执行程序
add_executable(DllTest main.cpp)

# 4. 链接 .lib 导入库
# 写法A：绝对路径
target_link_libraries(DllTest PRIVATE ${PROJECT_SOURCE_DIR}/thirdparty/lib/Release/xxx.lib)

# 写法B：区分Debug/Release（必用，Debug库和Release库不能混用）
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_link_libraries(DllTest PRIVATE ${PROJECT_SOURCE_DIR}/thirdparty/lib/Debug/xxxd.lib)
else()
    target_link_libraries(DllTest PRIVATE ${PROJECT_SOURCE_DIR}/thirdparty/lib/Release/xxx.lib)
endif()
```

## 三、写法 2：find_library 自动搜索（工程通用）

自动在指定目录搜索 lib，适配不同平台、不同路径：

```cmake
# 搜索库：库名xxx，搜索路径
find_library(XXX_LIB
    NAMES xxx          # lib名称，自动匹配 xxx.lib / xxxd.lib
    PATHS ${PROJECT_SOURCE_DIR}/thirdparty/lib/Release
    NO_DEFAULT_PATH
)

# 判断是否找到
if(NOT XXX_LIB)
    message(FATAL_ERROR "未找到xxx.lib导入库！")
endif()

# 链接找到的库
target_link_libraries(DllTest PRIVATE ${XXX_LIB})
```

## 四、写法 3：导入已有第三方库（预编译库）

用 `add_library(IMPORTED)` 标准导入 DLL 库，工业项目标准写法：

```cmake
# 导入动态库
add_library(xxx SHARED IMPORTED)

# 设置头文件路径
target_include_directories(xxx INTERFACE ${PROJECT_SOURCE_DIR}/thirdparty/include)

# 设置导入库(.lib)路径
set_target_properties(xxx PROPERTIES
    IMPORTED_LOCATION_RELEASE "${PROJECT_SOURCE_DIR}/thirdparty/lib/Release/xxx.dll"  # dll路径
    IMPORTED_IMPLIB_RELEASE   "${PROJECT_SOURCE_DIR}/thirdparty/lib/Release/xxx.lib"  # lib路径
    IMPORTED_LOCATION_DEBUG   "${PROJECT_SOURCE_DIR}/thirdparty/lib/Debug/xxxd.dll"
    IMPORTED_IMPLIB_DEBUG     "${PROJECT_SOURCE_DIR}/thirdparty/lib/Debug/xxxd.lib"
)

# 链接目标
target_link_libraries(DllTest PRIVATE xxx)
```

## 五、运行时 dll 找不到的解决办法（最常见报错）

编译成功，运行提示**无法找到 xxx.dll**，4 种解决方案：

1. **最简单**：把 `xxx.dll` 复制到**exe 输出目录**（`CMAKE_RUNTIME_OUTPUT_DIRECTORY`） ```cmake
   # 自动复制dll到exe目录（CMake自动部署）
   configure_file(${PROJECT_SOURCE_DIR}/thirdparty/lib/Release/xxx.dll
               ${CMAKE_BINARY_DIR}/Debug/xxx.dll COPYONLY)
   ```
2. 把 dll 所在文件夹加入系统 `PATH` 环境变量；
3. VS 开发：配置属性 → 调试 → 环境，添加路径：`PATH=库路径;%PATH%`；
4. 放到系统目录：`C:\Windows\System32`(64 位 dll) / `SysWOW64`(32 位 dll)。

## 六、常见坑点

1. **32 位 / 64 位不匹配**：编译器架构必须和 dll 架构完全一致；
2. **Debug/Release 混用**：Debug 程序只能链接带`d`后缀的 Debug 库，Release 同理；
3. 只放 dll、没链接 lib：编译直接报 `unresolved external symbol` 未定义引用；
4. MSVC 运行库版本不一致：第三方库用 MD/MT，项目 Runtime 设置要保持一致。 设置方法： ```cmake
   set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>") # MT/MTd
   # set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL") # MD/MDd
   ```

## 七、静态库 (.lib) vs 动态库 (DLL) CMake 区别

- 静态库：直接链接 `.lib`，代码打包进 exe，运行不需要额外文件；
- 动态库：编译链接`.lib导入库`，运行必须依赖`.dll`，体积小、可单独更新库文件。