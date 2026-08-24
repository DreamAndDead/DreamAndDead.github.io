---
title: 结论先说：**理论完全可行，本质就是把 Debug Adapter 直接内嵌到你的 Angelscript 程序 / 引擎内部，省略独立的 Adapter 进程**。
---

# 结论先说：**理论完全可行，本质就是把 Debug Adapter 直接内嵌到你的 Angelscript 程序 / 引擎内部，省略独立的 Adapter 进程**。

但有明确的实现前提、优缺点、坑点，我帮你彻底讲清边界。

## 一、本质原理回顾

标准架构：

```plaintext
nvim-dap <--(STDIO/TCP DAP协议)--> 独立Adapter进程 <--(私有协议)--> 游戏AS引擎
```

你想要的架构：

```plaintext
nvim-dap <--(STDIO/TCP 原生DAP协议直连)--> Angelscript游戏程序
```

引擎程序**自身直接实现完整 DAP 协议收发、解析、应答**，不再额外中转程序。
 只要你的游戏进程**严格完整实现 DAP 协议**，nvim-dap 完全可以直接连接，不需要中间 Adapter。

## 二、两种通信方式分别能不能做

### 1. TCP Socket 方式：非常适合内嵌实现（推荐）

完全没问题，也是游戏脚本调试最主流的方案：

1. 游戏启动时，内部开启 TCP Server（`127.0.0.1:9090`）；
2. Socket 收发直接处理**标准 DAP JSON 报文（Content-Length 头部格式）**；
3. 收到 `setBreakpoint/next/continue/stackTrace` 等 DAP 请求，直接调用引擎内部 Angelscript 虚拟机 `asIDebugger` 原生接口执行逻辑；
4. 把结果封装成标准 DAP Response 返回 Socket；
5. 命中断点时，主动通过 Socket 向外推送 DAP `stopped` Event 事件。

nvim-dap 配置直接指向引擎 TCP 地址，`type = "server"` 模式：

```lua
dap.adapters.angelscript = {
  type = "server",
  host = "127.0.0.1",
  port = 9090,
}
```

直接连接游戏进程，**零额外 Adapter 程序**。

### 2. STDIO 标准管道方式：几乎不适合游戏程序

STDIO 模式是：nvim-dap **fork/exec 拉起你的程序作为子进程**，通过进程自带的 stdin/stdout 管道通信。
 限制极大：

1. 游戏引擎一般是图形窗口程序，Windows 子进程控制台 STDIO 容易失效；
2. 游戏自带日志会疯狂刷屏 stdout，直接污染 DAP 的协议报文；
3. 游戏一般都是长期运行进程，大多是 ** 附加 (attach)** 调试，很少用 launch 拉起，天然不适合 STDIO。

所以直连方案一律用 **TCP**。

## 三、“省去 Adapter”，你实际要自己承担 Adapter 的全部工作

原来独立 Adapter 干的所有事，现在全部要写进引擎代码里：

1. **严格实现完整 DAP 报文解析** 必须严格遵守 `Content-Length\r\n\r\n{json}` 格式，解析 `seq`、`type(request/response/event)`、command 字段，序列号一一对应，报文分包、粘包处理。
2. **命令完整实现** initialize、attach、setBreakpoints、continue、next/stepIn/stepOut、stackTrace、scopes、variables、disconnect 等核心命令一个不能少。
3. **异步事件主动推送** 断点暂停、线程退出，需要主动向 Socket 发送 DAP Event，不是被动应答。
4. **路径映射、源码匹配** 引擎内脚本路径 ↔ 本地磁盘绝对路径转换，否则断点红点无效。
5. **会话状态管理** 断点列表缓存、线程管理、调试暂停状态、多客户端连接保护。

> 简单说：**只是把 Adapter 的代码搬进游戏内部，工作量一点没少，只是少了一个 exe 进程。**

## 四、核心优势（直连方案的好处）

1. **架构精简** 少一个中间进程，没有进程间二次转发，延迟更低，调试响应更快。
2. **内存、线程调度更可控** 直接在引擎主线程 / 脚本线程操作 AS 虚拟机调试上下文，不需要跨进程传递上下文。
3. 便于深度耦合 可以直接读取引擎内部数据、自定义全局对象，不需要私有协议中转。

