---
title: CMake 项目引入 ImGui（原生 Make/VS 工程，无自带 CMake）四种常用方案，按推荐度排序
---

# CMake 项目引入 ImGui（原生 Make/VS 工程，无自带 CMake）四种常用方案，按推荐度排序

ImGui 本身没有官方 CMakeLists，主流引入方式：**手动加源码、子目录引入、FetchContent 在线拉取、静态库预编译**。下面以标准项目结构举例，一步到位。

## 项目目录结构

```plaintext
ProjectRoot/
├── CMakeLists.txt
├── src/          # 你的业务代码
└── thirdparty/
    └── imgui/    # 完整解压的imgui源码（包含backends、misc等文件夹）
```

## 方案 1：手动把 ImGui 源码加入当前工程（最简单，首选）

### 1. 需要纳入编译的核心源码

基础核心文件：

```cpp
imgui.cpp imgui_demo.cpp imgui_draw.cpp imgui_tables.cpp imgui_widgets.cpp
```

**必须配套后端**（根据渲染 API 二选一）：

- OpenGL + GLFW：`backends/imgui_impl_glfw.cpp` + `backends/imgui_impl_opengl3.cpp`
- DirectX11 + Win32：`backends/imgui_impl_win32.cpp` + `backends/imgui_impl_dx11.cpp`

### 2. CMake 写法

```cmake
# 1. 定义ImGui路径
set(IMGUI_ROOT ${PROJECT_SOURCE_DIR}/thirdparty/imgui)

# 2. 收集核心源码
file(GLOB IMGUI_SOURCES
    ${IMGUI_ROOT}/*.cpp
    # 按需开启对应后端
    ${IMGUI_ROOT}/backends/imgui_impl_win32.cpp
    ${IMGUI_ROOT}/backends/imgui_impl_dx11.cpp
)

# 3. 创建静态库（推荐封装成静态库，解耦）
add_library(imgui STATIC ${IMGUI_SOURCES})

# 4. 头文件目录暴露给主程序
target_include_directories(imgui PUBLIC
    ${IMGUI_ROOT}
    ${IMGUI_ROOT}/backends
)

# 5. 主程序可直接链接
add_executable(App src/main.cpp)
target_link_libraries(App PRIVATE imgui)
```

### 配套依赖说明

1. DX11/Win32 后端：Windows 系统自带，无需额外库；
2. GLFW/OpenGL 后端：你的项目必须提前配置好 **glfw**，CMake 正常 find_package 即可；
3. 编译选项可统一挂在 `imgui` 这个静态库目标上，不会污染主程序。

## 方案 2：使用 FetchContent 自动下载 ImGui（无需手动下载源码）

不用手动放 thirdparty，CMake 配置时自动从 GitHub 拉取源码，适合版本管控。

```cmake
include(FetchContent)

FetchContent_Declare(
  imgui
  GIT_REPOSITORY https://github.com/ocornut/imgui.git
  GIT_TAG docking  # 常用docking分支，也可以写固定tag版本号
)
FetchContent_MakeAvailable(imgui)

# 后续逻辑和方案1完全一致，${imgui_SOURCE_DIR} 为自动下载的源码路径
set(IMGUI_ROOT ${imgui_SOURCE_DIR})
file(GLOB IMGUI_SOURCES
    ${IMGUI_ROOT}/*.cpp
    ${IMGUI_ROOT}/backends/imgui_impl_win32.cpp
    ${IMGUI_ROOT}/backends/imgui_impl_dx11.cpp
)
add_library(imgui STATIC ${IMGUI_SOURCES})
target_include_directories(imgui PUBLIC ${IMGUI_ROOT} ${IMGUI_ROOT}/backends)
target_link_libraries(App PRIVATE imgui)
```

## 方案 3：单独编译 ImGui 为静态库，外部链接

1. 用 VS / Make 手动编译 `imgui.lib`（Windows），得到静态库文件；
2. CMake 只配置头文件路径 + 链接库文件：

```cmake
set(IMGUI_INC ${PROJECT_SOURCE_DIR}/thirdparty/imgui)
set(IMGUI_LIB ${PROJECT_SOURCE_DIR}/thirdparty/imgui/lib/imgui.lib)

target_include_directories(App PRIVATE ${IMGUI_INC} ${IMGUI_INC}/backends)
target_link_libraries(App PRIVATE ${IMGUI_LIB})
```

适合不想把 ImGui 源码混入主项目编译的场景，缺点是升级 ImGui 需要重新手动编译库。

## 方案 4：直接把源码扔进主 exe（小型项目简易写法）

不单独建静态库，源码直接归属于主程序，适合测试原型：

```cmake
add_executable(App
    src/main.cpp
    # 直接罗列imgui源码
    thirdparty/imgui/imgui.cpp
    thirdparty/imgui/imgui_draw.cpp
    thirdparty/imgui/backends/imgui_impl_win32.cpp
    thirdparty/imgui/backends/imgui_impl_dx11.cpp
)
target_include_directories(App PRIVATE thirdparty/imgui thirdparty/imgui/backends)
```

## 关键避坑点

1. **不要漏加 backend 后端文件** 只加核心 cpp、不加对应平台后端，必然调用函数找不到；
2. `imgui_demo.cpp` 包含全套示例代码，开发阶段加上，发布版本可以直接删掉减小体积；
3. C++ 标准统一 ImGui 用 C++11 起步，建议全局 `CMAKE_CXX_STANDARD 17/23`，主程序和 ImGui 编译标准必须一致；
4. 新增 / 删减 ImGui 源码文件后

- GLOB 写法：需要执行 `cmake --preset xxx --fresh` 重新扫描文件；
- 手动罗列文件：修改 CMakeLists 后重新 configure 即可；

5. 结合你当前的 Clang / MSVC 工具链 两套编译器编译出来的 `imgui.lib` **不能混用**，编译器必须保持一致。

## 调用示例（引入后直接使用）

```cpp
#include "imgui.h"
#include "backends/imgui_impl_win32.h"
#include "backends/imgui_impl_dx11.h"
```

按照对应后端流程初始化即可正常使用。