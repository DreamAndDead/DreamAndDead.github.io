---
title: Windows MSVC + CMake 完整落地 C++20 Modules 实战方案
---

# Windows MSVC + CMake 完整落地 C++20 Modules 实战方案

整套流程贴合你现有的 **CMake Presets + Toolchain + Ninja/FASTBuild** 工作流，从环境准备、目录结构、代码写法、CMake 配置、编译、混用旧头文件、常见问题全覆盖，可直接落地。

## 一、硬性环境要求（缺一不可）

1. **编译器** VS2022，版本 ≥ 17.4，平台工具集 `v14.34` 及以上，**无需 `/experimental:module`**，正式稳定版。
2. **CMake 版本** 最低 **3.28**，推荐 3.30+ / CMake 4.x，自带模块依赖自动扫描；
3. **构建后端（Generator）必须二选一** ✅ 支持：`Ninja`（开发首选）、`Visual Studio 17 2022` ❌ 完全不支持：MinGW Makefiles、Unix Makefiles 等 Make 系列生成器。
4. 后端可选升级：CMake4.2+ 的 **FASTBuild** 原生完美兼容 Modules，大型引擎首选。

## 二、标准目录结构（规范模块分层）

```plaintext
Project/
├─ CMakePresets.json          # 预设配置 Ninja/MSVC
├─ toolchain/msvc.toolchain.cmake
├─ CMakeLists.txt
├─ src/
│  ├─ modules/                # 存放所有模块接口 .ixx
│  │  └─ math.ixx
│  ├─ math_impl.cpp           # 模块实现文件
│  └─ main.cpp                # 入口，import 模块
└─ out/                       # Presets编译输出
```

## 三、分步代码编写

### 1. 模块接口文件：`src/modules/math.ixx`（对外 API）

后缀 `.ixx` 是 MSVC 标准模块接口后缀，负责定义导出符号。

```cpp
// 声明模块名称
export module math;

// 导出：外部可以访问
export int Add(int a, int b);
export int Mul(int a, int b);

// 未 export：模块私有，外部完全不可见
static int InternalCalc(int x);

// 模块内宏，不会泄露到外部代码
#define MOD_VERSION 1
```

### 2. 模块实现文件：`src/math_impl.cpp`

只归属模块，**不需要头文件**，只写 `module math;`，不用 `export`。

```cpp
module math; // 绑定所属模块

int Add(int a, int b)
{
    return a + b;
}

int Mul(int a, int b)
{
    return a * b;
}

int InternalCalc(int x)
{
    return x * 2;
}
```

### 3. 入口 main.cpp 使用模块

两种导入：**自定义模块** + **标准库 Header Unit**（日常稳定方案）

```cpp
// 导入自定义模块
import math;
// 标准库头文件单元（稳定，推荐日常使用）
import <iostream>;

int main()
{
    std::cout << Add(10, 20) << "\n";
    std::cout << Mul(6, 7) << "\n";
    return 0;
}
```

> 补充：完整标准库 `import std;` 属于实验特性，CMake3.30 + 才可开启，生产优先用 `import <xxx>`。

## 四、CMakeLists.txt 完整配置（现代标准写法）

```cmake
cmake_minimum_required(VERSION 3.28)
project(ModuleDemo LANGUAGES CXX)

# 1. C++20 标准强制开启
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 2. 全局开启 C++模块自动依赖扫描（核心开关）
set(CMAKE_CXX_SCAN_FOR_MODULES ON CACHE BOOL "Enable C++20 Modules scan")

# 3. 生成可执行目标
add_executable(App main.cpp math_impl.cpp)

# 4. 注册模块接口文件 CXX_MODULES（CMake识别模块的关键）
target_sources(App
    PUBLIC
    FILE_SET CXX_MODULES
        BASE_DIRS ${CMAKE_SOURCE_DIR}
        FILES src/modules/math.ixx
)

# 可选：统一模块缓存ifc存放目录
set_property(TARGET App PROPERTY CXX_MODULES_DIRECTORY ${CMAKE_BINARY_DIR}/ifc)
```

