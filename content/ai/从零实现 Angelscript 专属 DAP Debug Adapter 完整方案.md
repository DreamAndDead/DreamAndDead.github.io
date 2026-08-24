---
title: 从零实现 Angelscript 专属 DAP Debug Adapter 完整方案
---

# 从零实现 Angelscript 专属 DAP Debug Adapter 完整方案

整体架构：**DAP 协议解析层（标准 JSON） + 通信层 (STDIO/TCP) + Angelscript VM 调试桥接层**。
 DAP Adapter 本质是一个独立程序，可以用 Lua/Python/C++ 开发，下面给完整架构、协议规范、分层实现步骤、对接 Angelscript 虚拟机调试 API，最后对接 nvim-dap。

## 前置知识

1. Angelscript 原生自带一套**内置调试回调接口** `asIDebugger`，引擎侧可以注册调试钩子：断点、单步、获取堆栈、读取变量、线程控制，这是底层能力来源。
2. DAP 协议分为**请求 (Request)、响应 (Response)、事件 (Event)**，基于 JSON，底层传输二选一：
   - **STDIO（推荐本地调试）**：nvim-dap 启动 Adapter 子进程，通过标准输入输出通信，配置最简单。
   - **TCP Socket（游戏进程附加必备）**：游戏引擎内置 Angelscript 虚拟机开启 TCP 调试服务，Adapter 作为客户端连接引擎端口，适合附加运行中的游戏进程。
3. 开发选型建议：
   - 快速原型验证：**Python**，内置 json、socket、stdio 库，开发最快。
   - 正式嵌入引擎：**C++**，直接集成到游戏引擎，原生对接 Angelscript C API。

下面以 **Python 快速开发原型 DAP 适配器** 为例，完整流程。

## 一、整体分层架构（三层）

```plaintext
nvim-dap (客户端)
   ↓ DAP标准JSON消息 (STDIO/TCP)
【层1：DAP协议解析层】 解析/封装标准DAP报文，处理seq、command、event
   ↓ 指令中转
【层2：Angelscript VM 桥接层】
   DAP指令 ↔ 调用 Angelscript asIDebugger 原生调试接口
   ↓
【底层】游戏Angelscript虚拟机（断点、线程、变量、堆栈）
```

## 二、第一步：熟悉 Angelscript 原生调试 C API（核心）

Angelscript 官方 C++ SDK 的 `asIDebugger` 接口，所有调试能力全部来自这套接口，引擎必须暴露实现。
 核心接口清单：

```cpp
// 引擎注册调试器回调
class asIDebugger
{
    // 断点命中回调
    virtual void OnBreakpoint(asIScriptContext *ctx, asIScriptFunction *func, int line) = 0;
    // 单步控制：stepInto / stepOver / stepOut / continue
    virtual eDebugAction GetDebugAction() = 0;
    virtual void SetDebugAction(eDebugAction action) = 0;

    // 堆栈、线程
    virtual int GetCallstackDepth() = 0;
    virtual asIScriptFunction* GetFunction(int stackIndex) = 0;
    virtual int GetCurrentLine(int stackIndex) = 0;

    // 变量读取（局部/全局）
    virtual bool GetVariable(int stackIdx, const char* name, asIScriptGeneric* outVal) = 0;
    virtual bool SetVariable(int stackIdx, const char* name, void* value) = 0;

    // 断点管理
    virtual int AddBreakpoint(const char* file, int line) = 0;
    virtual void RemoveBreakpoint(int id) = 0;
};
```

### 两种对接模式

1. **模式 A：引擎内置 TCP 调试服务（最常用）** 游戏启动时，Angelscript VM 开启 TCP 端口（如 `127.0.0.1:9090`），引擎封装一套简易二进制 / JSON 私有协议，把上面的 `asIDebugger` 能力对外暴露。我们的 DAP Adapter 作为 TCP 客户端，连接引擎端口，收发引擎私有指令。
2. **模式 B：进程内嵌入** C++ 把 Adapter 直接编译进引擎进程，直接函数调用 `asIDebugger`，不走网络。

## 三、第二步：DAP 协议核心规则（必须严格实现）

### 1. DAP 消息标准格式（Content-Length 头 + JSON 体）

每条消息固定格式，STDIO/TCP 都遵循：

```plaintext
Content-Length: {数字}\r\n\r\n
{标准JSON字符串}
```

示例：

```plaintext
Content-Length: 123

{"seq":1,"type":"request","command":"initialize","arguments":{"clientID":"nvim-dap"}}
```

- `seq`：序列号，请求与响应一一对应。
- `type`：`request` 请求 / `response` 响应 / `event` 事件（断点暂停、线程退出等主动推送）。

### 必须实现的**最小核心 DAP 命令**（实现基础调试必备）

