---
title: CMake 现代特性完整汇总（3.19 ~ 4.2，工程实战向）
---

# CMake 现代特性完整汇总（3.19 ~ 4.2，工程实战向）

现代 CMake 核心思想：**面向目标 (Target-based)、无全局污染、可复用、多环境统一管理**，淘汰 `include_directories / link_directories / add_definitions` 等全局旧式命令。
 按模块分类，覆盖你前面聊过的 Presets、Toolchain、多后端、依赖管理、C++20 Modules、导入第三方库、构建优化等全部相关能力。

## 一、核心根基：面向目标 Target 体系（3.0+ 现代基石）

### 1. 三级作用域（PUBLIC / PRIVATE / INTERFACE）

彻底替代全局头文件、全局宏、全局链接，依赖自动传递

- `target_include_directories()`：头文件路径
- `target_compile_definitions()`：宏定义
- `target_compile_options()`：编译参数
- `target_link_options()`：链接参数
- `target_link_libraries()`：库链接（自动传递依赖）
- `target_sources()`：源码绑定到目标（3.1+）

```cmake
add_library(mylib STATIC src/lib.cpp)
# PUBLIC：库内部 + 使用者都可见
target_include_directories(mylib PUBLIC include)
# PRIVATE：仅库内部
target_compile_definitions(mylib PRIVATE INTERNAL_BUILD)
# INTERFACE：只暴露给使用者，库自己不用
target_compile_definitions(mylib INTERFACE API_EXPORT=1)
```

### 2. IMPORTED 导入目标（引入预编译 DLL/Lib，前面讲过）

统一封装外部非 CMake 库，像普通目标一样链接，支持区分 Debug/Release：

```cmake
add_library(extlib SHARED IMPORTED GLOBAL)
set_target_properties(extlib PROPERTIES
    IMPORTED_IMPLIB_RELEASE "${EXT_ROOT}/lib/ext.lib"
    IMPORTED_LOCATION_RELEASE "${EXT_ROOT}/bin/ext.dll"
)
target_link_libraries(app PRIVATE extlib)
```

### 3. ALIAS 别名目标

给库起短别名，简化跨目录引用：

```cmake
add_library(mylib_core STATIC src/core.cpp)
add_library(my::core ALIAS mylib_core)
# 上层直接用别名
target_link_libraries(app PRIVATE my::core)
```

### 4. FILE_SET 现代安装导出（3.23+，替代手动 install 目录）

批量管理头文件，导出时自动传递，解决旧版 `install(DIRECTORY)` 混乱问题：

```cmake
target_sources(mylib PUBLIC FILE_SET HEADERS
    BASE_DIRS ${CMAKE_SOURCE_DIR}/include
    FILES include/mylib/*.h
)
install(TARGETS mylib EXPORT mylibTargets FILE_SET HEADERS DESTINATION include)
```

## 二、多环境统一管理：CMake Presets（3.19+，你重点用过）

项目级 `CMakePresets.json` + 个人本地 `CMakeUserPresets.json`，彻底抛弃零散 `-D` 参数

1. **configurePresets**：统一管理生成器、toolchainFile、架构、缓存变量、环境变量
2. **buildPresets**：绑定配置预设，一键构建、指定目标、附加后端参数
3. **testPresets**：ctest 测试预设
4. 高级能力：
   - `inherits` 预设继承，公共配置抽离隐藏父预设
   - `condition` 按系统 / 架构自动启用预设
   - `include` 拆分大预设文件（Presets v4+）
   - 内置变量 `${sourceDir}` `${presetName}` `${hostSystemName}`
5. 命令行：`cmake --preset xxx` / `cmake --build --preset build-xxx`
6. 全 IDE 原生支持：VS2022、CLion、VSCode CMake Tools

## 三、依赖管理现代化（两大核心方案）

### 1. FetchContent（3.14+，替代老旧 ExternalProject）

**配置阶段下载源码并纳入构建**，子项目完全共享主项目 Toolchain、编译器、构建类型，调试源码无壁垒

```cmake
include(FetchContent)
FetchContent_Declare(fmt
  GIT_REPOSITORY https://github.com/fmtlib/fmt.git
  GIT_TAG 10.2.0
  GIT_SHALLOW ON
)
FetchContent_MakeAvailable(fmt)
target_link_libraries(app PRIVATE fmt::fmt)
```

对比 ExternalProject：

- FetchContent：configure 阶段拉取，可直接 `add_subdirectory`，共享编译环境
- ExternalProject：build 阶段才编译，环境隔离，适合非 CMake 外部工程

### 2. find_package Config 模式（现代第三方库标准）

库编译 install 导出 `xxxConfig.cmake`，无需手写 FindXXX.cmake，支持组件、版本约束：

```cmake
find_package(fmt 10 REQUIRED CONFIG)
find_package(Boost REQUIRED COMPONENTS system thread)
```

全局搜索路径统一由 Presets `CMAKE_PREFIX_PATH` 管理。

## 四、构建后端现代化（多 Generator，含 FASTBuild 4.2 新增）

