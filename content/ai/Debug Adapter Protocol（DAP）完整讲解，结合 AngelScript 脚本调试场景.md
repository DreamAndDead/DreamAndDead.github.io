---
title: Debug Adapter Protocol（DAP）完整讲解，结合 AngelScript 脚本调试场景
---

# Debug Adapter Protocol（DAP）完整讲解，结合 AngelScript 脚本调试场景

## 一、一句话定义

**DAP（调试适配器协议）是一套基于 JSON 的标准化网络通信协议**，用来统一「编辑器（前端）」和「调试程序（后端，你的 C++ 引擎 + AngelScript 虚拟机）」之间的对话规则。
 简单分工：

1. **前端（客户端）**：VSCode、VS、JetBrains Rider 等编辑器，负责展示界面、按钮（断点、单步、继续、监视变量）；
2. **后端（调试适配器 / 服务端）**：运行在你的游戏引擎进程里，对接 AngelScript 的 `asIScriptEngine` 原生调试 API，执行真正的断点、读取变量、获取调用栈；
3. 两者通过 TCP 套接字 / 标准 stdio 收发 JSON 消息通信，**前端完全不用关心底层是什么语言（C++/AngelScript/Lua/Python）**，只认 DAP 协议。

## 二、诞生的核心目的：解决调试器碎片化

在 DAP 出现之前，每种语言、每种脚本都要单独做一套编辑器插件：

- C/C++ 用 GDB/LLDB 协议
- Lua 一套调试协议
- AngelScript 自有回调接口
- Java、C# 各自私有协议 编辑器要为每一种调试后端单独开发适配插件，工作量极大。

DAP 由微软为 VSCode 设计，核心目标：**一套协议通吃所有编程语言、脚本、虚拟机调试**。
 只要你的后端程序实现了 DAP 服务端，VSCode 原生就能直接调试，不需要为 AngelScript 写专属编辑器插件。

## 三、底层通信基础

1. **数据格式**：纯 JSON，每条消息固定包头长度格式：

```plaintext
Content-Length: xxx\r\n\r\n{json消息体}
```

2. **通信方式两种**
   1. **stdio 管道**：编辑器启动调试进程，通过标准输入输出收发消息（本地调试常用）；
   2. **TCP Socket**：引擎进程开启 TCP 端口作为服务端，VSCode 局域网远程连接（**游戏引擎远程调试主机 / 手机必用方案**），AngelScript 远程调试首选 TCP。
3. 通信模型：**请求 (Request) / 响应 (Response) + 事件 (Event) 推送**
   - 请求：VSCode 发指令（设置断点、单步步入、获取变量）
   - 响应：引擎执行完毕，返回结果数据
   - 事件：主动推送异步消息（命中断点、脚本异常、程序退出）

## 四、DAP 核心常用消息（AngelScript 调试高频用到）

### 1. 初始化流程

1. `initialize`：编辑器告诉适配器自身能力（支持断点、条件断点、监视等）
2. `launch / attach`
   - `launch`：由 VSCode 启动你的游戏引擎进程；
   - `attach`：附加到**已经正在运行的游戏进程**（游戏开着，再连上调试，自研引擎最常用）。

### 2. 断点控制（核心）

- `setBreakpoints`：下发断点列表（文件路径 + 行号），引擎 AS 虚拟机记录断点位置；
- 当脚本执行命中断点，后端主动推送 `stopped` 事件给 VSCode，界面自动暂停、高亮当前行。

### 3. 执行控制（单步操作）

VSCode 按钮对应 DAP 指令：

- `continue`：继续运行
- `next`：步过（Step Over）
- `stepIn`：步入（Step Into）
- `stepOut`：步出（Step Out） 引擎收到指令后，切换 AngelScript `asIScriptContext` 的单步执行模式。

### 4. 数据查看

- `stackTrace`：获取当前脚本调用堆栈（函数名、文件名、行号）；
- `scopes`：获取当前作用域（局部变量、全局变量、this 对象）；
- `variables`：读取变量名、类型、值，对应读取 AS 上下文 `GetVarName`、`GetVarAddress`。

### 5. 异常捕获

`setExceptionBreakpoints`：配置遇到脚本异常（空句柄、数组越界）时自动断下，对接 AS 的`ExceptionCallback`。