| DAP Command | 作⁠用 | 对⁠应 Angelscript 底⁠层⁠能⁠力 |
| --- | --- | --- |
| initialize | 初⁠始⁠化⁠会⁠话⁠握⁠手 | 建⁠立⁠与⁠游⁠戏⁠引⁠擎 TCP 连⁠接 |
| launch / attach | 启⁠动⁠程⁠序 / 附⁠加⁠到⁠运⁠行⁠进⁠程 | 新⁠建⁠脚⁠本⁠进⁠程 / 连⁠接⁠游⁠戏 VM 端⁠口 |
| setBreakpoints | 设⁠置⁠行⁠断⁠点 | 调⁠用⁠引⁠擎⁠接⁠口 AddBreakpoint |
| continue | 继⁠续⁠运⁠行 | SetDebugAction(continue) |
| next | 单⁠步⁠跳⁠过 stepOver | 单⁠步⁠到⁠下⁠一⁠行，不⁠进⁠函⁠数 |
| stepIn | 单⁠步⁠进⁠入 stepInto | 进⁠入⁠当⁠前⁠函⁠数⁠内⁠部 |
| stepOut | 单⁠步⁠跳⁠出 stepOut | 返⁠回⁠上⁠层⁠调⁠用⁠栈 |
| scopes | 获⁠取⁠当⁠前⁠作⁠用⁠域（局⁠部 / 全⁠局） | 读⁠取⁠当⁠前⁠栈⁠帧⁠环⁠境 |
| variables | 获⁠取⁠变⁠量⁠列⁠表⁠与⁠值 | GetVariable 读⁠取⁠脚⁠本⁠变⁠量 |
| stackTrace | 获⁠取⁠调⁠用⁠堆⁠栈 | GetCallstackDepth + 遍⁠历⁠栈⁠帧 |
| disconnect | 断⁠开⁠调⁠试⁠会⁠话 | 关⁠闭 TCP 连⁠接，恢⁠复 VM 运⁠行 |

### 主动事件 Event（引擎主动推送给 nvim-dap）

1. `stopped`：命中断点、单步完成，必须告诉前端暂停位置、线程 ID、暂停原因。
2. `terminated`：脚本进程结束。

## 四、第三步：Python 快速实现最简 Angelscript DAP Adapter 原型

文件命名 `as_dap_adapter.py`，采用 **STDIO 通信（对接 nvim-dap） + TCP 客户端（对接游戏引擎 Angelscript TCP 调试端口）**。

### 完整代码结构

```python
import sys
import json
import socket

# ===================== 配置：游戏引擎Angelscript TCP调试服务地址 =====================
ENGINE_HOST = "127.0.0.1"
ENGINE_PORT = 9090
engine_sock: socket.socket = None  # 连接游戏引擎的Socket
seq_id = 1

# ===================== 1. STDIO 底层读写封装（与nvim-dap通信） =====================
def read_stdio_message():
    """从标准输入读取DAP完整消息"""
    headers = {}
    while True:
        line = sys.stdin.readline()
        line = line.strip()
        if not line:
            break
        k, v = line.split(":", 1)
        headers[k.strip()] = v.strip()
    length = int(headers["Content-Length"])
    body = sys.stdin.read(length)
    return json.loads(body)

def write_stdio_message(msg: dict):
    """向标准输出发送DAP响应消息"""
    payload = json.dumps(msg)
    content = f"Content-Length: {len(payload)}\r\n\r\n{payload}"
    sys.stdout.write(content)
    sys.stdout.flush()

# ===================== 2. 与游戏引擎Angelscript TCP通信封装 =====================
def connect_engine():
    global engine_sock
    engine_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    engine_sock.connect((ENGINE_HOST, ENGINE_PORT))

def send_engine_cmd(cmd: dict) -> dict:
    # 向游戏引擎发送私有调试指令（格式由引擎约定）
    engine_sock.send(json.dumps(cmd).encode("utf8") + b"\n")
    data = engine_sock.recv(4096)
    return json.loads(data.decode("utf8"))

# ===================== 3. DAP 命令路由处理核心逻辑 =====================
def handle_request(req: dict):
    global seq_id
    resp = {
        "seq": seq_id,
        "type": "response",
        "request_seq": req["seq"],
        "command": req["command"],
        "success": True,
        "body": {}
    }
    seq_id += 1
    cmd = req["command"]

    # 1. 初始化握手
    if cmd == "initialize":
        resp["body"] = {
            "supportsConfigurationDoneRequest": True,
            "supportsSetVariable": True,
            "supportsEvaluateForHovers": True
        }

    # 2. 附加到正在运行的游戏进程（Angelscript常用）
    elif cmd == "attach":
        connect_engine()

    # 3. 设置断点
    elif cmd == "setBreakpoints":
        args = req["arguments"]
        file = args["source"]["path"]
        lines = [bp["line"] for bp in args["breakpoints"]]
        # 调用引擎接口批量添加断点
        send_engine_cmd({"cmd": "set_bp", "file": file, "lines": lines})

    # 4. 继续运行
    elif cmd == "continue":
        send_engine_cmd({"cmd": "action", "action": "continue"})

    # 5. 单步跳过 next
    elif cmd == "next":
        send_engine_cmd({"cmd": "action", "action": "step_over"})

    # 6. 获取堆栈
    elif cmd == "stackTrace":
        res = send_engine_cmd({"cmd": "get_stack"})
        resp["body"]["stackFrames"] = res["stackFrames"]

    # 7. 获取变量
    elif cmd == "variables":
        res = send_engine_cmd({"cmd": "get_vars", "scopeId": req["arguments"]["variablesReference"]})
        resp["body"]["variables"] = res["variables"]

    # 断开连接
    elif cmd == "disconnect":
        engine_sock.close()

    write_stdio_message(resp)

# ===================== 4. 后台线程监听引擎主动事件（断点暂停事件） =====================
def engine_event_listener():
    import threading
    def loop():
        while True:
            try:
                data = engine_sock.recv(1024)
                event = json.loads(data.decode())
                # 引擎推送：命中断点暂停，发送DAP stopped事件给nvim-dap
                if event["type"] == "break_hit":
                    dap_event = {
                        "seq": seq_id,
                        "type": "event",
                        "event": "stopped",
                        "body": {
                            "reason": "breakpoint",
                            "threadId": event["threadId"]
                        }
                    }
                    write_stdio_message(dap_event)
            except:
                pass
    threading.Thread(target=loop, daemon=True).start()

# ===================== 主循环 =====================
def main():
    while True:
        req = read_stdio_message()
        handle_request(req)
        # 引擎连接成功后启动事件监听
        if req["command"] == "attach":
            engine_event_listener()

if __name__ == "__main__":
    main()
```

