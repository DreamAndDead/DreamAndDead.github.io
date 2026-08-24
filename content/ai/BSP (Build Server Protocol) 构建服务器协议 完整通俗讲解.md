---
title: BSP (Build Server Protocol) 构建服务器协议 完整通俗讲解
---

# BSP (Build Server Protocol) 构建服务器协议 完整通俗讲解

## 一、一句话核心定义

**BSP 是一套基于 JSON-RPC 2.0 的标准化通信协议，定位是「构建界的 LSP」**

- **LSP**：统一「编辑器 ↔ 编程语言」，解决 ** 写代码（补全、跳转、报错）** 的静态分析问题build-server-protocol.github.io。
- **BSP**：统一「编辑器 / LSP 语言服务 ↔ 构建工具 (CMake/Ninja/Make/Bazel)」，解决**编译、工程结构、依赖、运行、调试**的工程构建问题，是 LSP 的黄金配套协议。

底层和 LSP 完全同源，都是 JSON-RPC 双向通信，分为**客户端（Neovim/clangd）**、**服务端（构建程序）**。

![](data:image/svg+xml,%3csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20version=%271.1%27%20width=%27256%27%20height=%27192%27/%3e)![image](https://p26-flow-imagex-sign.byteimg.com/labis/image/9eb8ceb949b955275b93b968bddb68b8~tplv-a9rns2rl98-pc_smart_face_crop-v1:512:384.image?lk3s=8e244e95&rcl=202606231627426495562DE572872DBD74&rrcfp=cee388b0&x-expires=2097563276&x-signature=n303ZyjcmRoCCY6D%2FKXYeIo59d8%3D)

BSP架构图

![](data:image/svg+xml,%3csvg%20xmlns=%27http://www.w3.org/2000/svg%27%20version=%271.1%27%20width=%27256%27%20height=%27192%27/%3e)![image](https://p3-flow-imagex-sign.byteimg.com/labis/image/0f3b44d7dacd65dd4e1ca81e3ba02fa7~tplv-a9rns2rl98-pc_smart_face_crop-v1:485:364.image?lk3s=8e244e95&rcl=202606231627426495562DE572872DBD74&rrcfp=cee388b0&x-expires=2097563276&x-signature=oySSCLjO35VdFgt4TEeo9gicwD0%3D)

LSP+BSP互补

## 二、解决什么核心痛点（C++/CMake 开发必懂）

### 老式方案的弊端（不用 BSP）

C++ 的`clangd` LSP 想要正常识别头文件、宏定义、第三方库路径，必须读取静态文件 `compile_commands.json`：

1. 需要手动执行 CMake 命令生成该文件，修改 CMake 配置、新增源文件后，必须手动重新生成；
2. 多编译配置（Debug/Release）、多子工程、动态生成代码时，静态文件极易滞后、失效；
3. 每一款构建工具（CMake/Make/Ninja），都要单独写一套逻辑适配 LSP，耦合严重。

### BSP 的解决方案

BSP 启动**常驻的构建后台进程（Build Server）**，全程接管工程构建信息：

1. 实时动态向`clangd`推送**实时编译参数、头文件路径、宏、目标工程、依赖关系**，不再依赖静态 json 文件；
2. 构建工具只需要实现一套 BSP 服务，所有编辑器（Neovim/VSCode/IDEA）、所有 LSP 服务通用；
3. 编辑器内一键编译、查看编译报错、执行测试、启动调试，全部走标准 BSP 接口，一套命令适配所有构建工具。

## 三、BSP 完整三层架构

```plaintext
Neovim（BSP客户端）
    ↓ BSP标准JSON-RPC协议
Build Server（BSP服务端，CMake/Ninja等构建程序）
    ↓ 底层调用原生构建逻辑
工程源码/编译链
```

### 两大核心角色

1. **BSP Client 客户端** Neovim、clangd 语言服务器，发起请求：获取工程目标、执行编译、获取编译诊断、获取运行参数。
2. **BSP Server 服务端** 构建工具开启的常驻后台进程，解析 CMakeLists.txt，维护完整工程树、编译规则、依赖图谱，响应客户端所有请求。

## 四、BSP 核心能干哪些事

1. **实时同步编译配置（最核心）** 动态给`clangd`提供完整编译命令、include 目录、预定义宏，LSP 补全、头文件跳转永远准确，修改 CMake 配置即时生效。
2. **编辑器内一键构建** Neovim 内直接发起编译、增量编译、清理工程，实时推送编译进度、编译错误（编译报错直接在代码行标红）。
3. **工程目标管理** 自动识别项目所有可执行程序、静态库、测试程序，一键选择编译目标、运行程序。
4. **联动 DAP 调试** BSP 可以直接向 DAP 调试器传递**可执行文件路径、工作目录、启动参数**，打通「编译完成 → 一键启动调试」完整流程。
5. **支持动态代码生成** 游戏引擎 CMake 动态生成代码时，BSP 实时通知 LSP 刷新文件索引，不会出现新生成的头文件找不到的问题。

## 五、LSP / BSP / DAP 三者清晰分工（结合你的 Angelscript/C++ 开发）

| 协⁠议 | 负⁠责⁠阶⁠段 | 核⁠心⁠工⁠作 |
| --- | --- | --- |
| **LSP** | 编⁠码⁠静⁠态⁠阶⁠段 | 代⁠码⁠语⁠法⁠分⁠析、补⁠全、跳⁠转、重⁠构、静⁠态⁠报⁠错 |
| **BSP** | 工⁠程⁠构⁠建⁠阶⁠段 | 工⁠程⁠结⁠构、编⁠译⁠规⁠则、依⁠赖⁠解⁠析、执⁠行⁠编⁠译、输⁠出⁠程⁠序 |
| **DAP** | 程⁠序⁠运⁠行⁠阶⁠段 | 运⁠行⁠时⁠断⁠点、单⁠步⁠调⁠试、查⁠看⁠运⁠行⁠变⁠量、堆⁠栈 |

完整开发闭环：
**LSP 写代码 → BSP 编译出 exe → DAP 调试运行程序**。

## 六、CMake 项目 BSP 落地方式（Neovim）

### 1. CMake 官方 BSP 实现：cmake-bsp

CMake 原生支持 BSP 协议，可以直接启动 BSP 服务端，对接`bsp.nvim`插件。

### 2. Neovim 客户端插件：`nanotee/bsp.nvim`

作用：

- 作为 BSP 客户端连接 CMake 的 BSP 服务；
- 自动对接`clangd`，自动把 BSP 获取的编译参数注入 LSP；
- 提供编辑器命令：`BspStart`启动服务、`BspCompile`编译、`BspTargets`查看所有编译目标。

## 七、BSP 和传统 `compile_commands.json` 的区别

| 特⁠性 | 静⁠态 compile_commands.json | BSP 动⁠态⁠构⁠建⁠协⁠议 |
| --- | --- | --- |
| 更⁠新⁠方⁠式 | 手⁠动 CMake 生⁠成，文⁠件⁠静⁠态，修⁠改⁠配⁠置⁠必⁠须⁠重⁠新⁠生⁠成 | 常⁠驻⁠进⁠程⁠实⁠时⁠监⁠听 CMake 改⁠动，自⁠动⁠刷⁠新⁠参⁠数 |
| 多⁠配⁠置⁠支⁠持 | 切⁠换 Debug/Release 需⁠要⁠重⁠新⁠生⁠成⁠多⁠份⁠文⁠件，繁⁠琐 | 原⁠生⁠支⁠持⁠多⁠编⁠译⁠配⁠置，一⁠键⁠切⁠换 |
| 动⁠态⁠代⁠码⁠生⁠成 | 无⁠法⁠实⁠时⁠感⁠知，极⁠易⁠索⁠引⁠失⁠效 | 实⁠时⁠同⁠步⁠生⁠成⁠文⁠件，LSP 立⁠刻⁠识⁠别 |
| 编⁠译⁠联⁠动 | 和⁠编⁠辑⁠器⁠编⁠译⁠完⁠全⁠割⁠裂 | 一⁠体⁠打⁠通，编⁠译⁠报⁠错⁠实⁠时⁠同⁠步⁠到⁠编⁠辑⁠器 |
| 适⁠用⁠场⁠景 | 小⁠型⁠简⁠单⁠项⁠目⁠够⁠用 | 大⁠型⁠游⁠戏⁠引⁠擎 CMake 工⁠程、多⁠子⁠项⁠目⁠必⁠备 |

## 八、适用场景 & 什么时候需要用 BSP

### ✅ 强烈推荐使用（你的游戏引擎项目完美契合）

1. 大型 C++ CMake 引擎项目，多模块、第三方库繁多、头文件层级复杂；
2. 工程存在代码自动生成、自定义编译宏、多编译配置；
3. 需要 LSP 精准解析引擎内部头文件、SDK 路径，解决 clangd 找不到头文件的常见问题；
4. 想要在 Neovim 内一体化完成：编码→编译→运行→调试。

### ❌ 小型简单项目可以不用

单文件 C/C++、简易 Lua 项目，手动生成`compile_commands.json`完全够用，没必要额外部署 BSP。

## 九、补充常见误区

1. **BSP 不能替代 LSP** BSP 只管**构建数据供给**，不会做代码补全、语法分析，必须配合`clangd`这类 LSP 语言服务器一起工作。
2. BSP 不是只能用于 C++ Java (Gradle/Maven)、Scala、Rust 等构建系统都原生支持 BSP，是跨语言通用构建标准。
3. Windows 游戏引擎 CMake 完全兼容`cmake-bsp`跨平台，Windows 下可以完美配合你的 Angelscript 引擎 C++ 工程。