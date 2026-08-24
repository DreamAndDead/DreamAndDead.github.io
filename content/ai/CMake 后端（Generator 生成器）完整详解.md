---
title: CMake 后端（Generator 生成器）完整详解
---

# CMake 后端（Generator 生成器）完整详解

CMake 本身**不是编译器，也不是构建工具**，它只是**构建文件生成器**。
 前端写 CMakeLists，CMake 根据你选定的**后端 Generator**，生成对应构建系统的工程文件，再由后端工具执行编译、链接。

## 一、后端两大主流类别

1. **IDE 工程后端**：生成 VS Solution、Xcode 工程，适合图形 IDE 打开
2. **命令行构建后端**：Ninja、Make、MinGW Make，纯命令行极速编译（开发首选）

## 二、常用后端完整列表 & 适用平台

### 1. Ninja（当下最推荐、跨平台全能后端）

**Generator 名称：`Ninja`**

- 平台：Windows (MSVC/MinGW)、Linux、macOS 全平台通用
- 特点： 增量编译极快、依赖解析高效、日志简洁、完美配合 VSCode/CLion 现代 CMake + Presets + Toolchain 的标准搭档
- 依赖：需要单独安装 Ninja 程序，放在环境 PATH
- MSVC 使用前提：必须在 VS 开发者命令行，或 Presets 配置好 VS 环境变量

```json
// Presets 写法
"generator": "Ninja"
```

### 2. Visual Studio 解决方案后端（Windows MSVC 专用）

`Visual Studio 17 2022` （VS2022）
`Visual Studio 16 2019` （VS2019）

- 作用：生成 `.sln` 解决方案 + `.vcxproj` 工程文件，用 Visual Studio 打开
- 特点： 完整 VS 图形调试、属性页配置、自带 msbuild 构建； 缺点：sln 生成慢、增量编译速度远不如 Ninja
- 架构配置：配合 `architecture` 设置 x64/x86，不要手动改 sln

```json
"generator": "Visual Studio 17 2022",
"architecture": { "value": "x64", "strategy": "external" }
```

- 实际编译后端：底层调用 **MSBuild**

### 3. Makefile 系列（类 Unix 标准后端）

#### ① Unix Makefiles（Linux/macOS GCC/Clang 默认）

`generator: "Unix Makefiles"`
 生成标准 Makefile，后端用 `make` 命令编译

#### ② MinGW Makefiles（Windows MinGW GCC）

`generator: "MinGW Makefiles"`
 生成 Makefile，后端用 `mingw32-make.exe`

#### ③ MSYS Makefiles

适配 MSYS2 / Git Bash 环境的 Make

- 优缺点：稳定通用，但是增量编译速度弱于 Ninja

### 4. Xcode（macOS/iOS 专属）

`generator: "Xcode"`
 生成 `.xcworkspace` Xcode 工程，底层后端 `xcodebuild`，苹果开发专用。

### 5. 其他小众后端

- **NMake Makefiles**：微软自带命令行老式构建，基本淘汰
- **Watcom / Borland Makefiles**：古老编译器遗留
- **Green Hills、IAR Makefiles**：嵌入式专用 IDE 后端

## 三、后端底层执行工具对应关系

| CMake Generator（后⁠端⁠名⁠称） | 实⁠际⁠调⁠用⁠的⁠编⁠译⁠工⁠具 | 平⁠台 |
| --- | --- | --- |
| Ninja | ninja.exe / ninja | 全⁠平⁠台 |
| Visual Studio XX | MSBuild.exe | Windows |
| Unix Makefiles | make / gmake | Linux/macOS |
| MinGW Makefiles | mingw32-make | Windows MinGW |
| Xcode | xcodebuild | macOS |

## 四、Presets 中切换后端（一键切换）

只需要改 `generator` 字段即可切换整套后端，不用改 CMakeLists：

```json
"configurePresets": [
  {
    "name": "vs-sln",
    "generator": "Visual Studio 17 2022",
    "hidden": false
  },
  {
    "name": "ninja-msvc",
    "generator": "Ninja",
    "hidden": false
  }
]
```

## 五、怎么查看本机支持哪些后端

命令行执行：

```bash
cmake -G
```

会列出当前环境所有可用 Generator。

## 六、后端选型建议（实战最佳方案）

1. **Windows MSVC 日常开发**：首选 **Ninja**（速度快，VSCode/CLion 完美适配），需要图形调试再临时切 VS Solution
2. **Windows MinGW GCC**：优先 Ninja，次选 MinGW Makefiles
3. **Linux 服务器编译**：默认 Unix Makefiles，追求速度装 Ninja
4. **苹果开发**：固定 Xcode 后端
5. **CI 自动化编译**：一律用 Ninja，编译耗时最短

## 七、常见误区

1. **Toolchain 是编译器，Generator 是构建后端** Toolchain 决定用 `cl.exe/gcc`；Generator 决定用 Ninja/MSBuild/make 跑编译流程，两者互不冲突，可以自由组合。
2. 切换 Generator 必须**清空构建目录 /--fresh** 旧生成文件不兼容其他后端，直接切换会报错。
3. Ninja 不区分 Debug/Release 配置集 需要多配置时用 VS Generator，单配置构建（指定 CMAKE_BUILD_TYPE）用 Ninja。