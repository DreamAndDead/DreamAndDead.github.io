---
title: AngelScript 完整调试方案
---

# AngelScript 完整调试方案

AngelScript 的调试体系分为**内置原生调试接口（底层必懂）、日志打印、本地断点调试、VSCode/LSP 调试、远程调试、性能分析、崩溃定位**，分为原生 C++ 接入 + 上层脚本调试两部分，适配自研 C++ 游戏引擎。

## 一、前置基础：AS 自带完整调试回调接口

AngelScript 虚拟机 `asIScriptEngine` 原生预留了全套调试回调，不需要额外第三方库，核心入口：

```cpp
// 设置全局调试回调接口
engine->SetDebugger(&yourDebuggerImpl);
```

需要继承 `asIDebugger` 实现虚函数，核心回调：

```cpp
virtual void LineCallback(asIScriptContext *ctx, int lineNumber); // 行断点触发
virtual void BreakCallback(asIScriptContext *ctx);              // 主动中断
virtual void ExceptionCallback(asIScriptContext *ctx);           // 脚本异常崩溃
virtual void StepCallback(asIScriptContext *ctx);                // 单步执行回调
virtual int  GetDebugProperty(asIScriptContext *ctx, const char *name, ...); // 查看变量
```

所有断点、单步、异常捕获、变量查看，全部基于这套回调实现。

## 二、基础调试：最简打印、断言、异常捕获（快速排错）

### 1. 脚本内日志输出

AS 本身没有内置 print，需要**C++ 注册日志函数到脚本**。
 C++ 侧注册：

```cpp
void Log(const string &msg) { printf("[AS] %s\n", msg.c_str()); }
engine->RegisterGlobalFunction("void Log(const string &in msg)", asFUNCTION(Log), asCALL_CDECL);
```

脚本直接调用：

```csharp
void Test()
{
    int hp = 100;
    Log("当前血量：" + hp);
}
```

### 2. 脚本断言 Assert

C++ 注册断言函数，脚本校验参数，不满足直接触发异常，方便快速定位逻辑错误。

```cpp
void Assert(bool cond, const string &msg)
{
    if(!cond)
    {
        printf("Assert Failed: %s\n", msg.c_str());
        // 主动触发调试中断，进入调试器
        engine->BreakExecution();
    }
}
```

### 3. 捕获脚本运行时异常（最常用）

执行脚本 `Execute()` 时捕获返回值，配合上下文获取异常堆栈：

```cpp
asIScriptContext* ctx = engine->CreateContext();
int ret = ctx->Execute();
if(ret < 0)
{
    // 获取异常信息、出错行号、函数名
    const char* errMsg = ctx->GetExceptionMessage();
    int line = ctx->GetExceptionLineNumber();
    asIScriptFunction* func = ctx->GetExceptionFunction();
    printf("AS异常：%s 函数:%s 行:%d\n", errMsg, func->GetName(), line);

    // 打印完整调用堆栈
    PrintCallstack(ctx);
}
ctx->Release();
```

可以封装函数打印完整调用栈，精准定位空句柄、数组越界、类型错误。

## 三、核心：手动实现断点、单步调试（引擎内置调试器）

适合自研引擎内嵌游戏内调试面板，实现：**断点、继续、单步步入 / 步过、查看局部变量、查看 this 对象**。

### 1. 启用行回调（逐行执行钩子）

开启行回调，虚拟机执行每一行脚本都会进入回调：

```cpp
// 开启行回调
ctx->SetLineCallback(true);
```

在 `LineCallback` 回调内判断：

1. 当前文件名 + 行号 是否是预设断点；
2. 命中断点时，暂停虚拟机执行；
3. 此时可以读取当前上下文的局部变量、堆栈。

### 2. 单步控制模式

在暂停状态，可以通过上下文控制执行模式：

- `STEP_OVER` 步过（跳过函数）
- `STEP_INTO` 步入（进入函数）
- `STEP_OUT` 步出（跳出当前函数）

### 3. 读取上下文变量

暂停后，通过 `asIScriptContext` 读取局部变量、全局变量、对象成员：

```cpp
// 获取局部变量数量
uint32_t varCount = ctx->GetVarCount();
for(uint32_t i = 0; i < varCount; i++)
{
    const char* varName = ctx->GetVarName(i);
    int typeId = ctx->GetVarTypeId(i);
    void* data = ctx->GetVarAddress(i);
    // 根据类型解析值：int/float/string/对象句柄
}
```

也可以直接通过变量名字查找取值：`ctx->GetVarAddressByName("hp")`。

### 4. 条件断点扩展

在断点回调里额外判断变量值，例如 `hp <= 0` 才触发中断，实现条件断点。

## 四、标准方案：对接 VSCode 可视化调试（最主流）

工业项目通用方案：**AS 实现 Debug Adapter Protocol (DAP) 协议**，对接 VSCode，图形化断点、堆栈、监视变量，和调试 C++ 体验一致。

### 两种现成方案