## 四、第四步：游戏引擎侧配套改造（必不可少）

Adapter 只是中间翻译层，**引擎必须对外暴露 Angelscript VM 的调试 TCP 服务**，简要改造要点：

1. 在游戏主线程启动 TCP 服务端，监听 `127.0.0.1:9090`。
2. 实例化 `asIDebugger` 子类，把所有断点、单步、变量接口，封装成自定义 JSON 协议，通过 TCP 收发。
3. Angelscript 虚拟机运行时，设置 `context->SetDebugger(自定义调试器实例)`，启用调试钩子。
4. 断点命中阻塞脚本执行，等待 TCP 收到下一步指令后，再恢复 VM 运行。

## 五、第五步：在 nvim-dap 中配置并使用我们的自定义 Adapter

在你的 `nvim-dap` 配置中，注册新的 `angelscript` 适配器，指向我们写的 Python 脚本。

```lua
local dap = require("dap")

-- 1. 注册自定义Angelscript调试适配器（STDIO模式，执行python脚本）
dap.adapters.angelscript = {
  type = "executable",
  command = "python",
  args = { vim.fn.expand("D:/path/as_dap_adapter.py") }, -- 脚本绝对路径
}

-- 2. 配置调试模式：attach 附加游戏进程（最常用）
dap.configurations.angelscript = {
  {
    name = "附加游戏Angelscript进程",
    type = "angelscript",
    request = "attach",
    engineHost = "127.0.0.1",
    enginePort = 9090,
  },
  -- 可选：launch 直接启动AS脚本文件
  {
    name = "启动Angelscript脚本",
    type = "angelscript",
    request = "launch",
    program = "${file}", -- 当前打开的.as文件
  }
}
```

使用流程：

1. 启动游戏，引擎 TCP 调试端口正常监听。
2. Neovim 打开 `.as` 脚本，F9 打上断点。
3. F5 选择「附加游戏 Angelscript 进程」，即可进入调试，完整使用 F10/F11/F12 单步、查看变量、调用栈。

## 六、进阶优化与常见问题

### 1. 路径映射（必做）

游戏内加载的脚本是相对路径，nvim-dap 是本地绝对路径，需要在 Adapter 做路径映射转换，否则断点无法匹配文件：

```python
# 示例：引擎内路径 game/script/test.as  <=> 本地 D:/game/scripts/test.as
def map_engine_path(engine_path):
    return engine_path.replace("game/script/", "D:/game/scripts/")
```

### 2. 多线程支持

Angelscript 支持多脚本线程，DAP 原生支持 threadId，需要引擎侧返回线程 ID，Adapter 透传给前端，实现线程切换调试。

### 3. 正式版改用 C++ 开发

Python 原型验证完成后，建议用 C++ 重写 Adapter，直接链接 Angelscript SDK，省去 TCP 网络中转，性能更高，可以直接嵌入游戏引擎发布。

### 4. 补充高阶 DAP 能力

后续可以按需实现：条件断点、日志断点、表达式求值（hover 预览变量）、修改变量、异常捕获。

## 七、极简总结

1. Debug Adapter 两大核心：**DAP 标准协议编解码** + **Angelscript 虚拟机原生调试接口桥接**，TCP/STDIO 只是传输层。
2. 开发分两步：先用 Python 快速做原型验证协议连通；再完善引擎侧 TCP 调试服务。
3. 通信模式选择：本地调试用 STDIO；附加运行游戏进程，固定用 TCP Socket。
4. 整个适配器完全符合标准 DAP，无缝对接 nvim-dap 全套 UI、断点、单步调试能力。