---
title: CMake 不用 file (GLOB) 引入 ImGui（标准手写源码列表，现代 CMake 规范）
---

# CMake 不用 file (GLOB) 引入 ImGui（标准手写源码列表，现代 CMake 规范）

核心：**手动逐条写全 cpp 文件**，完全摒弃自动通配扫描，文件增删必须手动改 CMakeLists，稳定可靠、不会出现新增文件 CMake 识别不到的问题，配合你的 Presets、clangd、C++ Modules 非常适配。

## 目录结构不变

```plaintext
ProjectRoot/
├── CMakeLists.txt
├── src/
└── thirdparty/imgui/
    ├── imgui.cpp
    ├── imgui_draw.cpp
    ├── imgui_widgets.cpp
    ├── imgui_tables.cpp
    ├── imgui_demo.cpp
    └── backends/
        ├── imgui_impl_win32.cpp
        └── imgui_impl_dx11.cpp
```

## 完整 CMake 代码（静态库封装，手写源码）

```cmake
# ImGui 根路径
set(IMGUI_ROOT "${PROJECT_SOURCE_DIR}/thirdparty/imgui")

# 【手写枚举所有源码，无GLOB】
set(IMGUI_SRC
    # 核心源码
    ${IMGUI_ROOT}/imgui.cpp
    ${IMGUI_ROOT}/imgui_draw.cpp
    ${IMGUI_ROOT}/imgui_widgets.cpp
    ${IMGUI_ROOT}/imgui_tables.cpp
    # Demo示例，正式发布可注释此行
    ${IMGUI_ROOT}/imgui_demo.cpp

    # 按需选择后端，这里以 Win32 + DX11 举例
    ${IMGUI_ROOT}/backends/imgui_impl_win32.cpp
    ${IMGUI_ROOT}/backends/imgui_impl_dx11.cpp
)

# 创建静态库目标
add_library(imgui STATIC ${IMGUI_SRC})

# 头文件目录对外暴露 PUBLIC，主程序可直接 include
target_include_directories(imgui PUBLIC
    ${IMGUI_ROOT}
    ${IMGUI_ROOT}/backends
)

# 可选：统一给imgui设置C++标准，和主工程保持一致
target_compile_features(imgui PRIVATE cxx_std_23)

# 主程序可直接链接
add_executable(App src/main.cpp)
target_link_libraries(App PRIVATE imgui)
```

## OpenGL/GLFW 后端替换示例

如果用 GLFW + OpenGL3，替换后端文件即可：

```cmake
set(IMGUI_SRC
    # 核心不变
    ${IMGUI_ROOT}/imgui.cpp
    ${IMGUI_ROOT}/imgui_draw.cpp
    ${IMGUI_ROOT}/imgui_widgets.cpp
    ${IMGUI_ROOT}/imgui_tables.cpp
    ${IMGUI_ROOT}/imgui_demo.cpp
    # 更换后端
    ${IMGUI_ROOT}/backends/imgui_impl_glfw.cpp
    ${IMGUI_ROOT}/backends/imgui_impl_opengl3.cpp
)
```

## 增删文件的正确操作

1. **新增 cpp 文件** 在 `IMGUI_SRC` 列表里手动添加一行完整路径，保存 CMakeLists。
2. **删除文件** 注释 / 删掉对应行。
3. **生效命令** 改完 CMake 脚本，执行一次常规 configure 即可，不需要必带`--fresh`，只有切换工具链、改 toolchain、Preset 参数时才用`--fresh`

```bash
cmake --preset 你的预设名
```

之后正常 build 编译。

## 优点（对比 GLOB）

1. **编译数据库 compile_commands.json 精准可控**，clangd 不会漏文件；
2. 不会出现新建源码文件，CMake 静默无视的坑；
3. 版本 Git 追踪清晰，新增文件 CMake 改动可见，团队协作稳定；
4. 完美适配 C++ Modules 工程，不会因为自动扫描带来缓存异常。

## 配套头文件引用

代码正常头文件写法：

```cpp
#include "imgui.h"
#include "backends/imgui_impl_win32.h"
#include "backends/imgui_impl_dx11.h"
```

## 补充：如果后续需要新增自定义 ImGui 扩展文件

同样手写加入列表即可，示例：

```cmake
set(IMGUI_SRC
    # ...原有文件
    ${IMGUI_ROOT}/my_extend_widget.cpp
)
```