## 五、必须面对的硬坑（决定好不好落地）

### 1. DAP 协议体量不小，不是简单收发 JSON

完整 DAP 规范命令几十个，还要处理：

- 变量层级引用（`variablesReference` 引用 ID 机制）
- 多线程、栈帧处理
- 条件断点、日志断点、异常捕获
- 表达式求值 hover、运行时修改变量 只做最简断点 + 单步可以快速跑通，想要完整 VSCode/nvim-dap 体验，开发工作量不小。

### 2. 协议粘包、分包极易出错

TCP 是字节流，会出现半包、粘包。
 必须手动实现**流式缓冲区解析**：循环读取字节，先解析 `Content-Length`，再按长度截取完整 JSON，新手非常容易在这里翻车。
 而现成 Adapter 库都自带成熟的解析逻辑。

### 3. 调试状态和游戏主线程阻塞问题

Angelscript 命中断点后，虚拟机必须暂停。

- 如果 DAP 解析逻辑和脚本执行**同主线程**：收到下一步指令才能继续游戏，完美可控；
- 如果放在异步线程，极易出现线程竞争、上下文错乱、虚拟机访问越界。

### 4. 兼容性问题

nvim-dap 严格校验 DAP 返回字段，**少一个字段、类型不对、seq 序列号错乱，直接报错断开**。自己手写协议很容易细节不符合规范，而成熟 Adapter 都是长期验证过的。

### 5. 无法复用现成生态

后续想对接 VSCode、其他编辑器，同样要保证 DAP 实现完整；如果用通用 Adapter，只需要写私有协议对接引擎即可。

## 六、两种方案选型对比

| 方⁠案 | 实⁠现⁠难⁠度 | 适⁠用⁠场⁠景 |
| --- | --- | --- |
| 内⁠嵌⁠直⁠连 DAP（无⁠独⁠立 Adapter） | 高，需⁠吃⁠透⁠完⁠整 DAP 协⁠议 + TCP 流⁠式⁠解⁠析 | 自⁠研⁠引⁠擎⁠长⁠期⁠维⁠护、深⁠度⁠定⁠制⁠调⁠试⁠功⁠能、性⁠能⁠要⁠求⁠极⁠高 |
| 独⁠立 Adapter 中⁠间⁠层 | 低，Adapter 实⁠现⁠标⁠准 DAP，引⁠擎⁠只⁠需⁠要⁠自⁠定⁠义⁠简⁠易⁠私⁠有 TCP 协⁠议 | 快⁠速⁠开⁠发、原⁠型⁠验⁠证、不⁠想⁠啃⁠完⁠整 DAP 规⁠范、后⁠续⁠多⁠编⁠辑⁠器⁠兼⁠容 |

## 七、最简落地建议（针对你的 Angelscript）

1. **原型验证阶段：先用独立 Python Adapter 快速跑通流程** 先把 `asIDebugger` 调试接口、引擎 TCP 私有通信打通，熟悉整套调试逻辑。
2. **稳定后，再把 DAP 协议逻辑移植进引擎内部，移除独立 Adapter** 把 Python 端的 DAP 解析、命令路由逻辑 C++ 重写嵌入引擎 TCP 服务，完成直连。
3. 最低实现子集（能在 nvim-dap 正常断点调试），只需要实现这些命令：`initialize`、`attach`、`setBreakpoints`、`continue`、`next`、`stepIn`、`stepOut`、`stackTrace`、`scopes`、`variables`、`disconnect`，外加 `stopped` 事件推送。

## 八、总结

1. **技术上完全可行，引擎程序可以直接实现 DAP TCP 服务，彻底不需要独立 Debug Adapter 进程**；
2. Adapter 的职责不会消失，只是代码被内置到你的程序里，工作量并没有减少；
3. TCP 是唯一合适的通信方式，STDIO 模式不适合游戏程序；
4. 短期快速开发建议用独立 Adapter；长期自研引擎定制调试，内嵌直连 DAP 是更优的最终方案。