## 五、结合 AngelScript 的 DAP 整体架构（自研引擎实现逻辑）

整体三层结构：

```plaintext
VSCode(DAP客户端)  <--TCP网络-->  引擎内置DAP服务端(DAP解析层)  <--调用原生API-->  AngelScript asIScriptEngine
```

1. **第一层：VSCode**，通用 DAP 客户端，无需改动；
2. **第二层：自己在 C++ 引擎写 DAP 服务端** 负责解析 VSCode 发来的 DAP JSON 指令，翻译成调用 AS 原生调试接口：
   - 收到`setBreakpoints` → 记录文件行号断点，在 AS 的`LineCallback`行回调里判断命中；
   - 收到单步指令 → 控制`asIScriptContext`的步进模式；
   - 读取变量请求 → 调用`ctx->GetVarCount()`等接口取值，打包成 JSON 回传给 VSCode；
3. **第三层：AngelScript 原生虚拟机**，只需要开启`asIDebugger`回调，暴露调试能力。

## 六、DAP 的核心优势（为什么调试 AS 一定要用它）

1. **编辑器通用** 写完一套 DAP 服务端，VSCode、VS、Rider 全都能用，不用专门开发 AngelScript 编辑器插件。
2. **完美支持远程调试** TCP 架构可以做到：PC VSCode 调试 手机安卓、Switch、主机上运行的游戏进程，这是游戏开发刚需。
3. **功能完整对齐现代调试器** 原生支持普通断点、条件断点、命中次数断点、日志断点、变量监视、表达式求值、调用栈跳转，和调试 C++ 体验完全一致。
4. **解耦上层界面与底层虚拟机** 后续就算把脚本从 AngelScript 换成 Lua、QuickJS，**DAP 服务端架构不用改**，只需要替换底层虚拟机的 API 调用即可。

## 七、实现难度与现成方案

### 方案 1：从零简易实现（适合熟悉网络与 JSON）

只需要实现 TCP 收发、DAP 基础消息解析，对接 AS 的`asIDebugger`回调，小型引擎够用，只实现断点、单步、堆栈、变量核心功能。

### 方案 2：使用成熟开源 DAP 框架（推荐）

C++ 现成 DAP 库，封装好了协议解析，不用手动处理 JSON 包头：

- `cppdap`：C++ 标准 DAP 实现，轻量易用，绝大多数游戏引擎 DAP 调试的底层依赖； 只需要把 cppdap 的回调，绑定到 AngelScript 的调试 API 即可，大幅减少开发量。

### 方案 3：现成 AngelScript DAP 成品

开源项目 `as-dap`，是基于 cppdap 做好的 AngelScript 专用适配器，可以直接集成进 C++ 引擎，开箱即用。

## 八、DAP 和官方 asDebugger GUI 的区别

1. **asDebugger**：是 Windows 专属的桌面原生 GUI 程序，只能本地附加 Windows 进程调试，封闭平台、远程设备完全无法使用；
2. **DAP**：跨平台、支持 TCP 远程，Windows/Linux/Android/iOS/ 主机全平台通用，是工业化长线项目的标准方案，也是现在主流的选择。

## 九、简单对比：DAP 调试 vs 传统日志打印调试

| 方⁠式 | 优⁠点 | 缺⁠点 |
| --- | --- | --- |
| 日⁠志⁠打⁠印 | 实⁠现⁠最⁠简⁠单，零⁠架⁠构⁠成⁠本 | 无⁠法⁠暂⁠停⁠运⁠行，无⁠法⁠实⁠时⁠看⁠变⁠量，问⁠题⁠定⁠位⁠低⁠效，海⁠量⁠日⁠志⁠难⁠以⁠排⁠查 |
| DAP 可⁠视⁠化⁠断⁠点⁠调⁠试 | 随⁠时⁠暂⁠停、回⁠溯⁠堆⁠栈、实⁠时⁠查⁠看⁠所⁠有⁠变⁠量、条⁠件⁠断⁠点⁠精⁠准⁠定⁠位⁠问⁠题 | 需⁠要⁠前⁠期⁠集⁠成 DAP 适⁠配⁠器，少⁠量⁠开⁠发⁠工⁠作⁠量 |

简单总结：**日志用来快速临时验证，DAP 断点调试是 AngelScript 正式开发、复杂逻辑 BUG 排查的标准方案**。