## 五、CMakePresets.json 配置（Ninja MSVC 方案）

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "msvc-ninja-debug",
      "displayName": "MSVC Ninja Debug Modules",
      "hidden": false,
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/out/build/${presetName}",
      "installDir": "${sourceDir}/out/install/${presetName}",
      "architecture": {
        "value": "x64",
        "strategy": "external"
      },
      "toolchainFile": "${sourceDir}/toolchain/msvc.toolchain.cmake",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_CXX_SCAN_FOR_MODULES": "ON",
        "CMAKE_MSVC_RUNTIME_LIBRARY": "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "build-debug",
      "configurePreset": "msvc-ninja-debug",
      "targets": ["App"]
    }
  ]
}
```

## 六、msvc.toolchain.cmake 工具链配套

```cmake
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_CXX_COMPILER cl.exe)
set(CMAKE_C_COMPILER cl.exe)
add_compile_options(/utf-8 /W4)
```

## 七、命令行一键编译执行

```bash
# 配置预设
cmake --preset msvc-ninja-debug
# 构建
cmake --build --preset build-debug
# 运行产物 out/build/msvc-ninja-debug/App.exe
```

## 八、老项目核心需求：Modules 与传统 #include 头文件混合使用

### 规则：

1. **模块实现文件 (.cpp) 可以随意 #include 旧头文件**（完美兼容存量代码）
2. **模块接口 .ixx 尽量少 #include**，容易产生依赖混乱
3. 老式头文件代码，**无法 import 模块**，只能新模块兼容旧代码。

示例（模块实现引入第三方旧头）：

```cpp
module math;
#include "old_utils.h"  // 合法，实现文件内可以包含老式头

int Add(int a, int b)
{
    return OldSafeAdd(a, b);
}
```

## 九、多子项目 / 静态库之间互相调用模块

子库用 `FILE_SET CXX_MODULES` 导出模块，上层项目直接链接目标即可自动识别模块：

```cmake
# 子库
add_library(math_lib STATIC math_impl.cpp)
target_sources(math_lib PUBLIC FILE_SET CXX_MODULES FILES src/modules/math.ixx)

# 主程序链接子库，直接 import math;
target_link_libraries(App PRIVATE math_lib)
```

## 十、进阶：FASTBuild 后端使用 Modules（大型项目）

只需修改 Presets 的 `generator: "FASTBuild"`，CMake4.2 + 原生支持，`.ifc` 模块文件可以参与 FASTBuild 全局缓存，百万行引擎编译速度拉满：

```json
"generator": "FASTBuild"
```

构建命令携带缓存：

```bash
cmake --build --preset build-fb -- -cache
```

## 十一、高频坑点与解决方案

1. **报错：CXX_MODULES 不被识别 / 模块扫描失效**
   - 原因：CMake 版本过低，或者使用了 Make 生成器
   - 解决：升级 CMake≥3.28，强制使用 Ninja / VS 生成器。
2. Ninja 模式找不到 `cl.exe`
   在 **x64 Native Tools Command Prompt for VS2022** 执行命令行，或者在 Presets 的 `environment` 注入 VS 的 VC 环境 PATH。
3. 修改模块实现文件，不需要全项目重编
   只改 `math_impl.cpp`：仅重编当前文件；
   修改接口 `math.ixx`：才会重新生成 `.ifc`，所有导入该模块的代码重编，这是 Modules 核心优势。
4. 提示 `import <iostream>` 找不到
   确认 VS 版本 ≥17.4，工具集版本足够，不要用老旧 VS2019。
5. 清理模块缓存
   彻底重载配置：```bash
   cmake --preset msvc-ninja-debug --fresh
   ```

## 十二、落地选型建议

1. **全新中小型项目**：MSVC + Ninja + Header Unit（`import <xxx>`），稳定省心。
2. **游戏 / 大型引擎项目**：CMake4.2 + FASTBuild + C++20 Modules，编译速度最优。
3. **存量老项目**：渐进式改造，新增代码用 Modules，旧代码保留头文件，双向混合兼容。
4. **跨平台项目**：替换编译器为 LLVM Clang for Windows，Modules 标准兼容性更强，Windows/Linux 行为统一。