1. **AngelScript DAP 开源实现** 社区开源的 `as-dap` 适配器，完成 TCP 通信、DAP 协议封装，引擎内嵌 TCP Server，VSCode 通过插件连接引擎进程。
2. **使用 asDebugger 配套工具** 官方自带 asDebugger 桌面 GUI 调试器（Windows），可直接附加进程、加载脚本字节码、图形化断点调试，适合 Windows 单机快速调试。

### 工作流程

1. C++ 引擎启动 TCP 调试服务端；
2. VSCode 安装通用 DAP 调试插件，配置 launch.json 连接引擎端口；
3. VSCode 下发断点列表 → 引擎虚拟机注册断点；
4. 命中断点后，引擎把堆栈、变量数据回传给 VSCode 展示；
5. 支持单步、监视、全局变量查看、调用栈跳转。

## 五、编辑器实时热重载调试（AS 独有优势）

AS 最常用的开发模式就是**边改边热更调试**，不需要重启游戏：

1. 编辑器修改脚本文件；
2. 引擎重新编译对应脚本模块，动态替换旧的函数；
3. 当前游戏逻辑立刻使用新脚本运行，配合日志 + 断点即时验证修改效果。

**注意坑**：

- 仅函数逻辑可以热重载，**类结构、成员变量新增 / 删除无法动态替换**；
- 正在运行的协程上下文不会自动刷新，需要重新创建实例。

## 六、崩溃与内存问题调试

### 1. 句柄（智能指针）内存泄漏 / 悬空

AS 使用引用计数句柄管理跨语言对象，常见问题：循环引用、C++ 侧裸指针持有 AS 对象。
 调试手段：

1. 开启引擎内存追踪，`asIScriptEngine::SetMemoryFunctions()` 替换自定义内存分配器，记录所有对象创建释放；
2. 使用 `engine->GetStats()` 获取对象引用计数统计，定位长期不释放的对象；
3. 异常堆栈查看是否存在句柄空引用（null handle）访问。

### 2. C++ 与 AS 调用栈混合查看

当脚本调用 C++ 函数崩溃，或是 C++ 回调脚本崩溃时：

1. 崩溃时先打印**AS 脚本调用栈**（`PrintCallstack(ctx)`）；
2. 再配合 VS/GDB/Lldb 查看 C++ 原生调用栈；
3. 双向定位：是脚本传参错误，还是 C++ 绑定代码逻辑问题。

## 七、多线程调试注意事项

AngelScript 一个 `asIScriptEngine` 可以创建多个独立 `asIScriptContext`，每个上下文可跑在不同线程：

1. **调试回调是线程绑定的**，断点只会暂停当前执行的 Context，不会阻塞全局引擎；
2. 禁止多个线程同时操作同一个 Context；
3. 多线程脚本异常时，务必保存当前线程的 ctx 上下文，否则堆栈信息错乱。

## 八、移动端 / 主机平台调试方案

### 1. Android

1. 引擎开启网络端口，局域网 VSCode DAP 远程调试；
2. 输出日志到 logcat，结合文件落盘完整异常堆栈。

### 2. iOS / 主机 (Switch/PS/Xbox)

封闭平台无法附加 GUI 调试器，采用**日志落地 + 内存快照 + 异常 dump**方案：

1. 关键节点全量写日志到本地文件；
2. 异常时序列化当前脚本调用栈、局部变量存入日志；
3. PC 端解析日志定位问题，一般不做实时断点调试。

## 九、常用调试避坑要点

1. **编译脚本务必保留行号信息** 编译脚本时不要关闭调试符号： ```cpp
   // 开启行号、调试信息，否则无法断点和显示行号
   builder->SetBuildOption(asBO_BUILD_DEBUG_INFO, true);
   ```
2. 字节码缓存调试：不要预编译不带调试信息的字节码发布版用于开发调试；
3. 不要在 LineCallback 回调里做耗时逻辑，会严重卡游戏帧率；
4. 调试发布版时，可以单独开启 AS 调试符号，关闭 C++ 优化，方便定位 Release 下的隐性 bug。

## 十、调试工具选型速查表

| 场⁠景 | 推⁠荐⁠工⁠具 / 方⁠案 |
| --- | --- |
| Windows 快⁠速⁠本⁠地⁠调⁠试 | 官⁠方 asDebugger GUI 工⁠具 |
| 日⁠常⁠主⁠力⁠开⁠发 | VSCode + DAP 协⁠议⁠图⁠形⁠断⁠点⁠调⁠试 |
| 自⁠研⁠引⁠擎⁠内⁠置⁠调⁠试⁠面⁠板 | 原⁠生⁠实⁠现 `asIDebugger` 回⁠调 |
| 移⁠动⁠端⁠远⁠程⁠调⁠试 | 局⁠域⁠网 TCP DAP + 日⁠志 |
| 主⁠机⁠封⁠闭⁠平⁠台 | 日⁠志⁠文⁠件 + 异⁠常⁠堆⁠栈 dump 离⁠线⁠分⁠析 |
| 性⁠能⁠耗⁠时⁠分⁠析 | 上⁠下⁠文⁠执⁠行⁠计⁠时，统⁠计⁠函⁠数⁠字⁠节⁠码⁠执⁠行⁠耗⁠时 |