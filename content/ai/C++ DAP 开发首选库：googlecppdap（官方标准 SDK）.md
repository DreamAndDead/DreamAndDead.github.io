---
title: C++ DAP 开发首选库：**google/cppdap**（官方标准 SDK）
---

# C++ DAP 开发首选库：**google/cppdap**（官方标准 SDK）

微软 DAP 官网唯一收录的 C++ 专用 DAP 库，**业界标准、完整实现全套 DAP 协议、类型安全、跨平台**，专门用来从零开发自定义 Debug Adapter，完美适配你给 **Angelscript 引擎内嵌 DAP TCP 服务** 的需求，没有第二个同级替代品。

## 一、cppdap 核心介绍

仓库：[https://github.com/google/cppdap](https://link.wtturl.cn/?target=https%3A%2F%2Fgithub.com%2Fgoogle%2Fcppdap&scene=im&aid=497858&lang=zh)

### 核心优势

1. **完整覆盖全量 DAP 协议规范** 内置所有 Request/Response/Event 强类型 C++ 结构体（initialize、attach、setBreakpoints、stackTrace、variables、continue、stepIn 等），**编译期类型校验**，不会手写 JSON 字段写错、漏字段，彻底规避协议格式错误。
2. 自带底层报文封装 自动处理 DAP 标准 `Content-Length` 头、JSON 序列化 / 反序列化、消息序列号 seq 配对、分包粘包解析，**不用自己写底层协议解析逻辑**。
3. 双模式：同时支持 **DAP Server（TCP，引擎内嵌直连）、DAP Client（STDIO 独立 Adapter）**，刚好对应你的两种架构方案。
4. 依赖极简 默认绑定 `nlohmann/json`，也可切换 RapidJson/JsonCpp；C++11 最低标准，Windows/Linux/macOS 全平台，CMake 构建，极易集成到游戏引擎项目。
5. Apache 2.0 开源协议，**商用引擎完全免费无版权风险**。

### 核心能力

- 服务端模式（你要的方案）：启动 TCP Server，接收 nvim-dap 连接，处理客户端请求
- 客户端模式：作为独立 Adapter，TCP 连接游戏引擎私有调试接口
- 支持自定义扩展私有 DAP 消息，适配 Angelscript 引擎私有调试指令
- 完整支持变量引用 ID、多线程、条件断点、异常断点、悬浮求值等高级特性

## 二、环境快速集成

### 1. 安装方式（任选其一）

#### 方式 1：vcpkg 一键安装（Windows 游戏开发首选）

```bash
vcpkg install cppdap
```

#### 方式 2：CMake 子模块引入项目

```bash
git submodule add https://github.com/google/cppdap thirdparty/cppdap
git submodule update --init
```

#### 方式 3：MSYS2（Windows）

```bash
pacman -S mingw-w64-x86_64-cppdap
```

### 2. CMake 引入配置

```cmake
find_package(cppdap CONFIG REQUIRED)
target_link_libraries(你的引擎项目 PRIVATE cppdap::cppdap)
```

## 三、最简核心代码示例（TCP DAP Server，内嵌到 Angelscript 引擎）

实现**引擎内部直接开启 DAP TCP 服务**，不需要额外独立 Adapter 进程，对接 nvim-dap。

```cpp
#include <dap/server.h>
#include <dap/protocol.h>
#include <dap/transport.h>
#include <iostream>

// 1. 实现DAP请求回调处理类，对接Angelscript asIDebugger虚拟机API
class AngelscriptDapHandler : public dap::Session::Handler {
public:
    // 初始化握手
    void onInitialize(dap::InitializeRequest& req, dap::InitializeResponse& res) override {
        res.supportsConfigurationDoneRequest = true;
        res.supportsEvaluateForHovers = true;
        res.supportsSetVariable = true;
    }

    // attach附加调试（游戏进程常驻首选）
    void onAttach(dap::AttachRequest& req, dap::AttachResponse& res) override {
        // 此处绑定Angelscript虚拟机调试上下文 asIDebugger
        std::cout << "nvim-dap 已附加引擎AS调试进程" << std::endl;
    }

    // 设置断点
    void onSetBreakpoints(dap::SetBreakpointsRequest& req, dap::SetBreakpointsResponse& res) override {
        for (auto& bp : req.arguments.breakpoints) {
            // 调用Angelscript原生接口添加断点
            // asDebugger->AddBreakpoint(文件路径, bp.line);
            dap::Breakpoint result;
            result.line = bp.line;
            result.verified = true;
            res.body.breakpoints.push_back(result);
        }
    }

    // 继续运行
    void onContinue(dap::ContinueRequest& req, dap::ContinueResponse& res) override {
        // asDebugger->SetDebugAction(AS_DEBUG_CONTINUE);
    }

    // 单步跳过 next
    void onNext(dap::NextRequest& req, dap::NextResponse& res) override {
        // asDebugger->SetDebugAction(AS_DEBUG_STEP_OVER);
    }

    // 获取调用堆栈
    void onStackTrace(dap::StackTraceRequest& req, dap::StackTraceResponse& res) override {
        // 读取Angelscript调用栈，填充stackFrames
        // res.body.stackFrames = 虚拟机栈帧数据;
    }

    // 命中断点，主动推送stopped事件给nvim-dap
    void SendBreakStopEvent(dap::Session* session, int threadId) {
        dap::StoppedEvent event;
        event.body.reason = "breakpoint";
        event.body.threadId = threadId;
        session->send(event);
    }
};

int main() {
    // 2. 创建TCP Transport，开启本地 127.0.0.1:9090 端口
    auto transport = dap::tcpServerTransport("127.0.0.1", 9090);
    AngelscriptDapHandler handler;
    dap::Session session(&handler);

    // 3. 绑定TCP传输，启动DAP服务
    session.start(std::move(transport));
    session.wait(); // 阻塞等待调试会话

    return 0;
}
```

## 四、nvim-dap 配套配置（直连引擎 TCP DAP 服务）

```lua
local dap = require("dap")
-- 适配器类型为server，直连引擎内置TCP DAP服务
dap.adapters.angelscript = {
  type = "server",
  host = "127.0.0.1",
  port = 9090,
}
-- 调试配置：attach附加运行中的游戏进程
dap.configurations.angelscript = {
  {
    name = "附加Angelscript游戏进程",
    type = "angelscript",
    request = "attach",
  }
}
```

启动游戏引擎（内置 cppdap TCP 服务），nvim-dap 直接连接，完整断点、单步、变量查看。

## 五、两种架构落地方案（对应你的需求）

### 方案 A：引擎内嵌 cppdap（无独立 Adapter，推荐长期自研引擎）

1. 引擎 C++ 代码集成 cppdap，主线程启动 TCP DAP Server；
2. `AngelscriptDapHandler` 内部直接调用 `asIDebugger` 原生 C 接口；
3. 断点命中时，主动调用 `SendBreakStopEvent` 推送 DAP stopped 事件；
4. nvim-dap TCP 直连引擎，**零中间进程**，性能最优。

### 方案 B：独立 Adapter 程序（快速原型）

用 cppdap 做**DAP Client**（STDIO 模式被 nvim-dap 拉起），Adapter 内部 TCP 连接游戏引擎的私有简易调试协议，做协议中转翻译。
 适合快速验证，不需要修改引擎主程序。

## 六、备选小众 C++ DAP 库（不推荐主力使用）

1. **lldb-mi /liblldb 封装** 仅限调试原生 C/C++ 程序，**无法对接 Angelscript 虚拟机**，完全不适合脚本引擎调试。
2. 自研 JSON+Socket 手写解析 工作量极大，协议坑极多，仅适合极简玩具 demo，正式项目绝对不要手写 DAP 底层。

## 七、开发避坑要点

1. **路径映射必须实现** cppdap 拿到的是本地磁盘绝对路径，引擎内是脚本相对路径，在`onSetBreakpoints`中做路径转换，否则断点无法命中。
2. 虚拟机线程安全 Angelscript 脚本执行线程与 DAP 解析线程分离，访问`asIScriptContext`必须加线程锁，防止上下文竞争崩溃。
3. 事件异步推送`stopped`、`exited`等事件需要在脚本断点回调线程主动调用`session->send()`发送，不能阻塞主线程。
4. JSON 库兼容 游戏项目已有 nlohmann/json 则直接复用，避免多 JSON 库冲突。

## 总结

1. **cppdap 是 C++ 开发自定义 DAP Adapter 唯一标准首选库**，谷歌官方维护，协议完整可靠，省去 90% 的底层协议开发工作量。
2. 针对你的 Angelscript 引擎，最优路线：**引擎内部集成 cppdap 实现 TCP DAP Server 直连 nvim-dap**，彻底去掉中间独立 Adapter。
3. 开发顺序：先实现核心命令（initialize/attach/ 断点 / 单步 / 堆栈 / 变量），再逐步完善条件断点、变量修改、求值等高级功能。