1. **Ninja**：跨平台极速增量，开发首选
2. **Visual Studio / Xcode**：IDE 图形工程
3. **FASTBuild Generator（CMake 4.2+ 重磅）** 原生生成 `fbuild.bff`，单机缓存、分布式集群编译，适配百万行大型 C++ 引擎
4. Make 系列：Unix Makefiles / MinGW Makefiles
5. 统一切换方式：Presets 中修改 `generator` 字段，无需改动 CMakeLists

## 五、Toolchain 工具链标准化（现代跨平台 / 交叉编译标配）

独立 `.toolchain.cmake` 文件统一锁定编译器、架构、系统、编译标志，配合 Presets 一键切换编译环境：

- Windows MSVC / MinGW 工具链
- Linux GCC/Clang
- ARM 嵌入式交叉编译
- Emscripten WebAssembly 核心变量：`CMAKE_C_COMPILER` / `CMAKE_CXX_COMPILER` / `CMAKE_FIND_ROOT_PATH`

## 六、C++20 一等公民：C++ Modules 原生支持（3.28+）

CMake 原生扫描 `import / module` 依赖，自动生成 BMI/CMI 模块缓存文件，解决传统头文件编译缓慢问题：

1. 自动扫描源码模块依赖，动态构建编译顺序
2. 目标属性控制模块缓存目录：`CXX_MODULES_DIRECTORY`
3. Ninja/VS/FASTBuild 全部后端兼容

```cmake
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
target_sources(app PRIVATE src/mod.cppm src/main.cpp)
```

## 七、生成器表达式（跨配置条件编译，3.10 + 成熟）

在目标属性中写条件逻辑，替代大量 `if(CMAKE_BUILD_TYPE)`，Debug/Release 自动区分：

```cmake
# Debug用MDd，Release用MD
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

# 仅Windows添加编译参数
target_compile_options(app PRIVATE $<$<PLATFORM_ID:Windows>:/utf-8 /W4>)

# 复制DLL（前面自动拷贝逻辑）
$<TARGET_FILE:extlib> $<TARGET_FILE_DIR:app>
```

常用表达式：`<CONFIG:Debug>`、`<PLATFORM_ID>`、`<CXX_COMPILER_ID:MSVC>`、`<TARGET_FILE>`

## 八、文件与脚本现代化命令

### 1. file () 增强（替代旧 configure_file）

```cmake
# 内存字符串替换，无需生成中间文件
file(CONFIGURE OUTPUT "${CMAKE_BINARY_DIR}/config.h" CONTENT "#define VER @VERSION@")
# 递归遍历带变更依赖（GLOB不再每次重配）
file(GLOB_RECURSE SOURCES CONFIGURE_DEPENDS src/*.cpp)
# 下载/解压二进制依赖包
file(DOWNLOAD URL ...)
file(ARCHIVE_EXTRACT ...)
```

### 2. cmake_language 脚本调试（4.2+）

```cmake
cmake_language(TRACE ON) # 开启脚本执行跟踪，排查CMake逻辑
```

### 3. 并行安装（3.31+）

```cmake
set(CMAKE_INSTALL_PARALLEL ON)
```

## 九、导入导出与打包现代化

### 1. EXPORT 导出目标（跨工程复用库）

子项目导出 `xxxTargets.cmake`，其他项目可 `find_package` 引入，完整传递头文件、链接、模块依赖：

```cmake
install(TARGETS mylib EXPORT mylibTargets
    LIBRARY DESTINATION lib
    INCLUDES DESTINATION include
)
install(EXPORT mylibTargets FILE mylibConfig.cmake DESTINATION lib/cmake/mylib)
```

### 2. CPack 现代打包（AppImage、NSIS、ZIP、TGZ）

一键生成多平台安装包，Presets 统一配置打包参数。

## 十、4.x 全新重磅特性（4.0~4.2）

1. **FASTBuild 官方生成器**，大型工程分布式编译
2. VS 2026 生成器 `Visual Studio 18 2026`
3. `set(CACHE{VAR})` 直接操作缓存变量
4. 生成器表达式新增 `TARGET_INTERMEDIATE_DIR`（目标 obj 中间目录）
5. Emscripten WebAssembly 工具链原生简化支持
6. `SKIP_LINTING` 跳过静态分析加速构建

## 十一、现代 CMake 规范（对应上面所有特性）

### 禁止旧式全局命令（现代写法完全替代）

- 弃用 `include_directories` → `target_include_directories`
- 弃用 `link_directories` → `target_link_libraries(IMPORTED目标)`
- 弃用 `add_definitions` → `target_compile_definitions`
- 弃用 `file(GLOB)` 不带 `CONFIGURE_DEPENDS`
- 弃用零散命令行 `-D` 参数 → 统一 Presets

### 最佳工程分层搭配（你整套工作流）

1. `toolchain/*.toolchain.cmake`：底层编译器、架构
2. `CMakePresets.json`：生成器、输出目录、环境、第三方库根路径
3. `CMakeLists.txt`：纯面向 Target，FetchContent 管理依赖
4. `IMPORTED` 导入非 CMake 第三方 DLL/Lib
5. 后端按需切换 Ninja / FASTBuild / VS Solution
6. C++20 Modules 原生加速编译