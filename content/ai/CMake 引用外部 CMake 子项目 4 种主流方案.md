---
title: CMake 引用外部 CMake 子项目 4 种主流方案
---

# CMake 引用外部 CMake 子项目 4 种主流方案

按使用场景从简单到工程化排序，分别是：`add_subdirectory` 源码内嵌、`FetchContent` 自动拉取源码编译、`find_package` 查找预编译库、`ExternalProject` 外部编译，同时适配 Presets+Toolchain。

## 一、方案 1：add_subdirectory（源码放在本地，最常用）

适合：**拿到第三方完整 CMake 源码**，放在项目内作为子模块，一起编译。

### 目录结构

```plaintext
ProjectRoot/
├─ CMakeLists.txt
├─ main.cpp
└─ 3rdparty/
   └─ mylib/        # 第三方CMake项目（自带CMakeLists.txt）
      ├─ CMakeLists.txt
      └─ src/
```

### 顶层 CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.20)
project(MainProject)

# 1. 引入子CMake项目
add_subdirectory(3rdparty/mylib)

# 主程序
add_executable(main main.cpp)

# 2. 直接链接子项目暴露的目标名（重点：用TARGET，不用路径）
target_link_libraries(main PRIVATE mylib)
```

### 子项目对外暴露（子项目必须写）

子项目 `3rdparty/mylib/CMakeLists.txt`，用 `INTERFACE` 对外导出头文件路径，上层项目自动继承头文件，无需手动 `include_directories`：

```cmake
# 子项目生成静态/动态库
add_library(mylib SHARED src/mylib.cpp)

# 对外暴露头文件目录，上层链接 mylib 自动生效
target_include_directories(mylib
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)
```

- `PUBLIC`：库自身 + 调用方都能看到头文件
- `PRIVATE`：仅库内部使用
- `INTERFACE`：只给调用方使用

### 优缺点

✅ 优点：编译同步、调试源码、一键全编译、完美兼容 Toolchain/Presets，工具链全局生效
 ❌ 缺点：源码体积大，需要本地存放完整代码

## 二、方案 2：FetchContent（自动下载源码 + 编译，现代 CMake 首选）

无需手动下载源码，CMake 配置阶段自动从 Git/URL 拉取第三方 CMake 项目，自动执行 `add_subdirectory`，现代项目标准用法。

### 完整示例

```cmake
cmake_minimum_required(VERSION 3.20)
project(Main)

# 开启FetchContent模块
include(FetchContent)

# 配置要拉取的仓库
FetchContent_Declare(
    fmt  # 库名称
    GIT_REPOSITORY https://github.com/fmtlib/fmt.git
    GIT_TAG        10.2.0  # 指定tag/分支/commit
    SOURCE_DIR     ${CMAKE_SOURCE_DIR}/3rdparty/fmt  # 本地存放目录
)

# 自动下载、解压、执行子项目CMake
FetchContent_MakeAvailable(fmt)

# 直接链接目标 fmt
add_executable(main main.cpp)
target_link_libraries(main PRIVATE fmt)
```

### 常用参数

1. `GIT_SHALLOW ON`：浅克隆，只拉当前版本，加速下载
2. `URL xxx.zip`：直接下载压缩包，替代 Git
3. `FETCHCONTENT_UPDATES_DISCONNECTED ON`：离线模式，已下载源码不再联网更新

### 搭配 Presets / Toolchain

FetchContent 下载的子项目，**自动继承当前的 Toolchain 工具链、编译器、构建类型**，不需要额外配置，切换 Presets（MSVC/MinGW）子库会同步编译。

## 三、方案 3：find_package（查找已经编译好的 CMake 库，预编译产物）

适合：第三方项目已经编译完成，导出了 **CMake 配置文件（xxxConfig.cmake/xxx-config.cmake）**，只需要调用，不再重新编译源码。
 分为两种模式：**Module 模式 (FindXXX.cmake)**、**Config 模式 (官方库标配)**。

### 1. Config 模式（主流，现代第三方库）

以常用库为例，库安装后自带 `fmtConfig.cmake` 配置文件

```cmake
# 查找库，REQUIRED 找不到直接报错
find_package(fmt REQUIRED)

# 链接目标 fmt::fmt
add_executable(main main.cpp)
target_link_libraries(main PRIVATE fmt::fmt)
```

### 2. 指定库搜索路径（本地第三方编译好的库）

如果库不在系统默认路径，两种方式指定路径：

#### 方式 A：CMakeLists 内设置路径

```cmake
# 库的安装根目录
set(fmt_ROOT "D:/3rdparty/fmt-msvc-x64")
find_package(fmt REQUIRED)
```

#### 方式 B：在 CMakePresets.json 全局配置（推荐）

```json
"cacheVariables": {
  "fmt_ROOT": "${sourceDir}/out/install/fmt-release-x64",
  "CMAKE_PREFIX_PATH": "${sourceDir}/out/install/fmt-release-x64"
}
```

`CMAKE_PREFIX_PATH` 是 CMake 搜索预编译 CMake 库的全局路径。

### 关键前提

第三方 CMake 项目编译安装时，必须执行 `install()` 导出配置文件，子项目 CMake 需要写安装脚本：

```cmake
# 子项目末尾，导出CMake配置
install(TARGETS mylib EXPORT mylibTargets
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
    INCLUDES DESTINATION include
)
# 生成xxxConfig.cmake
install(EXPORT mylibTargets
    FILE mylibConfig.cmake
    DESTINATION lib/cmake/mylib
)
install(DIRECTORY include/ DESTINATION include)
```

编译执行 `cmake --install` 后，才会生成可供 `find_package` 读取的文件。

## 四、方案 4：ExternalProject（独立进程编译外部项目）

子项目**完全独立编译**，使用单独的编译器 / 构建目录，主项目编译时自动触发外部项目构建，适合跨工具链编译、交叉编译依赖，和主进程 CMake 环境隔离。

```cmake
include(ExternalProject)

ExternalProject_Add(
    mylib_external
    GIT_REPOSITORY https://xxx/mylib.git
    GIT_TAG main
    SOURCE_DIR ${CMAKE_SOURCE_DIR}/3rdparty/mylib
    BINARY_DIR ${CMAKE_BINARY_DIR}/build_mylib
    INSTALL_DIR ${CMAKE_BINARY_DIR}/install_mylib
    # 可以给子项目单独传工具链、编译参数
    CMAKE_ARGS
        -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}
        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
)

# 拿到编译后的lib文件路径
ExternalProject_Get_Property(mylib_external INSTALL_DIR)
set(MYLIB_LIB ${INSTALL_DIR}/lib/mylib.lib)
set(MYLIB_INC ${INSTALL_DIR}/include)

# 主程序链接
add_executable(main main.cpp)
target_include_directories(main PRIVATE ${MYLIB_INC})
target_link_libraries(main PRIVATE ${MYLIB_LIB})
# 强制主项目等待外部项目编译完成
add_dependencies(main mylib_external)
```

⚠️ 缺点：无法直接使用目标名，只能链接文件路径，调试麻烦，**日常开发优先用 FetchContent**。

## 五、四种方案选型对照表

| 方⁠案 | 适⁠用⁠场⁠景 | 能⁠否⁠调⁠试⁠源⁠码 | 共⁠用 Toolchain | 性⁠能 |
| --- | --- | --- | --- | --- |
| add_subdirectory | 本⁠地⁠已⁠有⁠源⁠码，内⁠部⁠子⁠模⁠块 | ✅ 可⁠以 | ✅ 完⁠全⁠共⁠用 | 最⁠优 |
| FetchContent | 开⁠源⁠库⁠自⁠动⁠拉⁠取，现⁠代⁠开⁠发 | ✅ 可⁠以 | ✅ 完⁠全⁠共⁠用 | 优⁠秀 |
| find_package | 预⁠编⁠译⁠成⁠品⁠库，不⁠编⁠译⁠源⁠码 | ❌ 不⁠可 | 读⁠取⁠现⁠有⁠产⁠物 | 最⁠快 |
| ExternalProject | 子⁠项⁠目⁠需⁠要⁠独⁠立⁠编⁠译、交⁠叉⁠编⁠译 | 麻⁠烦 | 可⁠单⁠独⁠指⁠定⁠工⁠具⁠链 | 较⁠慢 |

## 六、配套实用要点（结合你之前的 Preset/Toolchain/DLL）

### 1. 动态库 DLL 子项目的自动复制

子项目是 SHARED DLL，编译后主程序 exe 运行缺 dll，可在顶层 CMake 自动拷贝：

```cmake
# mylib为子项目目标，自动复制dll到exe输出目录
add_custom_command(TARGET main POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        $<TARGET_FILE:mylib>
        $<TARGET_FILE_DIR:main>
)
```

### 2. Git 子模块配合 add_subdirectory

```bash
# 添加子模块
git submodule add https://xxx/mylib.git 3rdparty/mylib
git submodule update --init --recursive
```

直接 `add_subdirectory(3rdparty/mylib)` 即可。

### 3. Presets 统一管理第三方库路径

所有第三方库的`ROOT`、`CMAKE_PREFIX_PATH`统一写在预设中，切换 Debug/Release、MSVC/MinGW 一键切换库版本，不用改 CMakeLists。

## 七、常见踩坑

1. **找不到头文件** 子项目必须用 `target_include_directories(PUBLIC)`，不要用全局 `include_directories`，否则上层无法继承头文件。
2. **子项目编译器和主项目不一致**`FetchContent/add_subdirectory` 会完全继承顶层 Toolchain，`ExternalProject` 需要手动传 `-DCMAKE_TOOLCHAIN_FILE`。
3. find_package 找不到库 检查三点：①路径写入`CMAKE_PREFIX_PATH` ②库目录存在`xxxConfig.cmake` ③架构 (32/64)、Debug/Release 运行库匹配。
4. 循环依赖 A 链接 B，B 又链接 A，CMake 直接报错，重构依赖结构。